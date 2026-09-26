-- Medication catalog data. Source: context/changes/seed-medication-catalog/verification.md
-- (status: zatwierdzone, 2026-09-26). Every value, id, source_url and checked_at is
-- copied 1:1 from that document. Public reference data from ChPL and the RPL CSV;
-- no personal data. Data only: no schema changes.

-- ---------------------------------------------------------------------------
-- substances
-- ---------------------------------------------------------------------------

insert into public.substances (id, name_pl, min_interval_hours, source_url, checked_at)
values
  ('paracetamol', 'Paracetamol', 4,
   'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic', '2026-09-25'),
  ('ibuprofen', 'Ibuprofen', 8,
   'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic', '2026-09-25');

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------

insert into public.products (
  id, substance_id, name_pl, form, strength_mg_per_ml, chpl_url, chpl_text_date,
  rule_type, dose_mg_per_kg, max_doses_24h, max_mg_per_kg_24h,
  min_age_months, min_weight_kg, max_weight_kg, warnings, source_url, checked_at
)
values
  (
    'panadol-dla-dzieci-120mg-5ml', 'paracetamol',
    'Panadol dla dzieci, 120 mg/5 ml, zawiesina doustna', 'oral_suspension', 24,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic', null,
    'per_kg', 15, 4, 60,
    3, 6, 42,
    array[
      'Nie stosować przy nadwrażliwości na paracetamol lub którąkolwiek substancję pomocniczą.',
      'Nie stosować przy ciężkiej niewydolności wątroby lub nerek.',
      'Bez konsultacji z lekarzem nie stosować regularnie dłużej niż 3 dni.',
      'Nie stosować przy dziedzicznej nietolerancji fruktozy (zawiera maltitol i sorbitol).'
    ],
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic', '2026-09-25'
  ),
  (
    'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 'ibuprofen',
    'Nurofen dla dzieci Forte pomarańczowy, 40 mg/ml, zawiesina doustna', 'oral_suspension', 40,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic', '2025-04-23',
    'weight_band', null, 3, 30,
    3, 5, 40,
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
    ],
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic', '2026-09-25'
  ),
  (
    'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 'ibuprofen',
    'Nurofen dla dzieci Forte truskawkowy, 40 mg/ml, zawiesina doustna', 'oral_suspension', 40,
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic', '2025-04-23',
    'weight_band', null, 3, 30,
    3, 5, 40,
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
    ],
    'https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic', '2026-09-25'
  );

-- ---------------------------------------------------------------------------
-- product_dose_bands: contiguous [weight_min_kg, weight_max_kg), last ends at
-- products.max_weight_kg (verification.md Z2, Z5).
-- ---------------------------------------------------------------------------

insert into public.product_dose_bands (product_id, weight_min_kg, weight_max_kg, dose_mg, max_doses_24h)
values
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 5, 7, 50, 3),
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 7, 10, 50, 3),
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 10, 16, 100, 3),
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 16, 20, 150, 3),
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 20, 30, 200, 3),
  ('nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 30, 40, 300, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 5, 7, 50, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 7, 10, 50, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 10, 16, 100, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 16, 20, 150, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 20, 30, 200, 3),
  ('nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 30, 40, 300, 3);

-- ---------------------------------------------------------------------------
-- product_barcodes: active OTC packages from the RPL CSV (downloaded 2026-09-25).
-- ---------------------------------------------------------------------------

insert into public.product_barcodes (gtin, product_id, package_ml, source_url, checked_at)
values
  ('05909991447175', 'panadol-dla-dzieci-120mg-5ml', 60,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909990327317', 'panadol-dla-dzieci-120mg-5ml', 100,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991447168', 'panadol-dla-dzieci-120mg-5ml', 200,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222833', 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 100,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222840', 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 150,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222857', 'nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml', 200,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222970', 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 100,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222987', 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 150,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25'),
  ('05909991222994', 'nurofen-dla-dzieci-forte-truskawkowy-40mg-ml', 200,
   'https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv', '2026-09-25');

-- ---------------------------------------------------------------------------
-- substance_pair_rules: one row per unordered pair (substance_a < substance_b).
-- ---------------------------------------------------------------------------

insert into public.substance_pair_rules (substance_a, substance_b, rule, message_pl, source_urls, checked_at)
values (
  'ibuprofen', 'paracetamol', 'block_until_previous_interval',
  'Naprzemienne podawanie tylko po konsultacji z lekarzem.',
  array[
    'https://ptp.edu.pl/najnowsze-zalecenia-dotyczace-leczenia-przeciwgoraczkowego-u-dzieci-w-wieku-0-36-miesiecy/',
    'https://www.nhs.uk/conditions/fever-in-children/'
  ],
  '2026-09-25'
);
