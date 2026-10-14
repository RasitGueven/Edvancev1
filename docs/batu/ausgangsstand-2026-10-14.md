# Batu — Ausgangsstand vor Schritt 2 (14.10.2026)

Abgezogen per `~/bin/dbread` (read-only) am 14.10.2026 um 06:38:48 UTC, vor dem Einspielen von
`20261014064047_batu_altleads_test`. Das ist der Vergleich für die Kontrolle danach.

## Leads

| id | full_name | first_name | status | ist_test | created_at (UTC) |
|---|---|---|---|---|---|
| d9c9b82a-7ab6-4946-8c13-44ed9eda83fc | Batu Demirel | Batu | rejected | f | 2026-07-18 22:00:31 |
| 7ab419b1-a7e4-440e-829b-2280d50761d6 | Batu Demirel | Batu | rejected | f | 2026-09-06 12:48:44 |

Monat der Anlage (Europe/Berlin): 07/2026 bzw. 09/2026 — passt zur Vorgabe.

## Schülerzeile

| id | is_provisional | ist_test | lead_id | profile_id | class_level | school_type |
|---|---|---|---|---|---|---|
| c017bf9e-b011-4a84-87f9-e1976fc4263a | t | t | d9c9b82a-7ab6-4946-8c13-44ed9eda83fc | – | 9 | Gymnasium |

`students` hat keine Namensspalte; der Name kommt über den Lead.

## LSA-Sessions an c017bf9e (10)

`antworten` = Zahl der `lsa_responses`. `antworten_md5` = md5 über alle Antwortzeilen der Session
(id, task_id, part_nr, response, correct, duration_ms, fehlbild_slug, abgabeart, created_at; nach id
sortiert). `summary_md5` = md5 von `result_summary`.

| id | status | testlauf | started_at (UTC) | completed_at (UTC) | antworten | antworten_md5 | summary_md5 |
|---|---|---|---|---|---|---|---|
| 74a1d807-22dd-4ba3-92c5-d193b105ed2f | completed | f | 2026-07-18 22:01:45.73996 | 2026-07-19 20:51:16.272574 | 8 | db096c8a8fdcb4a9971873c42fcbfe22 | b2d95c522ac55d1a3361937de5bdfabb |
| a8ff43dc-6d2d-4306-901e-f03dc81d59f3 | completed | f | 2026-07-21 10:26:01.874066 | 2026-07-21 10:28:27.943576 | 7 | 80f0f623b1ea0d3601ff24bb7a6159b4 | 02138bb693e854619386823984b7a111 |
| 142bcebb-76d9-427b-8c71-e4df2089d8fe | completed | f | 2026-07-21 14:37:34.040024 | 2026-07-22 07:35:35.451329 | 7 | 26a530d1a56bc3796bc1d8f0ca6ed11c | dd33ff1deb0daa17b9d046fadd436797 |
| f0a0ac0f-c5ba-4505-80e0-5c2c94e1556d | completed | f | 2026-07-22 07:48:44.60393 | 2026-07-22 07:54:39.461763 | 8 | 72d0e65e2ec8fe655376deeec6dd79d1 | 1045c79a1b54a20fa3ba418ef25b861d |
| da10ca1b-15dd-4484-95b5-a815dffd9a8f | completed | f | 2026-07-22 07:54:56.164328 | 2026-07-22 07:56:04.8295 | 7 | 0b72200e90c8c809f2cc323cdb962c09 | a36a2bf4d8549e6c943cb845e09bd3a8 |
| 73217031-0fa2-44cd-b2d4-d0c33a21dd52 | completed | f | 2026-07-22 08:00:55.540247 | 2026-07-22 09:06:58.908937 | 7 | 921f01fa580874b30d4196b5101fa0b1 | 30409c6585b59b7a0df27112881e0750 |
| 2b796028-b35c-4fe1-8bb3-14606e992050 | completed | f | 2026-07-22 10:28:40.702061 | 2026-07-23 20:01:14.680784 | 8 | 4ee77a3bedc5b275e906ab86ff9a7fab | 560162fa4be537dbc8f080d41dde3091 |
| d0ba7a1b-7f2e-4b95-8207-c82cff162362 | completed | f | 2026-07-29 08:09:05.117862 | 2026-07-30 09:41:16.900695 | 35 | 5758b48eae73ad2509dfbca6633d195c | b0711e8888acb8509537e5f26d3fc243 |
| 4fe409f0-69e1-402a-adfb-5d63af6eb971 | completed | f | 2026-07-30 09:41:37.290228 | 2026-07-30 09:47:47.218879 | 24 | 53691cc4ee053d016aadfc42845694ea | cfd343b05355e353d2bb7797e658077b |
| ed93da46-7076-4cfa-96b4-26e6be429768 | completed | f | 2026-08-06 16:49:05.990173 | 2026-08-12 08:49:25.74409 | 4 | 0c8fcca0fe78fda622693f7db5f6794f | 977df532b4b72853fe6e14b84d736ae3 |

Summe: 115 Antworten.

## Lernpfad und Report an c017bf9e

| Tabelle | Zeilen |
|---|---|
| lernpfad | 0 |
| lernpfad_belege | 0 |
| lernpfad_protokoll | 0 |
| eltern_reports | 0 |
| parent_reports | 0 |
| parent_report_generations | 0 |

## Kontrolle nach dem Einspielen

Eingespielt am 14.10.2026 06:41 UTC (`~/bin/mig 20261014064047 batu_altleads_test`, je Lead 1 Zeile).
Dieselbe Abfrage um 06:41:34 UTC erneut per dbread, Ausgabe gegen die obige per `diff` verglichen:

- abweichend nur die beiden Leads: `ist_test = t`, `full_name` „Batu Demirel (alt 07/2026)“ bzw.
  „Batu Demirel (alt 09/2026)“; `first_name`, `status`, `created_at` gleich, `rejected_at` weiter leer
- Schülerzeile c017bf9e unverändert
- alle 10 Sessions gleich: Status, testlauf, Zeiten, Antwortzahl, `antworten_md5`, `summary_md5`
- Lernpfad und Report weiter 0 Zeilen
- `schema_migrations`: `20261014064047 | batu_altleads_test` vorhanden
