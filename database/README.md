# SSRSM Database Setup

## PostgreSQL Schema & Seed
- `schema.sql`: Contains DDL for `users`, `products`, `salesmen`, and `daily_stock_entries` using the `tableName_column_name` convention, partial unique indexes for soft deletes, `CHECK` constraints, and `updated_at` triggers.
- `seed.sql`: Idempotent seed data for the default admin account (`admin` / `Admin@1234`) and initial brands (`Dettol`, `Dabur`, `Diaper`, `Wholesale`) — no dummy salesmen or entries.
- `backups/`: Directory for local `pg_dump` backups created via `npm run db:backup`.

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
   *(Or run `npm run db:seed` from `backend/` to seed via Node.js with a fresh `bcryptjs` hash.)*
