<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Gospodarstwo z dzieckiem

- **Plan**: context/changes/household-with-child/plan.md
- **Scope**: Full plan
- **Reviewed phases**: 1, 2, 3, 4
- **Date**: 2026-09-25
- **Verdict**: NEEDS ATTENTION → APPROVED after triage (6 fixed, 3 deferred to S-02, 1 accepted)
- **Findings**: 0 critical, 4 warnings, 6 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | WARNING |

Automated re-run 2026-09-25: `npm run lint` PASS, `npx astro check` 0 errors, `npx supabase test db` 17/17 PASS, `npx supabase migration list` remote = 20260925165142. Smoke 14/14 and CI green on 419cb86 (earlier in session).

## Findings

### F1 — Starsza waga nadpisuje nowszą „bieżącą wagę”

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: src/pages/api/children/[id]/weight.ts:41-54, src/lib/services/children.ts:78-86
- **Detail**: Aktualizacja przyjmuje dowolną datę pomiaru między urodzeniem a dziś, także starszą niż zapisane `weight_measured_at`. Wpisanie zaległego pomiaru nadpisuje nowszą wagę, na której S-02 oprze dawkę.
- **Fix**: Odrzucać `weightMeasuredAt < child.weight_measured_at` (dociągnąć kolumnę w istniejącym SELECT, dodać refine z polskim komunikatem).
  - Strength: Jedna reguła w jednym schemacie; chroni wejście bramki przed cofnięciem w czasie.
  - Tradeoff: Nie da się poprawić błędnej daty najnowszego pomiaru „wstecz” — trzeba wpisać nowy pomiar z dzisiejszą datą.
  - Confidence: HIGH — schemat już porównuje z `birth_date` w tym samym miejscu.
  - Blind spot: Czy opiekunowie wpisują zaległe pomiary — nie badane.
- **Decision**: FIXED — refine w `weightUpdateSchema` + SELECT `weight_measured_at` w endpointcie; krok smoke „older weight measurement is rejected”; break-check PASS

### F2 — Usunięcie konta zostawia osierocone dane zdrowotne

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925165142_household_and_children.sql:16-17,25
- **Detail**: Usunięcie użytkownika z `auth.users` kasuje tylko jego `household_members`; `households` i `children` zostają bez członków — niewidoczne przez RLS, ale nigdy nieusuwane (retencja / RODO).
- **Fix A ⭐ Recommended**: Trigger po DELETE na `household_members` usuwa gospodarstwo, gdy odszedł ostatni członek (kaskada zabiera dzieci)
  - Strength: Dane znikają razem z ostatnim opiekunem; zgodne z płaskim członkostwem.
  - Tradeoff: Nieodwracalne kasowanie danych w bazie; musi mieć test pgTAP.
  - Confidence: MEDIUM — prosty trigger, ale nieodwracalność wymaga ostrożności.
  - Blind spot: Przyszłe S-04 (dołączanie) — ostatni członek może „wyjść” zamiast usunąć konto.
- **Fix B**: Zapisać w rejestrze ryzyk + ręczna procedura purge przed publicznym startem
  - Strength: Zero kodu teraz; człowiek decyduje o kasowaniu (zgodnie z CLAUDE.md).
  - Tradeoff: Łatwo zapomnieć; dane leżą do czasu purge.
  - Confidence: HIGH — nic nie psuje.
  - Blind spot: Brak automatu przy rosnącej liczbie kont.
- **Decision**: FIXED via Fix A — trigger `delete_empty_household` w `20260925200500_household_hardening.sql`; pgTAP `household_hardening.test.sql`; break-check PASS

### F3 — Reguły dat tylko w Zod, nie w bazie

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925165142_household_and_children.sql:27-29
- **Detail**: Baza nie egzekwuje `weight_measured_at >= birth_date`; bezpośrednie wywołanie PostgREST z JWT użytkownika (cookie nie jest httpOnly) ominie Zod.
- **Fix**: W następnej migracji CHECK `weight_measured_at >= birth_date` (reguły „nie w przyszłości” wymagałyby triggera — pominąć).
- **Decision**: FIXED — CHECK `children_weight_measured_after_birth` w `20260925200500_household_hardening.sql`; pgTAP

### F4 — Brak dowodu kroku 4.4 w ścieżce audytu

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: context/deployment/deploy-plan.md:60
- **Detail**: 4.4 jest `[x]`, ale kolumna Weryfikacja zapisuje tylko przekierowania anonima i schemat; brak wzmianki, że przepływ zalogowanego przeszedł na produkcji (potwierdzone przez człowieka 2026-09-25).
- **Fix**: Dopisać do wiersza: „przepływ zalogowanego (gospodarstwo, syntetyczne dziecko, aktualizacja wagi) potwierdzony ręcznie przez człowieka”.
- **Decision**: FIXED — kolumna Weryfikacja w `context/deployment/deploy-plan.md`

