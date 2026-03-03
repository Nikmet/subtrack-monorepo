import { compare, hash } from "bcryptjs";
import { Router } from "express";
import { z } from "zod";

import { env } from "../../config/env.js";
import { authRequired, optionalAuth } from "../../middlewares/auth.js";
import { validateBody } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import {
  createRefreshTokenValue,
  getRefreshTokenExpiresAt,
  hashRefreshToken,
  refreshTokenExpiresInSec,
  signAccessToken,
  accessTokenExpiresInSec,
} from "../../lib/auth-tokens.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";
import { clearAuthCookies, setAuthCookies } from "../../utils/auth-cookies.js";
import { loadAuthUser } from "../../utils/load-auth-user.js";

const refreshCookieOrBodySchema = z.object({
  refreshToken: z.string().optional(),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

const authLoginBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

const authRegisterBodySchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

const authLogoutBodySchema = z.object({
  refreshToken: z.string().optional(),
});

type IssuedTokens = {
  accessToken: string;
  refreshToken: string;
};

async function issueTokens(params: {
  userId: string;
  email: string;
  role: "USER" | "ADMIN";
  userAgent?: string | null;
  ipAddress?: string | null;
}): Promise<IssuedTokens> {
  const refreshToken = createRefreshTokenValue();
  const refreshHash = hashRefreshToken(refreshToken);
  const expiresAt = getRefreshTokenExpiresAt();
  const accessToken = signAccessToken({
    sub: params.userId,
    email: params.email,
    role: params.role,
  });

  await prisma.refreshToken.create({
    data: {
      userId: params.userId,
      tokenHash: refreshHash,
      expiresAt,
      userAgent: params.userAgent ?? null,
      ipAddress: params.ipAddress ?? null,
    },
  });

  return { accessToken, refreshToken };
}

async function rotateRefreshToken(params: {
  refreshToken: string;
  userAgent?: string | null;
  ipAddress?: string | null;
}): Promise<{ tokens: IssuedTokens; user: NonNullable<Awaited<ReturnType<typeof loadAuthUser>>> }> {
  const hashValue = hashRefreshToken(params.refreshToken);
  const now = new Date();

  const tokenRecord = await prisma.refreshToken.findUnique({
    where: {
      tokenHash: hashValue,
    },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          isBanned: true,
          banReason: true,
        },
      },
    },
  });

  if (!tokenRecord || tokenRecord.revokedAt || tokenRecord.expiresAt <= now) {
    throw new AppError({
      status: 401,
      code: "TOKEN_INVALID",
      message: "Refresh token недействителен.",
    });
  }

  await prisma.refreshToken.update({
    where: { id: tokenRecord.id },
    data: { revokedAt: now },
  });

  const authUser = await loadAuthUser(tokenRecord.userId);
  if (!authUser) {
    throw new AppError({
      status: 401,
      code: "UNAUTHORIZED",
      message: "Пользователь не найден.",
    });
  }

  if (authUser.isBanned) {
    throw new AppError({
      status: 403,
      code: "BANNED",
      message: authUser.banReason?.trim() || "Аккаунт заблокирован администратором.",
    });
  }

  const tokens = await issueTokens({
    userId: authUser.id,
    email: authUser.email,
    role: authUser.role,
    userAgent: params.userAgent,
    ipAddress: params.ipAddress,
  });

  return { tokens, user: authUser };
}

export const authRouter = Router();

authRouter.post(
  "/register",
  validateBody(authRegisterBodySchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof authRegisterBodySchema>;
    const name = body.name.trim();
    const email = body.email.trim().toLowerCase();
    const password = body.password;
    const clientType = body.clientType ?? "web";

    const existed = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });

    if (existed) {
      throw new AppError({
        status: 409,
        code: "CONFLICT",
        message: "Пользователь с таким email уже существует.",
      });
    }

    const passwordHash = await hash(password, 10);
    const role = email === env.ADMIN_BOOTSTRAP_EMAIL ? "ADMIN" : "USER";

    const created = await prisma.user.create({
      data: {
        name,
        email,
        password: passwordHash,
        role,
      },
      select: {
        id: true,
        email: true,
        role: true,
      },
    });

    const tokens = await issueTokens({
      userId: created.id,
      email: created.email,
      role: created.role,
      userAgent: req.header("user-agent"),
      ipAddress: req.ip,
    });

    if (clientType === "web") {
      setAuthCookies(res, tokens);
    }

    const user = await loadAuthUser(created.id);
    sendSuccess(res, {
      user,
      tokenPair:
        clientType === "mobile"
          ? {
              ...tokens,
              accessTokenExpiresInSec,
              refreshTokenExpiresInSec,
            }
          : undefined,
    });
  }),
);

