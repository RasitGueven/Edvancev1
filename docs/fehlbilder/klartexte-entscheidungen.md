# Fehlbild-Klartexte (W5-a) — Bestand und Entscheidungen

Stand 2026-10-04. Migrationen `20261004002101_fehlbild_klartexte_entwuerfe.sql`
(eingespielt) und `20261004003939_fehlbild_familien_entwuerfe.sql` (Nachtrag),
Prüfskript `supabase/checks/fehlbild_klartexte.PRUEFUNG.sql`, Abnahmeliste
[klartexte-abnahme.md](klartexte-abnahme.md).

## Bestand (Teil 1, per dbread)

| | Anzahl |
|---|---|
| Slugs in `known_errors` von Nicht-VERA-Aufgaben | **153** |
| davon ohne Zeile in `fehlbild_labels` | 0 |
| davon ohne Klartext | **53** |
| davon mit Klartext, aber ohne Erklärung | 27 (alle schon abgenommen) |
| Lückenliste 1c (Klartext oder Erklärung leer) | **80** |
| davon in den Themen der ersten LSA | 28 |
| verwendete Slugs ohne Familie | 85 (53 aus 1c + 32 weitere) |
| verwendete Slugs mit `freigegeben_am` | 29 |

`known_errors` kommt im Bestand nur als Objekt `{"falscher Wert": "slug"}` vor,
keine Listenform. Neu gegenüber früheren Zählungen: In 99 mehrteiligen Aufgaben
(Vorlauf, LGS, K9/K10) steht `known_errors` **je Teilaufgabe**
(`acceptance -> '1' -> 'known_errors'`). Die Abfrage aus A20 sah nur die oberste
Ebene und fand 145 Slugs; mit den Teilaufgaben sind es 153. Prüfskript K1 zählt
beide Ebenen.

Erste LSA = Thema `reelle_zahlen` plus `thema_einstieg`, `skill_voraussetzung`
und deren Vorgänger über `skill_kante`: 14 Skills (zahl_wurzel_*, potenzen,
bruch_dezimal, bruch_kuerzen, dezimal_*, runden_ueberschlag, vorzeichen_*).
„LSA“ in den Tabellen heißt: der Slug kommt in mindestens einer Aufgabe dieser
Skills vor.

Kein Blocker: 53 Slugs ohne Klartext liegen unter der Grenze von 80.

## Entscheidungen

**E1 — Klartext beschreibt die Handlung, Erklärung den Grund.** Klartext ist
ein Satz im Passiv („Es wurde malgenommen, wo geteilt werden muss.“), meist
mit einem kleinen Zahlenbeispiel. Seit AF4 ist `klartext` der Coach-Satz, er
bleibt deshalb sachlich und kurz. Die Erklärung hat höchstens zwei Sätze: was
richtig wäre, und warum der Schritt naheliegt. Keine Aussagen über das Kind,
keine Prognose, kein „Geübt wird …“ (das wäre ein Versprechen, das der Text
nicht halten kann). Jeder Satz wurde gegen **alle** Aufgaben des Slugs
gelesen, nicht nur gegen zwei Beispiele; wo die Aufgaben auseinanderlaufen,
ist der Satz allgemeiner und der Unterschied steht als Befund im
Abnahme-Dokument (Abschnitt 3).

**E2 — Keine Familie in der ersten Migration** (durch E7 ergänzt). Der Auftrag sieht vor, leere
Familien zu füllen. Das tut die Migration bewusst nicht.
`lsa_fehlbild_auswertung` gibt den Familien-Elterntext aus, sobald die
**Familie** abgenommen ist (`fehlbild_familien.freigegeben_am`), und prüft die
Abnahme des einzelnen Slugs gar nicht. Alle fünf Familien sind seit 14.08.
abgenommen. Eine Familie an einen neuen Entwurf zu hängen, hieße also, den
Slug ohne Lenas Blick in den Elternbericht zu schalten — genau das, was
`freigegeben_am` verhindern soll. Die Vorschläge stehen in Tabelle 1 der
Abnahmeliste (14 von 53; für die übrigen passt keine der fünf Familien).

