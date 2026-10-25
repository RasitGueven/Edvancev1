# Zweitprüfung Bericht v4 und Präsentation v4 (Fall batuV4)

**Was:** Unabhängiger Abgleich der Kontrollwerte aus `Bauauftrag-V4.md`, Anhang B, mit den Abnahme-PDFs des Eltern-Berichts und den Abnahmefotos der Tablet-Präsentation, jeweils gegen die Prod-Daten der Testlauf-Sitzung vom 24.10.2026. Dazu kommen die Sprach- und Layout-Leitplanken.

**Womit:**
- PDFs `abnahme/v4-2/batuV4-A.pdf`, `batuV4-B.pdf`, `batuMitNote-A.pdf`, `batuMitNote-B.pdf`. Den Text habe ich mit `gs -sDEVICE=txtwrite` gezogen, die Seitenbilder mit 70 dpi und Ausschnitte mit 160 dpi angesehen.
- Fotos `abnahme/v4-3/batuV4_1180x820_01` bis `_04` sowie `_04-punkt1` bis `_04-punkt4`.
- `~/bin/dbread`, nur lesend, auf diese Tabellen: `lsa_sessions`, `lsa_responses`, `lsa_skill_urteil`, `skills`, `skill_kante`, `skill_thema`, `themen`, `schul_themenplan`, `schulen`, `leads`, `lsa_report_notes` und `fehlbild_labels`.
- Code nur gelesen. Es gibt keine Änderung an `src/`.

**Wann:** 25.10.2026, Branch `feat/lsa-report-v3` @ `dc20c419`.

**Name:** Im Testlauf heißt das Kind anders. In allen Prüflingen steht der Fixture-Name „Ilkay (Fixture)“, hier „das Testkind“.

**Gesetzte Werte:** Die Fixture setzt `klassenarbeit_status = 'geschrieben'`, und `batuMitNote` setzt dazu Note 4. In Prod ist beides leer (`leads.klassenarbeit_status` und `letzte_klassenarbeit_note` sind NULL). Diese Werte gelten hier als vorgegeben.

**A gegen B:** Die Varianten A und B sind auf den Seiten 1, 2, 4 und 5 pixelgleich. Nur Seite 3 unterscheidet sich: A ist das unveränderte Layout A aus v3, so gewollt laut „Nicht in diesem Auftrag“. B ist das neue Layout mit Blöcken je Arbeit. `batuMitNote` weicht von `batuV4` nur in „geschrieben · Note 4“ auf Seite 1 ab.

## Prüftabelle

