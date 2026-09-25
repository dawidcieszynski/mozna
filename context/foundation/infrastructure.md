---
project: mozna
researched_at: 2026-09-16
recommended_platform: Cloudflare Workers
runner_up: Fly.io
context_type: mvp
tech_stack:
  language: TypeScript
  framework: Astro + React
  runtime: Cloudflare Workers (workerd) + Supabase
interview:
  persistent_connections: yes
  cost_vs_dx: balanced
  prior_familiarity: none
  geography: single-region
  colocated_services: external-ok
---

## Recommendation

**Deploy on Cloudflare Workers.**

Astro + React + TypeScript already ships with `@astrojs/cloudflare` and `wrangler.jsonc` targeting Workers Static Assets (not Pages). Interview required durable server-side connections: Durable Objects + WebSockets are GA on Workers, while Netlify and Vercel were hard-filtered. External Supabase fits the “external providers OK” answer; free-tier request volume covers medium household MVP scale. Fly.io scored highest for literal always-on processes; anti-bias on Fly surfaced stack-rewire cost and PRD/realtime mismatch, so the final choice is Cloudflare Workers with Fly as runner-up.

## Platform Comparison

| Platform | CLI-first | Managed/Serverless | Agent-readable docs | Stable deploy API | MCP / Integration | Notes |
|---|---|---|---|---|---|---|
| Cloudflare Workers | Pass | Pass | Pass | Pass | Pass | WebSockets via Durable Objects (GA); no traditional always-on daemon; Astro → Workers, not Pages |
| Vercel | — | — | — | — | — | **Hard-filtered** — no always-on process; WebSockets Public Beta with `maxDuration` caps (checked 2026-09-16) |
| Netlify | — | — | — | — | — | **Hard-filtered** — no long-lived WebSocket / persistent process |
| Fly.io | Pass | Pass | Pass | Pass | Partial | True Machines + WebSockets (GA); `fly mcp server` wraps CLI; remote MCP-on-Machine beta; pay-after-trial |
| Railway | Partial | Pass | Pass | Pass | Pass | Persistent + WebSockets (GA); arbitrary rollback is dashboard-only; remote MCP in public testing |
| Render | Partial | Pass | Pass | Pass | Pass | WebSockets GA; free web spins down (~1 min cold start — bad for night gate); no CLI rollback |

Soft weights: Q1 persistent connections boosted container PaaS (Fly/Railway/Render); single-region removed Cloudflare edge premium; external providers OK removed co-located-DB premium; cost≈DX left scoring criteria-led. Initial shortlist ranked Fly → Cloudflare → Railway; user selected Cloudflare after anti-bias on Fly.

### Shortlisted Platforms

#### 1. Cloudflare Workers (Recommended)

Best agent surface (`wrangler`, `llms.txt`, MCP), free tier fits 10k–100k req/mo, and the repo is already Workers-shaped (`main: "@astrojs/cloudflare/entrypoints/server"`, `nodejs_compat`, assets → `./dist`). Durable Objects provide GA WebSockets/hibernation when persistent connections are required. Gap vs Fly: no traditional always-on OS process.

#### 2. Fly.io (Runner-up)

Won the raw score for true persistent Machines + WebSockets and complete CLI deploy/logs. Lost the final choice after anti-bias: no permanent free tier, default dual-Machine HA cost, image-based rollback caveats, and departure from the already-scaffolded Cloudflare adapter path — plus PRD/stack flags (`has_realtime: false`, `has_background_jobs: false`) make always-on overkill for the gate MVP.

#### 3. Railway

Strong solo DX and always-on services with WebSockets; weaker CLI rollback and usage-based cost after Hobby credits. Kept as a solid escape hatch if Cloudflare’s process model cannot express a future always-on worker.

## Anti-Bias Cross-Check: Cloudflare Workers

### Devil's Advocate — Weaknesses

1. **No traditional always-on process** — Workers are invocation-scoped; “persistent” means Durable Objects (+ hibernation), not a daemon. If the product needs a long-running Node worker outside DO, this choice fails the interview literally.
2. **Pages vs Workers drift** — `tech-stack.md` still says `deployment_target: cloudflare-pages`, while Astro’s Cloudflare adapter no longer supports Pages and this repo already uses Workers Static Assets. Following the hint blindly burns calendar time.
3. **`nodejs_compat` / workerd footguns** — Astro SSR on workerd can return HTTP 200 with empty/garbage bodies when Node-compat flags disagree with the adapter; night-gate “looks healthy in logs” while users see blank pages.
4. **Deploy disconnects WebSockets** — every Worker deploy drops DO WebSocket clients; caregivers mid-session need reconnect/retry UX.
5. **Supabase is off-platform** — edge Worker → remote Postgres latency and auth cookie/session wiring dominate the ~1s night-gate budget; wrong Supabase region or cold DB path looks like a Cloudflare failure.

### Pre-Mortem — How This Could Fail

The team treated “Cloudflare” as interchangeable with Pages, shipped the first preview on a Pages project, then discovered the Astro adapter no longer supports that path and spent a week migrating secrets, preview URLs, and GitHub Actions. Meanwhile someone cached “last dose” in KV for speed; eventual consistency (~60s) produced a false allow for a second caregiver. Durable Objects were added late for “realtime” the PRD never needed, raising complexity and billables. A compatibility-flag tweak after an Astro minor upgrade made production return 200 with empty HTML at 03:00; `wrangler tail` showed success. Trust collapsed, and the household fell back to a paper log — the MVP’s shared-state promise broken by platform assumptions, not by the gate algorithm.

### Unknown Unknowns

