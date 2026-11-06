# Phase 8: F&B, Kitchen Display, Transfers and Purchasing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- **Purchasing:** a purchase order is created, sent and received (in parts) with stock and cost updated.
- **Transfers:** stock is requested, approved, shipped and received between stores, and a difference is flagged.
- **F&B stores:** dine-in bills sit on tables, items are routed to the kitchen or bar (kitchen display and station printers), and the kitchen moves tickets from new to served.

**Architecture:**
- **What already exists:**
  - stock transfers (`request_stock_transfer`, `transition_stock_transfer`)
  - goods receipts that update the PO, stock and weighted cost
  - kitchen tickets (`order_status`) created from line stations
  - `kitchen.status` and `dining_table.status` sync
- **Migration 2000 adds atomic RPCs with names for the screens:**
  - `save_purchase_order`, `set_purchase_order_status`, `receive_purchase_order`
  - `purchase_order_detail`, `purchase_order_list`
  - `transfer_list`, `transfer_detail`
  - `kitchen_queue`
- **Back office:** Pembelian (purchase orders) and Transfer pages; Meja (dining tables and the store's F&B switch).
- **Terminal:**
  - lines carry their kitchen station
  - dine-in bills on tables (Meja screen)
  - **Kirim ke dapur** holds the bill and prints a ticket per station
  - a Dapur screen (KDS, online) with the live queue

**Tech stack:** existing stack, no new packages.

**Spec:** [phase-0 A12, A13, §4.6 transfers and receipts, §4.7 kitchen routing, §8 Phase 8](../../phase-0-architecture.md).

## Global Constraints

- Purchasing, transfers and the kitchen display are online (A12). Selling dine-in works offline, and tickets reach the kitchen when the bill syncs.
- Purchase order status:
  - `draft → ordered → partially_received → received`
  - `draft|ordered → cancelled`, only before anything is received
  - Items change only while the PO is draft or ordered and nothing has been received.
  - A receipt may not exceed what is still open on a line (`receipt_exceeds_order`).
- Transfers keep the existing rules. The sender approves and ships (`transfer.approve`); the receiver receives (`inventory.receive`).
- Kitchen stations are `kitchen` or `bar`. A product's station wins over its category's. Lines without a station make no ticket.
- F&B screens show only when `stores.fnb_mode` is on (all three demo stores are retail, A13).

## Review Focus

1. **A receipt in two parts:** the PO goes `ordered → partially_received → received`; stock rises each time and the cost is averaged (pgTAP).
2. **Receiving more than ordered, or cancelling after a receipt:** refused (pgTAP).
3. **A shipped 10, received 9 transfer:** `TRANSFER_DISCREPANCY`, and the detail shows both figures (pgTAP).
4. **A dine-in bill with kitchen and bar items:** two tickets, each listing only its station's items (pgTAP `kitchen_queue`). The terminal sends each line's station (app test).
5. **Two bills for one table:** the second is refused on the terminal while the first is open (app test).

---

### Task 1: Server (`2000_purchasing_fnb.sql`, pgTAP `190_purchasing_fnb.test.sql`)
- **Purchase orders:**
  - `save_purchase_order(p)`: `{id?, store_id, supplier_id, expected_date, note, items[{variant_id, quantity_ordered, unit_cost}]}` saves the header and replaces the items. Needs `purchase.manage`.
  - `set_purchase_order_status(id, status)`: `ordered` or `cancelled`. Audited.
  - `receive_purchase_order(p)`: `{purchase_order_id, note, items[{purchase_order_item_id, quantity, unit_cost?}]}` creates one goods receipt, numbered `GR-<STORE>-yyMMdd-NNN`. Needs `inventory.receive`.
  - `purchase_order_detail(id)` and `purchase_order_list(store_id, status)`, with names.
- **Transfers:** `transfer_list(store_id, direction, status)` and `transfer_detail(id)`, with store, employee and item names.
- **Kitchen:** `kitchen_queue(station)`: the terminal's store; active tickets with order number, table, age and that station's items, oldest first.

### Task 2: Back office
- **Pembelian:**
  - list (store and status filters)
  - editor (supplier, store, expected date, item picker, qty, cost, total)
  - Simpan (draft), Pesan (ordered), Batalkan
  - detail with received vs ordered, **Terima barang** (quantities and cost per line) and a PDF for the supplier
- **Transfer:**
  - list (incoming and outgoing), new request
  - detail with the actions the person may take: approve or reject, ship with quantities, receive with quantities, cancel
- **Meja:** per store, the F&B switch (owner) and the tables (name, area, capacity, active).

### Task 3: Terminal
- `CatalogItem.kitchenStation` (product, else category) → `CartLine.kitchenStation` → `kitchen_station` in the payload. The cart gains `orderType`, `tableId`, `tableName` and `guestCount`.
- Mirror `dining_tables` (store-scoped, JSON).
- **Meja screen (F&B stores):**
  - a grid of tables; a table is occupied when a local open bill is on it, else the server status
  - tap a free table to start a dine-in bill (guests)
  - tap an occupied table to resume its bill
  - **Kosongkan meja** sends `dining_table.status` available
- **Kirim ke dapur:** holds the bill, then prints one ticket per station on the `kitchen` / `bar` printer when set up. Each ticket has the order, table, time and items with modifiers and notes.
- Printer setup gets three slots: receipt, kitchen and bar.
- **Dapur screen:**
  - station filter
  - live queue (refreshes every 10 s and on Realtime changes to `order_status`)
  - tickets coloured by age, with **Mulai**, **Siap** and **Disajikan** (`kitchen.status`)

### Task 4: Verify
- `dart format` and the analyzers are clean.
- Core, app and database tests pass.
- `flutter build web` succeeds.
- Docs are updated, and the plan gets its "As built" notes.

## As built (deviations)

- **"Two tickets" means one per station.** A dine-in bill with food and a drink prints two tickets: one in the kitchen, one at the bar. Each holds only its own items (`fnb_flow_test.dart`, pgTAP `190`).
- **Tickets print only what is new.** The cart keeps `kitchenSent` (line → quantity sent). Sending again prints the added quantity, marked TAMBAHAN. There is no reprint of a whole ticket.
- **No schema change on the terminal:**
  - `dining_tables` is a JSON mirror.
  - The kitchen and bar printers are rows `kitchen` / `bar` in `local_printers`.
  - The Drift version is unchanged.
- **Occupied tables:**
  - This terminal refuses a second bill on a table with one of its own held bills (`table_occupied`, in `OrderService.hold` and `complete`).
  - A bill from another terminal shows through the table status from the last pull. Such a table can't be opened here.
  - The server keeps the first bill as `current_order_id`.
- **The kitchen display is online only.**
  - It reads `kitchen_queue` and listens to Realtime on `order_status` for the store.
  - Offline it keeps the last list; status changes still queue in the outbox.
  - Realtime is not covered by the tests: they use a fake queue source.
- **Receiving goods:**
  - A cost is sent only when it was changed.
  - The RPC accepts a receipt note, but the screen doesn't ask for one.
- **Back-office buttons follow the person's permission set from `current_principal`.** The RPCs still check each store, so a button may appear for a store where the server then refuses.
- **Verified on 2026-11-07:**
  - `dart format` and the analyzers are clean.
  - Tests pass: core 122, app 156, database 21 files / 412 assertions.
  - `flutter build web` succeeds.
  - New app tests:
    - `fnb_service_test.dart`: payload fields, cart JSON, tickets per station and additions, the second bill on a table refused, table listing and clearing, `kitchen.status` needing `kitchen.view`
    - `fnb_flow_test.dart`: seat Meja 7, send to the kitchen (two printers), resume, addition; kitchen display filter and Mulai → Siap → Disajikan
    - `purchasing_screens_test.dart`: over-receipt refused, receive with a new cost; a new PO; a transfer received short (9 of 10)
- **Not done:** running on a real kitchen printer or a live Supabase project.
