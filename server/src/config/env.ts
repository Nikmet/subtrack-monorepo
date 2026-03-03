import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
    NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
    LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
    PORT: z.coerce.number().int().positive().default(4000),
    CORS_ORIGIN: z.string().default("http://localhost:3000"),
    AUTH_SECRET: z.string().min(16),
    ACCESS_TOKEN_TTL_MINUTES: z.coerce.number().int().positive().default(15),
    REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
    AUTH_ACCESS_COOKIE_NAME: z.string().default("subtrack_access"),
    AUTH_REFRESH_COOKIE_NAME: z.string().default("subtrack_refresh"),
    ADMIN_BOOTSTRAP_EMAIL: z.string().email().default("metlov.nm@yandex.ru"),
    POSTGRES_PRISMA_URL: z.string().optional(),
    DB_DATABASE_URL: z.string().optional()
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
    console.error("Invalid backend environment variables", parsed.error.flatten().fieldErrors);
    process.exit(1);
}

export const env = parsed.data;

export const prismaConnectionString =
    env.POSTGRES_PRISMA_URL ?? env.DB_DATABASE_URL ?? "postgresql://subtrack:subtrack@localhost:5432/subtrack";
