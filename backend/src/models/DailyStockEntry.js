import db from '../config/db.js';

export const DailyStockEntry = {
  /**
   * Find latest closing stock before a given date for a product
   */
  async findLatestClosingStockBefore(productId, date) {
    const result = await db.query(
      `SELECT closing_stock FROM daily_stock_entries 
       WHERE product_id = $1 AND entry_date < $2 AND is_extra_entry = FALSE AND is_delete = FALSE 
       ORDER BY entry_date DESC LIMIT 1`,
      [productId, date]
    );
    if (result.rows.length > 0) {
      return parseFloat(result.rows[0].closing_stock);
    }
    return null;
  },

  /**
   * Find entry by ID
   */
  async findById(id) {
    const result = await db.query(
      `SELECT e.*, p.name as product_name, s.name as salesman_name
       FROM daily_stock_entries e
       JOIN products p ON e.product_id = p.id
       LEFT JOIN salesmen s ON e.salesman_id = s.id
       WHERE e.id = $1 AND e.is_delete = FALSE`,
      [id]
    );
    return result.rows[0] || null;
  },

  /**
   * Find first entry for a specific date and product (to autofill for 2nd entry)
   */
  async findFirstForDate(productId, date) {
    const result = await db.query(
      `SELECT * FROM daily_stock_entries 
       WHERE product_id = $1 AND entry_date = $2 AND is_delete = FALSE 
       ORDER BY created_at ASC LIMIT 1`,
      [productId, date]
    );
    return result.rows[0] || null;
  },

  /**
   * Insert a new daily stock entry
   */
  async create(data) {
    const {
      entryDate,
      productId,
      salesmanId = null,
      openingStock = 0,
      newStock = 0,
      dailySales = 0,
      stockReceived = 0,
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
      INSERT INTO daily_stock_entries (
        entry_date, product_id, salesman_id,
        opening_stock, new_stock, daily_sales, stock_received, closing_stock,
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
      stockReceived,
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
   * Update existing daily stock entry by ID
   */
  async update(id, data) {
    const {
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
    } = data;

    const updateQuery = `
      UPDATE daily_stock_entries SET
        entry_date = COALESCE($2, entry_date),
        product_id = COALESCE($3, product_id),
        salesman_id = $4,
        opening_stock = COALESCE($5, opening_stock),
        new_stock = COALESCE($6, new_stock),
        daily_sales = COALESCE($7, daily_sales),
        stock_received = COALESCE($8, stock_received),
        closing_stock = COALESCE($9, closing_stock),
        cash_amount = COALESCE($10, cash_amount),
        cheque_amount = COALESCE($11, cheque_amount),
        rtgs_amount = COALESCE($12, rtgs_amount),
        auto_amount = COALESCE($13, auto_amount),
        credit_amount = COALESCE($14, credit_amount),
        note = COALESCE($15, note),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *;
    `;

    const values = [
      id,
      entryDate,
      productId,
      salesmanId !== undefined ? salesmanId : null,
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
    ];

    const result = await db.query(updateQuery, values);
    return result.rows[0] || null;
  },

  /**
   * Soft delete entry by ID
   */
  async delete(id) {
    const result = await db.query(
      `UPDATE daily_stock_entries 
       SET is_delete = TRUE, is_active = FALSE, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 AND is_delete = FALSE 
       RETURNING *`,
      [id]
    );
    return result.rows[0] || null;
  },

  /**
   * Soft delete multiple entries in ONE single query
   */
  async deleteMany(ids) {
    if (!ids || ids.length === 0) return [];
    const result = await db.query(
      `UPDATE daily_stock_entries 
       SET is_delete = TRUE, is_active = FALSE, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ANY($1::uuid[]) AND is_delete = FALSE 
       RETURNING id`,
      [ids]
    );
    return result.rows;
  },

  /**
   * Find entries with filters
   */
  async findAll({ productId, startDate, endDate } = {}) {
    let queryText = `
      SELECT e.*, 
        TO_CHAR(e.entry_date, 'YYYY-MM-DD') AS entry_date,
        p.name as product_name, 
        s.name as salesman_name
      FROM daily_stock_entries e
      JOIN products p ON e.product_id = p.id
      LEFT JOIN salesmen s ON e.salesman_id = s.id
      WHERE e.is_delete = FALSE
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      queryText += ` AND e.product_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      queryText += ` AND e.entry_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      queryText += ` AND e.entry_date <= $${params.length}`;
    }

    queryText += ' ORDER BY e.entry_date DESC, e.created_at DESC';

    const result = await db.query(queryText, params);
    return result.rows;
  },
};
