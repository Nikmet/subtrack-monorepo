import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateBody, validateParams } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import { formatPaymentMethodLabel, normalizeCardNumberInput } from "../../lib/formatters.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";

const createPaymentMethodBodySchema = z.object({
  bankId: z.string().uuid(),
  cardNumber: z.string().min(4).max(24),
});

const updatePaymentMethodBodySchema = z.object({
  bankId: z.string().uuid(),
  cardNumber: z.string().min(4).max(24),
});

const paymentMethodIdParamsSchema = z.object({
  id: z.string().uuid(),
});

const normalizeCardNumber = (value: string) => normalizeCardNumberInput(value);

export const paymentMethodsRouter = Router();

paymentMethodsRouter.get(
  "/",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;

    const paymentMethods = await prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: [{ isDefault: "desc" }, { createdAt: "asc" }, { id: "asc" }],
      select: {
        id: true,
        cardNumber: true,
        bankId: true,
        isDefault: true,
        bank: {
          select: {
            name: true,
            iconLink: true,
          },
        },
        _count: {
          select: {
            subscriptions: true,
          },
        },
      },
    });

    sendSuccess(
      res,
      paymentMethods.map((item) => ({
        ...item,
        label: formatPaymentMethodLabel(item.bank.name, item.cardNumber),
      })),
    );
  }),
);

paymentMethodsRouter.post(
  "/",
  authRequired,
  notBanned,
  validateBody(createPaymentMethodBodySchema),
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const body = req.body as z.infer<typeof createPaymentMethodBodySchema>;
    const cardNumber = normalizeCardNumber(body.cardNumber);

    if (cardNumber.length < 4 || cardNumber.length > 24) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Некорректный номер карты.",
      });
    }

    const bank = await prisma.bank.findUnique({
      where: { id: body.bankId },
      select: { id: true, name: true },
    });

    if (!bank) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Банк не найден.",
      });
    }

    const existing = await prisma.paymentMethod.findFirst({
      where: {
        userId,
        cardNumber: {
          equals: cardNumber,
          mode: "insensitive",
        },
      },
      select: { id: true },
    });

    if (existing) {
      throw new AppError({
        status: 409,
        code: "PAYMENT_METHOD_EXISTS",
        message: "Способ оплаты с такой картой уже существует.",
      });
    }

    const methodsCount = await prisma.paymentMethod.count({
      where: { userId },
    });

    const created = await prisma.paymentMethod.create({
      data: {
        userId,
        bankId: bank.id,
        cardNumber,
        isDefault: methodsCount === 0,
      },
      select: {
        id: true,
        bankId: true,
        cardNumber: true,
        isDefault: true,
      },
    });

    sendSuccess(
      res,
      {
        ...created,
        label: formatPaymentMethodLabel(bank.name, created.cardNumber),
      },
      {},
      201,
    );
  }),
);

paymentMethodsRouter.patch(
  "/:id",
  authRequired,
  notBanned,
  validateParams(paymentMethodIdParamsSchema),
  validateBody(updatePaymentMethodBodySchema),
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const params = req.params as z.infer<typeof paymentMethodIdParamsSchema>;
    const body = req.body as z.infer<typeof updatePaymentMethodBodySchema>;
    const cardNumber = normalizeCardNumber(body.cardNumber);

    const method = await prisma.paymentMethod.findFirst({
      where: {
        id: params.id,
        userId,
      },
      select: { id: true },
    });

    if (!method) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Способ оплаты не найден.",
      });
    }

    const bank = await prisma.bank.findUnique({
      where: { id: body.bankId },
      select: { id: true, name: true },
    });

    if (!bank) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Банк не найден.",
      });
    }

    const existing = await prisma.paymentMethod.findFirst({
      where: {
        userId,
        id: {
          not: params.id,
        },
        cardNumber: {
          equals: cardNumber,
          mode: "insensitive",
        },
      },
      select: { id: true },
    });

    if (existing) {
      throw new AppError({
        status: 409,
        code: "PAYMENT_METHOD_EXISTS",
        message: "Способ оплаты с такой картой уже существует.",
      });
    }

    const updated = await prisma.paymentMethod.update({
      where: { id: params.id },
      data: {
        bankId: bank.id,
        cardNumber,
      },
      select: {
        id: true,
        bankId: true,
        cardNumber: true,
        isDefault: true,
      },
    });

    await prisma.userSubscription.updateMany({
      where: {
        userId,
        paymentMethodId: params.id,
      },
      data: {
        paymentCardLabel: formatPaymentMethodLabel(bank.name, cardNumber),
      },
    });

    sendSuccess(res, {
      ...updated,
      label: formatPaymentMethodLabel(bank.name, updated.cardNumber),
    });
  }),
);

paymentMethodsRouter.patch(
  "/:id/default",
  authRequired,
  notBanned,
  validateParams(paymentMethodIdParamsSchema),
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const params = req.params as z.infer<typeof paymentMethodIdParamsSchema>;

    const method = await prisma.paymentMethod.findFirst({
      where: {
        id: params.id,
        userId,
      },
      select: { id: true },
    });

    if (!method) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Способ оплаты не найден.",
      });
    }

    await prisma.$transaction([
      prisma.paymentMethod.updateMany({
        where: { userId },
        data: { isDefault: false },
      }),
      prisma.paymentMethod.update({
        where: { id: method.id },
        data: { isDefault: true },
      }),
    ]);

    sendSuccess(res, { success: true });
  }),
);

paymentMethodsRouter.delete(
  "/:id",
  authRequired,
  notBanned,
  validateParams(paymentMethodIdParamsSchema),
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const params = req.params as z.infer<typeof paymentMethodIdParamsSchema>;

    const method = await prisma.paymentMethod.findFirst({
      where: {
        id: params.id,
        userId,
      },
      select: {
        id: true,
        isDefault: true,
        _count: {
          select: {
            subscriptions: true,
          },
        },
      },
    });

    if (!method) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Способ оплаты не найден.",
      });
    }

    if (method._count.subscriptions > 0) {
      throw new AppError({
        status: 409,
        code: "PAYMENT_METHOD_IN_USE",
        message: "Нельзя удалить способ оплаты, который используется в подписках.",
      });
    }

    await prisma.paymentMethod.delete({
      where: { id: method.id },
    });

    if (method.isDefault) {
      const replacement = await prisma.paymentMethod.findFirst({
        where: { userId },
        orderBy: [{ createdAt: "asc" }, { id: "asc" }],
        select: { id: true },
      });

      if (replacement) {
        await prisma.paymentMethod.update({
          where: { id: replacement.id },
          data: { isDefault: true },
        });
      }
    }

    sendSuccess(res, { success: true });
  }),
);
