-- Read-only medication catalog: substances, products (one row per SmPC/ChPL),
-- weight bands, GTIN barcodes and substance pair rules. Every value carries its
-- source and check date. Schema only; data arrives in a separate migration after
-- human verification (context/changes/seed-medication-catalog/verification.md).

create extension if not exists btree_gist with schema extensions;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.substances (
  id text primary key,
  name_pl text not null,
  -- The substance's own minimum dosing interval; also used by the pair rule.
  min_interval_hours numeric not null check (min_interval_hours > 0),
  source_url text not null,
  checked_at date not null
);

create table public.products (
  id text primary key,
  substance_id text not null references public.substances (id) on delete restrict,
  name_pl text not null,
  form text not null check (form in ('oral_suspension')),
  strength_mg_per_ml numeric not null check (strength_mg_per_ml > 0),
  chpl_url text not null,
  -- Null when the SmPC text date could not be established.
  chpl_text_date date,
  rule_type text not null check (rule_type in ('per_kg', 'weight_band')),
  dose_mg_per_kg numeric,
  max_doses_24h int not null check (max_doses_24h > 0),
  max_mg_per_kg_24h numeric not null check (max_mg_per_kg_24h > 0),
  min_age_months int not null check (min_age_months >= 0),
  min_weight_kg numeric not null,
  max_weight_kg numeric not null,
  warnings text[] not null default '{}',
  source_url text not null,
  checked_at date not null,
  constraint products_weight_range check (max_weight_kg > min_weight_kg),
  -- per_kg products are dosed by formula; weight_band products by product_dose_bands.
  constraint products_dose_per_kg_matches_rule check ((rule_type = 'per_kg') = (dose_mg_per_kg is not null))
);

create index products_substance_id_idx on public.products (substance_id);

-- Bands are contiguous [weight_min_kg, weight_max_kg); the last one ends at
-- products.max_weight_kg. Overlap is rejected by the exclusion constraint.
create table public.product_dose_bands (
  product_id text not null references public.products (id) on delete restrict,
  weight_min_kg numeric not null,
  weight_max_kg numeric not null,
  dose_mg numeric not null check (dose_mg > 0),
  max_doses_24h int not null check (max_doses_24h > 0),
  primary key (product_id, weight_min_kg),
  constraint product_dose_bands_weight_range check (weight_max_kg > weight_min_kg),
  constraint product_dose_bands_no_overlap exclude using gist (
    product_id with =,
    numrange(weight_min_kg, weight_max_kg, '[)') with &&
  )
);

create table public.product_barcodes (
  gtin text primary key check (gtin ~ '^[0-9]{14}$'),
  product_id text not null references public.products (id) on delete restrict,
  package_ml numeric not null check (package_ml > 0),
  source_url text not null,
  checked_at date not null
);

create index product_barcodes_product_id_idx on public.product_barcodes (product_id);

-- One row per unordered pair: substance_a sorts before substance_b.
create table public.substance_pair_rules (
  substance_a text not null references public.substances (id) on delete restrict,
  substance_b text not null references public.substances (id) on delete restrict,
  rule text not null check (rule in ('block_until_previous_interval')),
  message_pl text not null,
  source_urls text[] not null,
  checked_at date not null,
  primary key (substance_a, substance_b),
  constraint substance_pair_rules_ordered check (substance_a < substance_b)
);

create index substance_pair_rules_substance_b_idx on public.substance_pair_rules (substance_b);

-- ---------------------------------------------------------------------------
-- Row level security: signed-in users read the catalog; nobody writes via API.
-- ---------------------------------------------------------------------------

alter table public.substances enable row level security;
alter table public.products enable row level security;
alter table public.product_dose_bands enable row level security;
alter table public.product_barcodes enable row level security;
alter table public.substance_pair_rules enable row level security;

create policy "substances_select_authenticated"
  on public.substances
  for select
  to authenticated
  using (true);

create policy "products_select_authenticated"
  on public.products
  for select
  to authenticated
  using (true);

create policy "product_dose_bands_select_authenticated"
  on public.product_dose_bands
  for select
  to authenticated
  using (true);

create policy "product_barcodes_select_authenticated"
  on public.product_barcodes
  for select
  to authenticated
  using (true);

create policy "substance_pair_rules_select_authenticated"
  on public.substance_pair_rules
  for select
  to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- Grants say what the policies allow (same pattern as household_hardening).
-- ---------------------------------------------------------------------------

revoke all on public.substances, public.products, public.product_dose_bands,
  public.product_barcodes, public.substance_pair_rules from anon, authenticated;

grant select on public.substances, public.products, public.product_dose_bands,
  public.product_barcodes, public.substance_pair_rules to authenticated;
