import { Router } from "express";
import { z } from "zod";

import { adminRequired, authRequired, notBanned } from "../../middlewares/auth.js";
import { validateBody, validateParams, validateQuery } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { getSubscriptionCategoryLabel, isSubscriptionCategory } from "../../lib/subscription-constants.js";
import { asyncHandler } from "../../utils/async-handler.js";

const allowedPeriods = new Set([1, 3, 6, 12]);

const moderationQuerySchema = z.object({
  q: z.string().optional().default(""),
  category: z.string().optional().default(""),
  period: z.coerce.number().int().optional(),
});

const publishedQuerySchema = z.object({
  q: z.string().optional().default(""),
  category: z.string().optional().default(""),
  period: z.coerce.number().int().optional(),
});

const usersQuerySchema = z.object({
  q: z.string().optional().default(""),
  role: z.enum(["USER", "ADMIN", ""]).optional().default(""),
  ban: z.enum(["banned", "active", ""]).optional().default(""),
});

const idParamsSchema = z.object({
  id: z.string().uuid(),
});

const publishBodySchema = z.object({
  moderationComment: z.string().optional().nullable(),
});

const rejectBodySchema = z.object({
  reason: z.string().trim().min(1),
});

const updateSubscriptionBodySchema = z.object({
  name: z.string().trim().min(2),
  imgLink: z.string().optional().default(""),
  category: z.string().min(1),
  price: z.coerce.number().positive(),
  period: z.coerce.number().int(),
  moderationComment: z.string().optional().nullable(),
});

const banBodySchema = z.object({
  reason: z.string().trim().min(1),
});

const createBankBodySchema = z.object({
  name: z.string().trim().min(2),
  iconLink: z.string().trim().min(1),
});

const updateBankBodySchema = createBankBodySchema;

const createNotificationForUsers = async (
  userIds: string[],
  title: string,
  message: string,
  kind: string,
) => {
  if (userIds.length === 0) {
    return;
  }

  await prisma.notification.createMany({
    data: userIds.map((userId) => ({
      userId,
      kind,
      title,
      message,
    })),
  });
};

export const adminRouter = Router();

adminRouter.use(authRequired, notBanned, adminRequired);

adminRouter.get(
  "/moderation/subscriptions",
  validateQuery(moderationQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof moderationQuerySchema>;
    const where: Record<string, unknown> = {
      status: "PENDING",
    };

    if (isSubscriptionCategory(query.category)) {
      where.category = query.category;
    }

    if (query.period && allowedPeriods.has(query.period)) {
      where.period = query.period;
    }

    if (query.q) {
      where.OR = [
        { name: { contains: query.q, mode: "insensitive" } },
        { createdByUser: { name: { contains: query.q, mode: "insensitive" } } },
        { createdByUser: { email: { contains: query.q, mode: "insensitive" } } },
      ];
    }

    const pendingSubscriptions = await prisma.commonSubscription.findMany({
      where,
      orderBy: [{ createdAt: "asc" }, { id: "asc" }],
      select: {
        id: true,
        name: true,
        imgLink: true,
        category: true,
        price: true,
        period: true,
        createdByUser: {
          select: {
            name: true,
            email: true,
          },
        },
      },
      take: 200,
    });

    sendSuccess(
      res,
      pendingSubscriptions.map((item) => ({
        ...item,
        categoryName: getSubscriptionCategoryLabel(item.category),
        price: Number(item.price.toString()),
      })),
    );
  }),
);

adminRouter.post(
  "/moderation/subscriptions/:id/publish",
  validateParams(idParamsSchema),
  validateBody(publishBodySchema),
  asyncHandler(async (req, res) => {
    const admin = req.authUser!;
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof publishBodySchema>;

    const subscription = await prisma.commonSubscription.update({
      where: { id: params.id },
      data: {
        status: "PUBLISHED",
        moderatedByUserId: admin.id,
        moderatedAt: new Date(),
        moderationComment: body.moderationComment?.trim() || null,
      },
      select: {
        id: true,
        name: true,
        createdByUserId: true,
      },
    });

    if (subscription.createdByUserId) {
      await prisma.notification.create({
        data: {
          userId: subscription.createdByUserId,
          kind: "success",
          title: "Подписка опубликована",
          message: `Ваша заявка "${subscription.name}" прошла модерацию и опубликована.`,
        },
      });
    }

    sendSuccess(res, subscription);
  }),
);

