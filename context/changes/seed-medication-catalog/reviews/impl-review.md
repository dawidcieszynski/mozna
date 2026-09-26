<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Minimalny katalog substancji

- **Plan**: context/changes/seed-medication-catalog/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3, 4
- **Date**: 2026-09-26
- **Verdict**: NEEDS ATTENTION → APPROVED after triage (6 fixed, 1 deferred, 3 accepted)
- **Findings**: 0 critical, 4 warnings, 6 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | WARNING |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | PASS |

Automated re-run 2026-09-26: `npx supabase db reset` 4 migrations clean, `npx supabase test db` 78/78 PASS, `npm run lint` PASS. Independent cross-check of the seed against `verification.md`: 0 mismatches across 194 values (incl. warning texts byte-for-byte, 9 GTINs, all approval decisions Z1–Z7, N1, D5; D2 correctly without data change).

## Findings

### F1 — Brak wiersza-CHECK sufitu dla reguły per_kg

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925212010_medication_catalog.sql:31
- **Detail**: `dose_mg_per_kg` nie ma `> 0` ani ograniczenia `dose_mg_per_kg * max_doses_24h <= max_mg_per_kg_24h`; test pokrywa sufit tylko dla pasm. Dziś Panadol spełnia (15 × 4 = 60), ale literówka w przyszłej korekcie przeszłaby do bazy — najtańsza ochrona przed fałszywym allow.
- **Fix**: Nowa migracja: CHECK `dose_mg_per_kg > 0` i `dose_mg_per_kg is null or dose_mg_per_kg * max_doses_24h <= max_mg_per_kg_24h`; asercje w teście schematu.
- **Decision**: FIXED — CHECK `products_dose_per_kg_positive`, `products_per_kg_within_daily_ceiling` w `20260926120000_medication_catalog_hardening.sql`; asercje w teście schematu

### F2 — Dwa źródła „maks. dawek na dobę” dla ibuprofenu

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925212010_medication_catalog.sql:54 vs :32
- **Detail**: `product_dose_bands.max_doses_24h` i `products.max_doses_24h` są niezależne; nic nie wymusza pasmo ≤ produkt i nie jest ustalone, które czyta bramka.
- **Fix**: Test danych: każde pasmo `max_doses_24h <= products.max_doses_24h`; w notatkach S-02: dla `weight_band` bramka stosuje minimum z obu.
  - Strength: Oba źródła zostają (wierne ChPL), a bramka nie może wybrać wyższego.
  - Tradeoff: Reguła „min z dwóch” żyje w S-02, nie w bazie (międzytabelowa).
  - Confidence: HIGH — dziś obie wartości to 3.
  - Blind spot: Przyszłe produkty z pasmami o różnych limitach.
- **Decision**: FIXED — test danych „no band allows more doses per 24 h than its product”; notatka S-02: dla `weight_band` bramka stosuje minimum z obu wartości

### F3 — Brak granic liczbowych (niezgodne ze wzorcem gospodarstwa)

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: supabase/migrations/20260925212010_medication_catalog.sql:16, 35-36, 51-52
- **Detail**: `min_weight_kg`/`weight_min_kg` bez `>= 0`; `min_interval_hours` tylko `> 0` (groźna literówka to np. 0.4). Tabele gospodarstwa mają granice (`weight_kg between 0.5 and 150`).
- **Fix**: W tej samej nowej migracji: wagi `>= 0` i `<= 150`, `min_interval_hours between 1 and 24`; asercje w teście.
- **Decision**: FIXED — CHECK wag 0–150 kg (produkty, pasma) i `min_interval_hours between 1 and 24` w `20260926120000_medication_catalog_hardening.sql`

