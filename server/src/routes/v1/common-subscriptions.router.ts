import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateBody } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { DEFAULT_SUBSCRIPTION_CATEGORY, isSubscriptionCategory } from "../../lib/subscription-constants.js";
import { asyncHandler } from "../../utils/async-handler.js";

const optionalManagementUrlSchema = z
  .string()
  .trim()
  .optional()
  .default("")
  .refine((value) => value === "" || z.string().url().safeParse(value).success, {
    message: "Некорректная ссылка на страницу управления.",
  });

const createCommonSubscriptionBodySchema = z.object({
  name: z.string().trim().min(2),
  category: z.string().optional().default(DEFAULT_SUBSCRIPTION_CATEGORY),
  imgLink: z.string().optional().default(""),
  managementUrl: optionalManagementUrlSchema,
  price: z.coerce.number().positive(),
  period: z.coerce.number().int(),
});

const allowedPeriods = new Set([1, 3, 6, 12]);

export const commonSubscriptionsRouter = Router();

commonSubscriptionsRouter.post(
  "/",
  authRequired,
  notBanned,
  validateBody(createCommonSubscriptionBodySchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const body = req.body as z.infer<typeof createCommonSubscriptionBodySchema>;

    if (!allowedPeriods.has(body.period)) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Выберите корректный период подписки.",
      });
    }

    const category = isSubscriptionCategory(body.category)
      ? body.category
      : DEFAULT_SUBSCRIPTION_CATEGORY;

    const created = await prisma.commonSubscription.create({
      data: {
        name: body.name.trim(),
        imgLink: body.imgLink.trim(),
        managementUrl: body.managementUrl.trim() || null,
        category,
        price: body.price,
        period: body.period,
        status: "PENDING",
        createdByUserId: user.id,
      },
    });

    await prisma.notification.create({
      data: {
        userId: user.id,
        kind: "info",
        title: "Заявка отправлена на модерацию",
        message: `Подписка "${body.name.trim()}" отправлена на проверку модератору.`,
      },
    });

    sendSuccess(res, created, {}, 201);
  }),
);
