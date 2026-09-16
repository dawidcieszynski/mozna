---
project: "Można?"
context_type: greenfield
created: 2026-09-15
updated: 2026-09-15
timeline_budget:
  mvp_weeks: 3
  hard_deadline: 2026-11-04
  after_hours_only: false
product_type: web-app
target_scale:
  users: medium
  qps: null
  data_volume: null
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved:
    - topic: context_type
      decision: greenfield (override — repo has only workflow scaffold, no product code)
    - topic: pain category
      decision: missing feature — no shared household medication state
    - topic: insight
      decision: dosing calculators exist; they do not hold shared household history
    - topic: primary persona scope
      decision: caregivers across many households (same role)
    - topic: access model
      decision: login required; flat household membership — all members see the same data
    - topic: mvp first flow
      decision: child → identify med (barcode or popular list) → gate/dose → log; second caregiver sees history or wait-until; ~3 weeks, mixed schedule (part after-hours, part alongside day work, in parallel); AI photo-scan deferred
    - topic: FR-005 socrates
      decision: gate/dose requires child weight and age; without them no allow/dose
    - topic: FR-008 socrates
      decision: MVP is shared in-app visibility only; push notifications deferred (non-goal for v1)
  frs_drafted: 8
  quality_check_status: accepted
---

# Shape notes — Można?

Seed (from project brief, verbatim intent):

> wspólny dla całego domu log podawania leków dziecku, z deterministyczną bramką odpowiadającą na pytanie „czy mogę podać teraz i ile".

## Vision & Problem Statement

O 3:00 dziecko ma gorączkę. Ostatnią dawkę podał ktoś inny w domu — nie wiadomo kiedy i czego. Opiekun stoi przed decyzją „czy mogę podać teraz i ile" bez wspólnego stanu.

Kalkulatorów dawkowania są setki; brakuje wspólnego logu domu. Różnicownik: mama, tata i babcia widzą to samo — historię podań i odpowiedź bramki w jednym miejscu.

Scale note: at ~100× users the domain gate rule stays the same; pressure would be operational (performance, tenancy), not a change to allow/wait/block logic.

## User & Persona

**Primary:** opiekun małego dziecka w gospodarstwie domowym (rodzic, babcia/dziadek lub inna osoba podająca leki). Sięga po produkt w momencie decyzji o podaniu — często w nocy, pod stresem, gdy inna osoba mogła już podać dawkę.

## Access Control

Login required (account per caregiver). Access is scoped to a household: members of the same household share patients, products, and administration history. Membership is flat for MVP — no admin/member/guest split; every household member sees the same data. That shared visibility is the product point (e.g. grandma sees that dad already gave a dose).

## Success Criteria

### Primary
- Two caregivers in one household complete: select child → identify medication (barcode or popular list) → see gate answer and dose → log administration; the second caregiver sees that a dose was given and/or when the next dose is allowed.

### Secondary
- The seeded popular-medication list covers a typical night without caregivers having to author dosing rules from scratch.

### Guardrails
- The gate never returns allow when an interval or daily limit has not elapsed (false allow is a regression).
- Health data (child identity, weight, allergies, administration history) does not leak outside the household; seeds, fixtures, and tests use synthetic data only.

## Functional Requirements

### Household & access
- FR-001: Caregiver can log in and belong to a household. Priority: must-have
  > Socrates: Counter-argument considered: local-only account / household onboarding friction at night. Resolution: kept; shared household state requires login-scoped membership.
- FR-002: Caregiver can add and select a child (patient) in the household, including weight and age needed for dosing. Priority: must-have
  > Socrates: Counter-argument considered: hardcode one child / skip profile edit. Resolution: kept; weight and age are required inputs for the gate (see FR-005).

### Medication identification
- FR-003: Caregiver can identify a medication by barcode. Priority: must-have
  > Socrates: Counter-argument considered: list-only for v1 / empty barcode promise without EAN data. Resolution: kept as parallel path with FR-004; seeded mappings required for popular meds.
- FR-004: Caregiver can select a medication from a popular list. Priority: must-have
  > Socrates: Counter-argument considered: list useless without seeded rules / list maintenance cost. Resolution: kept; Secondary success criterion covers seed coverage for a typical night.

### Gate, dose & log
- FR-005: Caregiver can see the gate answer and dose for a selected child and medication. Without usable weight and age, the product must not return allow or a dose. Priority: must-have
  > Socrates: Counter-argument considered: "dose without weight/age is dangerous." Resolution: kept and tightened — weight and age are mandatory inputs; otherwise block / no dose.
- FR-006: Caregiver can record an administration. Priority: must-have
  > Socrates: Counter-argument considered: history view without explicit log / edit-delete safety hole. Resolution: kept; recording the dose is the shared-state write; edit/delete policy left for later if needed.
- FR-007: Caregiver can view administration history in the household. Priority: must-have
  > Socrates: Counter-argument considered: last dose only / noisy full history at night. Resolution: kept; MVP can emphasize last dose while history remains available.
- FR-008: A second caregiver in the same household can see in the app that a dose was given and/or when the next dose is allowed. Priority: must-have
  > Socrates: Counter-argument considered: "push notification is required; view alone is not enough." Resolution: kept as in-app shared visibility for MVP; push notifications deferred (v1 non-goal).

## User Stories

### US-01: Night dose across two caregivers
**Given** two caregivers belong to the same household and a child (with weight and age) and seeded popular medications exist  
**When** caregiver A selects the child, identifies a medication (barcode or list), sees the gate/dose, and records an administration  
**Then** caregiver B, identifying the same medication for that child, sees in the app that a dose was given and/or when the next dose is allowed

## Business Logic

For a child and a medication, based on administration history and substance rules, the application answers allow / wait / block and computes a dose — or refuses when weight/age are missing.

User-visible inputs: the child (weight, age), the identified medication/substance, household administration history, and “now”.  
Output: `allow` | `wait` (with until-when) | `block` (with reasons), plus a display dose — or no dose / block when weight or age is missing.  
In the product flow: after child and medication are chosen, before recording an administration; a second caregiver sees the same gate outcome on the next attempt.

## Non-Functional Requirements

- Gate response feels fast enough for night-time use (roughly under ~1s perceived wait after child + medication are selected).
- Health data does not leave the household boundary; seeds, fixtures, and tests use synthetic data only.
- Gate behavior is deterministic: the same inputs produce the same result (no model guessing on the critical path).

## Non-Goals

- Avoid: AI packaging photo-scan / leaflet OCR in v1 — medication ID is barcode and/or popular list only (keeps the critical path free of model extraction).
- Avoid: push notifications in v1 — shared in-app visibility is enough for the MVP proof (FR-008).
- Avoid: offline-first sync and double-dose conflict resolution in v1 — online-first; offline is later architecture work.
- Avoid: end-user authoring of ChPL dosing rules — safety rules come from a seeded catalog, not a caregiver-edited rule editor.

## Quality cross-check

All greenfield checks present: Access Control, Business Logic (one-sentence rule), project artifacts, timeline-cost acknowledgment (mvp_weeks: 3), Non-Goals. Status: accepted.

## Forward: tech-stack

(Captured from brief for later chain steps — not PRD content.)
User prefers course-aligned stack; dosing logic must stay deterministic (no LLM on critical path). MVP medication identification = barcode and/or popular list; AI packaging photo-scan deferred. Offline-sync deferred as later architecture evolution.
