-- =============================================================================
-- Test helpers, installed once (this file commits; the others roll back).
-- Runs first because pg_prove and tools/db-test run files in name order.
--   tests.id('store.pst'), tests.variant('MNM-AIR-600'), tests.customer(1)
--   tests.act_as(auth_uid) / tests.act_as_postgres()
--   tests.order_payload(...)  -> a complete order.upsert payload whose money
--                                 math follows docs/phase-0-architecture.md §4.5
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select plan(1);

create schema if not exists tests;
grant usage on schema tests to authenticated, anon;

create or replace function tests.id(p_name text)
returns uuid
language sql
immutable
as $$
  select (case p_name
    when 'store.pst'          then 'a0000000-0000-4000-8000-000000000001'
    when 'store.bks'          then 'a0000000-0000-4000-8000-000000000002'
    when 'store.tgr'          then 'a0000000-0000-4000-8000-000000000003'
    when 'user.owner'         then 'b0000000-0000-4000-8000-000000000001'
    when 'user.manager_pst'   then 'b0000000-0000-4000-8000-000000000011'
    when 'user.manager_bks'   then 'b0000000-0000-4000-8000-000000000012'
    when 'user.cashier_pst'   then 'b0000000-0000-4000-8000-000000000021'
    when 'user.device_pst'    then 'b1000000-0000-4000-8000-000000000001'
    when 'user.device_bks'    then 'b1000000-0000-4000-8000-000000000002'
    when 'user.device_tgr'    then 'b1000000-0000-4000-8000-000000000003'
    when 'emp.owner'          then 'e0000000-0000-4000-8000-000000000001'
    when 'emp.budi'           then 'e0000000-0000-4000-8000-000000000011'
    when 'emp.citra'          then 'e0000000-0000-4000-8000-000000000012'
    when 'emp.dewi'           then 'e0000000-0000-4000-8000-000000000013'
    when 'emp.eko'            then 'e0000000-0000-4000-8000-000000000021'
    when 'emp.fitri'          then 'e0000000-0000-4000-8000-000000000022'
    when 'emp.gilang'         then 'e0000000-0000-4000-8000-000000000023'
    when 'emp.hana'           then 'e0000000-0000-4000-8000-000000000024'
    when 'emp.indra'          then 'e0000000-0000-4000-8000-000000000025'
    when 'emp.joko'           then 'e0000000-0000-4000-8000-000000000026'
    when 'emp.kurniawan'      then 'e0000000-0000-4000-8000-000000000031'
    when 'device.pst'         then 'd0000000-0000-4000-8000-000000000001'
    when 'device.bks'         then 'd0000000-0000-4000-8000-000000000002'
    when 'device.tgr'         then 'd0000000-0000-4000-8000-000000000003'
  end)::uuid
$$;

create or replace function tests.variant(p_sku text)
returns uuid language sql immutable as $$ select md5('cashiera:variant:' || p_sku)::uuid $$;

create or replace function tests.product(p_key text)
returns uuid language sql immutable as $$ select md5('cashiera:product:' || p_key)::uuid $$;

create or replace function tests.customer(p_n integer)
returns uuid language sql immutable as $$ select md5('cashiera:customer:' || p_n)::uuid $$;

-- Deterministic ids for rows a test creates.
create or replace function tests.uuid(p_seed text)
returns uuid language sql immutable as $$ select md5('cashiera:test:' || p_seed)::uuid $$;

-- Become a signed-in user (role authenticated + JWT sub), like PostgREST does.
create or replace function tests.act_as(p_auth_user uuid)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', p_auth_user, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_auth_user::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

create or replace function tests.act_as_postgres()
returns void
language plpgsql
as $$
begin
  perform set_config('role', 'none', true);
  perform set_config('request.jwt.claims', '', true);
  perform set_config('request.jwt.claim.sub', '', true);
end;
$$;

