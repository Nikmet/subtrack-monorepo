import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateQuery } from "../../middlewares/validate.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";

const notificationsQuerySchema = z.object({
    limit: z.coerce.number().int().min(1).max(200).optional().default(80)
});

export const notificationsRouter = Router();

notificationsRouter.get(
    "/",
    authRequired,
    notBanned,
    validateQuery(notificationsQuerySchema),
    asyncHandler(async (req, res) => {
        const userId = req.authUser!.id;
        const query = req.query as unknown as z.infer<typeof notificationsQuerySchema>;

        const notifications = await prisma.notification.findMany({
            where: { userId },
            orderBy: { createdAt: "desc" },
            take: query.limit
        });

        sendSuccess(res, notifications);
    })
);

notificationsRouter.delete(
    "/",
    authRequired,
    notBanned,
    asyncHandler(async (req, res) => {
        const userId = req.authUser!.id;
        await prisma.notification.deleteMany({
            where: { userId }
        });
        sendSuccess(res, { success: true });
    })
);