**E3 — Keine Erklärung unter einer alten Abnahme.** Die 27 Slugs mit
Klartext, aber ohne Erklärung, sind alle abgenommen. Eine neu eingetragene
Erklärung stünde unter Lenas Zeitstempel vom 14.08., ohne dass sie sie
gelesen hat. Die Migration fasst deshalb keine Zeile mit `freigegeben_am`
an. Die 27 Entwürfe stehen nur in Tabelle 1b. `erklaerung` wird heute
außerdem nur im Autoren-Werkzeug ausgewertet (`authoring_review_meta`), nicht
im Bericht — es eilt also nicht.

**E4 — `teilgekuerzt` bleibt leer.** `fehlbild_familien.PRUEFUNG.sql` F14
(läuft in CI) verlangt ausdrücklich, dass `teilgekuerzt` keinen Klartext
bekommt, bevor der Slug umbenannt ist. Das ist eine frühere, begründete
Entscheidung; die Migration überstimmt sie nicht. Der Entwurf steht trotzdem
in Tabelle 1 (markiert), Prüfskript K1 nimmt den Slug aus, K3 prüft die
Gegenrichtung. Der Slug liegt im LSA-Umfang (bruch_kuerzen,
zahl_wurzel_irrational) — die Umbenennung sollte vor der LSA passieren.

**E5 — Nichts überschreiben.** Die Migration legt fehlende Zeilen per
`on conflict (slug) do nothing` an und füllt bestehende Zeilen Feld für Feld
nur, wo `klartext` bzw. `erklaerung` null oder leer ist. Zweiter Lauf: 0
Zeilen (lokal geprüft). Sicherheitsgrenze nur nach oben: höchstens 52
berührte Zeilen. In Prod ergänzt sie 52 vorhandene Zeilen; im CI-Neuaufbau
legt sie die meisten neu an (lokal: 51 neu, 1 ergänzt).

**E6 — Häufigkeit = Zahl der Aufgaben.** Echte Antworten mit Fehlbild gibt
es bisher kaum; die Zahl der Aufgaben, in denen ein Slug hinterlegt ist,
zeigt besser, wie oft Lena den Satz später lesen wird.

**E7 — Nachtrag: fünf Entwurfs-Familien (Migration 20261004003939).** Auf
Rasits Auftrag nach dem Einspielen der ersten Migration. Neu sind
`brueche_anteile`, `kommazahlen`, `potenzen_wurzeln`, `runden` und
`rechenart_formel`, jeweils mit Elterntext, aber ohne `freigegeben_am`.
Zugeordnet sind 33 Slugs: alle 21 LSA-Slugs ohne Familie (außer
`teilgekuerzt`, F14) und 12 weitere, die inhaltlich passen (Bruchrechnung,
Formel-Verwechslungen). Zugeordnet wird nur, wo `familie` leer ist, und nur zu
einer Familie, die nicht freigegeben ist; eine schon freigegebene Familie
bekommt nie neue Slugs. Die 14 Vorschläge zu den alten Familien (E2) bleiben
deshalb unverändert Vorschläge.

Dass eine Entwurfs-Familie den Elternbericht nicht erreicht, ist dreifach
belegt:
- `lsa_fehlbild_auswertung` liefert `familie_elterntext` nur bei gesetztem
  `fehlbild_familien.freigegeben_am`.
- `src/lib/reportFehlbilder.ts` verwirft Zeilen ohne Elterntext (Test
  `reportFehlbilder.test.ts`).
- Der Funktionstest `fehlbild_familien_entwurf.PRUEFUNG.sql` legt in der
  Wegwerf-DB eine Sitzung mit `mal_exponent` und `komma_ignoriert` an: kein
  Elterntext; nach Freigabe von `potenzen_wurzeln` genau dessen Text.

