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

## Skill fkt_linear_gleichung

Prüfer: neuer frischer Subagent (kein Fork), 08.10.2026, Ablauf wie oben.

### Teil 1: Blind-Löser

→ **6/6 = 100 %**, 0 Abweichungen, 0 unsicher. Die Checks von K2 und K3 wurden danach umgestellt (Befund 1, R15);
Wortlaut und Lösungen sind gleich geblieben, die ids wandern mit dem Inhalt mit, der Abgleich gilt weiter.

| Check (nach der Umstellung) | Löser | hinterlegt |
|---|---|---|
| erklaer-gleichung-k1-c1 | 9 | 9 |
| erklaer-gleichung-k1-c2 | -5 | -5 |
| erklaer-gleichung-k2-c1 (b bestimmen) | 1 | 1 |
| erklaer-gleichung-k2-c2 (f(4)) | 7 | 7 |
| erklaer-gleichung-k3-c1 (Becken) | 30 | 30 |
| erklaer-gleichung-k3-c2 (Fitnessstudio) | 110 | 110 |

### Teil 2: Befunde und was daraus wurde

Keine fachlichen Fehler, alle Punkte und Dreiecke an der genannten Stelle, kein Schritt verrät einen Check.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K3 C | Variante passt nicht · sollte | Beide Fehlbilder entstehen nur im zweiten Check (Becken). | **Behoben:** Becken ist jetzt der erste Check und hat zusätzlich `groessen_vertauscht` (50 · 5 − 4 = 246), damit auch B erreichbar bleibt. Neue Regel R15 (offener Punkt 18). |
| 2 | K3 B | Variante passt nicht · sollte | Klartext von `b_ignoriert` („Teilt sofort …“) passt nicht zu „Grundgebühr vergessen“. | **Begründet:** Der Bestand nutzt den Slug genau dafür (`linfkt-gleichung-05`, 6 = 0,30 · 20). Katalogfrage, offener Punkt 15. |
| 3 | K2 C | Variante passt nicht · sollte | „Gefragt ist b, nicht m“ passt nur zum b-Check. | **Behoben:** „Lies genau, was gefragt ist: m oder b.“ Der b-Check ist jetzt der erste Check (R15: `addiert_statt_subtrahiert` und `falsche_groesse_beantwortet` stehen nur dort). |
| 4 | K1 C | Variante passt nicht · sollte | Nur negatives m, Check 1 hat negatives b. | **Behoben:** „y-Achsenabschnitt -3: $y = 2x - 3$. Bei x = 2: $4 - 3 = 1$. Nicht $4 + 3 = 7$.“ Dazu „Prüf dein Ergebnis am Bild: über oder unter der x-Achse?“ (betrag_fehler). |
| 5 | K1 A | Lücke · sollte | f(x) = y nicht gesagt; kein negatives b. | **Behoben:** „Statt y schreibt man auch f(x).“ Beispiel mit $b = -1$, „Ein Minus schreibst du mit.“ |
| 6 | K2 A Beispiel | Lücke · sollte | Kein Minus vor Minus, Check verlangt 5 − (−1). | **Behoben:** Beispiel A(1\|-2), B(3\|4): $\frac{4 - (-2)}{3 - 1}$, „Minus Minus heißt plus.“ |
| 7 | K2 A Bild | Lücke · kann | Dreieck rüber 2, hoch 2 zeigt nicht, was oben steht. | **Behoben:** A(1\|2), B(3\|6), rüber 2, hoch 4. |
| 8 | K3 A | Lücke · kann | Fallender Fall nur ein Satz. | **Behoben:** „15 cm, pro Stunde 2 cm weniger, $h(x) = -2x + 15$.“ |
| 9 | K1 C | Sprache · kann | „passt nicht zur fallenden Geraden“ setzt etwas voraus. | **Behoben** mit Nr. 4 (Satz entfällt). |
| 10 | K1 B/C, K3 B | Sprache · kann | „Abschnitt“ und „Rate“ nicht eingeführt. | **Behoben:** „y-Achsenabschnitt“ ausgeschrieben, „Betrag pro Stück“ statt „Rate“. |
| 11 | K2 A Merksatz | Sprache · kann | Indizes $y_B - y_A$ evtl. neu. | **Begründet, keine Änderung:** derselbe Merksatz wie im abgenommenen Muster (Steigung K2), „hoch durch rüber“ steht im Text. |
| 12 | Bilder | Lesbarkeit · kann | Namen S und P auf der Geraden. | **Offen**, offener Punkt 17. |

Danach: Nachrechnung grün (mit R15), Vorschau ohne überlaufenden Bildschirm.

## Skill fkt_linear_graph

