# Zweitprüfung Erklärsequenzen Lineare Funktionen (E2b)

Prüfer: frischer Subagent (kein Fork, ohne Kenntnis der Lösungen), 07.10.2026.

- **Teil 1, Blind-Löser** nach `tools/blind-loeser/AUFTRAG.md`: Er durfte nur `aufgaben.json` aus
  `tools/blind-loeser/exportiere.mjs` und die Abbildung lesen. Ergebnis in `erklaer-k8-linfkt-checks-blind.json`.
- **Teil 2, Lesen der Sequenzen**: erst nachdem das JSON aus Teil 1 geschrieben war. Gelesen hat er den Export
  `node tools/erklaer-vorschau.mjs … --export` (Markdown und PNG, ohne Lösungen und known_errors der Checks).

## Skill fkt_linear_steigung (Muster)

### Teil 1: Blind-Löser

`node tools/verify-tasks.mjs --from-file docs/prefill/erklaer-k8-linfkt-checks.json --answers-from docs/prefill/erklaer-k8-linfkt-checks-blind.json --min-pass 1.0`
→ **3/3 = 100 %**, 0 Abweichungen, 0 mehrdeutig, 0 unsicher. Der Blind-Abgleich steht auch in
`erklaer-k8-linfkt-checks-verifikation.md`.

| Check | Löser | hinterlegt |
|---|---|---|
| erklaer-steigung-k1-c1 | 4 | 4 |
| erklaer-steigung-k2-c1 | 1.5 | 3/2, 1,5 |
| erklaer-steigung-k3-c1 | 10 | 10 |

### Teil 2: Befunde und was daraus wurde

Der Prüfer fand je Prüfpunkt: **keine fachlichen Fehler** (alle Rechnungen stimmen), **keine Widersprüche zwischen Text
und Bild** (alle Punkte liegen an der genannten Stelle) und **keinen Schritt, der einen Check verrät**.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K3 C | Variante passt nicht · sollte | Der Klartext von `b_ignoriert` („Teilt sofort, ohne die Konstante vorher wegzurechnen“) beschreibt einen Fehler beim Gleichungslösen. Im Check wird nicht geteilt, der Fehler ist 3 · 5 = 15. Die Variante selbst passt zum Fehler. | **Begründet, keine Änderung.** Der Bestand nutzt `b_ignoriert` genau für diesen Fall: In `linfkt-steigung-06` zeigt „8“ (2 · 4, „wie bei einer Ursprungsgeraden gerechnet“) darauf. Fehlbilder dürfen nur aus den known_errors der Aufgaben dieses Skills kommen. Neuer Klartext ist eine Katalogfrage → offener Punkt 15. |
| 2 | K3 C | Sprache · sollte | In 5 + 2 · 2 sind Schrittzahl und Steigung beide 2. „m · x“ wurde nicht eingeführt. | **Behoben:** P(1\|5), m = 3, x = 3: „2 Schritte, 5 + 2 · 3 = 11. Nicht 3 · 3 = 9.“ Neues Bild (y = 3x + 2). „Steigung mal x“ statt „m · x“. |
| 3 | K2 B | Lücke · sollte | „Schau zuerst aufs Bild“, aber der Check hat kein Bild. | **Behoben:** „Ohne Bild: Wird y mit x größer, steigt sie.“ |
| 4 | K2 A | Lücke · sollte | Alle Beispiele haben ganzzahlige Ergebnisse, der Check ergibt 6/4 = 1,5. | **Behoben:** Die Erklärung rechnet die Bildpunkte A(-2\|0), B(2\|2) aus: 2/4, also 0,5. |
| 5 | K2 A | Widerspruch · kann | Bildpunkte im Text nicht genutzt; „Unterschied“ sagt nichts über die Reihenfolge. | **Behoben:** „Hoch = y von B minus y von A. Rüber = x von B minus x von A.“ und die Rechnung aus 4. |
| 6 | K2 C vs. K1 B | Sprache · kann | Gleiche Zahlen (3 rüber, 6 hoch, m = 2, „umgekehrt 3/6“). | **Behoben:** K2 C rechnet A(0\|-3), B(2\|5): 8/2 = 4, umgekehrt 2/8. Neues Bild. |
| 7 | K1 B | Sprache · kann | „Die Zahl für oben steht oben im Bruch“ ist doppeldeutig. | **Behoben:** „Wie weit es nach oben geht, steht oben im Bruch. Wie weit es nach rechts geht, steht unten.“ |
| 8 | K3 B | Lücke · sollte | Koordinaten von P und Q fehlen, die Rechnung endet nicht beim y-Wert. | **Behoben:** „P(0\|-4), m = 2, 4 Schritte: -4 + 4 · 2 = 4, also Q(4\|4). Nicht -4 + 2 = -2.“ |
| 9 | K3 A | Sprache · kann | „nach rechts nach oben“ holprig; „ein Schritt = 1 nach rechts“ fehlt. | **Behoben:** „Ein Schritt heißt: 1 nach rechts. Bei jedem Schritt geht es um m nach oben.“ |
| 10 | K1 | Lücke · kann | Keine Variante für Zählfehler über die x-Achse (Check-Bild von y = -2 bis y = 6). | **Begründet, keine Änderung.** Für Zählfehler gibt es in den known_errors der Steigungs-Aufgaben kein Fehlbild (Bestand); ohne Slug kann die Engine keine Variante danach wählen. Eine falsche Antwort ohne Fehlbild führt zur nächsten ungezeigten Variante (B). Ein neues Fehlbild wäre Katalogarbeit (Lena). |