### F4 — Ostrzeżenia 2..n bez podwójnego zapisu

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Adherence
- **Location**: supabase/tests/medication_catalog_data.test.sql:84-113
- **Detail**: Test sprawdza tylko liczbę i pierwszy element `warnings`; literówka lub zmiana kolejności w elementach 2–4 (Panadol) i 2–10 (Forte) przeszłaby. Plan wymagał każdej wartości. (Ręcznie: 0 różnic.)
- **Fix**: `is(warnings, array[...])` z pełnymi tablicami przepisanymi z verification.md dla 3 produktów.
- **Decision**: FIXED — pełne tablice `warnings` przepisane z verification.md w teście danych

### F5 — Masa równa max_weight_kg poza pasmem

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925212010_medication_catalog.sql:59
- **Detail**: Pasma `[)`, więc 40,0 kg nie trafia w pasmo — bezpieczne tylko, jeśli bramka traktuje brak pasma jako block. Już rozstrzygnięte jako D2 (notatki S-02: granica produktu włączna).
- **Fix**: Bez zmian w F-01; S-02 przypina zachowanie testem.
- **Decision**: ACCEPTED — rozstrzygnięte jako D2 w notatkach S-02

### F6 — Luki w teście schematu

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: supabase/tests/medication_catalog_schema.test.sql
- **Detail**: Brak asercji: TRUNCATE dla authenticated (jest w household_hardening), odwrotny kierunek `products_dose_per_kg_matches_rule` (weight_band z dawką), `products_weight_range`, `product_dose_bands_weight_range`, `dose_mg > 0`; odczyt authenticated sprawdzony tylko na `products`.
- **Fix**: Dopisać te asercje razem z F1/F3.
- **Decision**: FIXED — asercje TRUNCATE, weight_band z dawką, zakresy wag, dose_mg 0 w teście schematu

### F7 — Korekta katalogu zmienia znaczenie historii podań

- **Severity**: OBSERVATION
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Architecture
- **Location**: N/A (dotyczy S-03)
- **Detail**: Korekta wartości w miejscu (`update`) po cichu zmienia sens podań, które odwołują się do produktu.
- **Fix**: Notatka dla S-03: zapis podania przechowuje migawkę (produkt, dawka mg, masa użyta do dawki, reguła/pasmo, `checked_at` katalogu).
  - Strength: Historia podań pozostaje prawdziwa po korekcie katalogu.
  - Tradeoff: Kilka kolumn więcej w podaniu.
  - Confidence: HIGH.
  - Blind spot: Jeszcze nie ma schematu podań.
- **Decision**: DEFERRED — notatka dla S-03 w `context/changes/gate-from-popular-list/change.md`

### F8 — Plik spoza zmiany w commicie fazy 2

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Scope Discipline
- **Location**: commit 6e22585 (`context/changes/gate-from-popular-list/change.md`)
- **Detail**: Notatka D2 dla S-02 weszła do commitu fazy 2 F-01 — świadomie, ale poza zbiorem plików zmiany.
- **Fix**: Zaakceptować; kolejne notatki dla innych zmian commitować osobno.
- **Decision**: ACCEPTED — kolejne notatki dla innych zmian commitowane osobno

### F9 — Test „nieznany GTIN” jest tautologiczny

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: supabase/tests/medication_catalog_data.test.sql:215
- **Detail**: GTIN `05900000000000` nigdy nie był wstawiony, więc test zawsze przechodzi; dokumentuje kontrakt, ale niczego nie chroni.
- **Fix**: Zaakceptować jako dokumentację kontraktu; prawdziwy test „nieznany GTIN → brak rekomendacji” należy do S-05.
- **Decision**: ACCEPTED — dokumentacja kontraktu; realny test w S-05

### F10 — deploy-plan zgubił datę przy wierszu Supabase

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: context/deployment/deploy-plan.md:24
- **Detail**: Wiersz „Supabase” stracił adnotację daty wdrożenia migracji (commit e4a4e6a); daty są w „Historia wdrożeń”.
- **Fix**: Pominąć — historia wdrożeń ma daty.
- **Decision**: ACCEPTED — daty w „Historia wdrożeń”
