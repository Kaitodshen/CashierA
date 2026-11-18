# Stores and staff in the back office

Date: 2026-11-18 · Status: design for owner approval

## 1. Why

A new production project starts empty. After `supabase/production/first_owner.sql` creates the first owner, everything else must be possible from the back office. Today nothing is: there is no page to add a store, add staff, set a PIN, or give a manager a back-office login. On the old project the demo seed hid this gap.

Success: on a fresh project, the owner signs in and, without opening the Supabase dashboard again:
- adds the stores,
- adds managers, cashiers, kitchen and inventory staff to them,
- sets their PINs,
- invites managers by email.

An invited manager sets a password from the email and signs in. Cashiers pair a terminal, refresh the staff list and sign in with their PIN.

## 2. Goals, non-goals, anti-goals

Goals:
- **Stores page:** list, add and edit stores (code, name, address, phone, timezone, active).
- **Staff page:** list, add and edit staff (name, phone, role, stores, active); set or reset a PIN; invite to the back office by email.
- **Set-password page:** the invitation link opens it; the manager chooses a password and lands in the back office.
- **Who may act** follows the database rules that already exist:
  - Stores: owner only.
  - Staff: the owner for everyone; a manager with `employee.manage` only for staff of their own stores, never for all-stores roles.

Non-goals (later, separate work):
- Editing roles and permissions.
- "Forgot password" for people who already have a login.
- Deleting stores or staff (deactivate instead; history must keep its names).
- Transferring ownership.
- CAPTCHA.

Anti-goals (a failure even if it works):
- The service-role key ever reaching the app or the repository.
- A manager able to invite or edit staff outside their stores, or to create an owner.
- A PIN or password shown, logged or stored in plain text anywhere.

## 3. What exists (verified in the code)

- **RLS:**
  - `stores_insert` and `stores_update` allow the owner.
  - `employees_insert` needs `employee.manage`; `employees_update` and `employee_stores_insert`/`delete` use `app.can_manage_employee`.
  - The trigger `app.guard_employee_changes` stops non-owners from creating or changing all-stores employees and keeps one active owner.
- **Store trigger:** a trigger on `stores` creates its `store_settings` and default payment methods.
- **PINs:** `public.set_employee_pin(p_employee_id, p_pin)` sets a PIN (4–6 digits, refuses repeated digits and simple sequences) and writes the audit log. `employee_pins` has no client access.
- **Terminals:** they pick up staff with **Muat ulang staf** (`refreshRoster`).
- **Edge Functions:** pure logic lives in `supabase/functions/_shared/handlers.ts` with injected deps, tested with Node (`npm test` in `supabase/functions`). `deno.ts` builds a Supabase client that carries the caller's `Authorization` header, so database rules apply to the caller.
- **Back office:**
  - Routes use hash URLs (`/#/admin/...`).
  - The Settings section has the tabs Store settings and Tables.
  - Phase 3 widgets are available: `AdminPage`, `AdminToolbar`, `FormSection`, `GlassTable`, `GlassDialog`, `StatusChip`, `InitialsAvatar`.
- **Email:**
  - No SMTP is configured; Supabase's built-in sender is rate-limited (a few emails an hour) and may land in spam.
  - No page handles an invitation or recovery link today.

## 4. Approaches considered

1. **Dashboard login, linked by email in the app.** Smallest, no server code, but the owner keeps opening the dashboard. Not chosen.
2. **Invitation email from the app** — **chosen by the owner.** An Edge Function holds the service-role key, checks the caller, creates the login and sends the invitation; a new page sets the password.
3. **Temporary password shown to the owner.** No email setup, but the owner handles someone else's password. Not chosen.

## 5. Design

### 5.1 Navigation

Settings section tabs become **Store settings · Stores · Staff · Tables**, with routes `/admin/stores` and `/admin/staff`. Both tabs show to anyone who can open the section. The pages hide what the person may not do, and the database refuses it anyway.

### 5.2 Stores page

- **Toolbar:** **Add store** (owner only).
- **List:** `GlassTable` with code, name, address · phone, timezone, and an active `StatusChip`. Tapping a row opens the editor (owner only).
- **Editor (`GlassDialog`):** code (2–5 letters/digits, upper-cased, unique), name (required), address, phone, timezone (Asia/Jakarta, Asia/Makassar, Asia/Jayapura), active.
- **Saving:** writes `stores` directly under RLS. After adding a store, the stores list used everywhere (`backOfficeStoresProvider`) refreshes, so the new store appears in Store settings, Tables and the staff editor.

### 5.3 Staff page

