// POST {id} from a paired terminal → the charge as Midtrans settled it
// (cancelled, or paid when the customer paid just before).
import { cancelQris } from '../_shared/handlers.ts';
import { gatewayDeps, preflight, reply } from '../_shared/deno.ts';

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  const { id } = (await req.json()) as { id: string };
  return reply(await cancelQris(id, gatewayDeps(req)));
});
