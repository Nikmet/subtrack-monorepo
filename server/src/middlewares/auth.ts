import type { NextFunction, Request, Response } from "express";

import { env } from "../config/env.js";
import { AppError } from "../lib/app-error.js";
import { verifyAccessToken } from "../lib/auth-tokens.js";
import { loadAuthUser } from "../utils/load-auth-user.js";

const getAccessTokenFromRequest = (req: Request): string | null => {
  const authHeader = req.header("authorization");
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return authHeader.slice("Bearer ".length).trim();
  }

  const cookieToken = req.cookies?.[env.AUTH_ACCESS_COOKIE_NAME];
  if (typeof cookieToken === "string" && cookieToken.trim()) {
    return cookieToken.trim();
  }

  return null;
};

export async function optionalAuth(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const token = getAccessTokenFromRequest(req);
    if (!token) {
      next();
      return;
    }

    const payload = verifyAccessToken(token);
    const userId = payload.sub;
    if (!userId) {
      next();
      return;
    }

    const authUser = await loadAuthUser(userId);
    if (authUser) {
      req.authUser = authUser;
    }

    next();
  } catch {
    next();
  }
}

export async function authRequired(req: Request, _res: Response, next: NextFunction): Promise<void> {
  const token = getAccessTokenFromRequest(req);
  if (!token) {
    next(
      new AppError({
        status: 401,
        code: "UNAUTHORIZED",
        message: "Требуется авторизация.",
      }),
    );
    return;
  }

  try {
    const payload = verifyAccessToken(token);
    const userId = payload.sub;
    if (!userId) {
      throw new Error("Missing subject");
    }

    const authUser = await loadAuthUser(userId);
    if (!authUser) {
      next(
        new AppError({
          status: 401,
          code: "UNAUTHORIZED",
          message: "Сессия недействительна.",
        }),
      );
      return;
    }

    req.authUser = authUser;
    next();
  } catch (error) {
    next(
      new AppError({
        status: 401,
        code: "TOKEN_INVALID",
        message: "Токен недействителен или истек.",
        details: { reason: error instanceof Error ? error.message : "unknown" },
      }),
    );
  }
}

export function notBanned(req: Request, _res: Response, next: NextFunction): void {
  const user = req.authUser;
  if (!user) {
    next(
      new AppError({
        status: 401,
        code: "UNAUTHORIZED",
        message: "Требуется авторизация.",
      }),
    );
    return;
  }

  if (user.isBanned) {
    next(
      new AppError({
        status: 403,
        code: "BANNED",
        message: user.banReason?.trim() || "Аккаунт заблокирован администратором.",
      }),
    );
    return;
  }

  next();
}

export function adminRequired(req: Request, _res: Response, next: NextFunction): void {
  const user = req.authUser;
  if (!user) {
    next(
      new AppError({
        status: 401,
        code: "UNAUTHORIZED",
        message: "Требуется авторизация.",
      }),
    );
    return;
  }

  if (user.role !== "ADMIN") {
    next(
      new AppError({
        status: 403,
        code: "FORBIDDEN",
        message: "Недостаточно прав.",
      }),
    );
    return;
  }

  next();
}
