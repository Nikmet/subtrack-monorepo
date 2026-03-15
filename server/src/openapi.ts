import {
  OpenApiGeneratorV31,
  OpenAPIRegistry,
  extendZodWithOpenApi
} from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

extendZodWithOpenApi(z);

const registry = new OpenAPIRegistry();

const metaSchema = z.record(z.string(), z.unknown()).default({});

const apiErrorSchema = z.object({
    error: z.object({
        code: z.string(),
        message: z.string(),
        details: z.record(z.string(), z.unknown()).optional()
    }),
    requestId: z.string().optional()
});

const unknownSuccessSchema = z.object({
    data: z.unknown(),
    meta: metaSchema
});

const authTokenPairSchema = z.object({
    accessToken: z.string(),
    refreshToken: z.string(),
    accessTokenExpiresInSec: z.number(),
    refreshTokenExpiresInSec: z.number()
});

const authUserSchema = z.object({
    id: z.string().uuid(),
    email: z.string().email(),
    role: z.enum(["USER", "ADMIN"]),
    isBanned: z.boolean(),
    banReason: z.string().nullable()
});

const authLoginBodySchema = z.object({
    email: z.string().email(),
    password: z.string().min(1),
    clientType: z.enum(["web", "mobile"]).optional().default("web")
});

const authRegisterBodySchema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    password: z.string().min(8),
    clientType: z.enum(["web", "mobile"]).optional().default("web")
});

const authRefreshBodySchema = z.object({
    refreshToken: z.string().optional(),
    clientType: z.enum(["web", "mobile"]).optional().default("web")
});

const authLogoutBodySchema = z.object({
    refreshToken: z.string().optional()
});

const createUserSubscriptionBodySchema = z.object({
    commonSubscriptionId: z.string().uuid(),
    nextPaymentAt: z.string().min(1),
    paymentMethodId: z.string().optional(),
    newPaymentMethodBankId: z.string().optional(),
    newPaymentMethodCardNumber: z.string().optional()
});

const updateUserSubscriptionBodySchema = z.object({
    nextPaymentAt: z.string().min(1),
    paymentMethodId: z.string().optional(),
    newPaymentMethodBankId: z.string().optional(),
    newPaymentMethodCardNumber: z.string().optional()
});

const createCommonSubscriptionBodySchema = z.object({
    name: z.string().min(2),
    imgLink: z.string().url().or(z.string().min(1)),
    category: z.string().min(1),
    price: z.number().positive(),
    period: z.number().int().positive()
});

const paymentMethodBodySchema = z.object({
    bankId: z.string().uuid(),
    cardNumber: z.string().min(4),
    isDefault: z.boolean().optional()
});

const paymentMethodRenameBodySchema = z.object({
    bankId: z.string().uuid().optional(),
    cardNumber: z.string().min(4).optional()
});

const updateProfileBodySchema = z.object({
    name: z.string().min(2),
    email: z.string().email(),
    avatarLink: z.string().url().nullable().optional()
});

const updatePasswordBodySchema = z.object({
    currentPassword: z.string().min(1),
    newPassword: z.string().min(8),
    confirmPassword: z.string().min(1)
});

const publishBodySchema = z.object({
    moderationComment: z.string().nullable().optional()
});

const rejectBodySchema = z.object({
    reason: z.string().min(1)
});

const updateAdminSubscriptionBodySchema = z.object({
    name: z.string().min(2),
    imgLink: z.string().optional().default(""),
    category: z.string().min(1),
    price: z.number().positive(),
    period: z.number().int().positive(),
    moderationComment: z.string().nullable().optional()
});

const banBodySchema = z.object({
    reason: z.string().min(1)
});

const createBankBodySchema = z.object({
    name: z.string().min(2),
    iconLink: z.string().min(1)
});

const updateBankBodySchema = createBankBodySchema;

