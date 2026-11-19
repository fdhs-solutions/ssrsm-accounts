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
   * Find single salesman by ID
   */
  async findById(id) {
    const result = await db.query(
      'SELECT s.*, p.name as product_name FROM salesmen s LEFT JOIN products p ON s.product_id = p.id WHERE s.id = $1',
      [id]
    );
    return result.rows[0] || null;
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

  /**
   * Update salesman by ID
   */
  async update(id, { name, productId }) {
    const updates = [];
    const params = [id];

    if (name) {
      params.push(name.trim());
      updates.push(`name = $${params.length}`);
    }
    if (productId) {
      params.push(productId);
      updates.push(`product_id = $${params.length}`);
    }
    updates.push('updated_at = CURRENT_TIMESTAMP');

    const result = await db.query(
      `UPDATE salesmen SET ${updates.join(', ')} WHERE id = $1 RETURNING *`,
      params
    );
    return result.rows[0] || null;
  },

  /**
   * Delete salesman by ID (Soft delete or Cascade)
   */
  async delete(id) {
    const result = await db.query(
      'DELETE FROM salesmen WHERE id = $1 RETURNING *',
      [id]
    );
    return result.rows[0] || null;
  },
};