`rueckbezug.ts` nutzt Familienschlüssel nur aus den schon gebündelten,
also freigegebenen Familien. Alle fünf Familientexte prüfte derselbe
Zweitprüfer; Beanstandungen sind eingearbeitet.

## Befund für die erste LSA: der Elternbericht hängt an der Familie

Der Auftrag geht davon aus, dass ein Fehlbild im Elternbericht erscheint,
sobald es einen abgenommenen Klartext hat. Im Code ist es anders:

- Der Elternbericht (`lsa_fehlbild_auswertung` → `src/lib/reportFehlbilder.ts`)
  zeigt **nur Familien-Elterntexte**. Ein Slug ohne Familie fällt still weg,
  egal ob sein Klartext abgenommen ist.
- Der Slug-Klartext geht nur in die Coach-Sicht (`lsa_fehlbild_report`), und
  dort nur mit `freigegeben_am`.

Folge: Diese Migration macht die 52 Fehlbilder für den Coach sichtbar,
sobald Lena abnimmt — für Eltern erst, wenn sie zusätzlich eine Familie
bekommen. **22 der LSA-relevanten Slugs haben keine Familie.** Für die
meisten davon (Brüche, Kommazahlen, Potenzen und Wurzeln, Runden) passt keine
der fünf Familien `vorzeichen`, `gleichungen_umformen`, `rechenreihenfolge`,
`einheiten_massstab`, `sachaufgaben`. Vor der ersten LSA braucht es deshalb
wahrscheinlich neue Familien mit eigenem Elterntext, zum Beispiel
„Kommazahlen“, „Brüche“, „Potenzen und Wurzeln“, „Runden“. Das ist eine
Entscheidung für Lena. Der Nachtrag (E7) legt diese Familien als Entwurf an.

Verwendete Slugs mit Klartext, aber ohne Familie (32, außerhalb der Lückenliste):
pi_vergessen, radius_durchmesser_verwechselt, bogenmass_modus,
hypotenuse_verwechselt, tangens_verwechselt, koordinaten_vertauscht,
sin_cos_vertauscht, potenzgesetz_verwechselt, strahlensatz_falsch_zugeordnet,
winkelbeziehung_verwechselt, umkehrfunktion_vergessen, nur_eine_grundseite,
pfadregel_addiert, gegenereignis_nicht_abgezogen, kreisanteil_falsch,
periode_falsch, verhaeltnis_statt_anteil, amplitude_verwechselt,
teilflaeche_vergessen, drittel_vergessen, faktor_ohne_wurzel (LSA),
zuruecklegen_ignoriert, anfangswert_faktor_vertauscht,
basiswinkel_falsch_zugeordnet, log_falsch_geteilt, median_ohne_sortieren,
nur_ein_pfad, irrational_verwechselt (LSA), pythagoras_ohne_rechten_winkel,
aussenwinkel_verwechselt, mittelwert_statt_median, rechter_winkel_falsche_ecke.

## Prüfung (Teil 3)

- Unabhängige Zweitprüfung der Texte durch einen frischen Subagenten, der je
  Slug bis zu vier Beispielaufgaben nachgerechnet hat. Runde 1: 80 Slugs,
  davon 27 beanstandet (10 neue Entwürfe, 17 Erklärungen/Klartexte in 1b).
  Runde 2: 20 überarbeitete Fassungen, davon 5 beanstandet. Runde 3: 5,
  davon 2 beanstandet; deren Ersatztexte wurden wörtlich übernommen.
  Beanstandungen an schon abgenommenen Klartexten stehen als Befund in
  Abschnitt 3 der Abnahmeliste, die Klartexte selbst sind unverändert.
- Wegwerf-DB aus allen 139 Migrationen + dieser: Lauf 1 ok, Lauf 2 ändert
  nichts (auch mit `--single-transaction`), Prüfskript K1–K3 grün.
  Gegenprobe ohne Migration: K1 schlägt an.
- Prüfskript lesend gegen Prod vor dem Einspielen: K1 meldet genau die 52
  Slugs der Migration.
