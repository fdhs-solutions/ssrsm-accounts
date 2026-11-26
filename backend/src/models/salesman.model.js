import db from '../config/db.js';

export const SalesmanModel = {
  async find({ productId } = {}) {
    let queryText = `
      SELECT
        s.salesmen_id AS id,
        s.salesmen_name AS name,
        s.salesmen_phone AS phone,
        s.salesmen_products_id AS product_id,
        p.products_name AS product_name,
        s.salesmen_is_active AS is_active
      FROM salesmen s
      LEFT JOIN products p ON s.salesmen_products_id = p.products_id
      WHERE s.salesmen_is_delete = FALSE AND s.salesmen_is_active = TRUE
    `;
    const params = [];

    if (productId) {
      params.push(productId);
      queryText += ` AND s.salesmen_products_id = $${params.length}`;
    }
    queryText += ' ORDER BY s.salesmen_name ASC';

    const result = await db.query(queryText, params);
    return result.rows;
  },

  async findById(id) {
    const result = await db.query(
      `SELECT
         s.salesmen_id AS id,
         s.salesmen_name AS name,
         s.salesmen_phone AS phone,
         s.salesmen_products_id AS product_id,
         p.products_name AS product_name,
         s.salesmen_is_active AS is_active
       FROM salesmen s
       LEFT JOIN products p ON s.salesmen_products_id = p.products_id
       WHERE s.salesmen_id = $1 AND s.salesmen_is_delete = FALSE`,
      [id]
    );
    return result.rows[0] || null;
  },

  async create({ name, productId, phone = null }) {
    const result = await db.query(
      `INSERT INTO salesmen (salesmen_name, salesmen_products_id, salesmen_phone)
       VALUES ($1, $2, $3)
       RETURNING
         salesmen_id AS id,
         salesmen_name AS name,
         salesmen_phone AS phone,
         salesmen_products_id AS product_id,
         salesmen_is_active AS is_active`,
      [name.trim(), productId, phone]
    );
    return result.rows[0];
  },

  async update(id, { name, productId, phone }) {
    const updates = [];
    const params = [id];

    if (name !== undefined) {
      params.push(name.trim());
      updates.push(`salesmen_name = $${params.length}`);
    }
    if (productId !== undefined) {
      params.push(productId);
      updates.push(`salesmen_products_id = $${params.length}`);
    }
    if (phone !== undefined) {
      params.push(phone);
      updates.push(`salesmen_phone = $${params.length}`);
    }

    if (updates.length === 0) return this.findById(id);

    const result = await db.query(
      `UPDATE salesmen
       SET ${updates.join(', ')}
       WHERE salesmen_id = $1 AND salesmen_is_delete = FALSE
       RETURNING
         salesmen_id AS id,
         salesmen_name AS name,
         salesmen_phone AS phone,
         salesmen_products_id AS product_id,
         salesmen_is_active AS is_active`,
      params
    );
    return result.rows[0] || null;
  },

  async delete(id) {
    const result = await db.query(
      `UPDATE salesmen
       SET salesmen_is_delete = TRUE,
           salesmen_is_active = FALSE
       WHERE salesmen_id = $1 AND salesmen_is_delete = FALSE
       RETURNING
         salesmen_id AS id,
         salesmen_name AS name,
         salesmen_products_id AS product_id`,
      [id]
    );
    return result.rows[0] || null;
  },
};
