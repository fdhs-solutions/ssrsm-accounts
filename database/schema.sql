-- SSRSM Accounts - PostgreSQL Schema
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'admin' CHECK (role IN ('admin', 'manager', 'accountant')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. Products Table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(100),
    default_opening_stock NUMERIC(12, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Salesmen Table
CREATE TABLE IF NOT EXISTS salesmen (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_salesman_product UNIQUE (name, product_id)
);

-- 4. Daily Stock Register Table
CREATE TABLE IF NOT EXISTS daily_stock_registers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_date DATE NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    salesman_id UUID REFERENCES salesmen(id) ON DELETE SET NULL,
    serial_no INT,
    is_extra_entry BOOLEAN DEFAULT FALSE,
    opening_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    new_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    daily_sales NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    return_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
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

CREATE INDEX idx_registers_date_product ON daily_stock_registers(entry_date, product_id);
CREATE INDEX idx_registers_salesman ON daily_stock_registers(salesman_id);

-- 5. Collections Detail Table
CREATE TABLE IF NOT EXISTS register_collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    register_id UUID NOT NULL REFERENCES daily_stock_registers(id) ON DELETE CASCADE,
    payment_mode VARCHAR(20) NOT NULL CHECK (payment_mode IN ('Cash', 'Cheque', 'RTGS', 'Auto', 'Credit')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    cheque_number VARCHAR(50),
    cheque_status VARCHAR(20) DEFAULT 'Cleared' CHECK (cheque_status IN ('Pending', 'Cleared', 'Bounced')),
    reference_note TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reg_colls_register_id ON register_collections(register_id);
