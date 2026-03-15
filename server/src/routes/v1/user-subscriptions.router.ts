import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import { formatPaymentMethodLabel, formatRub, normalizeCardNumberInput } from "../../lib/formatters.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import {
  DEFAULT_SUBSCRIPTION_CATEGORY,
  getSubscriptionCategoryLabel,
  isSubscriptionCategory,
} from "../../lib/subscription-constants.js";
import { asyncHandler } from "../../utils/async-handler.js";

const NEW_PAYMENT_METHOD_VALUE = "__new__";

const optionalManagementUrlSchema = z
  .string()
  .trim()
  .optional()
  .default("")
  .refine((value) => value === "" || z.string().url().safeParse(value).success, {
    message: "Некорректная ссылка на страницу управления.",
  });

const createUserSubscriptionBodySchema = z.object({
  commonSubscriptionId: z.string().uuid(),
  nextPaymentAt: z.string().min(1),
  paymentMethodId: z.string().optional().default(""),
  newPaymentMethodBankId: z.string().optional().default(""),
  newPaymentMethodCardNumber: z.string().optional().default(""),
});

const updateUserSubscriptionBodySchema = z.object({
  nextPaymentAt: z.string().min(1),
  paymentMethodId: z.string().optional().default(""),
  newPaymentMethodBankId: z.string().optional().default(""),
  newPaymentMethodCardNumber: z.string().optional().default(""),
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

const userSubscriptionIdParamsSchema = z.object({
  id: z.string().uuid(),
});

const parseDate = (value: string): Date | null => {
  const parsed = new Date(`${value}T00:00:00`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const normalizeCardNumber = (value: string) => normalizeCardNumberInput(value);

const isValidCardNumber = (value: string) => value.length >= 4 && value.length <= 24;

const getOrCreatePaymentMethod = async (
  userId: string,
  paymentMethodIdInput: string,
  newPaymentMethodBankId: string,
  newPaymentMethodCardNumber: string,
) => {
  if (paymentMethodIdInput && paymentMethodIdInput !== NEW_PAYMENT_METHOD_VALUE) {
    const paymentMethod = await prisma.paymentMethod.findFirst({
      where: {
        id: paymentMethodIdInput,
        userId,
      },
      select: {
        id: true,
        cardNumber: true,
        bank: {
          select: {
            name: true,
          },
        },
      },
    });

    if (!paymentMethod) {
      return null;
    }

    return {
      id: paymentMethod.id,
      snapshotLabel: formatPaymentMethodLabel(paymentMethod.bank.name, paymentMethod.cardNumber),
    };
  }

  if (!newPaymentMethodBankId || !isValidCardNumber(newPaymentMethodCardNumber)) {
    return null;
  }

  const bank = await prisma.bank.findUnique({
    where: {
      id: newPaymentMethodBankId,
    },
    select: {
      id: true,
      name: true,
    },
  });

  if (!bank) {
    return null;
  }

  const existed = await prisma.paymentMethod.findFirst({
    where: {
      userId,
      cardNumber: {
        equals: newPaymentMethodCardNumber,
        mode: "insensitive",
      },
    },
    select: {
      id: true,
      cardNumber: true,
      bank: {
        select: {
          name: true,
        },
      },
    },
  });

  if (existed) {
    return {
      id: existed.id,
      snapshotLabel: formatPaymentMethodLabel(existed.bank.name, existed.cardNumber),
    };
  }

  const methodsCount = await prisma.paymentMethod.count({
    where: {
      userId,
    },
  });

  const created = await prisma.paymentMethod.create({
    data: {
      userId,
      bankId: bank.id,
      cardNumber: newPaymentMethodCardNumber,
      isDefault: methodsCount === 0,
    },
    select: {
      id: true,
      cardNumber: true,
      bank: {
        select: {
          name: true,
        },
      },
    },
  });

  return {
    id: created.id,
    snapshotLabel: formatPaymentMethodLabel(created.bank.name, created.cardNumber),
  };
};

export const userSubscriptionsRouter = Router();

userSubscriptionsRouter.post(
  "/",
  authRequired,
  notBanned,
  validateBody(createUserSubscriptionBodySchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const body = req.body as z.infer<typeof createUserSubscriptionBodySchema>;
    const nextPaymentAt = parseDate(body.nextPaymentAt);
    if (!nextPaymentAt) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Некорректная дата следующего платежа.",
      });
    }

    const commonSubscription = await prisma.commonSubscription.findUnique({
      where: { id: body.commonSubscriptionId },
      select: {
        id: true,
        name: true,
        price: true,
        status: true,
      },
    });

    if (!commonSubscription || commonSubscription.status !== "PUBLISHED") {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Подписка не найдена.",
      });
    }

    const paymentMethod = await getOrCreatePaymentMethod(
      user.id,
      body.paymentMethodId,
      body.newPaymentMethodBankId,
      normalizeCardNumber(body.newPaymentMethodCardNumber),
    );

    if (!paymentMethod) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Некорректные данные способа оплаты.",
      });
    }

    const duplicate = await prisma.userSubscription.findUnique({
      where: {
        userId_commonSubscriptionId: {
          userId: user.id,
          commonSubscriptionId: body.commonSubscriptionId,
        },
      },
      select: { id: true },
    });

    if (duplicate) {
      throw new AppError({
        status: 409,
        code: "COMMON_SUBSCRIPTION_EXISTS",
        message: "Подписка уже добавлена.",
      });
    }

    const created = await prisma.userSubscription.create({
      data: {
        userId: user.id,
        commonSubscriptionId: body.commonSubscriptionId,
        paymentMethodId: paymentMethod.id,
        nextPaymentAt,
        paymentCardLabel: paymentMethod.snapshotLabel,
      },
    });

    await prisma.notification.create({
      data: {
        userId: user.id,
        kind: "success",
        title: "Подписка добавлена",
        message: `Вы добавили ${commonSubscription.name} в список подписок.`,
      },
    });

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfPaymentDate = new Date(
      nextPaymentAt.getFullYear(),
      nextPaymentAt.getMonth(),
      nextPaymentAt.getDate(),
    );
    const diffDays = Math.floor(
      (startOfPaymentDate.getTime() - startOfToday.getTime()) / (1000 * 60 * 60 * 24),
    );

    if (diffDays === 0 || diffDays === 1) {
      await prisma.notification.create({
        data: {
          userId: user.id,
          kind: "info",
          title: "Скоро списание",
          message: `${diffDays === 0 ? "Сегодня" : "Завтра"} будет списано ${formatRub(
            Number(commonSubscription.price.toString()),
          )} за ${commonSubscription.name}.`,
        },
      });
    }

    sendSuccess(res, created, {}, 201);
  }),
);

