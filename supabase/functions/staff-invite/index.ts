// POST {employee_id, email, full_name?} from a signed-in owner or manager →
// an invitation email to the back office, the login linked to the employee.
import { inviteStaff, type InviteInput } from '../_shared/staff.ts';
import { preflight, reply, staffDeps } from '../_shared/deno.ts';

Deno.serve(async (req) => {
  const early = preflight(req);
  if (early) return early;
  const input = (await req.json()) as InviteInput;
  return reply(await inviteStaff(input, staffDeps(req)));
});
