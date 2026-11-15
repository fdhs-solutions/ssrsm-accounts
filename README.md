# SSRSM-ACCOUNTS

> **Wholesale Inventory & Accounts Management System**  
> A lightweight, offline-first wholesale management system built with Flutter for Android mobile & tablet devices, featuring on-device local execution and automated cloud backup to a Node.js & PostgreSQL server.

---

## 📌 Project Overview

**SSRSM-ACCOUNTS** is purpose-built for a wholesale distribution business transitioning from handwritten physical registers to a streamlined, automated digital solution. The system eliminates manual calculation errors, stock discrepancies, and untracked shop credit balances through automated calculations and immediate searchable access.

### Primary Objectives

- **100% Offline Independence:** Full functionality without internet access. Counter billing, inventory adjustments, and reports work seamlessly offline.
- **Lightweight & High-Speed:** Zero network latency. All searches, stock lookups, and transaction entries process instantly against embedded local storage.
- **Digitize Handwritten Day-Books:** Replace physical paper registers with rapid, touch-friendly digital entries.
- **Automate Math:** Remove human calculation error from daily stock roll-forwards, customer credit balances, and cash drawer reconciliations.
- **Single Administrator Focus:** Tailored for a single business owner—free of multi-tenant, role-based, or enterprise complexity.
- **Cloud Backup & Disaster Recovery:** Automatic and on-demand cloud backups to a secure Node.js + PostgreSQL server whenever an internet connection is available.

---

## 💻 Technology Stack

| Layer                         | Technology               | Details                                                                                                              |
| :---------------------------- | :----------------------- | :------------------------------------------------------------------------------------------------------------------- |
| **Mobile & Tablet App**       | **Flutter (Dart)**       | Lightweight, touch-first Android interface optimized for mobile and tablet devices with native rendering speed.      |
| **Local Storage (On-Device)** | **SQLite / Drift**       | Embedded local database powering 100% offline transactions, instant search, and zero-latency counter operations.     |
| **Cloud Backup API**          | **Node.js**              | Lightweight REST service handling admin authentication, secure backup data ingestion, and disaster restore services. |
| **Cloud Database**            | **PostgreSQL**           | Cloud database preserving periodic backups, transactional integrity, and point-in-time recovery archives.            |
| **Printing & Reports**        | **Flutter Print Engine** | Local on-device PDF generation and direct printing via Android print framework (thermal & standard).                 |

---

## 🔄 Offline-First & Cloud Backup Architecture

```
 ┌─────────────────────────────────────────────────────────────┐
 │                ANDROID DEVICE (PHONE / TABLET)              │
 │                                                             │
 │   ┌─────────────────┐               ┌───────────────────┐   │
 │   │  Flutter Touch  │ ──Instant──►  │ Embedded Local DB │   │
 │   │   UI / Logic    │ ◄──Queries─── │     (SQLite)      │   │
 │   └────────┬────────┘               └─────────┬─────────┘   │
 └────────────┼──────────────────────────────────┼─────────────┘
              │                                  │
     Runs 100% Offline                  Background Sync
     No Internet Required               When Online
              │                                  │
              ▼                                  ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                     REMOTE CLOUD SERVER                     │
 │                                                             │
 │   ┌─────────────────┐               ┌───────────────────┐   │
 │   │  Node.js Backup │ ────────────► │    PostgreSQL     │   │
 │   │     Service     │ ◄─Restore──── │  Backup Database  │   │
 │   └─────────────────┘               └───────────────────┘   │
 └─────────────────────────────────────────────────────────────┘
```

- **Zero-Latency Daily Operations:** All product lookups, sale billings, credit ledger updates, and stock calculations run directly against the on-device database.
- **Seamless Offline Billing:** The business owner can continue full operations in basements, warehouses, or areas with poor cellular coverage.
- **Automated Cloud Backup:** Whenever the device connects to Wi-Fi or mobile data, the app safely synchronizes incremental backups to the remote server.
- **One-Tap Manual Backup & Restore:** The admin can trigger an instant cloud backup anytime or restore complete historical records onto a new device if hardware is replaced.

---

## 🔐 Authentication & Access Control

The application is strictly designed for **single-user operation** by the business owner:

- **Single Administrator Login:** Pre-configured secure admin account.
- **No Self-Registration:** Registration workflows and employee account creation are intentionally omitted.
- **No Role Hierarchy:** Full, unrestricted access to all modules under the admin profile.
- **Password Management:** Secure in-app password update mechanism and safe session logout.
- **Secure Handling:** Encrypted credential verification; no plain-text credentials stored in code.

---

## 📦 Core Business Modules & Workflows

### 1. Product & Category Management

- **Single-Entry Creation:** Categories and products are registered once in master records to prevent duplicate or inconsistent names.
- **Searchable Autocomplete:** During daily billing or stock entry, products are selected using rapid, searchable dropdowns—eliminating repetitive typing.
- **Initial Catalog:** Pre-seeded categories including:
  - `Dettol`
  - `Dabur`
  - `Diapers`
