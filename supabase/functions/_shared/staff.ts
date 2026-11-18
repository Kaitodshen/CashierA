// Staff invitations. The logic lives here (tested under Node); deno.ts wires
// the Supabase clients. The caller's own token checks who may invite whom
// (prepare_staff_invite); the service role creates the login and links it.

import type { Reply } from './handlers.ts';

export type InviteInput = { employee_id: string; email: string; full_name?: string };

export interface StaffDb {
  /** As the caller: may they invite this employee with this email? */
  prepareAsCaller(id: string, email: string): Promise<{ resend: boolean }>;
  /** Service role: create the login and send the invitation email. */
  invite(email: string, redirectTo: string, fullName?: string): Promise<{ userId: string }>;
  /** Service role: attach the login to the employee. */
  link(id: string, userId: string, email: string): Promise<void>;
}

export type StaffDeps = { db: StaffDb; siteUrl: string };

const fail = (status: number, error: string): Reply => ({ status, body: { error } });

export async function inviteStaff(input: InviteInput, deps: StaffDeps): Promise<Reply> {
  const id = input?.employee_id?.trim();
  const email = input?.email?.trim().toLowerCase();
  if (!id || !email) return fail(400, 'invalid_input');

  let resend: boolean;
  try {
    ({ resend } = await deps.db.prepareAsCaller(id, email));
  } catch (e) {
    const code = (e as { code?: string }).code ?? 'unknown';
    return fail(code === 'permission_denied' ? 403 : 409, code);
  }

  const redirectTo = `${deps.siteUrl.replace(/\/+$/, '')}/#/admin/set-password`;
  let userId: string;
  try {
    ({ userId } = await deps.db.invite(email, redirectTo, input.full_name));
  } catch (e) {
    const message = (e as Error).message ?? '';
    if (/already (been )?registered/i.test(message)) return fail(409, 'email_taken');
    return fail(502, 'invite_failed');
  }

  if (!resend) await deps.db.link(id, userId, email);
  return { status: 200, body: { ok: true } };
}
