# Gospodarstwo z dzieckiem — plan implementacji

## Overview

Roadmap S-01 (`household-with-child`, FR-001, FR-002, Access Control). Zalogowany opiekun zakłada gospodarstwo, dodaje dziecko z datą urodzenia i wagą (z datą pomiaru), wybiera je z listy i aktualizuje wagę. W bazie powstaje granica gospodarstwa (RLS), na której opierają się S-02 (bramka), S-03 (log podań) i S-04 (drugi opiekun).

## Current State Analysis

- Auth działa (Supabase e-mail/hasło, sesje w cookies). `src/middleware.ts:4` chroni tylko `/dashboard`; `src/env.d.ts:2-4` definiuje wyłącznie `locals.user`.
- Brak schematu: `supabase/` zawiera tylko `config.toml` (`schema_paths = []`, seed wskazuje nieistniejący `./seed.sql`, `enable_confirmations = false` lokalnie).
- Strony szablonowe po angielsku: `src/pages/dashboard.astro`, `src/layouts/Layout.astro` (`lang="en"`, tytuł „10x Astro Starter”).
- Brak runnera testów; `scripts/smoke.mjs` sprawdza przepływ auth przez HTTP i oczekuje `200` z `/dashboard` po zalogowaniu (krok „dashboard renders for signed-in user”).
- CI (`.github/workflows/ci.yml`) w jobie `smoke` podnosi lokalny Supabase (`supabase start` stosuje migracje z `supabase/migrations/`), buduje i uruchamia smoke.
- Produkcja: hostowany Supabase (Frankfurt) bez migracji; Worker `mozna` (`context/deployment/deploy-plan.md`). Zmiany schematu są bramką człowieka (`context/foundation/infrastructure.md` §Rollback/Approval).

## Desired End State

- Nowy użytkownik po zalogowaniu trafia na `/household/new`, zakłada gospodarstwo i ląduje na `/dashboard`.
- `/dashboard` pokazuje dzieci gospodarstwa i formularz dodania dziecka (imię/przydomek, data urodzenia, waga kg, data pomiaru).
- `/children/<id>` to widok wybranego dziecka z formularzem aktualizacji wagi.
- Opiekun z innego gospodarstwa nie widzi ani nie zmienia tych danych — również bezpośrednio przez API Supabase (dowód: testy pgTAP w CI).
- Opiekun nie może założyć drugiego gospodarstwa.
- Migracja zastosowana na produkcji, Worker wdrożony, przepływ sprawdzony na `https://mozna.cieszy-ski.workers.dev` na syntetycznym dziecku.

### Key Discoveries:

- `src/lib/supabase.ts:5` — `createClient(headers, cookies)` zwraca `null`, gdy brak konfiguracji; każdy nowy handler musi obsłużyć `null` tak jak `src/pages/api/auth/signup.ts:10-12`.
- `src/middleware.ts:18-22` — wzorzec przekierowania dla chronionych tras; rozszerzamy go, nie zastępujemy.
- `src/pages/api/auth/signup.ts` — wzorzec API: `formData()` → Supabase → `redirect` z `?error=`; nowe trasy go powtarzają (z Zod zamiast rzutowania `as string`).
- `scripts/smoke.mjs:40-60` — tablica kroków `[name, run, expected]`; nowe kroki dopisujemy w tym samym kształcie.
- `.github/workflows/ci.yml` job `smoke` — lokalny Supabase jest już uruchomiony; `supabase test db` wpina się po `Start local Supabase`.

## What We're NOT Doing

- Dołączanie drugiego opiekuna do gospodarstwa, zaproszenia, kody — S-04.
- Wiele gospodarstw na opiekuna i przełącznik gospodarstw.
- Usuwanie dziecka, edycja imienia i daty urodzenia (poza wagą) — wraca razem z polityką usuwania danych (PRD Open Question 6).
- Historia pomiarów wagi — jedna bieżąca waga z datą pomiaru.
- Alergie i inne dane zdrowotne poza wagą i datą urodzenia.
- Liczenie wieku w miesiącach i progi „nieaktualnej wagi” — należą do bramki (S-02).
- Katalog leków (F-01), bramka, log podań.
- Automatyczne migracje produkcji z CI.
- Generowanie typów Supabase (`supabase gen types`) — ręczne DTO w `src/types.ts` wystarczą dla trzech tabel.