authRouter.post(
  "/login",
  validateBody(authLoginBodySchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof authLoginBodySchema>;
    const email = body.email.trim().toLowerCase();
    const password = body.password;
    const clientType = body.clientType ?? "web";

    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        name: true,
        email: true,
        password: true,
        role: true,
        isBanned: true,
        banReason: true,
      },
    });

    if (!user) {
      throw new AppError({
        status: 401,
        code: "INVALID_CREDENTIALS",
        message: "Неверный email или пароль.",
      });
    }

    const isValidPassword = await compare(password, user.password);
    if (!isValidPassword) {
      throw new AppError({
        status: 401,
        code: "INVALID_CREDENTIALS",
        message: "Неверный email или пароль.",
      });
    }

    if (user.isBanned) {
      throw new AppError({
        status: 403,
        code: "BANNED",
        message: user.banReason?.trim() || "Аккаунт заблокирован администратором.",
      });
    }

    let role = user.role;
    if (user.email === env.ADMIN_BOOTSTRAP_EMAIL && role !== "ADMIN") {
      await prisma.user.update({
        where: { id: user.id },
        data: { role: "ADMIN" },
      });
      role = "ADMIN";
    }

    const tokens = await issueTokens({
      userId: user.id,
      email: user.email,
      role,
      userAgent: req.header("user-agent"),
      ipAddress: req.ip,
    });

    if (clientType === "web") {
      setAuthCookies(res, tokens);
    }

    const authUser = await loadAuthUser(user.id);
    sendSuccess(res, {
      user: authUser,
      tokenPair:
        clientType === "mobile"
          ? {
              ...tokens,
              accessTokenExpiresInSec,
              refreshTokenExpiresInSec,
            }
          : undefined,
    });
  }),
);

authRouter.post(
  "/refresh",
  validateBody(refreshCookieOrBodySchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof refreshCookieOrBodySchema>;
    const clientType = body.clientType ?? "web";
    const refreshTokenFromCookie = req.cookies?.[env.AUTH_REFRESH_COOKIE_NAME];
    const refreshTokenRaw = body.refreshToken ?? refreshTokenFromCookie;

    if (!refreshTokenRaw) {
      throw new AppError({
        status: 401,
        code: "TOKEN_INVALID",
        message: "Refresh token отсутствует.",
      });
    }

    const { tokens, user } = await rotateRefreshToken({
      refreshToken: refreshTokenRaw,
      userAgent: req.header("user-agent"),
      ipAddress: req.ip,
    });

    if (clientType === "web" || refreshTokenFromCookie) {
      setAuthCookies(res, tokens);
    }

    sendSuccess(res, {
      user,
      tokenPair:
        clientType === "mobile"
          ? {
              ...tokens,
              accessTokenExpiresInSec,
              refreshTokenExpiresInSec,
            }
          : undefined,
    });
  }),
);

authRouter.post(
  "/logout",
  validateBody(authLogoutBodySchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof authLogoutBodySchema>;
    const refreshTokenFromCookie = req.cookies?.[env.AUTH_REFRESH_COOKIE_NAME];
    const refreshTokenRaw = body.refreshToken ?? refreshTokenFromCookie;

    if (refreshTokenRaw) {
      await prisma.refreshToken.updateMany({
        where: {
          tokenHash: hashRefreshToken(refreshTokenRaw),
          revokedAt: null,
        },
        data: { revokedAt: new Date() },
      });
    }

    clearAuthCookies(res);
    sendSuccess(res, { success: true });
  }),
);

authRouter.get(
  "/me",
  optionalAuth,
  authRequired,
  asyncHandler(async (req, res) => {
    const user = req.authUser;
    sendSuccess(res, { user });
  }),
);

