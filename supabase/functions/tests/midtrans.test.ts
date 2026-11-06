import { strict as assert } from 'node:assert';
import { createHash } from 'node:crypto';
import { test } from 'node:test';

import {
  chargeRequest,
  grossToRupiah,
  mapStatus,
  parseCharge,
  parseMidtransTime,
  signatureKey,
  verifyNotification,
} from '../_shared/midtrans.ts';

const key = 'SB-Mid-server-TEST';

test('the signature is sha512(order_id + status_code + gross_amount + key)', async () => {
  const expected = createHash('sha512').update('ord-1' + '200' + '10000.00' + key).digest('hex');
  assert.equal(await signatureKey('ord-1', '200', '10000.00', key), expected);
});

test('a notification verifies only with the right key and fields', async () => {
  const n = {
    order_id: 'ord-1',
    status_code: '200',
    gross_amount: '10000.00',
    transaction_status: 'settlement',
    signature_key: await signatureKey('ord-1', '200', '10000.00', key),
  };
  assert.equal(await verifyNotification(n, key), true);
  assert.equal(await verifyNotification({ ...n, signature_key: n.signature_key.toUpperCase() }, key), true);
  assert.equal(await verifyNotification({ ...n, gross_amount: '1.00' }, key), false, 'amount changed');
  assert.equal(await verifyNotification(n, 'other-key'), false, 'other key');
  assert.equal(await verifyNotification({ ...n, signature_key: '' }, key), false);
  assert.equal(await verifyNotification(n, ''), false, 'no key configured');
});

test('statuses map onto the charge states', () => {
  assert.equal(mapStatus('settlement'), 'paid');
  assert.equal(mapStatus('capture', 'accept'), 'paid');
  assert.equal(mapStatus('capture', 'challenge'), 'pending');
  assert.equal(mapStatus('pending'), 'pending');
  assert.equal(mapStatus('expire'), 'expired');
  assert.equal(mapStatus('cancel'), 'cancelled');
  assert.equal(mapStatus('deny'), 'failed');
  assert.equal(mapStatus('failure'), 'failed');
});

test('rupiah amounts are whole', () => {
  assert.equal(grossToRupiah('10000.00'), 10000);
  assert.equal(grossToRupiah(2500), 2500);
  assert.throws(() => grossToRupiah('10000.50'));
  assert.throws(() => grossToRupiah('abc'));
});

test('the charge request uses the charge id as order_id', () => {
  const body = chargeRequest({ chargeId: 'pay-1', amount: 25500, orderNumber: 'PST-T1-261107-0001' });
  assert.deepEqual(body.transaction_details, { order_id: 'pay-1', gross_amount: 25500 });
  assert.equal(body.payment_type, 'qris');
  assert.deepEqual(body.custom_expiry, { expiry_duration: 15, unit: 'minute' });
  assert.throws(() => chargeRequest({ chargeId: 'x', amount: 0 }));
  assert.throws(() => chargeRequest({ chargeId: 'x', amount: 10.5 }));
});

test('a charge response gives the QR, the reference and the expiry in WIB', () => {
  const c = parseCharge({
    status_code: '201',
    transaction_id: 'trx-1',
    transaction_status: 'pending',
    qr_string: '00020101021226...',
    expiry_time: '2026-11-07 12:15:00',
  });
  assert.deepEqual(c, {
    transactionId: 'trx-1',
    qrString: '00020101021226...',
    expiresAt: '2026-11-07T12:15:00+07:00',
    status: 'pending',
  });
  assert.throws(() => parseCharge({ status_code: '406', status_message: 'duplicate order id' }), /duplicate/);
  assert.throws(() => parseCharge({ status_code: '201' }), /QR/);
  assert.equal(parseMidtransTime(undefined), null);
});
