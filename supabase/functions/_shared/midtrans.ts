// Midtrans Core API (QRIS): request building, response parsing, webhook
// signatures and status mapping. Plain TypeScript with no Deno or Node APIs
// beyond Web Crypto, so the Edge Functions and the Node tests share it.

export type ChargeStatus = 'pending' | 'paid' | 'failed' | 'expired' | 'cancelled';

export type MidtransNotification = {
  order_id: string;
  status_code: string;
  gross_amount: string;
  signature_key: string;
  transaction_status: string;
  transaction_id?: string;
  fraud_status?: string;
};

export type ParsedCharge = {
  transactionId: string;
  qrString: string;
  expiresAt: string | null;
  status: ChargeStatus;
};

export class GatewayError extends Error {
  code: string;
  constructor(code: string, message: string) {
    super(message);
    this.code = code;
  }
}

export function baseUrl(isProduction: boolean): string {
  return isProduction ? 'https://api.midtrans.com' : 'https://api.sandbox.midtrans.com';
}

export function authHeader(serverKey: string): string {
  return 'Basic ' + btoa(serverKey + ':');
}

export async function sha512Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-512', new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** sha512(order_id + status_code + gross_amount + server_key), lowercase hex. */
export function signatureKey(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  serverKey: string,
): Promise<string> {
  return sha512Hex(orderId + statusCode + grossAmount + serverKey);
}

function sameText(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

export async function verifyNotification(
  n: Partial<MidtransNotification>,
  serverKey: string,
): Promise<boolean> {
  if (!serverKey || !n.order_id || !n.status_code || !n.gross_amount || !n.signature_key) return false;
  const expected = await signatureKey(n.order_id, n.status_code, n.gross_amount, serverKey);
  return sameText(expected, n.signature_key.toLowerCase());
}

/** Midtrans transaction_status (and fraud_status for capture) → our status. */
export function mapStatus(transactionStatus: string, fraudStatus?: string): ChargeStatus {
  switch (transactionStatus) {
    case 'settlement':
      return 'paid';
    case 'capture':
      return fraudStatus === 'challenge' ? 'pending' : fraudStatus === 'deny' ? 'failed' : 'paid';
    case 'pending':
    case 'authorize':
      return 'pending';
    case 'expire':
      return 'expired';
    case 'cancel':
      return 'cancelled';
    case 'deny':
    case 'failure':
      return 'failed';
    default:
      return 'pending';
  }
}

/** "10000.00" → 10000; fractions are refused (rupiah are whole). */
export function grossToRupiah(gross: string | number): number {
  const value = typeof gross === 'number' ? gross : Number(gross);
  if (!Number.isFinite(value) || !Number.isInteger(value)) {
    throw new GatewayError('invalid_amount', `not a whole rupiah amount: ${gross}`);
  }
  return value;
}

/** "2026-11-07 12:15:00" (Midtrans, WIB) → ISO 8601 with +07:00. */
export function parseMidtransTime(text: string | undefined | null): string | null {
  if (!text) return null;
  const m = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})/.exec(text);
  return m ? `${m[1]}T${m[2]}+07:00` : null;
}

export type ChargeInput = {
  chargeId: string;
  amount: number;
  orderNumber?: string | null;
  expiryMinutes?: number;
};

/** POST /v2/charge body. The charge id is Midtrans's order_id. */
export function chargeRequest(input: ChargeInput): Record<string, unknown> {
  if (!Number.isInteger(input.amount) || input.amount <= 0) {
    throw new GatewayError('invalid_amount', `amount must be a positive whole number: ${input.amount}`);
  }
  return {
    payment_type: 'qris',
    transaction_details: { order_id: input.chargeId, gross_amount: input.amount },
    qris: { acquirer: 'gopay' },
    custom_expiry: { expiry_duration: input.expiryMinutes ?? 15, unit: 'minute' },
    custom_field1: input.orderNumber ?? undefined,
  };
}

/** The charge response, or a GatewayError with Midtrans's status code. */
export function parseCharge(json: Record<string, unknown>): ParsedCharge {
  const code = String(json.status_code ?? '');
  if (code !== '201' && code !== '200') {
    throw new GatewayError(
      `midtrans_${code || 'error'}`,
      String(json.status_message ?? 'charge refused'),
    );
  }
  const qr = typeof json.qr_string === 'string' ? json.qr_string : '';
  if (!qr) throw new GatewayError('midtrans_no_qr', 'the charge has no QR string');
  return {
    transactionId: String(json.transaction_id ?? ''),
    qrString: qr,
    expiresAt: parseMidtransTime(json.expiry_time as string | undefined),
    status: mapStatus(String(json.transaction_status ?? 'pending'), json.fraud_status as string | undefined),
  };
}
