# Stores and Staff Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the owner set up a fresh production project from the back office: stores, staff, PINs, and email invitations for back-office logins.

**Architecture:**
- **App:** two new back-office pages (Stores, Staff) under the Settings section and a public Set-password page, built on the phase 3 widgets. They read and write through a new `StaffAdminRepository` (direct table writes under the existing RLS, plus the existing `set_employee_pin` RPC).
- **Invitations:** a new Edge Function `staff-invite`. It checks the caller through a new security-definer SQL function `prepare_staff_invite`, invites with the service role, and links the login through a service-role-only SQL function `link_staff_login`.

**Tech Stack:** PostgreSQL 17 + pgTAP on PGlite (`tools/db-test`), Supabase Edge Functions (Deno; logic Node-tested), Flutter 3.47.8 / Dart ^3.13, Riverpod 3, go_router 18.

**Spec:** `docs/superpowers/specs/2026-11-18-stores-and-staff-design.md`

## Global Constraints

- The service-role key never appears in `app/` or in committed files; only the Edge Function reads it from `SUPABASE_SERVICE_ROLE_KEY`.
- No PIN or password is logged, stored in plain text, or written to the audit log.
- Owner is never offered as a role in the app; managers act only on staff of their own stores (the database rules already enforce this, and the UI hides it).
- Stores and staff are deactivated, never deleted.
- Store code: 2–5 characters `[A-Z0-9]`, upper-cased, unique, not editable after creation.
- Store timezones offered: `Asia/Jakarta` (WIB), `Asia/Makassar` (WITA), `Asia/Jayapura` (WIT).
- PIN: 4–6 digits, typed twice; strength rules come from `set_employee_pin`. Password: minimum 8 characters, typed twice.
- Invitation link format: `{{ .SiteURL }}/?token_hash={{ .TokenHash }}&type=invite#/admin/set-password`.
- Every new string in both `app_id.arb` and `app_en.arb`; use phase 3 widgets (`AdminPage`, `AdminToolbar`, `GlassTable`, `GlassDialog`, `StatusChip`, `InitialsAvatar`, `CenteredGlassPage`); no `Card(`, `AlertDialog(` or `FloatingActionButton` (the back-office glass rule test enforces this).
- Checks before each push:
  - `cd tools/db-test && npm test`
  - `cd supabase/functions && npm test`
  - app: `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test`, `flutter build web --release`
  - core: `dart test`

## Review Focus

1. A manager opens Staff: the store checkboxes, the store filter and the Add / Invite / PIN actions cover only their stores, and an owner row shows no actions. Test in Task 4.
2. Inviting an email that already belongs to a login or another employee says so clearly (no second login, no half-linked row). Tests in Tasks 1 and 2.
3. A used or expired invitation link opens the set-password page and shows "ask for a new invitation", not a blank page or the sign-in screen. Test in Task 5.
4. A signed-out visitor on the web can open `/admin/set-password` (the router must not bounce them to sign-in). Test in Task 5.
5. Adding a store makes it appear at once in the store pickers elsewhere (Store settings, Tables, the staff editor). Test in Task 3.

---

### Task 1: Database: `prepare_staff_invite`, `link_staff_login` and `staff_overview`

**Files:**
- Create: `supabase/migrations/20261118002200_staff_invite.sql`
- Test: `supabase/tests/database/210_staff_invite.test.sql`

