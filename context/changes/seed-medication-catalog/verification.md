---
change_id: seed-medication-catalog
phase: 2
checked_at: 2026-09-25
status: zatwierdzone
approved_at: 2026-09-26
approved_by: human
---

# Weryfikacja wartości katalogu z ChPL i CSV RPL

Jedyne źródło danych dla migracji i testu w fazie 3. Każdy wiersz: `tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi`.
Zawężenia według zasad danych z planu są oznaczone w kolumnie uwag jako **ZAWĘŻENIE: ChPL → wybrana wartość**.
Pliki źródłowe (PDF, CSV) leżą wyłącznie w scratchpadzie sesji, nie w repozytorium.

## Do zatwierdzenia przez człowieka

**Zatwierdzone przez człowieka 2026-09-26** (bramka 2.2): Z1–Z7 wszystkie; N1 → `null`; D2 → rozstrzygnięcie w S-02 (górna granica produktu włączna, masa równa `max_weight_kg` trafia do ostatniego pasma); D5 → ostrzeżenia rozszerzone o pkt 4.2 i 4.4 (niżej). D1, D3, D4, D6, D7 przyjęte bez zmian (przedstawione w podsumowaniu bramki, bez sprzeciwu).

Zawężenia (zasady danych z planu):

- [x] **Z1** `substances.min_interval_hours` (ibuprofen): „co około 6 do 8 godzin” → **8**.
- [x] **Z2** `product_dose_bands.max_doses_24h`, pasmo 7–9 kg (obie wersje Forte): „3 do 4 razy” → **3**.
- [x] **Z3** `products.max_doses_24h` (obie wersje Forte): tabela ChPL 3 razy albo „3 do 4 razy” → **3**.
- [x] **Z4** `products.max_mg_per_kg_24h` (obie wersje Forte): sufit „20 do 30 mg/kg” → **30** (górna wartość ChPL, potwierdzona też w pkt 5.1: „maksymalnie 30 mg/kg mc./dobę”).
- [x] **Z5** Luki w tabeli pasm Forte, domknięte do niższego pasma: 9–10 kg → pasmo 7 kg (50 mg), 15–16 kg → pasmo 10 kg (100 mg), 19–20 kg → pasmo 16 kg (150 mg), 29–30 kg → pasmo 20 kg (200 mg). Pierwszy wiersz „od 5 kg” nie ma górnej granicy w ChPL; kończy się na 7 kg, gdzie zaczyna się następny wiersz.
- [x] **Z6** Paracetamol, dolny próg: `products.min_weight_kg = 6`, `products.min_age_months = 3` to **decyzja użytkownika na podstawie tabeli ChPL** (tabela zaczyna się od „6 kg · 3,5 ml · 3 miesiące”). ChPL nie podaje wprost minimalnej masy ani wieku.
- [x] **Z7** Górne granice: `products.max_weight_kg` = 42 (Panadol, koniec tabeli) i 40 (Forte, „30 do 40 kg”). Masa powyżej → block.

Decyzje, które warto potwierdzić (nie są zawężeniami, ale wpływają na dane):

- [x] **D1** `products.dose_mg_per_kg` (Panadol) = **15**. ChPL mówi wprost „15 mg/kg masy ciała w dawce jednorazowej”. Zakres „10-15 mg/kg” pojawia się tylko w zdaniu o maksymalnej dawce dobowej, więc nie stosuję reguły „koniec ostrożniejszy”. Tabela ChPL zaokrągla objętości i daje miejscami do ok. 15,4 mg/kg (12,5 kg → 8,0 ml = 192 mg); wzór 15 mg/kg daje dawkę nie wyższą niż tabela.
- [x] **D2** Masa równa dokładnie 40,0 kg (Forte): ostatnie pasmo to `[30, 40)` i kończy się na `max_weight_kg = 40`, więc 40,0 kg nie trafia do żadnego pasma, a bramka zwróci block. ChPL mówi „30 do 40 kg”, czyli 40 kg obejmuje. To fałszywy block, nie fałszywe allow. Do zatwierdzenia albo korekty w S-02 (włączna górna granica produktu). Tak samo dla Panadolu przy 42,0 kg: to zależy od tego, jak S-02 porówna masę z `max_weight_kg`.
- [x] **D3** Seedujemy **oba** warianty Forte (pomarańczowy 33567 i truskawkowy 33568). Mają identyczne dawkowanie i przeciwwskazania, każdy ma zweryfikowane ChPL i 3 aktywne GTIN-y.
- [x] **D4** Import równoległy pominięty: w CSV jest kilkanaście wierszy „Nurofen dla dzieci Forte …” z typem procedury IR (np. Delfarma, Medezin, InPharm), z własnymi GTIN-ami i osobnym ChPL (np. `…/41153/characteristic`). Nie weryfikowałem ich ChPL, więc ich GTIN-y nie wchodzą do katalogu: nieznany GTIN oznacza brak rekomendacji.
- [x] **D5** `products.warnings` zawiera tylko przeciwwskazania z pkt 4.3 (zgodnie z kontraktem). Pominąłem „W trzecim trymestrze ciąży” (dotyczy dorosłych, katalog jest dla dzieci). **Poza `warnings`** zostały limity z pkt 4.2: „Bez konsultacji z lekarzem leku nie należy stosować regularnie dłużej niż przez 3 dni” (Panadol), porada lekarza po 3 dniach / po 24 h u 3–5 mies. (Forte), oraz z pkt 4.4 Panadolu: nietolerancja fruktozy. Schemat pozwala je dopisać jako tekst; decyzja, czy mają tam trafić.
- [x] **D6** `substance_pair_rules.message_pl`: dosłownie tekst decyzji z research §6: „Naprzemienne podawanie tylko po konsultacji z lekarzem.”
- [x] **D7** Identyfikatory (slugi) produktów: `panadol-dla-dzieci-120mg-5ml`, `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml`, `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml`.

