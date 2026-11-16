# SSRSM Database Setup

## PostgreSQL Schema & Migrations
- `schema.sql`: Contains DDL for users, products, salesmen, daily_stock_registers, and register_collections.
- `seed.sql`: Seed data for default admin, initial brands (Dettol, Dabur, Diaper), and salesmen.

### How to run locally:
1. Create Database:
   ```bash
   createdb -U postgres ssrsm_accounts
   ```
2. Run Schema:
   ```bash
   psql -U postgres -d ssrsm_accounts -f database/schema.sql
   ```
3. Run Seed Data:
   ```bash
   psql -U postgres -d ssrsm_accounts -f database/seed.sql
   ```