## Implementation Approach

Najpierw dane i izolacja (faza 1) z testami na poziomie bazy, bo błąd RLS przecieka do każdego kolejnego wycinka. Potem kontekst gospodarstwa w middleware i onboarding (faza 2), następnie dzieci (faza 3), na końcu ręczne wdrożenie produkcji (faza 4). Formularze to zwykły HTML w Astro (bez React — brak interaktywności). Zapis gospodarstwa + członkostwa idzie przez jedną funkcję SQL, bo dwa osobne INSERT-y nie przejdą RLS (przed członkostwem gospodarstwo jest niewidoczne dla twórcy).

## Critical Implementation Details

- **Rekurencja RLS:** polityka na `household_members` odwołująca się do `household_members` zapętla się. Sprawdzanie członkostwa robi funkcja `security definer` z `set search_path = ''`, a polityki wszystkich tabel wołają ją zamiast subzapytań.
- **Środowisko lokalne:** `.env` wskazuje hostowany Supabase bez migracji. Do ręcznej weryfikacji faz 2–3 lokalny serwer musi rozmawiać z lokalnym Supabase (`npx supabase start`, wartości z `npx supabase status -o env`). Implementujący sprawdza, który plik (`.env` czy `.dev.vars`) wygrywa w `npm run dev`, i nie nadpisuje `.env` użytkownika bez pytania.

## Faza 1: Schemat, RLS i testy izolacji

### Overview

Pierwsza migracja z trzema tabelami, funkcjami i politykami per operacja, plus testy pgTAP uruchamiane lokalnie i w CI.

### Changes Required:

#### 1. Migracja

**File**: `supabase/migrations/<YYYYMMDDHHmmss>_household_and_children.sql`

**Intent**: Utworzyć model gospodarstwa z płaskim członkostwem (jeden opiekun = jedno gospodarstwo) i dzieci z danymi potrzebnymi bramce, z RLS włączonym na każdej tabeli.

**Contract**:
- `households`: `id uuid pk default gen_random_uuid()`, `name text not null` (1–80 znaków, check), `created_at timestamptz not null default now()`.
- `household_members`: `household_id uuid not null → households(id) on delete cascade`, `user_id uuid not null → auth.users(id) on delete cascade`, `created_at`; PK `(household_id, user_id)`; **`unique (user_id)`** — egzekwuje jedno gospodarstwo na opiekuna.
- `children`: `id uuid pk`, `household_id uuid not null → households(id) on delete cascade`, `display_name text not null` (1–60), `birth_date date not null` (check: nie wcześniej niż 2000-01-01), `weight_kg numeric(5,2) not null` (check: 0.5–150), `weight_measured_at date not null`, `created_at`, `updated_at timestamptz not null default now()`; indeks na `household_id`.
- `public.is_household_member(p_household_id uuid) returns boolean` — `stable security definer set search_path = ''`, sprawdza `auth.uid()` w `public.household_members`.
- `public.create_household(p_name text) returns uuid` — `security definer set search_path = ''`; odrzuca brak `auth.uid()`; w jednej transakcji wstawia gospodarstwo i członkostwo; naruszenie `unique (user_id)` propaguje jako błąd. `revoke execute ... from public, anon; grant execute ... to authenticated` dla obu funkcji.
- RLS włączony na wszystkich trzech tabelach; polityki tylko dla roli `authenticated`:
  - `households`: SELECT `using (is_household_member(id))`. Brak INSERT/UPDATE/DELETE (tworzenie wyłącznie przez RPC).
  - `household_members`: SELECT `using (user_id = auth.uid() or is_household_member(household_id))`. Brak INSERT/UPDATE/DELETE (S-04 doda dołączanie).
  - `children`: SELECT `using (is_household_member(household_id))`; INSERT `with check (is_household_member(household_id))`; UPDATE `using` + `with check (is_household_member(household_id))`. Brak DELETE.
- `updated_at` na `children` odświeżany triggerem przy UPDATE.
- Grant UPDATE na `children` dla `authenticated` zawężony do kolumn `(weight_kg, weight_measured_at)` — zakres „edytujemy tylko wagę” egzekwowany także w bazie.

#### 2. Testy pgTAP

**File**: `supabase/tests/household_rls.test.sql`

