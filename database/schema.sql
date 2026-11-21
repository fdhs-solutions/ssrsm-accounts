-- SSRSM Accounts - Production Database Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Products / Brands Table (Dettol, Dabur, Diaper, etc.)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(100),
    default_opening_stock NUMERIC(12, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Salesmen Table (Attached to a product/brand)
CREATE TABLE IF NOT EXISTS salesmen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_salesman_product UNIQUE (name, product_id)
);

-- 4. Daily Stock Entries Table (Core Accounting Book / Khata)
CREATE TABLE IF NOT EXISTS daily_stock_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    salesman_id UUID REFERENCES salesmen(id) ON DELETE SET NULL,
    serial_no INT,
    is_extra_entry BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_delete BOOLEAN DEFAULT FALSE,
    opening_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    new_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    daily_sales NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    stock_received NUMERIC(12, 2) NOT NULL DEFAULT 0.00, -- renamed from return_stock as requested
    closing_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    cash_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    cheque_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    rtgs_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    auto_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    credit_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_collection NUMERIC(12, 2) GENERATED ALWAYS AS (cash_amount + cheque_amount + rtgs_amount + auto_amount) STORED,
    note TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stock_entries_date_product ON daily_stock_entries(entry_date, product_id);
CREATE INDEX IF NOT EXISTS idx_stock_entries_salesman ON daily_stock_entries(salesman_id);
