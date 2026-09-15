# Projekt zaliczeniowy 10xDevs 4.0

Greenfield. Termin zgłoszenia: 4 listopada 2026.

## Dane osobowe

Repozytorium jest publiczne, a domena aplikacji obejmuje dane o zdrowiu.
W śledzonych plikach nigdy nie umieszczaj danych prawdziwych — seed, fixtures,
testy i zrzuty ekranu wyłącznie na danych syntetycznych.
Sekrety tylko w `.env` i GitHub Secrets, nigdy w repo.

## Łańcuch pracy

```
/10x-init → /10x-shape → /10x-prd → /10x-tech-stack-selector → /10x-bootstrapper
          → /10x-agents-md → /10x-rule-review → /10x-infra-research → deploy (Plan Mode)
```

Każdy krok konsumuje artefakt poprzedniego. Wcześniejszy krok można uruchomić
ponownie, żeby poprawić kontrakt w trakcie pracy.

## Kontrakty w `context/`

| Ścieżka | Właściciel | Rola |
|---|---|---|
| `foundation/prd.md` | `/10x-prd` | wymagania produktowe |
| `foundation/tech-stack.md` | `/10x-tech-stack-selector` | twarde ograniczenia dla infry |
| `foundation/infrastructure.md` | `/10x-infra-research` | wybór platformy + rejestr ryzyk |
| `foundation/lessons.md` | `/10x-lesson` | powtarzalne pułapki, dopisywane |
| `deployment/deploy-plan.md` | Plan Mode | ścieżka audytowa wdrożenia |
| `changes/<change-id>/` | — | zmiany w toku |
| `archive/` | — | **niezmienne, nigdy tu nie zapisuj** |

Dokumenty fundamentowe edytuje się w miejscu. Bez datowanych kopii; dokument
całkowicie zastąpiony ląduje w `foundation/archive/YYYY-MM-DD-<nazwa>.md`.

## PRD celowo nie zawiera stacku

Framework, baza danych i platforma hostingowa **nie są** decyzjami PRD — wybiera je
`/10x-tech-stack-selector` po zamknięciu PRD. Nie deklaruj ich wcześniej.

## Miękkie bramki podczas kształtowania

- **Empty-CRUD** — „dodaj, wylistuj, edytuj, usuń" bez reguły domenowej. Aplikacja
  musi coś *decydować* za użytkownika: rekomendacja, priorytetyzacja, klasyfikacja,
  walidacja, scoring, workflow albo obliczenie.
- **MVP-too-big** — pierwszy przepływ dłuższy niż ~tydzień pracy po godzinach,
  więcej niż ~4 działania przed widoczną wartością, albo kilka integracji przed
  jakimkolwiek efektem.

Obie ostrzegają, żadna nie blokuje. Nadpisanie trafia do `## Open Questions` w PRD.

## Dostęp do produkcji

- Tokeny ograniczone zakresem do jednego projektu, nigdy klucze główne.
- Tokeny w zmiennych środowiskowych, nie w plikach commitowanych do repo.
- **Działania nieodwracalne wykonuje człowiek** — usunięcie bazy, rotacja sekretu,
  skasowanie projektu. Ręczne kliknięcie kosztuje 30 sekund, sprzątanie po
  automatycznym błędzie kosztuje godziny.
- Zacznij od CLI. MCP dodawaj dopiero, gdy zauważysz powtarzalny wzorzec
  przechodzenia przez `--help`, który agent musi wykonywać.

Przed zamknięciem decyzji o platformie uruchom trzy perspektywy: adwokat diabła
(3–5 konkretnych słabości), pre-mortem (narracja porażki po pół roku),
niewiadome niewiadome (czego nie widać w dokumentacji).

## Reguły kursowe

Powyższe to destylat. Pełny blok reguł 10xDevs to materiał płatnego kursu i nie
trafia do repozytorium — pobierz go własnym kontem:
`npx @przeprogramowani/10x-cli get m1l5`.
Przy kolejnych pobraniach dodaj `--no-course-rules`, żeby CLI nie wstawiło bloku
z powrotem do tego pliku.

@.claude/10x-course-rules.md