| # | Prüfpunkt | Anhang B | PDF A/B | Foto | dbread | Urteil |
|---|---|---|---|---|---|---|
| 1 | Station 1, Titel | „Reelle Zahlen und Wurzeln“ | „Reelle Zahlen“ (S. 1, Leiste S. 2–5, S. 3 B, S. 4) | 01 und 03: „Reelle Zahlen“ | `schul_themenplan` FWG Kl. 9, Pos. 1: `uv_titel` = „Reelle Zahlen“. „Reelle Zahlen und Wurzeln“ ist `themen.label` (KLP). | Abweichung datenbedingt (a): Der Fahrplan nimmt richtig den Schultitel. |
| 2 | Station 1, Stand | „geschrieben“ | „geschrieben“, hellblau mit Haken | 01: Haken, „geschrieben“. 03: Pille „GESCHRIEBEN“. | `leads.klassenarbeit_status` NULL, Wert für die Abnahme gesetzt | stimmt |
| 3 | Station 1, Note (`batuMitNote`) | – (Entscheidung 1: „geschrieben · Note 4“) | `batuMitNote` A/B S. 1: „geschrieben · Note 4“. `batuV4` ohne Note. | – (kein Foto) | `letzte_klassenarbeit_note` NULL, Wert gesetzt | stimmt |
| 4 | Station 2 | Quadratische Funktionen, `fehlt`, nächste Arbeit | Nr. 2, „nächste Arbeit“, „Voraussetzungen fehlen noch“ | 01 und 03 gleich | Pos. 2 `quadratische_funktionen`. Signal per SQL: 3 fehlt, 2 sitzt → `fehlt` | stimmt |
| 5 | Station 3 | Kreise, Prismen und Zylinder, `fehlt` | Nr. 3, „voraussichtlich“, fehlt | 01 und 03 gleich | Pos. 3 `kreis`: 3 fehlt, 3 sitzt → `fehlt` | stimmt |
| 6 | Station 4 | Nicht genannt („weitere Plan-Themen … dahinter mit `ohne`“) | Nr. 4 Potenzen und Potenzgesetze, „voraussichtlich“, „dazu noch nichts geprüft“, grau | 01 und 03 gleich (graue Karte) | Pos. 4 `potenzen`: kein geprüfter Bereich über `skill_kante`/`skill_thema` → `ohne` | Abweichung datenbedingt (b): Potenzen steht im Plan vor Pythagoras. |
| 7 | Station 5 | Pythagoras als dritte kommende Station (KA 4), `fehlt` | Nr. 5 Der Satz des Pythagoras und Berechnungen in Körpern, „voraussichtlich“, fehlt | 01 und 03: KA 5 | Pos. 5 `pythagoras`: 1 fehlt, 1 sitzt → `fehlt` | Abweichung datenbedingt (b) |
| 8 | „+n weitere“ | – | „+1 weiteres Thema bis zum Schuljahresende“ | 01 und 03 gleich | Pos. 6 Daten und Wahrscheinlichkeit. Bei vier kommenden Stationen bleibt 1 übrig. | stimmt |
| 9 | Satz unter dem Fahrplan | `satzFehlt` (mind. ein `fehlt`) | Wortlaut Anhang A, mint Kasten | 01: gleicher Wortlaut im mint Kasten. 03: auch als Unterzeile. | 3 × `fehlt` | stimmt |
| 10 | Quellenzeile | Schulplan-Fassung | S. 1: „Die Reihenfolge stammt aus dem Schulplan des Friedrich-Wilhelm-Gymnasiums. Wann genau …“. S. 3: Fußnote mit Schulplan. | 03: gleicher Satz. 01: keine Quellenzeile (siehe Befund H6). | `schulen.name` = Friedrich-Wilhelm-Gymnasium, Quelle Schulplan | stimmt |
| 11 | Leiste S. 2–5 | – (Entscheidung 10) | Auf S. 2–5 je fünf Chips: Haken hellblau, 2/3/5 rosé, 4 grau. Titel mit Ellipse (erlaubt). | – | wie 2–7 | stimmt |
| 12 | S. 3, Einstiegssatz | „Die Arbeit zu Reelle Zahlen und Wurzeln hat {Rufname} … Klassenarbeit 2.“ | B: „Die Arbeit zu **Reelle Zahlen** hat Ilkay laut Ihren Angaben schon geschrieben. Deshalb beginnt diese Übersicht mit Klassenarbeit 2. …“, hellblauer Kasten mit Haken | – | Folgt aus 1 | Abweichung datenbedingt (a) |
| 13 | Block KA 2, fehlt | mind. Binomische Formeln, Faktorisieren mit binomischer Formel | Werte in Terme einsetzen · Binomische Formeln (Quadrat einer Summe/Differenz) · Faktorisieren mit binomischer Formel | 03: dieselben drei | `term_einsetzen`, `term_binom_quadrat`, `term_binom_faktorisieren` | stimmt |
| 14 | Block KA 2, sitzt | mind. Gleichungen aufstellen (Sachkontext) | Punkte im Koordinatensystem · Gleichungen aufstellen (Sachkontext) | 03: dieselben zwei | `geo_koordinaten`, `gleichung_modellieren` | stimmt |
| 15 | Block KA 3, fehlt | mind. Flächeneinheiten, Fläche von Dreieck und Parallelogramm, Werte in Terme einsetzen | genau diese drei | 03: dieselben drei | `groessen_flaechen`, `geo_flaeche_dreieck`, `term_einsetzen` | stimmt |
| 16 | Block KA 3, sitzt | – | Fläche von Rechteck und Quadrat · Umfang von Rechteck und Dreieck · Dreisatz, proportional und antiproportional | 03: dieselben drei | `geo_flaeche_rechteck`, `geo_umfang`, `proportionalitaet` | stimmt |
| 17 | Block Pythagoras, fehlt | mind. Teilweise die Wurzel ziehen | KA 5: Teilweise die Wurzel ziehen | 03: gleich | `zahl_wurzel_teilweise` (Kante aus Migration 20261024143626, in Prod eingespielt) | stimmt. Die Nummer 5 folgt aus 7. |
| 18 | Block Pythagoras, sitzt | mind. Punkte im Koordinatensystem | Punkte im Koordinatensystem | 03: gleich | `geo_koordinaten` | stimmt |
| 19 | Kein Block für `ohne` | – (Entscheidung 4) | Kein Block für KA 4 | 03: Karte ohne Liste | – | stimmt |
| 20 | Weitere Stärken | – | Längen umrechnen, Einsetzungsverfahren, Satz des Thales, Terme für Flächeninhalte, Rationale und irrationale Zahlen, Wurzelgesetze, Wurzeln abschätzen (7) | – | Die 7 sicheren Bereiche ohne kommendes Thema dieses Schuljahrs | stimmt (siehe H7) |
| 21 | Wird später wichtig | Additionsverfahren, Gleichungssysteme grafisch, Trapez, Drachen und Raute, Summenregel | genau diese fünf | – | Übungsbedarf ohne kommendes Thema: `gleichung_lgs_addition`, `gleichung_lgs_grafisch`, `geo_flaeche_trapez`, `geo_flaeche_drachen_raute`, `stoch_pfad_summe` | stimmt |
| 22 | Kein Bereich geht verloren | – | 5 sitzt + 7 Stärken = 12. 6 fehlt + 5 später = 11. | – | 23 direkt belegte Urteile, keins `offen` | stimmt |
| 23 | Lernpfad Punkt 1 | Terme & Gleichungen, „Voraussetzung für Klassenarbeit 2“ | „Schritt 1 · Voraussetzung für Klassenarbeit 2 und 3“, Terme & Gleichungen | punkt1: Pille „Voraussetzung für Klassenarbeit 2 und 3“, Titel Terme & Gleichungen | `term_einsetzen` betrifft `quadratische_funktionen` und `kreis`. Anhang B nennt es selbst unter „Kreise fehlt“. | Abweichung datenbedingt (c) |
| 24 | Lernpfad Punkt 2 | Gruppe „Grundlagen für „Kreise, Prismen und Zylinder““ aus Größen und Geometrie, KA 3 | Gleicher Titel, KA 3, Teile Flächeneinheiten, Dreieck/Parallelogramm, Trapez, Drachen/Raute | punkt2: gleicher Titel, Pille KA 3, gleiche vier Teile | Erste Ziel-Station von Größen und Geometrie ist jeweils `kreis` | stimmt |
| 25 | Lernpfad Punkt 3 | Teilweise die Wurzel ziehen, KA 4 | Titel „Teilweise die Wurzel ziehen“, „Voraussetzung für Klassenarbeit 5“ | punkt3 und Kurve: Titel **„Reelle Zahlen und Wurzeln“**, „Klassenarbeit 5“ | `zahl_wurzel_teilweise` → `pythagoras` (Pos. 5) | **Fehler** (Präsentation, F1). Im PDF stimmt der Titel, die KA-Nummer weicht datenbedingt ab (b). |
| 26 | Lernpfad „später“ | Daten & Zufall | „Danach · Wenn der Schulstoff sitzt · Themen späterer Schuljahre“, „Daten & Zufall.“ | Bleibt laut V4-3 nicht auf der Kurve | `stoch_pfad_summe` ohne kommendes Thema | stimmt |
| 27 | Sorgfalt-Muster | Liegt vor: 6 von 11 | S. 1 Anliegen: Sorgfalt-Satz. S. 5 Fazit: Sorgfalt-Satz. | 01: Lead-Satz. punkt4: Punkt „Sorgfalt · in jeder Session“ mit blauer Kugel. | 11 Fehlbild-Antworten. vorzeichen 3 + schritt_vergessen 2 + figuren 1 = 6 (≥ 3 und ≥ 50 %). | stimmt |
| 28 | Ziele S. 5 (1 vorbereitet QF, 2 später Kreise + Pythagoras, 3 Sorgfalt, 4 übrige Lücken) und die Zeile „Ziel: …“ in Station 04 | vier Ziele | **fehlt** auf S. 5 in allen vier PDFs. Auch „Wir versprechen keine Noten …“ fehlt. | **fehlt** in punkt1–4 (keine „Ziel:“-Zeile) | Prod: `ziele_bestaetigt` = false. Die Rechnung belegt der Vitest `Seite5V4.test.tsx` mit `NOTIZEN_ZIELE`: Die Sätze entsprechen Anhang B. | **Fehler** (Abnahmematerial, F2) |
| 29 | Zählungen | – | S. 1 und S. 2: 23 geprüft · 12 sicher · 11 Übungsbedarf | 02: 23 · 12 · 11 | 12 `traegt`, 11 andere (6 `traegt_nicht`, 4 `traegt_teilweise`, 1 `nicht_angesetzt`) | stimmt |
| 30 | Aufgaben | – | S. 1: 34 Aufgaben | 02: 34 Aufgaben bearbeitet | 34 verschiedene `task_id` (39 Teilantworten). `result_summary.answered` = 34. | stimmt |
| 31 | Stufen-Blick | – | Grundlagen 4+1, Weiterführend 5+9, Aktueller Stoff 3+1 | 01: gleich | Nach `klasse_herkunft`: 5/6 → 4/1, 7/8 → 5/9, 9 → 3/1 | stimmt |
| 32 | Fazit S. 5 | – | „… in den nächsten 3 Klassenarbeiten wieder gebraucht … Wir beginnen mit den Voraussetzungen für „Quadratische Funktionen“.“ | – | 3 Stationen mit `fehlt` | stimmt |
| 33 | Rufname im Fuß | {Rufname} | S. 1–5: „edvance · Köln · Lernstandsanalyse Ilkay“, Seitenzahl x / 5 | – | `leads.first_name` gesetzt. Die Fixture ersetzt ihn durch den Muster-Namen. | stimmt |
| 34 | S. 1 ohne einzelne Voraussetzungen | – (Entscheidung 3) | Nur Signale. Keine Bereichsnamen im Fahrplan. | 01: gleich | – | stimmt |
| 35 | Station 03 = Blöcke S. 3 | – | S. 3 B | 03: Karten KA 2/3/5 mit denselben Listen. KA 1 zeigt den Satz `s3.offen` zu „Teilweise die Wurzel ziehen“. | wie 13–18 | stimmt |
| 36 | Station 02, Felder und Klassen gegen PDF S. 2 | – (V4-3: Labels von Station 02 gegen das PDF) | S. 2: Größen „Klasse 5–6“, Prozent & Dreisatz „Klasse 7“, Daten & Zufall „Klasse 8“, Zahlen & Rechnen „Klasse 9“ | 02: „Klasse 5/6“, „7/8“, „7/8“, „9/10“. Geometrie „5-8“ mit Bindestrich. Die Reihenfolge der Felder ist anders. | `klasse_herkunft`: `proportionalitaet` 7, `stoch_pfad_summe` 8, `zahl_wurzel_*` 9 | **Fehler** (gering, F3). Die Zahlen je Feld stimmen. |
| 37 | Paketempfehlung | – | S. 5: Vorschlag **Standard** („4 Schwerpunkte, 11 von 23“) | 04: „Unsere Empfehlung für Ilkay: **Paket Premium**“ | Prod: `paket` = 'basis', `paket_bestaetigt` = false. Die Präsentation würde in Prod „Basic“ zeigen, der Bericht „Standard“. | **Fehler** (F4) |
| 38 | Kein Preis | – (Entscheidung 3a) | Preise aus (Standard), kein Betrag | 04: kein Preis | – | stimmt |
| 39 | Seite 4 ohne Fehlerbilder | – (Entscheidung 6) | Kein Block „Fehlermuster“, kein Rechenbeispiel | 04: keine Fehlerbild-Liste | – | stimmt |
| 40 | Lernpfad-Marken | – (Entscheidung 5) | Navy-Marken „für 2 / 3 / 5“ mit Kurztitel, „danach +“ grau | – | – | stimmt |

