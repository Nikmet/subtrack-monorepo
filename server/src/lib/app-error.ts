import type { ApiErrorCode } from "./error-codes.js";

export class AppError extends Error {
  readonly status: number;
  readonly code: ApiErrorCode;
  readonly details: Record<string, unknown>;

  constructor(params: {
    status: number;
    code: ApiErrorCode;
    message: string;
    details?: Record<string, unknown>;
  }) {
    super(params.message);
    this.name = "AppError";
    this.status = params.status;
    this.code = params.code;
    this.details = params.details ?? {};
  }
}

export const isAppError = (value: unknown): value is AppError => value instanceof AppError;
