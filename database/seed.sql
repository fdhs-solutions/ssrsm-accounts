-- Initial Admin
INSERT INTO users (username, password_hash, full_name, role)
VALUES ('admin', '$2b$10$w8T0iZ/v1yKz.jP0FqfV5uXj7p.nK3j0c9uO3o4x2L1sX5e4d2a1m', 'Administrator', 'admin')
ON CONFLICT (username) DO NOTHING;

-- Initial Products (Brands)
INSERT INTO products (name, category, default_opening_stock) VALUES
('Dettol', 'Hygiene', 145.00),
('Dabur', 'Health', 110.00),
('Diaper', 'Baby Care', 80.00)
ON CONFLICT (name) DO NOTHING;

-- Initial Salesmen
INSERT INTO salesmen (product_id, name)
SELECT id, 'Ramesh' FROM products WHERE name = 'Dettol';

INSERT INTO salesmen (product_id, name)
SELECT id, 'Suresh' FROM products WHERE name = 'Dabur';