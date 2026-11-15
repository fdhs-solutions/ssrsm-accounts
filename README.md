# SSRSM Accounts
> **Client:** Sai Ram Marketing (SSRSM)
> **Built by:** FDHS Solutions · fdhssolutions@gmail.com

A lightweight, offline-first Android app that replaces the client's handwritten daily godown account register (*Bahi-Khata*) with a clean digital ledger — tracking ₹ values across three brand accounts with automatic calculations and cloud backup.

---

## What the App Does

The business owner currently maintains a **physical paper register** with daily entries for three brands. This app digitizes that exact format, automates all the math, and keeps data safe with a cloud backup.

**Three completely separate brand ledgers:**
- Dettol
- Dabur
- Diapers (MamyPoko Pants)

---

## The Ledger Format

Directly mirrors the client's physical register:

| S.No | Date | O/P (Opening) | Incoming (+) | Daily Sales (−) | R/T Return (+) | Total (Godown) | Cash | Cheque | RTGS | Total Collection |
|:---:|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 11/11/2026 | ₹ 35,00,000 | ₹ 0 | ₹ 1,25,000 | ₹ 5,000 | **₹ 33,80,000** | ₹ 80,000 | ₹ 25,000 | ₹ 20,000 | **₹ 1,25,000** |
| 2 | 12/11/2026 | ₹ 33,80,000 | ₹ 5,00,000 | ₹ 1,80,000 | ₹ 10,000 | **₹ 37,10,000** | ₹ 1,00,000 | ₹ 50,000 | ₹ 30,000 | **₹ 1,80,000** |

### Auto-Calculations

**Godown Total:**
```
Total = O/P (Opening) + Incoming (+) − Daily Sales (−) + R/T Return (+)
```

**Collection Total:**
```
Total Collection = Cash + Cheque + RTGS
```

**Auto Roll-Forward:** The next day's `O/P (Opening)` is automatically filled from the previous day's `Total (Godown Value)`. No manual copying.

**Cascading Recalculation:** If any past entry is edited or deleted, all subsequent rows recalculate automatically — just like correcting a column in a spreadsheet.

---

## Core Features

| Feature | Description |
|---|---|
| **3 Brand Ledgers** | Dettol, Dabur, Diapers — each completely separate |
| **Daily Entry** | Add date, incoming stock, sales, and returns — totals auto-calculate |
| **Edit / Delete** | Modify any past entry; cascading recalc keeps everything accurate |
| **Dashboard** | Combined summary: total godown value, today's sales, today's collection |
| **Reports** | Filter by Daily / Monthly / Yearly / Custom date range |
| **Export** | One-tap PDF print + Excel (.xlsx) export per brand |
| **Language Toggle** | English and Hindi (हिन्दी) — switchable at any time |
| **Offline First** | 100% works without internet; data lives on-device |
| **Cloud Backup** | Automatic backup to server when connected; restore on new device |
| **Single Admin Login** | One account for the business owner — no employees, no roles |

---

## App Navigation

**Splash Screen → Login → App**

```
Top Bar:   [ ← Back ]  SSRSM  [ EN / HI ]  [ Logout ]

Body:      Screen content (Dashboard / Ledger / Reports)

Bottom Nav:
  🏠 Home   📒 Ledger   📊 Reports   📤 Export
```

**Inside Ledger tab** → Brand selector chips (Dettol · Dabur · Diapers) → that brand's daily table.

---

## Login

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `Admin123` |

Single admin only. No self-registration. No multi-user.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile App | **Flutter (Dart)** | Android mobile + tablet UI |
| On-Device DB | **SQLite / Drift** | Local storage, works 100% offline |
| Cloud Backup API | **Node.js** | Receives and stores backup data |
| Cloud Database | **PostgreSQL** | Secure cloud backup storage |
| PDF / Print | **Flutter Print** | Native Android PDF and printer support |

---

## Offline-First Architecture

```
┌────────────────────────────────┐
│   ANDROID DEVICE               │
│   Flutter App  ◄──►  SQLite   │  ← All daily work happens here
│   (100% offline capable)       │
└──────────────┬─────────────────┘
               │  Background sync when online
               ▼
┌────────────────────────────────┐
│   CLOUD SERVER                 │
│   Node.js API  ◄──►  PostgreSQL│  ← Backup only
└────────────────────────────────┘
```

- Daily entries, edits, reports — all instant, no internet needed
- When online: auto-syncs backup to cloud silently in background
- Admin can also trigger manual backup or restore anytime

---

## UI Standards

- Minimum 48×48 dp touch targets — comfortable for counter use
- Indian number formatting: `₹ 35,00,000` (not `₹ 3,500,000`)
- Mobile and tablet responsive — no desktop layout needed
- Clean, high-contrast typography — readable in godown lighting
- FontAwesome icons throughout for fast visual recognition

---

*Developed by FDHS Solutions · fdhssolutions@gmail.com*
