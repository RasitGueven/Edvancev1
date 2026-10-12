# Zweitprüfung Hinweise E3 · gleichung_quadr_wurzel + gleichung_quadr_formel

Quelle: `scratchpad/e3/vorschau-wurzel-formel.md`, abgeglichen mit `docs/prefill/hinweise-e3-snapshot.json` (known_errors, typical_errors, correct_answers). Alle Aufgaben selbst gerechnet; alle Zahlen in den Hinweisen nachgerechnet und stimmig. Alle genannten Fehlbilder kommen in den known_errors der jeweiligen Aufgabe vor.

| Aufgabe | Urteil | Befunde |
|---|---|---|
| quadrgl-formel-03 · 2x² − 4x − 6 = 0 | ok | – |
| quadrgl-formel-05 · Rechteck 60 cm² | ok | – |
| quadrgl-formel-06 · Weg um Beet 500 m² | kann | Stufe 3 endet vor der eingesetzten Formel, bleibt hinter „bis kurz vor das Ergebnis“ zurück; Umstellen auf = 0 nicht erwähnt |
| quadrgl-formel-01 · x² + 2x − 15 = 0 | ok | – |
| quadrgl-formel-04 · x² + 4x − 1 = 0, gerundet | muss | Stufe 3 „runde auf zwei Stellen“: Anweisung verkürzt, Aufgabe verlangt „zwei Stellen nach dem Komma“ |
| quadrgl-formel-02 · x² − 6x + 5 = 0 | ok | – |
| quadrgl-wurzel-03 · (x − 2)² = 25 | ok | – |
| quadrgl-wurzel-02 · 2x² − 18 = 0 | ok | – |
| quadrgl-wurzel-04 · 3x² = 60, gerundet | muss | Stufe 3 „runde auf zwei Stellen“: wie formel-04 |
| quadrgl-wurzel-06 · Quadrat 121 cm² | ok | – |
| quadrgl-wurzel-05 · Rechteck 98 m² | ok | – |
| quadrgl-wurzel-01 · x² = 49 | muss | Keine Steigerung 2 → 3: Stufe 3 hilft weniger als Stufe 2 und wiederholt im Kern Stufe 1 |

Bilanz: 8 ok, 1 kann, 3 muss. Keine falsche Zahl, keine Stufe verrät eine Lösung oder Teillösung, Sprache überall im Rahmen (Du-Form, höchstens zwei Sätze, keine Wertung, kein $…$).

## Einzelheiten

### quadrgl-formel-03 · ok
Nachgerechnet: : 2 → x² − 2x − 3 = 0, p = −2, q = −3, −p/2 = 1, (p/2)² = 1, √(1 + 3) = 2, x = −1 bzw. 3. Stufe 1 ohne Zahl, Stufe 2 erster Schritt (Division, Fehlbild division_vergessen passt), Stufe 3 endet bei 1 ± √(1 + 3) mit Erinnerung „kleinere Lösung zuerst“. Fehlbilder pq_vorzeichen, division_vergessen in known_errors.

### quadrgl-formel-05 · ok
Nachgerechnet: x(x + 4) = 60 → x² + 4x − 60 = 0, −p/2 = −2, (p/2)² = 4, √64 = 8, x = 6, Länge 10. Stufe 3 nennt weder 6 noch 10, verweist auf positive Breite und „+ 4“ (falsche_groesse_beantwortet, pq_vorzeichen in known_errors). Steigerung sauber.

### quadrgl-formel-06 · kann
Nachgerechnet: (20 + 2x)(15 + 2x) = 300 + 70x + 4x² = 500 → 4x² + 70x − 200 = 0 → x² + 17,5x − 50 = 0; −p/2 = −8,75, (p/2)² = 76,5625, √126,5625 = 11,25, x = 2,5. Alle Zahlen im Hinweis stimmen.
- kann (Stufe 3): Sie hört bei der Normalform auf, während alle anderen Stufen-3-Hinweise die eingesetzte Formel zeigen. Gerade −p/2 und (p/2)² mit Dezimalzahlen sind hier die Hürde (pq_vorzeichen). Außerdem fehlt der Schritt „500 abziehen“ zwischen Ausmultiplizieren und Teilen.
  Vorschlag: „Ausmultiplizieren, 500 abziehen und durch 4 teilen ergibt x² + 17,5x − 50 = 0, also x = −8,75 ± √(76,5625 + 50). Nur die positive Breite ist sinnvoll.“

