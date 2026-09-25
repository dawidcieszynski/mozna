# Minimalny katalog substancji — plan implementacji

## Overview

Roadmap F-01 (`seed-medication-catalog`). W bazie powstaje katalog tylko do odczytu, z którego S-02 policzy odpowiedź bramki i dawkę, a S-05 zidentyfikuje lek po kodzie kreskowym: dwie substancje (paracetamol, ibuprofen), dwa produkty w zawiesinie doustnej, ich reguły dawkowania z ChPL, pasma dawek, kody GTIN i reguła naprzemienności. Każda liczba ma źródło (`source_url`) i datę sprawdzenia (`checked_at`) i jest zweryfikowana z PDF ChPL oraz zatwierdzona przez człowieka przed produkcją.

## Current State Analysis

- Schemat zawiera wyłącznie tabele gospodarstwa: `supabase/migrations/20260925165142_household_and_children.sql` (households, household_members, children, RLS) i `20260925200500_household_hardening.sql` (trigger sprzątający, CHECK dat, granty zawężone do polityk: `anon` bez uprawnień, `authenticated` z kolumnowymi INSERT/UPDATE).
- Brak jakichkolwiek danych o lekach w repo i bazie (`grep medication|substance` → 0).
- Testy bazy: pgTAP w `supabase/tests/` (`household_rls.test.sql`, `household_hardening.test.sql`), uruchamiane przez `npx supabase test db` lokalnie i w CI (`.github/workflows/ci.yml`, krok „Run database tests”, CLI przypięty do 2.117.0).
- Produkcja: migracje trafiają przez `supabase db push` wykonywane przez człowieka, najpierw schemat, potem deploy (`context/deployment/deploy-plan.md`).
- Research: `context/changes/seed-medication-catalog/research.md` — produkty, wartości, GTIN-y, źródła, niewiadome (data tekstu Panadolu, pasma Forte, status produktów w CSV RPL) i sekcja 6 (naprzemienność).

## Desired End State

- Tabele katalogu istnieją lokalnie i na produkcji, z danymi produktów zatwierdzonych w `verification.md` (paracetamol + zweryfikowane warianty ibuprofenu); `authenticated` może je czytać, nikt nie zapisuje przez API, `anon` nie ma dostępu.
- Każda wartość w danych ma odpowiadający wiersz w `verification.md` (wartość → cytat i strona PDF ChPL), zatwierdzony przez człowieka.
- Wyszukanie po GTIN zwraca produkt z mocą w mg/ml; nieznany GTIN zwraca brak wiersza.
- Testy pgTAP sprawdzają schemat, uprawnienia i każdą zapisaną wartość (podwójny zapis: migracja + test).

### Key Discoveries:

- `supabase/migrations/20260925200500_household_hardening.sql` — wzorzec grantów po F6: `revoke all ... from anon, authenticated`, potem minimalne granty; nowe tabele katalogu stosują ten sam wzorzec.
- `supabase/tests/household_hardening.test.sql` — wzorzec testu: `plan(n)`, `set local role`, `throws_ok` z kodem `42501`, `has_table_privilege`.
- Research §2: paracetamol dawkowany wzorem (15 mg/kg, ≥ 4 h, maks. 4 dawki i 60 mg/kg na 24 h); ibuprofen Forte dawkowany pasmami masy ze stałą dawką (np. 10–15 kg → 100 mg, 3× na dobę), 20–30 mg/kg/dobę, co 6–8 h.

## What We're NOT Doing

- Logika bramki (allow/wait/block, liczenie dawki, wieku, świeżości wagi) — S-02.
- UI katalogu, wyszukiwanie leku, lista popularnych w interfejsie — S-02; skanowanie kodów — S-05.
- Czopki i inne postacie (inne progi niż zawiesiny) — poza v1 (research §1).
- Automatyczny import z CSV RPL; GTIN-y seedowane ręcznie z przypiętą datą.
- Przeciwwskazania jako powody block zależne od cech dziecka (astma, choroba wrzodowa…) — dziecko nie ma tych danych (S-01); katalog zapisuje je tylko jako tekst ostrzeżeń ze źródłem, do wyświetlenia w S-02.
- Edytor reguł dla użytkownika (PRD Non-Goals).
- Nurofen 100 mg/5 ml (ChPL 9094) — brak w bieżącym CSV RPL, nie seedujemy (research §2 Rozbieżności).
- Zmiany kodu aplikacji i deploy Workera.

