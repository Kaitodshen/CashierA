-- =============================================================================
-- CashierA · 1500 · Phase 4 (cashier): atomic promotion save, and the tax
-- check for bills whose taxable part is only the service charge.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Order totals: same checks as 1000, with one change to the line-tax rule.
-- ---------------------------------------------------------------------------
create or replace function app.validate_order_totals(p_order_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  o public.orders%rowtype;
  v_items record;
  v_disc record;
  v_pay record;
  v_base bigint;
  v_service bigint;
  v_tax bigint;
begin
  select * into o from public.orders where id = p_order_id;

  select count(*) as n,
         coalesce(sum(gross_amount), 0) as gross,
         coalesce(sum(item_discount_amount), 0) as item_disc,
         coalesce(sum(bill_discount_amount), 0) as bill_disc,
         coalesce(sum(net_amount), 0) as net,
         coalesce(sum(tax_amount), 0) as tax,
         coalesce(sum(net_amount) filter (where is_taxable), 0) as taxable_net
    into v_items
    from public.order_items
   where order_id = p_order_id;

  if v_items.n = 0 then
    perform app.fail('order_empty', o.order_number);
  end if;
  if v_items.gross <> o.gross_total then
    perform app.fail('order_totals_mismatch', format('lines gross %s <> gross_total %s', v_items.gross, o.gross_total));
  end if;
  if v_items.item_disc <> o.item_discount_total then
    perform app.fail('order_totals_mismatch', format('lines item discounts %s <> item_discount_total %s', v_items.item_disc, o.item_discount_total));
  end if;
  if v_items.bill_disc <> o.bill_discount_total + o.points_discount then
    perform app.fail('order_totals_mismatch', format('lines bill discounts %s <> bill_discount_total + points_discount %s',
      v_items.bill_disc, o.bill_discount_total + o.points_discount));
  end if;
  if v_items.net <> o.net_total then
    perform app.fail('order_totals_mismatch', format('lines net %s <> net_total %s', v_items.net, o.net_total));
  end if;
  -- The line tax shares add up to the bill's tax. When no taxable line has
  -- anything left (an exempt basket with a taxable service charge, or taxable
  -- lines discounted to zero), there is nothing to carry it: the header keeps
  -- the tax and the lines carry none.
  if v_items.taxable_net > 0 and v_items.tax <> o.tax_total then
    perform app.fail('order_totals_mismatch', format('lines tax %s <> tax_total %s', v_items.tax, o.tax_total));
  end if;
  if v_items.taxable_net = 0 and v_items.tax <> 0 then
    perform app.fail('order_totals_mismatch', format('lines tax %s with no taxable net', v_items.tax));
  end if;

  select coalesce(sum(amount) filter (where order_item_id is not null), 0) as item_disc,
         coalesce(sum(amount) filter (where order_item_id is null and source <> 'points'), 0) as bill_disc,
         coalesce(sum(amount) filter (where source = 'points'), 0) as points
    into v_disc
    from public.order_discounts
   where order_id = p_order_id;

  if (v_disc.item_disc, v_disc.bill_disc, v_disc.points)
     is distinct from (o.item_discount_total, o.bill_discount_total, o.points_discount) then
    perform app.fail('order_discounts_mismatch', format(
      'discount rows item/bill/points %s/%s/%s <> header %s/%s/%s',
      v_disc.item_disc, v_disc.bill_disc, v_disc.points,
      o.item_discount_total, o.bill_discount_total, o.points_discount));
  end if;

  -- Service charge and tax are computed once per bill (see docs §4.5).
  v_service := round(o.net_total::numeric * o.service_charge_bps / 10000);
  if o.service_charge_total <> v_service then
    perform app.fail('service_charge_mismatch', format('service %s <> expected %s', o.service_charge_total, v_service));
  end if;

  v_base := v_items.taxable_net + case when o.service_charge_taxable then o.service_charge_total else 0 end;
  v_tax := case
    when o.tax_rate_bps = 0 then 0
    when o.tax_inclusive then round(v_base::numeric * o.tax_rate_bps / (10000 + o.tax_rate_bps))
    else round(v_base::numeric * o.tax_rate_bps / 10000)
  end;
  if o.tax_total <> v_tax then
    perform app.fail('tax_mismatch', format('tax %s <> expected %s on base %s', o.tax_total, v_tax, v_base));
  end if;

  select count(*) filter (where status <> 'paid') as unpaid,
         coalesce(sum(amount) filter (where status = 'paid'), 0) as applied,
         coalesce(sum(amount) filter (where status = 'paid' and method_type <> 'kasbon'), 0) as paid,
         coalesce(sum(change_amount) filter (where status = 'paid'), 0) as change,
         count(*) filter (where method_type = 'kasbon') as kasbon_rows
    into v_pay
    from public.payments
   where order_id = p_order_id;

  if v_pay.unpaid > 0 then
    perform app.fail('payment_pending', 'every payment must be paid before the order completes');
  end if;
  if v_pay.applied <> o.grand_total then
    perform app.fail('payment_mismatch', format('payments %s <> grand_total %s', v_pay.applied, o.grand_total));
  end if;
  if v_pay.paid <> o.paid_total then
    perform app.fail('payment_mismatch', format('non-kasbon payments %s <> paid_total %s', v_pay.paid, o.paid_total));
  end if;
  if v_pay.change <> o.change_total then
    perform app.fail('payment_mismatch', format('change %s <> change_total %s', v_pay.change, o.change_total));
  end if;
  if v_pay.kasbon_rows > 0 and o.customer_id is null then
    perform app.fail('kasbon_requires_customer', 'kasbon needs a customer');
  end if;
  if (o.points_redeemed > 0 or o.points_earned > 0) and o.customer_id is null then
    perform app.fail('loyalty_requires_customer', 'points need a customer');
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- save_promotion(p): the promotion and its store list in one transaction.
--   p = {id?, name, description, promo_type, rules, priority, is_stackable,
--        starts_at, ends_at, days_of_week, start_time, end_time, is_active,
--        store_ids: [uuid, ...]}   (empty store_ids = every store)
-- The table's CHECK constraints validate the rules (app.promotion_rules_valid).
-- ---------------------------------------------------------------------------
create or replace function public.save_promotion(p jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := coalesce((p ->> 'id')::uuid, gen_random_uuid());
  v_stores uuid[];
begin
  if not app.has_permission('promo.manage') then
    perform app.fail('permission_denied', 'promo.manage is required');
  end if;
  if coalesce(length(trim(p ->> 'name')), 0) = 0 then
    perform app.fail('invalid_input', 'promotion name is required');
  end if;
  if not app.promotion_rules_valid(p ->> 'promo_type', p -> 'rules') then
    perform app.fail('promotion_rules_invalid', coalesce(p ->> 'promo_type', 'missing promo_type'));
  end if;

  select coalesce(array_agg(e.value::uuid), '{}') into v_stores
  from jsonb_array_elements_text(coalesce(p -> 'store_ids', '[]'::jsonb)) as e(value);
  if exists (select 1 from unnest(v_stores) s(id) where not exists (select 1 from public.stores st where st.id = s.id)) then
    perform app.fail('invalid_input', 'unknown store in store_ids');
  end if;

  insert into public.promotions (id, name, description, promo_type, rules, priority, is_stackable,
                                 starts_at, ends_at, days_of_week, start_time, end_time, is_active)
  values (v_id, trim(p ->> 'name'), nullif(trim(p ->> 'description'), ''), p ->> 'promo_type', p -> 'rules',
          coalesce((p ->> 'priority')::integer, 100), coalesce((p ->> 'is_stackable')::boolean, false),
          (p ->> 'starts_at')::timestamptz, (p ->> 'ends_at')::timestamptz,
          case when jsonb_typeof(p -> 'days_of_week') = 'array'
               then (select array_agg(d.value::smallint) from jsonb_array_elements_text(p -> 'days_of_week') d(value))
          end,
          (p ->> 'start_time')::time, (p ->> 'end_time')::time, coalesce((p ->> 'is_active')::boolean, true))
  on conflict (id) do update set
    name = excluded.name,
    description = excluded.description,
    promo_type = excluded.promo_type,
    rules = excluded.rules,
    priority = excluded.priority,
    is_stackable = excluded.is_stackable,
    starts_at = excluded.starts_at,
    ends_at = excluded.ends_at,
    days_of_week = excluded.days_of_week,
    start_time = excluded.start_time,
    end_time = excluded.end_time,
    is_active = excluded.is_active;

  delete from public.promotion_stores ps
   where ps.promotion_id = v_id and not (ps.store_id = any (v_stores));
  insert into public.promotion_stores (promotion_id, store_id)
  select v_id, s.id from unnest(v_stores) s(id)
  on conflict do nothing;

  return jsonb_build_object('promotion_id', v_id, 'store_count', cardinality(v_stores));
end;
$$;

revoke execute on function public.save_promotion(jsonb) from public, anon;
grant execute on function public.save_promotion(jsonb) to authenticated, service_role;
