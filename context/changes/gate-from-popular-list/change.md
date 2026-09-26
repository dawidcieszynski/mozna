---
change_id: gate-from-popular-list
title: Gate and dose for a medication picked from the popular list
status: new
created: 2026-09-25
updated: 2026-09-25
archived_at: null
---

## Notes

Roadmap S-02. Carried over from S-01 (`household-with-child`) production feedback
(user, 2026-09-25) — include in this change's UI:
- Weight update gets its own view (e.g. `/children/<id>/weight`), separate from the
  child profile. The gate should link there when the weight is missing or stale.
- Adding a child gets its own view (e.g. `/children/new`), separate from the
  children list on `/dashboard`.

Grants hardening from the S-01 review is done (`20260925200500_household_hardening.sql`);
new tables must follow it: no anon privileges, column-scoped INSERT/UPDATE.
- Signed-in users land on a confusing start page: `src/pages/api/auth/signin.ts:19`
  redirects to `/`, which renders the starter `Welcome.astro` with static
  Sign in / Sign up buttons (lines 30–36) regardless of session. Fix: after sign-in
  go to `/dashboard`; `/` and `/auth/signin|signup` redirect signed-in users to
  `/dashboard`; replace the starter start page. Update `scripts/smoke.mjs`
  ("signin accepts correct password" expects `/`).

From the S-01 implementation review (`context/changes/household-with-child/reviews/impl-review.md`):
- F5: query the household in middleware only for protected routes, onboarding and
  `/api/*` except `/api/auth/*`; today a Supabase outage returns 503 on every page
  for signed-in users, including sign-out.
- F7: align the starter auth routes with project conventions — Zod instead of
  `as string`, Polish messages, no raw Supabase `error.message`, Polish page titles.
- F8: the child view should render an error message on a Supabase read failure
  (like the dashboard) instead of a generic 500.

From F-01 verification (`context/changes/seed-medication-catalog/verification.md`, D2, user 2026-09-26):
- The product's upper weight bound is inclusive: a weight equal to
  `products.max_weight_kg` (40.0 kg Forte, 42.0 kg Panadol) uses the last band /
  the per-kg rule; only weight above it is blocked. Bands stay `[min, max)` in data.
- Show `products.warnings` (ChPL 4.2 / 4.3 / 4.4 texts) next to the gate answer;
  they never change allow/wait/block.
