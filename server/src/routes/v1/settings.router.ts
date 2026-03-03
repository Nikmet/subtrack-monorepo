import { compare, hash } from "bcryptjs";
import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateBody } from "../../middlewares/validate.js";
import { AppError } from "../../lib/app-error.js";
import { formatPaymentMethodLabel } from "../../lib/formatters.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";

const updateProfileBodySchema = z.object({
  name: z.string().trim().min(2),
  email: z.string().email(),
  avatarLink: z.string().url().optional().nullable(),
});

const changePasswordBodySchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8),
  confirmPassword: z.string().min(1),
});

const getInitials = (name: string) =>
  name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");

export const settingsRouter = Router();

settingsRouter.get(
  "/",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUnique({
      where: { id: req.authUser!.id },
      include: {
        paymentMethods: {
          where: { isDefault: true },
          orderBy: [{ createdAt: "asc" }, { id: "asc" }],
          take: 1,
          select: {
            cardNumber: true,
            bank: { select: { name: true } },
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

settingsRouter.get(
  "/profile",
  authRequired,
  notBanned,
  asyncHandler(async (req, res) => {
    const currentUser = await prisma.user.findUnique({
      where: { id: req.authUser!.id },
      select: {
        name: true,
        email: true,
        avatarLink: true,
      },
    });

    sendSuccess(res, currentUser);
  }),
);

settingsRouter.patch(
  "/profile",
  authRequired,
  notBanned,
  validateBody(updateProfileBodySchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const body = req.body as z.infer<typeof updateProfileBodySchema>;
    const email = body.email.trim().toLowerCase();
    const avatarLink = body.avatarLink?.trim() || null;

    const existed = await prisma.user.findFirst({
      where: {
        email,
        id: {
          not: user.id,
        },
      },
      select: { id: true },
    });

    if (existed) {
      throw new AppError({
        status: 409,
        code: "CONFLICT",
        message: "Пользователь с таким email уже существует.",
      });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: {
        name: body.name.trim(),
        email,
        avatarLink,
      },
    });

    sendSuccess(res, { success: true });
  }),
);

settingsRouter.patch(
  "/security/password",
  authRequired,
  notBanned,
  validateBody(changePasswordBodySchema),
  asyncHandler(async (req, res) => {
    const user = req.authUser!;
    const body = req.body as z.infer<typeof changePasswordBodySchema>;

    if (body.newPassword !== body.confirmPassword) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Пароли не совпадают.",
      });
    }

    const dbUser = await prisma.user.findUnique({
      where: { id: user.id },
      select: { password: true },
    });

    if (!dbUser) {
      throw new AppError({
        status: 404,
        code: "NOT_FOUND",
        message: "Пользователь не найден.",
      });
    }

    const isCurrentValid = await compare(body.currentPassword, dbUser.password);
    if (!isCurrentValid) {
      throw new AppError({
        status: 400,
        code: "BAD_REQUEST",
        message: "Текущий пароль введен неверно.",
      });
    }

    const passwordHash = await hash(body.newPassword, 10);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: passwordHash,
      },
    });

    sendSuccess(res, { success: true });
  }),
);
