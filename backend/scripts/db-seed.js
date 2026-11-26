import bcrypt from 'bcryptjs';
import { pool } from '../src/config/db.js';

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const passwordHash = await bcrypt.hash('Admin@1234', 10);
    await client.query(
      `INSERT INTO users (users_username, users_email, users_password_hash, users_role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (users_username) DO NOTHING`,
      ['admin', 'admin@ssrsm.local', passwordHash, 'admin']
    );

    const products = [
      ['Dettol', 'Hygiene', 145.0],
      ['Dabur', 'Health', 110.0],
      ['Diaper', 'Baby Care', 80.0],
      ['Wholesale', 'Wholesale', 0.0],
    ];

    for (const [name, category, opening] of products) {
      await client.query(
        `INSERT INTO products (products_name, products_category, products_default_opening_stock)
         VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING`,
        [name, category, opening]
      );
    }

    await client.query('COMMIT');
    console.log('Database seeded successfully (default admin: admin / Admin@1234 + 4 products)');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', err.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
