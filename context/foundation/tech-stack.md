---
starter_id: 10x-astro-starter
package_manager: npm
project_name: mozna
hints:
  language_family: js
  team_size: solo
  deployment_target: cloudflare-workers
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
---

## Why this stack

Web-app MVP („Można?") with a 3-week timeline, medium household scale, and must-have login-scoped household membership. Auth + Postgres + edge deploy ship in the recommended JS default (Astro + React + TypeScript + Supabase + Cloudflare); that matches the night-time shared-log flow without adding payments, AI, realtime, or background jobs. Standard path accepted the vetted `(web, js)` pick; scaffolding confidence is first-class. Deploy to Cloudflare Workers; CI on GitHub Actions with auto-deploy on merge to main.