**Summe:** 40 Prüfpunkte. 31 stimmen, 5 weichen datenbedingt ab (1, 6, 7, 12, 23), und 4 sind Fehler (25, 28, 36, 37).

Alle drei gemeldeten Abweichungen sind belegt:
- **(a):** Der Schulplan-Titel ist „Reelle Zahlen“.
- **(b):** FWG Pos. 4 ist Potenzen (`ohne`), Pos. 5 ist Pythagoras.
- **(c):** Das ergibt sich aus `term_einsetzen` → `kreis`. Anhang B ist hier in sich widersprüchlich, weil er „Werte in Terme einsetzen“ selbst unter „Kreise fehlt“ führt.

## Leitplanken

**Geprüft:** Volltext aller vier PDFs, dazu die sichtbaren Texte der acht Fotos.

- **Verbotene Wörter:** „trägt“, „gemeistert“, „Klassenband“ und „wirkt auf“ kommen nicht vor. Das Wort „Note“ steht nur an drei Stellen: in der Elternangabe „Letzte Zeugnisnote in Mathematik: 4“, in „geschrieben · Note 4“ (Entscheidung 1) und in „Das ist keine Note und kein Prozentwert“.
- **„bis“:** Es steht nur in „bis zum Schuljahresende“ und in „Klasse 5 bis 8“, nie vor „Klassenarbeit“.
- **Keine Zusagen:** Es gibt keine Ergebnisprognose und kein Noten-Versprechen. Seite 3 sagt ausdrücklich „keine Vorhersage“, und Seite 4 schließt mit „Der Coach prüft … und passt den Plan an“. Der Satz „Wir versprechen keine Noten“ fehlt, weil der Zielabschnitt fehlt (F2).
- **Kein Preis:** Im Bericht ist der Schalter aus, und die Präsentation zeigt nirgends einen Preis.
- **Ränder und Abschnitte:** Bei 70 und 160 dpi ragt nichts über den Rand und nichts ist abgeschnitten. Lange Titel brechen um: die Fahrplanspalte Pythagoras auf vier Zeilen, die Marke „für 5“ auf vier Zeilen, der Blocktitel KA 5 auf zwei Zeilen. Nur die Leiste kürzt mit Ellipse, und das ist erlaubt.
- **Präsentation:** Die Pille „Voraussetzung für Klassenarbeit 2 und 3“ bricht sauber in zwei Zeilen. Die Kurvenbeschriftungen überlappen sich nicht. In punkt3 reicht der Lichtschein der gewählten Kugel bis dicht an „Klassenarbeit 5“, deckt die Schrift aber nicht ab.