**Interfaces:**
- Produces:
  - `public.prepare_staff_invite(p_employee_id uuid, p_email text) returns boolean` (true when it is a resend to an unconfirmed linked login). Security definer, executable by `authenticated`. Raises with `app.fail` codes:
    - `permission_denied` (not `app.can_manage_employee(app.current_employee_id(), p_employee_id)`, or caller not an employee),
    - `not_found`,
    - `already_linked` (target has an `auth_user_id` whose `auth.users.email_confirmed_at` is set). A linked login that is still unconfirmed with the same email passes, which is a resend,
    - `invalid_email` (`!~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'`),
    - `email_taken` (another employee's `lower(email)`, or an `auth.users.email` other than the target's own login, matches case-insensitively).
  - `public.staff_overview() returns table (employee_id uuid, has_pin boolean, login_confirmed boolean)`. Security definer, executable by `authenticated`. Returns only employees with `app.can_see_employee(id)`. `has_pin` comes from `employee_pins`; `login_confirmed` from `auth.users.email_confirmed_at is not null`. This is how the app learns PIN and login state, since neither table is readable by clients.
  - `public.link_staff_login(p_employee_id uuid, p_auth_user_id uuid, p_email text) returns void`. Security definer, `revoke all from public, anon, authenticated; grant execute to service_role`. Sets `auth_user_id`, `email = lower(p_email)`, and inserts `audit_log (action 'employee.invited', entity_type 'employee', entity_id p_employee_id, actor_employee_id null)`. Raises `already_linked` if set.

- [ ] **Step 1: Failing pgTAP file `210_staff_invite.test.sql`** (seeded ids, `tests.act_as`), plan(13):
  - As the owner (`tests.id('user.owner')`): `lives_ok` on `prepare_staff_invite(tests.id('emp.fitri'), 'fitri@toko.id')`.
  - As the PST manager (`user.manager_pst`): lives for `emp.fitri` (PST cashier); `throws_like '%permission_denied%'` for `emp.gilang` (BKS) and for `emp.andi` (owner, all stores).
  - As the owner:
    - `already_linked` for `emp.eko` (has a login),
    - `invalid_email` for `'bukan-email'`,
    - `email_taken` for `'OWNER@cashiera.test'`.
  - As `authenticated` (owner): `throws_like '%permission denied%'` calling `link_staff_login`.
  - As the owner, after the link: `prepare_staff_invite(emp.fitri, 'fitri@toko.id')` lives again (an unconfirmed resend). As the PST manager, `staff_overview()` returns PST staff only, and `emp.andi`'s row (seeded PIN) has `has_pin = true`.
  - As service role (`pg_temp.act_as_service()`, copied from 200): `link_staff_login(emp.fitri, <new auth user>, 'Fitri@Toko.id')` lives; then `employees.email = 'fitri@toko.id'`, `auth_user_id` set, and one `audit_log` row `employee.invited`.

  Use the seed's id helper names as they exist in `000_*.sql`; read them before writing.
- [ ] **Step 2: Run** `cd tools/db-test && npm test`. Expected: 210 fails (functions missing).
- [ ] **Step 3: Write the migration** as in Interfaces.
- [ ] **Step 4: Run** `npm test`. Expected: all files pass, including 210.
- [ ] **Step 5: Commit**: `Staff invitations: prepare and link functions`

---

### Task 2: Edge Function `staff-invite`

**Files:**
- Create: `supabase/functions/_shared/staff.ts`, `supabase/functions/staff-invite/index.ts`
- Modify: `supabase/functions/_shared/deno.ts` (add `staffDeps(req)`), `supabase/config.toml` (`[functions.staff-invite]` with `verify_jwt = true`)
- Test: `supabase/functions/tests/staff.test.ts`

**Interfaces:**
- `export type InviteInput = { employee_id: string; email: string }`
- `export interface StaffDb { prepareAsCaller(id: string, email: string): Promise<{ resend: boolean }>; invite(email: string, redirectTo: string, fullName?: string): Promise<{ userId: string }>; link(id: string, userId: string, email: string): Promise<void> }`
- `export type StaffDeps = { db: StaffDb; siteUrl: string }`
- `export async function inviteStaff(input: InviteInput, deps: StaffDeps): Promise<Reply>`:
  - 400 `{error:'invalid_input'}` when a field is missing.
  - Errors from `prepareAsCaller` map to `{error: <code>}` with 403 for `permission_denied` and 409 for the others.
  - An invite error whose message contains "already been registered" maps to 409 `email_taken`.
  - Success is 200 `{ok:true}`. When the employee is already linked (a resend), `link` is skipped. `prepareAsCaller` returns `{ resend: boolean }`, and the SQL function returns `boolean` (true = resend), so change its return type in Task 1 to `returns boolean`.
  - `redirectTo` is `${siteUrl}/#/admin/set-password`.
