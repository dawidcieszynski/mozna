---
project: mozna
deployed_at: 2026-09-25
platform: Cloudflare Workers
worker_name: mozna
url: https://mozna.cieszy-ski.workers.dev
current_version_id: 259cf1b7-4257-4ec2-b1a0-779b965bd433
source: context/foundation/infrastructure.md, context/foundation/tech-stack.md
---

# Deploy plan — pierwsze wdrożenie

Zatwierdzony w Plan Mode 2026-09-25. Źródło prawdy dla „co jest już wdrożone”.

## Co jest wdrożone

| Element | Stan |
|---|---|
| Worker | `mozna` na Cloudflare Workers (Workers Static Assets, **nie Pages**) |
| URL | `https://mozna.cieszy-ski.workers.dev` |
| Preview URLs | wyłączone (`preview_urls: false`) — ryzyko ekspozycji danych z rejestru |
| Bindingi | `ASSETS`, `IMAGES` (bez KV — `session: false` w `astro.config.mjs`) |
| Secrety Workera | `SUPABASE_URL`, `SUPABASE_KEY` (publishable key; nigdy `secret`/`service_role`) |
| Supabase | hostowany projekt `mozna`, Central EU (Frankfurt); migracje: `20260925165142_household_and_children`, `20260925200500_household_hardening`, `20260925212010_medication_catalog`, `20260926073557_medication_catalog_seed`, `20260926120000_medication_catalog_hardening` (`supabase db push`) |
| Auth Cloudflare | Account API Token z szablonu „Edit Cloudflare Workers”, jedno konto, w lokalnym `.env` (gitignored) |

## Zmiany w repo

- `wrangler.jsonc`: `name: "mozna"`, `preview_urls: false`.
- `astro.config.mjs`: `session: false` — aplikacja używa cookies `@supabase/ssr`, nie Astro Sessions; brak KV usuwa ryzyko eventual consistency.
- `context/foundation/tech-stack.md`: `deployment_target: cloudflare-workers`.

## Kroki

Ręczne (człowiek): projekt Supabase EU, subdomena `workers.dev` (`cieszy-ski`), scoped API token + account ID w `.env`, Site URL / Redirect URLs w Supabase Auth.

Agent:
1. `npm run lint`, `npx astro check`, `npm run build`, `npx wrangler deploy --dry-run`.
2. `npx wrangler whoami` → token z `CLOUDFLARE_API_TOKEN`.
3. `npm run build && npx wrangler deploy`.
4. `npx wrangler secret put SUPABASE_URL` / `SUPABASE_KEY` (wartości przekazane z `.env` przez stdin, nie wypisywane).
5. Redeploy po `preview_urls: false`.

## Weryfikacja (read-only, 2026-09-25)

| Sprawdzenie | Wynik |
|---|---|
| `GET /` | 200, niepusty HTML |
| `GET /dashboard` (anonim) | 302 → `/auth/signin` |
| `GET /auth/signin` | 200, niepusty HTML |
| `POST /api/auth/signin` złe dane, nieistniejące konto | 302 `?error=Invalid login credentials` — Worker ↔ Supabase działa |

Pełny smoke auth (`npm run smoke`, zakłada konto) **nie** jest uruchamiany na produkcji — hostowany Supabase wymaga potwierdzenia e-mail i ma limit SMTP. Zostaje w CI na lokalnym Supabase.

## Historia wdrożeń

| Data | Worker version | Zmiana | Migracja | Weryfikacja |
|---|---|---|---|---|
| 2026-09-25 | 45f8c663 | pierwsze wdrożenie (szkielet auth) | — | read-only, patrz wyżej |
| 2026-09-25 | 210b8ab6 | `household-with-child` (S-01): gospodarstwo, dzieci, RLS | `20260925165142_household_and_children` | anonim → `/auth/signin` na chronionych trasach; schemat prod: RLS na 3 tabelach, 5 polityk, 0 DELETE, UPDATE dzieci tylko waga; przepływ zalogowanego (gospodarstwo, syntetyczne dziecko, aktualizacja wagi) potwierdzony ręcznie przez człowieka |
| 2026-09-25 | 259cf1b7 | poprawki z przeglądu `household-with-child` (F1 waga, F2/F3/F6 baza) | `20260925200500_household_hardening` | anonim → `/auth/signin`; schemat prod: trigger `household_members_delete_empty_household`, CHECK `children_weight_measured_after_birth`, anon bez grantów, authenticated: SELECT + INSERT kolumn danych + UPDATE wagi |
| 2026-09-26 | 259cf1b7 (bez zmian) | `seed-medication-catalog` (F-01): katalog tylko do odczytu | `20260925212010_medication_catalog`, `20260926073557_medication_catalog_seed` | 4 migracje zdalnie; 5 tabel katalogu z RLS i SELECT tylko dla authenticated; anon przez REST → 401/42501; dane: 3 produkty, 12 pasm, 9 GTIN-ów zgodnie z `verification.md` (zrzut tylko tabel katalogu, usunięty) |
| 2026-09-26 | 259cf1b7 (bez zmian) | poprawki z przeglądu `seed-medication-catalog` (F1, F3) | `20260926120000_medication_catalog_hardening` | `db push` wykonany przez agenta na wyraźne polecenie człowieka, po zielonym CI i dry-run; schemat prod: 5 nowych CHECK-ów (dawka per kg w sufitcie, dawka > 0, wagi 0–150 kg, odstęp 1–24 h) |

Kolejność przy zmianach schematu: **najpierw `supabase db push` (człowiek), potem `wrangler deploy`** — middleware odpytuje tabele gospodarstwa przy każdym żądaniu zalogowanego użytkownika.

## Operacje

- Deploy: `npm run build && npx wrangler deploy`
- Logi: `npx wrangler tail`
- Wersje: `npx wrangler versions list`
- Rollback (człowiek potwierdza): `npx wrangler rollback <VERSION_ID>` — nie cofa migracji Supabase.
- Rotacja secretów: człowiek, `wrangler secret put` + weryfikacja.

## Odłożone

- GitHub remote + Actions auto-deploy on merge (hint z `tech-stack.md`).
- Osobne środowisko preview (`CLOUDFLARE_ENV`), Cloudflare Access.
- Custom domain.
- Migracje Supabase (schemat domeny), RLS.
