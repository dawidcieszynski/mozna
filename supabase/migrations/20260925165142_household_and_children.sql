-- Households with flat membership (one caregiver = one household) and children
-- with the data the dosing gate needs. RLS on every table; membership checks go
-- through a security definer function to avoid recursive policies.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  created_at timestamptz not null default now()
);

create table public.household_members (
  household_id uuid not null references public.households (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (household_id, user_id),
  unique (user_id)
);

create table public.children (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 60),
  birth_date date not null check (birth_date >= date '2000-01-01'),
  weight_kg numeric(5, 2) not null check (weight_kg between 0.5 and 150),
  weight_measured_at date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index children_household_id_idx on public.children (household_id);

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger children_set_updated_at
  before update on public.children
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Functions
-- ---------------------------------------------------------------------------

create function public.is_household_member(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.household_members m
    where m.household_id = p_household_id
      and m.user_id = auth.uid()
  );
$$;

create function public.create_household(p_name text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_household_id uuid;
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  insert into public.households (name)
  values (p_name)
  returning id into v_household_id;

  -- unique (user_id) rejects a second household for the same caregiver.
  insert into public.household_members (household_id, user_id)
  values (v_household_id, v_user_id);

  return v_household_id;
end;
$$;

revoke execute on function public.is_household_member(uuid) from public, anon;
grant execute on function public.is_household_member(uuid) to authenticated;

revoke execute on function public.create_household(text) from public, anon;
grant execute on function public.create_household(text) to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.children enable row level security;

-- households: read own household; writes only through create_household().
create policy "households_select_member"
  on public.households
  for select
  to authenticated
  using (public.is_household_member(id));

-- household_members: read own membership and co-members; no direct writes.
create policy "household_members_select_member"
  on public.household_members
  for select
  to authenticated
  using (user_id = auth.uid() or public.is_household_member(household_id));

-- children: members read, add and update; no delete.
create policy "children_select_member"
  on public.children
  for select
  to authenticated
  using (public.is_household_member(household_id));

create policy "children_insert_member"
  on public.children
  for insert
  to authenticated
  with check (public.is_household_member(household_id));

create policy "children_update_member"
  on public.children
  for update
  to authenticated
  using (public.is_household_member(household_id))
  with check (public.is_household_member(household_id));

-- Only the current weight is editable; name and birth date stay fixed.
revoke update on public.children from authenticated;
grant update (weight_kg, weight_measured_at) on public.children to authenticated;