-- Builds an order.upsert payload.
-- p_lines:   [{"sku":"MNM-AIR-600","qty":"2","item_discount":0,"approved_by":null,
--              "modifiers":[{"modifier_id":..,"group_name":..,"modifier_name":..,"price_delta":5000}]}]
-- p_options: {"customer_id":..., "points_redeemed":50, "earn_points":true,
--             "bill_discount":{"amount":8500,"approved_by":...},
--             "voucher":{"code":"HEMAT10","amount":2000},
--             "payments":[{"method":"cash","tendered":100000} | {"method":"kasbon"} |
--                         {"method":"qris"} | {"method":"debit","amount":28000,"reference":"APR1"}],
--             "ordered_at":..., "kasbon_due_date":...}
create or replace function tests.order_payload(
  p_order_id uuid,
  p_store_id uuid,
  p_shift_id uuid,
  p_cashier_id uuid,
  p_order_number text,
  p_lines jsonb,
  p_status text default 'completed',
  p_version integer default 1,
  p_options jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_settings public.store_settings%rowtype;
  v_point_value bigint;
  v_earn_amount bigint;
  n integer := jsonb_array_length(p_lines);
  v_line jsonb;
  v_rec record;
  v_ids uuid[] := '{}';
  v_variant uuid[] := '{}';
  v_product uuid[] := '{}';
  v_pname text[] := '{}';
  v_vname text[] := '{}';
  v_sku text[] := '{}';
  v_qty numeric[] := '{}';
  v_price bigint[] := '{}';
  v_mod bigint[] := '{}';
  v_gross bigint[] := '{}';
  v_idisc bigint[] := '{}';
  v_alloc bigint[] := '{}';
  v_net bigint[] := '{}';
  v_tax bigint[] := '{}';
  v_taxable boolean[] := '{}';
  v_cost bigint[] := '{}';
  v_rem numeric[] := '{}';
  v_mods jsonb[] := '{}';
  v_mod_total bigint;
  i integer;
  k integer;
  v_base_total bigint := 0;
  v_bill bigint := coalesce((p_options #>> '{bill_discount,amount}')::bigint, 0);
  v_voucher bigint := coalesce((p_options #>> '{voucher,amount}')::bigint, 0);
  v_points integer := coalesce((p_options ->> 'points_redeemed')::integer, 0);
  v_points_disc bigint;
  v_to_alloc bigint;
  v_left bigint;
  v_gross_total bigint := 0;
  v_item_disc_total bigint := 0;
  v_net_total bigint := 0;
  v_taxable_net bigint := 0;
  v_sc_bps integer;
  v_service bigint;
  v_rate integer;
  v_tax_total bigint;
  v_grand bigint;
  v_remaining bigint;
  v_pay jsonb;
  v_payments jsonb := '[]'::jsonb;
  v_discounts jsonb := '[]'::jsonb;
  v_items jsonb := '[]'::jsonb;
  v_paid bigint := 0;
  v_change bigint := 0;
  v_amount bigint;
  v_tendered bigint;
  v_method text;
  v_pm public.payment_methods%rowtype;
  v_customer uuid := (p_options ->> 'customer_id')::uuid;
  v_points_earned integer := 0;
  v_ordered_at timestamptz := coalesce((p_options ->> 'ordered_at')::timestamptz, now());
begin
  select * into v_settings from public.store_settings where store_id = p_store_id;
  select loyalty_point_value, loyalty_earn_amount into v_point_value, v_earn_amount
  from public.business_profile where id = 1;
  v_points_disc := v_points * v_point_value;

  -- Lines: price lookup (store override first), gross, item discounts.
  for i in 1..n loop
    v_line := p_lines -> (i - 1);
    select pv.id, pv.product_id, p.name as pname, pv.name as vname, pv.sku,
           coalesce(svs.price_override, pv.price) as price, pv.cost, p.is_taxable
      into v_rec
      from public.product_variants pv
      join public.products p on p.id = pv.product_id
      left join public.store_variant_settings svs on svs.variant_id = pv.id and svs.store_id = p_store_id
     where pv.sku = v_line ->> 'sku';
    if v_rec.id is null then
      raise exception 'tests.order_payload: unknown sku %', v_line ->> 'sku';
    end if;

    select coalesce(sum((m.value ->> 'price_delta')::bigint), 0) into v_mod_total
    from jsonb_array_elements(coalesce(v_line -> 'modifiers', '[]'::jsonb)) m;

    v_ids := v_ids || md5(p_order_id::text || ':item:' || i)::uuid;
    v_variant := v_variant || v_rec.id;
    v_product := v_product || v_rec.product_id;
    v_pname := v_pname || v_rec.pname;
    v_vname := v_vname || v_rec.vname;
    v_sku := v_sku || v_rec.sku;
    v_qty := v_qty || (v_line ->> 'qty')::numeric;
    v_price := v_price || v_rec.price;
    v_mod := v_mod || v_mod_total;
    v_gross := v_gross || round((v_rec.price + v_mod_total) * (v_line ->> 'qty')::numeric)::bigint;
    v_idisc := v_idisc || coalesce((v_line ->> 'item_discount')::bigint, 0);
    v_taxable := v_taxable || v_rec.is_taxable;
    v_cost := v_cost || v_rec.cost;
    v_mods := v_mods || coalesce(v_line -> 'modifiers', '[]'::jsonb);
    v_base_total := v_base_total + v_gross[i] - v_idisc[i];
  end loop;

  -- Bill discounts and points, allocated by largest remainder.
  v_to_alloc := v_bill + v_voucher + v_points_disc;
  v_left := v_to_alloc;
  for i in 1..n loop
    if v_base_total > 0 then
      v_alloc := v_alloc || floor(v_to_alloc::numeric * (v_gross[i] - v_idisc[i]) / v_base_total)::bigint;
      v_rem := v_rem || ((v_to_alloc::numeric * (v_gross[i] - v_idisc[i])) % v_base_total);
    else
      v_alloc := v_alloc || 0::bigint;
      v_rem := v_rem || 0::numeric;
    end if;
    v_left := v_left - v_alloc[i];
  end loop;
  while v_left > 0 loop
    select x.idx into k
    from unnest(v_rem) with ordinality as x(r, idx)
    order by x.r desc, x.idx
    limit 1;
    v_alloc[k] := v_alloc[k] + 1;
    v_rem[k] := -1;
    v_left := v_left - 1;
  end loop;

  for i in 1..n loop
    v_net := v_net || (v_gross[i] - v_idisc[i] - v_alloc[i]);
    v_gross_total := v_gross_total + v_gross[i];
    v_item_disc_total := v_item_disc_total + v_idisc[i];
    v_net_total := v_net_total + v_net[i];
    if v_taxable[i] then
      v_taxable_net := v_taxable_net + v_net[i];
    end if;
  end loop;

  -- Service charge and tax, once per bill.
  v_sc_bps := case when v_settings.service_charge_enabled then v_settings.service_charge_bps else 0 end;
  v_service := round(v_net_total::numeric * v_sc_bps / 10000);
  v_rate := case when v_settings.tax_enabled then v_settings.tax_rate_bps else 0 end;
  v_tax_total := case
    when v_rate = 0 then 0
    when v_settings.tax_inclusive
      then round((v_taxable_net + case when v_settings.service_charge_taxable then v_service else 0 end)::numeric
                 * v_rate / (10000 + v_rate))
    else round((v_taxable_net + case when v_settings.service_charge_taxable then v_service else 0 end)::numeric
               * v_rate / 10000)
  end;

  -- Tax spread over taxable lines by largest remainder.
  v_rem := '{}';
  v_left := v_tax_total;
  for i in 1..n loop
    if v_taxable[i] and v_taxable_net > 0 then
      v_tax := v_tax || floor(v_tax_total::numeric * v_net[i] / v_taxable_net)::bigint;
      v_rem := v_rem || ((v_tax_total::numeric * v_net[i]) % v_taxable_net);
    else
      v_tax := v_tax || 0::bigint;
      v_rem := v_rem || (-1)::numeric;
    end if;
    v_left := v_left - v_tax[i];
  end loop;
  while v_left > 0 loop
    select x.idx into k
    from unnest(v_rem) with ordinality as x(r, idx)
    order by x.r desc, x.idx
    limit 1;
    v_tax[k] := v_tax[k] + 1;
    v_rem[k] := -1;
    v_left := v_left - 1;
  end loop;

  v_grand := v_net_total + v_service + case when v_settings.tax_inclusive then 0 else v_tax_total end;

  -- Payments (default: exact cash for a completed order, none otherwise).
  v_remaining := v_grand;
  k := 0;
  for v_pay in
    select value from jsonb_array_elements(
      coalesce(p_options -> 'payments',
               case when p_status = 'completed' then jsonb_build_array(jsonb_build_object('method', 'cash'))
                    else '[]'::jsonb end))
  loop
    exit when v_remaining <= 0 and v_grand > 0;
    if v_grand = 0 then
      exit;
    end if;
    k := k + 1;
    v_method := v_pay ->> 'method';
    select * into v_pm from public.payment_methods
    where code = case v_method when 'debit' then 'debit_card' when 'credit' then 'credit_card' else v_method end;
    v_amount := coalesce((v_pay ->> 'amount')::bigint, v_remaining);
    if v_pm.method_type = 'cash' then
      v_tendered := coalesce((v_pay ->> 'tendered')::bigint, v_amount);
      v_change := v_change + (v_tendered - v_amount);
    else
      v_tendered := null;
    end if;
    if v_pm.method_type <> 'kasbon' then
      v_paid := v_paid + v_amount;
    end if;
    v_remaining := v_remaining - v_amount;
    v_payments := v_payments || jsonb_build_object(
      'id', md5(p_order_id::text || ':pay:' || k)::uuid,
      'payment_method_id', v_pm.id,
      'method_type', v_pm.method_type,
      'amount', v_amount,
      'tendered_amount', v_tendered,
      'change_amount', case when v_pm.method_type = 'cash' then v_tendered - v_amount else 0 end,
      'reference', v_pay ->> 'reference',
      'status', 'paid',
      'paid_at', v_ordered_at);
  end loop;

  if v_customer is not null and coalesce((p_options ->> 'earn_points')::boolean, true) then
    v_points_earned := floor(v_net_total::numeric / v_earn_amount)::integer;
  end if;

  -- Discount rows.
  k := 0;
  for i in 1..n loop
    if v_idisc[i] > 0 then
      k := k + 1;
      v_discounts := v_discounts || jsonb_build_object(
        'id', md5(p_order_id::text || ':disc:' || k)::uuid,
        'order_item_id', v_ids[i], 'source', 'manual', 'description', 'Diskon item',
        'amount', v_idisc[i], 'approved_by', (p_lines -> (i - 1)) ->> 'approved_by');
    end if;
  end loop;
  if v_bill > 0 then
    k := k + 1;
    v_discounts := v_discounts || jsonb_build_object(
      'id', md5(p_order_id::text || ':disc:' || k)::uuid, 'source', 'manual', 'description', 'Diskon nota',
      'amount', v_bill, 'approved_by', p_options #>> '{bill_discount,approved_by}');
  end if;
  if v_voucher > 0 then
    k := k + 1;
    v_discounts := v_discounts || jsonb_build_object(
      'id', md5(p_order_id::text || ':disc:' || k)::uuid, 'source', 'voucher',
      'voucher_id', (select vo.id from public.vouchers vo where upper(vo.code) = upper(p_options #>> '{voucher,code}')),
      'description', 'Voucher ' || (p_options #>> '{voucher,code}'), 'amount', v_voucher);
  end if;
  if v_points_disc > 0 then
    k := k + 1;
    v_discounts := v_discounts || jsonb_build_object(
      'id', md5(p_order_id::text || ':disc:' || k)::uuid, 'source', 'points',
      'description', 'Tukar ' || v_points || ' poin', 'amount', v_points_disc);
  end if;

  for i in 1..n loop
    v_items := v_items || jsonb_build_object(
      'id', v_ids[i], 'product_id', v_product[i], 'variant_id', v_variant[i],
      'product_name', v_pname[i], 'variant_name', v_vname[i], 'sku', v_sku[i],
      'quantity', v_qty[i]::text, 'unit_price', v_price[i], 'modifiers_unit_total', v_mod[i],
      'gross_amount', v_gross[i], 'item_discount_amount', v_idisc[i], 'bill_discount_amount', v_alloc[i],
      'net_amount', v_net[i], 'tax_amount', v_tax[i], 'is_taxable', v_taxable[i],
      'unit_cost', v_cost[i], 'cost_amount', round(v_cost[i] * v_qty[i])::bigint, 'sort_order', i,
      'modifiers', (
        select coalesce(jsonb_agg(m.value || jsonb_build_object(
                 'id', md5(p_order_id::text || ':mod:' || i || ':' || m.ord)::uuid) order by m.ord), '[]'::jsonb)
        from jsonb_array_elements(v_mods[i]) with ordinality as m(value, ord)));
  end loop;

  return jsonb_build_object(
    'id', p_order_id, 'store_id', p_store_id, 'shift_id', p_shift_id, 'cashier_id', p_cashier_id,
    'order_number', p_order_number, 'order_type', coalesce(p_options ->> 'order_type', 'takeaway'),
    'status', p_status, 'version', p_version, 'customer_id', v_customer,
    'gross_total', v_gross_total, 'item_discount_total', v_item_disc_total,
    'bill_discount_total', v_bill + v_voucher, 'points_redeemed', v_points, 'points_discount', v_points_disc,
    'net_total', v_net_total, 'service_charge_total', v_service, 'tax_total', v_tax_total,
    'tax_inclusive', v_settings.tax_inclusive, 'tax_rate_bps', v_rate, 'service_charge_bps', v_sc_bps,
    'service_charge_taxable', v_settings.service_charge_taxable, 'rounding_amount', 0,
    'grand_total', v_grand, 'paid_total', v_paid, 'change_total', v_change,
    'points_earned', v_points_earned, 'kasbon_due_date', p_options ->> 'kasbon_due_date',
    'ordered_at', v_ordered_at,
    'completed_at', case when p_status = 'completed' then v_ordered_at end,
    'items', v_items, 'discounts', v_discounts, 'payments', v_payments);
end;
$$;

-- Shortcut: open a shift on a terminal and return its id.
create or replace function tests.open_shift(p_seed text, p_store_id uuid, p_employee_id uuid, p_opening bigint)
returns uuid
language plpgsql
as $$
declare
  v_id uuid := tests.uuid(p_seed);
  v_result jsonb;
begin
  v_result := public.sync_push(tests.uuid(p_seed || ':push'), 'shift', 'open',
    jsonb_build_object('id', v_id, 'store_id', p_store_id, 'opened_by', p_employee_id,
                       'opened_at', now(), 'opening_cash', p_opening));
  if v_result ->> 'status' not in ('applied', 'duplicate') then
    raise exception 'tests.open_shift failed: %', v_result;
  end if;
  return v_id;
end;
$$;

grant execute on all functions in schema tests to authenticated, anon;

select ok(true, 'test helpers installed');
select * from finish();
commit;
