import { Router } from "express";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";

export const banksRouter = Router();

banksRouter.get(
  "/",
  authRequired,
  notBanned,
  asyncHandler(async (_req, res) => {
    const banks = await prisma.bank.findMany({
      orderBy: [{ name: "asc" }, { id: "asc" }],
      select: {
        id: true,
        name: true,
        iconLink: true,
      },
    });

    sendSuccess(res, banks);
  }),
);
