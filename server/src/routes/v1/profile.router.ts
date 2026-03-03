import { Router } from "express";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { formatPaymentMethodLabel } from "../../lib/formatters.js";
import { asyncHandler } from "../../utils/async-handler.js";

const getInitials = (name: string) =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

export const profileRouter = Router();

profileRouter.get(
  "/",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        subscriptions: {
          include: {
            commonSubscription: {
              select: {
                price: true,
                period: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      sendSuccess(res, null);
      return;
    }

    const monthlyTotal = user.subscriptions.reduce((sum, item) => {
      const price = Number(item.commonSubscription.price.toString());
      const period = Math.max(item.commonSubscription.period, 1);
      return sum + price / period;
    }, 0);

    sendSuccess(res, {
      name: user.name,
      email: user.email,
      initials: getInitials(user.name),
      avatarLink: user.avatarLink,
      yearlyTotal: Math.round(monthlyTotal * 12),
      activeSubscriptions: user.subscriptions.length,
    });
  }),
);

profileRouter.get(
  "/settings",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const userId = req.authUser!.id;
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        paymentMethods: {
          where: { isDefault: true },
          orderBy: [{ createdAt: "asc" }, { id: "asc" }],
          take: 1,
          select: {
            cardNumber: true,
            bank: {
              select: {
                name: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      sendSuccess(res, null);
      return;
    }

    sendSuccess(res, {
      name: user.name,
      email: user.email,
      initials: getInitials(user.name),
      avatarLink: user.avatarLink,
      defaultPaymentMethodLabel: user.paymentMethods[0]
        ? formatPaymentMethodLabel(user.paymentMethods[0].bank.name, user.paymentMethods[0].cardNumber)
        : "Не указан",
      role: user.role,
    });
  }),
);