## Implementation Approach

Najpierw schemat i uprawnienia (faza 1), żeby weryfikacja w fazie 2 wiedziała, do jakich pól mapuje każdą liczbę. Dane trafiają do bazy dopiero po zatwierdzonej weryfikacji (faza 3) i dopiero potem na produkcję (faza 4). Model reguł odwzorowuje ChPL 1:1: produkt ma typ reguły `per_kg` (paracetamol) albo `weight_band` (ibuprofen) i nie przeliczamy jednego typu na drugi.

Zasady danych (decyzje planistyczne):
- Pasmo dawki wybiera wyłącznie masa; wiek działa tylko jako dolny próg (`min_age_months`).
- Gdy ChPL podaje zakres **schematu** (np. „co 6–8 h”, „3–4 razy na dobę”), zapisujemy koniec ostrożniejszy (8 h, 3 dawki) — obie wartości mieszczą się w ChPL, a fałszywe allow jest najgorszym błędem.
- Gdy ChPL podaje **sufit** (np. „20–30 mg/kg/dobę” jako maksimum dobowe), zapisujemy górną wartość ChPL (30 mg/kg) — dolna wartość zaprzeczałaby tabeli pasm (10 kg: 100 mg × 3 = 30 mg/kg). Dawki z tabeli pasm są autorytatywne; sufit ich nie obcina.
- Pasma są ciągłe: `[weight_min_kg, weight_min_kg następnego pasma)`; masa w luce tabeli ChPL (np. 9,4 kg między „7–9 kg” a „10–15 kg”) należy do **niższego** pasma, więc dostaje dawkę nie wyższą niż z tabeli.
- Każde zawężenie (zakres schematu, luka pasm) jest oznaczone w `verification.md` jako „ChPL → wybrana wartość”, żeby człowiek mógł je nadpisać na bramce fazy 2.
- Masa powyżej zakresu tabeli ChPL (> 40 kg ibuprofen, > 42 kg paracetamol) → `max_weight_kg`, bramka zwróci block.
- Naprzemienność: reguła pary substancji `block_until_previous_interval` — dopóki nie minął własny `min_interval_hours` substancji podanej poprzednio, druga dostaje block z komunikatem „naprzemienne podawanie tylko po konsultacji z lekarzem” (research §6: PTP 2024, NHS).

## Critical Implementation Details

- **Kolejność migracji:** faza 1 i faza 3 to dwie osobne migracje (schemat, potem dane). Produkcja dostaje obie jednym `db push` w fazie 4 — migracja danych nie może powstać przed zatwierdzeniem bramki fazy 2.
- **Podwójny zapis wartości:** test pgTAP w fazie 3 wpisuje oczekiwane liczby niezależnie od migracji (przepisane z `verification.md`, nie wyliczane z tabel), żeby literówka w migracji nie przechodziła testu.

## Faza 1: Schemat i uprawnienia katalogu

### Overview

Tabele katalogu z ograniczeniami i uprawnieniami tylko do odczytu, bez danych.

### Changes Required:

#### 1. Migracja schematu

**File**: `supabase/migrations/<YYYYMMDDHHmmss>_medication_catalog.sql`

**Intent**: Model danych, który przechowuje reguły dawkowania obu typów z ChPL wraz ze źródłami, oraz mapowanie GTIN → produkt.