const homeQuerySchema = z.object({
    currency: z.enum(["rub", "usd", "eur"]).optional()
});

const authSuccessSchema = z.object({
    data: z.object({
        user: authUserSchema.nullable(),
        tokenPair: authTokenPairSchema.optional()
    }),
    meta: metaSchema
});

registry.register("ApiError", apiErrorSchema);
registry.register("UnknownSuccess", unknownSuccessSchema);
registry.register("AuthSuccess", authSuccessSchema);
registry.register("AuthLoginBody", authLoginBodySchema);
registry.register("AuthRegisterBody", authRegisterBodySchema);
registry.register("AuthRefreshBody", authRefreshBodySchema);
registry.register("AuthLogoutBody", authLogoutBodySchema);
registry.register("CreateUserSubscriptionBody", createUserSubscriptionBodySchema);
registry.register("UpdateUserSubscriptionBody", updateUserSubscriptionBodySchema);
registry.register("CreateCommonSubscriptionBody", createCommonSubscriptionBodySchema);
registry.register("PaymentMethodBody", paymentMethodBodySchema);
registry.register("PaymentMethodRenameBody", paymentMethodRenameBodySchema);
registry.register("UpdateProfileBody", updateProfileBodySchema);
registry.register("UpdatePasswordBody", updatePasswordBodySchema);
registry.register("PublishBody", publishBodySchema);
registry.register("RejectBody", rejectBodySchema);
registry.register("UpdateAdminSubscriptionBody", updateAdminSubscriptionBodySchema);
registry.register("BanBody", banBodySchema);
registry.register("CreateBankBody", createBankBodySchema);
registry.register("UpdateBankBody", updateBankBodySchema);

const successContent = {
    "application/json": {
        schema: unknownSuccessSchema
    }
} as const;

const errorContent = {
    "application/json": {
        schema: apiErrorSchema
    }
} as const;

const authSecurity: Array<Record<string, string[]>> = [{ bearerAuth: [] }, { sessionCookie: [] }];

function registerProtectedPath(config: {
    method: "get" | "post" | "patch" | "delete";
    path: string;
    summary: string;
    tags: string[];
    request?: any;
}) {
    registry.registerPath({
        ...config,
        security: authSecurity,
        responses: {
            200: { description: "OK", content: successContent },
            201: { description: "Created", content: successContent },
            400: { description: "Bad Request", content: errorContent },
            401: { description: "Unauthorized", content: errorContent },
            403: { description: "Forbidden", content: errorContent },
            404: { description: "Not Found", content: errorContent },
            409: { description: "Conflict", content: errorContent }
        }
    } as any);
}

registry.registerPath({
    method: "get",
    path: "/health",
    summary: "Liveness probe",
    tags: ["system"],
    responses: {
        200: {
            description: "OK",
            content: {
                "application/json": {
                    schema: z.object({ ok: z.boolean() })
                }
            }
        }
    }
});

registry.registerPath({
    method: "post",
    path: "/api/v1/auth/register",
    summary: "Register account",
    tags: ["auth"],
    request: {
        body: {
            content: {
                "application/json": { schema: authRegisterBodySchema }
            }
        }
    },
    responses: {
        200: { description: "OK", content: { "application/json": { schema: authSuccessSchema } } },
        409: { description: "Conflict", content: errorContent }
    }
});

registry.registerPath({
    method: "post",
    path: "/api/v1/auth/login",
    summary: "Login with email and password",
    tags: ["auth"],
    request: {
        body: {
            content: {
                "application/json": { schema: authLoginBodySchema }
            }
        }
    },
    responses: {
        200: { description: "OK", content: { "application/json": { schema: authSuccessSchema } } },
        401: { description: "Unauthorized", content: errorContent },
        403: { description: "Forbidden", content: errorContent }
    }
});

