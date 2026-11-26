# SSRSM Accounts

> **Client:** Sai Ram Marketing (SSRSM)  
> **Built by:** FDHS Solutions · `fdhssolutions@gmail.com`

Digital daily stock & collection register (*Bahi-Khata*) for managing brand-wise godown stock, salesman collections, analytics, and PDF/Excel reports.

---

## Key Features

- **4 Brand Ledgers:** Dettol, Dabur, Diaper, and Wholesale.
- **Daily Stock Entries:** Auto-filled opening stock, live closing stock calculation (`Opening + New - Daily Sales + Stock Received`), and multi-mode collections (`Cash`, `Cheque`, `RTGS`, `Auto`, `Credit`).
- **Salesman Management:** Add, edit, and soft-delete salesmen per brand.
- **Dashboard Analytics:** Date/range & brand filters, collection by payment mode, salesman breakdown, and daily trends.
- **Reports & Export:** Register view with bulk delete, A4 Landscape PDF export, and Excel export.
- **Security & Auth:** Single-admin JWT authentication (`bcryptjs`), rate limiting, and **6-digit email OTP Forgot Password**.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Dart) |
| **Backend API** | Node.js, Express 5, Zod, Pino, PDFKit |
| **Database** | PostgreSQL (`tableName_column_name` schema) |

---

## Default Login

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `Admin@1234` |

*(Password can be changed or reset anytime via **Forgot password?** in the app.)*

---

## Quick Local Setup

```bash
# 1. Apply PostgreSQL schema & seed
psql -U postgres -d ssrsm_accounts -f database/schema.sql
psql -U postgres -d ssrsm_accounts -f database/seed.sql

# 2. Configure & start backend
cd backend
cp .env.example .env   # fill DB_*, JWT_SECRET, SMTP_*, RESET_PASSWORD_EMAIL
npm install
npm run dev

# 3. Run Flutter app
cd ../frontend
flutter pub get
flutter run
```

---

## Useful Backend Commands

```bash
npm test            # Run Vitest unit & integration tests
npm run db:seed     # Seed default admin, products, and salesmen
npm run db:backup   # Create timestamped pg_dump in database/backups/
npm run db:restore  # Restore latest backup from database/backups/
```
