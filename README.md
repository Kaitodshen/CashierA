# CashierA

A multi-store point of sale and back office for Indonesian retail, offline-first on cashier terminals, built with Flutter and Supabase.

| Phase | Status | Where |
|---|---|---|
| 0 · Architecture, folder structure, packages, risks | ✅ done | [docs/phase-0-architecture.md](docs/phase-0-architecture.md) |
| 1 · Database: schema, RLS, triggers, sync RPCs, seed, tests | ✅ done | [supabase/README.md](supabase/README.md) |
| 2 · Flutter core: theme, routing, Riverpod, Drift, pairing, PIN login, sync queue | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-05-phase-2-flutter-core.md) |
| 3 · Catalog, inventory, CSV/XLSX import and export | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-05-phase-3-catalog-inventory.md), [import template](docs/templates/README.md) |
| 4 · Cashier: pricing engine, cart, promos, vouchers, split payments, kasbon, receipts | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-06-phase-4-cashier.md) |
| 5 · Shift close, X/Z reports, cash in/out, voids, refunds, approvals, audit log, thermal printing and drawer | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-06-phase-5-shifts-printing.md) |
| 6 · Customers, loyalty points, kasbon ledger and installments | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-07-phase-6-customers-loyalty-kasbon.md) |
| 7 · Dashboard and reports (sales, payments, products, staff, tax, stock value) with PDF/Excel export | ✅ done | [app/README.md](app/README.md), [plan](docs/superpowers/plans/2026-11-07-phase-7-reports.md) |
| 8 · F&B tables, KDS, transfers, purchase orders | next | — |
| 9 | planned | see the phase plan in the architecture doc |

## Run the tests

Database (embedded Postgres, no Docker):

```bash
cd tools/db-test && npm install && npm test
```

Flutter app:

```bash
cd app && flutter test
```

Money and quantity rules:

```bash
cd packages/cashiera_core && dart test
```

## Run the app

```bash
cd app && flutter run -d chrome --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable key>
```

See [app/README.md](app/README.md) for terminals (Android and Windows need Android Studio or Visual Studio installed).

## Layout

```text
app/         Flutter app: POS shell (terminals) + back-office shell (web/phone)
packages/    cashiera_core: pure-Dart money, quantity, rounding, catalog CSV, pricing, promotions, payments, shift reports, refunds and ESC/POS printing
supabase/    config, migrations, demo seed, pgTAP tests
tools/       db-test: runs migrations + tests on embedded Postgres
docs/        architecture, phase plans, catalog import template
```
