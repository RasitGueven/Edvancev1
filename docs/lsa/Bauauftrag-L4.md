Du arbeitest im Repo Edvancev1 (WSL). Paket L4: Nachtrag zu L3 – Voraussetzungen direkt prüfen statt nur mitbelegen, kein kommender Stoff ohne Thema, Berichtstexte nach Klassenarbeits-Stand. Erst simulieren, dann umsetzen. Arbeite alles von Schritt 0 bis zum Melden in einem Rutsch ab. Lege diesen Auftrag wörtlich als docs/lsa/Bauauftrag-L4.md in den PR.

FREIGABE RASIT (25.10.2026, gilt nur für diesen Auftrag): Migrationen selbst einspielen (Muster CLAUDE.md §10, eine &&-Kette, Nachweis per dbread danach) und selbst über PRs nach dev mergen, auch mehrmals (nie Push auf dev oder main, nie Force-Push, nie Rebase, nichts in .github/).

LEITSATZ RASIT (gilt weiter): Kinder bekommen in der LSA nur Stoff, den sie schon hatten. Kein Ausblick (#324). Ausdrücklich so entschieden: Das aktuelle Thema laut Schulplan zählt als „hatte“, auch wenn der Kernlehrplan einzelne Einstiege eine Klasse höher führt (L3-offen Punkt 2, Themenraum bleibt ohne Klassengrenze).

## Schritt 0 · Stand herstellen
- Ist PR #325 (L3) in origin/dev gemergt? Falls nicht: gh pr checks 325 (nur session_a2 rot = bekannt), dann gh pr merge 325 --merge. Migration 20261025223011 ist laut Retro schon in Prod, per dbread bestätigen.
- PR #323 ist in #324 enthalten: falls noch offen, gh pr close 323 --comment "in #324 enthalten".
- Lesen: docs/lsa/Bauauftrag-L3.md, l3-simulation.md (vor allem 6.1–6.4), l3-offen.md, Retro L3; supabase/migrations/20261025223011_lsa_l3_ka_modus.sql; die aktuelle lsa_urteil_buchen_core (20261022131358_lsa_v2_ausblick.sql) und lsa_mitbelegung (20260723100000_a15_lsa_auswahl.sql); im Bericht src/lib/report/fundament.ts, src/lib/supabase/lsaReportSkills.ts, src/types/report.ts (der Bericht nutzt NUR belegt_direkt), src/lib/report/elternbericht/schwerpunkte.ts (themaGrund), fahrplan.ts, bericht.ts, die Seite-3-Texte und Station 03.
- Worktree ../Edvancev1-l4 auf feat/rasit-lsa-l4-nachtrag von origin/dev (nach dem Merge von #325).

## Teil A · Bericht-Voraussetzungen direkt prüfen (statt nur mitbelegt)
Anlass: Bei Batu belegt die erste Themenaufgabe (zahl_wurzel_irrational richtig) bruch_dezimal, dezimal_div und potenzen mit, zahl_wurzel_naeherung belegt runden_ueberschlag mit. Ein mitbelegtes Urteil ist heute final, die Vorschau überspringt diese Knoten, und der Bericht zeigt sie bewusst nicht (nur belegt_direkt). Folge: Für Klassenarbeit 3 und 4 fehlt dem Bericht genau dort das Signal (11 von 17 statt mehr).

Entscheidungen (nicht neu verhandeln):
1. Der Bericht bleibt bei „nur direkt geprüft“. Mitbelegte Urteile werden NICHT als geprüft gezählt oder angezeigt.
2. Stattdessen: In der Vorschau (beide Modi) darf ein Knoten, der nur mitbelegt ist (Urteil vorhanden, belegt_direkt = false), noch einmal direkt geprüft werden, wenn er eine Bericht-Voraussetzung (★, die das Signal einer der nächsten drei Klassenarbeiten bestimmt, gleiche Definition wie l3-gruppen.sql „Bericht-Voraussetzung“) ist. Andere mitbelegte Knoten bleiben übersprungen.
3. Reihenfolge in der Vorschau: zuerst Knoten ohne Urteil wie heute, danach diese mitbelegten ★-Knoten. Sie verdrängen keine ungeprüften Voraussetzungen.
4. Das Ergebnis der direkten Probe ersetzt das mitbelegte Urteil (belegt_direkt = true, die üblichen Regeln für Zweitbeleg gelten). Ein falsches direktes Ergebnis gewinnt gegen ein mitbelegtes „sicher“. Kein Abstieg unter einen solchen Knoten, wenn er richtig ist; bei falsch Abstieg wie heute (eine Stufe, Klassengrenze).
5. Dafür darf lsa_urteil_buchen_core geändert werden, aber nur an dieser Stelle (mitbelegtes Urteil durch direktes ersetzen). Alles andere an der Funktion bleibt textgleich; diff im PR zeigen.
6. Leitsatz und Klassengrenzen gelten unverändert; Ende bleibt 19 Minuten oder 40 Aufgaben.

## Teil B · Ohne Thema kein kommender Stoff
Anlass (l3-simulation.md 6.3): Hat das aktuelle Thema keine freie Aufgabe (v_mit_thema = false), läuft die alte Auswahl (Breite b, Schritt 5) und zieht Einstiege kommender Themen (Sophie, Max im Prod-Pool: 1 bzw. 2 Aufgaben).

Entscheidungen:
7. Auch ohne Thema gilt: keine Skills aus Themen, die laut Plan nach der aktuellen Position noch kommen (gleiche Mengen wie v_kommend / v_spaeter), und Klassengrenze = eigene Klasse. Ist die Planposition unbekannt, bleibt nur die Klassengrenze.
8. Die Vorschau auf die nächsten drei Klassenarbeiten (Voraussetzungen, inklusive Auffüllen aus Klasse + 1 nach L3) soll auch ohne Thema laufen, wenn ein Plan da ist. Prüfe in der Simulation, ob das heute schon so ist; falls nicht, so umsetzen, dass ohne Thema Vorschau → Breite → Rückblick läuft.
9. Wird eine Sitzung dadurch früh leer: nicht auffüllen, in der Simulation ausweisen.

## Teil C · Frische Prod-Fixture
10. Die L2/L3-Fixture (134 Aufgaben, Vormittag 25.10.) ist veraltet (heute 145 freigegeben). Neue Fixture per dbread (nur lesend), gleiche Form wie l2-fixture.sql, als l4-fixture.sql. Keine echten Namen, IDs oder Zeitstempel. Vorher/nachher mit beiden Fixtures rechnen.
11. In die Simulation zusätzlich: „Batu nach Lenas Freigaben“ = aktuelle Fixture plus die 36 Freigaben aus docs/lsa/freigabeliste-batu-1025.md als freigegeben simuliert (je Bereich die zwei Entwürfe, darunter jeweils der ohne MC). Ziel: zeigen, ob Batus LSA damit bis Minute 19 trägt.

## Schritt 1 · Simulation vorher (nie gegen Prod)
Wie L3 (simulation.sh im lokalen Neuaufbau, KINDER_ZUSATZ=l3-kinder.sql), alle L2- und L3-Kinder, Neuaufbau-Pool, l2-fixture, l4-fixture und „nach Lenas Freigaben“. Kennzahlen wie in L3 Abschnitt 3/4, zusätzlich die Spalte „mitbelegt → direkt“ (Anzahl ★-Knoten, die nachgeprüft wurden) und „Ausblick“ (Einstiege kommender Themen, auch ohne Thema).

## Schritt 2 · Umsetzen
EINE Migration supabase/migrations/<V>_lsa_l4_nachtrag.sql mit Rollback (Teil A und B). lsa_select_next_core bleibt unter 20 ms je Aufruf (Messung wie L3 Abschnitt 7).

## Schritt 3 · Abnahmekriterien (alle, sonst höchstens drei Runden, dann mit Befund melden)
- Kinder MIT Thema und ohne mitbelegte ★-Knoten: Folge Aufgabe für Aufgabe gleich wie vorher.
- BatuG/BatuN4 (Neuaufbau-Pool): KA direkt mindestens 15 von 17; die 5 mitbelegten Paare aus l3-simulation.md 6.1 sind direkt geprüft, soweit Zeit und Pool reichen. gleichung_quadr_formel bleibt ausgeschlossen.
- Sophie und Max (Prod-Fixtures): Ausblick = 0, keine Aufgabe über der eigenen Klasse.
- In keinem Lauf: Aufgabe über der eigenen Klasse außerhalb des aktuellen Themas, Ausblick > 0, über 40 Aufgaben oder 19 Minuten, Wiederholung nach L2-Regeln.
- „Batu nach Lenas Freigaben“: Ende durch Zeit (nicht „leer“). Falls doch leer, Bereiche nennen, die dann noch fehlen (das ist eine Liste für Lena, kein Grund zum Auffüllen).

## Teil D · Berichtstexte nach Klassenarbeits-Stand (Frontend, eigener Commit)
12. Die drei Fälle aus l3-offen.md „Für später“ in Bericht v4 und Präsentation umsetzen, an der Stelle, an der heute der individuelle Satz zur Arbeit im aktuellen Thema steht (Seite 3 und Station 03; themaGrund in schwerpunkte.ts). Texte (Namespace elternbericht bzw. praesentation, de):
    - steht an oder unbekannt: „Die Arbeit zu {Thema} steht noch an. Darauf bereiten wir zuerst vor.“
    - geschrieben, Note offen: „Die Analyse zeigt für {Thema}: sicher war {X}, noch unsicher {Y}. Sobald Sie die Note kennen, gleichen wir das gemeinsam ab.“
    - geschrieben, Note bekannt: „Die Arbeit zu {Thema} ist mit Note {n} zurückgekommen. Dazu passt, was die Analyse zeigt: {Y} war noch unsicher. {Y} wird bei Klassenarbeit {k} wieder gebraucht.“
    {X}/{Y} = Bereichsnamen aus belegt_direkt (höchstens zwei je Platzhalter). Ohne unsicheren Bereich: den Satzteil mit {Y} weglassen, nicht umformulieren. Ohne kommende Arbeit, die {Y} braucht: letzten Satz weglassen.
13. Quelle für Status und Note: lsa_sessions.ka_modus / ka_note der Sitzung, auf der der Bericht beruht (Stand beim LSA-Start). Fehlt das (alte Sitzung), leads.klassenarbeit_status / letzte_klassenarbeit_note. Ändert sich der Lead später, zeigt der Bericht trotzdem den Stand der Sitzung; Unterschied nur als Hinweis in der Admin-Ansicht, nicht im Elternbericht.
14. Leitplanken: keine erwartete oder prognostizierte Note, keine Ursachenbehauptung („dazu passt“, nie „weil“), kein „trägt/tragen“. Invariantentest um diese drei Texte erweitern.
15. LSA-Startdialog: Fehlen Status oder Note der letzten Klassenarbeit im Erstgespräch, ein Hinweis vor dem Start („Stand der letzten Klassenarbeit fehlt – die Analyse startet mit dem aktuellen Thema.“), mit Link ins Erstgespräch. Kein Blocker.
16. Tests: je Fall ein Fixture-Test (Batu V4-Fixtures um ka_modus/ka_note ergänzen), Druck-/Überlaufprüfung wie V4 (Seite 3 und Station 03 dürfen nicht überlaufen), Ansichtstests grün.

## Schritt 4 · Prüfen, einspielen, mergen
1. pgTAP supabase/tests/lsa_l4_nachtrag.test.sql: mitbelegter ★-Knoten wird in der Vorschau nachgeprüft, nicht-★ nicht; direktes Ergebnis ersetzt mitbelegtes; falsch gewinnt gegen mitbelegt-sicher; ohne Thema keine Skills kommender Themen und nichts über der Klasse; Leitsatz-Tests aus L3 weiter grün. Alle bestehenden LSA-Tests grün.
2. Zweitprüfung durch einen frischen Subagenten (Kernlogik und Berichtstexte): Migration gegen Entscheidungen 1–9, Texte gegen 12–15, Simulation gegen die Abnahmekriterien.
3. Vor dem Einspielen pg_proc auf alle geänderten Funktionen prüfen (md5 gleich mit dem Stand nach L3). Einspielen nach CLAUDE.md §10, per dbread nachweisen, Schema-Snapshot committen.
4. PR gegen dev, gh pr checks --watch (nur session_a2 rot = bekannt), gh pr merge --merge. Wenn Teil D länger braucht: Teil A–C als eigener PR zuerst mergen, Teil D als zweiter PR. Retro.

## Leitplanken
- Simulationen nur im lokalen Neuaufbau. Prod nur lesend, außer dem Einspielen der einen Migration.
- Keine echten Namen, IDs oder Zeitstempel ins Repo. Dateien ≤ 400 Zeilen (Ausnahme wie L3: lsa_select_next_core vollständig in einer Migration, im PR vermerken).
- Keine Stammdaten erfinden. Keine Noten- oder Ergebnisprognosen, nirgends.

## Melden
PR-Link(s); Simulationstabelle vorher/nachher je Kind mit KA direkt, „mitbelegt → direkt“, Ausblick, Ende; ob Batu nach Lenas Freigaben bis Minute 19 trägt (sonst Liste der fehlenden Bereiche); Laufzeit; diff von lsa_urteil_buchen_core; Screenshots Seite 3 und Station 03 für die drei Fälle; Ergebnis der Zweitprüfung; eingespielte Migration mit Version; offene Punkte.
