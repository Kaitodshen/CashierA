# Phase 2: Flutter Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter workspace that boots into the right shell, pairs a terminal, switches staff by PIN offline, and syncs a durable write queue to `sync_push`.

> **As built (deviations):**
> - No pub workspace: Flutter 3.47.8 pins `test_api` 0.7.12, which conflicts with `build_runner` 2.16 inside one resolution. `app/` depends on `packages/cashiera_core` by path instead.
> - `PinPad` takes `onSubmitted` with 4–6 digits and an OK key, not a fixed `length`.
> - `PairingApi` and `StaffApi` were merged into `TerminalBackend`.
> - The UI reads `SyncItem` rather than Drift rows, because riverpod_generator can't see Drift's generated types.

**Architecture:** `app/` (Flutter) plus `packages/cashiera_core/` (pure Dart). The app is feature-first:
- `core/` holds the database, sync, auth, design system and l10n.
- `features/` holds the screens.
- All backend calls sit behind small interfaces (`PairingApi`, `StaffApi`, `SyncTransport`), so the logic is tested with fakes and an in-memory Drift database.

**Tech Stack:** Flutter 3.47.8 / Dart 3.13, Riverpod 3 (`@riverpod` codegen), go_router 18, Drift 2.35 + drift_flutter, supabase_flutter 2.18, connectivity_plus 7.3.1, flutter_secure_storage 11, bcrypt 1.2, uuid 4.6 (v7), intl + gen-l10n, toastification, skeletonizer.

**Spec:** [docs/phase-0-architecture.md](../../phase-0-architecture.md) §4.1–4.3, §4.9–4.10, §5, and [supabase/README.md](../../../supabase/README.md) §4–6.

## Global Constraints

- Money: integer rupiah only. Display format `Rp 25.000`; negative values `-Rp 2.000`.
- `sync_queue` columns: id, entity, action, payload, client_uuid, created_at, retry_count, status (`PENDING` / `SYNCING` / `FAILED` / `DONE`), plus last_error and next_attempt_at.
- Every local write and its queue row go in one Drift transaction. Client ids are UUID v7.
- Retry: transient errors back off 2 s, 4 s, 8 s and so on, capped at 300 s with ≤20% jitter. A `rejected` result goes to FAILED, with a manual retry. A FAILED item never blocks later items.
- PIN: 4–6 digits, tap your name first. 5 wrong tries lock that person for 5 minutes. Hashes are pgcrypto bcrypt (`$2a$`).
- Header shows Online/Offline and the count of PENDING + SYNCING + FAILED items.
- Dark theme for POS: bg `#0F172A`, surface `#1E293B`, primary `#6366F1`, secondary `#14B8A6`, text `#F8FAFC`. Light theme for back office: bg `#F8FAFC`, surface `#FFFFFF`, text `#1E293B`. Status colors `#10B981` / `#F59E0B` / `#EF4444`. Radius 12/16, touch targets ≥48dp, breakpoint 600dp.
- Font: Plus Jakarta Sans, bundled from google/fonts under the OFL.
- Languages: Bahasa Indonesia (default) and English. No hard-coded UI strings.
- Web builds the back-office shell only. Drift is never opened on web.

## Review Focus

1. **App killed mid-sync** leaves items stuck in SYNCING. On engine start, SYNCING rows go back to PENDING (test in Task 4).
2. **Same queue item enqueued twice** (double tap) must not produce two rows. `client_uuid` is unique, and enqueue returns the existing id (Task 4).
3. **A device clock changed backwards** must not freeze retries forever. Due items are any with `next_attempt_at <= now`, and a manual retry clears `next_attempt_at` (Task 4).
4. **A roster refresh while someone is locked out** must keep the lockout. Attempts live in their own table, keyed by employee (Task 5).
5. **Starting without SUPABASE_URL / ANON key** must show a setup screen, not crash (Task 3).

---

### Task 1: Workspace, core package, money formatting