- `staffDeps(req)`:
  - `prepareAsCaller` uses the caller-token client's `rpc('prepare_staff_invite', …)`.
  - `invite` and `link` use a service-role client (`auth.admin.inviteUserByEmail`, `rpc('link_staff_login')`).
  - `siteUrl` comes from `Deno.env.get('SITE_URL')`.

- [ ] **Step 1: Failing tests in `staff.test.ts`** with a `FakeStaffDb`:
  - Missing email → 400, no invite.
  - `prepareAsCaller` throws `{code:'permission_denied'}` → 403, `invite` and `link` never called.
  - `already_linked` → 409.
  - `invite` throws "User already been registered" → 409 `email_taken`, `link` not called.
  - Success → 200, `invite` got `redirectTo === 'https://bo.example/#/admin/set-password'`, `link` got the returned user id and the email.
  - Resend (`prepareAsCaller` → `{resend:true}`) → 200, `invite` called, `link` not called.
- [ ] **Step 2: Run** `cd supabase/functions && npm test`. Expected: FAIL (module missing).
- [ ] **Step 3: Implement** `staff.ts`, `index.ts` (same shape as `qris-create/index.ts`), `staffDeps`, config entry.
- [ ] **Step 4: Run** `npm test`. Expected: all pass, the existing 15 included.
- [ ] **Step 5: Commit**: `Staff invitations: the staff-invite Edge Function`

---

### Task 3: Repository, navigation and the Stores page

**Files:**
- Create: `app/lib/features/back_office/data/staff_admin_repository.dart`, `app/lib/features/back_office/presentation/stores_admin_screen.dart`
- Modify:
  - `app/lib/features/back_office/presentation/back_office_providers.dart` (providers)
  - `app/lib/app/app_mode.dart` (`adminStores = '/admin/stores'`, `adminStaff = '/admin/staff'`)
  - `app/lib/app/router.dart`
  - `app/lib/features/back_office/presentation/admin_nav.dart` (Settings tabs: Store settings · Stores · Staff · Tables)
- Test: `app/test/features/back_office/stores_admin_test.dart`; update `admin_nav_test.dart` for the two new tabs

**Interfaces:**
- Models in the repository file:
  - `class AdminStore {id, code, name, address?, phone?, timezone, isActive}` with `fromJson`.
  - `class StoreInput {code, name, address?, phone?, timezone, isActive}`.
- `abstract interface class StaffAdmin`:
  - Stores: `Future<List<AdminStore>> stores()`, `Future<void> addStore(StoreInput)`, `Future<void> updateStore(String id, StoreInput)` (code ignored on update).
  - Staff: `Future<List<AdminStaff>> staff()`, `Future<void> saveStaff(StaffInput, {String? id})`, `Future<void> setActive(String id, bool active)`, `Future<void> setPin(String id, String pin)`, `Future<void> invite(String id, String email)`.
  - Implementation: `class SupabaseStaffAdmin implements StaffAdmin`. Staff types are defined in Task 4 but declared here so one interface serves both.
- Providers:
  - `@riverpod StaffAdmin staffAdmin(Ref)` → `SupabaseStaffAdmin(ref.watch(supabaseClientProvider))`.
  - `@riverpod Future<List<AdminStore>> adminStoresList(Ref)`.
  - After add/update the page invalidates `adminStoresListProvider` and `backOfficeStoresProvider`.
