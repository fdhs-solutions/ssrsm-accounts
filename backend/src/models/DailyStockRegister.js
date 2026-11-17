import db from '../config/db.js';

export const DailyStockRegister = {
  /**
   * Find latest closing stock before a given date for a product
   */
  async findLatestClosingStockBefore(productId, date) {
    const result = await db.query(
      `SELECT closing_stock FROM daily_stock_registers 
       WHERE product_id = $1 AND entry_date < $2 AND is_extra_entry = FALSE 
       ORDER BY entry_date DESC LIMIT 1`,
      [productId, date]
    );
    if (result.rows.length > 0) {
      return parseFloat(result.rows[0].closing_stock);
    }
    return null;
  },

  /**
   * Insert a new daily stock register entry
   */
  async create(data) {
    const {
      entryDate,
      productId,
      salesmanId = null,
      openingStock = 0,
      newStock = 0,
      dailySales = 0,
      returnStock = 0,
      closingStock = 0,
      cashAmount = 0,
      chequeAmount = 0,
      rtgsAmount = 0,
      autoAmount = 0,
      creditAmount = 0,
      note = '',
      isExtraEntry = false,
    } = data;

    const insertQuery = `
      INSERT INTO daily_stock_registers (
        entry_date, product_id, salesman_id,
        opening_stock, new_stock, daily_sales, return_stock, closing_stock,
        cash_amount, cheque_amount, rtgs_amount, auto_amount, credit_amount,
        note, is_extra_entry
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *;
    `;

    const values = [
      entryDate,
      productId,
      salesmanId || null,
      openingStock,
      newStock,
      dailySales,
      returnStock,
      closingStock,
      cashAmount,
      chequeAmount,
      rtgsAmount,
      autoAmount,
      creditAmount,
      note,
      isExtraEntry,
    ];

    const result = await db.query(insertQuery, values);
    return result.rows[0];
  },

  /**
   * Find registers with filters
   */
  async findAll({ productId, startDate, endDate } = {}) {
    let queryText = `
      SELECT r.*, p.name as product_name, s.name as salesman_name
      FROM daily_stock_registers r
      JOIN products p ON r.product_id = p.id
      LEFT JOIN salesmen s ON r.salesman_id = s.id
      WHERE 1=1
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      queryText += ` AND r.product_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      queryText += ` AND r.entry_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      queryText += ` AND r.entry_date <= $${params.length}`;
    }

    queryText += ' ORDER BY r.entry_date DESC, r.created_at DESC';

    const result = await db.query(queryText, params);
    return result.rows;
  },
};
