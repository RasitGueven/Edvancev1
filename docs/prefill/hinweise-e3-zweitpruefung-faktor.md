# Zweitprüfung Hinweise · gleichung_quadr_faktor

Quelle: docs/prefill/hinweise-e3-vorschau.md (+ snapshot.json für known_errors/typical_errors). Alle Aufgaben selbst gerechnet, alle Umformungen in den Hinweisen nachgerechnet; keine Rechenfehler gefunden. Alle genannten Fehlbilder stehen in den known_errors der jeweiligen Aufgabe.

| Aufgabe | Urteil | Befunde |
|---|---|---|
| quadrgl-faktor-03 · 3x² = 12x | ok | kann: Stufe 1 nimmt den Ansatz („alles auf eine Seite") schon vorweg, Stufe 2 bringt nur noch die Zeile |
| quadrgl-faktor-01 · x² − 5x = 0 | ok | kann: Fehlbild vorzeichen_aus_klammer (known_error) bleibt ungenutzt |
| quadrgl-faktor-02 · (x − 3)(x + 5) = 0 | Befund | **muss**: Stufe 3 nennt die Umformung „− 5" für x + 5 = 0; auf der rechten Seite steht 0, das Ergebnis −5 (Teilaufgabe 1) ist damit nur noch abzuschreiben. kann: Wir/du-Mischung in einem Satz |
| quadrgl-faktor-05 · h = 20t − 5t² | ok | kann: division_vergessen (known_error) ungenutzt |
| quadrgl-faktor-04 · x(2x − 7) = 0 | ok | kann: Stufe 3 elliptisch formuliert |
| quadrgl-faktor-06 · 2x² + bx = 0 | ok | – |

## Einzelheiten

### quadrgl-faktor-03 · 3x² = 12x (Lösungen 0 und 4)
- Nachgerechnet: 3x² − 12x = 3x · (x − 4) ✓. Fehlbild loesung_null_verloren steht in known_errors ✓.
- Stufe 3 endet bei der faktorisierten Form; das entspricht dem Lösungsweg kurz vor „x = 0 oder x = 4" und ist die gleiche Tiefe wie die Aufgabenstellung von faktor-02. Kein Verstoß.
- **kann (Steigerung):** Stufe 1 enthält schon Warnung *und* Ansatz („bring lieber alles auf eine Seite"); Stufe 2 ist dann nur die Ausführung. Vorschlag Stufe 1: „Gesucht sind alle x, für die beide Seiten gleich sind. Wenn du durch x teilst, geht eine Lösung verloren; überlege, wie du die Gleichung stattdessen so umformst, dass rechts null steht." (Optional, die Steigerung ist auch so vorhanden.)

### quadrgl-faktor-01 · x² − 5x = 0 (Lösungen 0 und 5)
- Nachgerechnet: x · (x − 5) = x² − 5x ✓. loesung_null_verloren in known_errors ✓.
- Stufe 3 beantwortet die Frage aus Stufe 2 und ergänzt das Nullprodukt; „prüfe … auch das einzelne x" nennt den Wert 0 nicht. Ok.
- **kann:** known_errors enthält auch vorzeichen_aus_klammer (−5 statt 5). Vorschlag Stufe 3: „Wir klammern x aus: x · (x − 5) = 0. Prüfe beide Faktoren, auch das einzelne x, und überlege bei x − 5 genau, für welches x die Klammer null wird."

### quadrgl-faktor-02 · (x − 3)(x + 5) = 0 (Lösungen −5 und 3)
- Nachgerechnet: Faktoren null bei x = 3 und x = −5 ✓. vorzeichen_aus_klammer in known_errors ✓. Stufe 1 und 2 ok.
- **muss (Teillösung verraten):** Stufe 3 „bei x + 5 = 0 rechnest du auf beiden Seiten − 5". Da rechts 0 steht, ergibt das unmittelbar x = −5; die Zahl im Hinweis ist genau die Lösung der Teilaufgabe 1 (kleinere Lösung) und muss nur abgeschrieben werden. Zudem nimmt der Hinweis genau die Stelle vorweg, an der das Fehlbild vorzeichen_aus_klammer entsteht. (Vergleich: in faktor-04 bleibt nach „+ 7, dann : 2" noch 7 : 2 zu rechnen, in faktor-06 noch 2 · 3 und das Umstellen.)
- **kann (Sprache):** „Wir stellen … um; bei … rechnest du …" wechselt im selben Satz von Wir- zu Du-Form.
- Vorschlag Stufe 3: „Wir stellen beide Gleichungen nach x um, indem wir die Zahl neben x auf die andere Seite bringen. Achte dabei auf das Vorzeichen und trag die kleinere Lösung zuerst ein."

### quadrgl-faktor-05 · Ball, h = 20t − 5t² (Lösung 4)
- Nachgerechnet: t · (20 − 5t) = 20t − 5t² ✓; t = 0 ist der Abwurf und nicht die gefragte Lösung, darf also genannt werden. vorzeichen_beim_umstellen in known_errors ✓.
- Steigerung 1 → 2 → 3 sauber (Bedingung h = 0 → Gleichung → Faktorisierung + Auswahl).
- **kann:** division_vergessen (t = 20) ist known_error, wird nicht angesprochen. Vorschlag Stufe 3, zweiter Satz: „Die Lösung t = 0 ist der Abwurf; löse also 20 − 5t = 0 nach t auf, achte auf das Vorzeichen und rechne bis t allein steht."

### quadrgl-faktor-04 · x · (2x − 7) = 0 (Lösungen 0 und 3,5)
- Nachgerechnet: 2x − 7 = 0 | + 7 → 2x = 7 | : 2 → x = 3,5 ✓. Hinweis nennt nur die Operationen, die Rechnung 7 : 2 bleibt beim Kind. Stufe 2 und 3 schreiben „x = 0" nicht aus. division_vergessen und loesung_null_verloren in known_errors ✓.
- **kann (Sprache):** „erst auf beiden Seiten + 7, dann durch 2 teilen" ist elliptisch. Vorschlag: „Wir lösen 2x − 7 = 0: Rechne erst auf beiden Seiten + 7 und teile dann durch 2. Vergiss die Lösung aus dem Faktor x nicht."

### quadrgl-faktor-06 · 2x² + bx = 0, Lösungen 0 und 3 (b = −6)
- Nachgerechnet: x · (2x + b) ✓; 2 · 3 + b = 0 → 6 + b = 0 → b = −6 ✓. Die Zahl −6 erscheint nicht; 2 · 3 und das Umstellen bleiben beim Kind. vorzeichen_aus_klammer in known_errors ✓ (typical_error b = 6).
- Steigerung und Lösungsweg passen. ok.

## Runde 2

Geprüft wurden die vier geänderten Stufen jeweils im Zusammenhang mit Stufe 1–3 ihrer Aufgabe. Neue Fehlbild-Angaben stehen alle in den known_errors.

| Aufgabe | Urteil | Befunde |
|---|---|---|
| quadrgl-faktor-02 · Stufe 3 | ok | Der Muss-Befund ist behoben: Keine Zahl aus der Lösung mehr, die Umformung von x + 5 = 0 bleibt beim Kind. Die Steigerung passt (Stufe 2: die Gleichungen, Stufe 3: wie man sie umstellt). Die Wir/du-Mischung steht jetzt in getrennten Sätzen. |
| quadrgl-faktor-01 · Stufe 3 | ok | kann: Der Satz „Ein Produkt ist null, wenn ein Faktor null ist“ ist entfallen, und keine Stufe dieser Aufgabe nennt ihn jetzt noch. „Prüfe beide Faktoren“ setzt ihn voraus. Optional: „Wir klammern x aus: x · (x − 5) = 0. Ein Produkt ist null, wenn ein Faktor null ist; prüfe beide Faktoren, auch das einzelne x, und überlege bei x − 5 genau, wann die Klammer null wird.“ |
| quadrgl-faktor-05 · Stufe 3 | ok | t · (20 − 5t) = 20t − 5t² nachgerechnet. „rechne, bis t allein steht“ zielt auf division_vergessen, ohne 4 oder 20 : 5 zu nennen. |
| quadrgl-faktor-04 · Stufe 3 | ok | Die Operationen + 7 und : 2 stimmen, und 7 : 2 bleibt zu rechnen. x = 0 wird nicht ausgeschrieben. |

Zu faktor-03 Stufe 1: Die Begründung trägt; mein früherer Befund war nur ein Kann. Damit bleiben keine Muss-Befunde offen.