Prüfer Runde 1: neuer frischer Subagent (kein Fork), 08.10.2026, Ablauf wie oben; Teil 1 mit den sechs Check-Abbildungen.

### Teil 1: Blind-Löser

→ **6/6 = 100 %**, 0 Abweichungen, 0 unsicher. Alle Check-Abbildungen laut Löser eindeutig auf ganzen Gitterpunkten ablesbar.

| Check | Löser | hinterlegt |
|---|---|---|
| erklaer-graph-k1-c1 (b ablesen) | -3 | -3 |
| erklaer-graph-k1-c2 (m ablesen) | -2 | -2 |
| erklaer-graph-k2-c1 (y bei x = 1) | -2 | -2 |
| erklaer-graph-k2-c2 (x bei y = -1) | 4 | 4 |
| erklaer-graph-k3-c1 (Taxi, je km) | 3 | 3 |
| erklaer-graph-k3-c2 (Paket, je kg) | 0,5 | 1/2, 0,5 |

### Teil 2, Runde 1: Befunde und was daraus wurde

Keine fachlichen Fehler, alle Punkte und Dreiecke an der genannten Stelle.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K2 A | Lücke · muss | Nur „x gegeben → y“, Check 2 fragt x zu gegebenem y. | **Behoben:** „Ist y gegeben: Geh umgekehrt, von y auf der y-Achse waagerecht zur Geraden, dann senkrecht zur x-Achse.“ |
| 2 | K3 A | Lücke · muss | Paket-Check (m = 0,5): Punkt bei x = 1 nicht auf dem Gitter, „hoch durch rüber“ fehlt in K3 A. | **Behoben:** „Trifft die Gerade bei 1 nach rechts keine Kästchenecke, geh weiter, bis sie eine trifft. Dann: hoch durch rüber.“ (Wortlaut nach Runde 2) |
| 3 | K1 C | Variante passt nicht · sollte | Am ersten Check (b) entsteht `betrag_fehler` bei b, C erklärt nur das Minus von m. | **Behoben** (in Runde 2 nachgeschärft): S(0\|-1), „also $b = -1$, nicht 1“. |
| 4 | K1 C | Widerspruch · sollte | „Nicht 4/(-2)“ = -2 ist die richtige Lösung des nächsten Checks. | **Behoben:** Beispiel rüber 4, hoch -1: $m = -0,25$, „Nicht $\frac{4}{-1} = -4$“. |
| 5 | K2 B | Sprache · sollte | „Geh bei 4 waagerecht“: wo liegt die 4? | **Behoben:** „Dafür startest du auf der y-Achse bei 4 …“ |
| 6 | K1 A Beispiel | Widerspruch · kann | Text „3 nach unten“, Bild „hoch -3“. | **Behoben:** „3 nach unten, also hoch -3.“ |
| 7 | K1 B | Lücke · kann | „Steigung nur 0,5“ ohne Begründung; „Stelle“ meint sonst x. | **Behoben:** „b ist ein Wert auf der y-Achse“, „Die Steigung ist 0,5, sie gehört nicht zu b.“ |
| 8 | K2 A Bild | Lesbarkeit · kann | Keine Hilfslinien für den Ableseweg. | **Offen**, offener Punkt 20 (Generator ohne Ablese-Hilfslinien); P(2\|3) steht jetzt im Text. |
| 9 | K3 B | Sprache · kann | „Nicht umgekehrt“ unklar. | **Behoben:** „Die 6 ist der Start, nicht der Betrag pro Einheit.“ |
| 10 | Bilder | Lesbarkeit · kann | Label S dicht an Achsenzahlen. | **Offen**, offener Punkt 17. |

### Teil 2, Runde 2 (geänderte Stellen, neuer frischer Subagent)

