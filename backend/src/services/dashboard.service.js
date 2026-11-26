import db from '../config/db.js';
import { ProductService } from './product.service.js';

export const DashboardService = {
  async getDashboard({ date, startDate, endDate, productId }) {
    const product = await ProductService.resolveProduct(productId, { allowAll: true });

    const conditions = ['e.daily_stock_entries_is_delete = FALSE'];
    const params = [];

    if (date) {
      params.push(date);
      conditions.push(`e.daily_stock_entries_entry_date = $${params.length}`);
    } else {
      if (startDate) {
        params.push(startDate);
        conditions.push(`e.daily_stock_entries_entry_date >= $${params.length}`);
      }
      if (endDate) {
        params.push(endDate);
        conditions.push(`e.daily_stock_entries_entry_date <= $${params.length}`);
      }
    }

    if (product?.id) {
      params.push(product.id);
      conditions.push(`e.daily_stock_entries_products_id = $${params.length}`);
    }

    const whereClause = conditions.join(' AND ');

    const modeQuery = `
      WITH distinct_dates AS (
        SELECT DISTINCT ON (e.daily_stock_entries_products_id, e.daily_stock_entries_entry_date)
          e.daily_stock_entries_opening_stock AS opening_stock,
          e.daily_stock_entries_closing_stock AS closing_stock,
          e.daily_stock_entries_daily_sales AS daily_sales,
          e.daily_stock_entries_new_stock AS new_stock,
          e.daily_stock_entries_stock_received AS stock_received
        FROM daily_stock_entries e
        WHERE ${whereClause}
        ORDER BY e.daily_stock_entries_products_id, e.daily_stock_entries_entry_date, e.daily_stock_entries_created_at ASC
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
          COALESCE(SUM(e.daily_stock_entries_cash_amount), 0) AS total_cash,
          COALESCE(SUM(e.daily_stock_entries_cheque_amount), 0) AS total_cheque,
          COALESCE(SUM(e.daily_stock_entries_rtgs_amount), 0) AS total_rtgs,
          COALESCE(SUM(e.daily_stock_entries_auto_amount), 0) AS total_auto,
          COALESCE(SUM(e.daily_stock_entries_credit_amount), 0) AS total_credit,
          COALESCE(SUM(e.daily_stock_entries_total_collection), 0) AS total_collection
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

    const salesmanQuery = `
      SELECT
        COALESCE(s.salesmen_id::text, 'unassigned') AS salesman_id,
        COALESCE(s.salesmen_name, 'Unassigned') AS salesman_name,
        COALESCE(SUM(e.daily_stock_entries_total_collection), 0) AS total_collection,
        COALESCE(SUM(e.daily_stock_entries_cash_amount), 0) AS cash_amount,
        COALESCE(SUM(e.daily_stock_entries_cheque_amount), 0) AS cheque_amount,
        COALESCE(SUM(e.daily_stock_entries_rtgs_amount), 0) AS rtgs_amount,
        COALESCE(SUM(e.daily_stock_entries_auto_amount), 0) AS auto_amount,
        COALESCE(SUM(e.daily_stock_entries_credit_amount), 0) AS credit_amount,
        COALESCE(SUM(e.daily_stock_entries_daily_sales), 0) AS total_sales
      FROM daily_stock_entries e
      LEFT JOIN salesmen s ON e.daily_stock_entries_salesmen_id = s.salesmen_id
      WHERE ${whereClause}
      GROUP BY s.salesmen_id, s.salesmen_name
      ORDER BY total_collection DESC
    `;

    // Fixed: count daily_sales once per (product, entry_date) while summing collections across all entries
    const trendQuery = `
      WITH distinct_daily_sales AS (
        SELECT DISTINCT ON (e.daily_stock_entries_products_id, e.daily_stock_entries_entry_date)
          e.daily_stock_entries_entry_date AS entry_date,
          e.daily_stock_entries_daily_sales AS daily_sales
        FROM daily_stock_entries e
        WHERE ${whereClause}
        ORDER BY e.daily_stock_entries_products_id, e.daily_stock_entries_entry_date, e.daily_stock_entries_created_at ASC
      ),
      sales_by_date AS (
        SELECT entry_date, COALESCE(SUM(daily_sales), 0) AS daily_sales
        FROM distinct_daily_sales
        GROUP BY entry_date
      ),
      collections_by_date AS (
        SELECT
          e.daily_stock_entries_entry_date AS entry_date,
          COALESCE(SUM(e.daily_stock_entries_total_collection), 0) AS total_collection,
          COALESCE(SUM(e.daily_stock_entries_cash_amount), 0) AS cash_amount
        FROM daily_stock_entries e
        WHERE ${whereClause}
        GROUP BY e.daily_stock_entries_entry_date
      )
      SELECT
        TO_CHAR(c.entry_date, 'YYYY-MM-DD') AS entry_date,
        COALESCE(s.daily_sales, 0) AS daily_sales,
        c.total_collection,
        c.cash_amount
      FROM collections_by_date c
      LEFT JOIN sales_by_date s ON c.entry_date = s.entry_date
      ORDER BY c.entry_date ASC
    `;

    const [modeRes, salesmanRes, trendRes] = await Promise.all([
      db.query(modeQuery, params),
      db.query(salesmanQuery, params),
      db.query(trendQuery, params),
    ]);

    const modeRow = modeRes.rows[0] || {};

    return {
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
      collectionByMode: {
        cash: parseFloat(modeRow.total_cash || 0),
        cheque: parseFloat(modeRow.total_cheque || 0),
        rtgs: parseFloat(modeRow.total_rtgs || 0),
        auto: parseFloat(modeRow.total_auto || 0),
        credit: parseFloat(modeRow.total_credit || 0),
      },
      collectionBySalesman: salesmanRes.rows.map((row) => ({
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
      dailyTrend: trendRes.rows.map((row) => ({
        date: row.entry_date,
        dailySales: parseFloat(row.daily_sales),
        totalCollection: parseFloat(row.total_collection),
        cashAmount: parseFloat(row.cash_amount),
      })),
    };
  },
};
