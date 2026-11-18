import { strict as assert } from 'node:assert';
import { test } from 'node:test';

import { type InviteInput, inviteStaff, type StaffDb } from '../_shared/staff.ts';

/** Records what the handler asked for; failures are scripted per test. */
class FakeStaffDb implements StaffDb {
  invites: Array<{ email: string; redirectTo: string; fullName?: string }> = [];
  links: Array<[string, string, string]> = [];
  prepareError: Error | null = null;
  resend = false;
  inviteError: Error | null = null;

  async prepareAsCaller(_id: string, _email: string): Promise<{ resend: boolean }> {
    if (this.prepareError) throw this.prepareError;
    return { resend: this.resend };
  }

  async invite(email: string, redirectTo: string, fullName?: string): Promise<{ userId: string }> {
    if (this.inviteError) throw this.inviteError;
    this.invites.push({ email, redirectTo, fullName });
    return { userId: 'user-1' };
  }

  async link(id: string, userId: string, email: string): Promise<void> {
    this.links.push([id, userId, email]);
  }
}

const coded = (code: string) => Object.assign(new Error(code), { code });
const deps = (db: FakeStaffDb) => ({ db, siteUrl: 'https://bo.example' });
const input: InviteInput = { employee_id: 'emp-1', email: 'fitri@toko.id' };

test('a missing email is refused before anything else', async () => {
  const db = new FakeStaffDb();
  const r = await inviteStaff({ employee_id: 'emp-1', email: '' }, deps(db));
  assert.equal(r.status, 400);
  assert.deepEqual(r.body, { error: 'invalid_input' });
  assert.equal(db.invites.length, 0);
});

test('no permission: nothing is sent and nothing is linked', async () => {
  const db = new FakeStaffDb();
  db.prepareError = coded('permission_denied');
  const r = await inviteStaff(input, deps(db));
  assert.equal(r.status, 403);
  assert.deepEqual(r.body, { error: 'permission_denied' });
  assert.equal(db.invites.length, 0);
  assert.equal(db.links.length, 0);
});

test('an already linked employee is a conflict', async () => {
  const db = new FakeStaffDb();
  db.prepareError = coded('already_linked');
  const r = await inviteStaff(input, deps(db));
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: 'already_linked' });
});

test('an email the auth server already knows is email_taken, and nothing is linked', async () => {
  const db = new FakeStaffDb();
  db.inviteError = new Error('A user with this email address has already been registered');
  const r = await inviteStaff(input, deps(db));
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: 'email_taken' });
  assert.equal(db.links.length, 0);
});

test('a first invitation is sent to the set-password page and linked', async () => {
  const db = new FakeStaffDb();
  const r = await inviteStaff({ ...input, full_name: 'Fitri' }, deps(db));
  assert.equal(r.status, 200);
  assert.deepEqual(r.body, { ok: true });
  assert.deepEqual(db.invites, [
    { email: 'fitri@toko.id', redirectTo: 'https://bo.example/#/admin/set-password', fullName: 'Fitri' },
  ]);
  assert.deepEqual(db.links, [['emp-1', 'user-1', 'fitri@toko.id']]);
});

test('a resend invites again without linking again', async () => {
  const db = new FakeStaffDb();
  db.resend = true;
  const r = await inviteStaff(input, deps(db));
  assert.equal(r.status, 200);
  assert.equal(db.invites.length, 1);
  assert.equal(db.links.length, 0);
});