Die überarbeiteten Stellen sind fachlich richtig. Der Prüfer sah die Check-Abbildungen nicht (der `--export` enthält sie
bewusst nicht, sie gehören zu Teil 1) und meldete das als „muss“; das ist eine Eigenschaft des Prüfaufbaus, nicht der
Charge: In Runde 1 lagen alle sechs Abbildungen vor und wurden blind richtig gelöst.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | Checks | Vollständigkeit · muss | Keine Abbildung im Export. | **Begründet:** siehe oben, Teil 1 hatte die Abbildungen. |
| 2 | K3 Beispiel | Lösung verraten? · muss, falls zutreffend | Taxi-Beispiel im selben Kontext wie der Taxi-Check. | **Behoben:** Beispiel jetzt Handytarif. Werte waren schon verschieden (Beispiel 5 € + 2 €/km, Check 4 € + 3 €/km). |
| 3, 4 | K3 A | Lücke, Sprache · sollte | Satz „Punkt nicht auf der Gitterlinie“ ungenau. | **Behoben:** „Kästchenecke“-Wortlaut (siehe Runde 1 Nr. 2). Ein ausgerechnetes Dreieck mit rüber 2 zeigen B (1,5) und C (2,5); A bleibt im Rahmen eines Bildschirms. |
| 5 | K1 A | Lücke · sollte | Wie weit nach rechts? | **Behoben:** „Geh nach rechts, bis die Gerade genau eine Kästchenecke trifft.“ |
| 6 | K1 C | Variante passt · sollte | Bild mit positivem b. | **Behoben:** Gerade $y = -0,25x - 1$, S(0\|-1), P(4\|-2). |
| 7 | K2 B | Variante passt · sollte | Zeigt nur „x gesucht“, der Fehler entsteht bei „y gesucht“. | **Behoben:** beide Richtungen am selben Q(2\|4). |
| 8 | K2 A | Lücke · sollte | Rückrichtung nur als Satz. | **Behoben:** „Umgekehrt gehört zu y = 3 die Stelle x = 2.“ |
| 9 | K1 B | Passung · kann | m zum Vergleich fehlt. | **Behoben** mit Runde 1 Nr. 7. |
| 10 | K3 B | Sprache · kann | „bei jedem Schritt“ vs. rüber 2. | **Behoben:** „je Kästchen nach rechts“. |
| 11 | K1 B, K2 C | Form · kann | Überschriften mit Punkt. | **Keine Änderung:** wie im abgenommenen Muster (z. B. „Erst hoch, dann durch rüber.“). |

## Skill fkt_linear_nullstelle

Prüfer: neuer frischer Subagent (kein Fork), 08.10.2026, Ablauf wie oben; Teil 1 mit den zwei Check-Abbildungen.

### Teil 1: Blind-Löser

→ **6/6 = 100 %**, 0 Abweichungen, 0 unsicher.

| Check | Löser | hinterlegt |
|---|---|---|
| erklaer-nullstelle-k1-c1 (Abbildung) | -4 | -4 |
| erklaer-nullstelle-k1-c2 (Abbildung) | 3 | 3 |
| erklaer-nullstelle-k2-c1 (3x - 12) | 4 | 4 |
| erklaer-nullstelle-k2-c2 (-5x + 10) | 2 | 2 |
| erklaer-nullstelle-k3-c1 (Tank) | 8 | 8 |
| erklaer-nullstelle-k3-c2 (Guthaben) | 15 | 15 |

Alle 30 Checks zusammen: `verify-tasks --from-file docs/prefill/erklaer-k8-linfkt-checks.json --answers-from
docs/prefill/erklaer-k8-linfkt-checks-blind.json --min-pass 1.0` → **30/30 = 100 %**.

### Teil 2: Befunde und was daraus wurde

Keine fachlichen Fehler, alle Punkte an der genannten Stelle, kein Schritt verrät einen Check.

| Nr | Ort | Art · Gewicht | Befund | Erledigt |
|---|---|---|---|---|
| 1 | K1 A Beispiel | Lücke · sollte | Probe mit einem Term, den der Text nie nennt. | **Behoben:** „Die Gerade gehört zu $f(x) = -2x - 2$.“ |
| 2 | K2 A | Lücke · sollte | Sprung von 2x − 6 = 0 auf 2x = 6. | **Behoben:** „Plus 9 auf beiden Seiten: $3x = 9$. Durch 3: $x = 3$.“ (neue Gerade, siehe Nr. 7) |
| 3 | K2 B | Variante passt teilweise · sollte | `falsche_gegenoperation` auch beim b-Schritt. | **Behoben:** „Rechne jeden Schritt rückwärts: Aus minus wird plus, aus mal wird geteilt.“ und „Plus 10: $2x = 10$“. |
| 4 | K2 C | Variante passt teilweise · sollte | Kein Beispiel mit negativem m für `vorzeichen_beim_umstellen`. | **Behoben:** „Ist m negativ: $-2x + 6 = 0$, $-2x = -6$, $x = 3$. Minus durch Minus gibt Plus.“ |
| 5 | K1 B | Sprache · kann | „b“ nicht eingeführt. | **Behoben:** „gehört zum y-Achsenabschnitt“. |
| 6 | K3 B | Methode · kann | Abkürzung 10 : 2. | **Behoben:** „$-2x + 10 = 0$, $-2x = -10$, also nach 5 Minuten.“ |
| 7 | K2 A | Wiederholung · kann | Gerade 2x − 6 wie in Check K1 c2. | **Behoben:** K2 A nimmt $f(x) = 3x - 9$. |
| 8 | Bilder | Lesbarkeit · kann | Gerade läuft über Achsenzahlen, alles lesbar. | **Offen**, offener Punkt 17. |

Danach: Nachrechnung grün, Vorschau ohne überlaufenden Bildschirm.
