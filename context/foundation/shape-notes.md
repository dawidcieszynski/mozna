---
project: "Można?"
context_type: greenfield
created: 2026-09-15
updated: 2026-09-15
timeline_budget:
  mvp_weeks: 3
  hard_deadline: null
  after_hours_only: null
checkpoint:
  current_phase: 5
  phases_completed: [1, 2, 3, 4]
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
      decision: child → identify med (barcode or popular list) → gate/dose → log; second caregiver sees history or wait-until; ~3 weeks after-hours; AI photo-scan deferred
    - topic: FR-005 socrates
      decision: gate/dose requires child weight and age; without them no allow/dose
    - topic: FR-008 socrates
      decision: MVP is shared in-app visibility only; push notifications deferred (non-goal for v1)
  frs_drafted: 8
  quality_check_status: pending
---

# Shape notes — Można?

Seed (from project brief, verbatim intent):

> wspólny dla całego domu log podawania leków dziecku, z deterministyczną bramką odpowiadającą na pytanie „czy mogę podać teraz i ile".

## Vision & Problem Statement

O 3:00 dziecko ma gorączkę. Ostatnią dawkę podał ktoś inny w domu — nie wiadomo kiedy i czego. Opiekun stoi przed decyzją „czy mogę podać teraz i ile" bez wspólnego stanu.

Kalkulatorów dawkowania są setki; brakuje wspólnego logu domu. Różnicownik: mama, tata i babcia widzą to samo — historię podań i odpowiedź bramki w jednym miejscu.

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
- FR-002: Caregiver can add and select a child (patient) in the household. Priority: must-have

### Medication identification
- FR-003: Caregiver can identify a medication by barcode. Priority: must-have
- FR-004: Caregiver can select a medication from a popular list. Priority: must-have

### Gate, dose & log
- FR-005: Caregiver can see the gate answer and dose for a selected child and medication. Priority: must-have
- FR-006: Caregiver can record an administration. Priority: must-have
- FR-007: Caregiver can view administration history in the household. Priority: must-have
- FR-008: A second caregiver in the same household can see that a dose was given and/or when the next dose is allowed. Priority: must-have

## User Stories

### US-01: Night dose across two caregivers
**Given** two caregivers belong to the same household and a child and seeded popular medications exist  
**When** caregiver A selects the child, identifies a medication (barcode or list), sees the gate/dose, and records an administration  
**Then** caregiver B, identifying the same medication for that child, sees that a dose was given and/or when the next dose is allowed

## Forward: tech-stack

(Captured from brief for later chain steps — not PRD content.)
User prefers course-aligned stack; dosing logic must stay deterministic (no LLM on critical path). MVP medication identification = barcode and/or popular list; AI packaging photo-scan deferred. Offline-sync deferred as later architecture evolution.