registry.registerPath({
    method: "post",
    path: "/api/v1/auth/refresh",
    summary: "Rotate refresh token and issue new session",
    tags: ["auth"],
    request: {
        body: {
            content: {
                "application/json": { schema: authRefreshBodySchema }
            }
        }
    },
    responses: {
        200: { description: "OK", content: { "application/json": { schema: authSuccessSchema } } },
        401: { description: "Unauthorized", content: errorContent }
    }
});

registry.registerPath({
    method: "post",
    path: "/api/v1/auth/logout",
    summary: "Logout current session",
    tags: ["auth"],
    request: {
        body: {
            content: {
                "application/json": { schema: authLogoutBodySchema }
            }
        }
    },
    responses: {
        200: { description: "OK", content: successContent }
    }
});

registry.registerPath({
    method: "get",
    path: "/api/v1/auth/me",
    summary: "Get current authenticated user",
    tags: ["auth"],
    security: authSecurity,
    responses: {
        200: { description: "OK", content: { "application/json": { schema: authSuccessSchema } } },
        401: { description: "Unauthorized", content: errorContent }
    }
});

registry.registerPath({
    method: "get",
    path: "/api/v1/downloads/android",
    summary: "Redirect to the current Android APK download",
    tags: ["downloads"],
    responses: {
        302: { description: "Redirect to APK file" },
        503: { description: "Service unavailable", content: errorContent }
    }
});

registerProtectedPath({ method: "post", path: "/api/v1/uploads/avatar", summary: "Upload avatar", tags: ["uploads"] });
registerProtectedPath({ method: "post", path: "/api/v1/uploads/icon", summary: "Upload icon", tags: ["uploads"] });

registerProtectedPath({
    method: "get",
    path: "/api/v1/home",
    summary: "Get home screen data",
    tags: ["home"],
    request: { query: homeQuerySchema }
});
registerProtectedPath({ method: "get", path: "/api/v1/profile", summary: "Get profile page data", tags: ["profile"] });
registerProtectedPath({
    method: "get",
    path: "/api/v1/profile/settings",
    summary: "Get profile settings data",
    tags: ["profile", "settings"]
});

registerProtectedPath({
    method: "get",
    path: "/api/v1/notifications",
    summary: "List notifications",
    tags: ["notifications"],
    request: { query: z.object({ limit: z.number().int().min(1).max(200).optional() }) }
});
registerProtectedPath({
    method: "delete",
    path: "/api/v1/notifications",
    summary: "Clear notifications",
    tags: ["notifications"]
});

registerProtectedPath({
    method: "get",
    path: "/api/v1/calendar/events",
    summary: "Get billing events for month",
    tags: ["calendar"],
    request: { query: z.object({ month: z.string().regex(/^\d{4}-\d{2}$/) }) }
});

registerProtectedPath({
    method: "get",
    path: "/api/v1/catalog/categories",
    summary: "List catalog categories",
    tags: ["catalog"]
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/catalog/popular",
    summary: "List popular subscriptions",
    tags: ["catalog"],
    request: { query: z.object({ limit: z.number().int().min(1).max(100).optional() }) }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/catalog/search",
    summary: "Search subscriptions",
    tags: ["catalog"],
    request: { query: z.object({ q: z.string().optional(), category: z.string().optional() }) }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/catalog",
    summary: "Catalog with pagination",
    tags: ["catalog"],
    request: {
        query: z.object({
            q: z.string().optional(),
            category: z.string().optional(),
            page: z.number().int().min(1).optional(),
            pageSize: z.number().int().min(1).max(100).optional()
        })
    }
});

registry.registerPath({
    method: "get",
    path: "/api/v1/catalog/{id}",
    summary: "Get subscription by id",
    tags: ["catalog"],
    security: authSecurity,
    request: {
        params: z.object({ id: z.string().uuid() })
    },
    responses: {
        200: { description: "OK", content: successContent },
        401: { description: "Unauthorized", content: errorContent },
        403: { description: "Forbidden", content: errorContent }
    }
});

