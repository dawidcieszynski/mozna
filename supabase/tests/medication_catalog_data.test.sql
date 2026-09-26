-- Medication catalog data: double entry. Every expected value below is typed in
-- independently from context/changes/seed-medication-catalog/verification.md
-- (status: zatwierdzone), never derived from the tables, so a typo in the seed
-- migration fails here.
begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

-- ---------------------------------------------------------------------------
-- substances
-- ---------------------------------------------------------------------------

select results_eq(
  $$select id, name_pl, min_interval_hours, source_url, checked_at
    from public.substances order by id$$,
  $$values
    ('ibuprofen'::text, 'Ibuprofen'::text, 8::numeric,
     'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic'::text, '2026-09-25'::date),
    ('paracetamol'::text, 'Paracetamol'::text, 4::numeric,
     'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic'::text, '2026-09-25'::date)$$,
  'substances: paracetamol 4 h, ibuprofen 8 h, with source and check date'
);

-- ---------------------------------------------------------------------------
-- products: every rule column, one assertion per product
-- ---------------------------------------------------------------------------

select results_eq(
  $$select substance_id, name_pl, form, strength_mg_per_ml, rule_type, dose_mg_per_kg,
           max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
           chpl_url, chpl_text_date, source_url, checked_at
    from public.products where id = 'panadol-dla-dzieci-120mg-5ml'$$,
  $$values (
    'paracetamol'::text, 'Panadol dla dzieci, 120 mg/5 ml, zawiesina doustna'::text,
    'oral_suspension'::text, 24::numeric, 'per_kg'::text, 15::numeric,
    4::int, 60::numeric, 3::int, 6::numeric, 42::numeric,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic'::text,
    null::date,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic'::text,
    '2026-09-25'::date
  )$$,
  'Panadol: rule columns match verification.md (chpl_text_date null, N1)'
);

select results_eq(
  $$select substance_id, name_pl, form, strength_mg_per_ml, rule_type, dose_mg_per_kg,
           max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
           chpl_url, chpl_text_date, source_url, checked_at
    from public.products where id = 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'$$,
  $$values (
    'ibuprofen'::text, 'Nurofen dla dzieci Forte pomarańczowy, 40 mg/ml, zawiesina doustna'::text,
    'oral_suspension'::text, 40::numeric, 'weight_band'::text, null::numeric,
    3::int, 30::numeric, 3::int, 5::numeric, 40::numeric,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic'::text,
    '2025-04-23'::date,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic'::text,
    '2026-09-25'::date
  )$$,
  'Forte pomarańczowy: rule columns match verification.md'
);

select results_eq(
  $$select substance_id, name_pl, form, strength_mg_per_ml, rule_type, dose_mg_per_kg,
           max_doses_24h, max_mg_per_kg_24h, min_age_months, min_weight_kg, max_weight_kg,
           chpl_url, chpl_text_date, source_url, checked_at
    from public.products where id = 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'$$,
  $$values (
    'ibuprofen'::text, 'Nurofen dla dzieci Forte truskawkowy, 40 mg/ml, zawiesina doustna'::text,
    'oral_suspension'::text, 40::numeric, 'weight_band'::text, null::numeric,
    3::int, 30::numeric, 3::int, 5::numeric, 40::numeric,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic'::text,
    '2025-04-23'::date,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic'::text,
    '2026-09-25'::date
  )$$,
  'Forte truskawkowy: rule columns match verification.md'
);

-- ---------------------------------------------------------------------------
-- warnings: full arrays, transcribed from verification.md (review F4)
-- ---------------------------------------------------------------------------

