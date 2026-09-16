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

| Ścieżka | Rola |
|---|---|
| `foundation/` | żywe dokumenty między zmianami (PRD, stack, infra, lessons…) |
| `changes/<change-id>/` | zmiany w toku |
| `archive/` | ukończone zmiany — **niezmienne, nigdy tu nie zapisuj** |

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

Pełny blok reguł 10xDevs to materiał płatnego kursu i nie trafia do repozytorium.
Pobierz lokalnie własnym kontem (`npx @przeprogramowani/10x-cli sync --all`).
CLI domyślnie nie wstawia bloku do tego pliku (`--no-course-rules`) — mimo to
po `get --type rules` potrafi dopisać marker; wtedy wytnij sekcję
`<!-- BEGIN @przeprogramowani/10x-cli -->` … `<!-- END … -->`.

@.claude/10x-course-rules.md

## Komendy

Skrypty i lint-staged: `@package.json`. Po zmianach auth/zależności odpal
`npm run smoke` wobec działającego serwera (`BASE_URL`, domyślnie
`http://localhost:4321`).

## Architektura

**Astro 7 SSR** + React 19 islands, Tailwind 4, Supabase auth, shadcn/ui.
Deploy: Cloudflare Workers.

### Rendering

Pełny SSR (`output: "server"` w `astro.config.mjs`). Strony domyślnie
server-rendered. Trasy API muszą eksportować `const prerender = false`.

### Auth

- `src/lib/supabase.ts` — klient Supabase SSR (`@supabase/ssr`, sesje w cookies).
  `SUPABASE_URL` i `SUPABASE_KEY` przez `astro:env/server` (`env.schema` w
  `astro.config.mjs`).
- `src/middleware.ts` — na każdym requestcie ustawia `context.locals.user`;
  przekierowuje niezalogowanych z tras w `PROTECTED_ROUTES`.
- API: `src/pages/api/auth/{signin,signup,signout}.ts`
- Strony: `src/pages/auth/{signin,signup,confirm-email}.astro`
- Przykład chronionej strony: `src/pages/dashboard.astro`

### Konwencje

- Alias ścieżek: `@/*` → `./src/*` (tsconfig).
- Komponenty Astro na treść/layout; React tylko przy interaktywności.
- Tailwind: klasy łączyć przez `cn()` z `@/lib/utils` (clsx + tailwind-merge) —
  bez ręcznej konkatenacji stringów.
- shadcn/ui w `src/components/ui/`, wariant „new-york”. Nowe:
  `npx shadcn@latest add [name]`.
- Trasy API: eksporty `GET` / `POST` (uppercase); walidacja wejścia Zod.
- Migracje Supabase: `supabase/migrations/`, format
  `YYYYMMDDHHmmss_short_description.sql`. Zawsze RLS z granularnymi politykami
  per operacja / per rola.
- React: bez dyrektyw Next.js (`"use client"` itd.). Hooki w
  `src/components/hooks/`.
- Serwisy/helpers w `src/lib/` (lub `src/lib/services/` dla logiki biznesowej).
- Współdzielone typy (encje, DTO) w `src/types.ts`.

### Środowisko

- Node.js v22.14.0 (zob. `.nvmrc`)
- Env: `SUPABASE_URL`, `SUPABASE_KEY` — skopiuj `.env.example` → `.env` (Node)
  albo `.dev.vars` (lokalny Cloudflare)
- Lokalny Supabase: `npx supabase start` (wymaga Dockera)
- Lokalny Cloudflare: sekrety w `.dev.vars` (gitignored)
- Deploy: `npx wrangler deploy` (konto Cloudflare + auth `wrangler`)

## CI

GitHub Actions (`.github/workflows/ci.yml`): lint + build na push i PR do
`master`. Wymaga secretów repozytorium `SUPABASE_URL` i `SUPABASE_KEY` na kroku
build.
