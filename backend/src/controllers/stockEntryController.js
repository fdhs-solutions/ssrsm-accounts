import { Product, Salesman, DailyStockEntry } from '../models/index.js';
import { sendSuccess, sendError, sendBadRequest } from '../utils/response.js';

// ==========================================
// 1. PRODUCTS CONTROLLERS
// ==========================================
export const getProducts = async (req, res) => {
  try {
    const products = await Product.findActive();
    return sendSuccess(res, products);
  } catch (error) {
    return sendError(res, error);
  }
};

// ==========================================
// 2. SALESMEN CONTROLLERS (Full CRUD: GET, POST, PUT, DELETE)
// ==========================================

// GET /api/salesmen
export const getSalesmen = async (req, res) => {
  try {
    const { productId } = req.query;
    const salesmen = await Salesman.find({ productId });
    return sendSuccess(res, salesmen);
  } catch (error) {
    return sendError(res, error);
  }
};

// POST /api/salesmen
export const addSalesman = async (req, res) => {
  try {
    const { name, productId } = req.body;
    if (!name || !productId) {
      return sendBadRequest(res, 'Name and Product are required');
    }

    const salesman = await Salesman.create({ name, productId });
    return sendSuccess(res, salesman, 201);
  } catch (error) {
    return sendError(res, error);
  }
};

// PUT /api/salesmen/:id (Update Salesman)
export const updateSalesman = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, productId } = req.body;

    if (!name && !productId) {
      return sendBadRequest(res, 'At least name or productId is required to update');
    }

    const updated = await Salesman.update(id, { name, productId });
    if (!updated) {
      return sendError(res, 'Salesman not found', 404);
    }

    return sendSuccess(res, updated, 200, 'Salesman updated successfully');
  } catch (error) {
    return sendError(res, error);
  }
};

// DELETE /api/salesmen/:id (Delete Salesman)
export const deleteSalesman = async (req, res) => {
  try {
    const { id } = req.params;
    const deleted = await Salesman.delete(id);

    if (!deleted) {
      return sendError(res, 'Salesman not found', 404);
    }

    return sendSuccess(res, deleted, 200, 'Salesman deleted successfully');
  } catch (error) {
    return sendError(res, error);
  }
};

// ==========================================
// 3. DAILY STOCK ENTRIES CONTROLLERS (Full CRUD: GET, POST, PUT, DELETE)
// ==========================================

// GET /api/stock-entries/opening-stock
export const getOpeningStock = async (req, res) => {
  try {
    const { productId, date } = req.query;
    if (!productId) {
      return sendBadRequest(res, 'productId is required');
    }

    const targetDate = date || new Date().toISOString().split('T')[0];

    // Find the latest previous entry before this date
    const prevClosingStock = await DailyStockEntry.findLatestClosingStockBefore(productId, targetDate);

    if (prevClosingStock !== null) {
      return res.json({ success: true, openingStock: prevClosingStock });
    }

    // If no previous entry exists, fallback to product default opening stock
    const defaultStock = await Product.getDefaultOpeningStock(productId);
    return res.json({ success: true, openingStock: defaultStock });
  } catch (error) {
    return sendError(res, error);
  }
};

// GET /api/stock-entries (Fetch with filters)
export const getStockEntries = async (req, res) => {
  try {
    const { productId, startDate, endDate } = req.query;
    const entries = await DailyStockEntry.findAll({ productId, startDate, endDate });
    return sendSuccess(res, entries);
  } catch (error) {
    return sendError(res, error);
  }
};

// POST /api/stock-entries (Create Daily Stock Entry)
export const createStockEntry = async (req, res) => {
  try {
    const {
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

// PUT /api/stock-entries/:id (Update Daily Stock Entry)
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

    // Formula calculation
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

// DELETE /api/stock-entries/:id (Delete Daily Stock Entry)
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