select is(
  (select warnings from public.products where id = 'panadol-dla-dzieci-120mg-5ml'),
  array[
    'Nie stosować przy nadwrażliwości na paracetamol lub którąkolwiek substancję pomocniczą.',
    'Nie stosować przy ciężkiej niewydolności wątroby lub nerek.',
    'Bez konsultacji z lekarzem nie stosować regularnie dłużej niż 3 dni.',
    'Nie stosować przy dziedzicznej nietolerancji fruktozy (zawiera maltitol i sorbitol).'
  ]::text[],
  'Panadol warnings match verification.md'
);
select is(
  (select warnings from public.products where id = 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'),
  array[
    'Nie stosować przy nadwrażliwości na ibuprofen lub którąkolwiek substancję pomocniczą.',
    'Nie stosować, jeśli po kwasie acetylosalicylowym, ibuprofenie lub innym NLPZ wystąpiły reakcje nadwrażliwości (np. skurcz oskrzeli, astma, pokrzywka, obrzęk).',
    'Nie stosować po krwawieniu lub perforacji przewodu pokarmowego związanych z wcześniejszym leczeniem NLPZ.',
    'Nie stosować przy czynnej lub nawracającej chorobie wrzodowej żołądka lub dwunastnicy albo krwotoku.',
    'Nie stosować przy krwawieniu z naczyń mózgowych lub innym czynnym krwawieniu.',
    'Nie stosować przy ciężkiej niewydolności wątroby, nerek lub serca.',
    'Nie stosować przy zaburzeniach wytwarzania krwi o nieustalonym pochodzeniu.',
    'Nie stosować przy ciężkim odwodnieniu (wymioty, biegunka, zbyt mało płynów).',
    'U dzieci 3–5 mies.: skonsultuj z lekarzem, jeśli objawy nasilają się lub nie ustępują po 24 godzinach.',
    'U dzieci od 6 mies. do 12 lat: skonsultuj z lekarzem, jeśli lek jest potrzebny dłużej niż 3 dni lub objawy się nasilają.'
  ]::text[],
  'Forte pomarańczowy warnings match verification.md'
);
select is(
  (select warnings from public.products where id = 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'),
  array[
    'Nie stosować przy nadwrażliwości na ibuprofen lub którąkolwiek substancję pomocniczą.',
    'Nie stosować, jeśli po kwasie acetylosalicylowym, ibuprofenie lub innym NLPZ wystąpiły reakcje nadwrażliwości (np. skurcz oskrzeli, astma, pokrzywka, obrzęk).',
    'Nie stosować po krwawieniu lub perforacji przewodu pokarmowego związanych z wcześniejszym leczeniem NLPZ.',
    'Nie stosować przy czynnej lub nawracającej chorobie wrzodowej żołądka lub dwunastnicy albo krwotoku.',
    'Nie stosować przy krwawieniu z naczyń mózgowych lub innym czynnym krwawieniu.',
    'Nie stosować przy ciężkiej niewydolności wątroby, nerek lub serca.',
    'Nie stosować przy zaburzeniach wytwarzania krwi o nieustalonym pochodzeniu.',
    'Nie stosować przy ciężkim odwodnieniu (wymioty, biegunka, zbyt mało płynów).',
    'U dzieci 3–5 mies.: skonsultuj z lekarzem, jeśli objawy nasilają się lub nie ustępują po 24 godzinach.',
    'U dzieci od 6 mies. do 12 lat: skonsultuj z lekarzem, jeśli lek jest potrzebny dłużej niż 3 dni lub objawy się nasilają.'
  ]::text[],
  'Forte truskawkowy warnings match verification.md'
);

-- A band never allows more doses per day than its product (review F2).
select is_empty(
  $$select b.product_id, b.weight_min_kg from public.product_dose_bands b
    join public.products p on p.id = b.product_id
    where b.max_doses_24h > p.max_doses_24h$$,
  'no band allows more doses per 24 h than its product'
);

-- ---------------------------------------------------------------------------
-- product_dose_bands: full list per Forte product, none for Panadol
-- ---------------------------------------------------------------------------

select results_eq(
  $$select weight_min_kg, weight_max_kg, dose_mg, max_doses_24h
    from public.product_dose_bands
    where product_id = 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'
    order by weight_min_kg$$,
  $$values
    (5::numeric, 7::numeric, 50::numeric, 3::int),
    (7::numeric, 10::numeric, 50::numeric, 3::int),
    (10::numeric, 16::numeric, 100::numeric, 3::int),
    (16::numeric, 20::numeric, 150::numeric, 3::int),
    (20::numeric, 30::numeric, 200::numeric, 3::int),
    (30::numeric, 40::numeric, 300::numeric, 3::int)$$,
  'Forte pomarańczowy: six bands as in verification.md'
);

select results_eq(
  $$select weight_min_kg, weight_max_kg, dose_mg, max_doses_24h
    from public.product_dose_bands
    where product_id = 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'
    order by weight_min_kg$$,
  $$values
    (5::numeric, 7::numeric, 50::numeric, 3::int),
    (7::numeric, 10::numeric, 50::numeric, 3::int),
    (10::numeric, 16::numeric, 100::numeric, 3::int),
    (16::numeric, 20::numeric, 150::numeric, 3::int),
    (20::numeric, 30::numeric, 200::numeric, 3::int),
    (30::numeric, 40::numeric, 300::numeric, 3::int)$$,
  'Forte truskawkowy: six bands as in verification.md'
);

select is_empty(
  $$select 1 from public.product_dose_bands where product_id = 'panadol-dla-dzieci-120mg-5ml'$$,
  'Panadol (per_kg) has no dose bands'
);

-- Daily ceiling: dose_mg * max_doses_24h <= max_mg_per_kg_24h * weight_min_kg.
select is_empty(
  $$select b.product_id, b.weight_min_kg
    from public.product_dose_bands b
    join public.products p on p.id = b.product_id
    where b.dose_mg * b.max_doses_24h > p.max_mg_per_kg_24h * b.weight_min_kg$$,
  'no band exceeds the product daily ceiling at its lower weight'
);

-- Contiguity: first band starts at min_weight_kg, each next one at the previous
-- weight_max_kg, last ends at max_weight_kg; every weight_band product has bands.
select is_empty(
  $$with b as (
      select b.product_id, b.weight_min_kg, b.weight_max_kg,
             p.min_weight_kg as product_min, p.max_weight_kg as product_max,
             lag(b.weight_max_kg) over (partition by b.product_id order by b.weight_min_kg) as prev_max,
             row_number() over (partition by b.product_id order by b.weight_min_kg) as rn,
             count(*) over (partition by b.product_id) as n
      from public.product_dose_bands b
      join public.products p on p.id = b.product_id
    )
    select product_id, weight_min_kg from b
    where (rn = 1 and weight_min_kg <> product_min)
       or (rn > 1 and weight_min_kg <> prev_max)
       or (rn = n and weight_max_kg <> product_max)
    union all
    select p.id, null from public.products p
    where p.rule_type = 'weight_band'
      and not exists (select 1 from public.product_dose_bands x where x.product_id = p.id)$$,
  'bands of every weight_band product run contiguously from min_weight_kg to max_weight_kg'
);

-- ---------------------------------------------------------------------------
-- product_barcodes
-- ---------------------------------------------------------------------------

select results_eq(
  $$select gtin, product_id, package_ml, source_url, checked_at
    from public.product_barcodes order by gtin$$,
  $$values
    ('05909990327317'::text, 'panadol-dla-dzieci-120mg-5ml'::text, 100::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222833'::text, 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'::text, 100::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222840'::text, 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'::text, 150::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222857'::text, 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml'::text, 200::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222970'::text, 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'::text, 100::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222987'::text, 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'::text, 150::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991222994'::text, 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml'::text, 200::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991447168'::text, 'panadol-dla-dzieci-120mg-5ml'::text, 200::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date),
    ('05909991447175'::text, 'panadol-dla-dzieci-120mg-5ml'::text, 60::numeric,
     'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv'::text, '2026-09-25'::date)$$,
  'nine active GTINs map to the expected product and package size'
);

select is_empty(
  $$select 1 from public.product_barcodes where gtin = '05900000000000'$$,
  'unknown GTIN returns no product'
);

-- ---------------------------------------------------------------------------
-- substance_pair_rules
-- ---------------------------------------------------------------------------

select results_eq(
  $$select substance_a, substance_b, rule, message_pl, source_urls, checked_at
    from public.substance_pair_rules$$,
  $$values (
    'ibuprofen'::text, 'paracetamol'::text, 'block_until_previous_interval'::text,
    'Naprzemienne podawanie tylko po konsultacji z lekarzem.'::text,
    array[
      'https://ptp.edu.pl/najnowsze-zalecenia-dotyczace-leczenia-przeciwgoraczkowego-u-dzieci-w-wieku-0-36-miesiecy/',
      'https://www.nhs.uk/conditions/fever-in-children/'
    ]::text[],
    '2026-09-25'::date
  )$$,
  'paracetamol-ibuprofen pair: block_until_previous_interval with the approved message'
);

-- ---------------------------------------------------------------------------
-- Signed-in users read the catalog.
-- ---------------------------------------------------------------------------

set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-0000000000f2","role":"authenticated"}';

select is(
  (select count(*)::int from public.products),
  3,
  'authenticated reads all 3 catalog products'
);

reset role;

select * from finish();
rollback;