- **Dynamic Catalog:** Ability to introduce new categories and products at any time without disrupting historical transactions.

---

### 2. Inventory Management & Automated Roll-Forward

Maintains daily product-wise stock records with automated continuity:

$$\text{Closing Stock} = \text{Opening Stock} - \text{Stock Sold} + \text{Sellable Returned Stock} \pm \text{Audited Adjustments}$$

- **Automatic Roll-Forward:** The opening stock of any day automatically carries forward from the verified closing stock of the preceding day.
- **Invalid Deduction Protection:** System blocks negative stock deductions during normal sales entries.
- **Stock Corrections & Adjustments:** Dedicated adjustment utility with mandatory reason logging for physical count discrepancies, breakage, or expired goods.
- **Category-Wise Stock Aggregation:** Real-time visibility into overall stock volumes grouped by category.

---

### 3. Sales Management & Wholesale Billing

- **Customer / Shop Records:** Record transactions against specific retailer accounts (e.g., _Sharma General Store_, _Gupta Medical_).
- **Streamlined Amount Entry:** Prioritizes quick amount and quantity entry over cumbersome unit-conversion steps, matching fast-paced counter workflows.
- **Credit Sales & Partial Payments:** Supports full credit sales, partial upfront settlements, and custom line-item remarks.
- **Customer Sales History:** Complete chronological log of all sales invoices per customer.

---

### 4. Customer Ledger & Pending Payment Tracking

- **Running Ledger Balance:** Real-time computation of net shop liabilities:
  $$\text{Outstanding Balance} = \sum \text{Sales} - \sum \text{Valid Payments} - \sum \text{Return Credits}$$
- **Persistent Pending Alerts:** Outstanding shop dues remain prominently displayed on the dashboard and customer profile until cleared in full.
- **Settlement Records:** Tracks payments received against historical credit balances, updating the outstanding figure automatically.

---

### 5. Multi-Mode Payment & Collection Tracking

Sales and collections are strictly decoupled to allow advance payments, round settlements, and partial collections:

- **Cash:** Direct counter cash collections.
- **RTGS / Bank Transfers:** Electronic bank settlements with reference numbers.
- **Cheque:** Tracked with distinct statuses (`Pending`, `Cleared`, or `Bounced`). A bounced cheque automatically restores the customer's outstanding balance.
- **Auto Collection:** Dedicated tracking for cash collected by auto-rickshaw delivery personnel during goods distribution routes.
- **Mode-Wise Totals:** Distinct totals for Cash, RTGS, Cheque, and Auto Collection visible at all times.

---

### 6. Returns & Damaged Stock Management

Clear distinction between returned goods to safeguard salable inventory integrity:

- **Sellable Returns:** Resalable goods returned by shops that automatically restock available inventory and issue credit to the shop's balance.
- **Damaged Returns:** Damaged or defective goods tracked separately for vendor return; **never** added to available sellable stock.
- **Audit History:** Full return logs detailing customer, item, condition, quantity, and reason.

---

### 7. Executive Dashboard & Daily Closing Summary

- **At-a-Glance Dashboard:**
  - Total Available Stock (overall & category-wise breakdown)
  - Today's Total Sales
  - Today's Collections (split into Cash, RTGS, Cheque, and Auto Collection)
  - Total Market Outstanding Balances
- **Daily Closing & Reconciliation:**
  - End-of-day summary comparing recorded system cash against physical drawer cash.
  - Clear highlight of cash discrepancies or collection mismatches.
  - Permanent historical archive of daily closing summaries.

---

### 8. Reports & Native Android PDF / Printing

- **Supported Reporting Ranges:**
  - Daily
  - Monthly
  - Quarterly
  - Yearly
  - Custom Date Range
- **Report Types:**
  - Sales Summary (shop-wise and product-wise)
  - Inventory & Stock Movement Summary
  - Collection Summary by Payment Mode
  - Customer Outstanding & Credit Ageing
  - Daily Business Closing Summary
- **Android Print & PDF Engine:**
  - Formatted for direct PDF generation and Android system printing (compatible with standard and mobile thermal printers).
  - Clean, high-contrast tabular design.
  - _(Excel export is intentionally excluded to maintain clean mobile workflows)._

---

## 🎨 UI/UX Design Standards

- **Touch-First Controls:** Large touch targets (minimum 48x48 dp) for effortless operation in warehouse and shop counter environments.
- **Fast Search Selectors:** Instant filtering for shops and products with minimal keyboard interaction.
- **Dual Form-Factor Support:**
  - **Phones:** Bottom tab navigation, vertical card feeds, single-thumb interactive zones.
  - **Tablets:** Master-detail split screens, multi-column metric tiles, and side-by-side ledger inspection.
- **High Contrast & Readability:** Clean typography and legible status badges (`Cleared`, `Pending`, `Bounced`, `Damaged`).
