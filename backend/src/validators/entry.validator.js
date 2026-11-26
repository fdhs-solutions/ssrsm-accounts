import { z } from 'zod';
import { UUID_REGEX } from '../utils/formatters.js';

const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD');
const nonNegNumber = z.coerce.number().finite().min(0, 'Value cannot be negative');

export const openingStockSchema = z.object({
  query: z.object({
    productId: z.string().trim().min(1, 'productId is required'),
    date: isoDate.optional(),
  }),
});

export const getEntriesSchema = z.object({
  query: z.object({
    productId: z.string().trim().optional(),
    startDate: isoDate.optional(),
    endDate: isoDate.optional(),
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(500).optional(),
  }),
});

export const createEntrySchema = z.object({
  body: z.object({
    entryDate: isoDate,
    productId: z.string().trim().min(1, 'productId is required'),
    salesmanId: z.string().regex(UUID_REGEX, 'Invalid salesmanId').optional().nullable().or(z.literal('')),
    openingStock: nonNegNumber.default(0),
    newStock: nonNegNumber.default(0),
    dailySales: nonNegNumber.default(0),
    stockReceived: nonNegNumber.default(0),
    cashAmount: nonNegNumber.default(0),
    chequeAmount: nonNegNumber.default(0),
    rtgsAmount: nonNegNumber.default(0),
    autoAmount: nonNegNumber.default(0),
    creditAmount: nonNegNumber.default(0),
    note: z.string().max(1000).optional().default(''),
    isExtraEntry: z.boolean().optional().default(false),
  }),
});

export const updateEntrySchema = z.object({
  params: z.object({
    id: z.string().regex(UUID_REGEX, 'Invalid entry ID'),
  }),
  body: z.object({
    entryDate: isoDate.optional(),
    productId: z.string().trim().min(1).optional(),
    salesmanId: z.string().regex(UUID_REGEX, 'Invalid salesmanId').optional().nullable().or(z.literal('')),
    openingStock: nonNegNumber.optional(),
    newStock: nonNegNumber.optional(),
    dailySales: nonNegNumber.optional(),
    stockReceived: nonNegNumber.optional(),
    cashAmount: nonNegNumber.optional(),
    chequeAmount: nonNegNumber.optional(),
    rtgsAmount: nonNegNumber.optional(),
    autoAmount: nonNegNumber.optional(),
    creditAmount: nonNegNumber.optional(),
    note: z.string().max(1000).optional(),
  }),
});

export const entryIdParamSchema = z.object({
  params: z.object({
    id: z.string().regex(UUID_REGEX, 'Invalid entry ID'),
  }),
});

export const bulkDeleteEntriesSchema = z.object({
  body: z.object({
    ids: z.array(z.string().regex(UUID_REGEX, 'Invalid entry ID in ids')).min(1, 'At least one entry ID is required'),
  }),
});