userSubscriptionsRouter.get(
  "/pending",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const user = req.authUser!;

    const pendingItems = await prisma.commonSubscription.findMany({
      where: {
        createdByUserId: user.id,
        status: {
          in: ["PENDING", "PUBLISHED", "REJECTED"],
        },
      },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      select: {
        id: true,
        name: true,
        imgLink: true,
        category: true,
        price: true,
        period: true,
        createdAt: true,
        moderationComment: true,
        status: true,
      },
    });

    sendSuccess(
      res,
      pendingItems.map((item) => ({
        ...item,
        categoryName: getSubscriptionCategoryLabel(item.category),
        price: Number(item.price.toString()),
      })),
    );
  }),
);

userSubscriptionsRouter.patch(
  "/:id",
  authRequired,
  notBanned,
  validateParams(userSubscriptionIdParamsSchema),
  validateBody(updateUserSubscriptionBodySchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const params = req.params as z.infer<typeof userSubscriptionIdParamsSchema>;
    const body = req.body as z.infer<typeof updateUserSubscriptionBodySchema>;
    const nextPaymentAt = parseDate(body.nextPaymentAt);

    if (!nextPaymentAt) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "РќРµРєРѕСЂСЂРµРєС‚РЅР°СЏ РґР°С‚Р° СЃР»РµРґСѓСЋС‰РµРіРѕ РїР»Р°С‚РµР¶Р°.",
      });
    }

    const existingSubscription = await prisma.userSubscription.findFirst({
      where: {
        id: params.id,
        userId: user.id,
      },
      select: {
        id: true,
      },
    });

    if (!existingSubscription) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "РџРѕРґРїРёСЃРєР° РЅРµ РЅР°Р№РґРµРЅР°.",
      });
    }

    const paymentMethod = await getOrCreatePaymentMethod(
      user.id,
      body.paymentMethodId,
      body.newPaymentMethodBankId,
      normalizeCardNumber(body.newPaymentMethodCardNumber),
    );

    if (!paymentMethod) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "РќРµРєРѕСЂСЂРµРєС‚РЅС‹Рµ РґР°РЅРЅС‹Рµ СЃРїРѕСЃРѕР±Р° РѕРїР»Р°С‚С‹.",
      });
    }

    const updated = await prisma.userSubscription.update({
      where: { id: existingSubscription.id },
      data: {
        nextPaymentAt,
        paymentMethodId: paymentMethod.id,
        paymentCardLabel: paymentMethod.snapshotLabel,
      },
    });

    sendSuccess(res, updated);
  }),
);

userSubscriptionsRouter.delete(
  "/:id",
  authRequired,
  notBanned,
  validateParams(userSubscriptionIdParamsSchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const params = req.params as z.infer<typeof userSubscriptionIdParamsSchema>;

    const subscription = await prisma.userSubscription.findFirst({
      where: {
        id: params.id,
        userId: user.id,
      },
      select: {
        id: true,
        commonSubscription: {
          select: {
            name: true,
          },
        },
      },
    });

    if (!subscription) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "РџРѕРґРїРёСЃРєР° РЅРµ РЅР°Р№РґРµРЅР°.",
      });
    }

    await prisma.userSubscription.delete({
      where: {
        id: subscription.id,
      },
    });

    await prisma.notification.create({
      data: {
        userId: user.id,
        kind: "warning",
        title: "РџРѕРґРїРёСЃРєР° СѓРґР°Р»РµРЅР°",
        message: `РџРѕРґРїРёСЃРєР° ${subscription.commonSubscription.name} СѓРґР°Р»РµРЅР° РёР· РІР°С€РµРіРѕ СЃРїРёСЃРєР°.`,
      },
    });

    sendSuccess(res, { success: true, id: subscription.id });
  }),
);

userSubscriptionsRouter.post(
  "/common",
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