**Intent**: Udowodnić izolację gospodarstw na poziomie bazy, jako rzeczywiste role, niezależnie od UI.

**Contract**: Test w transakcji zaczynającej się od `create extension if not exists pgtap with schema extensions;`, z `plan(n)` / `finish()`, dwóch syntetycznych użytkowników (A, B) wstawionych do `auth.users`, przełączanie przez `set local role authenticated` + `set local request.jwt.claims`. Asercje:
- A: `create_household` zwraca id; A widzi 1 gospodarstwo i siebie w `household_members`.
- A: drugie `create_household` rzuca błąd.
- A: wstawia dziecko do swojego gospodarstwa; B (z własnym gospodarstwem) widzi 0 dzieci i 0 gospodarstw A.
- B: INSERT dziecka z `household_id` A rzuca błąd RLS (`42501`).
- B: UPDATE dziecka A zmienia 0 wierszy.
- `anon`: SELECT z `children` nie zwraca wierszy lub rzuca brak uprawnień; `create_household` niedostępne.
- A: wstawienie dziecka z `weight_kg = 0` rzuca naruszenie check.

#### 3. CI

**File**: `.github/workflows/ci.yml`

**Intent**: Uruchamiać testy RLS przy każdym pushu na istniejącym lokalnym Supabase.

**Contract**: W jobie `smoke` nowy krok `supabase test db` bezpośrednio po `Start local Supabase`.

#### 4. Konfiguracja seeda

**File**: `supabase/config.toml`

**Intent**: Usunąć odwołanie do nieistniejącego `./seed.sql` albo dodać pusty plik — tak, by `supabase db reset` nie ostrzegał. Implementujący wybiera wariant zgodny z tym, co CLI faktycznie zgłasza.

**Contract**: `[db.seed]` bez błędów przy `npx supabase db reset`.

### Success Criteria:

#### Automated Verification:

- Migracja stosuje się czysto: `npx supabase db reset`
- Testy RLS przechodzą: `npx supabase test db`
- Lint przechodzi: `npm run lint`
- CI na pushu: job `smoke` z krokiem `supabase test db` jest zielony

#### Manual Verification:

- W Supabase Studio lokalnie tabele mają włączony RLS i polityki zgodne z kontraktem (bez polityk DELETE)

**Implementation Note**: Po automatycznej weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka przed fazą 2.

---

## Faza 2: Kontekst gospodarstwa i onboarding

### Overview

Middleware zna gospodarstwo użytkownika; użytkownik bez gospodarstwa jest prowadzony do jego założenia.

### Changes Required:

#### 1. Typy

**File**: `src/types.ts` (nowy), `src/env.d.ts`

**Intent**: Wspólne DTO dla gospodarstwa i dziecka oraz nowe pole w `Locals`.

**Contract**: `Household { id: string; name: string }`, `Child { id; householdId; displayName; birthDate: string (YYYY-MM-DD); weightKg: number; weightMeasuredAt: string }`. `App.Locals.household: Household | null`.

#### 2. Middleware

**File**: `src/middleware.ts`

**Intent**: Dla zalogowanego użytkownika pobrać jego gospodarstwo (jedno zapytanie przez `household_members` → `households`) i ustawić `locals.household`; rozszerzyć ochronę tras.

**Contract**:
- Trasy wymagające zalogowania: `/dashboard`, `/household`, `/children` (anonim → `/auth/signin`, jak dziś).
- Trasy wymagające gospodarstwa: `/dashboard`, `/children` (brak → `/household/new`).
- `/household/new` z istniejącym gospodarstwem → `/dashboard`.
- Zapytanie o gospodarstwo tylko gdy `locals.user` istnieje; bez użytkownika `locals.household = null`.
- Błąd zapytania (sieć, timeout, błąd Supabase) ≠ brak gospodarstwa: przy błędzie nie przekierowywać na onboarding, tylko zwrócić `503` z prośbą o odświeżenie strony.

#### 3. Onboarding

**File**: `src/pages/household/new.astro`, `src/pages/api/household.ts`

**Intent**: Ekran „Załóż gospodarstwo” z polem nazwy; API woła `create_household` i przekierowuje.

