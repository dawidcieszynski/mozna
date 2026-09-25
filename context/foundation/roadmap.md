---
project: "Można?"
version: 1
status: draft
created: 2026-09-25
updated: 2026-09-25
prd_version: 1
main_goal: speed
top_blocker: decisions
milestone_id: first-shared-night-dose
milestone_seq: 1
milestone_status: open
---

# Roadmap: Można?

> Derived from `context/foundation/prd.md` (v1) + auto-researched codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Milestone

**M-1: Pierwsza wspólna nocna dawka** — Status: open

- **Intent:** Dwoje opiekunów z jednego gospodarstwa przechodzi pełny przepływ z US-01: wybór dziecka → identyfikacja leku → odpowiedź bramki i dawka → zapis podania, a drugi opiekun widzi, że dawkę podano i kiedy wolno następną.
- **Source materials:** `context/foundation/prd.md` (v1)
- **Done when:** every F-NN and S-NN below is `done`.
- **Scope anchors:** FR-001–FR-008, US-01.

## Vision recap

O 3:00 dziecko ma gorączkę, a ostatnią dawkę podał ktoś inny w domu — nie wiadomo kiedy i czego. Kalkulatorów dawkowania są setki; brakuje wspólnego logu domu. Wyróżnik produktu (cecha, bez której byłby kolejnym kalkulatorem): wszyscy domownicy widzą tę samą historię podań i tę samą odpowiedź bramki allow / wait / block.

## North star

**S-04: Drugi opiekun w gospodarstwie widzi, że dawkę podano i kiedy wolno podać następną** — to jest dowód wyróżnika produktu i główne kryterium sukcesu PRD; przy celu `speed` wszystko, co nie prowadzi do tego momentu, czeka.

> „North star” (gwiazda przewodnia) to tutaj najmniejszy kompletny przepływ, którego działanie dowodzi głównej hipotezy produktu — ustawiony tak wcześnie, jak pozwalają zależności, bo reszta ma znaczenie tylko wtedy, gdy on działa.

## At a glance

| ID   | Change ID                     | Outcome (user can …)                                                                 | Prerequisites | PRD refs                    | Status   |
| ---- | ----------------------------- | ------------------------------------------------------------------------------------ | ------------- | --------------------------- | -------- |
| F-01 | seed-medication-catalog       | (foundation) katalog popularnych substancji z regułami dawkowania i źródłami ChPL jest w bazie | —             | FR-004, FR-005, Success Criteria (Secondary), NFR (deterministyczna bramka), Non-Goals (brak edytora reguł) | in-progress |
| S-01 | household-with-child          | opiekun zakłada gospodarstwo i dodaje dziecko z wagą i wiekiem, a potem je wybiera   | —             | FR-001, FR-002, Access Control | done |
| S-02 | gate-from-popular-list        | opiekun wybiera dziecko i lek z listy i widzi allow / wait / block oraz dawkę        | S-01, F-01    | FR-004, FR-005, US-01, NFR (odpowiedź poniżej ~1 s, deterministyczna bramka), Guardrails (brak fałszywego allow) | proposed |
| S-03 | record-administration         | opiekun zapisuje podanie i widzi historię podań gospodarstwa; bramka ją uwzględnia   | S-02          | FR-006, FR-007, US-01       | proposed |
| S-04 | second-caregiver-sees-dose    | drugi opiekun dołącza do gospodarstwa i widzi, że dawkę podano i kiedy wolno następną | S-03          | FR-001, FR-008, US-01, Success Criteria (Primary), Access Control (płaskie członkostwo) | proposed |
| S-05 | barcode-identification        | opiekun identyfikuje lek, skanując kod kreskowy opakowania                           | S-02, F-01    | FR-003                      | proposed |

## Streams

Navigation aid — groups items that share a Prerequisites chain. Canonical ordering still lives in the dependency graph below; this table is the proposed reading order across parallel tracks.

| Stream | Theme                 | Chain                                  | Note                                                                 |
| ------ | --------------------- | -------------------------------------- | -------------------------------------------------------------------- |
| A      | Katalog, bramka i log | `F-01` → `S-02` → `S-03` → `S-04`      | Ścieżka do gwiazdy przewodniej; przy celu `speed` to jest kręgosłup. |
| B      | Dom i dziecko         | `S-01`                                 | Startuje od razu, równolegle z F-01; dołącza do strumienia A w S-02. |
| C      | Kod kreskowy          | `S-05`                                 | Odgałęzienie od S-02; może iść równolegle z S-03 / S-04.             |

## Baseline

What's already in place in the codebase as of `2026-09-25` (auto-researched + user-confirmed).
Foundations below assume these are present and do NOT re-scaffold them.