Nach den Änderungen: Nachrechnung grün (`node tools/erklaer-rechnen.mjs`), pgTAP `session_e2b` 43/43, Vorschau ohne
überlaufenden Bildschirm. Die Check-Aufgaben haben sich nicht geändert, daher gilt das Ergebnis aus Teil 1 weiter.

## Runde 2 (07.10.2026): zweiter Check je Kernidee und Steigungsdreieck

Nach Rasits Entscheidung (zwei Checks je Kernidee, Steigungsdreieck im Bild) prüfte ein **neuer** frischer Subagent:
Teil 1 blind die drei neuen Checks (`…-k1-c2`, `…-k2-c2`, `…-k3-c2`), Teil 2 alle elf geänderten Bilder mit ihrem Text.

### Teil 1: Blind-Löser

| Check | Löser | hinterlegt |
|---|---|---|
| erklaer-steigung-k1-c2 | 1.5 | 3/2, 1,5 |
| erklaer-steigung-k2-c2 | -3 | -3 |
| erklaer-steigung-k3-c2 | 14 | 14 |

Alle sechs Checks zusammen: `verify-tasks --from-file … --answers-from docs/prefill/erklaer-k8-linfkt-checks-blind.json
--min-pass 1.0` → **6/6 = 100 %**, Struktur 6 ok. Im ersten Lauf meldete die Strukturprüfung „wortgleiche Dublette“
(k1-c1 und k1-c2 hatten denselben Text, nur die Abbildung unterschied sich); k1-c2 ist umformuliert („In der Abbildung
siehst du … Wie groß ist die Steigung m dieser Geraden?“), Inhalt und Lösung unverändert.

### Teil 2: Bilder

Der Prüfer fand in allen elf Bildern das Dreieck richtig (Start und Ende auf der Geraden, „rüber“ und „hoch“ passend zu
Gitter, Text und Rechnung), keine Rechen- oder Vorzeichenfehler und keinen verratenen Check.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K3 C | Widerspruch · sollte | Klartext von `b_ignoriert` passt nicht (wie Runde 1, Befund 1). | Begründet, offener Punkt 15. |
| 2 | K3 A | Lesbarkeit · sollte | Zweites „rüber 1“ wird von der Geraden und der Senkrechten des ersten Dreiecks geschnitten. | **Behoben:** Die Dreiecke liegen nicht mehr nebeneinander (P→Q und R→S, vier Punkte). Neue Regel im Nachrechen-Skript: „rüber“ kreuzt kein anderes Dreieck. |
| 3 | K2 A Beispiel, K2 B | Lesbarkeit · sollte | Die Senkrechte läuft durch den Buchstaben des Endpunkts; „rüber 3“ beginnt auf der y-Achse. | **Behoben:** Der Generator setzt den Namen eines Punkts, an dem ein Dreieck von oben ankommt, unter den Punkt (nur mit Dreieck, sonst byte-gleich; Test in `test_koordinatensystem.py`). Neue Regel: „rüber“ nicht auf der y-Achse; K2 A, K2 Beispiel und K2 B haben neue Punkte, Text und Rechnung zogen mit. |
| 4 | K3 A | fachlich · kann | „geht es um m nach oben“ stimmt nur für positives m. | **Behoben:** „Ist m negativ, geht es nach unten.“ |
| 5 | K1 A | Widerspruch · kann | Das Bild zeigt rüber 2 / hoch 4, der Text rechnet nicht. | **Behoben:** „Hier: 4 : 2 = 2.“ |
| 6 | mehrere | Lesbarkeit · kann | Punktnamen auf oder dicht an Achsen und Geraden. | **Offen** (Generator: Namen auf die von der Geraden abgewandte Seite), offener Punkt 17. Lesbar ist es laut Prüfer. |
| 7 | K3 C | Lesbarkeit · kann | y-Achse bis 13, Bild sehr hochkant. | **Behoben:** P(2\|3), m = 3, x = 4 (y bis 10). |

