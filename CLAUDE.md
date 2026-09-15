# Projekt zaliczeniowy 10xDevs 4.0

Greenfield. Termin zgłoszenia: 4 listopada 2026.

## Dane osobowe

Repozytorium jest publiczne, a domena aplikacji obejmuje dane o zdrowiu.
W śledzonych plikach nigdy nie umieszczaj danych prawdziwych — seed, fixtures,
testy i zrzuty ekranu wyłącznie na danych syntetycznych.
Sekrety tylko w `.env` i GitHub Secrets, nigdy w repo.

## Kontrakty w `context/`

| Ścieżka | Rola |
|---|---|
| `foundation/` | żywe dokumenty między zmianami (PRD, stack, infra, lessons…) |
| `changes/<change-id>/` | zmiany w toku |
| `archive/` | ukończone zmiany — **niezmienne, nigdy tu nie zapisuj** |

Dokumenty fundamentowe edytuje się w miejscu. Bez datowanych kopii; dokument
całkowicie zastąpiony ląduje w `foundation/archive/YYYY-MM-DD-<nazwa>.md`.

## Reguły kursowe

Pełny blok reguł 10xDevs to materiał płatnego kursu i nie trafia do repozytorium.
Pobierz lokalnie własnym kontem (`npx @przeprogramowani/10x-cli sync --all`).
CLI domyślnie nie wstawia bloku do tego pliku (`--no-course-rules`) — mimo to
po `get --type rules` potrafi dopisać marker; wtedy wytnij sekcję
`<!-- BEGIN @przeprogramowani/10x-cli -->` … `<!-- END … -->`.

@.claude/10x-course-rules.md