**Contract**:
- `substances`: `id text pk` (slug: `paracetamol`, `ibuprofen`), `name_pl text not null`, `min_interval_hours numeric not null check > 0` (własny odstęp substancji używany też przez regułę naprzemienności), `source_url text not null`, `checked_at date not null`.
- `products` (jeden wiersz na ChPL — warianty smakowe z osobnym ChPL to osobne wiersze): `id text pk` (slug), `substance_id → substances`, `name_pl text not null`, `form text not null check in ('oral_suspension')`, `strength_mg_per_ml numeric not null check > 0`, `chpl_url text not null`, `chpl_text_date date` (null, jeśli nieustalona), `rule_type text not null check in ('per_kg','weight_band')`, `dose_mg_per_kg numeric` (wymagane dla `per_kg`), `max_doses_24h int not null check > 0`, `max_mg_per_kg_24h numeric not null check > 0`, `min_age_months int not null check >= 0`, `min_weight_kg numeric not null`, `max_weight_kg numeric not null` (check `max_weight_kg > min_weight_kg`), `warnings text[] not null default '{}'`, `source_url text not null`, `checked_at date not null`; CHECK: `rule_type = 'per_kg'` ⇔ `dose_mg_per_kg is not null`.
- `product_dose_bands`: `product_id → products`, `weight_min_kg numeric not null`, `weight_max_kg numeric not null` (check `>` min), `dose_mg numeric not null check > 0`, `max_doses_24h int not null check > 0`, PK `(product_id, weight_min_kg)`; pasma jednego produktu nie nachodzą na siebie: migracja włącza `create extension if not exists btree_gist with schema extensions` i dodaje constraint `exclude using gist (product_id with =, numrange(weight_min_kg, weight_max_kg, '[)') with &&)`; pasma są ciągłe (`weight_max_kg` pasma = `weight_min_kg` następnego), ostatnie kończy się na `products.max_weight_kg`.
- `product_barcodes`: `gtin text pk check (gtin ~ '^[0-9]{14}$')`, `product_id → products`, `package_ml numeric not null check > 0`, `source_url text not null`, `checked_at date not null`.
- `substance_pair_rules`: `substance_a → substances`, `substance_b → substances`, `rule text not null check in ('block_until_previous_interval')`, `message_pl text not null`, `source_urls text[] not null`, `checked_at date not null`; PK `(substance_a, substance_b)`, check `substance_a < substance_b` (jedna para, niezależnie od kolejności).
- Wszystkie FK `on delete restrict`.
- RLS włączony na każdej tabeli; jedna polityka SELECT `to authenticated using (true)` per tabela; brak INSERT/UPDATE/DELETE.
- Granty: `revoke all ... from anon, authenticated`; `grant select ... to authenticated`.

#### 2. Testy schematu

**File**: `supabase/tests/medication_catalog_schema.test.sql`

**Intent**: Udowodnić, że katalog jest czytelny tylko dla zalogowanych, niezapisywalny przez API i odrzuca nieprawidłowe dane.

**Contract**: pgTAP w transakcji (`create extension if not exists pgtap with schema extensions;`, `plan(n)`, rollback). Asercje: `has_table_privilege('anon', …, 'select')` = false dla każdej tabeli; `authenticated` SELECT = true, INSERT/UPDATE/DELETE = false; `authenticated` INSERT do `products` rzuca `42501`; jako `postgres`: produkt `per_kg` bez `dose_mg_per_kg` rzuca `23514`, GTIN o 13 cyfrach rzuca `23514`, para z `substance_a > substance_b` rzuca `23514`, nachodzące pasma są odrzucane.

### Success Criteria:

#### Automated Verification:

- Migracje stosują się czysto: `npx supabase db reset`
- Testy bazy przechodzą: `npx supabase test db`
- Lint przechodzi: `npm run lint`

#### Manual Verification:

- Schemat odpowiada kontraktowi (tabele, CHECK-i, polityki, granty) — przegląd `git diff` migracji

**Implementation Note**: Po automatycznej weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka przed fazą 2.

---

## Faza 2: Weryfikacja wartości z ChPL

### Overview

Każda liczba, która trafi do katalogu, zostaje sprawdzona w PDF ChPL i w CSV RPL i zapisana z cytatem; człowiek zatwierdza tabelę.

### Changes Required:

#### 1. Dokument weryfikacji

**File**: `context/changes/seed-medication-catalog/verification.md`

**Intent**: Jedno miejsce, w którym dla każdego pola z fazy 1 stoi wartość, cytat ze źródła i numer strony/sekcji — podstawa migracji danych i testu w fazie 3.

**Contract**: Tabele per produkt i per pole: `tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi`. Wiersze typu „zakres ChPL → wybrana wartość” oznaczone. Sekcje: Panadol (5104), Nurofen Forte — osobno każdy wariant, który seedujemy (33567 pomarańczowy, 33568 truskawkowy; faza ustala, które warianty i GTIN-y wchodzą), w tym każde pasmo z tabeli dawkowania, GTIN-y (wiersz CSV RPL: kolumny „Opakowanie”, status, wielkość opakowania; data pobrania CSV), `substances.min_interval_hours`, reguła pary (research §6), `warnings` (przeciwwskazania z sekcji 4.3). Rozstrzygnięcia niewiadomych z research: data tekstu ChPL Panadolu (pkt 10), dokładne pasma masa–wiek Forte (wizualnie z PDF), status obu produktów i ich GTIN-ów w bieżącym CSV. Pliki źródłowe (PDF, CSV) tylko w scratchpadzie, nie w repo.

