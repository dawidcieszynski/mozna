---
project: "Można?"
context_type: greenfield
created: 2026-09-15
updated: 2026-09-15
checkpoint:
  current_phase: 1
  phases_completed: []
  gray_areas_resolved:
    - topic: context_type
      decision: greenfield (override — repo has only workflow scaffold, no product code)
  frs_drafted: 0
  quality_check_status: pending
---

# Shape notes — Można?

Seed (from project brief, verbatim intent):

> wspólny dla całego domu log podawania leków dziecku, z deterministyczną bramką odpowiadającą na pytanie „czy mogę podać teraz i ile".

## Forward: tech-stack

(Captured from brief for later chain steps — not PRD content.)
User prefers course-aligned stack; dosing logic must stay deterministic (no LLM on critical path). Offline-sync deferred as later architecture evolution.
