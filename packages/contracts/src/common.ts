import { z } from "zod";

export const userRoleSchema = z.enum(["USER", "ADMIN"]);

export const subscriptionCategorySchema = z.enum([
  "streaming",
  "music",
  "games",
  "shopping",
  "ai",
  "finance",
  "other",
]);

export const commonSubscriptionStatusSchema = z.enum(["PENDING", "PUBLISHED", "REJECTED"]);

export const apiErrorCodeSchema = z.enum([
  "VALIDATION_ERROR",
  "UNAUTHORIZED",
  "FORBIDDEN",
  "NOT_FOUND",
  "CONFLICT",
  "INTERNAL_ERROR",
  "INVALID_CREDENTIALS",
  "BANNED",
  "TOKEN_EXPIRED",
  "TOKEN_INVALID",
  "PAYMENT_METHOD_EXISTS",
  "PAYMENT_METHOD_IN_USE",
  "COMMON_SUBSCRIPTION_EXISTS",
  "UPLOAD_FAILED",
  "BAD_REQUEST",
]);

export const apiErrorSchema = z.object({
  error: z.object({
    code: apiErrorCodeSchema,
    message: z.string(),
    details: z.record(z.string(), z.unknown()).default({}),
  }),
  requestId: z.string(),
});

export const successEnvelopeSchema = <T extends z.ZodTypeAny>(dataSchema: T) =>
  z.object({
    data: dataSchema,
    meta: z.record(z.string(), z.unknown()).default({}),
  });

export type ApiErrorCode = z.infer<typeof apiErrorCodeSchema>;
export type ApiError = z.infer<typeof apiErrorSchema>;
