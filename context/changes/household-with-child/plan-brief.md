# Gospodarstwo z dzieckiem — Plan Brief

> Full plan: `context/changes/household-with-child/plan.md`

## What & Why

Roadmap S-01: zalogowany opiekun zakłada gospodarstwo, dodaje dziecko z datą urodzenia i wagą (z datą pomiaru), wybiera je i aktualizuje wagę. To pierwszy wycinek z danymi zdrowotnymi — tu powstaje granica gospodarstwa w bazie, na której stoją bramka (S-02), log podań (S-03) i drugi opiekun (S-04). Błąd izolacji na tym etapie przecieka do wszystkiego później.

## Starting Point

Auth Supabase działa na produkcji, middleware chroni tylko `/dashboard`. Brak schematu i migracji, brak runnera testów (jest smoke HTTP), strony szablonowe po angielsku. CI podnosi lokalny Supabase.

## Desired End State

Nowy użytkownik po zalogowaniu zakłada gospodarstwo, dodaje dziecko i widzi je na liście; w widoku dziecka aktualizuje wagę. Użytkownik z innego gospodarstwa nie widzi tych danych — także bezpośrednio przez API Supabase, co udowadniają testy pgTAP w CI. Całość działa na produkcji.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) |
| --- | --- | --- |
| Gospodarstw na opiekuna | Dokładnie jedno (`unique (user_id)`) | Brak przełącznika w nocy; pasuje do płaskiego członkostwa z PRD. |
| Tworzenie gospodarstwa | Jawny krok po zalogowaniu | S-04 doda obok „Dołącz do istniejącego” bez osieroconych gospodarstw. |
| Wiek | Data urodzenia | Wiek liczony na dzień podania nie starzeje się. |
| Waga | Bieżąca waga + data pomiaru | S-02 odrzuci nieaktualną wagę; bez historii pomiarów. |
| Operacje na dziecku | Dodaj, wybierz, zmień wagę | Bez aktualizacji wagi bramka zablokowałaby dziecko na stałe. |
| Testy izolacji | pgTAP (`supabase test db`) lokalnie i w CI | Testuje polityki jako realne role, nie tylko to, co pokazuje UI. |
| Migracja produkcji | Ręcznie, `supabase db push` | Schemat za bramką człowieka; agent nie dostaje hasła do bazy. |
| Zapis gospodarstwa | Jedna funkcja SQL `create_household` | Dwa INSERT-y nie przejdą RLS przed utworzeniem członkostwa. |

## Scope

**In scope:** tabele `households` / `household_members` / `children` z RLS, testy pgTAP + krok CI, `locals.household` w middleware, onboarding `/household/new`, lista i formularz dzieci na `/dashboard`, widok `/children/<id>` z aktualizacją wagi, polski UI, rozszerzony smoke, wdrożenie produkcji.

**Out of scope:** dołączanie drugiego opiekuna (S-04), wiele gospodarstw, usuwanie i pełna edycja dziecka, historia wagi, alergie, liczenie wieku i progi świeżości wagi (S-02), katalog leków, auto-migracje z CI.

## Architecture / Approach

Postgres (Supabase) trzyma granicę gospodarstwa: funkcja `security definer` `is_household_member` zasila polityki SELECT/INSERT/UPDATE per tabela (bez DELETE), a `create_household` atomowo tworzy gospodarstwo z członkostwem. Middleware Astro dokłada `locals.household` i przekierowuje użytkownika bez gospodarstwa na onboarding. Endpointy biorą `household_id` wyłącznie z `locals`, walidują Zod, a formularze to zwykły HTML w Astro.

## Phases at a Glance

| Phase | What it delivers | Key risk |
| --- | --- | --- |
| 1. Schemat, RLS i testy | Migracja + pgTAP + krok CI | Rekurencja polityk / luka izolacji |
| 2. Kontekst i onboarding | `locals.household`, `/household/new`, smoke | Pętla przekierowań w middleware |
| 3. Dzieci | Dodanie, lista, widok, aktualizacja wagi | Walidacja dat i wagi z przecinkiem |
| 4. Produkcja | `db push` (człowiek), deploy, weryfikacja | Migracja przed deployem, nie odwrotnie |

**Prerequisites:** Docker + lokalny Supabase CLI (są), dostęp do projektu Supabase z hasłem bazy (człowiek, faza 4).
**Estimated effort:** ~3–4 sesje w 4 fazach.

## Open Risks & Assumptions

- Lokalna weryfikacja wymaga, by `npm run dev` rozmawiał z lokalnym Supabase; `.env` wskazuje produkcję bez migracji — do sprawdzenia, który plik wygrywa.
- Starsza wersja Workera po rollbacku działa z nowym schematem (addytywny), ale rollback nie cofa migracji.

## Success Criteria (Summary)

- Opiekun od zera dochodzi do wybranego dziecka z aktualną wagą w kilku krokach.
- Drugie gospodarstwo nie widzi cudzych danych ani przez UI, ani przez API — potwierdzone w CI.
- Działa na `https://mozna.cieszy-ski.workers.dev`.
