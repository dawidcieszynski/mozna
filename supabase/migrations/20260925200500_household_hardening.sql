-- Hardening after the household-with-child implementation review
-- (context/changes/household-with-child/reviews/impl-review.md: F2, F3, F6).

-- ---------------------------------------------------------------------------
-- F2: a household without members is deleted together with its children.
-- Deleting a caregiver's auth user cascades to household_members; when the last
-- member is gone, nobody can read the household through RLS, so its health data
-- would otherwise stay behind forever.
-- ---------------------------------------------------------------------------

create function public.delete_empty_household()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.households h
  where h.id = old.household_id
    and not exists (
      select 1 from public.household_members m where m.household_id = old.household_id
    );
  return null;
end;
$$;

revoke execute on function public.delete_empty_household() from public, anon, authenticated;

create trigger household_members_delete_empty_household
  after delete on public.household_members
  for each row execute function public.delete_empty_household();

-- ---------------------------------------------------------------------------
-- F3: the weight cannot be measured before the child was born.
-- "Not in the future" stays in the app: CHECK cannot depend on the current date.
-- ---------------------------------------------------------------------------

alter table public.children
  add constraint children_weight_measured_after_birth check (weight_measured_at >= birth_date);

-- ---------------------------------------------------------------------------
-- F6: grants say what the policies allow. Supabase grants every privilege on new
-- public tables to anon and authenticated by default; RLS blocked the rest, but
-- the intent now lives in the grants too.
-- ---------------------------------------------------------------------------

revoke all on public.households, public.household_members, public.children from anon;
revoke all on public.households, public.household_members, public.children from authenticated;

-- Households and memberships are written only through create_household().
grant select on public.households, public.household_members to authenticated;

-- Children: read, add with data columns only, update the current weight only.
grant select on public.children to authenticated;
grant insert (household_id, display_name, birth_date, weight_kg, weight_measured_at) on public.children to authenticated;
grant update (weight_kg, weight_measured_at) on public.children to authenticated;