adminRouter.post(
  "/moderation/subscriptions/:id/reject",
  validateParams(idParamsSchema),
  validateBody(rejectBodySchema),
  asyncHandler(async (req, res) => {
    const admin = req.authUser!;
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof rejectBodySchema>;

    const subscription = await prisma.commonSubscription.findUnique({
      where: { id: params.id },
      select: {
        id: true,
        name: true,
        status: true,
        createdByUserId: true,
      },
    });

    if (!subscription) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Подписка не найдена.",
      });
    }

    if (subscription.status !== "PENDING") {
      throw new AppError({
        status: 409,
        code: "CONFLICT",
        message: "Можно отклонить только подписку в статусе PENDING.",
      });
    }

    const updated = await prisma.commonSubscription.update({
      where: { id: subscription.id },
      data: {
        status: "REJECTED",
        moderatedByUserId: admin.id,
        moderatedAt: new Date(),
        moderationComment: body.reason,
      },
      select: {
        id: true,
        name: true,
        status: true,
      },
    });

    if (subscription.createdByUserId) {
      await prisma.notification.create({
        data: {
          userId: subscription.createdByUserId,
          kind: "warning",
          title: "Заявка отклонена",
          message: `Подписка "${subscription.name}" отклонена модератором. Причина: ${body.reason}.`,
        },
      });
    }

    sendSuccess(res, updated);
  }),
);

adminRouter.get(
  "/published/subscriptions",
  validateQuery(publishedQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof publishedQuerySchema>;
    const where: Record<string, unknown> = {
      status: "PUBLISHED",
    };

    if (isSubscriptionCategory(query.category)) {
      where.category = query.category;
    }

    if (query.period && allowedPeriods.has(query.period)) {
      where.period = query.period;
    }

    if (query.q) {
      where.OR = [{ name: { contains: query.q, mode: "insensitive" } }];
    }

    const publishedSubscriptions = await prisma.commonSubscription.findMany({
      where,
      orderBy: [{ updatedAt: "desc" }, { id: "asc" }],
      select: {
        id: true,
        name: true,
        imgLink: true,
        category: true,
        price: true,
        period: true,
        subscriptions: {
          select: {
            id: true,
          },
        },
      },
      take: 250,
    });

    sendSuccess(
      res,
      publishedSubscriptions.map((item) => ({
        ...item,
        categoryName: getSubscriptionCategoryLabel(item.category),
        subscribersCount: item.subscriptions.length,
        price: Number(item.price.toString()),
      })),
    );
  }),
);

adminRouter.get(
  "/subscriptions/:id",
  validateParams(idParamsSchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof idParamsSchema>;
    const item = await prisma.commonSubscription.findUnique({
      where: { id: params.id },
      select: {
        id: true,
        name: true,
        imgLink: true,
        category: true,
        price: true,
        period: true,
        moderationComment: true,
        status: true,
      },
    });
    sendSuccess(
      res,
      item
        ? {
            ...item,
            price: Number(item.price.toString()),
          }
        : null,
    );
  }),
);

adminRouter.patch(
  "/subscriptions/:id",
  validateParams(idParamsSchema),
  validateBody(updateSubscriptionBodySchema),
  asyncHandler(async (req, res) => {
    const admin = req.authUser!;
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof updateSubscriptionBodySchema>;

    if (!allowedPeriods.has(body.period)) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Некорректный период.",
      });
    }

    if (!isSubscriptionCategory(body.category)) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Некорректная категория.",
      });
    }

    const updated = await prisma.commonSubscription.update({
      where: { id: params.id },
      data: {
        name: body.name,
        imgLink: body.imgLink.trim(),
        category: body.category,
        price: body.price,
        period: body.period,
        moderatedByUserId: admin.id,
        moderatedAt: new Date(),
        moderationComment: body.moderationComment?.trim() || null,
      },
      select: {
        id: true,
        name: true,
      },
    });

    sendSuccess(res, updated);
  }),
);

adminRouter.delete(
  "/subscriptions/:id",
  validateParams(idParamsSchema),
  validateBody(rejectBodySchema),
  asyncHandler(async (req, res) => {
    const admin = req.authUser!;
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof rejectBodySchema>;

    const subscription = await prisma.commonSubscription.findUnique({
      where: { id: params.id },
      select: {
        id: true,
        name: true,
        status: true,
        createdByUserId: true,
        subscriptions: {
          select: {
            userId: true,
          },
        },
      },
    });

    if (!subscription) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Подписка не найдена.",
      });
    }

    if (subscription.status === "PENDING") {
      await prisma.commonSubscription.update({
        where: { id: subscription.id },
        data: {
          status: "REJECTED",
          moderatedByUserId: admin.id,
          moderatedAt: new Date(),
          moderationComment: body.reason,
        },
      });

      if (subscription.createdByUserId) {
        await prisma.notification.create({
          data: {
            userId: subscription.createdByUserId,
            kind: "warning",
            title: "Заявка отклонена",
            message: `Подписка "${subscription.name}" отклонена модератором. Причина: ${body.reason}.`,
          },
        });
      }

      sendSuccess(res, { status: "REJECTED", id: subscription.id });
      return;
    }

    const affectedUserIds = [...new Set(subscription.subscriptions.map((item) => item.userId))];
    await prisma.commonSubscription.delete({
      where: {
        id: params.id,
      },
    });

    if (subscription.status === "PUBLISHED") {
      await createNotificationForUsers(
        affectedUserIds,
        "Подписка удалена",
        `Подписка "${subscription.name}" снята с публикации администратором. Причина: ${body.reason}.`,
        "warning",
      );
    }

    sendSuccess(res, { status: "DELETED", id: subscription.id });
  }),
);

