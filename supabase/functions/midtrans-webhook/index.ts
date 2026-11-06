// Midtrans HTTP notification (Payment Notification URL). No Supabase JWT:
// the request is trusted only through its signature_key (config.toml turns
// verify_jwt off for this function alone).
import { handleNotification } from '../_shared/handlers.ts';
import { gatewayDeps, reply } from '../_shared/deno.ts';

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('method not allowed', { status: 405 });
  let body: Record<string, string>;
  try {
    body = await req.json();
  } catch {
    return new Response('bad request', { status: 400 });
  }
  return reply(await handleNotification(body, gatewayDeps(null)));
});
