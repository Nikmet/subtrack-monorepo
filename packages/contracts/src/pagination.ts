import { z } from "zod";

export const pageQuerySchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  pageSize: z.coerce.number().int().min(1).max(100).optional().default(24),
});

export type PageQuery = z.infer<typeof pageQuerySchema>;