### Success Criteria:

#### Automated Verification:

- Każde pole danych z kontraktu fazy 1 ma wiersz w `verification.md`: skrypt Node w scratchpadzie porównuje kolumny z `information_schema.columns` (tabele katalogu, bez `id`/FK) z nazwami `tabela.kolumna` w `verification.md` i wypisuje braki (0 braków)

#### Manual Verification:

- Człowiek porównał tabelę z PDF ChPL i zatwierdził ją (także każde zawężenie zakresu)

**Implementation Note**: Faza nie tworzy migracji danych. Po zatwierdzeniu człowieka przejdź do fazy 3; korekty z bramki wpisuje się do `verification.md` przed fazą 3.

---

## Faza 3: Dane katalogu

### Overview

Zatwierdzone wartości trafiają do bazy migracją, a test pgTAP niezależnie sprawdza każdą z nich.

### Changes Required:

#### 1. Migracja danych

**File**: `supabase/migrations/<YYYYMMDDHHmmss>_medication_catalog_seed.sql`

**Intent**: Wstawić substancje, produkty, pasma, GTIN-y i regułę pary dokładnie z `verification.md`.

**Contract**: Wyłącznie `insert` do tabel z fazy 1; wartości i `source_url`/`checked_at` 1:1 z `verification.md`; nagłówek migracji wskazuje `verification.md` jako źródło; dane syntetyczne nie dotyczą (to publiczne dane referencyjne, bez danych osobowych).

#### 2. Test danych

**File**: `supabase/tests/medication_catalog_data.test.sql`

**Intent**: Podwójny zapis każdej wartości — literówka w migracji nie może przejść.

**Contract**: pgTAP: dla każdego produktu `results_eq`/`is` na każdą kolumnę reguły; pełna lista pasm Forte (`results_eq` z wartościami wpisanymi w teście); każdy GTIN → oczekiwany produkt i `package_ml`; nieznany GTIN (`05900000000000`) → 0 wierszy; reguła pary `paracetamol`–`ibuprofen` = `block_until_previous_interval`; dla każdego pasma `dose_mg × max_doses_24h ≤ max_mg_per_kg_24h × weight_min_kg` (spójność pasm z sufitem dobowym); pasma każdego produktu są ciągłe od `min_weight_kg` do `max_weight_kg`; jako `authenticated` odczyt katalogu zwraca dane.

### Success Criteria:

#### Automated Verification:

- Migracje stosują się czysto: `npx supabase db reset`
- Testy bazy przechodzą: `npx supabase test db`
- Lint przechodzi: `npm run lint`
- CI na pushu jest zielone (job `smoke` z krokiem testów bazy)

#### Manual Verification:

- Losowo wybrane 3 wartości z bazy zgadzają się z zatwierdzonym `verification.md`

**Implementation Note**: Po automatycznej weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka przed fazą 4.

---

## Faza 4: Wdrożenie na produkcję

### Overview

Obie migracje na hostowany Supabase (człowiek), weryfikacja schematu i danych, wpis w historii wdrożeń.

### Changes Required:

#### 1. Migracja produkcji (bramka człowieka)

**File**: — (operacja)

**Intent**: Zastosować schemat i dane katalogu na produkcji.

**Contract**: Człowiek: `npx supabase db push` (projekt już podlinkowany). Dopiero po zielonym CI z fazy 3.

#### 2. Zapis wdrożenia

**File**: `context/deployment/deploy-plan.md`

**Intent**: Odnotować migracje katalogu i wynik weryfikacji; Worker bez zmian.

**Contract**: Wiersz w „Historia wdrożeń” (Worker version bez zmian, nazwy obu migracji, weryfikacja) i aktualizacja wiersza „Supabase” w „Co jest wdrożone”.

### Success Criteria:

#### Automated Verification:

- `npx supabase migration list` pokazuje obie migracje katalogu jako zastosowane zdalnie
- Schemat produkcyjny (`npx supabase db dump --linked --schema public`) zawiera tabele katalogu z RLS i grantem SELECT tylko dla `authenticated`
- Anonim przez REST nie czyta katalogu (`GET /rest/v1/products` z kluczem publishable → brak dostępu)

#### Manual Verification:

- W Supabase Dashboard liczba wierszy `products` i pasma w `product_dose_bands` są zgodne z `verification.md`

**Implementation Note**: Po weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka.

---

## Testing Strategy

### Unit Tests:

- Brak runnera jednostkowego; reguły danych żyją w bazie i są testowane pgTAP.

### Integration Tests:

- `medication_catalog_schema.test.sql`: uprawnienia, CHECK-i, brak zapisu przez API, rozłączność pasm.
- `medication_catalog_data.test.sql`: każda wartość, każde pasmo, każdy GTIN, nieznany GTIN, reguła pary.

### Manual Testing Steps:

1. Porównanie `verification.md` z PDF ChPL (bramka fazy 2).
2. Wyrywkowa kontrola 3 wartości w bazie (faza 3).
3. Kontrola danych w Supabase Dashboard na produkcji (faza 4).

## Performance Considerations

Katalog ma kilka–kilkanaście wierszy; PK na slugach i GTIN wystarcza. Bez cache.

## Migration Notes

Dwie migracje addytywne (schemat, dane). Korekta wartości w przyszłości = nowa migracja `update` z nowym `checked_at` i wierszem w `verification.md`, nigdy edycja zastosowanej migracji. Rollback Workera nie dotyczy (brak zmian kodu).

## References

- Research: `context/changes/seed-medication-catalog/research.md` (§1–5 produkty i źródła, §6 naprzemienność)
- Roadmap: `context/foundation/roadmap.md` (F-01, odblokowuje S-02 i S-05)
- PRD: `context/foundation/prd.md` (FR-004, FR-005, Secondary Success Criterion, Guardrails, Non-Goals)
- Wzorce: `supabase/migrations/20260925200500_household_hardening.sql`, `supabase/tests/household_hardening.test.sql`
- Wdrożenie: `context/deployment/deploy-plan.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Schemat i uprawnienia katalogu

#### Automated

- [x] 1.1 Migracje stosują się czysto: `npx supabase db reset`
- [x] 1.2 Testy bazy przechodzą: `npx supabase test db`
- [x] 1.3 Lint przechodzi: `npm run lint`

#### Manual

- [x] 1.4 Schemat odpowiada kontraktowi (tabele, CHECK-i, polityki, granty) — przegląd `git diff` migracji

### Phase 2: Weryfikacja wartości z ChPL

#### Automated

- [ ] 2.1 Każde pole danych z kontraktu fazy 1 ma wiersz w `verification.md`: skrypt Node w scratchpadzie porównuje kolumny z `information_schema.columns` (tabele katalogu, bez `id`/FK) z nazwami `tabela.kolumna` w `verification.md` i wypisuje braki (0 braków)

#### Manual

- [ ] 2.2 Człowiek porównał tabelę z PDF ChPL i zatwierdził ją (także każde zawężenie zakresu)

### Phase 3: Dane katalogu

#### Automated

- [ ] 3.1 Migracje stosują się czysto: `npx supabase db reset`
- [ ] 3.2 Testy bazy przechodzą: `npx supabase test db`
- [ ] 3.3 Lint przechodzi: `npm run lint`
- [ ] 3.4 CI na pushu jest zielone (job `smoke` z krokiem testów bazy)

#### Manual

- [ ] 3.5 Losowo wybrane 3 wartości z bazy zgadzają się z zatwierdzonym `verification.md`

### Phase 4: Wdrożenie na produkcję

#### Automated

- [ ] 4.1 `npx supabase migration list` pokazuje obie migracje katalogu jako zastosowane zdalnie
- [ ] 4.2 Schemat produkcyjny (`npx supabase db dump --linked --schema public`) zawiera tabele katalogu z RLS i grantem SELECT tylko dla `authenticated`
- [ ] 4.3 Anonim przez REST nie czyta katalogu (`GET /rest/v1/products` z kluczem publishable → brak dostępu)

#### Manual

- [ ] 4.4 W Supabase Dashboard liczba wierszy `products` i pasma w `product_dose_bands` są zgodne z `verification.md`
