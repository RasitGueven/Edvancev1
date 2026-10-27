# A0 · Doppel-Aufgaben (Haltepunkt)

Stand 27.10.2026, alle Zahlen per `~/bin/dbread` gegen Prod.

## Markierung heute

`tasks.einsatz text[] not null default '{lsa,session}'`, CHECK `einsatz <@ {lsa,session,check,quest}`
und `tasks_einsatz_quest_allein`. Die LSA filtert über `lsa_im_pool(task)` (`'lsa' = any(einsatz)`, ready,
aktiv, kein Tutorial, Antworten vorhanden, eindeutiges Eingabeformat), die Session über
`session_im_pool(task)` (`'session' = any(einsatz)`, ready, aktiv, Antworten vorhanden).

## Zählung

```sql
select einsatz, status, count(*) from tasks group by 1,2 order by 1,2;
select count(*) filter (where lsa_im_pool(id) and session_im_pool(id)) beide_im_pool,
       count(*) filter (where lsa_im_pool(id)) lsa_pool,
       count(*) filter (where session_im_pool(id)) session_pool from tasks;
with l as (select distinct task_id from lsa_ausgegeben), s as (select distinct task_id from session_ausgegeben)
select count(*) from l join s using(task_id);
```

| Lesart von „beide Markierungen" | Anzahl |
|---|---|
| `einsatz @> '{lsa,session}'` (alle Status) | **1184** (1038 draft, 146 ready) |
| davon `ready` | **146** |
| tatsächlich in beiden Pools (`lsa_im_pool` und `session_im_pool`) | **144** |
| in beiden tatsächlich schon gezogen (`lsa_ausgegeben` ∩ `session_ausgegeben`) | **12** |

Alle anderen Werte: `{lsa}` 2 (1 ready), `{check}` 1. Es gibt **keine** Aufgabe nur mit `{session}`.
Der LSA-Pool hat 145, der Session-Pool 146 Aufgaben.

**Keine Lesart ergibt „rund 40".** Die Markierung ist der Spalten-Default; fast jede Aufgabe trägt beide.

## Folge der Regel aus Entscheidung 4

„Alle Aufgaben mit beiden Markierungen werden lsa" hieße wörtlich: Der Session-Pool fällt von 146 auf
**0 ready-Aufgaben** (nur noch die eine `{check}`-Aufgabe ohne Session-Markierung bleibt außen vor).
Jeder Skill verliert seine Session-Aufgaben, bis Bauform-Instanzen freigegeben sind. Betroffen wären
auch die laufenden Session-Skills (z. B. `fkt_linear_*`, `zahl_wurzel_*`).

## Liste

Die 144 Aufgaben in beiden Pools stehen mit id, Skill, Status, is_diagnostic, einsatz, input_type und
difficulty in `doppel-aufgaben-im-pool.csv`. Je Skill:

| Skill | n | Skill | n |
|---|---|---|---|
| bruch_dezimal | 4 | proportionalitaet | 2 |
| bruch_kuerzen | 3 | runden_ueberschlag | 10 |
| dezimal_add_sub | 3 | term_ausmultiplizieren | 4 |
| dezimal_div | 3 | term_binom_quadrat | 4 |
| dezimal_mult | 3 | term_einsetzen | 2 |
| geo_flaeche_dreieck | 2 | term_zusammenfassen | 3 |
| geo_flaeche_rechteck | 2 | vorzeichen_add_sub | 7 |
| geo_koordinaten | 3 | vorzeichen_mult_div | 7 |
| geo_umfang | 2 | vorzeichen_vorrang | 3 |
| gleichung_beidseitig | 3 | zahl_wurzel_gesetze | 6 |
| gleichung_einschrittig | 2 | zahl_wurzel_irrational | 6 |
| gleichung_modellieren | 3 | zahl_wurzel_naeherung | 6 |
| gleichung_zweischrittig | 4 | zahl_wurzel_quadrat | 5 |
| groessen_flaechen | 2 | zahl_wurzel_teilweise | 6 |
| groessen_laengen | 2 | potenzen | 19 |
| (ohne skill_key) | 13 | | |

In beiden schon gezogen (12): dezimal_add_sub 1, fkt_linear_gleichung 1, fkt_linear_graph 1,
fkt_linear_nullstelle 2, fkt_linear_steigung 1, fkt_linear_yabschnitt 1, gleichung_beidseitig 1,
gleichung_modellieren 2, zahl_wurzel_gesetze 1, zahl_wurzel_quadrat 1.