Nierozstrzygnięte:

- [x] **N1** `products.chpl_text_date` (Panadol) = **null**. Punkt 10 w PDF jest **pusty**: to nie obraz, strona 8 nie zawiera obrazów ani żadnego tekstu pod nagłówkiem (sprawdzone ekstrakcją tekstu, PyMuPDF i renderem strony). Kandydat do decyzji człowieka: **2025-03-27**. To data z nazwy pliku serwowanego przez RPL (`Charakterystyka-5104-2025-03-27-20632/N-2025-04-10.pdf`). Dla Forte ten sam schemat nazwy (`Charakterystyka-33567-2025-04-23-…`) zgadza się z datą w pkt 10 (23.04.2025), ale to wniosek z nazwy pliku, nie z tekstu ChPL. Metadane PDF: utworzony 2025-03-25.

## Źródła

| Źródło | URL | Plik (Content-Disposition) | Stron | Pobrano |
|---|---|---|---|---|
| ChPL Panadol dla dzieci 120 mg/5 ml | https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic | `Charakterystyka-5104-2025-03-27-20632/N-2025-04-10.pdf` | 8 | 2026-09-25 23:36 CEST |
| ChPL Nurofen dla dzieci Forte pomarańczowy 40 mg/ml | https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic | `Charakterystyka-33567-2025-04-23-22142/B-2025-05-16.pdf` | 16 | 2026-09-25 23:36 CEST |
| ChPL Nurofen dla dzieci Forte truskawkowy 40 mg/ml | https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic | `Charakterystyka-33568-2025-04-23-22142/B-2025-05-16.pdf` | 15 | 2026-09-25 23:36 CEST |
| CSV RPL (22 916 wierszy produktów) | https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv | — | — | **2026-09-25 23:37 CEST** |
| PTP + Konsultant Krajowy, Przegl Pediatr 2024;53(4):32-43 | https://ptp.edu.pl/najnowsze-zalecenia-dotyczace-leczenia-przeciwgoraczkowego-u-dzieci-w-wieku-0-36-miesiecy/ | — | — | sprawdzone ponownie 2026-09-25 |
| NHS, Fever in children | https://www.nhs.uk/conditions/fever-in-children/ | — | — | sprawdzone ponownie 2026-09-25 |

Numery stron podane według PDF-u, sprawdzone na renderze stron z tabelą dawkowania.
Dane RPL: licencja CC BY 4.0, źródło: Rejestr Produktów Leczniczych (dane.gov.pl).

## Rozstrzygnięcia niewiadomych z research

1. **Data tekstu ChPL Panadolu (pkt 10):** nie ma jej w dokumencie, bo punkt 10 jest pusty (nie jest to obraz). Zapisuję `null`, kandydat 2025-03-27 czeka na decyzję człowieka (N1).
2. **Pasma masa–wiek Forte:** odczytane wzrokowo z renderu str. 1–2 obu PDF-ów. Tabela ma 6 wierszy: od 5 kg (3–5 mies.) 50 mg × 3; 7–9 kg (6–11 mies.) 50 mg × 3–4; 10–15 kg (1–3 lata) 100 mg × 3; 16–19 kg (4–5 lat) 150 mg × 3; 20–29 kg (6–9 lat) 200 mg × 3; 30–40 kg (10–12 lat) 300 mg × 3. W obu wariantach tabela jest identyczna. Research wymieniał te same pasma. Wiek w tabeli nie wpływa na dane: pasmo wybiera wyłącznie masa, a wiek jest tylko dolnym progiem (`min_age_months`).
3. **Status w CSV RPL (2026-09-25):**
   - Panadol dla dzieci (ID RPL 100051046, pozwolenie 03273, bezterminowe): 3 opakowania aktywne OTC (60/100/200 ml), 2 „Skasowane” (Lz 300 ml, 1000 ml).
   - Forte pomarańczowy (100335677, pozwolenie 22448, bezterminowe): 3 aktywne OTC (100/150/200 ml), 2 „Skasowane” (30 ml, 50 ml).
   - Forte truskawkowy (100335683, pozwolenie 22449, bezterminowe): 3 aktywne OTC (100/150/200 ml), 2 „Skasowane” (30 ml, 50 ml).
   - Numery pozwoleń w CSV zgadzają się z pkt 8 ChPL (R/3273, 22448, 22449). Link „Charakterystyka” w każdym z tych wierszy wskazuje dokładnie na zweryfikowany PDF.
