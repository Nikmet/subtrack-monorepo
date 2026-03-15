import { Router } from "express";

import { env } from "../../config/env.js";
import { AppError } from "../../lib/app-error.js";
import { asyncHandler } from "../../utils/async-handler.js";

export const downloadsRouter = Router();

downloadsRouter.get(
  "/android",
  asyncHandler(async (_req, res) => {
    if (!env.ANDROID_APK_DOWNLOAD_URL) {
      throw new AppError({
        status: 503,
        code: "INTERNAL_ERROR",
        message: "Ссылка на Android APK пока не настроена.",
      });
    }

    res.redirect(302, env.ANDROID_APK_DOWNLOAD_URL);
  }),
);
