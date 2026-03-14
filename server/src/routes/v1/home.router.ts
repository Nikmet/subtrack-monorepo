import { Router } from "express";
import { z } from "zod";

import { loadCbrCurrencyRates, convertRubAmount, homeCurrencyValues, type HomeCurrency } from "../../lib/currency.js";
import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateQuery } from "../../middlewares/validate.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { getSubscriptionCategoryLabel, OTHER_CATEGORY_NAME } from "../../lib/subscription-constants.js";
import { asyncHandler } from "../../utils/async-handler.js";

const getInitials = (name: string) =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

const toMonthlyAmount = (price: number, period: number) => {
  const safePeriod = Math.max(period, 1);
  return price / safePeriod;
};

const homeQuerySchema = z.object({
  currency: z.enum(homeCurrencyValues).optional().default("rub"),
});

const buildCategoryStats = (items: Array<{ categoryName: string; monthlyPrice: number }>) => {
  const grouped = new Map<string, number>();

  for (const item of items) {
    const key = item.categoryName.trim() || OTHER_CATEGORY_NAME;
    grouped.set(key, (grouped.get(key) ?? 0) + item.monthlyPrice);
  }

  const sorted = [...grouped.entries()]
    .map(([name, amount]) => ({ name, amount }))
    .sort((a, b) => b.amount - a.amount);

  let limited = sorted;

  if (sorted.length > 4) {
    const topThree = sorted.slice(0, 3);
    const tailAmount = sorted.slice(3).reduce((sum, item) => sum + item.amount, 0);

    const otherIndex = topThree.findIndex((item) => item.name === OTHER_CATEGORY_NAME);
    if (otherIndex >= 0) {
      topThree[otherIndex] = {
        ...topThree[otherIndex],
        amount: topThree[otherIndex].amount + tailAmount,
      };
      limited = topThree;
    } else {
      limited = [...topThree, { name: OTHER_CATEGORY_NAME, amount: tailAmount }];
    }
  }

  const total = limited.reduce((sum, item) => sum + item.amount, 0);
  const stats = limited.map((item) => ({
    name: item.name,
    amount: item.amount,
    share: total > 0 ? (item.amount / total) * 100 : 0,
  }));

  return { stats, total };
};

const buildCardStats = (items: Array<{ paymentCardLabel: string; monthlyPrice: number }>) => {
  const grouped = new Map<string, { amount: number; subscriptionsCount: number }>();

  for (const item of items) {
    const key = item.paymentCardLabel.trim() || "Автосписание";
    const current = grouped.get(key) ?? { amount: 0, subscriptionsCount: 0 };
    grouped.set(key, {
      amount: current.amount + item.monthlyPrice,
      subscriptionsCount: current.subscriptionsCount + 1,
    });
  }

  const sorted = [...grouped.entries()]
    .map(([label, value]) => ({
      label,
      amount: value.amount,
      subscriptionsCount: value.subscriptionsCount,
    }))
    .sort((a, b) => b.amount - a.amount || b.subscriptionsCount - a.subscriptionsCount);

  const limited = sorted.slice(0, 4);
  const total = limited.reduce((sum, item) => sum + item.amount, 0);
  const stats = limited.map((item) => ({
    label: item.label,
    amount: item.amount,
    subscriptionsCount: item.subscriptionsCount,
    share: total > 0 ? (item.amount / total) * 100 : 0,
  }));

  return { stats, total };
};

export const homeRouter = Router();

homeRouter.get(
  "/",
  authRequired,
  notBanned,
  validateQuery(homeQuerySchema),
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const query = req.query as unknown as z.infer<typeof homeQuerySchema>;
    const requestedCurrency = query.currency;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { name: true, avatarLink: true },
    });

    if (!user) {
      sendSuccess(res, null);
      return;
    }

    const userSubscriptions = await prisma.userSubscription.findMany({
      where: { userId },
      orderBy: [{ nextPaymentAt: "asc" }, { id: "asc" }],
      include: {
        commonSubscription: true,
      },
    });

    let effectiveCurrency: HomeCurrency = requestedCurrency;
    let currencyFallback = false;
    let rates: Awaited<ReturnType<typeof loadCbrCurrencyRates>> | null = null;

    if (requestedCurrency !== "rub") {
      try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 5000);

        try {
          rates = await loadCbrCurrencyRates(controller.signal);
        } finally {
          clearTimeout(timeout);
        }
      } catch {
        effectiveCurrency = "rub";
        currencyFallback = true;
      }
    }

    const subscriptions = userSubscriptions.map((item) => {
      const priceRub = Number(item.commonSubscription.price.toString());
      const monthlyPriceRub = toMonthlyAmount(priceRub, item.commonSubscription.period);

      return {
        id: item.id,
        price: rates ? convertRubAmount(priceRub, effectiveCurrency, rates) : priceRub,
        monthlyPrice: rates
          ? convertRubAmount(monthlyPriceRub, effectiveCurrency, rates)
          : monthlyPriceRub,
        period: item.commonSubscription.period,
        nextPaymentAt: item.nextPaymentAt,
        paymentMethodId: item.paymentMethodId,
        paymentCardLabel: item.paymentCardLabel,
        typeName: item.commonSubscription.name,
        typeImage: item.commonSubscription.imgLink ?? "",
        categoryName: getSubscriptionCategoryLabel(item.commonSubscription.category),
      };
    });

    const monthlyTotal = subscriptions.reduce((sum, item) => sum + item.monthlyPrice, 0);
    const { stats, total } = buildCategoryStats(subscriptions);
    const { stats: cardStats, total: cardTotal } = buildCardStats(
      userSubscriptions.map((item) => ({
        paymentCardLabel: item.paymentCardLabel,
        monthlyPrice: rates
          ? convertRubAmount(
              toMonthlyAmount(
                Number(item.commonSubscription.price.toString()),
                item.commonSubscription.period,
              ),
              effectiveCurrency,
              rates,
            )
          : toMonthlyAmount(
              Number(item.commonSubscription.price.toString()),
              item.commonSubscription.period,
            ),
      })),
    );

    sendSuccess(res, {
      currency: effectiveCurrency,
      currencyFallback,
      userInitials: getInitials(user.name),
      userAvatarLink: user.avatarLink,
      monthlyTotal,
      subscriptionsCount: subscriptions.length,
      subscriptions,
      categoryStats: stats,
      categoryTotal: total,
      cardStats,
      cardTotal,
    });
  }),
);
