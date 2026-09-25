<!-- PLAN-REVIEW-REPORT -->
# Plan Review: Minimalny katalog substancji

- **Plan**: context/changes/seed-medication-catalog/plan.md
- **Mode**: Deep
- **Date**: 2026-09-25
- **Verdict**: REVISE → SOUND after triage
- **Findings**: 2 critical, 2 warnings, 1 observation

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS |
| Lean Execution | PASS |
| Architectural Fitness | WARNING |
| Blind Spots | FAIL |
| Plan Completeness | WARNING |

## Grounding
5/5 paths ✓, extensions: pgtap ✓, btree_gist available (not installed) — brief↔plan ✓

## Findings

### F1 — Luki między pasmami masy

- **Severity**: ❌ CRITICAL
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Blind Spots
- **Location**: Faza 1 (product_dose_bands) + Faza 2
- **Detail**: Pasma Forte „od 5 kg”, „7–9 kg”, „10–15 kg” zapisane dosłownie zostawiają masy bez pasma (np. 9,4 kg); bramka musiałaby zgadywać.
- **Fix A ⭐ Recommended**: Pasma ciągłe `[min, min następnego)`, masa w luce → niższe pasmo; zawężenie oznaczone w verification.md.
- **Fix B**: Masa w luce → block.
- **Decision**: FIXED via Fix A

### F2 — „Koniec ostrożniejszy” dla limitu dobowego zaprzecza tabeli

- **Severity**: ❌ CRITICAL
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Blind Spots
- **Location**: Implementation Approach — zasady danych
- **Detail**: 20 mg/kg/dobę (dolny koniec 20–30) wyklucza trzecią dawkę z pasma 10–15 kg (100 mg × 3 = 30 mg/kg).
- **Fix**: Sufit = górna wartość ChPL; zakresy schematu = koniec ostrożniejszy; test spójności `dose_mg × max_doses_24h ≤ max_mg_per_kg_24h × weight_min_kg`.
- **Decision**: FIXED

### F3 — Warunkowe „btree_gist, jeśli dostępne”

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Architectural Fitness
- **Location**: Faza 1 — product_dose_bands
- **Fix**: `create extension if not exists btree_gist with schema extensions` + EXCLUDE na (product_id =, numrange '[)' &&).
- **Decision**: FIXED

### F4 — Warianty Forte: jeden produkt czy dwa?

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Faza 1 (products.chpl_url), Faza 4 (4.4)
- **Fix**: Jeden wiersz products na ChPL; faza 2 ustala warianty; 4.4 według verification.md.
- **Decision**: FIXED

### F5 — Niejasne kryterium 2.1

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Faza 2 — Success Criteria
- **Fix**: Skrypt porównujący `information_schema.columns` z polami w verification.md.
- **Decision**: FIXED