## Befunde

### Fehler

**F1 · Präsentation, Station 04, Punkt 3: falscher Titel.**
- Auf der Kurve und im Kasten steht „Reelle Zahlen und Wurzeln · Klassenarbeit 5“. Der Bericht (S. 4, Schritt 3) titelt richtig „Teilweise die Wurzel ziehen“.
- Damit erscheint die geschriebene Arbeit 1 unter ihrem KLP-Namen als Förderpunkt für Arbeit 5. Für Eltern ist das verwirrend und widerspricht dem Papier.
- **Ursache:** In `src/components/edvance/praesentation/foerderPunkte.ts` (ca. Z. 60–65) fehlt der Sonderfall, den `src/components/edvance/elternbericht/LernpfadV4.tsx` (Z. 55–62) hat: Bei `art === 'luecke'` mit Grund `spaeterGebraucht`/`themaGeschrieben` wird der Titel aus den Übungsbedarf-Bereichen gebildet statt aus `titelThema`.

**F2 · Abnahmematerial: Die Ziele sind nirgends sichtbar.**
- `src/lib/report/elternbericht/fixtures/index.ts` hängt an `batuV4`/`batuMitNote` die `NOTIZEN` (`notizen.ts`). Dort ist `zieleBestaetigt` nicht gesetzt, und es gibt ein Coach-`zielbild`.
- Deshalb fehlen auf Seite 5 der PDFs die Ziele und der Satz „Wir versprechen keine Noten“, und in Station 04 fehlt die Zeile „Ziel: …“.
- Abnahmepunkt 1 („Seite 5 hat die Ziele in Elternsprache“) und der Wortlaut der Ziele lassen sich am 28.10. so nicht abnehmen.
- Es reicht nicht, nur `zieleBestaetigt: true` zu setzen: Dann ginge das Coach-Zielbild vor. Nötig ist eine Notiz wie `NOTIZEN_ZIELE` in `src/test/elternberichtV4.tsx` (`zielbild: ''`, `zieleBestaetigt: true`).
- Die Rechnung selbst ist laut Vitest (`Seite5V4.test.tsx`, `zielbild.test.ts`) richtig: vier Ziele, wie Anhang B.

