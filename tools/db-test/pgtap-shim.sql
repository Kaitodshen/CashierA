-- -----------------------------------------------------------------------------
-- A small subset of pgTAP, enough to run supabase/tests/database/*.test.sql on
-- PGlite. Signatures and TAP output match pgTAP, so the same files run
-- unchanged under `supabase test db` (which uses the real extension).
-- State lives in transaction-local settings, so any role can call these.
-- -----------------------------------------------------------------------------

create or replace function extensions._tap_counter(p_name text)
returns integer language sql as $$
  select coalesce(nullif(current_setting('tap.' || p_name, true), ''), '0')::integer
$$;

create or replace function extensions._tap_emit(p_ok boolean, p_description text)
returns text language plpgsql as $$
declare
  v_n integer := extensions._tap_counter('run') + 1;
begin
  perform set_config('tap.run', v_n::text, true);
  if not coalesce(p_ok, false) then
    perform set_config('tap.failed', (extensions._tap_counter('failed') + 1)::text, true);
  end if;
  return case when coalesce(p_ok, false) then 'ok ' else 'not ok ' end
         || v_n || coalesce(' - ' || p_description, '');
end
$$;

create or replace function extensions.plan(integer)
returns text language plpgsql as $$
begin
  perform set_config('tap.planned', $1::text, true);
  perform set_config('tap.run', '0', true);
  perform set_config('tap.failed', '0', true);
  return '1..' || $1;
end
$$;

create or replace function extensions.diag(text)
returns text language sql as $$ select '# ' || replace($1, E'\n', E'\n# ') $$;

create or replace function extensions.ok(boolean, text default null)
returns text language sql as $$ select extensions._tap_emit($1, $2) $$;

create or replace function extensions.pass(text default null)
returns text language sql as $$ select extensions._tap_emit(true, $1) $$;

create or replace function extensions.fail(text default null)
returns text language sql as $$ select extensions._tap_emit(false, $1) $$;

create or replace function extensions.is(anyelement, anyelement, text default null)
returns text language plpgsql as $$
declare
  v_ok boolean := $1 is not distinct from $2;
  v_out text := extensions._tap_emit(v_ok, $3);
begin
  if not v_ok then
    v_out := v_out || E'\n' || extensions.diag(
      '        have: ' || coalesce($1::text, 'NULL') || E'\n        want: ' || coalesce($2::text, 'NULL'));
  end if;
  return v_out;
end
$$;

create or replace function extensions.isnt(anyelement, anyelement, text default null)
returns text language plpgsql as $$
declare
  v_ok boolean := $1 is distinct from $2;
  v_out text := extensions._tap_emit(v_ok, $3);
begin
  if not v_ok then
    v_out := v_out || E'\n' || extensions.diag('        have: ' || coalesce($1::text, 'NULL') || E'\n        want: anything else');
  end if;
  return v_out;
end
$$;

-- throws_ok(sql, errcode, errmsg, description): NULL errcode/errmsg are not checked.
create or replace function extensions.throws_ok(text, char(5), text, text)
returns text language plpgsql as $$
begin
  execute $1;
  return extensions._tap_emit(false, $4) || E'\n' || extensions.diag('      caught: no exception');
exception when others then
  if ($2 is null or sqlstate = $2) and ($3 is null or sqlerrm = $3) then
    return extensions._tap_emit(true, $4);
  end if;
  return extensions._tap_emit(false, $4) || E'\n' || extensions.diag(
    '      caught: ' || sqlstate || ': ' || sqlerrm || E'\n      wanted: ' || coalesce($2, '') || ': ' || coalesce($3, '(any)'));
end
$$;

-- throws_ok(sql, errcode_or_message, description)
create or replace function extensions.throws_ok(text, text, text)
returns text language plpgsql as $$
begin
  if $2 ~ '^[0-9A-Z]{5}$' then
    return extensions.throws_ok($1, $2::char(5), null::text, $3);
  end if;
  return extensions.throws_ok($1, null::char(5), $2, $3);
end
$$;

-- throws_like(sql, like_pattern, description): the error message matches the pattern.
create or replace function extensions.throws_like(text, text, text default null)
returns text language plpgsql as $$
begin
  execute $1;
  return extensions._tap_emit(false, $3) || E'\n' || extensions.diag('      caught: no exception');
exception when others then
  if sqlerrm like $2 then
    return extensions._tap_emit(true, $3);
  end if;
  return extensions._tap_emit(false, $3) || E'\n' || extensions.diag(
    '      error message: ' || sqlerrm || E'\n   doesn''t match: ' || $2);
end
$$;

create or replace function extensions.lives_ok(text, text default null)
returns text language plpgsql as $$
begin
  execute $1;
  return extensions._tap_emit(true, $2);
exception when others then
  return extensions._tap_emit(false, $2) || E'\n' || extensions.diag('    died: ' || sqlstate || ': ' || sqlerrm);
end
$$;

create or replace function extensions.finish()
returns setof text language plpgsql as $$
declare
  v_planned integer := extensions._tap_counter('planned');
  v_run integer := extensions._tap_counter('run');
  v_failed integer := extensions._tap_counter('failed');
begin
  if v_planned <> v_run then
    return next '# Looks like you planned ' || v_planned || ' tests but ran ' || v_run;
  end if;
  if v_failed > 0 then
    return next '# Looks like you failed ' || v_failed || ' test' || case when v_failed > 1 then 's' else '' end
                || ' of ' || v_run;
  end if;
  return;
end
$$;

grant execute on all functions in schema extensions to anon, authenticated, service_role;
