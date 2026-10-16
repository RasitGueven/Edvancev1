# Retro 16.10.2026 · loesungsweg_endet_falsch ohne Fehlalarm

**Gebaut:** Migration `20261016112652_lwef_regel_hauptweg.sql` (nur `pruef_auffaelligkeiten`), pgTAP `lwef_regel` (12),
`schema-erwartet.sql` aus dem Neuaufbau, Doku-Block in `schema.sql`.

**Entscheidung:** Zwei Lesarten statt einer. Das Ende des Hauptwegs (ohne Klammer-Einschübe, ohne Probe/Kontrolle/Check/denn,
erste Zahl nach dem letzten `=`/`≈`) allein hätte an 15 Pilot-Aufgaben neue Fehlalarme erzeugt
(`≈ 3,3166 … ≈ 3,32 m`, `= −14 … = 8 cm`). Deshalb: Befund nur, wenn beide Lesarten nicht voll sind. Nachher ⊆ vorher.

**Gemessen (Wegwerf-DB, Prod-Abzug der 255 Pilot-Aufgaben):** vorher 36 Aufgaben / 64 Befunde, davon 6 × loesungsweg_endet_falsch;
nachher 30 / 58, 0 × loesungsweg_endet_falsch. Geändert haben sich genau die 6 Belege.

**Befunde gespeichert?** Nein. `pruef_aufgabe` und `pruef_speichern` rechnen sie bei jedem Aufruf neu; `task_pruefung_ausgang`
sichert nur die Inhaltsfassung. Kein Datenteil nötig.

**Offen:** Einspielen in Prod (Rasit), danach `tools/schema-snapshot.sh`.
