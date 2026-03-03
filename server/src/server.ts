import { env } from "./config/env.js";
import { logger } from "./lib/logger.js";
import { app } from "./app.js";

const port = env.PORT;

process.on("unhandledRejection", (reason) => {
  logger.error("Unhandled promise rejection", { reason });
});

process.on("uncaughtException", (error) => {
  logger.error("Uncaught exception", { error });
});

app.listen(port, () => {
  logger.info("SubTrack backend started", { port, nodeEnv: env.NODE_ENV });
});