registerProtectedPath({
    method: "post",
    path: "/api/v1/user-subscriptions",
    summary: "Create user subscription",
    tags: ["user-subscriptions"],
    request: { body: { content: { "application/json": { schema: createUserSubscriptionBodySchema } } } }
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/user-subscriptions/{id}",
    summary: "Update user subscription",
    tags: ["user-subscriptions"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: updateUserSubscriptionBodySchema } } }
    }
});
registerProtectedPath({
    method: "delete",
    path: "/api/v1/user-subscriptions/{id}",
    summary: "Delete user subscription",
    tags: ["user-subscriptions"],
    request: {
        params: z.object({ id: z.string().uuid() })
    }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/user-subscriptions/pending",
    summary: "List pending user subscriptions",
    tags: ["user-subscriptions"]
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/user-subscriptions/common",
    summary: "Create common subscription request (legacy path)",
    tags: ["user-subscriptions", "common-subscriptions"],
    request: { body: { content: { "application/json": { schema: createCommonSubscriptionBodySchema } } } }
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/common-subscriptions",
    summary: "Create common subscription request",
    tags: ["common-subscriptions"],
    request: { body: { content: { "application/json": { schema: createCommonSubscriptionBodySchema } } } }
});

registerProtectedPath({
    method: "get",
    path: "/api/v1/payment-methods",
    summary: "List payment methods",
    tags: ["payment-methods"]
});
registry.registerPath({
    method: "post",
    path: "/api/v1/payment-methods",
    summary: "Create payment method",
    tags: ["payment-methods"],
    security: authSecurity,
    request: { body: { content: { "application/json": { schema: paymentMethodBodySchema } } } },
    responses: {
        200: { description: "OK", content: successContent },
        201: { description: "Created", content: successContent },
        400: { description: "Bad Request", content: errorContent },
        401: { description: "Unauthorized", content: errorContent },
        403: { description: "Forbidden", content: errorContent },
        409: { description: "Conflict", content: errorContent }
    }
});
registry.registerPath({
    method: "patch",
    path: "/api/v1/payment-methods/{id}",
    summary: "Rename payment method",
    tags: ["payment-methods"],
    security: authSecurity,
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: paymentMethodRenameBodySchema } } }
    },
    responses: {
        200: { description: "OK", content: successContent },
        400: { description: "Bad Request", content: errorContent },
        401: { description: "Unauthorized", content: errorContent },
        403: { description: "Forbidden", content: errorContent },
        404: { description: "Not Found", content: errorContent },
        409: { description: "Conflict", content: errorContent }
    }
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/payment-methods/{id}/default",
    summary: "Set default payment method",
    tags: ["payment-methods"],
    request: { params: z.object({ id: z.string().uuid() }) }
});
registerProtectedPath({
    method: "delete",
    path: "/api/v1/payment-methods/{id}",
    summary: "Delete payment method",
    tags: ["payment-methods"],
    request: { params: z.object({ id: z.string().uuid() }) }
});

registerProtectedPath({
    method: "get",
    path: "/api/v1/settings",
    summary: "Get settings overview",
    tags: ["settings"]
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/settings/profile",
    summary: "Get profile settings",
    tags: ["settings"]
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/settings/profile",
    summary: "Update profile",
    tags: ["settings"],
    request: { body: { content: { "application/json": { schema: updateProfileBodySchema } } } }
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/settings/security/password",
    summary: "Change password",
    tags: ["settings"],
    request: { body: { content: { "application/json": { schema: updatePasswordBodySchema } } } }
});

registerProtectedPath({ method: "get", path: "/api/v1/banks", summary: "List banks", tags: ["banks"] });

