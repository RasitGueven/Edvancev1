# Zweitprüfung A5 (Migration 20261027143548_reihe1_a5_board)

Frischer Subagent ohne Kontext (28.10.2026). Er hat die Funktionen als Lena in einer zurückgerollten Transaktion in
der Wegwerf-DB von Hand aufgerufen (NP-2 mit p_seed 3: sechs Beispiele, Stufen 1, 2, 2, 3, 3, 4). Kein P1. Sicherheit
in Ordnung: alle fünf Funktionen prüfen zuerst `darf_pruefen()`, Kinder und anon bekommen 42501, Rechte per
`proacl` bestätigt; `skill_pruefung_entscheiden` kann die Admin-Freigabe nicht umgehen.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | P2: Inner Join auf `task_solutions` nach `limit 6` lässt ein Beispiel still wegfallen | Kandidaten nur mit Lösungszeile (`exists`) |
| 2 | P2: wirft `aufgabe_payload` für eine kaputte Instanz, scheitert das ganze Detail | Bewusst so: eine Instanz ohne lesbare Kindersicht ist ein Fehler, den Lena sehen soll, nicht ein stilles Loch. Prüfmaschine und CHECKs verhindern solche Instanzen. |
| 3 | P2: neue Entscheidung zu einer Prüffrage überschreibt Prüfer und Notiz | Gewollt: es gilt die letzte Entscheidung. Ein „passt“ macht die alte Ablehnungsnotiz gegenstandslos. Ein Verlauf ist für eine Einzelfrage nicht verlangt (Konzept §6). Im DATENVERTRAG §13.8 benannt. |
| 4 | P2: pgTAP ohne Fälle für Notiz, Freigegeben, Coach ohne Recht | ergänzt: `passt_nicht` speichert die Notiz, freigegeben → P0002, Coach ohne Recht → 42501 (21 Zusicherungen) |
| 5 | P2: „wird nicht mehr gezogen“ prüft nur „anders gezogen“; Reihenfolge der Meldungen bei gleichem `now()` zufällig | zusätzlich `not aufgabe_ziehbar(gezogen)`; Meldung per `@>` statt Index |
| 6 | P3: Filter des Boards wie Konzept §6, Hinweis „wartet auf Lauf“ fehlt | so gewollt; Bauformen mit Verdacht stehen im Bericht mit Grund (Abnahme 11) |
| 7 | P3: `bauform_auffaellig` mit Aufgaben ohne Bauform | Typen erlauben null; konsistent |
| 8 | P3: Auswahl bei weniger als sechs grünen Instanzen, NULL-Stufe | ohne Fehler; Instanzen tragen immer eine Stufe |
| 9 | P3: Migration nicht idempotent | Repo-Regel: eine Migration läuft einmal (History) |
| 10 | P3: DATENVERTRAG ohne die neuen Namen | §13.8 ergänzt |
