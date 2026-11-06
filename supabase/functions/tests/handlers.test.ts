import { strict as assert } from 'node:assert';
import { test } from 'node:test';

import {
  cancelQris,
  type Charge,
  createQris,
  type Deps,
  type GatewayDb,
  handleNotification,
  type OpenInput,
} from '../_shared/handlers.ts';
import { type ChargeStatus, signatureKey } from '../_shared/midtrans.ts';

const key = 'SB-Mid-server-TEST';

/** An in-memory gateway_charges with the database's rules (paid is final,
 * amounts must match). */
class FakeDb implements GatewayDb {
  charges = new Map<string, Charge>();
  settles: Array<[string, ChargeStatus]> = [];

  async open(input: OpenInput): Promise<Charge> {
    const existing = this.charges.get(input.id);
    if (existing) return existing;
    const c: Charge = { id: input.id, status: 'pending', amount: input.amount };
    this.charges.set(c.id, c);
    return c;
  }

  async statusAsCaller(id: string): Promise<Charge> {
    const c = this.charges.get(id);
    if (!c) throw Object.assign(new Error('charge_not_found'), { code: 'charge_not_found' });
    return c;
  }

  async attach(id: string, ref: string, qr: string, expiresAt: string | null): Promise<Charge> {
    const c = { ...(await this.statusAsCaller(id)), provider_ref: ref, qr_string: qr, expires_at: expiresAt };
    this.charges.set(id, c);
    return c;
  }

  async settle(id: string, status: ChargeStatus, gross: number | null) {
    const c = await this.statusAsCaller(id);
    if (gross != null && gross !== c.amount) {
      throw Object.assign(new Error('amount_mismatch'), { code: 'amount_mismatch' });
    }
    this.settles.push([id, status]);
    const changed = c.status !== 'paid' && status !== 'pending' && status !== c.status;
    const next = changed ? { ...c, status } : c;
    this.charges.set(id, next);
    return { ...next, changed };
  }
}

/** Fake Midtrans: records calls, answers from [state]. */
function midtrans(state: { status: string; gross?: string; known?: boolean }) {
  const calls: Array<{ url: string; method: string; body?: unknown; auth?: string }> = [];
  const fetchFn = (async (url: string, init: RequestInit = {}) => {
    const headers = init.headers as Record<string, string>;
    calls.push({
      url,
      method: init.method ?? 'GET',
      body: init.body ? JSON.parse(init.body as string) : undefined,
      auth: headers?.Authorization,
    });
    let json: Record<string, unknown>;
    if (url.endsWith('/v2/charge')) {
      json = {
        status_code: '201',
        transaction_id: 'trx-1',
        transaction_status: 'pending',
        qr_string: 'QR-DATA',
        expiry_time: '2026-11-07 12:15:00',
      };
    } else if (url.endsWith('/cancel')) {
      json = { status_code: state.status === 'settlement' ? '412' : '200', transaction_status: 'cancel' };
      if (state.status !== 'settlement') state.status = 'cancel';
    } else if (state.known === false) {
      json = { status_code: '404', status_message: "Transaction doesn't exist." };
    } else {
      json = {
        status_code: '200',
        transaction_id: 'trx-1',
        transaction_status: state.status,
        gross_amount: state.gross ?? '25500.00',
      };
    }
    return new Response(JSON.stringify(json), { status: 200 });
  }) as unknown as typeof fetch;
  return { calls, fetchFn };
}

function deps(db: FakeDb, fetchFn: typeof fetch): Deps {
  return { db, fetch: fetchFn, serverKey: key, isProduction: false };
}

const input: OpenInput = {
  id: 'pay-1',
  store_id: 's-1',
  payment_method_id: 'm-qd',
  order_id: 'o-1',
  order_number: 'PST-T1-261107-0001',
  amount: 25500,
};

async function notification(status: string, gross = '25500.00', statusCode = '200') {
  return {
    order_id: 'pay-1',
    status_code: statusCode,
    gross_amount: gross,
    transaction_status: status,
    transaction_id: 'trx-1',
    signature_key: await signatureKey('pay-1', statusCode, gross, key),
  };
}

