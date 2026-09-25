-- Medication catalog schema: read-only for signed-in users, closed to anon,
-- constraints reject invalid rules. Synthetic test rows only (rolled back).
begin;
create extension if not exists pgtap with schema extensions;

select plan(31);

-- ---------------------------------------------------------------------------
-- Privileges as seen by the catalog.
-- ---------------------------------------------------------------------------

select is(has_table_privilege('anon', 'public.substances', 'select'), false, 'anon has no SELECT on substances');
select is(has_table_privilege('anon', 'public.products', 'select'), false, 'anon has no SELECT on products');
select is(has_table_privilege('anon', 'public.product_dose_bands', 'select'), false, 'anon has no SELECT on product_dose_bands');
select is(has_table_privilege('anon', 'public.product_barcodes', 'select'), false, 'anon has no SELECT on product_barcodes');
select is(has_table_privilege('anon', 'public.substance_pair_rules', 'select'), false, 'anon has no SELECT on substance_pair_rules');

select is(has_table_privilege('authenticated', 'public.substances', 'select'), true, 'authenticated has SELECT on substances');
select is(has_table_privilege('authenticated', 'public.products', 'select'), true, 'authenticated has SELECT on products');
select is(has_table_privilege('authenticated', 'public.product_dose_bands', 'select'), true, 'authenticated has SELECT on product_dose_bands');
select is(has_table_privilege('authenticated', 'public.product_barcodes', 'select'), true, 'authenticated has SELECT on product_barcodes');
select is(has_table_privilege('authenticated', 'public.substance_pair_rules', 'select'), true, 'authenticated has SELECT on substance_pair_rules');

select is(has_table_privilege('authenticated', 'public.substances', 'insert'), false, 'authenticated has no INSERT on substances');
select is(has_table_privilege('authenticated', 'public.substances', 'update'), false, 'authenticated has no UPDATE on substances');
select is(has_table_privilege('authenticated', 'public.substances', 'delete'), false, 'authenticated has no DELETE on substances');
select is(has_table_privilege('authenticated', 'public.products', 'insert'), false, 'authenticated has no INSERT on products');
select is(has_table_privilege('authenticated', 'public.products', 'update'), false, 'authenticated has no UPDATE on products');
select is(has_table_privilege('authenticated', 'public.products', 'delete'), false, 'authenticated has no DELETE on products');
select is(has_table_privilege('authenticated', 'public.product_dose_bands', 'insert'), false, 'authenticated has no INSERT on product_dose_bands');
select is(has_table_privilege('authenticated', 'public.product_dose_bands', 'update'), false, 'authenticated has no UPDATE on product_dose_bands');
select is(has_table_privilege('authenticated', 'public.product_dose_bands', 'delete'), false, 'authenticated has no DELETE on product_dose_bands');
select is(has_table_privilege('authenticated', 'public.product_barcodes', 'insert'), false, 'authenticated has no INSERT on product_barcodes');
select is(has_table_privilege('authenticated', 'public.product_barcodes', 'update'), false, 'authenticated has no UPDATE on product_barcodes');
select is(has_table_privilege('authenticated', 'public.product_barcodes', 'delete'), false, 'authenticated has no DELETE on product_barcodes');
select is(has_table_privilege('authenticated', 'public.substance_pair_rules', 'insert'), false, 'authenticated has no INSERT on substance_pair_rules');
select is(has_table_privilege('authenticated', 'public.substance_pair_rules', 'update'), false, 'authenticated has no UPDATE on substance_pair_rules');
select is(has_table_privilege('authenticated', 'public.substance_pair_rules', 'delete'), false, 'authenticated has no DELETE on substance_pair_rules');

-- ---------------------------------------------------------------------------
-- Synthetic catalog rows (as postgres) for the constraint checks.
-- ---------------------------------------------------------------------------

insert into public.substances (id, name_pl, min_interval_hours, source_url, checked_at)
values
  ('test_substance', 'Substancja testowa', 6, 'https://example.test/substance', '2026-01-01'),
  ('test_substance_z', 'Substancja testowa Z', 4, 'https://example.test/substance-z', '2026-01-01');

insert into public.products (
  id, substance_id, name_pl, form, strength_mg_per_ml, chpl_url, rule_type,
  max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
  source_url, checked_at
)
values (
  'test_product', 'test_substance', 'Produkt testowy', 'oral_suspension', 40, 'https://example.test/chpl', 'weight_band',
  3, 30, 6, 5, 40,
  'https://example.test/chpl', '2026-01-01'
);

insert into public.product_dose_bands (product_id, weight_min_kg, weight_max_kg, dose_mg, max_doses_24h)
values ('test_product', 5, 10, 50, 3);

-- ---------------------------------------------------------------------------
-- No writes through the API role.
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-0000000000f1","role":"authenticated"}';

select throws_ok(
  $$insert into public.products (
      id, substance_id, name_pl, form, strength_mg_per_ml, chpl_url, rule_type,
      max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
      source_url, checked_at
    )
    values (
      'test_product_api', 'test_substance', 'Produkt z API', 'oral_suspension', 40, 'https://example.test/chpl', 'weight_band',
      3, 30, 6, 5, 40,
      'https://example.test/chpl', '2026-01-01'
    )$$,
  '42501',
  null,
  'authenticated cannot insert into products'
);

reset role;

-- ---------------------------------------------------------------------------
-- Constraints (as postgres).
-- ---------------------------------------------------------------------------

select throws_ok(
  $$insert into public.products (
      id, substance_id, name_pl, form, strength_mg_per_ml, chpl_url, rule_type,
      max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
      source_url, checked_at
    )
    values (
      'test_product_per_kg', 'test_substance', 'Produkt testowy per kg', 'oral_suspension', 24, 'https://example.test/chpl', 'per_kg',
      4, 60, 2, 4, 42,
      'https://example.test/chpl', '2026-01-01'
    )$$,
  '23514',
  null,
  'per_kg product without dose_mg_per_kg violates check'
);

select throws_ok(
  $$insert into public.product_barcodes (gtin, product_id, package_ml, source_url, checked_at)
    values ('5900000000000', 'test_product', 100, 'https://example.test/rpl', '2026-01-01')$$,
  '23514',
  null,
  '13-digit GTIN violates check'
);

select throws_ok(
  $$insert into public.substance_pair_rules (substance_a, substance_b, rule, message_pl, source_urls, checked_at)
    values ('test_substance_z', 'test_substance', 'block_until_previous_interval', 'Komunikat testowy',
            array['https://example.test/pair'], '2026-01-01')$$,
  '23514',
  null,
  'pair with substance_a > substance_b violates check'
);

select throws_ok(
  $$insert into public.product_dose_bands (product_id, weight_min_kg, weight_max_kg, dose_mg, max_doses_24h)
    values ('test_product', 8, 15, 100, 3)$$,
  '23P01',
  null,
  'overlapping bands for one product are rejected'
);

select lives_ok(
  $$insert into public.product_dose_bands (product_id, weight_min_kg, weight_max_kg, dose_mg, max_doses_24h)
    values ('test_product', 10, 15, 100, 3)$$,
  'adjacent band starting at the previous weight_max_kg is accepted'
);

select * from finish();
rollback;
