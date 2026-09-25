---
change_id: seed-medication-catalog
researched_at: 2026-09-25
question: "Which substances and citeable ChPL sources seed the popular catalog / barcode mappings? (PRD Open Question 2)"
status: answered
---

# Research: katalog v1 — substancje, ChPL, kody kreskowe

Źródła sprawdzone 2026-09-25 (PDF-y ChPL pobrane z Rejestru Produktów Leczniczych i przeczytane).
**Każdą liczbę dawkowania zweryfikuj wzrokowo w PDF przed seedem** — od nich zależy guardrail „brak fałszywego allow”.

## 1. Zestaw substancji

**Paracetamol + ibuprofen, wyłącznie zawiesiny doustne.** To jedyne substancje w polskim OTC dla dzieci na gorączkę i ból.
Czopki odłożone: mają inne progi niż zawiesiny (np. Nurofen 60 mg czopki: od 6,0 kg i 3 mies., maks. 10 mg/kg na dawkę, odstęp ≥ 6 h), więc to osobna reguła; dawkowania czopków paracetamolu nie sprawdzono.

## 2. Parametry z ChPL

### Paracetamol — Panadol dla dzieci 120 mg/5 ml (24 mg/ml)

- ChPL: https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic
- Dawka jednorazowa 15 mg/kg; tabela w ChPL zaczyna się od 6 kg / 3 mies. (3,5 ml).
- Odstęp ≥ 4 h, najwyżej 4 dawki na dobę.
- Maks. 60 mg/kg/24 h w dawkach 10–15 mg/kg; bez lekarza nie dłużej niż 3 dni.
- Przeciwwskazania: nadwrażliwość, ciężka niewydolność wątroby lub nerek.
- Brak górnego limitu mg/dobę; tabela kończy się na 42 kg.
- Minimalny wiek/masa nie są podane wprost — **decyzja: < 6 kg lub < 3 mies. → block („konsultacja”)** (wniosek z tabeli, nie cytat).
- Data zmiany tekstu (pkt 10) nieczytelna w PDF (obraz) — do sprawdzenia ręcznie.

### Ibuprofen — Nurofen dla dzieci Forte pomarańczowy 40 mg/ml (ChPL z 23.04.2025)

- ChPL: https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic (wariant truskawkowy: 33568)
- 20–30 mg/kg/dobę w dawkach podzielonych, co ok. 6–8 h.
- Nie zaleca się < 3 mies. lub < 5 kg; dla 3–5 mies. — lekarz, jeśli objawy nie ustępują po 24 h.

| Masa (wiek) | Dawka | Razy na dobę |
|---|---|---|
| od 5 kg (3–5 mies.) | 50 mg / 1,25 ml | 3 |
| 7–9 kg | 50 mg | 3–4 |
| 10–15 kg | 100 mg | 3 |
| 16–19 kg | 150 mg | 3 |
| 20–29 kg | 200 mg | 3 |
| 30–40 kg | 300 mg | 3 |

Wiek i masa w tabeli nie pokrywają się bez luk (np. 7–9 kg ↔ 6–11 mies., 10–15 kg ↔ 1–3 lata) — bramka potrzebuje jednego kryterium rozstrzygającego; najbezpieczniej masa. Dokładne przypisanie pasm sprawdzić wzrokowo w PDF.

**Przeciwwskazania ibuprofenu jako powody block** (ChPL Nurofen czopki 16290, zawiesina 100 mg/5 ml 9094): nadwrażliwość na NLPZ/ASA, astma po NLPZ; choroba wrzodowa lub krwawienie z przewodu pokarmowego; ciężka niewydolność wątroby, nerek lub serca; skaza krwotoczna; ciężkie odwodnienie (zapis w ChPL czopków 16290 — sekcji 4.3 zawiesiny 9094 nie przejrzano w całości).
- ChPL czopków: https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/16290/characteristic

### Rozbieżności

- Klasyczny Nurofen 100 mg/5 ml (ChPL 01/2021, https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/9094/characteristic): „powyżej 5 kg”, < 6 mies. tylko po konsultacji; po szczepieniu (3–6 mies.) najwyżej 2 × 50 mg/24 h.
- Produktu z ChPL 9094 (pozwolenie 4567) nie ma w bieżącym CSV RPL — możliwe wycofanie; **nie seedować bez weryfikacji**.

## 3. Kody kreskowe

Oficjalny otwarty zbiór: **Rejestr Produktów Leczniczych** na dane.gov.pl — https://dane.gov.pl/pl/dataset/397,rejestr-produktow-leczniczych — licencja CC BY 4.0, aktualizacja codzienna.

