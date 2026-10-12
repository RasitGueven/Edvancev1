# Zweitprüfung Hinweise E3 · term_ausklammern + vorzeichen_add_sub

Grundlage: `vorschau-term-vz.md` (13 Aufgaben), Rohdaten `docs/prefill/hinweise-e3-snapshot.json`.
Alles selbst nachgerechnet. Nur gelesen, nichts im Repo geändert.

## Gesamturteil

**Kein „muss“-Befund.** Alle Zahlen stimmen (ggT, Antwort-Ids, Startpunkte, Richtungen, Schrittzahlen).
Keine Stufe nennt das Endergebnis, keine nennt die richtige MC-Option oder ihren Term. Schreibweise
durchgehend „−“ (Unicode), kein Bindestrich als Minus in den Hinweisen. Höchstens zwei Sätze je Stufe,
kein „richtig/falsch“. Drei „kann“-Befunde und eine Korrektur an der Slug-Annahme (siehe unten).

## Korrektur der Slug-Annahme (vorzeichen_add_sub)

Aus den Werten in `acceptance.known_errors`:

| Aufgabe | Lösung | vorzeichen_ignoriert | betrag_fehler | mult_add_verwechslung |
|---|---|---|---|---|
| 05 · −4 + 9 | 5 | 13 = 4 + 9 | −5 (Betrag ok, Vorzeichen falsch) | −36 = (−4)·9 |
| 02 · −7 + 4 | −3 | 11 = 7 + 4 | 3 (Betrag ok, Vorzeichen falsch) | −28 |
| 07 · −9 + 5 | −4 | 14 = 9 + 5 | 4 (Betrag ok, Vorzeichen falsch) | −45 |
| 03 · 2 − 9 | −7 | 11 = 2 + 9 | 7 (Betrag ok, Vorzeichen falsch) | −18 = 2·(−9) |
| 06 · 3 − 8 | −5 | 11 = 3 + 8 | 5 (Betrag ok, Vorzeichen falsch) | −24 |
| **01 · −3 − 5** | −8 | 8 = 3 + 5 | **−2** (Beträge subtrahiert) | 15 = (−3)·(−5) |
| **04 · −6 − 2** | −8 | 8 = 6 + 2 | **4** (Beträge subtrahiert) | 12 = (−6)·(−2) |

- `vorzeichen_ignoriert` = Beträge addiert, ohne Vorzeichen: **bestätigt, in allen 7 Aufgaben**.
  Bei 01 und 04 ist das gleichzeitig „richtiger Betrag, nur ohne Minus“.
- `betrag_fehler` = richtiger Betrag, falsches Vorzeichen: **stimmt nur für 02, 03, 05, 06, 07**.
  Bei 01 und 04 heißt es „Beträge subtrahiert“ (falscher Betrag): −2 bzw. 4.
- `mult_add_verwechslung` = multipliziert statt addiert/subtrahiert: bestätigt.

Folge für die Hinweise: keine. Die Stufe 3 bei 01/04 („Zähl die Schritte zusammen; das Ergebnis bleibt
negativ“) trifft beide tatsächlichen Fehlbilder (zusammen → gegen −2/4, negativ → gegen 8). Der Tag
`Fehlbild: vorzeichen_ignoriert, betrag_fehler` stimmt also überall; nur die Erklärung des Slugs
ist bei 01/04 eine andere. Hinweis für die Datenpflege: `betrag_fehler` ist im Skill nicht einheitlich
belegt (separater Punkt, nicht Teil dieser Prüfung).

`mult_add_verwechslung` wird von keinem Hinweis angesprochen. Das ist kein Regelverstoß (Fehler nur
aus known_errors *dürfen*, müssen aber nicht alle vorkommen).

## term_ausklammern (Schablone, 6 Aufgaben)

| Aufgabe | ggT | Lösung | Antwort-Id | Stufe 2/3 Zahlen | Urteil |
|---|---|---|---|---|---|
| 06 · 12x + 18 | 6 | 6(2x + 3) | c ✓ | 12, 18; „klammern 6 aus“ ✓ | ok |
| 03 · 4x + 20 | 4 | 4(x + 5) | b ✓ | 4, 20; „klammern 4 aus“ ✓ | ok |
| 01 · 4x + 8 | 4 | 4(x + 2) | d ✓ | 4, 8; „klammern 4 aus“ ✓ | ok |
| 02 · 6x + 12 | 6 | 6(x + 2) | c ✓ | 6, 12; „klammern 6 aus“ ✓ | ok |
| 05 · 8x + 12 | 4 | 4(2x + 3) | d ✓ | 8, 12; „klammern 4 aus“ ✓ | ok |
| 04 · 9x + 27 | 9 | 9(x + 3) | a ✓ | 9, 27; „klammern 9 aus“ ✓ | ok |

