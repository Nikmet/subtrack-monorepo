import { z } from "zod";

import { successEnvelopeSchema, userRoleSchema } from "./common";

export const authUserSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  email: z.string().email(),
  role: userRoleSchema,
  isBanned: z.boolean(),
  banReason: z.string().nullable(),
  avatarLink: z.string().nullable().optional(),
});

export const authLoginBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

export const authRegisterBodySchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(8),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

export const authRefreshBodySchema = z.object({
  refreshToken: z.string().optional(),
  clientType: z.enum(["web", "mobile"]).optional().default("web"),
});

export const authLogoutBodySchema = z.object({
  refreshToken: z.string().optional(),
});

export const authTokenPairSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  accessTokenExpiresInSec: z.number().int().positive(),
  refreshTokenExpiresInSec: z.number().int().positive(),
});

export const authSessionSchema = successEnvelopeSchema(
  z.object({
    user: authUserSchema,
    tokenPair: authTokenPairSchema.optional(),
  }),
);

export type AuthUser = z.infer<typeof authUserSchema>;
export type AuthLoginBody = z.infer<typeof authLoginBodySchema>;
export type AuthRegisterBody = z.infer<typeof authRegisterBodySchema>;
