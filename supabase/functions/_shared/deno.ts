// Deno-only wiring for the gateway functions: Supabase clients, secrets and
// HTTP helpers. The logic lives in handlers.ts (tested under Node).

import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';
import type { Charge, Deps, GatewayDb, Reply } from './handlers.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

export function preflight(req: Request): Response | null {
  return req.method === 'OPTIONS' ? new Response('ok', { headers: corsHeaders }) : null;
}

export function reply(r: Reply): Response {
  return new Response(JSON.stringify(r.body), {
    status: r.status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

type RpcError = { message: string; hint?: string; code?: string };

async function call<T>(client: SupabaseClient, fn: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await client.rpc(fn, args);
  if (error) {
    const e = error as RpcError;
    // app.fail puts the CashierA error code in the hint.
    throw Object.assign(new Error(e.message), { code: e.hint ?? e.code ?? 'rpc_error' });
  }
  return data as T;
}

/** [req]'s caller (a paired terminal) for scoped calls, the service role for
 * the rest. */
export function gatewayDeps(req: Request | null): Deps {
  const url = Deno.env.get('SUPABASE_URL')!;
  const service = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false },
  });
  const caller = req == null ? service : createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    auth: { persistSession: false },
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const db: GatewayDb = {
    open: (input) => call<Charge>(caller, 'gateway_charge_open', { p: input }),
    statusAsCaller: (id) => call<Charge>(caller, 'gateway_charge_status', { p_id: id }),
    attach: (id, ref, qr, expiresAt, raw) =>
      call<Charge>(service, 'gateway_charge_attach', {
        p_id: id,
        p_provider_ref: ref,
        p_qr_string: qr,
        p_expires_at: expiresAt,
        p_raw: raw,
      }),
    settle: (id, status, gross, trx, raw) =>
      call(service, 'gateway_charge_settle', {
        p_id: id,
        p_status: status,
        p_gross_amount: gross,
        p_transaction_id: trx,
        p_raw: raw,
      }),
  };
  return {
    db,
    fetch,
    serverKey: Deno.env.get('MIDTRANS_SERVER_KEY') ?? '',
    isProduction: Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true',
    expiryMinutes: Number(Deno.env.get('QRIS_EXPIRY_MINUTES') ?? '15'),
  };
}