Danach: Nachrechnung grün, Byte-Gleichheit der 53 bestehenden Figuren weiter belegt, pgTAP `session_e2b` 45/45,
Vorschau ohne überlaufenden Bildschirm.

## Skill fkt_linear_yabschnitt

Prüfer: neuer frischer Subagent (kein Fork), 08.10.2026, Ablauf wie oben. Teil 1 sah nur `aufgaben.json` der sechs
y-Abschnitt-Checks (`exportiere.mjs` auf eine gefilterte Check-Charge), Teil 2 den `--export` ohne Lösungen.

### Teil 1: Blind-Löser

`verify-tasks --from-file <y-Abschnitt-Checks> --answers-from docs/prefill/erklaer-k8-linfkt-checks-blind.json --min-pass 1.0`
→ **6/6 = 100 %**, 0 Abweichungen, 0 unsicher.

| Check | Löser | hinterlegt |
|---|---|---|
| erklaer-yabschnitt-k1-c1 | 6 | 6 |
| erklaer-yabschnitt-k1-c2 | -4 | -4 |
| erklaer-yabschnitt-k2-c1 | -1 | -1 |
| erklaer-yabschnitt-k2-c2 | 7 | 7 |
| erklaer-yabschnitt-k3-c1 | 4 | 4 |
| erklaer-yabschnitt-k3-c2 | 15 | 15 |

### Teil 2: Befunde und was daraus wurde

Keine fachlichen Fehler, alle Punkte an der genannten Stelle, kein Schritt verrät einen Check.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K1 A | Lücke · sollte | Nur positive b; „die Zahl ohne x“ kann bei 5x − 4 zu 4 führen. | **Behoben:** Beispiel jetzt f(x) = 3x − 5: „Die Zahl ohne x ist -5. Das Minus davor gehört dazu.“ |
| 2 | K1 A | Sprache · sollte | Die Form y = mx + b fehlt in A. | **Behoben:** „In $y = mx + b$ ist m die Steigung.“ |
| 3 | Bild 14, 15 | Lesbarkeit · kann | Punkt S verdeckt die Achsenzahl an seiner Stelle. | **Offen**, offener Punkt 17 (Namen und Achsenzahlen im Generator). |
| 4 | K2 A Beispiel | Widerspruch · kann | Text geht von P nach links, das Dreieck von S nach rechts mit „hoch -4“. | **Behoben im Text:** „Das Dreieck zeigt denselben Weg von S aus: rüber 4, hoch -4.“ Die Beschriftung „hoch -4“ ist die Konvention des abgenommenen Musters (Steigung K2: „Hoch: -1 - 5 = -6“); „runter 4“ wäre eine Generator-Änderung, offener Punkt 19. |
| 5 | K2 B | Variante passt teilweise · kann | „S tiefer als P“ gilt nur für steigende Geraden. | **Behoben:** „Die Gerade steigt, also liegt S(0\|1) tiefer als P.“ |
| 6 | K2 C | Lücke · kann | Variante prüft am Bild, die Checks haben keins. | **Behoben:** „Ohne Bild: Rechne Schritt für Schritt und schreib jedes Minus mit.“ |
| 7 | K3 C | Sprache · sollte | „Leer“ ohne Sachkontext. | **Behoben:** „Ein Tank hat $h(x) = -2x + 8$ Liter. Zu Beginn sind 8 Liter drin.“ |
| 8 | K3 A | Lücke · kann | Bild zeigt S bei 3, der Text nennt keinen Wert. | **Behoben:** „Hier startet die Gerade bei 3.“ |

Danach: Nachrechnung grün, Blind-Abgleich unverändert (Checks unverändert), Vorschau ohne überlaufenden Bildschirm.
