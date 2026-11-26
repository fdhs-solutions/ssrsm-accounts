import db from '../config/db.js';

const ENTRY_SELECT = `
  e.daily_stock_entries_id AS id,
  TO_CHAR(e.daily_stock_entries_entry_date, 'YYYY-MM-DD') AS entry_date,
  e.daily_stock_entries_products_id AS product_id,
  e.daily_stock_entries_salesmen_id AS salesman_id,
  e.daily_stock_entries_serial_no AS serial_no,
  e.daily_stock_entries_is_extra_entry AS is_extra_entry,
  e.daily_stock_entries_is_active AS is_active,
  e.daily_stock_entries_is_delete AS is_delete,
  e.daily_stock_entries_opening_stock AS opening_stock,
  e.daily_stock_entries_new_stock AS new_stock,
  e.daily_stock_entries_daily_sales AS daily_sales,
  e.daily_stock_entries_stock_received AS stock_received,
  e.daily_stock_entries_closing_stock AS closing_stock,
  e.daily_stock_entries_cash_amount AS cash_amount,
  e.daily_stock_entries_cheque_amount AS cheque_amount,
  e.daily_stock_entries_rtgs_amount AS rtgs_amount,
  e.daily_stock_entries_auto_amount AS auto_amount,
  e.daily_stock_entries_credit_amount AS credit_amount,
  e.daily_stock_entries_total_collection AS total_collection,
  e.daily_stock_entries_note AS note,
  e.daily_stock_entries_created_by AS created_by,
  e.daily_stock_entries_created_at AS created_at,
  e.daily_stock_entries_updated_at AS updated_at
`;

