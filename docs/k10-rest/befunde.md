# K10-Rest – Befunde

Stand 03.10.2026 · Branch `feat/k10-rest` · Auftrag `W4-k10-rest.md`. Prod nur lesend über `dbread`, nichts
eingespielt. Planung: [`phase1.md`](phase1.md), Entscheidungen: [`entscheidungen.md`](entscheidungen.md),
Einspielen: [`einspielen.md`](einspielen.md), Heimat-Themen: [`skill_thema.md`](skill_thema.md), je Thema
`thema-<kurz>.md` (Tabelle aller Aufgaben mit AFB-Begründung, Antwort, Fehlbildern).

## Zahl der Aufgaben je Thema (für Lenas Planung)

Alle Aufgaben `status = 'draft'`, Kennzeichen `vorbefuellt`, `class_level = 10`, Stoffanker 10, keine Hinweise.

| Thema | thema_key | Knoten | Aufgaben | AFB I / II / III | davon MULTI_PART | mit Abbildung | Einstiege |
|---|---|---|---|---|---|---|---|
| Exponentialfunktionen | `exponentialfunktionen` | 5 | 30 | 10 / 15 / 5 | 4 | 2 | 3 |
| Trigonometrie | `trigonometrie` | 5 | 30 | 10 / 15 / 5 | 1 | 0 | 2 |
| Sinusfunktion | `sinusfunktion` | 5 | 30 | 10 / 15 / 5 | 7 | 0 | 1 |
| **Summe** | | **15** | **90** | 30 / 45 / 15 | 12 | 2 | 6 |

Übersprungene Themen: **keine**. Übersprungene Inhalte siehe unten (B1–B4).

## Prüfprotokoll

| Stufe | Werkzeug | Ergebnis |
|---|---|---|
| Graph | `tools/k10-rest-graph-check.mjs` gegen Prod-Abzug (`bestand-prod.json`) | 15 Knoten, 26 Kanten, Tiefe 7…12, echt flacher, keine transitive Doppelung |
| Rechnung | `tools/k10-rest-lib.mjs` (exakt; sin/cos/tan, Umkehrfunktionen, ln, bˣ auf 60 Stellen; Rundungsgrenzen, Kollisionen) | alle 3 Chargen ohne Ablehnung |
| Parser-Fallstrick | `tools/k10-rest-minuscheck.mjs` | keine mehrdeutigen Ausdrücke |
| verify-prefill | `verify-tasks --prefill … --snapshot … --blind …` | **0 Gate-Fehler** in allen 3 Chargen (`docs/prefill/k10-*-verifikation.md`) |
| Blind-Löser | je Thema ein frischer Subagent, nur Export (`tools/blind-loeser`), Vergleich `verify-tasks --from-file … --answers-from … --min-pass 1.0` | **90/90, 100 %**, 0 Abweichungen, kein zweiter Löser nötig (`docs/prefill/k10-*-blind.json`). 2× „unsicher" (Sinus) nur, weil π-Taste und 3,14 verschieden runden; beide Werte stehen in `correct_answers` (geprüft) |
| Wegwerf-DB 1 | `tools/k10-rest-wegwerf-db.sh` (Grundlage + 130 Migrationen von origin/dev d3f3afe + 8 neue, zweimal, ohne Klammer wie CI) | grün, **idempotent** (130 Knoten, 224 Kanten, 101 Fehlbilder, 556 Aufgaben, 28 Figuren, 45 Einstiege in beiden Läufen) |
| Wegwerf-DB 2 | entfällt (E2) | K9-Migrationen sind Teil der Basis |
| Prüfskripte lokal | 8 Skripte, `-v lokal=true` | **76 von 76 t** |
| Prüfskripte gegen Prod | `dbread -f …` vor dem Einspielen | laufen fehlerfrei (nur lesend); Zeilen erwartungsgemäß noch `f` |
| Figuren | `DATABASE_URL=postgresql:///k10_alle upload_figures.py --dry-run` | geladen=28 (2 neu + 26 lokal ohne Hash) **fehler=0** |
| Frontend | `npx tsc --noEmit`, `npm run typecheck`, `npm run lint`, `npm run test` | grün (67 Dateien, 686 Tests) |
| Schema | reine Datenmigrationen (skills, skill_kante, fehlbild_labels, tasks, task_solutions, task_figures, thema_einstieg, skill_thema) | kein Schema-Abzug nötig |
| Versionen | Prod (`schema_migrations`, max. 20261003120051), `git log --all`, `~/wt/k8-rest`, `~/wt/k9-rest` | keine Kollision |

## Übersprungene Inhalte (mit Grund)

| Nr. | Inhalt | Grund |
|---|---|---|
| B1 | **Sinussatz** | Nicht in den Kompetenzerwartungen der Sek I (KLP G9 NRW Geo-8 nennt nur den Kosinussatz). |
| B2 | **Graph der Sinusfunktion als Abbildung** (Amplitude/Periode/Nullstellen ablesen, Term zum Graphen) | `koordinatensystem` kann keine Sinuskurve zeichnen, kein neuer Generator. Ersatz: Eigenschaften aus dem Term oder aus im Text genannten Hoch-/Tiefpunkten. Vorschlag: Generator-Typ `sinus {a,b,d}` (eigener Auftrag). |
| B3 | **Graph der Exponentialfunktion** (Asymptote, Monotonie, Kurvenverlauf) | Generator kann keine Exponentialkurve; abgedeckt nur „Punkte des Graphen ablesen" (2 Aufgaben). Vorschlag wie B2: Typ `exponentiell {a,b}`. |
| B4 | **Fkt-11** (Messreihen mit digitalen Werkzeugen) und **Fkt-10 „Modell begründet wählen"** als Entscheidung | Keine Werkzeug- oder Auswahl-Eingabe im Player (nur Zahl/Bruch). Fkt-10 indirekt über Fortschreiben und das Fehlbild `linear_statt_exponentiell`. |
| B5 | Phasenverschiebung, Kosinusfunktion als eigener Graph | Nicht im Auftrag; Kosinus nur am Einheitskreis. |

