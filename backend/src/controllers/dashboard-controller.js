import db from '../config/db.js';
import { Product } from '../models/index.js';
import { sendSuccess, sendError } from '../utils/response.js';

// GET /api/dashboard
// Optional query params: ?date=YYYY-MM-DD or ?startDate=YYYY-MM-DD&endDate=YYYY-MM-DD&productId=uuid
export const getDashboardData = async (req, res, next) => {
  try {
    let { date, startDate, endDate, productId } = req.query;

    if (productId && productId.toLowerCase() !== 'all') {
      if (!/^[0-9a-fA-F-]{36}$/.test(productId)) {
        const allProds = await Product.findActive();
        const matched = allProds.find(
          p => p.name.toLowerCase() === productId.toLowerCase()
        );
        if (matched) {
          productId = matched.id;
        }
      }
    } else {
      productId = null;
    }

    // Base WHERE conditions
    const conditions = ['e.is_delete = FALSE'];
    const params = [];

    if (date) {
      params.push(date);
      conditions.push(`e.entry_date = $${params.length}`);
    } else {
      if (startDate) {
        params.push(startDate);
        conditions.push(`e.entry_date >= $${params.length}`);
      }
      if (endDate) {
        params.push(endDate);
        conditions.push(`e.entry_date <= $${params.length}`);
      }
    }

    if (productId) {
      params.push(productId);
      conditions.push(`e.product_id = $${params.length}`);
    }

    const whereClause = conditions.join(' AND ');

    // 1. Total Metrics & Collection by Mode
    // Business Rule: For same date multiple entries, Opening Stock, New Stock, Daily Sales,
    // Stock Received and Closing Stock should be counted only ONCE per date (from the first entry).
    // Collection amounts (Cash, Cheque, RTGS, Auto, Credit) are summed across all entries.
    const modeQuery = `
      WITH distinct_dates AS (
        SELECT DISTINCT ON (e.product_id, e.entry_date)
          e.opening_stock,
          e.closing_stock,
          e.daily_sales,
          e.new_stock,
          e.stock_received
        FROM daily_stock_entries e
        WHERE ${whereClause}
        ORDER BY e.product_id, e.entry_date, e.created_at ASC
      ),
      stock_totals AS (
        SELECT 
          COALESCE(SUM(opening_stock), 0) AS total_opening_stock,
          COALESCE(SUM(closing_stock), 0) AS total_closing_stock,
          COALESCE(SUM(daily_sales), 0) AS total_sales,
          COALESCE(SUM(new_stock), 0) AS total_new_stock,
          COALESCE(SUM(stock_received), 0) AS total_stock_received
        FROM distinct_dates
      ),
      collection_totals AS (
        SELECT 
          COALESCE(SUM(e.cash_amount), 0) AS total_cash,
          COALESCE(SUM(e.cheque_amount), 0) AS total_cheque,
          COALESCE(SUM(e.rtgs_amount), 0) AS total_rtgs,
          COALESCE(SUM(e.auto_amount), 0) AS total_auto,
          COALESCE(SUM(e.credit_amount), 0) AS total_credit,
          COALESCE(SUM(e.total_collection), 0) AS total_collection
        FROM daily_stock_entries e
        WHERE ${whereClause}
      )
      SELECT 
        s.total_opening_stock,
        s.total_closing_stock,
        s.total_sales,
        s.total_new_stock,
        s.total_stock_received,
        c.total_cash,
        c.total_cheque,
        c.total_rtgs,
        c.total_auto,
        c.total_credit,
        c.total_collection
      FROM stock_totals s, collection_totals c
    `;

    // 2. Collection by Salesman
    const salesmanQuery = `
      SELECT 
        COALESCE(s.id::text, 'unassigned') AS salesman_id,
        COALESCE(s.name, 'Unassigned') AS salesman_name,
        COALESCE(SUM(e.total_collection), 0) AS total_collection,
        COALESCE(SUM(e.cash_amount), 0) AS cash_amount,
        COALESCE(SUM(e.cheque_amount), 0) AS cheque_amount,
        COALESCE(SUM(e.rtgs_amount), 0) AS rtgs_amount,
        COALESCE(SUM(e.auto_amount), 0) AS auto_amount,
        COALESCE(SUM(e.credit_amount), 0) AS credit_amount,
        COALESCE(SUM(e.daily_sales), 0) AS total_sales
      FROM daily_stock_entries e
      LEFT JOIN salesmen s ON e.salesman_id = s.id
      WHERE ${whereClause}
      GROUP BY s.id, s.name
      ORDER BY total_collection DESC
    `;

    // 3. Daily Trend (Date-wise sales and collection for Line Charts)
    const trendQuery = `
      SELECT 
        TO_CHAR(e.entry_date, 'YYYY-MM-DD') AS entry_date,
        COALESCE(SUM(e.daily_sales), 0) AS daily_sales,
        COALESCE(SUM(e.total_collection), 0) AS total_collection,
        COALESCE(SUM(e.cash_amount), 0) AS cash_amount
      FROM daily_stock_entries e
      WHERE ${whereClause}
      GROUP BY e.entry_date
      ORDER BY e.entry_date ASC
    `;

    // Parallel DB execution
    const [modeRes, salesmanRes, trendRes] = await Promise.all([
      db.query(modeQuery, params),
      db.query(salesmanQuery, params),
      db.query(trendQuery, params),
    ]);

    const modeRow = modeRes.rows[0] || {};

    const responseData = {
      // Metric Summary Cards
      summary: {
        totalOpeningStock: parseFloat(modeRow.total_opening_stock || 0),
        totalClosingStock: parseFloat(modeRow.total_closing_stock || 0),
        totalCollection: parseFloat(modeRow.total_collection || 0),
        totalSales: parseFloat(modeRow.total_sales || 0),
        totalCash: parseFloat(modeRow.total_cash || 0),
        totalCheque: parseFloat(modeRow.total_cheque || 0),
        totalRtgs: parseFloat(modeRow.total_rtgs || 0),
        totalAuto: parseFloat(modeRow.total_auto || 0),
        totalCredit: parseFloat(modeRow.total_credit || 0),
        totalNewStock: parseFloat(modeRow.total_new_stock || 0),
        totalStockReceived: parseFloat(modeRow.total_stock_received || 0),
      },

      // Pie / Donut Chart for Payment Modes
      collectionByMode: {
        cash: parseFloat(modeRow.total_cash || 0),
        cheque: parseFloat(modeRow.total_cheque || 0),
        rtgs: parseFloat(modeRow.total_rtgs || 0),
        auto: parseFloat(modeRow.total_auto || 0),
        credit: parseFloat(modeRow.total_credit || 0),
      },

      // Bar Chart / Table for Salesmen
      collectionBySalesman: salesmanRes.rows.map(row => ({
        salesmanId: row.salesman_id,
        salesmanName: row.salesman_name,
        totalCollection: parseFloat(row.total_collection),
        cashAmount: parseFloat(row.cash_amount),
        chequeAmount: parseFloat(row.cheque_amount),
        rtgsAmount: parseFloat(row.rtgs_amount),
        autoAmount: parseFloat(row.auto_amount),
        creditAmount: parseFloat(row.credit_amount),
        totalSales: parseFloat(row.total_sales),
      })),

      // Line Chart for Daily Trend
      dailyTrend: trendRes.rows.map(row => ({
        date: row.entry_date,
        dailySales: parseFloat(row.daily_sales),
        totalCollection: parseFloat(row.total_collection),
        cashAmount: parseFloat(row.cash_amount),
      })),
    };

    return sendSuccess(res, responseData);
  } catch (error) {
    return next(error);
  }
};