registerProtectedPath({
    method: "get",
    path: "/api/v1/admin/moderation/subscriptions",
    summary: "Admin moderation queue",
    tags: ["admin"],
    request: {
        query: z.object({
            q: z.string().optional(),
            category: z.string().optional(),
            period: z.number().int().optional()
        })
    }
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/admin/moderation/subscriptions/{id}/publish",
    summary: "Publish subscription",
    tags: ["admin"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: publishBodySchema } } }
    }
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/admin/moderation/subscriptions/{id}/reject",
    summary: "Reject subscription",
    tags: ["admin"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: rejectBodySchema } } }
    }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/admin/published/subscriptions",
    summary: "List published subscriptions",
    tags: ["admin"],
    request: {
        query: z.object({
            q: z.string().optional(),
            category: z.string().optional(),
            period: z.number().int().optional()
        })
    }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/admin/subscriptions/{id}",
    summary: "Get subscription details",
    tags: ["admin"],
    request: { params: z.object({ id: z.string().uuid() }) }
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/admin/subscriptions/{id}",
    summary: "Update subscription",
    tags: ["admin"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: updateAdminSubscriptionBodySchema } } }
    }
});
registerProtectedPath({
    method: "delete",
    path: "/api/v1/admin/subscriptions/{id}",
    summary: "Delete or reject subscription",
    tags: ["admin"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: rejectBodySchema } } }
    }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/admin/users",
    summary: "List users",
    tags: ["admin"],
    request: {
        query: z.object({
            q: z.string().optional(),
            role: z.enum(["USER", "ADMIN", ""]).optional(),
            ban: z.enum(["active", "banned", ""]).optional()
        })
    }
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/admin/users/{id}/ban",
    summary: "Ban user",
    tags: ["admin"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: banBodySchema } } }
    }
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/admin/users/{id}/unban",
    summary: "Unban user",
    tags: ["admin"],
    request: { params: z.object({ id: z.string().uuid() }) }
});
registerProtectedPath({
    method: "get",
    path: "/api/v1/admin/banks",
    summary: "List banks (admin)",
    tags: ["admin", "banks"]
});
registerProtectedPath({
    method: "post",
    path: "/api/v1/admin/banks",
    summary: "Create bank",
    tags: ["admin", "banks"],
    request: { body: { content: { "application/json": { schema: createBankBodySchema } } } }
});
registerProtectedPath({
    method: "patch",
    path: "/api/v1/admin/banks/{id}",
    summary: "Update bank",
    tags: ["admin", "banks"],
    request: {
        params: z.object({ id: z.string().uuid() }),
        body: { content: { "application/json": { schema: updateBankBodySchema } } }
    }
});
registerProtectedPath({
    method: "delete",
    path: "/api/v1/admin/banks/{id}",
    summary: "Delete bank",
    tags: ["admin", "banks"],
    request: { params: z.object({ id: z.string().uuid() }) }
});

export function buildOpenApiDocument() {
    const generator = new OpenApiGeneratorV31(registry.definitions);
    return generator.generateDocument({
        openapi: "3.1.0",
        info: {
            title: "SubTrack API",
            version: "1.0.0",
            description: "Standalone Express API for SubTrack web and mobile clients."
        },
        servers: [{ url: "/" }],
        tags: [
            { name: "system" },
            { name: "auth" },
            { name: "downloads" },
            { name: "uploads" },
            { name: "home" },
            { name: "profile" },
            { name: "catalog" },
            { name: "user-subscriptions" },
            { name: "common-subscriptions" },
            { name: "notifications" },
            { name: "settings" },
            { name: "payment-methods" },
            { name: "banks" },
            { name: "calendar" },
            { name: "admin" }
        ],
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: "http",
                    scheme: "bearer",
                    bearerFormat: "JWT"
                },
                sessionCookie: {
                    type: "apiKey",
                    in: "cookie",
                    name: "subtrack_access"
                },
                refreshCookie: {
                    type: "apiKey",
                    in: "cookie",
                    name: "subtrack_refresh"
                }
            }
        }
    } as any);
}
