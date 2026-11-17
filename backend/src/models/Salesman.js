import db from '../config/db.js';

export const Salesman = {
  /**
   * Find salesmen with optional product filter
   */
  async find({ productId } = {}) {
    let queryText = `
      SELECT s.*, p.name as product_name 
      FROM salesmen s 
      LEFT JOIN products p ON s.product_id = p.id 
      WHERE s.is_active = TRUE
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      queryText += ' AND s.product_id = $1';
    }
    queryText += ' ORDER BY s.name ASC';

    const result = await db.query(queryText, params);
    return result.rows;
  },

  /**
   * Create a new salesman
   */
  async create({ name, productId }) {
    const result = await db.query(
      'INSERT INTO salesmen (name, product_id) VALUES ($1, $2) RETURNING *',
      [name.trim(), productId]
    );
    return result.rows[0];
  },
};
