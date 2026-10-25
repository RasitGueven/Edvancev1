Du arbeitest im Repo Edvancev1 (WSL). Paket L2: Prüfen, ob die freigegebenen LSA-Aufgaben für Batu (Klasse 9, Friedrich-Wilhelm-Gymnasium, Thema Reelle Zahlen und Wurzeln, Klassenarbeit dazu geschrieben) die Breite und den Ausblick auf die nächsten Klassenarbeiten tragen, und sicherstellen, dass nie dieselbe oder eine fast gleiche Aufgabe mehrfach hintereinander kommt. Erst messen, dann gezielt ändern.

FREIGABE RASIT (25.10.2026, gilt nur für diesen Auftrag): Migrationen selbst einspielen (Muster CLAUDE.md §10) und selbst über PR nach dev mergen, wie im V4-Auftrag.

## Schritt 0 · Lesen
- supabase/migrations/20261022131358_lsa_v2_ausblick.sql (aktuelle lsa_select_next_core, lsa_urteil_buchen_core, lsa_ist_ausblick), 20261022065539_lsa_v_vorschau.sql, 20261011140200_f1_lsa_pool_testkonten.sql
- docs/lsa/Bauauftrag-LSA-V.md, Bauauftrag-LSA-V2.md, lsa-v2-simulation.md, freigabeliste-vorschau.md
- tools/lsa-testkinder/ (README, kinder.sql, erzeugen.sql, simulation.sh, auswertung.sql)
- Gibt es docs/report/v4/Bauauftrag-V4.md schon auf dev: Entscheidung 1 (Fahrplan) lesen. Sonst: Der Bericht zeigt die geschriebene Arbeit und die nächsten bis zu vier Plan-Themen als Klassenarbeiten.

## Schritt 1 · Ist-Stand per dbread (nur lesend), Tabelle in docs/lsa/l2-batu-pool.md
1. Batus Fahrplan aus dem FWG-Plan Klasse 9 (schul_themenplan): aktuelles Thema und die nächsten Plan-Themen in Reihenfolge.
2. Für jede Gruppe die Bereiche (Skills), die die LSA prüfen soll:
   a. Themenraum des aktuellen Themas (wie lsa_start ihn bildet)
   b. je kommendem Thema (die ersten DREI): die Randknoten bzw. Voraussetzungen, wie die Vorschau sie bildet, plus die Voraussetzungen, die der Bericht für sein Signal nutzt (skill_kante s → g mit Heimat-Thema von s = Thema)
   c. Grundlagen Klasse 5/6 und 7/8, die Tiefe bzw. Rückblick erreichen können
3. Je Bereich: Klasse, Feld, Zahl freigegebener Aufgaben (status wie der LSA-Pool für echte Kinder, NICHT der Testkonto-Pool), davon ohne MC, sondierrang-Verteilung, Zahl im Entwurf.
   Regel aus der Freigabeliste: mindestens 2 freigegebene Aufgaben, mindestens 1 ohne MC. Lücken markieren.
