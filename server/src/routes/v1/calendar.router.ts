import { Router } from "express";
import { z } from "zod";

import { authRequired, notBanned } from "../../middlewares/auth.js";
import { validateQuery } from "../../middlewares/validate.js";
import { sendSuccess } from "../../lib/http.js";
import { prisma } from "../../lib/prisma.js";
import { asyncHandler } from "../../utils/async-handler.js";

const calendarQuerySchema = z.object({
  month: z.string().regex(/^\d{4}-\d{2}$/).optional(),
});

const makeDate = (year: number, month: number, day: number) => new Date(year, month, day, 12, 0, 0, 0);
const stripTime = (date: Date) => makeDate(date.getFullYear(), date.getMonth(), date.getDate());

const addMonthsClamped = (date: Date, months: number) => {
  const year = date.getFullYear();
  const month = date.getMonth();
  const day = date.getDate();
  const targetFirst = makeDate(year, month + months, 1);
  const lastDay = new Date(targetFirst.getFullYear(), targetFirst.getMonth() + 1, 0, 12, 0, 0, 0).getDate();
  return makeDate(targetFirst.getFullYear(), targetFirst.getMonth(), Math.min(day, lastDay));
};

const toIsoDate = (date: Date) => {
  const year = date.getFullYear();
  const month = `${date.getMonth() + 1}`.padStart(2, "0");
  const day = `${date.getDate()}`.padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const parseMonthParam = (input: string | undefined): Date | null => {
  if (!input || !/^\d{4}-\d{2}$/.test(input)) {
    return null;
  }

  const [yearRaw, monthRaw] = input.split("-");
  const year = Number(yearRaw);
  const month = Number(monthRaw);
  if (!Number.isInteger(year) || !Number.isInteger(month) || month < 1 || month > 12) {
    return null;
  }
  return makeDate(year, month - 1, 1);
};

export const calendarRouter = Router();

calendarRouter.get(
  "/events",
  authRequired,
  notBanned,
  validateQuery(calendarQuerySchema),
  asyncHandler(async (req, res) => {
    const query = req.query as unknown as z.infer<typeof calendarQuerySchema>;
    const userId = req.authUser!.id;
    const now = stripTime(new Date());
    const monthStart = parseMonthParam(query.month) ?? makeDate(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = makeDate(monthStart.getFullYear(), monthStart.getMonth() + 1, 1);

    const subscriptions = await prisma.userSubscription.findMany({
      where: { userId },
      include: {
        commonSubscription: {
          select: {
            price: true,
            period: true,
            name: true,
            imgLink: true,
          },
        },
      },
    });

    const events: Array<{
      id: string;
      subscriptionId: string;
      typeName: string;
      typeIcon: string;
      paymentCardLabel: string;
      amount: number;
      date: Date;
      isoDate: string;
    }> = [];

    for (const subscription of subscriptions) {
      const period = Math.max(subscription.commonSubscription.period, 1);
      let occurrence = stripTime(subscription.nextPaymentAt);
      let safety = 0;

      while (occurrence < monthStart && safety < 240) {
        occurrence = addMonthsClamped(occurrence, period);
        safety += 1;
      }

      while (occurrence >= monthStart && occurrence < monthEnd && safety < 260) {
        events.push({
          id: `${subscription.id}-${toIsoDate(occurrence)}`,
          subscriptionId: subscription.id,
          typeName: subscription.commonSubscription.name,
          typeIcon: subscription.commonSubscription.imgLink,
          paymentCardLabel: subscription.paymentCardLabel,
          amount: Number(subscription.commonSubscription.price.toString()),
          date: occurrence,
          isoDate: toIsoDate(occurrence),
        });
        occurrence = addMonthsClamped(occurrence, period);
        safety += 1;
      }
    }

    events.sort((a, b) => a.date.getTime() - b.date.getTime() || a.typeName.localeCompare(b.typeName, "ru-RU"));

    const eventsByDay: Record<string, typeof events> = {};
    for (const event of events) {
      if (!eventsByDay[event.isoDate]) {
        eventsByDay[event.isoDate] = [];
      }
      eventsByDay[event.isoDate].push(event);
    }

    sendSuccess(res, {
      month: `${monthStart.getFullYear()}-${`${monthStart.getMonth() + 1}`.padStart(2, "0")}`,
      monthTotal: events.reduce((sum, event) => sum + event.amount, 0),
      monthUniqueSubscriptions: new Set(events.map((event) => event.subscriptionId)).size,
      events,
      eventsByDay,
    });
  }),
);
