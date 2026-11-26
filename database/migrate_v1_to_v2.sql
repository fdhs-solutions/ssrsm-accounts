-- SSRSM Accounts: v1 -> v2 Migration Script
-- Date: 2026-11-26
-- Upgrades schema to tableName_column_name, creates users (admin / Admin@1234),
-- preserves products, and clears salesmen & daily_stock_entries for a clean production start.

BEGIN;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW := jsonb_populate_record(NEW, jsonb_build_object(TG_TABLE_NAME || '_updated_at', CURRENT_TIMESTAMP));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Create users table if missing & seed default admin
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

INSERT INTO users (users_username, users_email, users_password_hash, users_role)
VALUES (
    'admin',
    'admin@ssrsm.local',
    '$2b$10$arAhCbYDlgyNVmGFnLU9vu1OSCrW/oYkDOg.1EvjnzzLqIlXQQhZG',
    'admin'
)
ON CONFLICT (users_username) DO NOTHING;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 2. Migrate products columns to products_*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'products' AND column_name = 'id'
    ) THEN
        ALTER TABLE products RENAME COLUMN id TO products_id;
        ALTER TABLE products RENAME COLUMN name TO products_name;
        ALTER TABLE products RENAME COLUMN category TO products_category;
        ALTER TABLE products RENAME COLUMN default_opening_stock TO products_default_opening_stock;
        ALTER TABLE products RENAME COLUMN is_active TO products_is_active;
        ALTER TABLE products RENAME COLUMN is_delete TO products_is_delete;
        ALTER TABLE products RENAME COLUMN created_at TO products_created_at;
        ALTER TABLE products RENAME COLUMN updated_at TO products_updated_at;
    END IF;
END $$;

ALTER TABLE products DROP CONSTRAINT IF EXISTS products_name_key;
CREATE UNIQUE INDEX IF NOT EXISTS uq_products_name_active
    ON products (LOWER(products_name))
    WHERE products_is_delete = FALSE;

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3. Migrate salesmen columns to salesmen_*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'salesmen' AND column_name = 'id'
    ) THEN
        ALTER TABLE salesmen RENAME COLUMN id TO salesmen_id;
        ALTER TABLE salesmen RENAME COLUMN product_id TO salesmen_products_id;
        ALTER TABLE salesmen RENAME COLUMN name TO salesmen_name;
        ALTER TABLE salesmen RENAME COLUMN phone TO salesmen_phone;
        ALTER TABLE salesmen RENAME COLUMN is_active TO salesmen_is_active;
        ALTER TABLE salesmen RENAME COLUMN is_delete TO salesmen_is_delete;
        ALTER TABLE salesmen RENAME COLUMN created_at TO salesmen_created_at;
        ALTER TABLE salesmen RENAME COLUMN updated_at TO salesmen_updated_at;
    END IF;
END $$;

ALTER TABLE salesmen DROP CONSTRAINT IF EXISTS uq_salesman_product;
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

-- 4. Migrate daily_stock_entries columns to daily_stock_entries_*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'daily_stock_entries' AND column_name = 'id'
    ) THEN
        ALTER TABLE daily_stock_entries RENAME COLUMN id TO daily_stock_entries_id;
        ALTER TABLE daily_stock_entries RENAME COLUMN entry_date TO daily_stock_entries_entry_date;
        ALTER TABLE daily_stock_entries RENAME COLUMN product_id TO daily_stock_entries_products_id;
        ALTER TABLE daily_stock_entries RENAME COLUMN salesman_id TO daily_stock_entries_salesmen_id;
        ALTER TABLE daily_stock_entries RENAME COLUMN serial_no TO daily_stock_entries_serial_no;
        ALTER TABLE daily_stock_entries RENAME COLUMN is_extra_entry TO daily_stock_entries_is_extra_entry;
        ALTER TABLE daily_stock_entries RENAME COLUMN is_active TO daily_stock_entries_is_active;
        ALTER TABLE daily_stock_entries RENAME COLUMN is_delete TO daily_stock_entries_is_delete;
        ALTER TABLE daily_stock_entries RENAME COLUMN opening_stock TO daily_stock_entries_opening_stock;
        ALTER TABLE daily_stock_entries RENAME COLUMN new_stock TO daily_stock_entries_new_stock;
        ALTER TABLE daily_stock_entries RENAME COLUMN daily_sales TO daily_stock_entries_daily_sales;
        ALTER TABLE daily_stock_entries RENAME COLUMN stock_received TO daily_stock_entries_stock_received;
        ALTER TABLE daily_stock_entries RENAME COLUMN closing_stock TO daily_stock_entries_closing_stock;
        ALTER TABLE daily_stock_entries RENAME COLUMN cash_amount TO daily_stock_entries_cash_amount;
        ALTER TABLE daily_stock_entries RENAME COLUMN cheque_amount TO daily_stock_entries_cheque_amount;
        ALTER TABLE daily_stock_entries RENAME COLUMN rtgs_amount TO daily_stock_entries_rtgs_amount;
        ALTER TABLE daily_stock_entries RENAME COLUMN auto_amount TO daily_stock_entries_auto_amount;
        ALTER TABLE daily_stock_entries RENAME COLUMN credit_amount TO daily_stock_entries_credit_amount;
        ALTER TABLE daily_stock_entries RENAME COLUMN total_collection TO daily_stock_entries_total_collection;
        ALTER TABLE daily_stock_entries RENAME COLUMN note TO daily_stock_entries_note;
        ALTER TABLE daily_stock_entries RENAME COLUMN created_by TO daily_stock_entries_created_by;
        ALTER TABLE daily_stock_entries RENAME COLUMN created_at TO daily_stock_entries_created_at;
        ALTER TABLE daily_stock_entries RENAME COLUMN updated_at TO daily_stock_entries_updated_at;
    END IF;
END $$;

DROP INDEX IF EXISTS idx_stock_entries_date_product;
DROP INDEX IF EXISTS idx_stock_entries_salesman;

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

-- 5. Clear dummy/test entries and salesmen for a clean production start
TRUNCATE TABLE daily_stock_entries, salesmen CASCADE;

COMMIT;
