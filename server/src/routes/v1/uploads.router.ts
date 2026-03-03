import { randomUUID } from "node:crypto";

import { put } from "@vercel/blob";
import { Router } from "express";
import multer from "multer";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { AppError } from "../../lib/app-error.js";
import { sendSuccess } from "../../lib/http.js";
import { logger } from "../../lib/logger.js";
import { asyncHandler } from "../../utils/async-handler.js";

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

const allowedMimeToExt: Record<string, string> = {
  "image/png": "png",
  "image/jpeg": "jpg",
  "image/webp": "webp",
  "image/svg+xml": "svg",
};

async function uploadToBlob(params: {
  folder: "avatars" | "subscriptions";
  userId: string;
  file: Express.Multer.File;
}): Promise<string> {
  const extension = allowedMimeToExt[params.file.mimetype];
  if (!extension) {
    throw new AppError({
      status: 400,
      code: "BAD_REQUEST",
      message: "Поддерживаются только PNG, JPG, WEBP и SVG.",
    });
  }

  const fileName = `${params.folder}/${params.userId}/${randomUUID()}.${extension}`;
  const uploaded = await put(fileName, params.file.buffer, {
    access: "public",
    addRandomSuffix: false,
    contentType: params.file.mimetype,
  });
  return uploaded.url;
}

export const uploadsRouter = Router();

uploadsRouter.post(
  "/avatar",
  authRequired,
  notBanned,
  upload.single("file"),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const file = req.file;
    if (!file) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Файл не передан.",
      });
    }

    try {
      const url = await uploadToBlob({ folder: "avatars", userId: user.id, file });
      sendSuccess(res, { url });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      logger.error("Avatar upload to blob failed", {
        requestId: req.requestId,
        userId: user.id,
        mimeType: file.mimetype,
        fileSize: file.size,
        error,
      });

      throw new AppError({
        status: 500,
        code: "UPLOAD_FAILED",
        message: "Не удалось загрузить аватар.",
        details: { reason: error instanceof Error ? error.message : "unknown" },
      });
    }
  }),
);

uploadsRouter.post(
  "/icon",
  authRequired,
  notBanned,
  upload.single("file"),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const file = req.file;
    if (!file) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Файл не передан.",
      });
    }

    try {
      const url = await uploadToBlob({ folder: "subscriptions", userId: user.id, file });
      sendSuccess(res, { url });
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }

      logger.error("Subscription icon upload to blob failed", {
        requestId: req.requestId,
        userId: user.id,
        mimeType: file.mimetype,
        fileSize: file.size,
        error,
      });

      throw new AppError({
        status: 500,
        code: "UPLOAD_FAILED",
        message: "Не удалось загрузить иконку.",
        details: { reason: error instanceof Error ? error.message : "unknown" },
      });
    }
  }),
);
