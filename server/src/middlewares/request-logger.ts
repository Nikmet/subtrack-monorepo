import type { NextFunction, Request, Response } from "express";

import { getRequestLogContext, logger } from "../lib/logger.js";

const getDurationMs = (startNs: bigint): number =>
  Number(((process.hrtime.bigint() - startNs) * BigInt(1000)) / BigInt(1_000_000)) / 1000;

export function requestLoggerMiddleware(req: Request, res: Response, next: NextFunction): void {
  const startedAtNs = process.hrtime.bigint();
  let logged = false;

  const writeAccessLog = (event: "finish" | "close"): void => {
    if (logged) {
      return;
    }
    logged = true;

    const statusCode = res.statusCode;
    const context = {
      ...getRequestLogContext(req),
      event,
      statusCode,
      durationMs: getDurationMs(startedAtNs),
      responseSize: res.getHeader("content-length")?.toString() ?? null,
    };

    if (event === "close" && !res.writableEnded) {
      logger.warn("HTTP request connection closed before response completed", context);
      return;
    }

    if (statusCode >= 500) {
      logger.error("HTTP request completed with server error", context);
      return;
    }

    if (statusCode >= 400) {
      logger.warn("HTTP request completed with client error", context);
      return;
    }

    logger.info("HTTP request completed", context);
  };

  res.on("finish", () => writeAccessLog("finish"));
  res.on("close", () => writeAccessLog("close"));

  next();
}
