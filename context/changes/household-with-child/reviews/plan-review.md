<!-- PLAN-REVIEW-REPORT -->
# Plan Review: Gospodarstwo z dzieckiem

- **Plan**: context/changes/household-with-child/plan.md
- **Mode**: Deep
- **Date**: 2026-09-25
- **Verdict**: SOUND
- **Findings**: 0 critical, 2 warnings, 1 observation

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS |
| Lean Execution | PASS |
| Architectural Fitness | PASS |
| Blind Spots | WARNING |
| Plan Completeness | WARNING |

## Grounding
8/8 paths ✓, symbols ✓ (`astro/zod` export, `ServerError.tsx`, `[db.migrations] enabled`), brief↔plan ✓

## Findings

### F1 — Błąd zapytania o gospodarstwo wygląda jak „brak gospodarstwa”

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Blind Spots
- **Location**: Faza 2 — Middleware
- **Detail**: Kontrakt przekierowywał każdy brak wyniku na `/household/new`; błąd sieci/Supabase kierowałby opiekuna na onboarding, a zapis odbiłby się od `unique (user_id)`.
- **Fix**: Rozróżnić błąd zapytania od braku wiersza; przy błędzie `503` z prośbą o odświeżenie.
- **Decision**: FIXED

### F2 — Testy pgTAP bez włączenia rozszerzenia

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Faza 1 — Testy pgTAP
- **Fix**: `create extension if not exists pgtap with schema extensions;` na początku transakcji testu.
- **Decision**: FIXED

### F3 — Polityka UPDATE na children obejmuje wszystkie kolumny

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Blind Spots
- **Location**: Faza 1 — Migracja
- **Detail**: UI zmienia tylko wagę, ale członek gospodarstwa mógłby przez API zmienić datę urodzenia (wpływa na bramkę).
- **Fix**: Grant UPDATE zawężony do `(weight_kg, weight_measured_at)`.
- **Decision**: FIXED