test('create: one Midtrans charge, retried calls reuse the QR', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'pending' });
  const first = await createQris(input, deps(db, mt.fetchFn));
  assert.equal(first.status, 200);
  assert.equal(first.body.qr_string, 'QR-DATA');
  assert.equal(first.body.expires_at, '2026-11-07T12:15:00+07:00');
  assert.equal(mt.calls.length, 1);
  assert.equal(mt.calls[0].url, 'https://api.sandbox.midtrans.com/v2/charge');
  assert.equal(mt.calls[0].auth, 'Basic ' + btoa(key + ':'));
  assert.deepEqual((mt.calls[0].body as { transaction_details: unknown }).transaction_details, {
    order_id: 'pay-1',
    gross_amount: 25500,
  });

  const again = await createQris(input, deps(db, mt.fetchFn));
  assert.equal(again.body.qr_string, 'QR-DATA');
  assert.equal(mt.calls.length, 1, 'no second charge at Midtrans');
});

test('create without a server key says so', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'pending' });
  const r = await createQris(input, { ...deps(db, mt.fetchFn), serverKey: '' });
  assert.equal(r.status, 502);
  assert.equal(r.body.error, 'gateway_not_configured');
});

test('webhook: a bad signature is refused and changes nothing', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'settlement' });
  await createQris(input, deps(db, mt.fetchFn));
  const forged = { ...(await notification('settlement')), signature_key: 'f'.repeat(128) };
  const r = await handleNotification(forged, deps(db, mt.fetchFn));
  assert.equal(r.status, 401);
  assert.equal(db.charges.get('pay-1')!.status, 'pending');
});

test('webhook: settlement marks it paid, using the status Midtrans reports', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'settlement' });
  await createQris(input, deps(db, mt.fetchFn));
  const r = await handleNotification(await notification('settlement'), deps(db, mt.fetchFn));
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'paid');
  assert.equal(mt.calls.at(-1)!.url, 'https://api.sandbox.midtrans.com/v2/pay-1/status');

  // A repeat, then a late expire: still paid.
  assert.equal((await handleNotification(await notification('settlement'), deps(db, mt.fetchFn))).body.changed, false);
  const late = midtrans({ status: 'expire' });
  await handleNotification(await notification('expire', '25500.00', '407'), deps(db, late.fetchFn));
  assert.equal(db.charges.get('pay-1')!.status, 'paid');
});

test('webhook: a signed notification for another amount is ignored', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'settlement', gross: '1.00' });
  await createQris(input, deps(db, mt.fetchFn));
  const r = await handleNotification(await notification('settlement', '1.00'), deps(db, mt.fetchFn));
  assert.equal(r.status, 200, 'Midtrans should stop retrying');
  assert.equal(r.body.ignored, 'amount_mismatch');
  assert.equal(db.charges.get('pay-1')!.status, 'pending');
});

test('webhook: an unknown transaction is acknowledged and ignored', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'settlement', known: false });
  const r = await handleNotification(await notification('settlement'), deps(db, mt.fetchFn));
  assert.equal(r.status, 200);
  assert.equal(r.body.ignored, 'unknown_transaction');
});

test('cancel: cancelled at Midtrans when nobody paid', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'pending' });
  await createQris(input, deps(db, mt.fetchFn));
  const r = await cancelQris('pay-1', deps(db, mt.fetchFn));
  assert.equal(r.body.status, 'cancelled');
  assert.ok(mt.calls.some((c) => c.url.endsWith('/v2/pay-1/cancel') && c.method === 'POST'));
});

test('cancel: the customer paid a second before, so it is paid', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'settlement' });
  await createQris(input, deps(db, mt.fetchFn));
  const r = await cancelQris('pay-1', deps(db, mt.fetchFn));
  assert.equal(r.body.status, 'paid');
});

test('cancel: a charge of another store is not found', async () => {
  const db = new FakeDb();
  const mt = midtrans({ status: 'pending' });
  const r = await cancelQris('pay-unknown', deps(db, mt.fetchFn));
  assert.equal(r.status, 404);
  assert.equal(mt.calls.length, 0);
});
