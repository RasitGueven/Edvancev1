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