**Files:** root `pubspec.yaml` (workspace: app, packages/cashiera_core); `packages/cashiera_core/{pubspec.yaml, analysis_options.yaml, lib/cashiera_core.dart, lib/src/money.dart, lib/src/rounding.dart, lib/src/qty.dart}`; `packages/cashiera_core/test/*_test.dart`.

**Produces:**
- `extension type const Money(int rupiah)` with `+`, `-`, `format() -> String`.
- `int divRoundHalfUp(int numerator, int denominator)`.
- `extension type const Qty(int milli)` with `Qty.parse(String)`, `toPayload() -> String` (3 decimals), and `Money times(Money unitPrice)` (half-up).

- [ ] Tests:
  - `Money(25000).format() == 'Rp 25.000'`, `Money(-2000).format() == '-Rp 2.000'`, `Money(0).format() == 'Rp 0'`, `Money(1250000).format() == 'Rp 1.250.000'`
  - `divRoundHalfUp(27500000, 11100) == 2477`, `divRoundHalfUp(5, 2) == 3`
  - `Qty.parse('1.25').milli == 1250`, `Qty.parse('2').toPayload() == '2.000'`
  - `Qty.parse('0.250').times(Money(42000)) == Money(10500)`
  - `Qty.parse('1.2345')` throws `FormatException`
- [ ] Run `dart test` in packages/cashiera_core and see it fail. Implement. Run it again and see it pass.

### Task 2: Flutter app scaffold, design system, l10n

**Files:**
- `flutter create --org com.cashiera --project-name cashiera --platforms android,ios,windows,macos,web app`
- `app/pubspec.yaml`, `app/l10n.yaml`, `app/analysis_options.yaml` (very_good_analysis, minus `public_member_api_docs`)
- `app/assets/fonts/`
- `app/lib/core/design_system/{tokens.dart, theme.dart, breakpoints.dart, widgets/{pin_pad.dart, status_chip.dart, empty_state.dart, toasts.dart}}`
- `app/lib/core/l10n/arb/{app_id.arb, app_en.arb}`

**Produces:**
- `AppTokens` colors, spacing and radii
- `AppTheme.pos()` (dark), `AppTheme.backOffice()` (light)
- `PinPad({required int length, required ValueChanged<String> onCompleted, bool enabled})`
- `SyncStatusChip({required bool online, required int pending})`

- [ ] Widget tests:
  - PinPad: tapping 4,8,2,9,1,3 calls `onCompleted('482913')` once; backspace removes a digit.
  - SyncStatusChip: online=false, pending=3 shows `Offline · 3 tertunda` under the `id` locale.

### Task 3: Config, Supabase client, router and shells

**Files:**
- `app/lib/core/config/env.dart`: `AppEnv.fromEnvironment()`, `bool get isConfigured`
- `app/lib/core/network/{supabase_client.dart, secure_session_storage.dart, connectivity.dart}`
- `app/lib/app/{app.dart, router.dart, app_mode.dart}`
- `app/lib/main.dart`, `app/lib/bootstrap.dart`

**Produces:**
- `enum AppMode { setupRequired, signedOut, terminalLocked, terminalUnlocked, backOffice }`
- `String? redirectFor(AppMode mode, String location)`, a pure function
- `@riverpod Stream<bool> online(Ref)`

- [ ] Unit tests for `redirectFor`, covering every mode × {`/setup`, `/welcome`, `/pair`, `/lock`, `/pos`, `/sync`, `/admin`, `/admin/sign-in`}:
  - setupRequired → `/setup`
  - signedOut → `/welcome` (except `/pair` and `/admin/sign-in`)
  - terminalLocked → `/lock`
  - terminalUnlocked → `/pos` unless on `/sync`
  - backOffice → `/admin`
  - On web, `/pair` and `/lock` redirect to `/admin/sign-in`.

### Task 4: Drift database and sync engine

**Files:**
- `app/lib/core/database/{app_database.dart, tables.dart, connection.dart}`
- `app/lib/core/sync/{sync_item.dart, sync_queue_dao.dart, sync_transport.dart, supabase_sync_transport.dart, backoff.dart, sync_engine.dart, sync_providers.dart}`

