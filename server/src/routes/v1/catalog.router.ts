import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned, optionalAuth } from "../../middlewares/auth.js";
import { validateQuery, validateParams } from "../../middlewares/validate.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import {
  getSubscriptionCategoryLabel,
  isSubscriptionCategory,
  SUBSCRIPTION_CATEGORIES,
} from "../../lib/subscription-constants.js";
import { asyncHandler } from "../../utils/async-handler.js";

type SearchSubscriptionItem = {
  id: string;
  name: string;
  imgLink: string;
  categoryName: string;
  categorySlug: string;
  suggestedMonthlyPrice: number | null;
  subscribersCount: number;
  price: number;
  period: number;
};

const catalogQuerySchema = z.object({
  q: z.string().optional().default(""),
  category: z.string().optional().default(""),
  page: z.coerce.number().int().min(1).optional().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).optional().default(24),
});

const popularQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).optional().default(8),
});

const searchQuerySchema = z.object({
  q: z.string().optional().default(""),
  category: z.string().optional().default(""),
});

const categoryQuerySchema = z.object({
  category: z.string().optional().default(""),
});

const catalogIdParamsSchema = z.object({
  id: z.string().uuid(),
});

const toMonthlyAmount = (price: { toString(): string }, period: number) => {
  const numericPrice = Number(price.toString());
  const safePeriod = Math.max(period, 1);
  return numericPrice / safePeriod;
};

async function getCatalog(): Promise<SearchSubscriptionItem[]> {
  const subscriptions = await prisma.commonSubscription.findMany({
    where: {
      status: "PUBLISHED",
    },
    select: {
      id: true,
      name: true,
      imgLink: true,
      category: true,
      price: true,
      period: true,
      subscriptions: {
        where: {
          user: {
            isBanned: false,
          },
        },
        select: { id: true },
      },
    },
  });

  return subscriptions
    .map((item) => {
      const price = Number(item.price.toString());
      const period = Math.max(item.period, 1);

      return {
        id: item.id,
        name: item.name.trim(),
        imgLink: item.imgLink.trim(),
        categorySlug: item.category,
        categoryName: getSubscriptionCategoryLabel(item.category),
        price,
        period,
        suggestedMonthlyPrice: toMonthlyAmount(item.price, period),
        subscribersCount: item.subscriptions.length,
      } satisfies SearchSubscriptionItem;
    })
    .filter((item) => item.name.length > 0)
    .sort(
      (a, b) =>
        b.subscribersCount - a.subscribersCount ||
        a.name.localeCompare(b.name, "ru-RU", { sensitivity: "base" }),
    );
}

export const catalogRouter = Router();

catalogRouter.get(
  "/categories",
  authRequired,
  notBanned,
  asyncHandler(async (_req, res) => {
    const services = await getCatalog();
    const categoriesInUse = new Set(services.map((item) => item.categorySlug));

    const categories = SUBSCRIPTION_CATEGORIES.filter((item) => categoriesInUse.has(item.value)).map(
      (item) => ({
        id: item.value,
        slug: item.value,
        name: item.label,
      }),
    );
    sendSuccess(res, categories);
  }),
);

catalogRouter.get(
  "/popular",
  authRequired,
  notBanned,
  validateQuery(popularQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof popularQuerySchema>;
    const services = await getCatalog();
    sendSuccess(res, services.slice(0, query.limit));
  }),
);

catalogRouter.get(
  "/search",
  authRequired,
  notBanned,
  validateQuery(searchQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof searchQuerySchema>;
    const normalizedQuery = query.q.trim().toLocaleLowerCase("ru-RU");
    const services = await getCatalog();

    const byCategory = isSubscriptionCategory(query.category)
      ? services.filter((item) => item.categorySlug === query.category)
      : services;

    const filtered =
      normalizedQuery.length === 0
        ? byCategory
        : byCategory.filter((item) => {
            const name = item.name.toLocaleLowerCase("ru-RU");
            const categoryName = item.categoryName.toLocaleLowerCase("ru-RU");
            return name.includes(normalizedQuery) || categoryName.includes(normalizedQuery);
          });

    sendSuccess(res, filtered.slice(0, 30));
  }),
);

catalogRouter.get(
  "/",
  authRequired,
  notBanned,
  validateQuery(catalogQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof catalogQuerySchema>;
    const normalizedQuery = query.q.trim().toLocaleLowerCase("ru-RU");
    const hasCategory = isSubscriptionCategory(query.category);
    const safePageSize = Math.max(Math.trunc(query.pageSize), 1);
    const catalog = await getCatalog();

    const filteredByCategory = hasCategory
      ? catalog.filter((item) => item.categorySlug === query.category)
      : catalog;

    const filtered =
      normalizedQuery.length === 0
        ? filteredByCategory
        : filteredByCategory.filter((item) => {
            const name = item.name.toLocaleLowerCase("ru-RU");
            const categoryName = item.categoryName.toLocaleLowerCase("ru-RU");
            return name.includes(normalizedQuery) || categoryName.includes(normalizedQuery);
          });

    const total = filtered.length;
    const totalPages = Math.max(Math.ceil(total / safePageSize), 1);
    const safePage = Math.min(Math.max(Math.trunc(query.page), 1), totalPages);
    const startIndex = (safePage - 1) * safePageSize;
    const items = filtered.slice(startIndex, startIndex + safePageSize);

    sendSuccess(res, {
      items,
      total,
      totalPages,
      page: safePage,
      pageSize: safePageSize,
    });
  }),
);

catalogRouter.get(
  "/:id",
  optionalAuth,
  validateParams(catalogIdParamsSchema),
  validateQuery(categoryQuerySchema),
  asyncHandler(async (req, res) => {
    const params = req.params as z.infer<typeof catalogIdParamsSchema>;
    const includeUnpublishedForAdmin = req.authUser?.role === "ADMIN";

    const item = await prisma.commonSubscription.findUnique({
      where: { id: params.id },
      select: {
        id: true,
        name: true,
        imgLink: true,
        category: true,
        price: true,
        period: true,
        status: true,
        subscriptions: {
          where: {
            user: {
              isBanned: false,
            },
          },
          select: { id: true },
        },
      },
    });

    if (!item) {
      sendSuccess(res, null);
      return;
    }

    if (item.status !== "PUBLISHED" && !includeUnpublishedForAdmin) {
      sendSuccess(res, null);
      return;
    }

    const period = Math.max(item.period, 1);

    sendSuccess(res, {
      id: item.id,
      name: item.name.trim(),
      imgLink: item.imgLink.trim(),
      categorySlug: item.category,
      categoryName: getSubscriptionCategoryLabel(item.category),
      price: Number(item.price.toString()),
      period,
      suggestedMonthlyPrice: toMonthlyAmount(item.price, period),
      subscribersCount: item.subscriptions.length,
    });
  }),
);
