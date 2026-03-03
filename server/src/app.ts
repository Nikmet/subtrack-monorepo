import cookieParser from "cookie-parser";
import cors from "cors";
import express from "express";
import helmet from "helmet";
import swaggerUi from "swagger-ui-express";

import { env } from "./config/env.js";
import { logger } from "./lib/logger.js";
import { errorHandler, notFoundHandler } from "./middlewares/error-handler.js";
import { requestIdMiddleware } from "./middlewares/request-id.js";
import { requestLoggerMiddleware } from "./middlewares/request-logger.js";
import { buildOpenApiDocument } from "./openapi.js";
import { v1Router } from "./routes/v1/index.js";

export const app = express();

const allowedCorsOrigins = env.CORS_ORIGIN.split(",")
  .map((item) => item.trim())
  .filter(Boolean);

app.disable("x-powered-by");
app.use(helmet());
app.use(requestIdMiddleware);
app.use(requestLoggerMiddleware);
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) {
        callback(null, true);
        return;
      }

      if (allowedCorsOrigins.includes(origin)) {
        callback(null, true);
        return;
      }

      logger.warn("CORS origin rejected", {
        origin,
        allowedOrigins: allowedCorsOrigins,
      });
      callback(null, false);
    },
    credentials: true,
  }),
);
app.use(express.json({ limit: "2mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

app.get("/health", (_req, res) => {
    res.status(200).json({ ok: true });
});

app.use("/api/v1", v1Router);

const openApiDocument = buildOpenApiDocument();
app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(openApiDocument));
app.get("/api/openapi.json", (_req, res) => {
    res.json(openApiDocument);
});

app.use(notFoundHandler);
app.use(errorHandler);
