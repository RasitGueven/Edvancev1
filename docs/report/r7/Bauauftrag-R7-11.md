# Bauauftrag R7-11 · Erster Ansatz am Thema, Anliegen mit Antwort

Stand 22.10.2026. Anlass: Rasit nach Durchsicht der Testberichte.

- **Ansatz:** Batu kommt wegen Reelle Zahlen und Wurzeln. „Unser erster Ansatz“ nennt aber Geometrie
  (Flächeninhalt von Drachen und Raute). Grund: Die Schwerpunkt-Regel aus R7, Entscheidung 7, kennt das
  Thema der LSA nicht. Sie nimmt gemischte Themenfelder zuerst, dann die tiefste Klassenstufe. Ein
  Befund aus der Breite (Klasse 8) schlägt so das Thema (Klasse 9). Dazu ist der Ansatz-Satz ein
  Baustein, der bei jedem Kind gleich klingt („Wir beginnen bei dem, was schon klappt.“).
- **Anliegen:** Seite 1 nennt z. B. „Sie machen sich Sorgen um Ilkays Konzentration.“, die Präsentation
  ergänzt „Zur Konzentration sagt eine Analyse dieser Länge nichts.“ Ein Anliegen, auf das der Bericht
  keine Antwort hat, verwirrt mehr, als es hilft.

**Ziel der Gründer:** Wer den Bericht öffnet, erkennt sofort, wo es hakt, und versteht jeden Satz.
Seite 1 beantwortet drei Fragen: Warum sind wir hier? Wo hakt es? Womit fangen wir an?

## Befund (Prod, nur lesend, 20.10.) — Batu Test1, Sitzung 6220b7e8, Klasse 9, Thema Reelle Zahlen

Aus R7-6 und R7-9: Themenraum 14 Bereiche, davon 5 direkt geprüft, 7 direkt geprüfte Bereiche liegen
außerhalb (Breite). Kanten mit direkt geprüfter Basis u. a.:
- Wurzelgesetze für Produkt und Quotient (9, teilweise) → Teilweise die Wurzel ziehen (9, Übungsbedarf)
- Bruch in Dezimalzahl (6, sicher) → Rationale und irrationale Zahlen (9, Übungsbedarf)
- außerhalb: Flächeninhalt von Drachen und Raute (8, Übungsbedarf), Additionsverfahren (8, Übungsbedarf)

Die erste Session im Session-Flow (Batu) beginnt mit genau diesem Umweg: Ziel „Teilweise die Wurzel
ziehen“, vorher die Wurzelgesetze festigen. Bericht und erste Stunde sollen dasselbe sagen.

## Prompt