**Contract**: `POST /api/household` (`prerender = false`), form field `name` (Zod: trim, 1–80). Sukces → `302 /dashboard`. Błąd walidacji / RPC → `302 /household/new?error=<msg>`. Brak klienta Supabase lub użytkownika → jak w `signup.ts`. Strona pokazuje `?error=` przez istniejący `src/components/auth/ServerError.tsx` albo odpowiednik w Astro.

#### 4. Layout i dashboard

**File**: `src/layouts/Layout.astro`, `src/pages/dashboard.astro`

**Intent**: Interfejs po polsku; dashboard pokazuje nazwę gospodarstwa (lista dzieci dochodzi w fazie 3).

**Contract**: `lang="pl"`, domyślny tytuł „Można?”. Dashboard renderuje `locals.household.name` i przycisk wylogowania.

#### 5. Smoke

**File**: `scripts/smoke.mjs`

**Intent**: Dostosować smoke do nowego przepływu i sprawdzić onboarding.

**Contract**: Po „signin accepts correct password”: `GET /dashboard` → `302 /household/new`; `POST /api/household` (`name: "Dom testowy"`) → `302 /dashboard`; `GET /dashboard` → `200`. Pozostałe kroki bez zmian. Dane syntetyczne.

### Success Criteria:

#### Automated Verification:

- Lint przechodzi: `npm run lint`
- Typy przechodzą: `npx astro check`
- Build przechodzi: `npm run build`
- Smoke przechodzi wobec lokalnego serwera na lokalnym Supabase: `npm run smoke`
- Testy RLS nadal przechodzą: `npx supabase test db`

#### Manual Verification:

- Nowe konto po zalogowaniu trafia na „Załóż gospodarstwo”, po zapisaniu na dashboard z nazwą gospodarstwa
- Wejście na `/household/new` z istniejącym gospodarstwem przekierowuje na dashboard

**Implementation Note**: Po automatycznej weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka przed fazą 3.

---

## Faza 3: Dzieci — dodanie, wybór, aktualizacja wagi

### Overview

Opiekun dodaje dziecko, widzi listę dzieci gospodarstwa, wybiera dziecko i aktualizuje jego wagę.

### Changes Required:

#### 1. Walidacja wspólna

**File**: `src/lib/services/children.ts` (nowy)

**Intent**: Jedno miejsce na schematy Zod i mapowanie wiersza bazy na `Child`, używane przez oba endpointy i strony.

**Contract**: Schemat dziecka: `displayName` trim 1–60; `birthDate` ISO date, nie w przyszłości, nie wcześniej niż 2000-01-01; `weightKg` liczba 0.5–150 (akceptuje przecinek dziesiętny z formularza); `weightMeasuredAt` ISO date, nie w przyszłości, nie wcześniej niż `birthDate`, domyślnie dziś. Schemat aktualizacji wagi: `weightKg` + `weightMeasuredAt` z tymi samymi regułami (porównanie z `birthDate` dziecka z bazy). Import `z` z `astro/zod`.

#### 2. API

**File**: `src/pages/api/children.ts`, `src/pages/api/children/[id]/weight.ts`

**Intent**: Zapis dziecka do gospodarstwa użytkownika i aktualizacja wagi; `household_id` zawsze z `locals.household`, nigdy z formularza.

**Contract**:
- `POST /api/children` → INSERT do `children` z `household_id = locals.household.id` → `302 /children/<new id>`; błąd → `302 /dashboard?error=<msg>`.
- `POST /api/children/<id>/weight` → UPDATE `weight_kg`, `weight_measured_at` dla dziecka `id` → `302 /children/<id>`; 0 zaktualizowanych wierszy (cudze lub nieistniejące dziecko) → `302 /dashboard?error=...`, bez ujawniania, czy dziecko istnieje.
- Obie trasy: `prerender = false`; brak użytkownika/gospodarstwa → przekierowanie jak middleware.

#### 3. Strony

**File**: `src/pages/dashboard.astro`, `src/pages/children/[id].astro`

**Intent**: Dashboard jako lista dzieci + formularz dodania; widok dziecka jako „wybrane dziecko”, na którym S-02 zbuduje bramkę.