**F3 · Präsentation, Station 02: Die Klassenangaben weichen vom PDF ab (gering).**
- Die Präsentation zeigt Klassenbänder (`stufeAusKlasse`, `Profilzeile.tsx`): Prozent & Dreisatz „7/8“, Daten & Zufall „7/8“, Zahlen & Rechnen „9/10“.
- Der Bericht zeigt die echten Herkunftsklassen: 7, 8 und 9.
- Dazu kommt ein uneinheitliches Format auf demselben Screen: „5-8“ mit Bindestrich neben „5/6“. Die Reihenfolge der Felder unterscheidet sich ebenfalls.
- Die Zählungen je Feld stimmen.

**F4 · Paketempfehlung: Bericht und Präsentation widersprechen sich.**
- Der Bericht nimmt den Systemvorschlag, solange `paket_bestaetigt` fehlt (`Seite5.tsx` Z. 40–42). Er schlägt Standard vor.
- Die Präsentation nimmt `notes.paket` ungeprüft (`src/lib/report/praesentation/praesentation.ts` Z. 182, `empfehlungAus`). Sie zeigt „Paket Premium“.
- Mit den Prod-Notizen der Sitzung (`paket` = 'basis', unbestätigt) stünde auf Papier „Standard“, auf dem iPad „Basic“.
- Das Verhalten stammt aus v3, fällt aber in der V4-Abnahme sofort auf.

