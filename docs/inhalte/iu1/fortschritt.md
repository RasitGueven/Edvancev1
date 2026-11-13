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
| 10:54 | O4 | Wiederaufnahme nach WSL-Neustart: Worktrees sauber, Prod ohne IU-1-Migration. CI-PR #417 (pg_attver, einmalige Freigabe) grün, pgTAP gleich dem letzten grünen dev-Lauf (99 ok, 8 bekannt rot), gemergt `a38fdfda` | ok |
| 10:54 | U0 | #412 mit origin/dev gemischt (Rebase bräuchte Force-Push), CI grün, gemergt `939682d4` | ok |
| 10:54 | U1 | Zweite Zweitprüfung des Fix-Commits (frischer Subagent): kein „falsch“, kein „bricht“; typecheck ok, Vitest 3380/3380; CI #416 grün | ok |
| 10:54 | U1 | Eingespielt: `~/einspielen/IU1-1-inhalte.sh` (20261113082550), `~/einspielen/IU1-2-pruefziel-msa.sh` (20261113082906, NOTICE 122/122 Skills, 50/50 Aufgaben); Prod-Abzug = Neuaufbau bis auf Kopfzeilen | ok |
| 10:54 | U1 | Prüfabfrage `abfragen/q_u1_pruefung.sql` → `ergebnisse/u1-pruefung.txt`: 19 Funktionen, 14 Trigger, 1 Ziel, 122 Skills, 13/37 Ausschluss, FR-2-Speicher mit WHERE (O1) | ok |
| 10:54 | U1 | Regression: `pruef_ziel_liste()` md5 `fb85…4b49`, 91 Zeilen, 223 ids, rest 139 = U0 | ok |
| 10:54 | U1 | MSA 35/9/78, 165 fehlende Texte (Bericht MSA-1 36/9/77, 163: −1 bereit/+2 Texte durch 2 zu schwere Pool-Aufgaben `geo_flaeche_drachen_raute`); Lena MSA: 85 Skills, rest 161, 231 Vorschläge (vorher nicht in der Liste: 20 Skills); Themen: Lena prüft 137 (Liste ohne Ziel: rest 139, Rest = Fall-B-Skills) | ok |
| 10:54 | U1 | Laufzeit live (Speicher noch nie gerechnet): LSA 1,4 s + MSA 1,0 s, Reihen 0,4 s + ohne Reihe 1,4 s; mit Speicher (Prod-Fixture) ≈ 10 ms / ≈ 90 ms. Erster Seitenaufruf frischt auf | ok |
| 10:54 | U1 | O1: Funktionskörper mit WHERE bestätigt; Lauf unter safeupdate nur über den Quelltext belegt (lokaler Test mit gebautem safeupdate.so von der Rechteprüfung abgelehnt), pgTAP 9a/9b ohne safeupdate grün. Klassenarbeit bestätigen (Wegwerf-DB, ohne safeupdate): Insert in `schul_klassenarbeiten` geht durch, Speicher wird veraltet, Neuberechnung frisch mit 1 bestätigtem Paket | ok |
| 10:54 | U1 | Types: keine generierten DB-Types im Repo (`client.ts` ohne Database-Typ), nichts zu tun | ok |
| 11:27 | U1 | #416 nach SF-1-Merge mit origin/dev gemischt; Prod-Abzug (IU-1 + SF-1) = lokaler Neuaufbau; CI grün; gemergt `867c8988` | ok |
| 11:27 | U2 | Seite `/admin/inhalte` (Reiter, Filter Klasse, Details Thema/MSA/Reihe, Adresse teilbar), Navigation: „Inhalte-Übersicht“ statt „LSA-Abdeckung“ (Seite bleibt erreichbar, aktivBei) | ok |
| 11:27 | U2 | typecheck, lint, Vitest 3402/3402 (neu: 9 Hilfsfunktionen, 8 Seite); Ansichtstests 10/10 bei 1180×820 und 1440×900 mit Prod-Zahlen (`vorschau/daten.json`, dbread 12:16), Fotos `abnahme/u2-*` | ok |
| 11:33 | U2 | CI #418 grün, gemergt `3db548b1` | ok |
| 11:33 | U3 | „Gezielt prüfen“: Umschalter „Alle \| MSA (ZP10)“ (`?ziel=`), Gruppen je Bereich, erledigte eingeklappt mit Haken und im Fortschritt, „1 von 2“, Filter `?skill=` mit „Gefiltert: … · Filter aufheben“; ohne Parameter Aufruf wie bisher | ok |
| 11:33 | U3 | Vitest neu 3 (Seite) + 2 (Rechnung); Ansichtstests 6/6 bei 1180×820 und 1440×900 mit Prod-Daten als Lena (dbread 12:31), Fotos `abnahme/u3-*`; Befund O6 (Lauf folgt Gesamtliste) | ok |
| 11:41 | U3 | CI #419 grün, gemergt `422d1f72` | ok |
| 11:41 | U4 | Abnahme a–i (`abfragen/q_u4_abnahme.sql` → `ergebnisse/u4-abnahme.txt`): a, b, c (73/73), e, f (7 Sessions), g (0), i grün; d 19/56 statt 20/59 (`fkt_sinus_periodisch` nur zu schwere Entwürfe); h nur mit Speicher (O7) | ok, O7 |
| 11:41 | U5 | Bericht, Retro, Roadmap | ok |
