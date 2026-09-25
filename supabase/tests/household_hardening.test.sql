-- Hardening from the implementation review: empty-household cleanup, date check,
-- narrowed grants. Synthetic users and data only.
begin;
create extension if not exists pgtap with schema extensions;

select plan(11);

insert into auth.users (id, aud, role, email)
values
  ('00000000-0000-4000-8000-0000000000d1', 'authenticated', 'authenticated', 'caregiver-d@example.test'),
  ('00000000-0000-4000-8000-0000000000e1', 'authenticated', 'authenticated', 'caregiver-e@example.test');

create temp table test_ids (k text primary key, id uuid not null);
grant select, insert on test_ids to authenticated;

-- Caregiver D: household with one child.
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-0000000000d1","role":"authenticated"}';

insert into test_ids (k, id) select 'household_d', public.create_household('Dom testowy D');

with c as (
  insert into public.children (household_id, display_name, birth_date, weight_kg, weight_measured_at)
  values ((select id from test_ids where k = 'household_d'), 'Dziecko testowe D', '2024-03-01', 11.2, '2026-09-01')
  returning id
)
insert into test_ids (k, id) select 'child_d', id from c;

-- F3: weight measured before birth is rejected by the database.
select throws_ok(
  $$insert into public.children (household_id, display_name, birth_date, weight_kg, weight_measured_at)
    values ((select id from test_ids where k = 'household_d'), 'Dziecko testowe przed', '2024-03-01', 4, '2024-02-01')$$,
  '23514',
  null,
  'F3: weight_measured_at before birth_date violates check'
);

-- F6: authenticated cannot set server-managed columns or delete directly.
select throws_ok(
  $$insert into public.children (id, household_id, display_name, birth_date, weight_kg, weight_measured_at)
    values (gen_random_uuid(), (select id from test_ids where k = 'household_d'), 'Dziecko testowe id', '2024-03-01', 10, '2026-09-01')$$,
  '42501',
  null,
  'F6: authenticated cannot choose children.id'
);

select throws_ok(
  $$delete from public.children where id = (select id from test_ids where k = 'child_d')$$,
  '42501',
  null,
  'F6: authenticated has no DELETE privilege on children'
);

select throws_ok(
  $$insert into public.households (name) values ('Dom z pominięciem RPC')$$,
  '42501',
  null,
  'F6: authenticated cannot insert households directly'
);

reset role;

-- F6: privileges as seen by the catalog.
select is(has_table_privilege('anon', 'public.children', 'select'), false, 'F6: anon has no SELECT on children');
select is(has_table_privilege('authenticated', 'public.children', 'truncate'), false, 'F6: authenticated has no TRUNCATE on children');
select is(
  has_column_privilege('authenticated', 'public.children', 'weight_kg', 'insert'),
  true,
  'F6: authenticated can insert data columns'
);

-- F2: deleting the last member deletes the household and its children.
delete from auth.users where id = '00000000-0000-4000-8000-0000000000d1';

select is(
  (select count(*)::int from public.households where id = (select id from test_ids where k = 'household_d')),
  0,
  'F2: household without members is deleted'
);

select is(
  (select count(*)::int from public.children where id = (select id from test_ids where k = 'child_d')),
  0,
  'F2: its children are deleted with it'
);

-- F2: a household that still has a member survives (membership removed directly).
set local role authenticated;
set local request.jwt.claims = '{"sub":"00000000-0000-4000-8000-0000000000e1","role":"authenticated"}';
insert into test_ids (k, id) select 'household_e', public.create_household('Dom testowy E');
reset role;

insert into auth.users (id, aud, role, email)
values ('00000000-0000-4000-8000-0000000000e2', 'authenticated', 'authenticated', 'caregiver-e2@example.test');
insert into public.household_members (household_id, user_id)
values ((select id from test_ids where k = 'household_e'), '00000000-0000-4000-8000-0000000000e2');

delete from auth.users where id = '00000000-0000-4000-8000-0000000000e2';

select is(
  (select count(*)::int from public.households where id = (select id from test_ids where k = 'household_e')),
  1,
  'F2: household with a remaining member is kept'
);

select is(
  (select count(*)::int from public.household_members where household_id = (select id from test_ids where k = 'household_e')),
  1,
  'F2: remaining member is untouched'
);

select * from finish();
rollback;