### Hinweise (kein Fehler nach Spezifikation)

**H1 · S. 3 und S. 4 widersprechen sich inhaltlich.**
- Seite 3 führt Additionsverfahren, Gleichungssysteme grafisch, Trapez und Drachen/Raute unter „Wird später wichtig … Wir nehmen sie dazu, sobald sie anstehen“.
- Seite 4 übt dieselben Bereiche schon in Schritt 1 („Additionsverfahren“, „+1 weitere“) und Schritt 2 (Trapez, Drachen/Raute).
- Das entspricht Entscheidung 5, weil die Teile alle Übungsbedarf-Bereiche des Schwerpunkts sind. Für Eltern ist es trotzdem widersprüchlich.

**H2 · S. 4, Schritt 2 (und Station 04, Punkt 2): „zuerst“ an zweiter Stelle.** Die Begründung „… – zuerst, weil es Stoff aus Klasse 5/6 ist“ steht beim zweiten Schritt (v3-Text `s4.grund.*`).

**H3 · Präsentation, Station 01 und 03: Verweis aufs Papier.** Der Satz `s1.satzFehlt` endet mit „Welche das sind, steht auf Seite 3.“. Auf dem iPad gibt es keine Seite 3, gemeint ist Station 03. Station 03 zeigt den Satz sogar als Unterzeile. Der Wortlaut stammt aus Anhang A.

