-- Hardening after the seed-medication-catalog implementation review
-- (context/changes/seed-medication-catalog/reviews/impl-review.md: F1, F3).
-- Constraints only; existing data already satisfies them.

-- F1: a per-kg rule cannot exceed its own daily ceiling.
alter table public.products
  add constraint products_dose_per_kg_positive
    check (dose_mg_per_kg is null or dose_mg_per_kg > 0),
  add constraint products_per_kg_within_daily_ceiling
    check (dose_mg_per_kg is null or dose_mg_per_kg * max_doses_24h <= max_mg_per_kg_24h);

-- F3: sane numeric bounds, matching the children table (weight 0.5–150 kg).
alter table public.products
  add constraint products_weight_bounds check (min_weight_kg >= 0 and max_weight_kg <= 150);

alter table public.product_dose_bands
  add constraint product_dose_bands_weight_bounds check (weight_min_kg >= 0 and weight_max_kg <= 150);

-- A typo such as 0.4 h must not shorten a dosing interval.
alter table public.substances
  add constraint substances_min_interval_hours_bounds check (min_interval_hours between 1 and 24);