4. Fast-Duplikate im freigegebenen Pool: Aufgaben desselben Skills, deren Text nach Normalisierung (Zahlen durch #, Leerzeichen, Groß/Klein) gleich ist oder sich nur in Zahlen unterscheidet. Liste je Skill.

## Schritt 2 · Simulation „Batu“ (CI-Neuaufbau, nie gegen Prod)
1. Neues Testkind „Batu“ in tools/lsa-testkinder/kinder.sql: Klasse 9, Schule mit dem FWG-Plan Klasse 9 als Fixture (aus Schritt 1.1, nur Themen-Keys und Reihenfolge), Thema reelle_zahlen, Klassenarbeit geschrieben. Antwortprofil aus Batus Testlauf vom 24.10. (Urteile per dbread, als Profil festgeschrieben, ohne IDs): traegt → richtig, traegt_nicht/teilweise → falsch, nicht_angesetzt → „Weiß ich nicht“; für Skills ohne Urteil: Klasse ≤ 6 richtig, 7/8 nach Feld wie in seinem Testlauf (Terme & Gleichungen eher falsch, Geometrie gemischt), 9 wie Thema. Profil im README begründen.
2. Pool für die Simulation: genau die freigegebenen Aufgaben aus Prod (Inhalte nicht nötig, nur id, skill_key, input_type, sondierrang, normalisierter Text-Hash aus Schritt 1.4) als Fixture.
3. Ausgabe je Lauf (Tabelle): Nr · Minute · Phase · Skill · Feld · Klasse · Gruppe (Thema / Voraussetzung KA2 / KA3 / KA4 / Grundlage / Ausblick / Rückblick) · Text-Hash · Ergebnis.
4. Auswertung:
   - Abdeckung je Gruppe: geprüft / vorgesehen; insbesondere je kommender Klassenarbeit, ob jede Voraussetzung, die im Bericht das Signal bestimmt, direkt geprüft wurde.
   - Wiederholungen: (a) dieselbe task_id zweimal (darf nie vorkommen), (b) gleicher Text-Hash zweimal in der Sitzung, (c) gleicher Text-Hash direkt hintereinander, (d) derselbe Skill mehr als 2× hintereinander, (e) dasselbe Feld mehr als 4× hintereinander.
   - Ende: Zeit, Deckel 40 oder leere Auswahl; Zahl der Aufgaben.

## Schritt 3 · Gezielte Änderungen (nur was die Messung belegt)
A. Fast-Duplikate: In einer Sitzung kommt keine Aufgabe, deren normalisierter Text einer schon ausgegebenen Aufgabe gleicht. Umsetzung in lsa_select_next_core an allen Stellen, an denen heute lsa_ausgegeben ausgeschlossen wird, über eine gemeinsame Hilfsfunktion (z. B. lsa_text_schluessel(task_id) als immutable Normalisierung, mit Index oder generierter Spalte auf tasks, wenn die Laufzeit es braucht). Ausnahme: Gibt es für einen Zweitbeleg nur noch Fast-Duplikate, entfällt der Zweitbeleg (Urteil mit einer Probe, wie heute bei leerem Pool), statt dieselbe Aufgabe mit anderen Zahlen zu stellen.
B. Hintereinander: Nach einem Zweitbeleg (also 2 Aufgaben desselben Skills) kommt als Nächstes keine dritte Aufgabe desselben Skills. Prüfe, ob die heutige Logik das schon garantiert; wenn ja, nur per Test absichern.
C. Ausblick auf die nächsten Klassenarbeiten: Deckt die Vorschau bei Batu die Voraussetzungen der ersten DREI kommenden Themen nicht ab (heute c_vorschau_themen = 2), erhöhe c_vorschau_themen auf 3, aber nur, wenn die Simulation danach für ALLE Testkinder zeigt: Themenraum-Abdeckung nicht schlechter als vorher, kein Kind über 40 Aufgaben, Ende spätestens 19 Minuten. Sonst bei 2 lassen und den Grund melden.
D. Pool-Lücken (Schritt 1.3) nicht selbst füllen. Daraus entsteht eine neue Freigabeliste für Lena: docs/lsa/freigabeliste-batu-1025.md mit den Bereichen, für die Aufgaben fehlen oder nur MC frei ist, je Bereich die Entwürfe, die es schon gibt (Kurztitel), sortiert nach Wichtigkeit: Voraussetzung KA2 vor KA3 vor KA4 vor Grundlagen.
Alle Änderungen an Funktionen in EINER Migration supabase/migrations/<V>_lsa_l2_wiederholung.sql mit Rollback; lsa_select_next_core bleibt unter 20 ms je Aufruf (Messung vorher/nachher wie in LSA-D).

## Schritt 4 · Nachher-Simulation und Merge
1. Simulation vorher/nachher für Batu und alle Testkinder; Tabellen in docs/lsa/l2-simulation.md.
2. pgTAP: supabase/tests/lsa_l2_wiederholung.test.sql (kein Fast-Duplikat in einer Sitzung, nie 3× derselbe Skill hintereinander, Zweitbeleg entfällt bei nur Fast-Duplikaten, ggf. 3 kommende Themen in der Vorschau). Alle bestehenden LSA-Tests grün.
3. Zweitprüfung durch einen frischen Subagenten (Kernlogik): liest Migration und Simulation, prüft die Regeln A–C gegen die Ausgabe.
4. Migration einspielen (Muster CLAUDE.md §10, vorher pg_proc auf die geänderten Funktionen prüfen), per dbread nachweisen, Schema-Snapshot. PR gegen dev, gh pr checks --watch (nur session_a2 rot = bekannt), gh pr merge --merge. Retro.

## Leitplanken
- Worktree ../Edvancev1-l2 auf feat/rasit-lsa-l2-batu-pool von origin/dev.
- Simulationen nur im CI-Neuaufbau bzw. in der Wegwerf-DB, nie gegen Prod. Prod nur lesend.
- Nicht anfassen: lsa_finish, lsa_durchklick_stand, Report- und Präsentationscode (läuft in der V4-Session), Aufgabeninhalte (L1).
- Keine echten Namen, IDs oder Zeitstempel ins Repo; das Testkind heißt „Batu“, sein Profil enthält nur Skill-Keys und Ergebnisse.
- Dateien ≤ 400 Zeilen.

## Melden
PR-Link; Abdeckungstabelle je Gruppe vorher/nachher (vor allem: welche Voraussetzungen von KA2, KA3, KA4 direkt geprüft werden); Wiederholungs-Befunde (a)–(e) vorher/nachher; Entscheidung zu c_vorschau_themen mit Begründung; Laufzeit; die neue Freigabeliste für Lena; offene Punkte.
