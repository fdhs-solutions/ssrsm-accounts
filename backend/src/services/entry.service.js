import { DailyStockEntryModel, ProductModel } from '../models/index.js';
import { ProductService } from './product.service.js';
import { AppError } from '../utils/app-error.js';

export function calculateClosingStock({ openingStock, newStock, dailySales, stockReceived }) {
  const values = [openingStock, newStock, dailySales, stockReceived].map((v) => Number(v ?? 0));
  if (values.some((v) => !Number.isFinite(v) || v < 0)) {
    throw new AppError('Stock values must be valid non-negative numbers', 400, 'INVALID_STOCK_VALUES');
  }

  const [open, added, sales, received] = values;
  const closingStock = Number((open + added - sales + received).toFixed(2));

  if (closingStock < 0) {
    throw new AppError('Daily sales cannot exceed available stock', 400, 'NEGATIVE_CLOSING_STOCK');
  }

  return closingStock;
}

export const EntryService = {
  async getOpeningStockInfo({ productId, date }) {
    const product = await ProductService.resolveProduct(productId);
    const targetDate = date || new Date().toISOString().split('T')[0];

    const [existingSameDay, prevClosingStock] = await Promise.all([
      DailyStockEntryModel.findFirstForDate(product.id, targetDate),
      DailyStockEntryModel.findLatestClosingStockBefore(product.id, targetDate),
    ]);

    const openingStock =
      prevClosingStock !== null
        ? prevClosingStock
        : await ProductModel.getDefaultOpeningStock(product.id);

    return {
      openingStock,
      sameDayEntry: existingSameDay
        ? {
            openingStock: parseFloat(existingSameDay.opening_stock || 0),
            newStock: parseFloat(existingSameDay.new_stock || 0),
            dailySales: parseFloat(existingSameDay.daily_sales || 0),
            stockReceived: parseFloat(existingSameDay.stock_received || 0),
            closingStock: parseFloat(existingSameDay.closing_stock || 0),
          }
        : null,
    };
  },

  async list({ productId, startDate, endDate, page, limit }) {
    const product = await ProductService.resolveProduct(productId, { allowAll: true });
    const safeLimit = limit !== undefined ? limit : undefined;
    const safeOffset = page !== undefined && safeLimit !== undefined ? (page - 1) * safeLimit : undefined;

    return DailyStockEntryModel.findAll({
      productId: product?.id,
      startDate,
      endDate,
      limit: safeLimit,
      offset: safeOffset,
    });
  },

  async create(payload, userId = null) {
    const product = await ProductService.resolveProduct(payload.productId);
    const closingStock = calculateClosingStock({
      openingStock: payload.openingStock,
      newStock: payload.newStock,
      dailySales: payload.dailySales,
      stockReceived: payload.stockReceived,
    });

    return DailyStockEntryModel.create({
      ...payload,
      productId: product.id,
      salesmanId: payload.salesmanId || null,
      closingStock,
      createdBy: userId,
    });
  },

  async update(id, payload) {
    const existing = await DailyStockEntryModel.findById(id);
    if (!existing) {
      throw new AppError('Stock entry not found', 404, 'ENTRY_NOT_FOUND');
    }

    let resolvedProductId = existing.product_id;
    if (payload.productId !== undefined) {
      const product = await ProductService.resolveProduct(payload.productId);
      resolvedProductId = product.id;
    }

    const merged = {
      entryDate: payload.entryDate ?? existing.entry_date,
      productId: resolvedProductId,
      salesmanId: payload.salesmanId !== undefined ? (payload.salesmanId || null) : existing.salesman_id,
      openingStock: payload.openingStock ?? existing.opening_stock,
      newStock: payload.newStock ?? existing.new_stock,
      dailySales: payload.dailySales ?? existing.daily_sales,
      stockReceived: payload.stockReceived ?? existing.stock_received,
      cashAmount: payload.cashAmount ?? existing.cash_amount,
      chequeAmount: payload.chequeAmount ?? existing.cheque_amount,
      rtgsAmount: payload.rtgsAmount ?? existing.rtgs_amount,
      autoAmount: payload.autoAmount ?? existing.auto_amount,
      creditAmount: payload.creditAmount ?? existing.credit_amount,
      note: payload.note ?? existing.note,
    };

    merged.closingStock = calculateClosingStock(merged);
    return DailyStockEntryModel.update(id, merged);
  },

  async remove(id) {
    const deleted = await DailyStockEntryModel.delete(id);
    if (!deleted) {
      throw new AppError('Stock entry not found', 404, 'ENTRY_NOT_FOUND');
    }
    return deleted;
  },

  async removeMany(ids) {
    const deletedRows = await DailyStockEntryModel.deleteMany(ids);
    return {
      deletedCount: deletedRows.length,
      deletedIds: deletedRows.map((r) => r.id),
    };
  },
};
