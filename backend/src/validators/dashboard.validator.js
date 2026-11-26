import { z } from 'zod';

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD');

export const dashboardQuerySchema = z.object({
  query: z.object({
    date: isoDate.optional(),
    startDate: isoDate.optional(),
    endDate: isoDate.optional(),
    productId: z.string().trim().optional(),
  }),
});
