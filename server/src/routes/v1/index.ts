import { Router } from "express";

import { adminRouter } from "./admin.router.js";
import { authRouter } from "./auth.router.js";
import { banksRouter } from "./banks.router.js";
import { calendarRouter } from "./calendar.router.js";
import { catalogRouter } from "./catalog.router.js";
import { commonSubscriptionsRouter } from "./common-subscriptions.router.js";
import { homeRouter } from "./home.router.js";
import { notificationsRouter } from "./notifications.router.js";
import { paymentMethodsRouter } from "./payment-methods.router.js";
import { profileRouter } from "./profile.router.js";
import { settingsRouter } from "./settings.router.js";
import { uploadsRouter } from "./uploads.router.js";
import { userSubscriptionsRouter } from "./user-subscriptions.router.js";

export const v1Router = Router();

v1Router.use("/auth", authRouter);
v1Router.use("/uploads", uploadsRouter);
v1Router.use("/home", homeRouter);
v1Router.use("/catalog", catalogRouter);
v1Router.use("/user-subscriptions", userSubscriptionsRouter);
v1Router.use("/common-subscriptions", commonSubscriptionsRouter);
v1Router.use("/notifications", notificationsRouter);
v1Router.use("/payment-methods", paymentMethodsRouter);
v1Router.use("/settings", settingsRouter);
v1Router.use("/banks", banksRouter);
v1Router.use("/calendar", calendarRouter);
v1Router.use("/profile", profileRouter);
v1Router.use("/admin", adminRouter);
