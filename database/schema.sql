-- SSRSM Accounts - Production Database Schema
-- Naming Convention: tableName_column_name

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Shared trigger function to auto-update *_updated_at columns
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW := jsonb_populate_record(NEW, jsonb_build_object(TG_TABLE_NAME || '_updated_at', CURRENT_TIMESTAMP));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Users Table (Single-owner admin account + password reset support)
CREATE TABLE IF NOT EXISTS users (
    users_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    users_username VARCHAR(100) UNIQUE NOT NULL,
    users_email VARCHAR(255) UNIQUE NOT NULL,
    users_password_hash TEXT NOT NULL,
    users_role VARCHAR(30) NOT NULL DEFAULT 'admin',
    users_reset_token_hash VARCHAR(64),
    users_reset_token_expires_at TIMESTAMPTZ,
    users_is_active BOOLEAN NOT NULL DEFAULT TRUE,
    users_is_delete BOOLEAN NOT NULL DEFAULT FALSE,
    users_created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    users_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_reset_token_hash
    ON users (users_reset_token_hash)
    WHERE users_reset_token_hash IS NOT NULL;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 2. Products / Brands Table (Dettol, Dabur, Diaper, Wholesale, etc.)
CREATE TABLE IF NOT EXISTS products (
    products_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    products_name VARCHAR(100) NOT NULL,
    products_category VARCHAR(100),
    products_default_opening_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (products_default_opening_stock >= 0),
    products_is_active BOOLEAN NOT NULL DEFAULT TRUE,
    products_is_delete BOOLEAN NOT NULL DEFAULT FALSE,
    products_created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    products_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_products_name_active
    ON products (LOWER(products_name))
    WHERE products_is_delete = FALSE;

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3. Salesmen Table (Attached to a product/brand)
CREATE TABLE IF NOT EXISTS salesmen (
    salesmen_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salesmen_products_id UUID NOT NULL REFERENCES products(products_id) ON DELETE CASCADE,
    salesmen_name VARCHAR(100) NOT NULL,
    salesmen_phone VARCHAR(20),
    salesmen_is_active BOOLEAN NOT NULL DEFAULT TRUE,
    salesmen_is_delete BOOLEAN NOT NULL DEFAULT FALSE,
    salesmen_created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    salesmen_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Partial unique index: allows re-adding a salesman name after soft delete
CREATE UNIQUE INDEX IF NOT EXISTS uq_salesmen_name_product_active
    ON salesmen (LOWER(salesmen_name), salesmen_products_id)
    WHERE salesmen_is_delete = FALSE;

CREATE INDEX IF NOT EXISTS idx_salesmen_products_active
    ON salesmen (salesmen_products_id)
    WHERE salesmen_is_delete = FALSE AND salesmen_is_active = TRUE;

DROP TRIGGER IF EXISTS trg_salesmen_updated_at ON salesmen;
CREATE TRIGGER trg_salesmen_updated_at
    BEFORE UPDATE ON salesmen
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4. Daily Stock Entries Table (Core Accounting Book / Khata)
CREATE TABLE IF NOT EXISTS daily_stock_entries (
    daily_stock_entries_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    daily_stock_entries_entry_date DATE NOT NULL,
    daily_stock_entries_products_id UUID NOT NULL REFERENCES products(products_id) ON DELETE RESTRICT,
    daily_stock_entries_salesmen_id UUID REFERENCES salesmen(salesmen_id) ON DELETE SET NULL,
    daily_stock_entries_serial_no INT,
    daily_stock_entries_is_extra_entry BOOLEAN NOT NULL DEFAULT FALSE,
    daily_stock_entries_is_active BOOLEAN NOT NULL DEFAULT TRUE,
    daily_stock_entries_is_delete BOOLEAN NOT NULL DEFAULT FALSE,
    daily_stock_entries_opening_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_opening_stock >= 0),
    daily_stock_entries_new_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_new_stock >= 0),
    daily_stock_entries_daily_sales NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_daily_sales >= 0),
    daily_stock_entries_stock_received NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_stock_received >= 0),
    daily_stock_entries_closing_stock NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_closing_stock >= 0),
    daily_stock_entries_cash_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_cash_amount >= 0),
    daily_stock_entries_cheque_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_cheque_amount >= 0),
    daily_stock_entries_rtgs_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_rtgs_amount >= 0),
    daily_stock_entries_auto_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_auto_amount >= 0),
    daily_stock_entries_credit_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (daily_stock_entries_credit_amount >= 0),
    daily_stock_entries_total_collection NUMERIC(12, 2) GENERATED ALWAYS AS (
        daily_stock_entries_cash_amount +
        daily_stock_entries_cheque_amount +
        daily_stock_entries_rtgs_amount +
        daily_stock_entries_auto_amount
    ) STORED,
    daily_stock_entries_note TEXT DEFAULT '',
    daily_stock_entries_created_by UUID REFERENCES users(users_id) ON DELETE SET NULL,
    daily_stock_entries_created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    daily_stock_entries_updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_daily_stock_entries_date_product_active
    ON daily_stock_entries (daily_stock_entries_entry_date DESC, daily_stock_entries_products_id)
    WHERE daily_stock_entries_is_delete = FALSE;

CREATE INDEX IF NOT EXISTS idx_daily_stock_entries_salesman_active
    ON daily_stock_entries (daily_stock_entries_salesmen_id)
    WHERE daily_stock_entries_is_delete = FALSE;

DROP TRIGGER IF EXISTS trg_daily_stock_entries_updated_at ON daily_stock_entries;
CREATE TRIGGER trg_daily_stock_entries_updated_at
    BEFORE UPDATE ON daily_stock_entries
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
