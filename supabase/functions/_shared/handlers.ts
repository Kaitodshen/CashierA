// The three gateway endpoints as plain functions. The database and HTTP are
// injected, so tests run them with fakes; index.ts files wire the real ones.

import {
  authHeader,
  baseUrl,
  chargeRequest,
  GatewayError,
  grossToRupiah,
  mapStatus,
  type ChargeStatus,
  type MidtransNotification,
  parseCharge,
  verifyNotification,
} from './midtrans.ts';

export type Charge = {
  id: string;
  status: ChargeStatus;
  amount: number;
  provider_ref?: string | null;
  qr_string?: string | null;
  expires_at?: string | null;
  order_number?: string | null;
};

export type OpenInput = {
  id: string;
  store_id: string;
  payment_method_id: string;
  order_id: string;
  order_number?: string | null;
  amount: number;
};

export interface GatewayDb {
  /** gateway_charge_open as the calling terminal (checks its store). */
  open(input: OpenInput): Promise<Charge>;
  /** gateway_charge_status as the caller (checks the store). */
  statusAsCaller(id: string): Promise<Charge>;
  /** gateway_charge_attach with the service role. */
  attach(id: string, ref: string, qr: string, expiresAt: string | null, raw: unknown): Promise<Charge>;
  /** gateway_charge_settle with the service role. */
  settle(
    id: string,
    status: ChargeStatus,
    grossAmount: number | null,
    transactionId: string | null,
    raw: unknown,
  ): Promise<Charge & { changed?: boolean }>;
}

export type Deps = {
  db: GatewayDb;
  fetch: typeof fetch;
  serverKey: string;
  isProduction: boolean;
  expiryMinutes?: number;
};

export type Reply = { status: number; body: Record<string, unknown> };

function api(deps: Deps, path: string, init: RequestInit = {}): Promise<Response> {
  if (!deps.serverKey) throw new GatewayError('gateway_not_configured', 'MIDTRANS_SERVER_KEY is not set');
  return deps.fetch(baseUrl(deps.isProduction) + path, {
    ...init,
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: authHeader(deps.serverKey),
    },
  });
}

async function midtransStatus(
  deps: Deps,
  id: string,
): Promise<{ status: ChargeStatus; gross: number | null; transactionId: string | null; raw: Record<string, unknown> } | null> {
  const res = await api(deps, `/v2/${encodeURIComponent(id)}/status`);
  const json = (await res.json()) as Record<string, unknown>;
  if (String(json.status_code) === '404') return null;
  return {
    status: mapStatus(String(json.transaction_status ?? 'pending'), json.fraud_status as string | undefined),
    gross: json.gross_amount == null ? null : grossToRupiah(json.gross_amount as string),
    transactionId: (json.transaction_id as string | undefined) ?? null,
    raw: json,
  };
}

function view(c: Charge): Record<string, unknown> {
  return {
    id: c.id,
    status: c.status,
    amount: c.amount,
    provider_ref: c.provider_ref ?? null,
    qr_string: c.qr_string ?? null,
    expires_at: c.expires_at ?? null,
  };
}

function failure(e: unknown): Reply {
  const code = e instanceof GatewayError ? e.code : (e as { code?: string })?.code ?? 'gateway_error';
  const message = e instanceof Error ? e.message : String(e);
  const status = code === 'permission_denied' || code === 'store_mismatch' ? 403
    : code === 'charge_not_found' ? 404
    : code === 'invalid_input' || code === 'invalid_amount' || code === 'payment_method_invalid' ? 400
    : 502;
  return { status, body: { error: code, message } };
}

/** qris-create: open (or reuse) the charge, ask Midtrans for a QR. */
export async function createQris(input: OpenInput, deps: Deps): Promise<Reply> {
  try {
    const charge = await deps.db.open(input);
    if (charge.status !== 'pending' || charge.qr_string) return { status: 200, body: view(charge) };
    const res = await api(deps, '/v2/charge', {
      method: 'POST',
      body: JSON.stringify(
        chargeRequest({
          chargeId: charge.id,
          amount: charge.amount,
          orderNumber: input.order_number,
          expiryMinutes: deps.expiryMinutes,
        }),
      ),
    });
    const json = (await res.json()) as Record<string, unknown>;
    const parsed = parseCharge(json);
    const attached = await deps.db.attach(charge.id, parsed.transactionId, parsed.qrString, parsed.expiresAt, json);
    return { status: 200, body: view({ ...charge, ...attached }) };
  } catch (e) {
    return failure(e);
  }
}

/** qris-cancel: cancel at Midtrans, then book what Midtrans says happened
 * (a customer who paid a second ago makes it "paid", not "cancelled"). */
export async function cancelQris(id: string, deps: Deps): Promise<Reply> {
  try {
    const charge = await deps.db.statusAsCaller(id);
    if (charge.status !== 'pending') return { status: 200, body: view(charge) };
    if (charge.provider_ref) {
      await api(deps, `/v2/${encodeURIComponent(id)}/cancel`, { method: 'POST' });
    }
    const truth = charge.provider_ref ? await midtransStatus(deps, id) : null;
    const status: ChargeStatus = truth == null || truth.status === 'pending' ? 'cancelled' : truth.status;
    const settled = await deps.db.settle(id, status, truth?.gross ?? null, truth?.transactionId ?? null, truth?.raw ?? {});
    return { status: 200, body: view({ ...charge, ...settled }) };
  } catch (e) {
    return failure(e);
  }
}

/** midtrans-webhook: check the signature, re-read the status from Midtrans,
 * settle. Unknown charges and amount mismatches answer 200 so Midtrans stops
 * retrying; both are logged by the database. */
export async function handleNotification(body: Partial<MidtransNotification>, deps: Deps): Promise<Reply> {
  if (!(await verifyNotification(body, deps.serverKey))) {
    return { status: 401, body: { error: 'invalid_signature' } };
  }
  try {
    const truth = await midtransStatus(deps, body.order_id!);
    if (truth == null) return { status: 200, body: { ignored: 'unknown_transaction' } };
    const settled = await deps.db.settle(body.order_id!, truth.status, truth.gross, truth.transactionId, truth.raw);
    return { status: 200, body: { id: settled.id, status: settled.status, changed: settled.changed ?? false } };
  } catch (e) {
    const code = (e as { code?: string })?.code;
    if (code === 'charge_not_found' || code === 'amount_mismatch') {
      return { status: 200, body: { ignored: code } };
    }
    return failure(e);
  }
}
