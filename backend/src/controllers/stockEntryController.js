import { Product, DailyStockEntry } from '../models/index.js';
import { sendSuccess, sendError, sendBadRequest } from '../utils/response.js';

// GET /api/entries/opening-stock
export const getOpeningStock = async (req, res) => {
  try {
    let { productId, date } = req.query;
    if (!productId) {
      return sendBadRequest(res, 'productId is required');
    }

    if (!/^[0-9a-fA-F-]{36}$/.test(productId)) {
      const allProds = await Product.findActive();
      const matched = allProds.find(
        p => p.name.toLowerCase() === productId.toLowerCase()
      );
      if (matched) {
        productId = matched.id;
      }
    }

    const targetDate = date || new Date().toISOString().split('T')[0];

    // Check if an entry already exists for this date and product (for 2nd entry autofill)
    const existingSameDay = await DailyStockEntry.findFirstForDate(productId, targetDate);

    const prevClosingStock = await DailyStockEntry.findLatestClosingStockBefore(productId, targetDate);

    const openingStock = prevClosingStock !== null ? prevClosingStock : 0;

    return res.json({
      success: true,
      openingStock,
      sameDayEntry: existingSameDay ? {
        openingStock: parseFloat(existingSameDay.opening_stock || 0),
        newStock: parseFloat(existingSameDay.new_stock || 0),
        dailySales: parseFloat(existingSameDay.daily_sales || 0),
        stockReceived: parseFloat(existingSameDay.stock_received || 0),
        closingStock: parseFloat(existingSameDay.closing_stock || 0),
      } : null,
    });
  } catch (error) {
    return sendError(res, error);
  }
};

// GET /api/entries (Fetch with optional filters: productId, startDate, endDate)
export const getEntries = async (req, res) => {
  try {
    let { productId, startDate, endDate } = req.query;

    if (productId && !/^[0-9a-fA-F-]{36}$/.test(productId)) {
      const allProds = await Product.findActive();
      const matched = allProds.find(
        p => p.name.toLowerCase() === productId.toLowerCase()
      );
      if (matched) {
        productId = matched.id;
      }
    }

    const entries = await DailyStockEntry.findAll({ productId, startDate, endDate });
    return sendSuccess(res, entries);
  } catch (error) {
    return sendError(res, error);
  }
};

// POST /api/entries (Create Daily Stock Entry)
export const createStockEntry = async (req, res) => {
  try {
    let {
      entryDate,
      productId,
      salesmanId,
      openingStock = 0,
      newStock = 0,
      dailySales = 0,
      stockReceived = 0,
      cashAmount = 0,
      chequeAmount = 0,
      rtgsAmount = 0,
      autoAmount = 0,
      creditAmount = 0,
      note = '',
      isExtraEntry = false,
    } = req.body;

    if (!productId || !entryDate) {
      return sendBadRequest(res, 'productId and entryDate are required');
    }

    // Resolve brand name like 'Dettol' to actual product UUID
    if (!/^[0-9a-fA-F-]{36}$/.test(productId)) {
      const allProds = await Product.findActive();
      const matched = allProds.find(
        p => p.name.toLowerCase() === productId.toLowerCase()
      );
      if (matched) {
        productId = matched.id;
      }
    }

    // Formula: Closing = Opening + New - Daily Sales + Stock Received
    const closingStock = (
      parseFloat(openingStock) +
      parseFloat(newStock) -
      parseFloat(dailySales) +
      parseFloat(stockReceived)
    );

    if (closingStock < 0) {
      return sendBadRequest(res, 'Daily sales cannot exceed available stock');
    }

    const newEntry = await DailyStockEntry.create({
      entryDate,
      productId,
      salesmanId,
      openingStock,
      newStock,
      dailySales,
      stockReceived,
      closingStock,
      cashAmount,
      chequeAmount,
      rtgsAmount,
      autoAmount,
      creditAmount,
      note,
      isExtraEntry,
    });

    return sendSuccess(res, newEntry, 201, 'Stock entry created successfully');
  } catch (error) {
    return sendError(res, error);
  }
};

// PUT /api/entries/:id (Update Daily Stock Entry)
export const updateStockEntry = async (req, res) => {
  try {
    const { id } = req.params;
    const existing = await DailyStockEntry.findById(id);

    if (!existing) {
      return sendError(res, 'Stock entry not found', 404);
    }

    const {
      entryDate = existing.entry_date,
      productId = existing.product_id,
      salesmanId = existing.salesman_id,
      openingStock = existing.opening_stock,
      newStock = existing.new_stock,
      dailySales = existing.daily_sales,
      stockReceived = existing.stock_received,
      cashAmount = existing.cash_amount,
      chequeAmount = existing.cheque_amount,
      rtgsAmount = existing.rtgs_amount,
      autoAmount = existing.auto_amount,
      creditAmount = existing.credit_amount,
      note = existing.note,
    } = req.body;

    const closingStock = (
      parseFloat(openingStock) +
      parseFloat(newStock) -
      parseFloat(dailySales) +
      parseFloat(stockReceived)
    );

    if (closingStock < 0) {
      return sendBadRequest(res, 'Daily sales cannot exceed available stock');
    }

    const updated = await DailyStockEntry.update(id, {
      entryDate,
      productId,
      salesmanId,
      openingStock,
      newStock,
      dailySales,
      stockReceived,
      closingStock,
      cashAmount,
      chequeAmount,
      rtgsAmount,
      autoAmount,
      creditAmount,
      note,
    });

    return sendSuccess(res, updated, 200, 'Stock entry updated successfully');
  } catch (error) {
    return sendError(res, error);
  }
};

// DELETE /api/entries/:id (Delete Daily Stock Entry)
export const deleteStockEntry = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await DailyStockEntry.delete(id);

    if (!deleted) {
      return sendError(res, 'Stock entry not found', 404);
    }

    return sendSuccess(res, deleted, 200, 'Stock entry deleted successfully');
  } catch (error) {
    return sendError(res, error);
  }
};
