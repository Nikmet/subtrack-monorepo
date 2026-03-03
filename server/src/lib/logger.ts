import type { Request } from "express";

import { env } from "../config/env.js";

type LogLevel = "debug" | "info" | "warn" | "error";

const levelWeights: Record<LogLevel, number> = {
  debug: 10,
  info: 20,
  warn: 30,
  error: 40,
};

const minLevel = env.LOG_LEVEL;

const serializeError = (error: Error) => ({
  name: error.name,
  message: error.message,
  stack: error.stack,
  cause: error.cause,
});

const safeStringify = (value: unknown): string => {
  const seen = new WeakSet<object>();

  return JSON.stringify(value, (_key, currentValue) => {
    if (typeof currentValue === "bigint") {
      return currentValue.toString();
    }

    if (currentValue instanceof Error) {
      return serializeError(currentValue);
    }

    if (typeof currentValue === "object" && currentValue !== null) {
      if (seen.has(currentValue)) {
        return "[Circular]";
      }
      seen.add(currentValue);
    }

    return currentValue;
  });
};

const shouldLog = (level: LogLevel) => levelWeights[level] >= levelWeights[minLevel];

const writeLog = (level: LogLevel, message: string, context: Record<string, unknown> = {}): void => {
  if (!shouldLog(level)) {
    return;
  }

  const payload = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...context,
  };

  const line = safeStringify(payload);
  if (level === "error") {
    console.error(line);
    return;
  }

  if (level === "warn") {
    console.warn(line);
    return;
  }

  console.log(line);
};

export const logger = {
  debug: (message: string, context?: Record<string, unknown>) => writeLog("debug", message, context),
  info: (message: string, context?: Record<string, unknown>) => writeLog("info", message, context),
  warn: (message: string, context?: Record<string, unknown>) => writeLog("warn", message, context),
  error: (message: string, context?: Record<string, unknown>) => writeLog("error", message, context),
};

export const getRequestLogContext = (req: Request): Record<string, unknown> => ({
  requestId: req.requestId,
  method: req.method,
  path: req.originalUrl,
  ip: req.ip,
  origin: req.header("origin") ?? null,
  userAgent: req.header("user-agent") ?? null,
  userId: req.authUser?.id ?? null,
});
