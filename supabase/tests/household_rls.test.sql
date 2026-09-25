-- Household isolation proven at the database level, as real roles.
-- Synthetic users and data only.
begin;
create extension if not exists pgtap with schema extensions;

select plan(17);

-- Synthetic caregivers A and B.
insert into auth.users (id, aud, role, email)
values
  ('00000000-0000-4000-8000-00000000000a', 'authenticated', 'authenticated', 'caregiver-a@example.test'),
  ('00000000-0000-4000-8000-00000000000b', 'authenticated', 'authenticated', 'caregiver-b@example.test');

-- Scratch table for ids created during the test, readable by the test roles.
create temp table test_ids (k text primary key, id uuid not null);
grant select, insert on test_ids to authenticated, anon;

-- ---------------------------------------------------------------------------
-- Caregiver A
-- ---------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated"}';

insert into test_ids (k, id) select 'household_a', public.create_household('Dom testowy A');

select isnt(
  (select id from test_ids where k = 'household_a'),
  null,
  'A: create_household returns an id'
);

select is(
  (select count(*)::int from public.households),
  1,
  'A: sees exactly one household'
);

select is(
  (select array_agg(user_id) from public.household_members),
  array['00000000-0000-4000-8000-00000000000a'::uuid],
  'A: sees itself in household_members'
);

select throws_ok(
  $$select public.create_household('Drugi dom testowy A')$$,
  '23505',
  null,
  'A: second create_household is rejected'
);

select lives_ok(
  $$with c as (
      insert into public.children (household_id, display_name, birth_date, weight_kg, weight_measured_at)
      values (
      (select id from test_ids where k = 'household_a'),
      'Dziecko testowe',
      '2024-01-15',
      12.5,
      '2026-09-01'
    ) returning id
    )
    insert into test_ids (k, id) select 'child_a', id from c$$,
  'A: inserts a child into own household'
);

-- ---------------------------------------------------------------------------
-- Caregiver B (own household)
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-00000000000b","role":"authenticated"}';

select lives_ok(
  $$select public.create_household('Dom testowy B')$$,
  'B: creates own household'
);

select is(
  (select count(*)::int from public.children),
  0,
  'B: sees no children'
);

select is(
  (select count(*)::int from public.households where id = (select id from test_ids where k = 'household_a')),
  0,
  'B: does not see household A'
);

select is(
  (select count(*)::int from public.household_members where household_id = (select id from test_ids where k = 'household_a')),
  0,
  'B: does not see members of household A'
);

select throws_ok(
  $$insert into public.children (household_id, display_name, birth_date, weight_kg, weight_measured_at)
    values ((select id from test_ids where k = 'household_a'), 'Obce dziecko testowe', '2024-02-01', 10, '2026-09-01')$$,
  '42501',
  null,
  'B: cannot insert a child into household A'
);

select is_empty(
  $$update public.children set weight_kg = 20 where id = (select id from test_ids where k = 'child_a') returning id$$,
  'B: update of A''s child affects no rows'
);

-- ---------------------------------------------------------------------------
-- Caregiver A: column-scoped updates
-- ---------------------------------------------------------------------------
reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated"}';

select is(
  (select weight_kg from public.children where id = (select id from test_ids where k = 'child_a')),
  12.50::numeric(5, 2),
  'A: child weight unchanged after B''s update attempt'
);

select throws_ok(
  $$update public.children set birth_date = '2023-01-01' where id = (select id from test_ids where k = 'child_a')$$,
  '42501',
  null,
  'A: cannot update birth_date'
);

select isnt_empty(
  $$update public.children set weight_kg = 13.1, weight_measured_at = '2026-09-20'
    where id = (select id from test_ids where k = 'child_a') returning id$$,
  'A: can update weight'
);

select throws_ok(
  $$insert into public.children (household_id, display_name, birth_date, weight_kg, weight_measured_at)
    values ((select id from test_ids where k = 'household_a'), 'Dziecko testowe zero', '2024-01-15', 0, '2026-09-01')$$,
  '23514',
  null,
  'A: weight_kg = 0 violates check'
);

-- ---------------------------------------------------------------------------
-- Anonymous
-- ---------------------------------------------------------------------------
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';

select throws_ok(
  $$select id from public.children$$,
  '42501',
  null,
  'anon: has no table privileges on children'
);

select throws_ok(
  $$select public.create_household('Dom anonimowy')$$,
  '42501',
  null,
  'anon: cannot execute create_household'
);

reset role;

select * from finish();
rollback;