export const DailyStockEntryModel = {
  async findLatestClosingStockBefore(productId, date) {
    const result = await db.query(
      `SELECT daily_stock_entries_closing_stock AS closing_stock
       FROM daily_stock_entries
       WHERE daily_stock_entries_products_id = $1
         AND daily_stock_entries_entry_date < $2
         AND daily_stock_entries_is_extra_entry = FALSE
         AND daily_stock_entries_is_delete = FALSE
       ORDER BY daily_stock_entries_entry_date DESC, daily_stock_entries_created_at DESC
       LIMIT 1`,
      [productId, date]
    );
    return result.rows.length > 0 ? parseFloat(result.rows[0].closing_stock) : null;
  },

  async findById(id) {
    const result = await db.query(
      `SELECT ${ENTRY_SELECT},
         p.products_name AS product_name,
         s.salesmen_name AS salesman_name
       FROM daily_stock_entries e
       JOIN products p ON e.daily_stock_entries_products_id = p.products_id
       LEFT JOIN salesmen s ON e.daily_stock_entries_salesmen_id = s.salesmen_id
       WHERE e.daily_stock_entries_id = $1 AND e.daily_stock_entries_is_delete = FALSE`,
      [id]
    );
    return result.rows[0] || null;
  },

  async findFirstForDate(productId, date) {
    const result = await db.query(
      `SELECT ${ENTRY_SELECT}
       FROM daily_stock_entries e
       WHERE e.daily_stock_entries_products_id = $1
         AND e.daily_stock_entries_entry_date = $2
         AND e.daily_stock_entries_is_delete = FALSE
       ORDER BY e.daily_stock_entries_created_at ASC
       LIMIT 1`,
      [productId, date]
    );
    return result.rows[0] || null;
  },

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
      createdBy = null,
    } = data;

    const result = await db.query(
      `INSERT INTO daily_stock_entries (
         daily_stock_entries_entry_date,
         daily_stock_entries_products_id,
         daily_stock_entries_salesmen_id,
         daily_stock_entries_opening_stock,
         daily_stock_entries_new_stock,
         daily_stock_entries_daily_sales,
         daily_stock_entries_stock_received,
         daily_stock_entries_closing_stock,
         daily_stock_entries_cash_amount,
         daily_stock_entries_cheque_amount,
         daily_stock_entries_rtgs_amount,
         daily_stock_entries_auto_amount,
         daily_stock_entries_credit_amount,
         daily_stock_entries_note,
         daily_stock_entries_is_extra_entry,
         daily_stock_entries_created_by
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
       RETURNING
         daily_stock_entries_id AS id,
         TO_CHAR(daily_stock_entries_entry_date, 'YYYY-MM-DD') AS entry_date,
         daily_stock_entries_products_id AS product_id,
         daily_stock_entries_salesmen_id AS salesman_id,
         daily_stock_entries_opening_stock AS opening_stock,
         daily_stock_entries_new_stock AS new_stock,
         daily_stock_entries_daily_sales AS daily_sales,
         daily_stock_entries_stock_received AS stock_received,
         daily_stock_entries_closing_stock AS closing_stock,
         daily_stock_entries_cash_amount AS cash_amount,
         daily_stock_entries_cheque_amount AS cheque_amount,
         daily_stock_entries_rtgs_amount AS rtgs_amount,
         daily_stock_entries_auto_amount AS auto_amount,
         daily_stock_entries_credit_amount AS credit_amount,
         daily_stock_entries_total_collection AS total_collection,
         daily_stock_entries_note AS note,
         daily_stock_entries_is_extra_entry AS is_extra_entry,
         daily_stock_entries_created_at AS created_at`,
      [
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
        createdBy,
      ]
    );
    return result.rows[0];
  },

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

    const result = await db.query(
      `UPDATE daily_stock_entries
       SET
         daily_stock_entries_entry_date = COALESCE($2, daily_stock_entries_entry_date),
         daily_stock_entries_products_id = COALESCE($3, daily_stock_entries_products_id),
         daily_stock_entries_salesmen_id = $4,
         daily_stock_entries_opening_stock = COALESCE($5, daily_stock_entries_opening_stock),
         daily_stock_entries_new_stock = COALESCE($6, daily_stock_entries_new_stock),
         daily_stock_entries_daily_sales = COALESCE($7, daily_stock_entries_daily_sales),
         daily_stock_entries_stock_received = COALESCE($8, daily_stock_entries_stock_received),
         daily_stock_entries_closing_stock = COALESCE($9, daily_stock_entries_closing_stock),
         daily_stock_entries_cash_amount = COALESCE($10, daily_stock_entries_cash_amount),
         daily_stock_entries_cheque_amount = COALESCE($11, daily_stock_entries_cheque_amount),
         daily_stock_entries_rtgs_amount = COALESCE($12, daily_stock_entries_rtgs_amount),
         daily_stock_entries_auto_amount = COALESCE($13, daily_stock_entries_auto_amount),
         daily_stock_entries_credit_amount = COALESCE($14, daily_stock_entries_credit_amount),
         daily_stock_entries_note = COALESCE($15, daily_stock_entries_note)
       WHERE daily_stock_entries_id = $1 AND daily_stock_entries_is_delete = FALSE
       RETURNING
         daily_stock_entries_id AS id,
         TO_CHAR(daily_stock_entries_entry_date, 'YYYY-MM-DD') AS entry_date,
         daily_stock_entries_products_id AS product_id,
         daily_stock_entries_salesmen_id AS salesman_id,
         daily_stock_entries_opening_stock AS opening_stock,
         daily_stock_entries_new_stock AS new_stock,
         daily_stock_entries_daily_sales AS daily_sales,
         daily_stock_entries_stock_received AS stock_received,
         daily_stock_entries_closing_stock AS closing_stock,
         daily_stock_entries_cash_amount AS cash_amount,
         daily_stock_entries_cheque_amount AS cheque_amount,
         daily_stock_entries_rtgs_amount AS rtgs_amount,
         daily_stock_entries_auto_amount AS auto_amount,
         daily_stock_entries_credit_amount AS credit_amount,
         daily_stock_entries_total_collection AS total_collection,
         daily_stock_entries_note AS note,
         daily_stock_entries_updated_at AS updated_at`,
      [
        id,
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
      ]
    );
    return result.rows[0] || null;
  },

  async delete(id) {
    const result = await db.query(
      `UPDATE daily_stock_entries
       SET daily_stock_entries_is_delete = TRUE,
           daily_stock_entries_is_active = FALSE
       WHERE daily_stock_entries_id = $1 AND daily_stock_entries_is_delete = FALSE
       RETURNING daily_stock_entries_id AS id`,
      [id]
    );
    return result.rows[0] || null;
  },

  async deleteMany(ids) {
    if (!ids || ids.length === 0) return [];
    const result = await db.query(
      `UPDATE daily_stock_entries
       SET daily_stock_entries_is_delete = TRUE,
           daily_stock_entries_is_active = FALSE
       WHERE daily_stock_entries_id = ANY($1::uuid[]) AND daily_stock_entries_is_delete = FALSE
       RETURNING daily_stock_entries_id AS id`,
      [ids]
    );
    return result.rows;
  },

  async findAll({ productId, startDate, endDate, limit, offset } = {}) {
    let queryText = `
      SELECT ${ENTRY_SELECT},
        p.products_name AS product_name,
        s.salesmen_name AS salesman_name
      FROM daily_stock_entries e
      JOIN products p ON e.daily_stock_entries_products_id = p.products_id
      LEFT JOIN salesmen s ON e.daily_stock_entries_salesmen_id = s.salesmen_id
      WHERE e.daily_stock_entries_is_delete = FALSE
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      queryText += ` AND e.daily_stock_entries_products_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      queryText += ` AND e.daily_stock_entries_entry_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      queryText += ` AND e.daily_stock_entries_entry_date <= $${params.length}`;
    }

    queryText += ' ORDER BY e.daily_stock_entries_entry_date DESC, e.daily_stock_entries_created_at DESC';

    if (limit !== undefined) {
      params.push(limit);
      queryText += ` LIMIT $${params.length}`;
    }

    if (offset !== undefined) {
      params.push(offset);
      queryText += ` OFFSET $${params.length}`;
    }

    const result = await db.query(queryText, params);
    return result.rows;
  },
};
