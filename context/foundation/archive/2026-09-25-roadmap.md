# Roadmap

Termin zgłoszenia projektu: **4 listopada 2026, 23:59**. Harmonogram mieszany —
część pracy po godzinach, część równolegle z pracą etatową.

## Faza 1 — MVP (≈3 tygodnie)

Zakres zgodny z `prd.md`: logowanie i gospodarstwo domowe, profil dziecka,
identyfikacja leku (kod kreskowy lub lista popularnych), bramka allow/wait/block
z wyliczeniem dawki, log podań widoczny dla wszystkich domowników.

Wyjście: wdrożony, działający przepływ z `## Success Criteria` + dokumenty
kontekstowe + testy weryfikujące działanie z perspektywy użytkownika.

## Faza 2 — rozbudowa architektury (po MVP)

**Offline-first i detekcja podwójnego podania.** W v1 świadomy non-goal; tutaj
wraca jako główna praca architektoniczna, bo wynika z domeny: o 3:00 w łazience
nie ma zasięgu, a dwoje opiekunów offline może podać tę samą substancję w oknie
odstępu. Rozwiązanie konfliktu synchronizacji jest tu decyzją o bezpieczeństwie,
nie techniczną ciekawostką — aplikacja nie scala takich zapisów po cichu, tylko
sygnalizuje podwójne podanie i przelicza bramkę od wcześniejszej dawki.

## Faza 3 — automatyzacja i praca zespołowa (po MVP)

Pipeline CI/CD: lint → typecheck → testy jednostkowe → build → testy integracyjne.
Agent wykonujący wstępne review pull requestów wg reguł projektu.

Wzorzec sprawdzony w projektach z poprzednich edycji: krok integracyjny bez
zmiennych środowiskowych jest **pomijany, nie failowany** — brak sekretów
w forku nie może wywracać pipeline'u.

## Wraca później (non-goals v1)

| Odłożone | Kiedy wraca |
|---|---|
| Skan opakowania i OCR ulotki przez AI | po MVP; wymaga evalów i bramki potwierdzenia przez człowieka |
| Powiadomienia push o następnej dawce | po MVP; w v1 wystarcza wspólna widoczność w aplikacji |
| Edycja i usuwanie zapisanych podań | gdy pojawi się realna potrzeba; patrz Open Question 6 w `prd.md` |
| Pacjenci dorośli | dawkowanie wg masy ciała ma sens głównie u dzieci; patrz Open Question 3 |

## Dług do spłacenia przy zgłoszeniu

- `decisions-log.md` — log ustaleń na powrót po przerwie, zakładany od razu.
- Mapowanie wymagań na konkretne ścieżki w `README.md`, żeby oceniający
  nie musiał niczego szukać.
- `test-plan.md` wymieniający także ryzyka **bez** automatycznego pokrycia,
  nie tylko te pokryte.