- **Frontend:** present — Astro SSR + React islands, Tailwind, shadcn/ui; strony wciąż szablonowe (`src/pages/index.astro`, `src/pages/dashboard.astro`).
- **Backend / API:** present — trasy API Astro, na razie tylko auth (`src/pages/api/auth/*`).
- **Data:** absent — brak schematu i migracji (`supabase/` zawiera tylko `config.toml`); jest klient `src/lib/supabase.ts`.
- **Auth:** present — Supabase e-mail/hasło, sesje w cookies, ochrona tras w `src/middleware.ts`; zweryfikowane na produkcji. Brak gospodarstwa i członkostwa.
- **Deploy / infra:** present — Worker `mozna` na `https://mozna.cieszy-ski.workers.dev` (`context/deployment/deploy-plan.md`), CI w `.github/workflows/ci.yml` na `github.com/dawidcieszynski/mozna` (pierwszy przebieg zielony 2026-09-25: lint, check, build, smoke auth); brak auto-deployu.
- **Observability:** partial — Workers observability włączone w `wrangler.jsonc`, `wrangler tail`; brak logowania błędów po stronie aplikacji.

## Foundations

### F-01: Minimalny katalog substancji

- **Outcome:** (foundation) w bazie jest katalog popularnych substancji z regułami potrzebnymi bramce (odstęp między dawkami, limit dobowy, dawka zależna od wagi i wieku) wraz ze wskazaniem cytowanego źródła ChPL dla każdej reguły.
- **Change ID:** seed-medication-catalog
- **PRD refs:** FR-004, FR-005, Success Criteria (Secondary), NFR (deterministyczna bramka), Non-Goals (brak edytora reguł)
- **Unlocks:** S-02 (bramka nie ma z czego liczyć bez reguł), S-05 (mapowania kodów kreskowych wskazują pozycje katalogu)
- **Prerequisites:** —
- **Parallel with:** S-01
- **Blockers:** —
- **Unknowns:**
  - Wartość odstępu przy naprzemiennym podawaniu paracetamolu i ibuprofenu (decyzja: bramka go pilnuje) — Owner: user. Block: no (rozstrzygnie `/10x-plan`).
- **Risk:** Katalog jest minimalny (tyle substancji, ile obejmuje typowa noc), nie kompletny; ryzykiem jest reguła przepisana z błędem, która prowadzi do fałszywego allow — dlatego każda reguła ma źródło.
- **Status:** in-progress

## Slices

### S-01: Gospodarstwo z dzieckiem

- **Outcome:** Opiekun po zalogowaniu zakłada gospodarstwo, dodaje dziecko z wagą i wiekiem i wybiera je z listy dzieci gospodarstwa.
- **Change ID:** household-with-child
- **PRD refs:** FR-001, FR-002, Access Control
- **Prerequisites:** —
- **Parallel with:** F-01
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Pierwszy wycinek z danymi zdrowotnymi — tu powstaje granica gospodarstwa w bazie; błąd izolacji na tym etapie przecieka do każdego kolejnego wycinka, więc idzie pierwszy i niezależnie od katalogu.
- **Status:** done

### S-02: Bramka dla leku z listy

- **Outcome:** Opiekun wybiera dziecko i lek z listy popularnych i widzi odpowiedź allow / wait (do kiedy) / block (z powodami) oraz dawkę; bez wagi lub wieku produkt nie zwraca allow ani dawki.
- **Change ID:** gate-from-popular-list
- **PRD refs:** FR-004, FR-005, US-01, NFR (odpowiedź poniżej ~1 s, deterministyczna bramka), Guardrails (brak fałszywego allow)
- **Prerequisites:** S-01, F-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Rdzeń logiki domenowej; fałszywe allow to regresja z Guardrails, więc wycinek dostarcza też automatyczną weryfikację reguły, zanim zbuduje się na niej zapis podań.
- **Status:** proposed

### S-03: Zapis podania i historia

- **Outcome:** Opiekun zapisuje podanie po odpowiedzi bramki i widzi historię podań gospodarstwa (z naciskiem na ostatnią dawkę); kolejna odpowiedź bramki uwzględnia ten zapis.
- **Change ID:** record-administration
- **PRD refs:** FR-006, FR-007, US-01
- **Prerequisites:** S-02
- **Parallel with:** S-05
- **Blockers:** —
- **Unknowns:**
  - Czy zapisane podanie można edytować lub usunąć? (PRD Open Question 6) — Owner: user. Block: no (MVP: tylko zapis i odczyt).
- **Risk:** Zapis to jedyna operacja zmieniająca wspólny stan; sekwencjonowany po bramce, żeby wait liczyło się od rzeczywistych podań, a nie od danych testowych.
- **Status:** proposed

### S-04: Drugi opiekun widzi podaną dawkę

- **Outcome:** Drugi opiekun dołącza do istniejącego gospodarstwa i przy tym samym dziecku i leku widzi, że dawkę podano i kiedy wolno podać następną.
- **Change ID:** second-caregiver-sees-dose
- **PRD refs:** FR-001, FR-008, US-01, Success Criteria (Primary), Access Control (płaskie członkostwo)
- **Prerequisites:** S-03
- **Parallel with:** S-05
- **Blockers:** —
- **Unknowns:**
  - W jaki sposób drugi opiekun dołącza do gospodarstwa (zaproszenie, kod)? — Owner: user. Block: no (rozstrzygnie `/10x-plan`).
