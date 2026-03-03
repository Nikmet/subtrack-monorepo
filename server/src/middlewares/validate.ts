import type { NextFunction, Request, Response } from "express";
import type { ZodObject, ZodTypeAny } from "zod";
import { ZodError } from "zod";

import { AppError } from "../lib/app-error.js";

export function validateBody<T extends ZodTypeAny>(schema: T) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(
          new AppError({
            status: 400,
            code: "VALIDATION_ERROR",
            message: "Некорректные данные запроса.",
            details: { issues: error.issues },
          }),
        );
        return;
      }
      next(error);
    }
  };
}

export function validateQuery<T extends ZodObject>(schema: T) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.query = schema.parse(req.query) as unknown as Request["query"];
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(
          new AppError({
            status: 400,
            code: "VALIDATION_ERROR",
            message: "Некорректные query-параметры.",
            details: { issues: error.issues },
          }),
        );
        return;
      }
      next(error);
    }
  };
}

export function validateParams<T extends ZodObject>(schema: T) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      req.params = schema.parse(req.params) as unknown as Request["params"];
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        next(
          new AppError({
            status: 400,
            code: "VALIDATION_ERROR",
            message: "Некорректные параметры пути.",
            details: { issues: error.issues },
          }),
        );
        return;
      }
      next(error);
    }
  };
}
