import db from '../config/db.js';

export const ProductModel = {
  async findActive() {
    const result = await db.query(
      `SELECT
         products_id AS id,
         products_name AS name,
         products_category AS category,
         products_default_opening_stock AS default_opening_stock,
         products_is_active AS is_active
       FROM products
       WHERE products_is_active = TRUE AND products_is_delete = FALSE
       ORDER BY products_name ASC`
    );
    return result.rows;
  },

  async findById(id) {
    const result = await db.query(
      `SELECT
         products_id AS id,
         products_name AS name,
         products_category AS category,
         products_default_opening_stock AS default_opening_stock,
         products_is_active AS is_active
       FROM products
       WHERE products_id = $1 AND products_is_delete = FALSE`,
      [id]
    );
    return result.rows[0] || null;
  },

  async findByName(name) {
    const result = await db.query(
      `SELECT
         products_id AS id,
         products_name AS name,
         products_category AS category,
         products_default_opening_stock AS default_opening_stock,
         products_is_active AS is_active
       FROM products
       WHERE LOWER(products_name) = LOWER($1)
         AND products_is_active = TRUE
         AND products_is_delete = FALSE
       LIMIT 1`,
      [name]
    );
    return result.rows[0] || null;
  },

  async getDefaultOpeningStock(id) {
    const result = await db.query(
      `SELECT products_default_opening_stock AS default_opening_stock
       FROM products
       WHERE products_id = $1 AND products_is_delete = FALSE`,
      [id]
    );
    return result.rows.length > 0 ? parseFloat(result.rows[0].default_opening_stock) : 0;
  },
};
