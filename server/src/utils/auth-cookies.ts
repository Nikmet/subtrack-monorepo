import type { Response } from "express";

import { env } from "../config/env.js";
import { accessTokenExpiresInSec, refreshTokenExpiresInSec } from "../lib/auth-tokens.js";

const isProduction = env.NODE_ENV === "production";

export function setAuthCookies(res: Response, tokens: { accessToken: string; refreshToken: string }): void {
  res.cookie(env.AUTH_ACCESS_COOKIE_NAME, tokens.accessToken, {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
    maxAge: accessTokenExpiresInSec * 1000,
  });

  res.cookie(env.AUTH_REFRESH_COOKIE_NAME, tokens.refreshToken, {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
    maxAge: refreshTokenExpiresInSec * 1000,
  });
}

export function clearAuthCookies(res: Response): void {
  res.clearCookie(env.AUTH_ACCESS_COOKIE_NAME, {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
  });
  res.clearCookie(env.AUTH_REFRESH_COOKIE_NAME, {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
  });
}