```
Du arbeitest im Repo Edvancev1 (WSL). Paket R7-11: Der Eltern-Bericht R7 (Druck) und die Tablet-Präsentation richten „Unser erster Ansatz“ und die Schwerpunkte am Thema der LSA aus, und der Abschnitt „Ihr Anliegen“ nennt nur noch Anliegen, auf die der Bericht eine Antwort hat. Ein Paket, ein PR.

Voraussetzung: R7-9 (Lernweg, Felder kanten, heimatThemen, plan in ReportErzaehlung) ist in dev gemergt, sonst STOPP. R7-10 berührt nur Seite 2; ist es noch offen, fasse Seite 2 nicht an.

Lies zuerst docs/report/r7/Bauauftrag-R7.md (Entscheidungen 7 und 9), Bauauftrag-R7-6.md (themaAbdeckung, Themenraum) und Bauauftrag-R7-9.md (Plan, Kommt noch). Lege diesen Bauauftrag als docs/report/r7/Bauauftrag-R7-11.md im PR ab.

## Entscheidungen der Gründer (22.10.2026, nicht neu verhandeln)

### A. Schwerpunkte (src/lib/report/elternbericht/schwerpunkte.ts, reine Funktion mit Test)
1. Mit Thema heißt: modus 'adaptiv', Themenraum vorhanden (einstieg ∪ darunter, dieselbe Quelle wie themaAbdeckung) und ein Themen-Label. Ohne Thema bleibt die bisherige Regel aus R7, Entscheidung 7, unverändert. Ilkays Bericht ändert sich durch dieses Paket nicht (Test hält das fest).
2. Mit Thema ist Schwerpunkt 1 immer das Thema selbst:
   - Titel: das Themen-Label (wie im Thema-Satz von R7-6), nicht der Name des Themenfelds.
   - Bereiche: nur direkt geprüfte Bereiche im Themenraum. Abgeleitete zählen nie.
   - Reihenfolge der Bereiche mit Übungsbedarf: entlang skill_kante innerhalb des Themenraums, Voraussetzungen zuerst (topologisch); Gleichstand nach Klasse aufsteigend, dann Label.
   - Startstelle: der erste Bereich dieser Reihenfolge, also eine unterste noch nicht sichere Stelle im Thema. Bei Batu: Wurzelgesetze vor Teilweise die Wurzel ziehen.
   - „teilweise“ zählt wie bisher als Übungsbedarf.
3. Mit Thema, aber ohne Übungsbedarf im Themenraum: Schwerpunkt 1 bleibt das Thema mit dem Satz aus C (ansatzThemaSicher). Die Breite folgt als Schwerpunkt 2 ff.
4. Danach die Breite: Themenfelder mit Übungsbedarf AUSSERHALB des Themenraums. Ein Bereich steht nie zugleich im Thema-Schwerpunkt und in einem Feld-Schwerpunkt.
   - Zuerst Felder, die für das nächste Schulthema gebraucht werden. Planrang eines Bereichs: die kleinste Position unter den Kommt-noch-Einträgen des Plans, deren themaKey das Heimat-Thema (heimatThemen) des Bereichs ist oder eines Bereichs, der laut skill_kante direkt auf ihm aufbaut. Planrang eines Felds: das Minimum seiner Bereiche mit Übungsbedarf. Kleinerer Planrang zuerst.
   - Kommt noch NICHT neu rechnen: verwende die Funktion aus lernweg.ts, die die Plan-Einträge nach der aktuellen Position bestimmt. Du darfst sie dafür exportieren, sonst nichts an lernweg.ts ändern.
   - Felder ohne Planrang danach, untereinander nach der bisherigen Regel (gemischt, tiefste Stufe, mehr Übungsbedarf, Feldreihenfolge).
5. Höchstens vier Schwerpunkte einschließlich des Themas; die übrigen wie bisher im Satz „Danach nehmen wir … dazu.“
6. Die Präsentation (Station 04 und alles, was Schwerpunkte zeigt) nimmt genau dieses Ergebnis. Prüfe empfehlung.ts und ueberblick.ts: Rechnen sie Schwerpunkte selbst, stelle sie auf schwerpunkte.ts um. Keine zweite Logik.

### B. Seite 1 „Auf einen Blick“
7. In den Listen „Das klappte bereits“ und „Hier braucht es noch Übung“ stehen mit Thema die Bereiche aus dem Themenraum zuerst (in der Reihenfolge aus Entscheidung 2), dann der Rest wie bisher. Die „+n weitere“-Logik bleibt.
8. Der Kasten „Unser erster Ansatz“ zeigt Schwerpunkt 1. Mit Thema ersetzen die konkreten Sätze aus C die Bausteine ansatzGemischt/ansatzUebung. Ohne Thema bleiben die bisherigen Bausteine.

### C. Texte für den Ansatz (Entwürfe für Lena, i18next mit count, Namespace elternbericht, gleiche Schlüssel in praesentation über tb)
- s1.blick.ansatzThema.sicher_one: „Sicher ist schon {{liste}}.“ / _other: „Sicher sind schon {{liste}}.“ (entfällt ohne Sicheres im Thema)
- s1.blick.ansatzThema.uebung: „Noch Übung braucht {{name}} bei {{liste}}.“ / ohne Namen „Noch Übung braucht es bei {{liste}}.“
- s1.blick.ansatzThema.start_one: „Dort setzen wir an.“ / _other: „Wir beginnen bei {{start}}.“
- s1.blick.ansatzThemaSicher: „Was wir im Thema {{thema}} geprüft haben, sitzt. Wir arbeiten am aktuellen Stoff weiter.“
- s4.chip.thema: „Aktuelles Thema“ (kleines Schild am Thema-Schwerpunkt auf Seite 4 und in Station 04; nur mit Thema)
Listen über die bestehende liste-Hilfe, Bereichsnamen über elternLabel (R7-9).
Erwartung Batu: „Noch Übung braucht Batu bei Wurzelgesetzen für Produkt und Quotient und Teilweise die Wurzel ziehen. Wir beginnen bei Wurzelgesetzen für Produkt und Quotient.“ — genaue Liste aus der Gegenrechnung.

### D. „Ihr Anliegen“ (Seite 1 und Station 01)
9. Finde heraus, woher die Anliegen kommen (Quelle von {{punkte}} in s1.anliegen.genannt) und liste alle möglichen Werte im PR auf.
10. Reine Funktion src/lib/report/elternbericht/anliegen.ts mit Test. Jeder Wert ist entweder fachlich (betrifft Mathe-Stoff oder Leistung, z. B. Noten, Lücken, Klassenarbeit, Thema) oder überfachlich (z. B. Konzentration, Motivation, Hausaufgaben, Selbstorganisation, Prüfungsangst). Die Zuordnung ist eine feste Tabelle in der Datei, ein unbekannter Wert gilt als überfachlich. Die Gründer bestätigen die Tabelle in der Abnahme.
11. Überfachliche Anliegen erscheinen weder im Bericht noch in der Präsentation. Kein Satz darüber, was die Analyse nicht sagen kann. Die Daten bleiben unverändert in der Datenbank (später für den Zwischenbericht, nicht in diesem Paket).
12. Der Abschnitt wird Frage und Antwort:
   - Mit Thema: s1.anliegen.thema „Sie sind wegen {{thema}} zu uns gekommen.“ und direkt danach die Antwort s1.anliegen.antwort „Dort hakt es bei {{liste}}.“ (Bereiche mit Übungsbedarf im Themenraum, höchstens drei, dann „und n weitere“) oder s1.anliegen.antwortSicher „Was wir dazu geprüft haben, sitzt.“
   - Fachliche Anliegen: wie bisher genannt, danach s1.anliegen.antwortSchwerpunkt „Dort setzen wir zuerst an: {{schwerpunkt}}.“ (Titel von Schwerpunkt 1). Mit Thema entfällt dieser Satz, wenn er dasselbe sagen würde wie die Thema-Antwort.
   - Ohne Thema und ohne fachliches Anliegen: Der Kasten entfällt still. Seite 1 hat keinen leeren Kasten; „So haben wir geprüft“ rückt nach, das Layout bleibt ruhig (Druck-Test).
   - Der bisherige Satz „Als nächstes Thema steht {{thema}} an.“ bleibt nur ohne Thema der LSA.
13. Station 01 der Präsentation folgt derselben Rechnung. Der Grenzsatz zur Konzentration und jeder ähnliche Schlüssel in praesentation.json entfällt.

### E. Sprachregeln
14. Alles aus R7, Entscheidung 9 (INV-4) gilt weiter. Neu als Invariante in inv4-elternbericht und inv4-praesentation: Kein Text auf Seite 1 und in Station 01 sagt, was die Analyse nicht sagen kann oder erst später klären wird (Wortliste mindestens: „sagt nichts“, „sagt eine Analyse“, „erst nach“, „können wir noch nicht“, „nach mehreren Sitzungen“). Der bestehende Methodenhinweis in „So haben wir geprüft“ bleibt erlaubt; liste ihn als Ausnahme ausdrücklich auf.
15. Sofortkorrektur Seite 2 (nur Text, keine Komponente): In s2.fussnote entfällt der Halbsatz „; die Bewertungsregel ist noch nicht abschließend festgelegt“. Der Satz lautet dann: „Ein Bereich gilt als sicher, wenn die geprüften Aufgaben dazu gelangen.“ Das ist die einzige Änderung an Seite 2 in diesem Paket.
16. Alle neuen und geänderten Texte als Entwürfe für Lena in docs/report/r7/texte-r7-11.md, alt → neu, mit den zusammengesetzten Sätzen aller Testfälle. Geänderte Anhang-A-Schlüssel einzeln in INV-4.9/4.11 auflisten wie in R7-6.

## Testfälle (FAELLE; PRAESENTATION_FAELLE übernimmt sie)
- abgestuft (Batu): Schwerpunkt 1 = Reelle Zahlen, Startstelle Wurzelgesetze; Geometrie steht weder im Ansatz auf Seite 1 noch an Platz 1 auf Seite 4; Listen auf Seite 1 beginnen mit Bereichen aus dem Thema.
- abgestuftThemaSicher: Thema ohne Übungsbedarf → ansatzThemaSicher, Breite ab Schwerpunkt 2.
- abgestuftPlanrang: zwei Felder in der Breite, eines davon wird für das nächste Plan-Thema gebraucht → dieses zuerst, obwohl die alte Regel das andere vorn hätte.
- ilkay: Ansatz, Schwerpunkte, Seite 4 und Station 04 wörtlich unverändert; Anliegen „Konzentration“ ist überfachlich → Kasten entfällt (sofern kein fachliches Anliegen), kein Grenzsatz.
- anliegenGemischt: Noten + Konzentration → nur Noten mit Antwortsatz.
- anliegenNurUeberfach ohne Thema: Kasten entfällt, Seite 1 ohne Lücke.
- Alle übrigen Fälle: Text alt → neu im PR, wo er sich ändert.

## Umfang
- Rechnung mit Test: src/lib/report/elternbericht/schwerpunkte.ts, anliegen.ts (neu), lernweg.ts (nur Export der Kommt-noch-Funktion), bereiche.ts (nur Reihenfolge der Listen, falls dort gerechnet)
- Präsentation-Rechnung: src/lib/report/praesentation/empfehlung.ts, ueberblick.ts (nur auf schwerpunkte.ts und anliegen.ts umstellen)
- Typen: src/types/elternbericht.ts, src/types/praesentation.ts (nur neue Felder)
- Druck: Seite1.tsx und Teile, Seite4.tsx (Schild), seite1.css, seite4.css
- Präsentation: Station1.tsx, Station4.tsx und ihre CSS
- Texte: elternbericht.json (s1.blick.ansatzThema*, s1.anliegen.*, s4.chip.*), praesentation.json (nur betroffene Schlüssel)
- Fixtures: src/lib/report/elternbericht/fixtures/**, src/lib/report/praesentation/fixtures.ts
- Invarianten: inv4-elternbericht.test.ts, inv4-praesentation.test.ts (Entscheidung 14 und Schlüsselliste)
- Doku: docs/report/r7/Bauauftrag-R7-11.md, texte-r7-11.md, offene-punkte-r7-11.md, Retro
- Nicht anfassen: Seite2/3/5 (außer s2.fussnote nach Entscheidung 15), Station2/3, lernweg.ts (außer Export), lernwegLinien.ts, themaAbdeckung.ts, seite2Rechnung.ts, tokens.css, supabase/**, playwright.*.config.ts

## Tests
- Vitest: Schwerpunkte (mit/ohne Thema, Thema sicher, topologische Reihenfolge mit Gleichstand, Planrang inkl. Kante zum Nachfolger, Grenze 4, kein Bereich doppelt, abgeleitete zählen nie), anliegen (Tabelle, unbekannter Wert, gemischt), Seite 1 ohne leeren Kasten, Station 01/04 nutzen dieselbe Rechnung.
- Druck-Tests für ALLE Fälle grün: EB_PORT=5193 EB_AUSGABE=docs/report/r7/abnahme/r7-11 npx playwright test -c playwright.elternbericht.config.ts
- Ansichtstests der Präsentation grün: TP_PORT=5194 TP_AUSGABE=docs/report/praesentation/abnahme/r7-11 npx playwright test -c playwright.praesentation.config.ts
- inv4-elternbericht, inv4-praesentation, Typecheck, Lint, Vitest grün.
- Gegenrechnung mit dbread für 6220b7e8 als Tabelle im PR: Themenraum mit Stand, Reihenfolge und Startstelle, Breite mit Planrang, Ergebnis Seite 1 und Seite 4.

## Leitplanken
- Worktree ../Edvancev1-r7k auf feat/rasit-report-r7-ansatz von origin/dev. PR gegen dev, nie main.
- Kein DDL, keine Migration, Prod nur lesend über dbread.
- Designregeln CLAUDE.md §11 mit der R7-Ausnahme: keine Hex-Werte außerhalb tokens.css, kein style={{…}}, INV-4.11/4.12, Dateien ≤ 400 Zeilen.
- CI: Ist in schema/neuaufbau NUR session_a2 rot (Laufzeitmessung), ist das nicht dein Fehler. Im PR vermerken, nichts ändern.
- Zweitprüfung durch eine frische Instanz in der Rolle eines Elternteils ohne Vorwissen. Sie liest nur Seite 1 und beantwortet in drei Sätzen: Warum sind wir hier? Wo hakt es? Womit fängt Edvance an? Jeder Satz, der dafür nicht gebraucht wird oder unverständlich ist, kommt mit Fundstelle in die offenen Punkte. Dazu: Steht irgendwo ein Grenzsatz oder ein Fachkürzel?
- STOPP nach dem PR.

## Melden
- PR-Link
- PDFs Seite 1 und 4 aus docs/report/r7/abnahme/r7-11/ (abgestuft, abgestuftThemaSicher, ilkay, anliegenGemischt, anliegenNurUeberfach)
- Fotos Station 01 und 04 (abgestuft, 1180x820)
- Liste der Anliegen-Werte mit Zuordnung fachlich/überfachlich
- Gegenrechnung Batu als Tabelle
- Ergebnis der Zweitprüfung (die drei Antworten wörtlich)
- Texte alt → neu (texte-r7-11.md), offene Punkte
```

## Abnahme (Gründer, Texte zusätzlich Lena)
1. Batu: Seite 1 sagt in den ersten Sätzen, dass er wegen Reelle Zahlen kam, wo es dort hakt und dass wir bei den Wurzelgesetzen beginnen. Geometrie kommt erst später.
2. Ilkay: Schwerpunkte unverändert, kein Satz zur Konzentration mehr.
3. Zuordnung der Anliegen fachlich/überfachlich bestätigen.
4. Lena nimmt die Texte aus texte-r7-11.md ab.

## Offen, nicht blockierend
- Überfachliche Anliegen (Konzentration usw.) gehören in den ersten Zwischenbericht, sobald der Coach etwas dazu beobachtet hat. Eigener Auftrag mit der Anforderung Eltern-Reports.
- Seite 4, Fazit-Satz „Ob dahinter ein gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen.“ prüfen, ob er nach diesem Paket noch gebraucht wird.