**Contract**:
- Dashboard: lista dzieci gospodarstwa (imię, data urodzenia, waga z datą pomiaru), każde jako link do `/children/<id>`; pusty stan „Dodaj pierwsze dziecko”; formularz z `<input type="date">` i `<input inputmode="decimal">`; komunikat `?error=`.
- `/children/<id>`: dane dziecka + formularz aktualizacji wagi. Dziecko niewidoczne przez RLS → `404`.

#### 4. Smoke

**File**: `scripts/smoke.mjs`

**Intent**: Pokryć dodanie dziecka i aktualizację wagi.

**Contract**: Po założeniu gospodarstwa: `POST /api/children` (syntetyczne dane, np. „Dziecko testowe”, `2024-01-15`, `12,5`, dziś) → `302` na `/children/`; `GET` tej lokalizacji → `200`; `POST .../weight` → `302` na to samo dziecko; `GET /children/00000000-0000-0000-0000-000000000000` → `404`.

### Success Criteria:

#### Automated Verification:

- Lint przechodzi: `npm run lint`
- Typy przechodzą: `npx astro check`
- Build przechodzi: `npm run build`
- Smoke przechodzi wobec lokalnego serwera na lokalnym Supabase: `npm run smoke`
- Testy RLS nadal przechodzą: `npx supabase test db`

#### Manual Verification:

- Dodanie dziecka z poprawnymi danymi prowadzi do jego widoku; dziecko jest na liście dashboardu
- Waga z przecinkiem („12,5”) zapisuje się jako 12.5 kg; data urodzenia w przyszłości i waga 0 są odrzucane z czytelnym komunikatem
- Aktualizacja wagi zmienia wagę i datę pomiaru w widoku dziecka
- Drugie konto (inne gospodarstwo) nie widzi dziecka na liście, a wejście na jego `/children/<id>` daje 404

**Implementation Note**: Po automatycznej weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka przed fazą 4.

---

## Faza 4: Wdrożenie na produkcję

### Overview

Migracja na hostowany Supabase (człowiek), deploy Workera i weryfikacja na produkcji.

### Changes Required:

#### 1. Migracja produkcji (bramka człowieka)

**File**: — (operacja)

**Intent**: Zastosować migrację na hostowanym projekcie bez przekazywania agentowi hasła do bazy.

**Contract**: Człowiek: `npx supabase login`, `npx supabase link --project-ref <ref>`, `npx supabase db push` (hasło wpisane interaktywnie). Dopiero po zielonym CI z fazy 3.

#### 2. Deploy i zapis

**File**: `context/deployment/deploy-plan.md`

**Intent**: Wdrożyć Worker i odnotować, co jest na produkcji.

**Contract**: `npm run build && npx wrangler deploy`; w `deploy-plan.md` nowa wersja Workera, zastosowana migracja (nazwa pliku), data.

### Success Criteria:

#### Automated Verification:

- Deploy kończy się sukcesem: `npx wrangler deploy` zwraca Version ID
- Anonim na produkcji: `GET /dashboard` → `302 /auth/signin`, `GET /household/new` → `302 /auth/signin`

#### Manual Verification:

- `npx supabase migration list` pokazuje migrację jako zastosowaną zdalnie
- Na produkcji własnym kontem: założenie gospodarstwa i dodanie syntetycznego dziecka działa
- W Supabase Dashboard tabele produkcyjne mają włączony RLS

**Implementation Note**: Po weryfikacji zatrzymaj się na ręczne potwierdzenie człowieka.

---

## Testing Strategy

### Unit Tests:

- Brak runnera jednostkowego (AGENTS.md); logika reguł dostępu żyje w bazie i jest testowana pgTAP.

### Integration Tests:

- pgTAP (`supabase/tests/household_rls.test.sql`): izolacja A/B, jedno gospodarstwo na opiekuna, brak dostępu anon, checki danych.
- Smoke HTTP (`scripts/smoke.mjs`): onboarding, dodanie dziecka, aktualizacja wagi, 404 dla obcego id.

### Manual Testing Steps:

1. Nowe konto → „Załóż gospodarstwo” → dashboard z nazwą.
2. Dodanie dziecka z wagą „12,5” → widok dziecka → aktualizacja wagi.
3. Drugie konto → brak dziecka pierwszego konta, 404 na jego adresie.

## Performance Considerations

Middleware dodaje jedno zapytanie o gospodarstwo na request zalogowanego użytkownika (indeks przez `unique (user_id)`); mieści się w budżecie ~1 s z PRD. Bez cache — przy spójności danych zdrowotnych nie chcemy nieaktualnego kontekstu.