adminRouter.get(
  "/users",
  validateQuery(usersQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof usersQuerySchema>;
    const where: Record<string, unknown> = {};

    if (query.q) {
      where.OR = [
        { name: { contains: query.q, mode: "insensitive" } },
        { email: { contains: query.q, mode: "insensitive" } },
      ];
    }

    if (query.role === "USER" || query.role === "ADMIN") {
      where.role = query.role;
    }

    if (query.ban === "banned") {
      where.isBanned = true;
    }

    if (query.ban === "active") {
      where.isBanned = false;
    }

    const users = await prisma.user.findMany({
      where,
      orderBy: [{ role: "desc" }, { id: "desc" }],
      select: {
        id: true,
        name: true,
        avatarLink: true,
        email: true,
        role: true,
        isBanned: true,
        banReason: true,
        subscriptions: {
          select: {
            id: true,
          },
        },
      },
      take: 250,
    });

    sendSuccess(
      res,
      users.map((user) => ({
        ...user,
        subscriptionsCount: user.subscriptions.length,
      })),
    );
  }),
);

adminRouter.post(
  "/users/:id/ban",
  validateParams(idParamsSchema),
  validateBody(banBodySchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof banBodySchema>;

    const target = await prisma.user.findUnique({
      where: { id: params.id },
      select: { id: true, role: true },
    });

    if (!target || target.role === "ADMIN") {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Нельзя заблокировать этого пользователя.",
      });
    }

    await prisma.user.update({
      where: { id: target.id },
      data: {
        isBanned: true,
        banReason: body.reason,
        bannedAt: new Date(),
      },
    });

    sendSuccess(res, { success: true });
  }),
);

adminRouter.post(
  "/users/:id/unban",
  validateParams(idParamsSchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof idParamsSchema>;
    await prisma.user.update({
      where: { id: params.id },
      data: {
        isBanned: false,
        banReason: null,
        bannedAt: null,
      },
    });
    sendSuccess(res, { success: true });
  }),
);

adminRouter.get(
  "/banks",
  asyncHandler(async (_req, res) => {
    const banks = await prisma.bank.findMany({
      orderBy: [{ name: "asc" }, { id: "asc" }],
      select: {
        id: true,
        name: true,
        iconLink: true,
        _count: {
          select: {
            paymentMethods: true,
          },
        },
      },
    });
    sendSuccess(res, banks);
  }),
);

adminRouter.post(
  "/banks",
  validateBody(createBankBodySchema),
  asyncHandler(async (req, res) => {
    const body = req.body as z.infer<typeof createBankBodySchema>;
    const created = await prisma.bank.create({
      data: {
        name: body.name,
        iconLink: body.iconLink,
      },
    });
    sendSuccess(res, created, {}, 201);
  }),
);

adminRouter.patch(
  "/banks/:id",
  validateParams(idParamsSchema),
  validateBody(updateBankBodySchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof idParamsSchema>;
    const body = req.body as z.infer<typeof updateBankBodySchema>;
    const updated = await prisma.bank.update({
      where: { id: params.id },
      data: {
        name: body.name,
        iconLink: body.iconLink,
      },
    });
    sendSuccess(res, updated);
  }),
);

adminRouter.delete(
  "/banks/:id",
  validateParams(idParamsSchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof idParamsSchema>;
    const bank = await prisma.bank.findUnique({
      where: { id: params.id },
      select: {
        id: true,
        _count: {
          select: {
            paymentMethods: true,
          },
        },
      },
    });

    if (!bank) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Банк не найден.",
      });
    }

    if (bank._count.paymentMethods > 0) {
      throw new AppError({
        status: 409,
        code: "CONFLICT",
        message: "Нельзя удалить банк, который используется в способах оплаты.",
      });
    }

    await prisma.bank.delete({
      where: { id: bank.id },
    });

    sendSuccess(res, { success: true });
  }),
);
