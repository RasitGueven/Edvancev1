# R1 · Einordnung der Rückfragen

Klassen: **A** Lena hat recht, Korrektur eindeutig → Migration · **B** Aufgabe stimmt, Frage sachlich beantwortbar →
keine Änderung · **C** didaktische Entscheidung → bleibt `rueckfrage`, Vorschlag an Rasit.

Nachgerechnet mit sympy 1.14 (`(x+5)² − (x+2)(x−2) = 10x + 29`, LGS, Geraden, Flächen). Alle sechs Lösungen stimmen.

| # | id | Klasse | kurz |
|---|---|---|---|
| 1 | `8c4a2d71` | A | Text nach Lenas Formulierung |
| 2 | `a61e8be9` | C | f(x) in Klasse 8? |
| 3 | `ffc76634` | A | x/y vertauscht: zwei Fehlbild-Werte und Dezimal-Schreibweisen fehlen |
| 4 | `1bbce78e` | C | wie 2 |
| 5 | `158c874c` | B | Umstellen nach y führt zur selben Lösung |
| 6 | `6274f6a5` | A | Dreiecksformel: Teilflächen und Seite als Höhe fehlen als Fehlbild |

## 1 · `8c4a2d71` (x + 5)² − (x + 2)(x − 2) für x = 100 → A

Lena schlägt „Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x = 100 ein.“ vor.
Der heutige Text („mit den binomischen Formeln … setze dann x = 100 ein“) ist nicht falsch, aber Lenas Fassung sagt
deutlicher, was eingesetzt wird. Wie in L1 (#316, 49² „mit Hilfe einer binomischen Formel“) wird ihre Formulierung
übernommen. Eine Kleinigkeit weicht ab: „setze dann für x = 100 ein“ ist doppelt (für x … = 100), daher
„setze dann für x den Wert 100 ein“. Die Zahlen im Text bleiben dieselben. Rechnung: 10 · 100 + 29 = 1029, richtig.
Bei der Gegenprobe der Schreibweisen fiel auf: „+1029“ ist im Urteil (`lsa_grade`) voll, steht aber nicht in
`correct_answers` (sonst im Bestand üblich) und gälte für `correct` und die Fehlbild-Erfassung als falsch. Ergänzt.

## 2 · `a61e8be9` f(4) bei m = 3, b = −2 → C

Rechnung stimmt: f(x) = 3x − 2, f(4) = 10. Lenas Frage ist, ob Kinder in Klasse 7/8 die Schreibweise f(x) kennen.
Das ist eine Frage der Klassenstufe und betrifft nicht nur diese Aufgabe: Im LSA-Bestand der `fkt_linear_*`-Skills
nutzen auch zwei schon freigegebene Aufgaben (`fkt_linear_gleichung`, `fkt_linear_yabschnitt`) und sechs Entwürfe f(…).
Eine Einzeländerung hier wäre eine Grundsatzentscheidung durch die Hintertür.

**Vorschlag für Rasit:** f-Schreibweise behalten, wenn sie im Kölner Unterricht der Klasse 8 eingeführt ist (das habe
ich nicht geprüft; Lena kennt die Schulpraxis), und eine Brücke in den Text setzen: „… und berechne damit f(4), also den Funktionswert an der Stelle x = 4.“ Alternative
nach Lena: „… und berechne damit den y-Wert an der Stelle x = 4.“ (ohne f). Beides ändert nur Text, keine Zahl, keine
Wertung. Die Entscheidung sollte für alle f(…)-Aufgaben der Klasse 8 gleich fallen.

## 3 · `ffc76634` b für die Gerade durch A(1 | 1) und B(3 | 7) → A

Rechnung stimmt: m = 6/2 = 3, b = 1 − 3 = −2. Lena: x- und y-Werte werden bei der Steigung und beim Einsetzen vertauscht.

- Beides vertauscht: m = (3 − 1)/(7 − 1) = 1/3, und weil A(1 | 1) symmetrisch ist, b = 1 − 1/3 = **2/3**; mit B
  vertauscht ebenfalls 2/3. Das ist schon als `steigung_kehrwert` hinterlegt (vertauschte Werte im Steigungsdreieck
  = Kehrwert), aber nur als Bruch „2/3“. Dezimal getippt (0,67; 0,7; 0,667; 0,6; 0,66; 0,666) fällt es durch.
- Nur bei der Steigung vertauscht, mit B eingesetzt: 7 = 1/3 · 3 + b → **b = 6** (`steigung_kehrwert`), fehlt.
- Nur beim Einsetzen vertauscht, mit B: 3 = 3 · 7 + b → **b = −18** (`koordinaten_vertauscht`, Familie
  geraden_schaubilder), fehlt. (Mit A ändert das Vertauschen nichts.)

Korrektur: diese known_errors ergänzen (−18 auch als „−18“ und „- 18“, 6 auch als „+6“) und `typical_errors` um den
Eintrag für `koordinaten_vertauscht` erweitern; der Kehrwert-Eintrag nennt zusätzlich b = 6. Keine Kollision mit
−2 oder den vorhandenen Schlüsseln.

## 4 · `1bbce78e` f(3) bei m = −2, b = 5 → C

Rechnung stimmt: f(x) = −2x + 5, f(3) = −1. Lena verweist auf ihre Anmerkung zu f(x) bei Aufgabe 2. Gleiche
Entscheidung, gleicher Vorschlag („… f(3), also den Funktionswert an der Stelle x = 3“).

## 5 · `158c874c` LGS x + 2y = 11, 3x − 4y = 3 → B

Rechnung stimmt: x = 5, y = 3. Lena: Ein Kind könnte nach y umstellen, weil das „normal“ ist. Das LGS hat genau eine
Lösung, jeder richtige Weg (nach x, nach y, Gleichsetzen, Additionsverfahren) endet bei x = 5 und y = 3. Getippt wird
nur das Ergebnis, das Tablet wertet also kein Kind ab, das nach y umstellt. Die Fehlbilder (Klammer vergessen,
Vorzeichen beim Teilen) beschreiben nur den x-Weg; ein Fehler auf dem y-Weg ergibt andere Zahlen und zählt dann als
„falsch ohne Fehlbild“, nie als falsches Fehlbild. Keine Änderung nötig. (AFB I steht schon.)

## 6 · `6274f6a5` Raute a = 13 cm, e = 24 cm, f = 10 cm → A

Rechnung stimmt: A = e · f : 2 = 120 cm²; die Seite passt (√(12² + 5²) = 13). Lena: Kinder nehmen die
Dreiecksformel. Je nachdem, womit:

- g = e, h = f: 24 · 10 : 2 = **120**, das ist die richtige Antwort (die Raute ist zwei Dreiecke e · (f/2) : 2).
- Nur eines der beiden Dreiecke (24 · 5 : 2) = **60**, eines der vier kleinen (12 · 5 : 2) = **30**: fehlt →
  `teilflaeche_vergessen` („lässt bei einer zusammengesetzten Figur eine Teilfläche weg“).
- Die Seite als Grundseite: 13 · 10 : 2 = **65**, 13 · 24 : 2 = **156**: fehlt → `falsche_hoehe` wie schon 13 · 13.

Korrektur: 30, 60, 65, 156 als known_errors in allen sechs Schreibweisen des Bestands (`v`, `+v`, `v cm²`, `vcm²`,
`+v cm²`, `+vcm²`) und zwei `typical_errors`-Einträge. Keine Kollision mit 120 oder vorhandenen Schlüsseln.
