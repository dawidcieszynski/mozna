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

Also from S-01 review: follow-up migration may `revoke truncate` on public tables
from `authenticated` (Supabase default grant; not reachable via REST today).
- Signed-in users land on a confusing start page: `src/pages/api/auth/signin.ts:19`
  redirects to `/`, which renders the starter `Welcome.astro` with static
  Sign in / Sign up buttons (lines 30–36) regardless of session. Fix: after sign-in
  go to `/dashboard`; `/` and `/auth/signin|signup` redirect signed-in users to
  `/dashboard`; replace the starter start page. Update `scripts/smoke.mjs`
  ("signin accepts correct password" expects `/`).
