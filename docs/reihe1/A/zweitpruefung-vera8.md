# Zweitprüfung VERA8 entfernen (Migration 20261028143121_reihe1_vera8_entfernen)

Frischer Subagent ohne Kontext (28.10.2026). Kein Blocker. Bestätigt: der Wächter liest alle 23 FK-Tabellen auf
`tasks` dynamisch (in einer zurückgerollten Simulation brach er bei einem fremden Verweis ab); keine FK auf
`lsa_responses`/`task_solutions`, keine Lösch-Trigger; das Löschen trifft nur `source = 'VERA8_IQB'` und die neun
Sitzungen; 299 / 243 / 66 wie in Prod; die Sicherung hat dieselben Spalten wie Prod und 299 / 243 / 66 Zeilen.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | P2: Kommentar „Prefill legt VERA8 an“ falsch, Test im Neuaufbau leer | Kommentar richtig; pgTAP legt VERA8-Zeilen an und liest die Migration noch einmal ein (4 Zusicherungen) |
| 2 | P2: die 9 Sitzungen bleiben `completed`/auswertbar mit 0 Antworten (`result_summary` aus gelöschten Antworten) | Nicht verändert, weil das Löschen nur die Antworten umfasst. Verknüpfte Berichte, Lernpfade, Urteile, Notizen: 0. Offener Punkt für Rasit im Bericht (auswertbar=false setzen oder löschen) |
| 3 | P3: keine Zeilenzahl-Prüfung | `get diagnostics` je Löschschritt, Abbruch bei Abweichung |
| 4 | P3: Test schwach | siehe 1; andere Aufgabe bleibt bytegleich |
| 5 | P3: Restore lässt Trigger feuern, `lsa_sessions` nicht gesichert | Rollback-Hinweis mit `session_replication_role = replica`; die 10 Sitzungen stehen als Kommentar in der Sicherung |
| 6 | P3: VERA8-Daten und Import-Skripte im Repo | gelistet in `vera8-entfernen.md`; eigener PR auf Rasits Wort |