## Offene Punkte und Befunde

| Nr. | Befund | Umgang / Vorschlag |
|---|---|---|
| O1 | **Prämisse des Auftrags überholt:** K9 ist in Prod. Keine `kanten_k10_k9.sql`, keine zweite Wegwerf-DB (E1, E2). | Nichts zu tun; Einspielen in einem Zug. |
| O2 | **Versionen neu vergeben:** Während des Laufs kam #196 (`20261003120051_vera8_ohne_bild_zurueck`) nach dev und Prod. Die ersten Substrat-Versionen (…115741–43) wären älter gewesen → alle 8 neu (`121328` … `121336`), alle Dateien neu erzeugt und neu geprüft. | Kommt vor dem Einspielen erneut etwas Neueres: Versionen per `date -u` neu, `docs/k10-rest/versionen.txt` anpassen, `node tools/k10-rest-substrat.mjs <kurz>`, `node tools/vorlauf-build.mjs docs/prefill/k10-<kurz>.json <Version> aufgaben_k10_<kurz>`, Einstieg/skill_thema umbenennen. |
| O3 | **Abstieg trägt erst nach Freigaben anderer Läufe:** `prozent_zins_zinseszins`, `fkt_linear_gleichung`, `fkt_linear_steigung`, `zahl_potenz_negativ`, `geo_aehnlich_streckfaktor`, `geo_pythagoras_hypotenuse`, `term_einsetzen`, `geo_koordinaten`, `geo_kreis_sektor` haben keine ready-Aufgaben (je 6 Entwürfe mit Rang 1+2). | Lena: diese Entwürfe vor den K10-Themen freigeben. Keine Auffüllung (E11). |
| O4 | **Figuren vor Freigabe hochladen:** `exp-term-04` und `exp-term-05` (Rang 1 von `fkt_exp_term` liegt auf term-05) sind ohne Upload nicht lösbar. | Teil 6 vor Lenas Freigabe. `upload_figures.py` hat keinen Filter (wie K9 B4): vor dem echten Lauf per dbread prüfen, dass nur diese 2 Zeilen ohne `svg_hash` sind. |
| O5 | **Tiefen-Reserve null:** `fkt_exp_anwendung` hat Tiefe 12. | Ein späterer Oberstufen-Knoten müsste an `fkt_exp_term` (11) hängen oder die Prozentkette (Zinseszins 9) verkürzt werden. |
| O6 | **Klartexte erweitert** (vor dem Einspielen, nichts in Prod): `sin_cos_vertauscht` nennt jetzt auch den Tangens-Kehrwert; `periode_falsch` auch b = p : 2π. Grund: so verwenden die Chargen sie. | Bei Lenas Abnahme prüfen. |
| O7 | **Bestands-Slugs ohne Klartext mitbenutzt:** `mal_exponent`, `umgekehrt_geteilt`, `halbieren_vergessen` (Faktor ½ beim Dreiecksflächeninhalt), `betrag_fehler` (−3 als 3), `multipliziert_statt_dividiert`. | Klartext/Familie in der Spec `fehlbild-labels-eltern.md`. |
| O8 | **Neue Slugs ohne Familie (NULL):** `anfangswert_faktor_vertauscht`, `log_falsch_geteilt`, `sin_cos_vertauscht`, `tangens_verwechselt`, `umkehrfunktion_vergessen`, `bogenmass_modus`, `pythagoras_ohne_rechten_winkel`, `periode_falsch`, `amplitude_verwechselt`. | Entscheidung Lena; ggf. neue Familie „trigonometrie". |
| O9 | **Schwache Fehlbildwerte:** `bogenmass_modus` liefert oft negative Längen (sin 35 im Bogenmaß); `exp-anwendung-01/-02` haben einen Fehlwert 1; `exp-halbwert-01` einen langen Fehlwert (0,001953125). | Diagnose korrekt, Trefferwahrscheinlichkeit gering; bewusst so gelassen. |
| O10 | **`trigo-anwendung-04`** verlangt, den Wechselwinkel (Sichtlinie von oben) zu erkennen; das steht nur im Lösungsweg. | AFB III; Blind-Löser löste richtig. |
| O11 | **verify-prefill ohne `--migration`** (wie K9): Der VERA8-Gate-Check meldet sonst jede `insert`-Anweisung, weil er für prefill-UPDATEs bestehender Aufgaben gedacht ist. Neue Aufgaben mit festen ids können keine VERA8-Aufgabe treffen. | Werkzeug-Befund: Check für vorlauf-build-Migrationen auf UPDATEs beschränken. |
| O12 | Lösungswege nennen negative Ergebnisse mit ASCII-Minus (`x = -3`). | Kosmetisch, wie K9 B12. |
| O13 | Kölner Schulpläne: Der Auftrag nennt 30/28/25 Schulen, `docs/themen/schulplaene.csv` enthält je 25 Schulen mit den drei Themen in Klasse 10. | Nur Quellenhinweis. |

## Werkzeuge (neu, im PR)

`tools/k10-rest-lib.mjs` (aus der K9-Lib, erweitert um Winkel-/Exponentialfunktionen), `k10-rest-substrat.mjs`,
`k10-rest-pruefung.mjs`, `k10-rest-graph-check.mjs`, `k10-rest-minuscheck.mjs`, `k10-rest-wegwerf-db.sh`, je Thema
`tools/k10-<kurz>-charge.mjs`. `tools/vorlauf-build.mjs` unverändert.
