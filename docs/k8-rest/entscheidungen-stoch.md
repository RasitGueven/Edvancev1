# K8-Rest · Thema 2 Daten und Wahrscheinlichkeit (`stoch`): Entscheidungen

Stand 03.10.2026 · Grundlage `docs/k8-rest/phase1.md` · Graph gelesen über `~/bin/dbread`.

## Knotenschnitt und Tiefen

| skill_key | label | Tiefe | direkte Voraussetzungen |
|---|---|---|---|
| `stoch_kenngroessen` | Median, Quartile und Spannweite | 4 | `dezimal_div` (3), `vorzeichen_add_sub` (1) |
| `stoch_laplace` | Laplace-Wahrscheinlichkeit | 5 | `bruch_dezimal` (4) |
| `stoch_gegenereignis` | Gegenereignis | 6 | `stoch_laplace`, `bruch_add` (2) |
| `stoch_pfad_produkt` | Mehrstufige Zufallsexperimente: Produktregel | 6 | `stoch_laplace`, `bruch_mult` (2) |
| `stoch_pfad_summe` | Mehrstufige Zufallsexperimente: Summenregel | 7 | `stoch_pfad_produkt`, `stoch_gegenereignis` |

Neun Kanten. Knoten und Labels wie vom Hub vorgeschlagen. Zwei Abweichungen bei den Kanten:

1. **`stoch_kenngroessen -> vorzeichen_add_sub` dazu.** Eine Aufgabe fragt die Spannweite einer
   Temperaturreihe mit negativen Werten (7 − (−5)). Das ist die typische Schulsituation für
   die Spannweite, und `vorzeichen_add_sub` ist von `dezimal_div` aus nicht erreichbar. Die Tiefe
   bleibt 4.
2. **`stoch_pfad_summe -> stoch_gegenereignis` statt `-> bruch_add`.** „Mindestens einmal“ ist
   ein mehrstufiges Ereignis, das man über das Gegenereignis rechnet. Es gehört deshalb in den
   Summen-Knoten (Tiefe 7), nicht in `stoch_gegenereignis` (Tiefe 6, dort ohne Pfadregel). Damit
   ist `bruch_add` über `stoch_gegenereignis` transitiv erreichbar, die direkte Kante wäre eine
   Doppelung. Beide Voraussetzungen haben Tiefe 6, die Tiefe 7 ändert sich nicht.

Nicht gesetzt, weil transitiv (Graph vom 03.10. gelesen): `bruch_kuerzen` (unter `bruch_dezimal`,
`bruch_add` und `bruch_mult`), `dezimal_mult` und `dezimal_add_sub` (unter `dezimal_div`).
Keine Kante zu `prozent_*`. Prozent ist hier nur die Schreibweise in Hundertsteln, also
`bruch_dezimal`, keine Prozentwert- oder Grundwertrechnung. Die Knoten liegen außerdem auf Tiefe
6 und mehr und würden `stoch_laplace` grundlos nach unten drücken.

„Mit und ohne Zurücklegen“ ist kein eigener Knoten. Es ändert nur die Faktoren entlang des
Pfades und steckt in beiden Pfad-Knoten (Produkt: 3 Aufgaben, Summe: 3 Aufgaben).

## Aufgaben und Antwortformate

- 30 Aufgaben, je 6 pro Knoten, alle `NUMERIC`, **keine Figur**. Es gibt keinen Generator für
  Baumdiagramm, Urne oder Säulen. Experimente stehen als Text in der Aufgabe, Datenreihen als Liste.
- Je Knoten vier reine Anwendungen (AFB I, I, II, II) und zwei mit Sachkontext oder Rückrichtung.
  Rückrichtungen: `laplace-06` (Gesamtzahl aus P und Anzahl), `gegenereignis-06` (Anzahl aus P(nicht
  rot)). Sachkontexte ohne Personen und Marken: Tombola, Lostrommel, Morgentemperaturen,
  Torstatistik einer Handballmannschaft (ohne Vereinsnamen), Abfüllmaschine, Glücksrad auf dem
  Jahrmarkt. Würfel und Münze heißen immer „fairer Würfel“ bzw. „faire Münze“.