- **Repo vs hint:** scaffold already targets Workers (`wrangler.jsonc` + `@astrojs/cloudflare` ^14 + Astro ^7); do not run Pages-specific deploy/docs flows.
- **`astro dev` ≈ production runtime** on current adapter versions (Cloudflare Vite plugin / workerd) — a separate `wrangler dev` loop is usually redundant for day-to-day UI work; treat version drift as a regression risk.
- **`main` entrypoint:** use `@astrojs/cloudflare/entrypoints/server` (Astro 6+/adapter v13+). Generic Cloudflare tutorials that point at `dist/_worker.js/index.js` are stale for this repo.
- **Interview vs product flags:** `tech-stack.md` has `has_realtime: false` and `has_background_jobs: false`, yet the interview answered “persistent connections: yes”. Prefer request/response + Supabase for the gate unless a concrete WS/DO requirement appears.
- **Per-environment builds:** on current Astro+adapter, use `CLOUDFLARE_ENV=… astro build && wrangler deploy` — do not assume one build then `wrangler deploy --env`.
- **Sessions via Workers KV** (adapter default) are eventually consistent — do not put dosing-critical “last administration” truth in KV; keep it in Supabase Postgres.

## Operational Story

How the chosen platform actually operates day to day. One concrete answer per line — not a category.

- **Preview deploys**: Prefer Workers Builds or GitHub Actions running `astro build && wrangler deploy` to a non-production Worker name / Cloudflare environment (`CLOUDFLARE_ENV` + separate build per env on current Astro+adapter). Protect previews if the URL is guessable (e.g. Cloudflare Access) before any real health data exists — use synthetic data only until then.
- **Secrets**: Put `SUPABASE_URL` / `SUPABASE_KEY` (and later tokens) in Workers Secrets (`wrangler secret put`) and GitHub Actions secrets for CI; never commit `.env`. Rotate by putting a new secret value, then redeploying; humans own rotation of production secrets.
- **Rollback**: `wrangler versions list` / deployments list, then `wrangler rollback [VERSION_ID]` (Workers Versions & Deployments). Typical revert is minutes for code; **Supabase migrations do not roll back with the Worker** — treat schema changes as human-gated. Rollbacks can be blocked after Durable Object class lifecycle / binding deletions.
- **Approval**: Human required for: first production custom domain, secret rotation, Supabase project destroy/restore, billing plan changes, irreversible DO migrations. Agent may: build, deploy to preview, tail logs, list deployments, propose rollback command for human confirm on production.
- **Logs**: Read-only via `npx wrangler tail` (runtime) and Workers observability in the dashboard; CI logs from GitHub Actions. Prefer CLI/MCP over scraping the UI.

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| Persistent-connection need exceeds DO/WebSocket model | Devil's advocate / Interview | M | H | Spike DO WebSocket only if a real realtime story appears; otherwise keep gate as HTTP + Supabase; escape hatch = Fly.io |
| Pages vs Workers confusion burns the 3-week MVP | Pre-mortem / Research | H | H | Treat Workers + `wrangler` as canonical; update deploy docs/CI away from Pages; ignore `cloudflare-pages` hint when it conflicts |
| `nodejs_compat` / adapter mismatch serves empty 200s | Unknown unknowns / Research | M | H | Pin adapter+wrangler; smoke-test HTML body after each upgrade; keep `compatibility_date` explicit in `wrangler.jsonc` |
| KV eventual consistency poisons dosing truth | Pre-mortem / Unknown unknowns | M | H | Store administrations and gate inputs only in Supabase Postgres; KV only for non-critical session UX |
| Every deploy drops live WebSockets | Devil's advocate | M | M | Document reconnect; avoid WS on the critical allow/wait/block path for MVP |
| Edge Worker ↔ Supabase latency misses ~1s night budget | Devil's advocate | M | M | Place Supabase in a nearby EU region; measure gate p95 early; avoid extra Worker hops |
| Preview URLs expose household health data | Operational / PRD guardrail | L | H | Synthetic data only in previews; Access or auth-gate before production-like datasets |
| Stale tutorial `main` path breaks deploy | Unknown unknowns / Research | M | M | Keep `main: "@astrojs/cloudflare/entrypoints/server"`; ignore `dist/_worker.js` snippets from older guides |
| Fly/Railway would have been simpler for always-on workers | Research finding | L | M | Keep Fly.io as documented runner-up; revisit if background jobs become must-have |

## Getting Started

Aligned to the **current repo** (Astro `^7.3.2`, `@astrojs/cloudflare` `^14.3.1`, `wrangler` `^4.131.1`) — not generic Pages tutorials.

1. **Cloudflare login (once):** `npx wrangler login`
2. **Rename the Worker** in `wrangler.jsonc` from `10x-astro-starter` to `mozna` (or your production Worker name).
3. **Local loop:** `npm run dev` — current adapter uses the Cloudflare/workerd path via the Vite plugin; do not assume a separate Pages “dev” command or a required daily `wrangler dev`.
4. **Secrets for SSR:** `npx wrangler secret put SUPABASE_URL` and `npx wrangler secret put SUPABASE_KEY` (values only in env/secret stores; synthetic data in seeds/tests). Locally use `.env` / `.dev.vars` — never commit secrets.
5. **First deploy:** `npm run build && npx wrangler deploy` — confirm the `*.workers.dev` URL returns real HTML (not empty 200). For named Cloudflare environments use `CLOUDFLARE_ENV=<name> npm run build && npx wrangler deploy`. Add GitHub Actions auto-deploy on merge later (out of scope here; stack hint already points at Actions).

## Out of Scope

The following were not evaluated in this research:
- Docker image configuration
- CI/CD pipeline setup
- Production-scale architecture (multi-region, HA, DR)
