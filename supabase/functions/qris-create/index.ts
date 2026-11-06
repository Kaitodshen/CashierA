// POST {id, store_id, payment_method_id, order_id, order_number, amount}
// from a paired terminal → the charge with its QR string.
import { createQris, type OpenInput } from '../_shared/handlers.ts';
import { gatewayDeps, preflight, reply } from '../_shared/deno.ts';

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  const input = (await req.json()) as OpenInput;
  return reply(await createQris(input, gatewayDeps(req)));
});