MC-Ausschluss in Stufe 3: Der genannte Faktor schließt jeweils nur eine Option aus (die mit kleinerem
Faktor: d bei 06/02, c bei 03, a bei 01/05, b bei 04). Es bleiben immer drei Optionen mit gleichem
Faktor; welche passt, muss das Kind durch Teilen (z. B. 18 : 6) selbst herausfinden. Regel eingehalten.

Steigerung: Stufe 1 (Begriff + „größte“), Stufe 2 (ggT an genau diesen Zahlen suchen), Stufe 3 (ggT
genannt, beide Summanden teilen, vergleichen). Minimalhilfe eingehalten.

- **kann (Stufe 3, Schablone):** Die drei Distraktoren mit gleichem Faktor unterscheiden sich nur im
  zweiten Summanden. Ein Probe-Tipp gibt dem Kind eine eigene Kontrolle, ohne mehr zu verraten.
  Vorschlag: „Wir klammern 6 aus: Teile 12x und 18 jeweils durch 6 und schreib die Ergebnisse in die
  Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten.“ (Zahl je Aufgabe
  einsetzen; „Wir klammern 6 aus“ als dritter Satz würde die Zwei-Satz-Grenze reißen, deshalb so
  zusammengezogen.)

## vorzeichen_add_sub (7 Aufgaben)

Stufe 1 (alle gleich): „Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche
Richtung gehst du?“ – keine Zahl, passt zu jeder Aufgabe des Skills. ok.

| Aufgabe | Lösung | Stufe 2 (Start, Richtung, Schritte) | Stufe 3 nachgerechnet | Urteil |
|---|---|---|---|---|
| 01 · −3 − 5 | −8 | −3, links, 5 ✓ | 3 + 5, negativ → −8 ✓ | ok, kann (A) |
| 04 · −6 − 2 | −8 | −6, links, 2 ✓ | 6 + 2, negativ → −8 ✓ | ok, kann (A) |
| 05 · −4 + 9 | 5 | −4, rechts, 9 ✓ | 4 Schritte bis 0, dann 9 − 4 nach rechts → 5 ✓ | ok |
| 03 · 2 − 9 | −7 | 2, links, 9 ✓ | 2 Schritte bis 0, dann 9 − 2 nach links → −7 ✓ | ok |
| 06 · 3 − 8 | −5 | 3, links, 8 ✓ | 3 Schritte bis 0, dann 8 − 3 nach links → −5 ✓ | ok |
| 02 · −7 + 4 | −3 | −7, rechts, 4 ✓ | 7 > 4, 7 − 4, negativ → −3 ✓ | ok, kann (B) |
| 07 · −9 + 5 | −4 | −9, rechts, 5 ✓ | 9 > 5, 9 − 5, negativ → −4 ✓ | ok, kann (B) |

Kein Hinweis nennt das Ergebnis; Stufe 3 lässt jeweils eine kleine Rechnung offen (z. B. 9 − 4).

- **kann (A) · Schablone „gleiche Richtung“ (01, 04), Stufe 3:** „Wir gehen von −3 aus noch 5 weiter
  ins Minus“ wiederholt fast wörtlich Stufe 2, und „Zähl die Schritte zusammen“ lässt offen, welche
  Schritte gemeint sind (die 3 bis −3 zählen mit). Vorschlag (01): „Von der 0 bis −3 sind es schon
  3 Schritte, dann kommen noch 5 dazu. Zähl beide zusammen; das Ergebnis bleibt negativ.“
  (04 analog mit 6 und 2.)
- **kann (B) · Schablone „Gegenrichtung, 0 nicht erreicht“ (02, 07), Stufe 3:** „Rechne 7 − 4“ verlässt
  das Zahlenstrahl-Bild, das die Stufen 1–2 und die Geschwister 05/03/06 tragen. Vorschlag (02):
  „Mit 4 Schritten nach rechts kommst du nicht bis zur 0; es fehlen noch 7 − 4 Schritte. So weit liegst
  du links von der 0, also im Minus.“ (07 analog mit 9 und 5.)

## Zusammenfassung

- 13/13 Aufgaben: **ok**, kein „muss“.
- Alle Zahlen, ggT, Antwort-Ids (c, b, d, c, d, a) und Schrittzahlen stimmen; keine Lösung verraten, kein
  MC-Ausschluss bis auf die richtige Option.
- Slug-Annahme: `vorzeichen_ignoriert` und `mult_add_verwechslung` bestätigt; `betrag_fehler` bedeutet
  nur bei 02/03/05/06/07 „richtiger Betrag, falsches Vorzeichen“, bei 01/04 dagegen „Beträge subtrahiert“
  (−2 bzw. 4). Die Hinweise treffen trotzdem beide Fehlbilder.
- 3 „kann“: Probe-Tipp in term_ausklammern Stufe 3; klarere Stufe 3 bei 01/04; Zahlenstrahl-Formulierung
  statt „Rechne 7 − 4“ bei 02/07.
