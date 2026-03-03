import { createHash, randomBytes } from "node:crypto";

import jwt from "jsonwebtoken";

import { env } from "../config/env.js";

export type AccessTokenPayload = {
  sub: string;
  email: string;
  role: "USER" | "ADMIN";
};

export const accessTokenExpiresInSec = env.ACCESS_TOKEN_TTL_MINUTES * 60;
export const refreshTokenExpiresInSec = env.REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60;

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.AUTH_SECRET, {
    expiresIn: accessTokenExpiresInSec,
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  return jwt.verify(token, env.AUTH_SECRET) as AccessTokenPayload;
}

export function createRefreshTokenValue(): string {
  return randomBytes(48).toString("base64url");
}

export function hashRefreshToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export function getRefreshTokenExpiresAt(): Date {
  return new Date(Date.now() + refreshTokenExpiresInSec * 1000);
}