- **Risk:** Gwiazda przewodnia; ustawiona tuż po zapisie podań, bo dopiero wspólny stan dwóch kont dowodzi wyróżnika — pierwsze miejsce, gdzie wychodzi błąd izolacji między gospodarstwami.
- **Status:** proposed

### S-05: Identyfikacja leku kodem kreskowym

- **Outcome:** Opiekun skanuje kod kreskowy opakowania i trafia do tej samej odpowiedzi bramki co przy wyborze z listy.
- **Change ID:** barcode-identification
- **PRD refs:** FR-003
- **Prerequisites:** S-02, F-01
- **Parallel with:** S-03, S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Druga ścieżka wejścia do tej samej bramki; poza drogą do gwiazdy przewodniej, więc przy celu `speed` nie blokuje S-03 / S-04.
- **Status:** proposed

## Backlog Handoff

| Roadmap ID | Change ID                  | Suggested issue title                                        | Ready for `/10x-plan` | Notes |
| ---------- | -------------------------- | ------------------------------------------------------------ | --------------------- | ----- |
| F-01       | seed-medication-catalog    | Katalog popularnych substancji z regułami i źródłami ChPL    | yes                   | Run `/10x-plan seed-medication-catalog`; research gotowy |
| S-01       | household-with-child       | Gospodarstwo i dziecko z wagą i wiekiem                      | yes                   | Run `/10x-plan household-with-child` |
| S-02       | gate-from-popular-list     | Bramka allow/wait/block i dawka dla leku z listy             | no                    | Po S-01 i F-01 |
| S-03       | record-administration      | Zapis podania i historia gospodarstwa                        | no                    | Po S-02 |
| S-04       | second-caregiver-sees-dose | Drugi opiekun widzi podaną dawkę i następny termin           | no                    | Po S-03 |
| S-05       | barcode-identification     | Identyfikacja leku kodem kreskowym                           | no                    | Po S-02 i F-01 |

## Open Roadmap Questions

1. **Final product name?** — Working title is „Można?". Owner: user. Block: —.
2. **Which substances and citeable ChPL sources seed the popular catalog / barcode mappings?** — Owner: user. Block: —. Rozstrzygnięte 2026-09-25 (PRD Open Question 2, `context/changes/seed-medication-catalog/research.md`).
3. **Are patients children only, or adults too?** — Owner: user. Block: — (v1 skupia się na dzieciach).
4. **Legal disclaimer wording** (register/calculator, not a medical device, does not replace a clinician) before any public URL — Owner: user. Block: — ; uwaga: adres `*.workers.dev` jest już publiczny, więc treść powinna trafić na stronę najpóźniej z S-02, gdy pojawi się pierwsza dawka.
5. **target_scale.qps and target_scale.data_volume** — Owner: user. Block: —.
6. **Administration edit/delete policy** — Owner: user. Block: — (S-03 dostarcza tylko zapis i odczyt).
7. **Dokumentacja projektu do przygotowania na koniec MVP**: log decyzji, mapowanie wymagań na ścieżki w `README.md`, plan testów wymieniający też ryzyka bez automatycznego pokrycia (przeniesione z poprzedniej wersji roadmapy). — Owner: user. Block: —.

## Parked

- **Skan opakowania i OCR ulotki przez AI** — Why parked: PRD §Non-Goals; wymaga ewaluacji i potwierdzenia przez człowieka.
- **Powiadomienia push o następnej dawce** — Why parked: PRD §Non-Goals; w v1 wystarcza wspólna widoczność w aplikacji (FR-008).
- **Offline-first i wykrywanie podwójnego podania** — Why parked: PRD §Non-Goals; kandydat na kolejny kamień milowy — konflikt synchronizacji jest decyzją o bezpieczeństwie (sygnalizuj podwójne podanie, przelicz bramkę od wcześniejszej dawki), nie scalanie po cichu.
- **Edycja reguł dawkowania przez użytkownika** — Why parked: PRD §Non-Goals; reguły pochodzą z katalogu.
- **Edycja i usuwanie zapisanych podań** — Why parked: PRD Open Question 6; wraca przy realnej potrzebie.
- **Pacjenci dorośli** — Why parked: PRD Open Question 3; dawkowanie wg masy ciała dotyczy głównie dzieci.
- **Pełny pipeline CI/CD z auto-deployem i agentem wstępnego review PR** — Why parked: cel `speed`; wdrożenie ręczne z `deploy-plan.md` wystarcza dla MVP. Krok integracyjny bez sekretów ma być pomijany, nie failowany.
- **Osobne środowisko preview i własna domena** — Why parked: `context/deployment/deploy-plan.md` §Odłożone.

## Milestone History

## Done

- **S-01: Opiekun po zalogowaniu zakłada gospodarstwo, dodaje dziecko z wagą i wiekiem i wybiera je z listy dzieci gospodarstwa.** — Archived 2026-09-25 → `context/archive/2026-09-25-household-with-child/`. Lesson: —.
