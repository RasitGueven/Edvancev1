# K9-Rest – Befunde

Stand 03.10.2026 · Branch `feat/k9-rest` · Auftrag `W4-k9-rest.md`. Prod nur lesend über `dbread`, nichts
eingespielt. Planung: [`phase1.md`](phase1.md), Entscheidungen: [`entscheidungen.md`](entscheidungen.md),
Einspielen: [`einspielen.md`](einspielen.md), je Thema: `thema-<kurz>.md` (mit Tabelle aller Aufgaben,
AFB-Begründung, Antwort, Fehlbildern, Sondierrang).

## Zahl der Aufgaben je Thema (für Lenas Planung)

Alle Aufgaben `status = 'draft'`, Kennzeichen `vorbefuellt`, `class_level = 9`, Stoffanker 9, keine Hinweise.

| Thema | thema_key | Knoten | Aufgaben | AFB I / II / III | davon MULTI_PART | mit Abbildung |
|---|---|---|---|---|---|---|
| Reelle Zahlen, Wurzeln | `reelle_zahlen` | 5 | 30 | 10 / 15 / 5 | 1 | 0 |
| Potenzen | `potenzen` | 4 | 24 | 8 / 12 / 4 | 6 | 0 |
| Quadratische Gleichungen | `quadratische_gleichungen` | 4 | 24 | 8 / 12 / 4 | 12 | 0 |
| Quadratische Funktionen | `quadratische_funktionen` | 5 | 30 | 10 / 15 / 5 | 14 | 4 |
| Satz des Pythagoras | `pythagoras` | 5 | 30 | 10 / 15 / 5 | 0 | 3 |
| Körper | `prismen_zylinder`, `koerper_pyramide_kegel_kugel` | 5 | 30 | 10 / 15 / 5 | 0 | 0 |
| Bedingte Wahrscheinlichkeit | `bedingte_wahrscheinlichkeit` | 5 | 30 | 10 / 15 / 5 | 12 | 0 |
| Ähnlichkeit, Strahlensätze | `aehnlichkeit` | 4 | 24 | 8 / 12 / 4 | 0 | 0 |
| **Summe** | | **37** | **222** | 74 / 111 / 37 | 45 | 7 |

Übersprungene Themen: **keine**. Ähnlichkeit ließ sich als Text eindeutig formulieren (Blind-Löser 24/24,
0 unsicher).

## Prüfprotokoll

| Stufe | Werkzeug | Ergebnis |
|---|---|---|
| Graph | `tools/k9-rest-graph-check.mjs` gegen Prod-Abzug | 37 Knoten, 57 Kanten, Tiefe 5…9, echt flacher, keine transitive Doppelung |
| Tiefen-Guard | Negativkontrolle lokal | Kante 6→7 und 5→6 abgewiesen, Tiefe 13 vom CHECK abgelehnt |
| Rechnung | `tools/k9-rest-lib.mjs` (exakt, Wurzeln 40 Stellen, π 35 Stellen, Rundungsgrenzen, Kollisionen) | alle 8 Chargen ohne Ablehnung |
| Parser-Fallstrick | `tools/k9-rest-minuscheck.mjs` | keine mehrdeutigen Ausdrücke |
| verify-prefill | `verify-tasks --prefill` | **0 Gate-Fehler** in allen 8 Chargen (`docs/prefill/k9-*-verifikation.md`) |
| Blind-Löser | je Thema ein frischer Subagent, nur Export (`tools/blind-loeser`), Vergleich `verify-tasks --from-file … --answers-from … --min-pass 1.0` | **222/222, 100 %**, 0 unsicher, 0 Abweichungen, kein zweiter Löser nötig (`docs/prefill/k9-*-blind.json`) |
| Wegwerf-DB | `tools/k9-rest-wegwerf-db.sh` (Grundlage + 102 Migrationen von origin/dev 8e6152b + 17 neue, zweimal) | grün, **idempotent** (96 Knoten, 162 Kanten, 68 Fehlbilder, 352 Aufgaben, 19 Figuren, 30 Einstiege in beiden Läufen) |
| Prüfskripte lokal | 17 Skripte, `-v lokal=true` | **182 von 182 t** |
| Prüfskripte gegen Prod | `dbread -f …` vor dem Einspielen | laufen fehlerfrei (nur lesend); Zeilen erwartungsgemäß noch `f` |
| Figuren | `DATABASE_URL=postgresql:///k9rest_alle upload_figures.py --dry-run` | geladen=19 (7 neu + 12 Bestand) **fehler=0** |
| Frontend | `npx tsc --noEmit`, `npm run typecheck`, `npm run lint`, `npm run test` | grün (67 Dateien, 674 Tests) |
| Schema | reine Datenmigrationen | kein Schema-Abzug nötig |
| Versionen | Prod, `git log --all`, `~/wt/k8-rest` | keine Kollision |

## Offene Punkte und Befunde

