import db from '../config/db.js';

export const Product = {
  /**
   * Find all active products ordered by name
   */
  async findActive() {
    const result = await db.query(
      'SELECT * FROM products WHERE is_active = TRUE AND is_delete = FALSE ORDER BY name ASC'
    );
    return result.rows;
  },

  /**
   * Find product by ID
   */
  async findById(id) {
    const result = await db.query(
      'SELECT * FROM products WHERE id = $1 AND is_delete = FALSE',
      [id]
    );
    return result.rows[0] || null;
  },

  /**
   * Get default opening stock for product
   */
  async getDefaultOpeningStock(id) {
    const result = await db.query(
      'SELECT default_opening_stock FROM products WHERE id = $1',
      [id]
    );
    return result.rows.length > 0 ? parseFloat(result.rows[0].default_opening_stock) : 0;
  },
};
