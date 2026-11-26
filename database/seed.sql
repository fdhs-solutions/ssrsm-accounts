-- SSRSM Accounts - Production Seed Data (Idempotent)
-- Seeds only the default admin user and product brands (no dummy salesmen or entries).

-- 1. Default Admin User (username: admin, password: Admin@1234)
INSERT INTO users (users_username, users_email, users_password_hash, users_role)
VALUES (
    'admin',
    'admin@ssrsm.local',
    '$2b$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
    'admin'
)
ON CONFLICT (users_username) DO NOTHING;

-- 2. Initial Products (Brands)
INSERT INTO products (products_name, products_category, products_default_opening_stock)
VALUES
    ('Dettol', 'Hygiene', 145.00),
    ('Dabur', 'Health', 110.00),
    ('Diaper', 'Baby Care', 80.00),
    ('Wholesale', 'Wholesale', 0.00)
ON CONFLICT DO NOTHING;