4. **Warianty w seedzie:** Panadol 5104 oraz oba warianty Forte, 33567 i 33568 (D3).

## substances

### paracetamol

| tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| substances.id | `paracetamol` | — | kontrakt fazy 1 (slug) | |
| substances.name_pl | `Paracetamol` | „5 ml zawiesiny zawiera 120 mg paracetamolu (Paracetamolum).” | ChPL 5104, pkt 2, s. 1 | |
| substances.min_interval_hours | `4` | „Nie należy zalecać podawania leku częściej niż co 4 godziny” | ChPL 5104, pkt 4.2, s. 2 | ChPL podaje jedną wartość, bez zakresu |
| substances.source_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic` | — | — | |
| substances.checked_at | `2026-09-25` | — | — | |

### ibuprofen

| tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| substances.id | `ibuprofen` | — | kontrakt fazy 1 (slug) | |
| substances.name_pl | `Ibuprofen` | „Każdy 1 ml zawiesiny doustnej zawiera 40 mg ibuprofenu.” | ChPL 33567, pkt 2, s. 1 | |
| substances.min_interval_hours | `8` | „Dawki należy podawać co około 6 do 8 godzin.” | ChPL 33567, pkt 4.2, s. 2 (identycznie ChPL 33568, s. 2) | **ZAWĘŻENIE (Z1): ChPL „6 do 8 h” → 8** |
| substances.source_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic` | — | — | |
| substances.checked_at | `2026-09-25` | — | — | |

## products

### Panadol dla dzieci 120 mg/5 ml (ChPL 5104)

| tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| products.id | `panadol-dla-dzieci-120mg-5ml` | — | slug (D7) | |
| products.substance_id | `paracetamol` | „5 ml zawiesiny zawiera 120 mg paracetamolu (Paracetamolum).” | ChPL 5104, pkt 2, s. 1 | |
| products.name_pl | `Panadol dla dzieci, 120 mg/5 ml, zawiesina doustna` | „Panadol dla dzieci, 120 mg/5 ml, zawiesina doustna.” | ChPL 5104, pkt 1, s. 1 | |
| products.form | `oral_suspension` | „Zawiesina doustna.” | ChPL 5104, pkt 3, s. 1; CSV: „Postać farmaceutyczna” = „Zawiesina doustna” | |
| products.strength_mg_per_ml | `24` | „1 ml zawiesiny zawiera 24 mg paracetamolu.” | ChPL 5104, pkt 4.2, s. 1 | CSV „Moc” = „2,4 % (W/V)”, co daje 24 mg/ml, spójnie |
| products.chpl_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic` | — | CSV, kolumna „Charakterystyka” | |
| products.chpl_text_date | `null` | pkt 10 „DATA ZATWIERDZENIA LUB CZĘŚCIOWEJ ZMIANY TEKSTU CHARAKTERYSTYKI PRODUKTU LECZNICZEGO”: brak treści pod nagłówkiem | ChPL 5104, pkt 10, s. 8 | **NIEROZSTRZYGNIĘTE (N1)**, kandydat 2025-03-27 |
| products.rule_type | `per_kg` | „15 mg/kg masy ciała w dawce jednorazowej.” | ChPL 5104, pkt 4.2, s. 1 | |
| products.dose_mg_per_kg | `15` | „15 mg/kg masy ciała w dawce jednorazowej.” | ChPL 5104, pkt 4.2, s. 1 | D1 |
| products.max_doses_24h | `4` | „ani stosować więcej niż 4 dawki w ciągu doby” | ChPL 5104, pkt 4.2, s. 2 | |
| products.max_mg_per_kg_24h | `60` | „Maksymalna dawka dobowa paracetamolu: 60 mg/kg masy ciała/24 godz.” | ChPL 5104, pkt 4.2, s. 2 | spójność: 15 × 4 = 60 ≤ 60 |
| products.min_age_months | `3` | wiersz tabeli: „6 kg · 3,5 · 3 miesiące” | ChPL 5104, pkt 4.2, tabela, s. 1 | **Z6: decyzja użytkownika na podstawie tabeli ChPL** (< 3 mies. → block) |
| products.min_weight_kg | `6` | wiersz tabeli: „6 kg · 3,5 · 3 miesiące” | ChPL 5104, pkt 4.2, tabela, s. 1 | **Z6: decyzja użytkownika na podstawie tabeli ChPL** (< 6 kg → block) |
| products.max_weight_kg | `42` | ostatni wiersz tabeli: „42 kg · 26,0 · 12 lat” | ChPL 5104, pkt 4.2, tabela, s. 2 | **Z7: koniec tabeli ChPL → 42** (powyżej → block); D2 |
| products.warnings | zob. sekcja [warnings](#warnings) | | ChPL 5104, pkt 4.3, s. 2 | |
| products.source_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/5104/characteristic` | — | — | |
| products.checked_at | `2026-09-25` | — | — | |

### Nurofen dla dzieci Forte pomarańczowy 40 mg/ml (ChPL 33567)

| tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| products.id | `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | — | slug (D7) | |
| products.substance_id | `ibuprofen` | „Każdy 1 ml zawiesiny doustnej zawiera 40 mg ibuprofenu.” | ChPL 33567, pkt 2, s. 1 | |
| products.name_pl | `Nurofen dla dzieci Forte pomarańczowy, 40 mg/ml, zawiesina doustna` | „Nurofen dla dzieci Forte pomarańczowy, 40 mg/ml, zawiesina doustna” | ChPL 33567, pkt 1, s. 1 | |
| products.form | `oral_suspension` | „Zawiesina doustna.” | ChPL 33567, pkt 3, s. 1 | |
| products.strength_mg_per_ml | `40` | „Każdy 1 ml zawiesiny doustnej zawiera 40 mg ibuprofenu.” | ChPL 33567, pkt 2, s. 1 | CSV „Moc” = „40 mg/ml” |
| products.chpl_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic` | — | CSV, kolumna „Charakterystyka” | |
| products.chpl_text_date | `2025-04-23` | „23.04.2025” | ChPL 33567, pkt 10, s. 16 | |
| products.rule_type | `weight_band` | „Schemat dawkowania z zastosowaniem dołączonego do opakowania urządzenia odmierzającego może być osiągnięty następująco:” (tabela masa → dawka) | ChPL 33567, pkt 4.2, s. 1–2 | |
| products.dose_mg_per_kg | `null` | — | — | wymagane `null` dla `weight_band` (CHECK) |
| products.max_doses_24h | `3` | „3 razy” / „3 do 4 razy” | ChPL 33567, pkt 4.2, tabela, s. 1–2 | **ZAWĘŻENIE (Z3): ChPL maks. „3 do 4 razy” → 3** |
| products.max_mg_per_kg_24h | `30` | „dawka dobowa … wynosi 20 do 30 mg/kg masy ciała w dawkach podzielonych”; pkt 5.1: „maksymalnie 30 mg/kg mc./dobę” | ChPL 33567, pkt 4.2, s. 1; pkt 5.1, s. 13 | **Z4: sufit ChPL „20 do 30” → 30** |
| products.min_age_months | `3` | „Nie zaleca się stosowania u dzieci w wieku poniżej 3 miesięcy lub o masie ciała poniżej 5 kg.” | ChPL 33567, pkt 4.2, s. 2 | wprost z ChPL |
| products.min_weight_kg | `5` | jw. oraz wiersz tabeli „od 5 kg (3 do 5 miesięcy)” | ChPL 33567, pkt 4.2, s. 1–2 | wprost z ChPL |
| products.max_weight_kg | `40` | wiersz tabeli „30 do 40 kg (10 do12 lat)” | ChPL 33567, pkt 4.2, tabela, s. 2 | **Z7: koniec tabeli ChPL → 40** (powyżej → block); D2 |
| products.warnings | zob. sekcja [warnings](#warnings) | | ChPL 33567, pkt 4.3, s. 2–3 | |
| products.source_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33567/characteristic` | — | — | |
| products.checked_at | `2026-09-25` | — | — | |

### Nurofen dla dzieci Forte truskawkowy 40 mg/ml (ChPL 33568)

Pkt 2 (poza substancjami pomocniczymi), 3, 4.2, 4.3 i 10 mają tę samą treść co w wariancie pomarańczowym (porównanie tekstu obu PDF-ów: różnice tylko w nazwie, substancjach pomocniczych i łamaniu wierszy).

| tabela.kolumna | wartość | cytat (dosłowny, PL) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| products.id | `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | — | slug (D7) | |
| products.substance_id | `ibuprofen` | „Każdy 1 ml zawiesiny doustnej zawiera 40 mg ibuprofenu.” | ChPL 33568, pkt 2, s. 1 | |
| products.name_pl | `Nurofen dla dzieci Forte truskawkowy, 40 mg/ml, zawiesina doustna` | „Nurofen dla dzieci Forte truskawkowy, 40 mg/ml, zawiesina doustna” | ChPL 33568, pkt 1, s. 1 | |
| products.form | `oral_suspension` | „Zawiesina doustna.” | ChPL 33568, pkt 3, s. 1 | |
| products.strength_mg_per_ml | `40` | „Każdy 1 ml zawiesiny doustnej zawiera 40 mg ibuprofenu.” | ChPL 33568, pkt 2, s. 1 | CSV „Moc” = „40 mg/ml” |
| products.chpl_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic` | — | CSV, kolumna „Charakterystyka” | |
| products.chpl_text_date | `2025-04-23` | „23.04.2025” | ChPL 33568, pkt 10, s. 15 | |
| products.rule_type | `weight_band` | „Schemat dawkowania z zastosowaniem dołączonego do opakowania urządzenia odmierzającego może być osiągnięty następująco:” | ChPL 33568, pkt 4.2, s. 1–2 | |
| products.dose_mg_per_kg | `null` | — | — | wymagane `null` dla `weight_band` (CHECK) |
| products.max_doses_24h | `3` | „3 razy” / „3 do 4 razy” | ChPL 33568, pkt 4.2, tabela, s. 1–2 | **ZAWĘŻENIE (Z3): ChPL maks. „3 do 4 razy” → 3** |
| products.max_mg_per_kg_24h | `30` | „dawka dobowa … wynosi 20 do 30 mg/kg masy ciała w dawkach podzielonych”; pkt 5.1: „maksymalnie 30 mg/kg mc./dobę” | ChPL 33568, pkt 4.2, s. 1; pkt 5.1, s. 13 | **Z4: sufit ChPL „20 do 30” → 30** |
| products.min_age_months | `3` | „Nie zaleca się stosowania u dzieci w wieku poniżej 3 miesięcy lub o masie ciała poniżej 5 kg.” | ChPL 33568, pkt 4.2, s. 2 | wprost z ChPL |
| products.min_weight_kg | `5` | jw. oraz wiersz tabeli „od 5 kg (3 do 5 miesięcy)” | ChPL 33568, pkt 4.2, s. 1–2 | wprost z ChPL |
| products.max_weight_kg | `40` | wiersz tabeli „30 do 40 kg (10 do12 lat)” | ChPL 33568, pkt 4.2, tabela, s. 2 | **Z7: koniec tabeli ChPL → 40**; D2 |
| products.warnings | zob. sekcja [warnings](#warnings) | | ChPL 33568, pkt 4.3, s. 2–3 | |
| products.source_url | `https://rejestrymedyczne.ezdrowie.gov.pl/api/rpl/medicinal-products/33568/characteristic` | — | — | |
| products.checked_at | `2026-09-25` | — | — | |

## product_dose_bands

Tylko produkty `weight_band` (oba warianty Forte; Panadol jest `per_kg` i nie ma pasm). Pasma są ciągłe, `[weight_min_kg, weight_max_kg)`; ostatnie kończy się na `products.max_weight_kg` = 40. Tabela ChPL jest identyczna w 33567 (s. 1–2) i 33568 (s. 1–2), odczytana wzrokowo z renderu stron.

| product_dose_bands.product_id | product_dose_bands.weight_min_kg | product_dose_bands.weight_max_kg | product_dose_bands.dose_mg | product_dose_bands.max_doses_24h | cytat (dosłowny, PL) | źródło | uwagi |
|---|---|---|---|---|---|---|---|
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 5 | 7 | 50 | 3 | „od 5 kg (3 do 5 miesięcy) · 1 x 50 mg/1,25 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33567, pkt 4.2, s. 1 | **Z5: ChPL „od 5 kg” (bez górnej granicy) → [5, 7)** |
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 7 | 10 | 50 | 3 | „7 do 9 kg (6 do 11 miesięcy) · 1 x 50 mg/1,25 ml (jednorazowe użycie strzykawki) · 3 do 4 razy” | ChPL 33567, pkt 4.2, s. 1 | **Z2: ChPL „3 do 4 razy” → 3**; **Z5: ChPL „7 do 9 kg” → [7, 10)** (luka 9–10 kg → niższe pasmo) |
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 10 | 16 | 100 | 3 | „10 do 15 kg (1 rok do 3 lat) · 1 x 100 mg/2,5 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33567, pkt 4.2, s. 1 | **Z5: ChPL „10 do 15 kg” → [10, 16)** |
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 16 | 20 | 150 | 3 | „16 do 19 kg (4 do 5 lat) · 1 x 150 mg/3,75 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33567, pkt 4.2, s. 1 | **Z5: ChPL „16 do 19 kg” → [16, 20)** |
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 20 | 30 | 200 | 3 | „20 do 29 kg (6 do 9 lat) · 1 x 200 mg/5 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33567, pkt 4.2, s. 2 | **Z5: ChPL „20 do 29 kg” → [20, 30)** |
| `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 30 | 40 | 300 | 3 | „30 do 40 kg (10 do12 lat) · 1 x 300 mg/7,5 ml (użycie strzykawki) · 3 razy” | ChPL 33567, pkt 4.2, s. 2 | koniec = `max_weight_kg`; D2 (40,0 kg) |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 5 | 7 | 50 | 3 | „od 5 kg (3 do 5 miesięcy) · 1 x 50 mg/1,25 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33568, pkt 4.2, s. 1 | **Z5: ChPL „od 5 kg” → [5, 7)** |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 7 | 10 | 50 | 3 | „7 do 9 kg (6 do 11 miesięcy) · 1 x 50 mg/1,25 ml (jednorazowe użycie strzykawki) · 3 do 4 razy” | ChPL 33568, pkt 4.2, s. 1 | **Z2: ChPL „3 do 4 razy” → 3**; **Z5: ChPL „7 do 9 kg” → [7, 10)** |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 10 | 16 | 100 | 3 | „10 do 15 kg (1 rok do 3 lat) · 1 x 100 mg/2,5 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33568, pkt 4.2, s. 1 | **Z5: ChPL „10 do 15 kg” → [10, 16)** |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 16 | 20 | 150 | 3 | „16 do 19 kg (4 do 5 lat) · 1 x 150 mg/3,75 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33568, pkt 4.2, s. 1 | **Z5: ChPL „16 do 19 kg” → [16, 20)** |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 20 | 30 | 200 | 3 | „20 do 29 kg (6 do 9 lat) · 1 x 200 mg/5 ml (jednorazowe użycie strzykawki) · 3 razy” | ChPL 33568, pkt 4.2, s. 2 | **Z5: ChPL „20 do 29 kg” → [20, 30)** |
| `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 30 | 40 | 300 | 3 | „30 do 40 kg (10 do12 lat) · 1 x 300 mg/7,5 ml (użycie strzykawki) · 3 razy” | ChPL 33568, pkt 4.2, s. 2 | koniec = `max_weight_kg`; D2 |

Wiek w nawiasach tabeli ChPL nie trafia do pasm: pasmo wybiera wyłącznie masa, a wiek działa tylko jako `products.min_age_months = 3`.

### Spójność pasm z sufitem dobowym

Warunek: `dose_mg × max_doses_24h ≤ max_mg_per_kg_24h (30) × weight_min_kg`. Ten sam wynik dla obu wariantów.

| pasmo | dose_mg × max_doses_24h | 30 × weight_min_kg | wynik | mg/kg na dawkę (przy weight_min_kg) |
|---|---|---|---|---|
| [5, 7) | 50 × 3 = 150 | 150 | OK (równość) | 10,0 |
| [7, 10) | 50 × 3 = 150 | 210 | OK | 7,1 |
| [10, 16) | 100 × 3 = 300 | 300 | OK (równość) | 10,0 |
| [16, 20) | 150 × 3 = 450 | 480 | OK | 9,4 |
| [20, 30) | 200 × 3 = 600 | 600 | OK (równość) | 10,0 |
| [30, 40) | 300 × 3 = 900 | 900 | OK (równość) | 10,0 |

**Naruszeń: 0.** Żadne pasmo nie przekracza też „od 7 do 10 mg/kg masy ciała na dawkę” (ChPL 33567 i 33568, pkt 5.1, s. 13) przy swojej dolnej masie. Uwaga: gdyby w paśmie 7–9 kg przyjąć 4 dawki (górny koniec ChPL), wyszłoby 200 ≤ 210, więc warunek też byłby spełniony. Zawężenie Z2 wynika z zasady „koniec ostrożniejszy”, nie z sufitu.

Panadol (`per_kg`): 15 mg/kg × 4 = 60 mg/kg ≤ 60, spójne.

## product_barcodes

Źródło: CSV RPL, kolumna „Opakowanie” (format `GTIN ¦ kategoria ¦ [status ¦] id opakowania`, w następnej linii wielkość). CSV pobrany 2026-09-25 23:37 CEST. Brak słowa „Skasowane” oznacza opakowanie aktywne.

| product_barcodes.gtin | product_barcodes.product_id | product_barcodes.package_ml | cytat (CSV „Opakowanie”, dosłownie) | status | product_barcodes.source_url | product_barcodes.checked_at |
|---|---|---|---|---|---|---|
| `05909991447175` | `panadol-dla-dzieci-120mg-5ml` | 60 | „05909991447175 ¦ OTC ¦ 139100 / 1 butelka 60 ml” | aktywne | `https://rejestry.ezdrowie.gov.pl/api/rpl/medicinal-products/public-pl-report/get-csv` | `2026-09-25` |
| `05909990327317` | `panadol-dla-dzieci-120mg-5ml` | 100 | „05909990327317 ¦ OTC ¦ 43832 / 1 butelka 100 ml” | aktywne | jw. | `2026-09-25` |
| `05909991447168` | `panadol-dla-dzieci-120mg-5ml` | 200 | „05909991447168 ¦ OTC ¦ 139099 / 1 butelka 200 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222833` | `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 100 | „05909991222833 ¦ OTC ¦ 108514 / 1 butelka 100 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222840` | `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 150 | „05909991222840 ¦ OTC ¦ 108515 / 1 butelka 150 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222857` | `nurofen-dla-dzieci-forte-pomaranczowy-40mg-ml` | 200 | „05909991222857 ¦ OTC ¦ 108516 / 1 butelka 200 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222970` | `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 100 | „05909991222970 ¦ OTC ¦ 108528 / 1 butelka 100 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222987` | `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 150 | „05909991222987 ¦ OTC ¦ 108529 / 1 butelka 150 ml” | aktywne | jw. | `2026-09-25` |
| `05909991222994` | `nurofen-dla-dzieci-forte-truskawkowy-40mg-ml` | 200 | „05909991222994 ¦ OTC ¦ 108530 / 1 butelka 200 ml” | aktywne | jw. | `2026-09-25` |

Wiersze CSV: Panadol (ID RPL 100051046, „Charakterystyka” → `…/5104/characteristic`), Forte pomarańczowy (100335677 → `…/33567/characteristic`), Forte truskawkowy (100335683 → `…/33568/characteristic`). Wielkości aktywnych opakowań mieszczą się w pkt 6.5 ChPL (Panadol: „Opakowania: 60 ml, 100 ml, 200 ml.”, s. 7; Forte: „Butelka zawiera 30 ml, 50 ml, 100 ml, 150 ml lub 200 ml zawiesiny doustnej.”, s. 15).

**Wykluczone** (status „Skasowane” albo import równoległy):

| GTIN | produkt | cytat CSV | powód |
|---|---|---|---|
| `05909990327331` | Panadol | „05909990327331 ¦ Lz ¦ Skasowane ¦ 7657 / 1 op. 1000 ml” | Skasowane |
| `05909990327324` | Panadol | „05909990327324 ¦ Lz ¦ Skasowane ¦ 15521 / 1 op. 300 ml” | Skasowane |
| `05909991222819` | Forte pomarańczowy | „05909991222819 ¦ OTC ¦ Skasowane ¦ 108512 / 1 butelka 30 ml” | Skasowane |
| `05909991222826` | Forte pomarańczowy | „05909991222826 ¦ OTC ¦ Skasowane ¦ 108513 / 1 butelka 50 ml” | Skasowane |
| `05909991222956` | Forte truskawkowy | „05909991222956 ¦ OTC ¦ Skasowane ¦ 108526 / 1 butelka 30 ml” | Skasowane |
| `05909991222963` | Forte truskawkowy | „05909991222963 ¦ OTC ¦ Skasowane ¦ 108527 / 1 butelka 50 ml” | Skasowane |
| różne (np. `05909991385170`, `05902023773914`) | Forte, import równoległy (IR) | osobne wiersze CSV z własnym ChPL (np. `…/41153/characteristic`) | ChPL niezweryfikowane (D4) |

## substance_pair_rules

| tabela.kolumna | wartość | cytat (dosłowny) | źródło (URL, sekcja/strona) | uwagi |
|---|---|---|---|---|
| substance_pair_rules.substance_a | `ibuprofen` | — | kontrakt fazy 1 | `'ibuprofen' < 'paracetamol'` (CHECK `substance_a < substance_b`) |
| substance_pair_rules.substance_b | `paracetamol` | — | kontrakt fazy 1 | |
| substance_pair_rules.rule | `block_until_previous_interval` | „Nie zalecamy naprzemiennego stosowania ibuprofenu i paracetamolu.” | PTP 2024, streszczenie na stronie PTP | decyzja użytkownika z research §6 (2026-09-25). Druga substancja dostaje block, dopóki nie minął `substances.min_interval_hours` substancji podanej poprzednio (paracetamol 4 h, ibuprofen 8 h) |
| substance_pair_rules.message_pl | `Naprzemienne podawanie tylko po konsultacji z lekarzem.` | NHS (EN): „do not alternate ibuprofen and paracetamol, unless a health professional such as a doctor or nurse tells you to” | https://www.nhs.uk/conditions/fever-in-children/ | tekst decyzji z research §6 (D6); cytat NHS po angielsku, bo źródło jest anglojęzyczne |
| substance_pair_rules.source_urls | `{https://ptp.edu.pl/najnowsze-zalecenia-dotyczace-leczenia-przeciwgoraczkowego-u-dzieci-w-wieku-0-36-miesiecy/, https://www.nhs.uk/conditions/fever-in-children/}` | — | research §6 | oba cytaty sprawdzone ponownie 2026-09-25. Pełny tekst PTP jest za paywallem. Streszczenie PTP dodaje: „W niektórych sytuacjach klinicznych możliwe jest jednoczesne podawanie obu leków.” Reguła tego nie uwzględnia, bo bez lekarza obowiązuje block |
| substance_pair_rules.checked_at | `2026-09-25` | — | — | |

Kontekst (bez wpływu na dane): ChPL 5104 pkt 4.5, s. 3: „Skojarzone podawanie paracetamolu i niesteroidowych leków przeciwzapalnych zwiększa ryzyko wystąpienia zaburzeń czynności nerek.” ChPL Forte (oba warianty) nie wspomina o paracetamolu (0 trafień w tekście).

## warnings

`products.warnings` to `text[]`: krótkie teksty po polsku z pkt 4.3 oraz — po decyzji D5 z 2026-09-26 — z pkt 4.2 i 4.4. Kolejność elementów tablicy jak w tabelach poniżej. Ostrzeżenia nie wpływają na allow/block; S-02 wyświetla je przy odpowiedzi bramki.

### products.warnings: Panadol (`panadol-dla-dzieci-120mg-5ml`)

| # | wartość (element tablicy) | cytat (dosłowny, PL) | źródło | uwagi |
|---|---|---|---|---|
| 1 | `Nie stosować przy nadwrażliwości na paracetamol lub którąkolwiek substancję pomocniczą.` | „Znana nadwrażliwość na paracetamol lub na którąkolwiek substancję pomocniczą wymienioną w punkcie 6.1” | ChPL 5104, pkt 4.3, s. 2 | |
| 2 | `Nie stosować przy ciężkiej niewydolności wątroby lub nerek.` | „Ciężka niewydolność wątroby lub nerek.” | ChPL 5104, pkt 4.3, s. 2 | |
| 3 | `Bez konsultacji z lekarzem nie stosować regularnie dłużej niż 3 dni.` | „Bez konsultacji z lekarzem leku nie należy stosować regularnie dłużej niż przez 3 dni.” | ChPL 5104, pkt 4.2 | D5 (2026-09-26) |
| 4 | `Nie stosować przy dziedzicznej nietolerancji fruktozy (zawiera maltitol i sorbitol).` | „Ze względu na zawartość maltitolu i sorbitolu, produktu nie należy stosować u pacjentów z rzadko występującą dziedziczną nietolerancją fruktozy.” | ChPL 5104, pkt 4.4 | D5 (2026-09-26) |

### products.warnings: Forte pomarańczowy i truskawkowy (ta sama tablica dla obu produktów)

| # | wartość (element tablicy) | cytat (dosłowny, PL) | źródło | uwagi |
|---|---|---|---|---|
| 1 | `Nie stosować przy nadwrażliwości na ibuprofen lub którąkolwiek substancję pomocniczą.` | „U pacjentów z nadwrażliwością na substancję czynną lub na którąkolwiek substancję pomocniczą wymienioną w punkcie 6.1.” | ChPL 33567 / 33568, pkt 4.3, s. 2 | |
| 2 | `Nie stosować, jeśli po kwasie acetylosalicylowym, ibuprofenie lub innym NLPZ wystąpiły reakcje nadwrażliwości (np. skurcz oskrzeli, astma, pokrzywka, obrzęk).` | „U pacjentów, u których w wywiadzie występowały reakcje nadwrażliwości (np. skurcz oskrzeli, astma, nieżyt błony śluzowej nosa, obrzęk naczynioruchowy lub pokrzywka) powiązane z przyjmowaniem kwasu acetylosalicylowego, ibuprofenu lub innych niesteroidowych leków przeciwzapalnych (NLPZ).” | ChPL 33567 s. 2–3 / 33568 s. 2, pkt 4.3 | |
| 3 | `Nie stosować po krwawieniu lub perforacji przewodu pokarmowego związanych z wcześniejszym leczeniem NLPZ.` | „U pacjentów, u których w wywiadzie wystąpiło krwawienie lub perforacja przewodu pokarmowego powiązane z wcześniejszą terapią lekami z grupy NLPZ.” | ChPL 33567 / 33568, pkt 4.3, s. 3 | |
| 4 | `Nie stosować przy czynnej lub nawracającej chorobie wrzodowej żołądka lub dwunastnicy albo krwotoku.` | „U pacjentów z czynną lub nawracającą w wywiadzie chorobą wrzodową żołądka i (lub) dwunastnicy lub z krwotokiem (dwa lub więcej niezależnych, potwierdzonych przypadków owrzodzenia lub krwawienia).” | ChPL 33567 / 33568, pkt 4.3, s. 3 | |
| 5 | `Nie stosować przy krwawieniu z naczyń mózgowych lub innym czynnym krwawieniu.` | „U pacjentów z krwawieniem z naczyń-mózgowych lub z innym czynnym krwawieniem.” | ChPL 33567 / 33568, pkt 4.3, s. 3 | |
| 6 | `Nie stosować przy ciężkiej niewydolności wątroby, nerek lub serca.` | „U pacjentów z ciężką niewydolnością wątroby, ciężką niewydolnością nerek”; „U pacjentów z ciężką niewydolnością serca klasa (IV wg NYHA)” | ChPL 33567 / 33568, pkt 4.3, s. 3 | dwa punkty ChPL połączone w jeden tekst |
| 7 | `Nie stosować przy zaburzeniach wytwarzania krwi o nieustalonym pochodzeniu.` | „U pacjentów z zaburzeniami wytwarzania krwi o nieustalonym pochodzeniu.” | ChPL 33567 / 33568, pkt 4.3, s. 3 | |
| 8 | `Nie stosować przy ciężkim odwodnieniu (wymioty, biegunka, zbyt mało płynów).` | „U pacjentów z ciężkim odwodnieniem (wywołanym wymiotami, biegunką lub niewystarczającym spożyciem płynów).” | ChPL 33567 / 33568, pkt 4.3, s. 3 | |
| 9 | `U dzieci 3–5 mies.: skonsultuj z lekarzem, jeśli objawy nasilają się lub nie ustępują po 24 godzinach.` | „W przypadku dzieci w wieku 3 - 5 miesięcy, należy zasięgnąć porady lekarza, jeśli objawy nasilają się lub jeśli nie ustępują po 24 godzinach.” | ChPL 33567 / 33568, pkt 4.2 | D5 (2026-09-26) |
| 10 | `U dzieci od 6 mies. do 12 lat: skonsultuj z lekarzem, jeśli lek jest potrzebny dłużej niż 3 dni lub objawy się nasilają.` | „W przypadku dzieci (w wieku ≥ 6 miesięcy do ≤ 12 lat), należy zasięgnąć porady lekarza, jeśli podawanie tego produktu leczniczego jest konieczne przez więcej niż 3 dni lub jeśli objawy ulegają nasileniu.” | ChPL 33567 / 33568, pkt 4.2 | D5 (2026-09-26); znaki ≥/≤ potwierdzone w ekstrakcji UTF-8 ChPL |

Pominięte z pkt 4.3 Forte: „W trzecim trymestrze ciąży (patrz punkt 4.6).”, bo nie dotyczy dzieci (D5).

## Pokrycie kolumn schematu

Wszystkie kolumny tabel katalogu z migracji `20260925212010_medication_catalog.sql` mają wiersz w tym dokumencie, także `id` i FK (`products.substance_id`, `product_dose_bands.product_id`, `product_barcodes.product_id`, `substance_pair_rules.substance_a/b`), bo faza 3 potrzebuje ich wartości. Sprawdzone skryptem Node w scratchpadzie (`coverage-check.js`) na `information_schema.columns` lokalnej bazy: **0 braków**.