- Errors: `StaffAdminException(String code)`. Codes are taken from the PostgREST/RPC message (`permission_denied`, `email_taken`, `already_linked`, `invalid_email`, `invalid_pin`, `weak_pin`, `last_owner`, `owner_only`, `duplicate_code` for unique violation 23505 on `stores.code`), else `unknown`.
- Page:
  - `AdminPage`; toolbar action **Add store** (`Key('store-add')`, owner only via `principal.isOwner`).
  - `GlassTable` rows keyed `store-<code>`: code, name, address · phone, timezone label, active chip.
  - Owner taps a row → `_StoreDialog` (`GlassDialog`) with fields `store-code` (disabled when editing), `store-name`, `store-address`, `store-phone`, `store-timezone`, `store-active`, and Save `store-save`.
- New l10n (at least): `navStores`, `navStaff`, `storesAdd`, `storeCode`, `storeCodeInvalid`, `storeName`, `storeTimezone`, `tzWib`, `tzWita`, `tzWit`, `storesEmpty`, `staffErrorDuplicateCode`.

- [ ] **Step 1: Failing widget tests** with `FakeStaffAdmin` and a principal override:
  - Owner: list shows `store-PST`. **Add store** with code `ab1` saves `StoreInput(code: 'AB1', …)`, and `backOfficeStoresProvider` is re-read (a counter in its override).
  - Code `A` shows `storeCodeInvalid`. A `duplicate_code` error shows its message.
  - Manager principal: no `store-add`, and tapping a row opens nothing.
  - 390×844: no exception.