- **Wahrscheinlichkeiten:** Die Frage nennt die zulässige Form: „als Bruch“, wenn der Wert
  periodisch ist (1/3, 5/12, 7/15 …), sonst „als Bruch, als Dezimalzahl oder in Prozent“
  (`laplace-05` verlangt „in Prozent“). `correct_answers` trägt trotzdem jede gleichwertige Form:
  - Bruch gekürzt und **jede** ungekürzte Zwischenform bis zum Rohnenner der Rechnung (42/90 →
    7/15, 14/30, 21/45, 42/90). Wer nur teilweise kürzt, rechnet richtig; deshalb gilt auch das.
  - Dezimalzahl nur, wenn sie endlich ist, mit Komma und Punkt.
  - Prozent nur, wenn endlich: „60 %“ und „60%“, bei Nachkommastellen mit Komma und Punkt
    („62,5 %“, „62.5 %“).
  - Jeder falsche Wert in denselben Formen. Das Charge-Skript prüft nach der Normalisierung der
    Bewertung (trim, Komma → Punkt, lower), dass keine Form eines falschen Werts mit einer Form
    der richtigen oder eines anderen Slugs kollidiert.
  - `teilgekuerzt` wird deshalb **nicht** verwendet: Keine Aufgabe verlangt „vollständig gekürzt“.
    Teilweise gekürzt ist dann richtig, nicht falsch.
- **Kenngrößen und Anzahlen:** Zahl mit Komma/Punkt, positive auch mit „+“ (phase1 e), negative
  mit „-“, „−“ und „- “, mit Einheit „°C“ bei der Temperaturreihe.
- Geprüft in der Wegwerf-DB: jede richtige Form `lsa_is_correct = true` und `lsa_grade = 'voll'`
  (auch „60 %“: `lsa_split_value_unit` trennt das Prozentzeichen ab, die Äquivalente greifen).
  Jeder falsche Wert ist nicht richtig, nicht „voll“ und trifft seinen Slug.

## Quartile

Die Schul-Definitionen weichen voneinander ab: Median der Hälften mit oder ohne Zentralwert,
Rangformel (aufgerundetes n/4) und die Tabellenkalkulations-Varianten (inklusive/exklusive
Interpolation). Die beiden Quartil-Aufgaben haben deshalb Reihen, für die **alle** Definitionen
denselben Wert liefern. Es gibt keine Regel im Text, die Definition des Schulbuchs der Lernenden gilt:

- `kenngroessen-03` (n = 8, unteres Quartil): geordnet 4, 6, 6, 9, 11, 15, 15, 18. Rang 2 und 3
  sind beide 6. Jede Definition ergibt 6 (Hälftenmedian (6+6)/2, Rang ⌈2⌉ bzw. Mittel aus Rang 2
  und 3, Interpolation zwischen 6 und 6).
- `kenngroessen-04` (n = 9, oberes Quartil): geordnet 2, 3, 5, 5, 7, 8, 10, 10, 12. Rang 7 und 8
  sind beide 10. Ohne Zentralwert ergibt sich (10+10)/2, mit Zentralwert der Median von 7, 8, 10,
  10, 12, also 10. Rang ⌈6,75⌉ = 7 ergibt ebenfalls 10. Das untere Quartil dieser Reihe hängt von
  der Definition ab (4 oder 5), deshalb wird es **nicht** gefragt und auch nicht als falscher Wert
  hinterlegt.

Median bei gerader Anzahl: `kenngroessen-02` ergibt 13, `kenngroessen-06` ergibt 11,5. Die Mittelwerte
der Fehlbilder sind endlich (14 und 12,9).

## Fehlbilder

Neu (phase1 d, Text wörtlich und gegen phase1 abgeglichen: 7 von 7 gleich, Familie NULL,
`freigegeben_am` NULL), Zahl der Aufgaben:

| Slug | Aufgaben |
|---|---|
| `verhaeltnis_statt_anteil` | 8 |
| `zuruecklegen_ignoriert` | 6 |
| `pfadregel_addiert` | 9 |
| `nur_ein_pfad` | 5 |
| `gegenereignis_nicht_abgezogen` | 8 |
| `mittelwert_statt_median` | 3 |
| `median_ohne_sortieren` | 5 |