### F5 — Middleware: 503 na wszystkich trasach i zapytanie przy każdym żądaniu

- **Severity**: OBSERVATION
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Architecture
- **Location**: src/middleware.ts:14-38
- **Detail**: Zapytanie o gospodarstwo idzie przy każdym żądaniu zalogowanego (także `/`, `/api/auth/*`); przy awarii Supabase 503 blokuje też wylogowanie i stronę główną.
- **Fix**: Odpytywać gospodarstwo tylko dla tras chronionych, onboardingu i `/api/*` poza `/api/auth/*`.
  - Strength: Mniej round-tripów; wylogowanie działa przy awarii.
  - Tradeoff: Lista tras w dwóch miejscach do utrzymania.
  - Confidence: MED — S-02 i tak zmieni routing strony startowej.
  - Blind spot: Topbar na stronach publicznych nie pokaże nazwy gospodarstwa.
- **Decision**: DEFERRED — przeniesione do `context/changes/gate-from-popular-list/change.md`

### F6 — Domyślne granty Supabase szersze niż polityki

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: supabase/migrations/20260925165142_household_and_children.sql (grants)
- **Detail**: `authenticated` ma DELETE/TRUNCATE, `anon` pełne granty tabelowe; RLS i brak polityk blokują to przez REST (TRUNCATE nieosiągalny), ale intencja nie jest wyrażona w grantach. INSERT pozwala klientowi ustawić `id`/`created_at`.
- **Fix**: Następna migracja: `revoke all ... from anon`, `revoke delete, truncate ... from authenticated`, INSERT na `children` zawężony do kolumn danych (już zapisane w notatkach S-02).
- **Decision**: FIXED — granty w `20260925200500_household_hardening.sql` (anon bez uprawnień, authenticated: SELECT, INSERT kolumn danych, UPDATE wagi); `household_rls.test.sql` dostosowany; pgTAP

### F7 — Stare trasy auth odbiegają od nowych wzorców

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: src/pages/api/auth/{signin,signup,signout}.ts, src/pages/auth/*.astro
- **Detail**: `form.get() as string` bez Zod, brak `prerender`, angielskie komunikaty i surowe `error.message` z Supabase, tytuły „Sign in” przy `lang="pl"`. Nowe trasy są spójne z konwencjami — rozjazd jest po stronie starterowego kodu; łączy się z uwagą użytkownika o mylącej stronie startowej.
- **Fix**: W S-02 razem z przekierowaniem zalogowanych: wyrównać trasy auth (Zod, polskie komunikaty, bez surowych błędów).
- **Decision**: DEFERRED — przeniesione do `context/changes/gate-from-popular-list/change.md`

### F8 — Niespójna obsługa błędu odczytu dziecka

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: src/pages/children/[id].astro:21-23 vs src/pages/dashboard.astro:20-21
- **Detail**: Błąd Supabase na widoku dziecka daje ogólne 500, a dashboard pokazuje komunikat. Obejście lintu `no-misused-promises` przy `return` we frontmatter.
- **Fix**: Przy przebudowie widoku dziecka w S-02 renderować komunikat błędu jak dashboard.
- **Decision**: DEFERRED — przeniesione do `context/changes/gate-from-popular-list/change.md`

### F9 — CI: niepinowana wersja Supabase CLI

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: .github/workflows/ci.yml:35-37
- **Detail**: `supabase/setup-cli` z `version: latest` — nowa wersja CLI może zmienić wynik `supabase test db` bez zmian w repo.
- **Fix**: Przypiąć wersję CLI (lokalnie 2.117.0).
- **Decision**: FIXED — `supabase/setup-cli` przypięty do 2.117.0 w `.github/workflows/ci.yml`

### F10 — Przekierowanie błędów wagi na widok dziecka (drobny dryf)

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Adherence
- **Location**: src/pages/api/children/[id]/weight.ts:45-48,56-60
- **Detail**: Błędy walidacji i zapisu wracają na `/children/<id>?error`, plan precyzował tylko przypadek 0 wierszy → dashboard. Rozsądna interpretacja; przypadek obcego dziecka zgodny z planem.
- **Fix**: Zaakceptować jako interpretację; widok wagi i tak przenosi się do osobnego ekranu w S-02.
- **Decision**: ACCEPTED — rozsądna interpretacja; widok wagi przenosi się na osobny ekran w S-02
