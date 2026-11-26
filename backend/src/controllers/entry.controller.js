import { EntryService } from '../services/entry.service.js';
import { asyncHandler } from '../utils/async-handler.js';
import { sendSuccess } from '../utils/response.js';

export const getOpeningStock = asyncHandler(async (req, res) => {
  const { productId, date } = req.validated.query;
  const info = await EntryService.getOpeningStockInfo({ productId, date });
  return res.json({
    success: true,
    openingStock: info.openingStock,
    sameDayEntry: info.sameDayEntry,
  });
});

export const getEntries = asyncHandler(async (req, res) => {
  const entries = await EntryService.list(req.validated.query);
  return sendSuccess(res, entries);
});

export const createStockEntry = asyncHandler(async (req, res) => {
  const newEntry = await EntryService.create(req.validated.body, req.user?.id || null);
  return sendSuccess(res, newEntry, 201, 'Stock entry created successfully');
});

export const updateStockEntry = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const updated = await EntryService.update(id, req.validated.body);
  return sendSuccess(res, updated, 200, 'Stock entry updated successfully');
});

export const deleteStockEntry = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const deleted = await EntryService.remove(id);
  return sendSuccess(res, deleted, 200, 'Stock entry deleted successfully');
});

export const deleteMultipleStockEntries = asyncHandler(async (req, res) => {
  const { ids } = req.validated.body;
  const result = await EntryService.removeMany(ids);
  return sendSuccess(res, result, 200, `${result.deletedCount} entries deleted successfully`);
});
