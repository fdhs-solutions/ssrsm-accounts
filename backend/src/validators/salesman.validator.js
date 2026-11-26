import { z } from 'zod';
import { UUID_REGEX } from '../utils/formatters.js';

export const getSalesmenSchema = z.object({
  query: z.object({
    productId: z.string().trim().optional(),
    productName: z.string().trim().optional(),
  }),
});

export const createSalesmanSchema = z.object({
  body: z.object({
    name: z.string().trim().min(1, 'Salesman name is required').max(100),
    productId: z.string().trim().min(1, 'Product is required'),
    phone: z.string().trim().max(20).optional().nullable(),
  }),
});

export const updateSalesmanSchema = z.object({
  params: z.object({
    id: z.string().regex(UUID_REGEX, 'Invalid salesman ID'),
  }),
  body: z.object({
    name: z.string().trim().min(1).max(100).optional(),
    productId: z.string().trim().min(1).optional(),
    phone: z.string().trim().max(20).optional().nullable(),
  }).refine((data) => Boolean(data.name || data.productId || data.phone !== undefined), {
    message: 'At least one field is required to update',
  }),
});

export const salesmanIdParamSchema = z.object({
  params: z.object({
    id: z.string().regex(UUID_REGEX, 'Invalid salesman ID'),
  }),
});