Wiederverwendet (vorhanden, nicht angefasst):

- aus der phase1-Liste: `umgekehrt_geteilt` (6, mögliche durch günstige Ergebnisse), `nenner_addiert`
  (1, 1/4 + 1/8 = 2/12 in `gegenereignis-04`).
- **über die phase1-Liste hinaus** (alle in Prod vorhanden, geprüft):
  - `falsche_groesse_beantwortet` (2): Median bzw. das andere Quartil statt des gefragten Quartils.
    Der Klartext („Rechnet richtig, gibt aber die andere gesuchte Größe an.“) trifft das genau.
  - `bedingung_unvollstaendig` (1): `gegenereignis-04` zieht nur Rot oder nur Blau von 1 ab.
  - `seiten_verwechselt` (1): Spannweite als kleinster minus größter Wert (−12).
  - `multipliziert_statt_dividiert` (1): `laplace-06`, 6 · 2/5 statt 6 : 2/5.
- `median_ohne_sortieren` wird auch beim Quartil verwendet (Median der ungeordneten Hälfte). Das
  Quartil ist der Median einer Hälfte; der Denkfehler „nicht geordnet, dann abgezählt“ ist derselbe.
- Für die Spannweite gibt es außer `seiten_verwechselt` kein passendes Fehlbild. Deshalb hat
  `kenngroessen-05` nur einen hinterlegten falschen Wert. „7 − 5 = 2“ (Minus überlesen) passt zu
  keinem vorhandenen Klartext (`vorzeichen_ignoriert` meint das Addieren der Beträge) und ist nicht
  hinterlegt.

## Sondierrang (aus vorlauf-build)

| Knoten | Rang 1 | Rang 2 |
|---|---|---|
| kenngroessen | `kenngroessen-01` {median_ohne_sortieren, mittelwert_statt_median} | `kenngroessen-04` {falsche_groesse_beantwortet, median_ohne_sortieren} |
| laplace | `laplace-01` {umgekehrt_geteilt, verhaeltnis_statt_anteil} | `laplace-06` {multipliziert_statt_dividiert, verhaeltnis_statt_anteil} |
| gegenereignis | `gegenereignis-04` {bedingung_unvollstaendig, gegenereignis_nicht_abgezogen, nenner_addiert} | `gegenereignis-03` {gegenereignis_nicht_abgezogen, verhaeltnis_statt_anteil} |
| pfad_produkt | `pfad-produkt-03` {pfadregel_addiert, zuruecklegen_ignoriert} | `pfad-produkt-01` {pfadregel_addiert} |
| pfad_summe | `pfad-summe-04` {gegenereignis_nicht_abgezogen, nur_ein_pfad, pfadregel_addiert} | `pfad-summe-02` {nur_ein_pfad, zuruecklegen_ignoriert} |

## Weitere Festlegungen

- `curriculum_grade` 8, `class_level` 8, `competency_content` `stochastik`, `cluster_id` Daten & Zufall.
- `est_duration_sec` nach Zeitregel: I 45 s, II 60 s, +30 s Sachkontext. Keine AFB-III-Aufgabe:
  Die Rückrichtungen sind einschrittig umgekehrt (II). Ein dreistufiger Pfad (`pfad-produkt-06`,
  `pfad-summe-05`) ist Anwenden, nicht Verallgemeinern.
- `pfad-summe-04` (mindestens eine Sechs) lässt zwei Wege zu, Gegenereignis oder drei Pfade.
  Beide stehen im Lösungsweg.
- Keine Hinweise (`leer.hints` mit Grund), keine Mastery-Sprache, keine Personen.

## Korrektur nach dem Blind-Abgleich (Hub, 28/30)

| Aufgabe | Soll | Lauf 1 | Lauf 2 | Folge |
|---|---|---|---|---|
| `laplace-05` (Tombola, „in Prozent“) | 20 % | „20“ | „20“ | **Aufgabenmangel**: Das Eingabefeld hat keine Einheit. Bei „in Prozent“ tippt ein Kind plausibel nur die Zahl, und „20“ stand nicht in `correct_answers`. |
| `gegenereignis-04` | 5/8 = 0,625 | 3/8 (Rechenfehler des Lösers) | 0.625 | keine Korrektur |