- CSV: https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv
- XML: https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/6.0.0/overall.xml
- XLSX: https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-xlsx
- Kolumna „Opakowanie” zawiera GTIN-14 (EAN-13 z wiodącym zerem — równoważne wg https://www.gov.pl/web/zdrowie/komunikat-ministra-zdrowia-w-sprawie-kodow-ean-13-i-gtin-14); są też kategoria (OTC), status „Skasowane”, wielkość opakowania, „Moc”, „Postać”, „Substancja czynna” i link do ChPL.

Pułapki przy przeliczaniu mg → ml: „Moc” to wolny tekst („2,4 % (W/V)”, „40 mg/ml”, „100 mg/5 ml”) do ręcznej normalizacji; niektóre opakowania w gramach („butelka 130 g”); import równoległy ma osobne GTIN-y i często brak linku do ChPL; opakowania „Skasowane” odfiltrować.

## 4. Zastrzeżenia prawne

- Dane RPL: CC BY 4.0 — wymagane podanie źródła.
- ChPL: bezpieczniej cytować liczby z odnośnikiem niż kopiować tekst; status licencyjny samych PDF-ów niezweryfikowany.
- Oprogramowanie liczące dawkę z odpowiedzią allow/block może kwalifikować się jako wyrób medyczny (MDR, reguła 11; MDCG 2019-11) — ocena niezweryfikowana cytatem. Wiąże się z PRD Open Question 4: wyraźne oznaczenie „prototyp edukacyjny, nie porada medyczna”, najpóźniej wraz z pierwszą wyświetloną dawką.

## 5. Rekomendacja (przyjęta 2026-09-25)

Seed v1: dwie substancje, dwa produkty.

- **Panadol dla dzieci 120 mg/5 ml** (ChPL 5104), GTIN 05909990327317 / 05909991447168 / 05909991447175 (100 / 200 / 60 ml).
- **Nurofen dla dzieci Forte 40 mg/ml**, pomarańczowy lub truskawkowy (ChPL 33567 / 33568), GTIN np. 05909991222833 / 05909991222840 / 05909991222857.

Zasady seedu:
- GTIN-y seedowane ręcznie z CSV RPL z przypiętą datą, bez automatycznego importu.
- Każda reguła ma `source_url` i `checked_at`.
- Nieznany GTIN → brak rekomendacji, nigdy allow.
- Brak limitu dobowego w mg → stosuj limit mg/kg; masa powyżej zakresu tabeli (> 40 kg ibuprofen, > 42 kg paracetamol) → block.
- **Decyzja:** przy naprzemiennym podawaniu paracetamolu i ibuprofenu bramka pilnuje odstępu między substancjami — reguła rozstrzygnięta w sekcji 6.

## Nierozstrzygnięte

- data tekstu ChPL Panadolu,
- status Nurofenu 100 mg/5 ml,
- dokładne przypisanie pasm masa–wiek w tabeli Forte,
- dawkowanie czopków paracetamolu (poza v1),
- ~~wartość odstępu przy podawaniu naprzemiennym~~ — rozstrzygnięte w sekcji 6.

## 6. Naprzemienne podawanie paracetamolu i ibuprofenu (sprawdzone 2026-09-25)

Żadne ChPL ani wytyczna nie podaje obowiązującego odstępu między dwiema substancjami.

- **PTP + Konsultant Krajowy, Przegl Pediatr 2024;53(4):32-43** — https://ptp.edu.pl/najnowsze-zalecenia-dotyczace-leczenia-przeciwgoraczkowego-u-dzieci-w-wieku-0-36-miesiecy/ — „Nie zalecamy naprzemiennego stosowania ibuprofenu i paracetamolu.” (pełny tekst za paywallem, niesprawdzony).
- **NHS** — https://www.nhs.uk/conditions/fever-in-children/ — „do not alternate ibuprofen and paracetamol, unless a health professional such as a doctor or nurse tells you to”.
- **NICE NG143, rek. 1.6.6** — https://www.nice.org.uk/guidance/ng143/chapter/Recommendations — „do not give both agents simultaneously; only consider alternating these agents if the distress persists or recurs before the next dose is due.” Bez liczby godzin.
- **AAP, Sullivan & Farrar 2011, PMID 21357332** i **Cochrane CD009572 (Wong 2013)** — niewystarczające dowody na schemat łączony/naprzemienny.
- **MP, Grygalewicz 2014** — https://www.mp.pl/pytania/pediatria/chapter/B25.QA.1.5.5. — jedyna konkretna liczba (4 h); ten sam autor w 2018 (B25.QA.1.5.4.): „nie opublikowano żadnego ogólnie przyjętego schematu”.
- **ChPL Panadol 4.5**: skojarzenie paracetamolu z NLPZ zwiększa ryzyko zaburzeń czynności nerek. **ChPL Nurofen Forte**: brak wzmianki o paracetamolu.

**Decyzja (user, 2026-09-25):** dopóki nie minął własny minimalny odstęp substancji podanej poprzednio, druga substancja dostaje **block** z komunikatem „naprzemienne podawanie tylko po konsultacji z lekarzem”. Źródła reguły: PTP 2024, NHS. Własne odstępy każdej substancji z ChPL obowiązują zawsze, niezależnie od tej reguły.