| Nr. | Befund | Umgang / Vorschlag |
|---|---|---|
| B1 | **Fehlende Kanten auf K8-Knoten** (bewusst nicht gesetzt): `stoch_bedingt_*` → Laplace/Baumdiagramm (K8 Stochastik), `geo_aehnlich_strahlen_*` → Stufen-/Wechselwinkel (K8 Winkel), `geo_pythagoras_anwendung` → Trapez/Raute (K8 Flächen). | Nachtrag, sobald beide Läufe in Prod sind. Tiefen passen (K8-Knoten liegen flacher). |
| B2 | **Abstieg trägt erst nach Freigaben anderer Läufe:** `term_einsetzen`, `geo_koordinaten` (Vorlauf), `term_binom_quadrat` (Binom), `geo_kreis_*` (Kreis) haben keine ready-Aufgaben. | Lena: diese Entwürfe vor den K9-Themen freigeben. |
| B3 | **Figuren vor Freigabe hochladen:** In `quadrfkt` liegen Rang 1 von `fkt_quadr_parabel` und `fkt_quadr_nullstellen` auf Aufgaben mit Abbildung; ohne Upload sind sie nicht lösbar. | Teil 6 (Upload) vor Lenas Freigabe. |
| B4 | **`upload_figures.py` hat keinen Filter** auf bestimmte Aufgaben; es lädt alle Zeilen ohne `svg_hash`. Teil 6 verlangt „ausschließlich deine neuen Aufträge“. | Vor dem echten Lauf per dbread prüfen, dass nur die 7 neuen Zeilen ohne Hash sind; sonst anhalten (K8-Figuren könnten gleichzeitig offen sein). |
| B5 | `term_ausklammern`: 6 ready MC-Aufgaben ohne `acceptance` — keine Fehlbild-Erfassung. | Eigener Lauf: known_errors über Options-IDs nachtragen (UPDATE). |
| B6 | Alt-Slugs ohne Klartext werden mitbenutzt (u. a. `wurzel_halbiert`, `mal_exponent`, `abgeschnitten`, `kommastellen_*`, `plus_statt_mal`, `multipliziert_statt_dividiert`, `falsche_hoehe`, `mal_zwei_vergessen`). Teils in leicht erweiterter Bedeutung (Details in `thema-*.md`). | Klartext/Familie in der Spec `fehlbild-labels-eltern.md`. |
| B7 | Neue Slugs ohne Familie (NULL): `irrational_verwechselt`, `faktor_ohne_wurzel`, `potenzgesetz_verwechselt`, `hypotenuse_verwechselt`, `drittel_vergessen`, `strahlensatz_falsch_zugeordnet`. | Entscheidung Lena. |
| B8 | `potenzgesetz_verwechselt` deckt auch Quotienten ab (Hochzahlen addiert/geteilt statt subtrahiert); Klartext nennt nur multiplizieren/addieren. | Bei der Abnahme ggf. Klartext erweitern. |
| B9 | Nicht erfassbare Fehler mangels Slug: 5⁰ = 5 (Basis stehen gelassen), Diskriminante mit +q statt −q. | Kandidaten für spätere Fehlbilder. |
| B10 | MULTI_PART: Wer zwei Teile vertauscht eingibt, löst je Teil ein Fehlbild aus (z. B. 7 in „kleinere Lösung“ → `negative_loesung_vergessen`, Vierfeldertafel → `randsumme_verwechselt`). | Folge der Prüfung je Teil; bewusst so gelassen. |
| B11 | Kanonischer Wert mit Endnullen bei „Runde, falls nötig“ (z. B. `360,00`); die ganze Zahl gilt ebenfalls als richtig. | Kosmetisch (Coach-Ansicht), wie beim Kreis. |
| B12 | Lösungswege nennen negative Ergebnisse mit ASCII-Minus (`-4`), Zwischenschritte mit `−`. | Kosmetisch; verify-prefill verlangt die Antwort wörtlich. |
| B13 | `stoch_bedingt_irrefuehrend` passt fachlich auch zu `statistik_beurteilen`; kein Einstieg dort. | Heimat-Thema-Vorschlag in `skill_thema.md`. |
| B14 | `skill_thema`-Nachtrag für die 37 Knoten (Lauf inhalte-themen, Teil 5). | Vorlage `skill_thema.md`. |
| B15 | Körper: In 6 π-Aufgaben ergeben π-Taste und 3,14 nach dem Runden denselben Wert (Liter, ganze Einheiten) — gewollt. Der verify-prefill-Bericht für Körper steht ohne `--blind`, weil dessen Vergleich bei zwei Rechenwegen Schein-Abweichungen meldet (Hinweis im Bericht). | – |

## Werkzeuge (neu, im PR)

`tools/k9-rest-lib.mjs`, `k9-rest-substrat.mjs`, `k9-rest-pruefung.mjs`, `k9-rest-graph-check.mjs`,
`k9-rest-minuscheck.mjs`, `k9-rest-wegwerf-db.sh`, je Thema `tools/k9-<kurz>-charge.mjs`;
`tools/vorlauf-build.mjs` wortgleich aus `feat/k8-rest`.