**Tables:** `sync_queue`, `local_device`, `local_stores`, `local_store_settings`, `local_staff`, `pin_attempts`, `sync_cursors`.

**Produces:**

- `SyncQueueDao`:

  | Method | Returns |
  |---|---|
  | `enqueue({required String entity, required String action, required Map<String, Object?> payload, String? clientUuid})` | `Future<String>` (client uuid); must be called inside the caller's transaction |
  | `nextDue(DateTime now)` | `Future<SyncItem?>` |
  | `markSyncing(int id)` | |
  | `markDone(int id)` | |
  | `markFailed(int id, String error)` | |
  | `scheduleRetry(int id, DateTime at, String error)` | |
  | `retryFailed(int id)` | |
  | `resetInterrupted()` | |
  | `watchOutstanding()` | `Stream<int>` |
  | `watchItems()` | `Stream<List<SyncItem>>` |

- `sealed class SyncResponse` with subclasses `SyncApplied(Map result)`, `SyncDuplicate(Map result)` and `SyncRejected(String code, String message)`. `class SyncTransientException implements Exception`.
- `abstract interface class SyncTransport { Future<SyncResponse> push(SyncItem item); }`
- `Duration retryDelay(int retryCount, {double jitter})`
- `SyncEngine(dao, transport, clock)` with `runOnce() -> Future<SyncRunSummary>`

Tests (in-memory `NativeDatabase.memory()` and a fake transport):

| Test | Expectation |
|---|---|
| `applied_marks_done` | |
| `duplicate_marks_done` | |
| `rejected_marks_failed_and_continues_with_next` | |
| `transient_schedules_retry_and_stops_run` | retry_count 1, next_attempt_at = now + 2 s |
| `not_retried_before_due` | |
| `manual_retry_requeues_failed` | |
| `fifo_order` | |
| `enqueue_same_uuid_once` | |
| `interrupted_syncing_reset_on_start` | |
| `transaction_rollback_drops_queue_row` | |
| `outstanding_counts_pending_syncing_failed` | |
| `retryDelay` | 0 → 2 s, 1 → 4 s, 8 → 300 s (cap), jitter within 20% |

### Task 5: Pairing, staff roster, offline PIN login, back-office sign-in

**Files:**
- `app/lib/core/auth/{pairing_api.dart, staff_api.dart, supabase_auth_apis.dart, device_session_repository.dart, staff_roster_repository.dart, pin_verifier.dart, session_controller.dart}`
- `app/lib/features/{setup, welcome, pairing, pin_login, pos_home, sync_status, back_office}/presentation/*.dart`

**Produces:**
- `PairingApi.pair(String code, {required String platform, required String appVersion}) -> Future<PairedDevice>`
- `StaffApi.fetchRoster() -> Future<List<StaffMember>>`
- `PinVerifier.verify(String employeeId, String pin) -> Future<PinResult>`, where `PinResult` is one of ok, mismatch(attemptsLeft), locked(until) or noPin
- `SessionController`, an `@riverpod` notifier exposing `AppMode` plus the current staff member

Tests:

| Test | Expectation |
|---|---|
| pgcrypto fixture | The hash of `482913` made by pgcrypto `crypt(.., gen_salt('bf', 10))` verifies |
| `mismatch_counts_down` | 4, 3, 2, 1 attempts left |
| `fifth_wrong_locks_for_5_minutes` | |
| `unlocks_after_5_minutes` | uses a fake clock |
| `success_resets_attempts` | |
| `roster_refresh_keeps_lockout` | |
| `normalizePairingCode(' abcd-2345 ') == 'ABCD2345'` | |
| `isValidPairingCode` | rejects `O`, `0`, `I`, `1` and wrong lengths |

### Task 6: Verify and document

- [ ] `flutter analyze` (app) and `dart analyze` (core): no issues.
- [ ] `flutter test` and `dart test`: all pass.
- [ ] `flutter build web`: succeeds.
- [ ] Update `README.md` with how to run, including the `--dart-define` keys and the database test command.
