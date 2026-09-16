# Repository Guidelines

`mozna` is an Astro 7 SSR app (React 19 islands, Tailwind 4, Supabase auth) targeting Cloudflare Workers. Product and workflow contracts live in `@CLAUDE.md` and `@context/foundation/`.

## Hard Rules

- Never commit real personal or health data — seeds, fixtures, tests, and screenshots must be synthetic (`@CLAUDE.md`).
- Secrets only in `.env` / `.dev.vars` and GitHub Secrets — never in tracked files (`@.env.example`).
- Do not write under `context/archive/` — it is immutable.
- Irreversible production actions (delete DB, rotate secrets, delete cloud project) are human-only.

## Project Structure & Module Organization

- `src/pages/` — Astro routes; `src/pages/api/` — API endpoints (export `prerender = false`).
- `src/components/` — Astro and React UI; `src/components/ui/` — shadcn (“new-york”).
- `src/lib/` — helpers and services; `src/middleware.ts` — session + `PROTECTED_ROUTES`.
- `supabase/migrations/` — SQL with RLS; `scripts/smoke.mjs` — auth smoke test.
- `context/` — living PRD/stack/infra docs; edit in place per `@CLAUDE.md`.

## Build, Test, and Development Commands

- `npm run dev` — Cloudflare workerd local server.
- `npm run lint` / `npm run lint:fix` — ESLint (type-checked).
- `npm run format` — Prettier (Astro + Tailwind plugins).
- `npm run build` / `npm run preview` — production build and preview.
- `npm run smoke` — auth-flow check against a running server (`BASE_URL`, default `http://localhost:4321`).

CI on `master` push/PR runs lint, `npx astro check`, build (needs `SUPABASE_URL` / `SUPABASE_KEY` secrets), and a smoke job with local Supabase — `@.github/workflows/ci.yml`.

## Coding Style & Naming Conventions

- TypeScript; alias `@/*` → `src/*` (`@tsconfig.json`).
- Astro for layout/static content; React only for interactivity; no Next.js `"use client"`.
- Merge Tailwind classes via `cn()` from `@/lib/utils` — do not concatenate class strings.
- API routes export uppercase `GET`/`POST`; validate input with Zod.
- Migration names: `YYYYMMDDHHmmss_short_description.sql`.
- Enforced by `@eslint.config.js`, `.prettierrc.json`, and husky lint-staged (`@package.json`).

## Testing Guidelines

No unit-test runner in `@package.json`. Prefer `npm run smoke` after auth or dependency changes. Keep all fixtures synthetic.

## Commit & Pull Request Guidelines

Recent history uses short imperative subjects (occasionally `chore:`). Keep PRs focused; expect CI lint, `astro check`, and build to pass before merge.

## Security & Configuration Tips

Copy `@.env.example` to `.env` and `.dev.vars`. Use Node `v22.14.0` (`@.nvmrc`). Local Supabase needs Docker (`npx supabase start`). Deploy with `npx wrangler deploy`.
