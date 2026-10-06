# Retro 2026-10-06 — Session-Rahmen P1, Paket Q1 (Home Quests)

## Gebaut
- Tabellen `quests`, `quest_aufgaben`, `push_tokens` mit RLS, dazu die Endpunkte `quest_erzeugen`,
  `quest_termin_setzen`, `quest_inhalt`, `quest_erledigt`, `push_token_registrieren`,
  `quest_erinnerungen_faellig` und `eltern_quest_wochenstand` (PR #215, Migrationen `20261007141352`–`…356`).
- Eingespielt am 06.10. Schema-Abzug aus Prod ist gleich dem Neuaufbau aus allen Migrationen.
- `home_quests_aktiv` bleibt aus, solange die Clinic prüft. In Prod gibt es noch keine Quest-Aufgabe.

## Entscheidungen
- Eigener Quest-Pool: `einsatz` enthält `quest`, nie zusammen mit `lsa`/`session`. Die Kombination verbietet
  die CHECK-Regel `tasks_einsatz_quest_allein`. Der Lösungsweg geht so nie an eine LSA- oder Session-Aufgabe.
- Ein Termin je Quest. Quest A wählt das Kind im Check-out, Quest B ist vorbelegt (Oberfläche in P2).
- `home_streak_sessions` zählt Wochen. Die Serie pausiert, wenn eine Woche ausfällt, und wird nie zurückgesetzt.
- XP über den Kern von `xp_buchen` (X0) mit dem Schlüssel `quest:<id>`.

## Gelernt
- `PGDATABASE=edvance_shadow` steht in der Shell. Wegwerf-DBs nur im eigenen Cluster mit ausdrücklichem
  `dbname`, je Paket mit eigenem Port.
- `not (a or b)` mit einem NULL-Vergleich lässt durch. Rechte-Prüfungen immer `coalesce(…, false)` und
  `coalesce(get_my_role(), '')`. Ein Test „fremder Coach“ hat die Lücke gefunden.
- Den pg_proc-Scan nach jedem Merge paralleler Pakete wiederholen: R1 brachte eine Überladung
  `quest_termin_setzen` mit, die erst nach dem Einspielen auffiel. Sie ist nicht mehrdeutig, aber doppelt benannt.
- Force-Push ist per Hook gesperrt. Nach einem lokalen Rebase stattdessen `origin/dev` mergen.

## Offen
Siehe `docs/session/offene-punkte-q1.md`: Quest-Inhalte, Anmeldung zuhause, Versand (Scheduler,
Eltern-Mail), Löschfristen (Windweiss), Verdrahtung mit R1/A1/C2, Coach-Filter für Testläufe in C2.
