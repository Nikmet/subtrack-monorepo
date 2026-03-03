import type { Response } from "express";

import type { ApiErrorCode } from "./error-codes.js";

export function sendSuccess<T>(
  res: Response,
  data: T,
  meta: Record<string, unknown> = {},
  status = 200,
): void {
  res.status(status).json({ data, meta });
}

export function sendError(
  res: Response,
  status: number,
  code: ApiErrorCode,
  message: string,
  details: Record<string, unknown> = {},
): void {
  const requestId = res.getHeader("x-request-id")?.toString() ?? "";
  res.status(status).json({
    error: { code, message, details },
    requestId,
  });
}