## Migration Notes

Pierwsza migracja projektu, brak danych do przeniesienia. Wycofanie Workera (`wrangler rollback`) nie cofa schematu — schemat jest addytywny, więc starsza wersja Workera działa z nowymi tabelami.

## References

- Roadmap: `context/foundation/roadmap.md` (S-01)
- PRD: `context/foundation/prd.md` (FR-001, FR-002, Access Control, NFR, Guardrails)
- Infra: `context/foundation/infrastructure.md`, `context/deployment/deploy-plan.md`
- Wzorce: `src/pages/api/auth/signup.ts`, `src/middleware.ts:18-22`, `scripts/smoke.mjs:40-60`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands. Do not rename step titles. See `references/progress-format.md`.

### Phase 1: Schemat, RLS i testy izolacji

#### Automated

- [x] 1.1 Migracja stosuje się czysto: `npx supabase db reset` — cd5da67
- [x] 1.2 Testy RLS przechodzą: `npx supabase test db` — cd5da67
- [x] 1.3 Lint przechodzi: `npm run lint` — cd5da67
- [x] 1.4 CI na pushu: job `smoke` z krokiem `supabase test db` jest zielony — cd5da67

#### Manual

- [x] 1.5 W Supabase Studio lokalnie tabele mają włączony RLS i polityki zgodne z kontraktem (bez polityk DELETE) — cd5da67

### Phase 2: Kontekst gospodarstwa i onboarding

#### Automated

- [x] 2.1 Lint przechodzi: `npm run lint` — 7774e9c
- [x] 2.2 Typy przechodzą: `npx astro check` — 7774e9c
- [x] 2.3 Build przechodzi: `npm run build` — 7774e9c
- [x] 2.4 Smoke przechodzi wobec lokalnego serwera na lokalnym Supabase: `npm run smoke` — 7774e9c
- [x] 2.5 Testy RLS nadal przechodzą: `npx supabase test db` — 7774e9c

#### Manual

- [x] 2.6 Nowe konto po zalogowaniu trafia na „Załóż gospodarstwo”, po zapisaniu na dashboard z nazwą gospodarstwa — 7774e9c
- [x] 2.7 Wejście na `/household/new` z istniejącym gospodarstwem przekierowuje na dashboard — 7774e9c

### Phase 3: Dzieci — dodanie, wybór, aktualizacja wagi

#### Automated

- [x] 3.1 Lint przechodzi: `npm run lint` — 419cb86
- [x] 3.2 Typy przechodzą: `npx astro check` — 419cb86
- [x] 3.3 Build przechodzi: `npm run build` — 419cb86
- [x] 3.4 Smoke przechodzi wobec lokalnego serwera na lokalnym Supabase: `npm run smoke` — 419cb86
- [x] 3.5 Testy RLS nadal przechodzą: `npx supabase test db` — 419cb86

#### Manual

- [x] 3.6 Dodanie dziecka z poprawnymi danymi prowadzi do jego widoku; dziecko jest na liście dashboardu — 419cb86
- [x] 3.7 Waga z przecinkiem („12,5”) zapisuje się jako 12.5 kg; data urodzenia w przyszłości i waga 0 są odrzucane z czytelnym komunikatem — 419cb86
- [x] 3.8 Aktualizacja wagi zmienia wagę i datę pomiaru w widoku dziecka — 419cb86
- [x] 3.9 Drugie konto (inne gospodarstwo) nie widzi dziecka na liście, a wejście na jego `/children/<id>` daje 404 — 419cb86

### Phase 4: Wdrożenie na produkcję

#### Automated

- [x] 4.1 Deploy kończy się sukcesem: `npx wrangler deploy` zwraca Version ID
- [x] 4.2 Anonim na produkcji: `GET /dashboard` → `302 /auth/signin`, `GET /household/new` → `302 /auth/signin`

#### Manual

- [x] 4.3 `npx supabase migration list` pokazuje migrację jako zastosowaną zdalnie
- [x] 4.4 Na produkcji własnym kontem: założenie gospodarstwa i dodanie syntetycznego dziecka działa
- [x] 4.5 W Supabase Dashboard tabele produkcyjne mają włączony RLS
