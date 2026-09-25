# Minimalny katalog substancji — Plan Brief

> Full plan: `context/changes/seed-medication-catalog/plan.md`
> Research: `context/changes/seed-medication-catalog/research.md`

## What & Why

Roadmap F-01: katalog, z którego bramka (S-02) policzy allow / wait / block i dawkę, a kod kreskowy (S-05) znajdzie lek. PRD wymaga, by reguły bezpieczeństwa pochodziły z katalogu z cytowalnym źródłem, a nie od użytkownika; fałszywe allow jest regresją. Dlatego każda liczba jest zweryfikowana z ChPL i zatwierdzona przez człowieka, zanim trafi na produkcję.

## Starting Point

Baza ma tylko tabele gospodarstwa i dzieci (S-01) z RLS i zawężonymi grantami; brak jakichkolwiek danych o lekach. Research wskazał produkty (Panadol dla dzieci 120 mg/5 ml, Nurofen dla dzieci Forte 40 mg/ml), wartości, GTIN-y z RPL i zostawił trzy niewiadome do sprawdzenia w PDF.

## Desired End State

Lokalnie i na produkcji istnieje katalog tylko do odczytu: 2 substancje, produkty zatwierdzone w weryfikacji (jeden wiersz na ChPL), pasma dawek ibuprofenu, GTIN-y opakowań i reguła naprzemienności. Każda wartość ma cytat w `verification.md`, a testy pgTAP sprawdzają ją niezależnie od migracji.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
| --- | --- | --- | --- |
| Substancje i produkty | Paracetamol + ibuprofen, tylko zawiesiny (ChPL 5104, 33567/33568) | Jedyne OTC dla dzieci na gorączkę; czopki mają inne progi. | Research |
| Kody kreskowe | Ręcznie z CSV RPL, z datą; nieznany GTIN → brak rekomendacji | Oficjalny zbiór CC BY 4.0; bez importu nic się nie zmienia po cichu. | Research |
| Próg paracetamolu | < 6 kg lub < 3 mies. → block („konsultacja”) | ChPL nie podaje progu wprost; tabela zaczyna się od 6 kg / 3 mies. | Research (user) |
| Model reguł | Dwa typy: `per_kg` (paracetamol) i `weight_band` (ibuprofen) | Dane 1:1 z ChPL, weryfikowalne bez przeliczeń. | Plan |
| Wybór pasma | Decyduje masa; wiek tylko jako dolny próg | Jednoznaczne; tabela Forte ma luki między masą a wiekiem. | Plan |
| Naprzemienność | Block, dopóki nie minął odstęp leku podanego poprzednio („tylko po konsultacji z lekarzem”) | Brak cytowalnego odstępu; PTP 2024 i NHS odradzają naprzemienność. | Plan (research §6) |
| Zakresy w ChPL | Schemat: koniec ostrożniejszy (co 8 h, 3 dawki); sufit dobowy: górna wartość ChPL (30 mg/kg) — do nadpisania na bramce | Minimalizuje fałszywe allow bez zaprzeczania tabeli pasm. | Plan (review F2) |
| Luki między pasmami | Pasma ciągłe; masa w luce → niższe pasmo (9,4 kg → 50 mg) | Każda masa ma jedną dawkę, nie wyższą niż z tabeli. | Plan (review F1) |
| Weryfikacja liczb | Agent z PDF → `verification.md` z cytatami → bramka człowieka | Zamyka niewiadome z researchu; ostatnie słowo przy danych medycznych ma człowiek. | Plan |
| Dostarczenie danych | Migracja z danymi, na prod przez `db push` | Jedna ścieżka dla lokalnego, CI i produkcji z historią w git. | Plan |

## Scope

**In scope:** tabele `substances`, `products`, `product_dose_bands`, `product_barcodes`, `substance_pair_rules` z RLS tylko do odczytu; `verification.md`; migracja danych; testy pgTAP schematu i danych; `db push` i wpis w `deploy-plan.md`.

**Out of scope:** logika bramki i UI (S-02), skanowanie (S-05), czopki, import CSV, przeciwwskazania jako block zależny od cech dziecka (tylko tekst ostrzeżeń), Nurofen 100 mg/5 ml, zmiany kodu aplikacji.

## Architecture / Approach

Substancja niesie własny minimalny odstęp (używany też przez regułę naprzemienności); produkt niesie typ reguły i jej parametry (limity dobowe, progi wieku i masy, moc mg/ml, ostrzeżenia, źródło); ibuprofen ma dodatkowo pasma masa → stała dawka; GTIN wskazuje produkt i objętość opakowania; para substancji ma regułę naprzemienności. Katalog jest publicznymi danymi referencyjnymi: jedna polityka SELECT dla `authenticated`, zero zapisu, `anon` bez dostępu. Schemat i dane to dwie migracje, a dane powstają dopiero po zatwierdzonej weryfikacji.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Schemat i uprawnienia | Puste tabele, CHECK-i, RLS, testy | Model nie pomieści czegoś z ChPL |
| 2. Weryfikacja z ChPL | `verification.md` z cytatami + bramka człowieka | Nieczytelne fragmenty PDF (data, pasma) |
| 3. Dane katalogu | Migracja danych + test każdej wartości | Literówka w liczbie — łapie podwójny zapis |
| 4. Produkcja | `db push` (człowiek), weryfikacja, deploy-plan | Kolejność: dane dopiero po zielonym CI |

**Prerequisites:** lokalny Supabase (jest), dostęp do PDF ChPL i CSV RPL (publiczne), Twój czas na bramkę fazy 2 i `db push`.
**Estimated effort:** ~2–3 sesje w 4 fazach.

## Open Risks & Assumptions

- Część wartości ChPL może być nieczytelna tekstowo (np. data w pkt 10 Panadolu jest obrazem) — wtedy `chpl_text_date` zostaje puste z adnotacją.
- Aplikacja kwalifikująca się jako wyrób medyczny (MDR, reguła 11) — poza tym planem; disclaimer z PRD Open Question 4 wraca w S-02.

## Success Criteria (Summary)

- S-02 może zapytać bazę o regułę produktu i pasmo dla masy dziecka oraz o produkt po GTIN i dostaje wartości zgodne z ChPL.
- Każdą liczbę w katalogu da się wskazać palcem w PDF ChPL przez `verification.md`.
- Katalog jest nietykalny przez API i niewidoczny dla anonima — także na produkcji.