- **Toolbar:** search by name, store filter, **Add staff** (owner, or `employee.manage`).
- **List:** `GlassTable`:
  - Person: `InitialsAvatar`, name, phone.
  - Role chip.
  - Stores: codes, or "All stores" for the owner.
  - Back-office login: none / invited / active, with the email.
  - PIN: set / not set.
  - Active chip.
- **Editor (`GlassDialog`):** full name (required), phone, role (manager, cashier, kitchen, inventory; owner is never offered), stores (one or more; checkboxes limited to stores the editor may manage), active. It is saved as an `employees` row plus `employee_stores` rows.
- **Row actions:**
  - **Set PIN:** a dialog with the PIN typed twice, sent to `set_employee_pin`. Server messages are shown in Indonesian (invalid, too weak, not allowed).
  - **Invite to back office:** shown when the person has no login. A dialog asks for the email and calls the `staff-invite` function. Afterwards the row shows "invited · email".
  - **Deactivate / reactivate:** a confirm dialog, then `is_active` changes. The database refuses to deactivate the last owner, with its own message.

### 5.4 The `staff-invite` Edge Function

- **Input:** `POST {employee_id, email}` with the caller's JWT.
- **Steps** (logic in `_shared/staff.ts`, deps injected, Node-tested like the QRIS handlers):
  1. As the caller, call a new SQL function `public.prepare_staff_invite(p_employee_id uuid, p_email text) returns void`, security definer. It fails with:
     - `permission_denied` unless `app.can_manage_employee(current employee, p_employee_id)`,
     - `already_linked` if the employee already has a login,
     - `email_taken` if another employee or auth user has that email (case-insensitive),
     - `invalid_email`.
     It also refuses all-stores targets, which `can_manage_employee` already covers for managers.
  2. With the service role: `auth.admin.inviteUserByEmail(email, { redirectTo: <back office>/#/admin/set-password, data: { full_name } })`.
  3. With the service role: set `employees.auth_user_id` and `employees.email`.
  4. Write `audit_log` (`employee.invited`).
- **Reply:** `{ok: true}`, or `{error: <code>}` with HTTP 4xx. The app maps codes to Indonesian messages.
- **Configuration:**
  - Secrets: `SITE_URL`, the back-office address, read by the function. The service-role key is the one Supabase provides to functions.
  - Deployed like the QRIS functions (`supabase functions deploy staff-invite`).

### 5.5 Set-password page and the invitation link

- **The problem:** the default invitation link returns tokens in the URL fragment, which collides with the app's hash routes.
- **The fix:**
  - The **Invite user** email template is changed (dashboard, documented in `docs/release/deploy.md`) to link to `{{ .SiteURL }}/?token_hash={{ .TokenHash }}&type=invite#/admin/set-password`.
  - The page reads `token_hash` and `type` from the query and calls `auth.verifyOTP(type: invite, tokenHash)`.
  - It shows **new password** twice (minimum 8 characters, matching the project setting) and calls `auth.updateUser(password)`.
  - Then it goes to `/admin`.
- **Errors:** an expired or used link shows a glass message asking the owner to send a new invitation. "Send again" on an invited-but-unconfirmed row re-runs the invite.
- **Layout:** `CenteredGlassPage`, like sign-in.

### 5.6 Email setup (documented, not code)

- `docs/release/deploy.md` gains a "Staff invitations" section:
  - Set the site URL.
  - Edit the Invite template.
  - Optionally connect an SMTP provider (Resend or Brevo) for volume and deliverability.
- The built-in sender works for the first few invitations.

## 6. Testing

- **Database (pgTAP, `supabase/tests`):** `prepare_staff_invite` allows the owner, allows a manager for their store's cashier, and refuses:
  - a manager for another store's staff,
  - any all-stores target,
  - an already-linked employee,
  - a taken email,
  - a malformed email.
- **Edge Function (Node):** the handler stops when `prepare_staff_invite` fails (no invite sent, no link written); sends the invite and links on success; maps an auth "already registered" error to `email_taken`.
- **App (widget tests with repository fakes):**
  - Stores: add and edit as the owner; read-only for a manager.
  - Staff: add a cashier to a store; the role list never offers owner; set PIN shows the server's weak-PIN message; invite shows "invited" afterwards; deactivate asks first.
  - Set password: mismatch and short passwords are refused; success navigates to `/admin`; an expired link shows the resend message.
  - Phone (390 px): no overflow on either page.
- **Live check:** on the new project, after deploy, with the owner's own second email.

## 7. Left to the builder

- Exact column flex, copy and Indonesian strings (both ARB files).
- Whether the store code is editable after creation (suggested: no, since receipts and document numbers use it).
- Repository and provider names, following `back_office/data/*_repository.dart` and `back_office_providers.dart`.
