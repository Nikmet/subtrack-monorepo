import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";

import { isAppError } from "../lib/app-error.js";
import { sendError } from "../lib/http.js";
import { getRequestLogContext, logger } from "../lib/logger.js";

export function notFoundHandler(req: Request, res: Response): void {
  logger.warn("Route not found", {
    ...getRequestLogContext(req),
    statusCode: 404,
    errorCode: "NOT_FOUND",
  });
  sendError(res, 404, "NOT_FOUND", "Маршрут не найден.");
}

export function errorHandler(
  error: unknown,
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  void next;

  const requestContext = getRequestLogContext(req);

  if (isAppError(error)) {
    const appErrorContext = {
      ...requestContext,
      statusCode: error.status,
      errorCode: error.code,
      errorDetails: error.details,
      error,
    };
    if (error.status >= 500) {
      logger.error("Request failed with AppError", appErrorContext);
    } else {
      logger.warn("Request failed with AppError", appErrorContext);
    }
    sendError(res, error.status, error.code, error.message, error.details);
    return;
  }

  if (error instanceof ZodError) {
    logger.warn("Request failed with Zod validation error", {
      ...requestContext,
      statusCode: 400,
      errorCode: "VALIDATION_ERROR",
      issues: error.issues,
    });
    sendError(res, 400, "VALIDATION_ERROR", "Некорректные данные запроса.", {
      issues: error.issues,
    });
    return;
  }

  logger.error("Unhandled backend error", {
    ...requestContext,
    statusCode: 500,
    errorCode: "INTERNAL_ERROR",
    error,
  });
  sendError(res, 500, "INTERNAL_ERROR", "Внутренняя ошибка сервера.");
}