- [ ] **Step 2: Run** `flutter test test/features/back_office/stores_admin_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** as in Interfaces, routes and tabs included.
- [ ] **Step 4: Run** the file, `admin_nav_test.dart` and the back-office glass rule test. Expected: PASS.
- [ ] **Step 5: Commit**: `Back office: Stores page`

---

### Task 4: Staff page (list, editor, PIN, invite, deactivate)

**Files:**
- Create: `app/lib/features/back_office/presentation/staff_admin_screen.dart`
- Modify: `staff_admin_repository.dart` (staff models and methods)
- Test: `app/test/features/back_office/staff_admin_test.dart`

**Interfaces:**
- Models:
  - `class AdminStaff {id, fullName, phone?, roleCode, roleName, storeIds, email?, hasLogin, loginConfirmed, hasPin, isActive}`. `hasLogin` = `auth_user_id != null`. `hasPin` and `loginConfirmed` come from `rpc('staff_overview')` (Task 1), merged by employee id.
  - `class StaffInput {fullName, phone?, roleCode, storeIds, isActive}`.
- Methods:
  - `saveStaff` inserts or updates `employees`, then reconciles `employee_stores` (delete removed, insert added).
  - `setPin` → `rpc('set_employee_pin', {p_employee_id, p_pin})`.
  - `invite` → `functions.invoke('staff-invite', body: {employee_id, email})`, mapping a non-200 `{error}` to `StaffAdminException`.
- Page:
  - Toolbar: search `staff-search`, store filter `staff-store`, **Add staff** `staff-add` (owner or `employee.manage`).
  - `GlassTable` row `staff-<id>`:
    - person (avatar, name, phone),
    - role chip,
    - stores (codes or `staffAllStores`),
    - login (`staffLoginNone` / `staffLoginInvited` / `staffLoginActive` + email),
    - PIN chip (`staffPinSet` / `staffPinMissing`),
    - active chip,
    - actions menu `staff-actions-<id>` with `staff-pin`, `staff-invite` (only when `!hasLogin`, and "send again" when invited but unconfirmed), `staff-toggle`.
  - Owner rows and rows the viewer cannot manage show no actions.
- Dialogs:
  - Editor: `staff-name`, `staff-phone`, `staff-role` (manager/cashier/kitchen/inventory only), store checkboxes `staff-store-<code>` limited to the viewer's manageable stores, `staff-active`, `staff-save`.
  - PIN: `pin-1`, `pin-2`, `pin-save`; mismatch shows `staffPinMismatch`.
  - Invite: `invite-email`, `invite-send`.
  - Deactivate: a confirm dialog.
- New l10n for every label above and each error code from Task 3's list.

- [ ] **Step 1: Failing widget tests** with `FakeStaffAdmin`:
  - Owner adds cashier "Sari" to PST → `saveStaff(StaffInput(roleCode:'cashier', storeIds:[pst]))`.
  - The role dropdown has 4 items and no owner.
  - PIN `1111` / `1111` with the fake throwing `weak_pin` → the weak-PIN message. `1357` / `1358` → `staffPinMismatch` and no call.
  - Invite `fitri@toko.id` → `invite(id,'fitri@toko.id')`, then the row shows `staffLoginInvited`. `email_taken` shows its message.
  - Deactivate asks first, then `setActive(id,false)`.
  - Manager (PST only): store checkboxes show only PST, the BKS staff row has no actions, and the owner row has no actions.
  - 390×844: no exception.
- [ ] **Step 2: Run** the file. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the file, `flutter test test/features/back_office` and the db tests if Task 1 grew. Expected: PASS.
- [ ] **Step 5: Commit**: `Back office: Staff page with PINs and invitations`

---

### Task 5: Set-password page and the public route

**Files:**
- Create: `app/lib/features/back_office/presentation/set_password_screen.dart`
- Modify: `app/lib/app/app_mode.dart` (`adminSetPassword = '/admin/set-password'`; `redirectFor` lets it through in `signedOut` and `backOffice` modes on web), `app/lib/app/router.dart`, `app/lib/features/back_office/data/back_office_backend.dart` (add `Future<void> acceptInvite(String tokenHash)` and `Future<void> setPassword(String password)`)
- Test: `app/test/features/back_office/set_password_test.dart`; extend `app/test/app/app_mode_test.dart`

**Interfaces:**
- `acceptInvite(tokenHash)` → `auth.verifyOTP(type: OtpType.invite, tokenHash: tokenHash)`. `setPassword(p)` → `auth.updateUser(UserAttributes(password: p))`.
- `SetPasswordScreen({String? tokenHash})`: the router passes `Uri.base.queryParameters['token_hash']`.
  - On open it calls `acceptInvite` once. Failure shows `setPasswordLinkExpired` in a `CenteredGlassPage` with a Back to sign-in button.
  - Success shows `set-password-1`, `set-password-2` and `set-password-save`, with 8-character minimum and match checks (`setPasswordTooShort`, `setPasswordMismatch`), then `setPassword` and `go(AppRoutes.admin)`.

- [ ] **Step 1: Failing tests**:
  - `redirectFor(AppMode.signedOut, '/admin/set-password', isWeb: true)` is null.
  - With a fake backend:
    - `acceptInvite` throwing → expired message, no form.
    - Success → `abc1234` shows too-short; `abcd1234` / `abcd1235` shows mismatch; `abcd1234` twice calls `setPassword('abcd1234')` and navigates to `/admin`.
  - 390×640: no exception.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the files and `test/app`. Expected: PASS.
- [ ] **Step 5: Commit**: `Back office: set password from an invitation`

---

### Task 6: Deploy notes, screenshots, checks, push

- [ ] **Step 1:** In `docs/release/deploy.md`, add "Staff invitations" after section 1:
  - set the site URL;
  - set the `SITE_URL` secret;
  - `supabase functions deploy staff-invite`;
  - change **Authentication → Email Templates → Invite user** to link to the format in Global Constraints;
  - optional SMTP (Resend or Brevo).

  Point section 1 step 4 at `supabase/production/first_owner.sql` and the new pages. Tick nothing in the checklist.
- [ ] **Step 2:** Add `app/test/screenshots/admin_staff_screenshot_test.dart` (tagged): Stores and Staff with fakes, plus the set-password form, at 1280×800 and 390×844. Look at every PNG.
- [ ] **Step 3:** All Global Constraints checks green.
- [ ] **Step 4:** Commit `Stores and staff: deploy notes and screenshots`, push the working branch, send the screenshots.
