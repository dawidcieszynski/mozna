---
project: "Można?"
context_type: greenfield
created: 2026-09-15
updated: 2026-09-15
checkpoint:
  current_phase: 3
  phases_completed: [1, 2]
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
  frs_drafted: 0
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

## Forward: tech-stack

(Captured from brief for later chain steps — not PRD content.)
User prefers course-aligned stack; dosing logic must stay deterministic (no LLM on critical path). Offline-sync deferred as later architecture evolution.
