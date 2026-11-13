# IU-1 · Fortschritt

| Zeit (UTC) | Phase | Schritt | Ergebnis |
|---|---|---|---|
| 08:20 | U0 | Worktree, Dummy kopiert und durchgeklickt (10 Fotos) | ok |
| 08:20 | U0 | Ist-Analyse 1–6, Abfragen und Ausgaben, Regressionsbasis `pruef_ziel_liste` (md5 fb85…4b49, 91 Zeilen) | ok, Befund O1 |
| 08:43 | U0 | PR #412, CI `neuaufbau` dreimal rot (pg_attver, Runner-Image) | HALTEPUNKT O4 |
| 08:43 | U1 | Migrationen `20261113082550_iu1_inhalte`, `20261113082906_iu1_pruefziel_msa`, Rollbacks; lokal Neuaufbau ok, Schema-Abzug nur eigene Objekte | ok |
| 08:43 | U1 | pgTAP `iu1_inhalte` 48/48; ganze Suite: 98 grün + 2 (Pfad) grün, 8 bekannt rot wie dev | ok |
| 08:43 | U1 | Rollback lokal: Schema = Stand vor IU-1 (gefilterter Vergleich leer) | ok |
| 08:43 | U1 | Prod-Fixture (dbread \copy): `pruef_ziel_liste()` vor/nach Migration md5-gleich; MSA 35/9/78, 165 fehlende Texte (Bericht 36/9/77, 163: Unterschied = 2 zu schwere Pool-Aufgaben `geo_flaeche_drachen_raute`) | ok |
| 08:43 | U1 | Laufzeit Prod-Fixture mit Speicher: Reiter LSA ≈ 30 ms, Reiter Reihen ≈ 80 ms; Neuberechnung 1,6 s | ok |
| 08:55 | U1 | Zweitprüfung (frischer Subagent): kein „bricht“; behoben: Themenraum direkt wie raum_a (falsch), Entwurf-Bauformen (falsch), fehlende Trigger (fehlt); dazu Sequenz statt Zeilensperre, echte WHERE, Grants-Tests | ok |
| 08:55 | U1 | pgTAP 54/54, Suite grün bis auf 8 bekannte, Prod-Fixture md5 gleich, PR #416 | nicht eingespielt (O4) |
| 08:55 | – | STOPP: Merge und Einspielen gesperrt bis CI grün (O4); U2–U5 nicht begonnen | HALTEPUNKT |