Die Regel steht jetzt im Charge-Skript (`pFormen`, `prozentErlaubt`). Erlaubt die Frage
„in Prozent“, gilt zusätzlich die **nackte Prozentzahl** ohne Zeichen, mit Komma und Punkt, aber
nur bei einem Prozentwert > 1. Darunter wäre sie mit einer Dezimal-Wahrscheinlichkeit
verwechselbar. Dieselbe Regel gilt für die falschen Werte, die Kollisionsprüfung läuft unverändert
mit. Neu richtig: laplace-02 (60), -04 (60), -05 (20), gegenereignis-02 (65), -04 (62,5),
-05 (40), pfad-produkt-01 (25), -03 (36), pfad-summe-01 (50), -02 (48), -05 (48,8). Neu bei
`known_errors` zum Beispiel laplace-05 „500“ (umgekehrt_geteilt) und „25“ (verhaeltnis_statt_anteil),
pfad-produkt-01 „100“, pfad-summe-01 „200“.

`pfad-produkt-06` (Soll 0,001 = 0,1 %) bekommt **keine** nackte Prozentzahl, weil „0,1“ als
Dezimalzahl 10 % hieße. Die Frage bietet Prozent weiter an („als Bruch, als Dezimalzahl oder in
Prozent“): Prozent ist dort eine natürliche Form (10 % zu leicht → 0,1 %), und mit Zeichen
eingegeben („0,1 %“) wird sie richtig gewertet. Befund: Wer dort „0,1“ meint und 0,1 % denkt, wird als
falsch gewertet. Diese Eingabe ist nicht als Fehlbild hinterlegt.

Nach der Korrektur: Charge und vorlauf-build (Version 20261003104948) ohne Fehler,
verify-prefill 0 Charge-Fehler, Struktur 30/30 ok, Wegwerf-DB IDEMPOTENT, beide Prüfskripte lokal
alle Zeilen t. Sondierrang unverändert, weil die Fehlbildprofile gleich bleiben.

## Offene Punkte / Befunde

1. **Kein Generator für Baumdiagramm, Urne oder Boxplot.** Die Pfad-Aufgaben lassen sich ohne
   Bild lösen. Ein Baumdiagramm würde aber die Darstellungskompetenz (Sto-4) erst prüfbar machen,
   und Boxplots (Sto-2) fehlen ganz. Das wäre ein eigener Generator-Lauf.
2. **Spannweite hat kaum Fehlbilder.** Typische Fehler (Minus überlesen, erster minus letzter Wert
   der ungeordneten Liste) haben keinen passenden Slug. Ein Slug wie `spannweite_ungeordnet` oder ein
   allgemeines `liste_nicht_geordnet` wäre zu prüfen (Lena).
3. **Quartile nur mit definitionsfesten Reihen.** Soll die Plattform eine Definition festlegen
   (z. B. Hälften ohne Zentralwert, wie in NRW-Schulbüchern verbreitet), wären auch allgemeine Reihen
   möglich. Bis dahin bleiben die Reihen so gewählt.
4. **`lsa_grade` und Prozent:** „60 %“ wird über das abgetrennte „%“ als Einheit gelesen. Das ist
   nur bewiesen, solange die Äquivalente vollständig hinterlegt sind; eine Toleranz oder
   `unit_graded` darf an diesen Aufgaben nicht gesetzt werden, sonst wären „60“ und „60 %“
   verschieden bewertet.
5. Alt-Slugs `falsche_groesse_beantwortet`, `bedingung_unvollstaendig`, `seiten_verwechselt` und
   `multipliziert_statt_dividiert` fehlen in der Wegwerf-DB (Datenimport). Die Prüfskripte schalten
   „Slugs existieren“ mit `-v lokal=true` ab; in Prod sind alle sechs wiederverwendeten Slugs
   vorhanden (dbread, Substrat-Prüfung Zeile „wiederverwendet_vorhanden“ = t).
