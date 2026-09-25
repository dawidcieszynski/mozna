---
project: mozna
deployed_at: 2026-09-25
platform: Cloudflare Workers
worker_name: mozna
url: https://mozna.cieszy-ski.workers.dev
current_version_id: 45f8c663-0b33-4b5e-b5c8-1f5a7f9e9503
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
| Supabase | hostowany projekt `mozna`, Central EU (Frankfurt), bez migracji |
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