**H4 · S. 1: ein loser Satz.** „Die Lücken liegen vor allem bei Termen und Gleichungen sowie bei der Geometrie.“ steht unter „Auf einen Blick“ ohne Kasten. Das widerspricht Entscheidung 10 („Kein Text steht lose“).

**H5 · Präsentation, Station 04: zwei Abweichungen im Wortlaut.**
- Die Kurvenbeschriftung lautet „Klassenarbeit n“ statt „für Klassenarbeit n“ (V4-3, Punkt 5).
- Die Caption sagt „anstehende Klausuren“. Bei Klasse 9 heißt es „Klassenarbeiten“.

**H6 · Präsentation, Station 01: keine Quellenzeile.** Unter dem Fahrplan fehlt die Quellenzeile. Station 03 hat sie.

**H7 · „Weitere Stärken“ und Station 1.** Dort steht „Wurzelgesetze für Produkt und Quotient“, obwohl der Bereich laut `skill_kante` das Thema der geschriebenen Station 1 (`reelle_zahlen`) betrifft. Die Rechnung zählt nur kommende Themen. Das ist vertretbar, weicht aber vom Wortlaut „kein Thema dieses Schuljahrs“ ab.

**H8 · Bauauftrag V4-3, Tests: „fünf Punkte“ passt nicht.** Dort steht „Station 04 mit fünf Punkten (batuV4)“. Nach Anhang B und den Daten sind es drei Lernpfad-Punkte plus Sorgfalt, also vier, wie im Foto.

## Nachtrag nach der Zweitprüfung (25.10.2026)

- **F1 behoben:** `foerderPunkte.ts` benennt eine Lücke im aktuellen Thema wie Seite 4 nach ihren Übungsbereichen
  („Teilweise die Wurzel ziehen“). Regressionstest in `StationFoerderansatz.test.tsx` (ohne Fix rot).
- **F2 behoben:** Die V4-Fixtures tragen `NOTIZEN_ZIELE` (Ziele bestätigt, kein eigenes Zielbild). Seite 5 zeigt
  die Ziele und „Wir versprechen keine Noten“, Station 04 die Zeile „Ziel: …“. PDFs und Fotos sind neu erzeugt.
  - Mit der Zielzeile lief der feste Kasten in Station 04 über, um bis zu 61 px. Der Ansichtstest hat das gefunden.
  - Behoben so: Obergrenze 540 statt 460 px, im Hochformat engere Abstände. Ein bestätigtes Ziel ersetzt im
    Kasten den Grund-Satz, der dasselbe sagt; bei Sorgfalt bleibt der Text. Diese Abweichung von der
    Spezifikation steht in `offene-punkte.md`.
- **F3 und F4 offen:** Klassenbänder in Station 02 und Paket Präsentation gegen Bericht sind Produktentscheidungen,
  siehe `offene-punkte.md`.
