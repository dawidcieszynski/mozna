---
bootstrapped_at: 2026-09-16T12:46:46Z
starter_id: 10x-astro-starter
starter_name: "10x Astro Starter (Astro + Supabase + Cloudflare)"
project_name: mozna
language_family: js
package_manager: npm
cwd_strategy: git-clone
bootstrapper_confidence: first-class
phase_3_status: ok
audit_command: "npm audit --json"
---

## Hand-off

```yaml
starter_id: 10x-astro-starter
package_manager: npm
project_name: mozna
hints:
  language_family: js
  team_size: solo
  deployment_target: cloudflare-pages
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: first-class
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
```

### Why this stack

Web-app MVP („Można?") with a 3-week timeline, medium household scale, and must-have login-scoped household membership. Auth + Postgres + edge deploy ship in the recommended JS default (Astro + React + TypeScript + Supabase + Cloudflare); that matches the night-time shared-log flow without adding payments, AI, realtime, or background jobs. Standard path accepted the vetted `(web, js)` pick; scaffolding confidence is first-class. Deploy to Cloudflare Pages; CI on GitHub Actions with auto-deploy on merge to main.

## Pre-scaffold verification

| Signal             | Value                                                              | Severity | Notes                                                                 |
| ------------------ | ------------------------------------------------------------------ | -------- | --------------------------------------------------------------------- |
| npm package        | not run                                                            | —        | cmd_template starts with `git clone`; npm package check skipped       |
| GitHub repo        | przeprogramowani/10x-astro-starter last pushed 2026-09-12T19:16:08Z | fresh    | via GitHub REST API (`gh` CLI unavailable); docs_url from registry card |

## Scaffold log

**Resolved invocation**: `git clone https://github.com/przeprogramowani/10x-astro-starter .bootstrap-scaffold && cd .bootstrap-scaffold && npm install`
**Strategy**: git-clone
**Exit code**: 0
**Files moved**: 30832
**Conflicts (.scaffold siblings)**: CLAUDE.md
**`.gitignore` handling**: append-merged
**.bootstrap-scaffold cleanup**: deleted (retry after Windows file-lock on nested `node_modules` remnant)

Notes:
- Upstream `.git/` removed before move-up so starter history did not leak into cwd.
- cwd already had `.git/`; existing wins.
- `context/` preserved (scaffold `context/**` dropped if any).
- npm install reported `found 0 vulnerabilities` and one EBADENGINE warning (`sitemap@9.0.1` wants npm `>=10.8.2`; local npm was `10.2.5` on Node `v24.18.1`).

## Post-scaffold audit

**Tool**: npm audit --json
**Summary**: 0 CRITICAL, 0 HIGH, 0 MODERATE, 0 LOW
**Direct vs transitive**: not distinguished (empty vulnerability set); dependency metadata: prod 377 / dev 269 / optional 167 / total 804

#### CRITICAL findings

none

#### HIGH findings

none

#### MODERATE findings

none

#### LOW / INFO findings

none

## Hints recorded but not acted on

| Hint                       | Value                              |
| -------------------------- | ---------------------------------- |
| bootstrapper_confidence    | first-class                        |
| quality_override           | false                              |
| path_taken                 | standard                           |
| self_check_answers         | null                               |
| team_size                  | solo                               |
| deployment_target          | cloudflare-pages                   |
| ci_provider                | github-actions                     |
| ci_default_flow            | auto-deploy-on-merge               |
| has_auth                   | true                               |
| has_payments               | false                              |
| has_realtime               | false                              |
| has_ai                     | false                              |
| has_background_jobs        | false                              |

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `git init` (if you have not already) to start your own repo history.
- Review any `.scaffold` siblings the conflict policy created and decide which version of each file to keep.
- Address audit findings per your project's risk tolerance — the full breakdown is in this log.
