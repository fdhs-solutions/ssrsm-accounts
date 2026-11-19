
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