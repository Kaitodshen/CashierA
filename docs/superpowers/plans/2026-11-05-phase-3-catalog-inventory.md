# Phase 3: Catalog, Inventory and Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- Owners manage the catalog and import or export it as CSV/XLSX in the back office.
- Terminals keep an offline copy of the catalog and their store's stock, and record stock in, stock out and opname offline.

**Architecture:**
- **Server side:** atomic writes go through three new RPCs: `save_product`, `import_catalog` and `stock_overview`. Single-row master data such as categories and suppliers uses direct table writes under the Phase 1 RLS policies.
- **Import parsing:** pure Dart in `cashiera_core`, so it is unit-tested without Flutter.
- **Terminal mirror:** each table is pulled by `updated_at` cursor (with a 5-minute overlap) plus tombstones by id. Realtime on `stock_levels` triggers a stock refresh.

**Spec:**
- [phase-0 §4.2 (sync down), §4.6 (stock)](../../phase-0-architecture.md)
- [supabase/README §5](../../../supabase/README.md)
- [docs/templates/README.md](../../templates/README.md) (import columns and rules)

## Global Constraints

- The template columns, in order: `product_name, variant_name, sku, barcode, category, unit, price, cost, taxable, track_stock, reorder_point, stock_<STORE CODE>...`
- **Prices:** whole rupiah digits only. `Rp 25.000` is rejected with an explanation.
- **Quantities:** decimals with `.` or `,`, at most 3 decimals.
- **Import limits:** at most 5,000 rows. The import is all-or-nothing in one database transaction.
- **Stock columns** set on-hand stock ("this is what I counted"). They are applied as one stock opname per store, so movement history shows why stock changed.
- **Terminal quantities** are integer thousandths. Server quantities are numeric(14,3).
- **Permissions:**
  - `catalog.manage` for catalog writes and imports.
  - `inventory.adjust` for stock in and out.
  - `inventory.opname` for counts.
  - `inventory.view` / `reports.view` to see stock.
- Terminals never overwrite local stock with a server pull while stock-changing items are still in the outbox.

## Review Focus

1. **A CSV saved by Excel in Indonesian locale** uses `;` separators, decimal commas and a UTF-8 BOM. It must import (core parser tests).
2. **Re-importing the same file** must not duplicate products or variants. SKUs match case-insensitively (pgTAP).
3. **An import where one row is bad** (unknown unit, duplicate barcode) must change nothing. The error names the row (core + pgTAP).
4. **A pull that runs while an offline stock adjustment is still queued** must not undo the local change (pull-service test).
5. **A product deleted on the server** disappears from the terminal through tombstones (pull-service test).

---

### Task 1: Server RPCs (migration `20261105001400_catalog_rpc.sql`, test `120_catalog.test.sql`)

- `save_product(p jsonb) -> jsonb {product_id}`. Upserts the product, its variants (by id; variants missing from the payload are deactivated, not deleted) and per-store settings `{store_id, price_override, reorder_point, is_available}`. Requires `catalog.manage`. Store overrides also accept `pricing.store_override` for that store.
- `import_catalog(p_rows jsonb) -> jsonb {categories_created, products_created, products_updated, variants_created, variants_updated, stock_lines}`. Requires `catalog.manage`. Stock is applied through `app.complete_opname` per store, and the caller needs `inventory.opname` there.
- `stock_overview(p_store_id uuid) -> table(variant_id, product_id, sku, barcode, product_name, variant_name, category_name, unit_code, quantity, reorder_point, is_low)`. Security invoker, so RLS applies.
- `catalog_export() -> table(... template columns ..., stock jsonb)`. Security invoker.
- pgTAP checks:
  - import creates categories, products and variants
  - re-import updates and does not duplicate
  - a bad unit rolls the whole import back
  - stock is set via opname movements
  - a manager without `catalog.manage` is refused
  - `save_product` deactivates removed variants
  - `stock_overview` flags low stock and stays scoped to the caller's stores

### Task 2: Core import/export (`packages/cashiera_core/lib/src/catalog_csv.dart`)

- `CatalogImport parseCatalogTable(List<List<String>> rows, {required Set<String> unitCodes, required Set<String> storeCodes})` returns `rows: List<CatalogImportRow>` and `issues: List<ImportIssue(row, column, code)>`.
- `List<List<String>> decodeCsv(String text)` handles the BOM, `,` or `;` (detected from the header) and quotes.
- `String encodeCatalogCsv(List<CatalogExportRow> rows, List<String> storeCodes)`
- Tests:
  - the template file parses into 4 rows with no issues
  - `;` + decimal comma + BOM
  - `Rp 25.000` gives `price_format`
  - duplicate SKU gives `duplicate_sku` on the second row
  - unknown unit gives `unknown_unit`
  - inconsistent product rows give `product_mismatch`
  - unknown `stock_XYZ` gives a header issue
  - a missing required column
  - more than 5,000 rows
  - an encode → decode round trip

### Task 3: Terminal mirror (Drift schema v2) and `CatalogPullService`

- Tables: `categories`, `units`, `products`, `product_variants`, `store_variant_settings`, `modifier_groups`, `modifiers`, `product_modifier_groups`, `store_favorites`, `stock_levels`. The migration from v1 creates them.
- `CatalogSource` interface:
  - `fetchChanged(TableSpec, DateTime since, {int offset})`
  - `fetchTombstones(int afterId)`
  - Implemented over Supabase.
- `CatalogPullService.pull({bool includeStock})` returns `PullSummary`.
- Tests:
  - first pull loads everything
  - cursor overlap is idempotent
  - a tombstone deletes the row locally
  - stock is skipped while the outbox has stock-changing items
  - JSON numeric quantities become milli

### Task 4: Terminal screens

- `/pos/catalog`: search by name, SKU or barcode (HID scanners type and press Enter, then an exact match opens), category chips, price (store override first), stock and a low-stock badge.
- Item sheet: stock in or out (`stock_adjustment.create`, plus the local stock change in the same transaction).
- `/pos/opname`: enter counts, then `stock_opname.submit`, and local stock is set to the counts.
- Both actions are hidden unless the on-duty staff member has the permission.

### Task 5: Back-office screens

A shell with navigation: Home, Products, Categories, Suppliers, Stock, Import/Export.
- **Product editor:** variants, per-store price and reorder point.
- **Stock page:** store picker, low-only filter, movement history and adjust dialog (via `sync_push`), plus open low-stock alerts with "resolve".
- **Import page:** pick a CSV/XLSX file, see a preview with row-level issues, then import. Also download the template and export as CSV or XLSX.

### Task 6: Verify

- `flutter analyze` and `dart analyze` report no issues.
- All Dart tests, the database tests and the web build pass.
- READMEs are updated.

## As built (deviations)

- One more RPC, `catalog_export()`, returns the catalog in import shape so export → edit → import round-trips.
- Opname numbers from an import get a 4-character random suffix (`IMPORT-<stamp>-<store>-xxxx`), because two imports in the same second collided.
- Riverpod codegen cannot put Drift row types in provider signatures, so the terminal catalog exposes plain models (`CatalogItem`, `CatalogCategory`).
- XLSX uses `excel_plus`, and file picking and saving use `file_picker` 13 (`FilePicker.saveFile` downloads on web).
- Verified on 2026-11-05: `flutter analyze` and `dart analyze` clean; app 70 tests, core 23 tests, database 14 files / 251 assertions; `flutter build web` succeeds. Not yet exercised against a live Supabase project (no Docker on this PC).