### quadrgl-formel-01 · ok
Nachgerechnet: p = 2, q = −15, −1 ± √16 = −1 ± 4 → −5, 3. Stufe 3 endet bei −1 ± √(1 + 15), Reihenfolge-Erinnerung vorhanden. Fehlbilder in known_errors.

### quadrgl-formel-04 · muss
Nachgerechnet: p = 4, q = −1, −2 ± √5, √5 ≈ 2,236 → −4,24 und 0,24. Zahlen im Hinweis stimmen, kein Ergebnis verraten.
- muss (Stufe 3, Rundung): „runde auf zwei Stellen“ gibt die Aufgabenanweisung „auf zwei Stellen nach dem Komma“ nur verkürzt wieder; „zwei Stellen“ lässt sich als zwei gültige Ziffern lesen (−4,2), was nicht akzeptiert wird.
  Vorschlag: „Wir setzen ein: x = −2 ± √(4 + 1) = −2 ± √5. Rechne √5 mit dem Taschenrechner, dann minus und plus; runde auf zwei Stellen nach dem Komma, kleinere Lösung zuerst.“

### quadrgl-formel-02 · ok
Nachgerechnet: p = −6, q = 5, −p/2 = 3, (p/2)² = 9, √4 = 2 → 1, 5. „denn −p/2 ist hier positiv“ adressiert pq_vorzeichen passend. Fehlbilder in known_errors.

### quadrgl-wurzel-03 · ok
Nachgerechnet: x − 2 = ±5 → 7, −3. Stufe 1 fragt nach ±5 (Zwischenwert, keine Lösung), Stufe 2 liefert die beiden Gleichungen (negative_loesung_vergessen), Stufe 3 nennt nur die Gegenoperation „+ 2“ (vorzeichen_aus_klammer) und die Reihenfolge. Weiter (z. B. „x = −5 + 2“) wäre bereits Abschreiben; so ist es richtig dosiert.

### quadrgl-wurzel-02 · ok
Nachgerechnet: 2x² = 18, x² = 9, x = ±3. Stufe 3 endet bei x² = 9 plus Hinweis auf beide Vorzeichen; die Wurzel muss noch gezogen werden. Fehlbilder falsche_gegenoperation, wurzel_vergessen, negative_loesung_vergessen in known_errors.

### quadrgl-wurzel-04 · muss
Nachgerechnet: x² = 20, √20 ≈ 4,472 → ±4,47. Zahlen stimmen, Fehlbilder in known_errors.
- muss (Stufe 3, Rundung): wie formel-04, „runde auf zwei Stellen“ statt „auf zwei Stellen nach dem Komma“ (4,5 bei zwei gültigen Ziffern).
  Vorschlag: „Wir ziehen die Wurzel: x = √20 oder x = −√20. Rechne √20 mit dem Taschenrechner, runde auf zwei Stellen nach dem Komma und trag die kleinere Lösung zuerst ein.“

### quadrgl-wurzel-06 · ok
Nachgerechnet: (x + 3)² = 121, x + 3 = ±11, x = 8 oder −14 → 8. Stufe 2 lenkt weg vom gliedweisen Quadrieren (quadrat_gliedweise in known_errors), Stufe 3 endet bei x + 3 = ±11 mit „− 3“ und Hinweis auf die gefragte Größe. Fehlbilder in known_errors.

### quadrgl-wurzel-05 · ok
Nachgerechnet: 2x² = 98, x² = 49, x = 7. Stufe 3 endet bei x² = 49 mit Hinweis auf die positive Lösung. Fehlbilder division_vergessen, falsche_gegenoperation, wurzel_vergessen in known_errors.

### quadrgl-wurzel-01 · muss
Nachgerechnet: x = ±7.
- muss (Steigerung 2 → 3): Stufe 2 gibt bereits x = √49 und x = −√49 an; Stufe 3 („die Zahl, deren Quadrat 49 ist, einmal mit Plus und einmal mit Minus“) fügt nichts hinzu, sondern formuliert Stufe 1 um. Damit hilft Stufe 3 nicht mehr als Stufe 2 (Prinzip der minimalen Hilfe / Steigerung verletzt). Lösung: Stufe 2 zurücknehmen, die Formeln nach Stufe 3 schieben.
  Vorschlag Stufe 2: „Zieh auf beiden Seiten die Wurzel. Dabei entstehen zwei Lösungen, eine positive und eine negative.“
  Vorschlag Stufe 3: „Wir erhalten x = √49 oder x = −√49. Rechne √49 aus und trag die kleinere Lösung zuerst ein.“
