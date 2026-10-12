# Hinweise E3 · Vorschau (KI-Entwurf, alles `entwurf`)

Erzeugt von `node tools/hinweise-e3.mjs vorschau`. Quelle: `tools/hinweise-e3/<skill>.mjs`, Bestand:
`docs/prefill/hinweise-e3-snapshot.json` (Prod, dbread 12.10.2026). Jede Zahl ist von
`node tools/hinweise-e3.mjs pruefen` nachgerechnet. Nicht von Hand ändern.

## gleichung_quadr_faktor

### quadrgl-faktor-03 · Ausklammern · 3x² = 12x

Aufgabe (`MULTI_PART`, `d7d81e80-6776-4308-a690-29675f7882d4`): Löse die Gleichung 3x² = 12x.<br>Gib die Lösungen exakt an.

Antwort: 1: 0 · 2: 4 · Fehlbilder (known_errors): loesung_null_verloren, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| 3x² = 12x \| − 12x<br>3x² − 12x = 0<br>3x ausklammern: 3x · (x − 4) = 0.<br>3x = 0, also x = 0, oder x − 4 = 0, also x = 4.<br>Kleinere Lösung: 0. Größere Lösung: 4. | Gesucht sind alle x, für die beide Seiten gleich sind. Teile nicht durch x, sonst geht eine Lösung verloren; bring lieber alles auf eine Seite.<br>_Fehlbild: loesung_null_verloren_ | Bring 12x auf die linke Seite: 3x² − 12x = 0. | Wir klammern 3x aus: 3x · (x − 4) = 0. Setze jetzt jeden Faktor gleich null und löse beide kleinen Gleichungen. |

### quadrgl-faktor-01 · Ausklammern · x² − 5x = 0

Aufgabe (`MULTI_PART`, `b47ef7d3-1933-416f-8fe8-edcbc8fe8929`): Löse die Gleichung x² − 5x = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: 0 · 2: 5 · Fehlbilder (known_errors): loesung_null_verloren, vorzeichen_aus_klammer

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x ausklammern: x · (x − 5) = 0.<br>Ein Produkt ist null, wenn ein Faktor null ist: x = 0 oder x − 5 = 0, also x = 5.<br>Kleinere Lösung: 0. Größere Lösung: 5. | Gesucht sind alle Zahlen für x, die die Gleichung erfüllen. Schau, ob in beiden Summanden derselbe Faktor steckt. | Klammere x aus. Was bleibt von x² − 5x in der Klammer übrig? | Wir klammern x aus: x · (x − 5) = 0. Ein Produkt ist null, wenn ein Faktor null ist; prüfe beide Faktoren, auch das einzelne x, und überlege bei x − 5 genau, wann die Klammer null wird.<br>_Fehlbild: loesung_null_verloren, vorzeichen_aus_klammer_ |

### quadrgl-faktor-02 · Nullprodukt · (x − 3)(x + 5) = 0

Aufgabe (`MULTI_PART`, `1c4a31af-20bc-4348-b8d9-cd83b273ff38`): Löse die Gleichung (x − 3)(x + 5) = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: -5 · 2: 3 · Fehlbilder (known_errors): vorzeichen_aus_klammer

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Ein Produkt ist null, wenn ein Faktor null ist.<br>x − 3 = 0, also x = 3, oder x + 5 = 0, also x = −5.<br>Kleinere Lösung: -5. Größere Lösung: 3. | Links steht schon ein Produkt, rechts steht null. Was weißt du über ein Produkt, das null ergibt? | Ein Produkt ist null, wenn ein Faktor null ist. Setze deshalb jede Klammer einzeln gleich null: x − 3 = 0 und x + 5 = 0. | Wir stellen beide Gleichungen nach x um, indem wir die Zahl neben x auf die andere Seite bringen. Achte dabei auf das Vorzeichen und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: vorzeichen_aus_klammer_ |

### quadrgl-faktor-05 · Nullprodukt · Ball landet wieder, h = 20t − 5t²

Aufgabe (`NUMERIC`, `9879542e-bb69-41c6-a77f-3916a26ffad1`): Ein Ball wird vom Boden aus senkrecht nach oben geworfen. Seine Höhe in Metern nach t Sekunden ist h = 20t − 5t².<br>Nach wie vielen Sekunden ist der Ball wieder am Boden? Gib das Ergebnis exakt an.

Antwort: 4 · Fehlbilder (known_errors): division_vergessen, vorzeichen_beim_umstellen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Am Boden ist h = 0: 20t − 5t² = 0.<br>t ausklammern: t · (20 − 5t) = 0.<br>t = 0 (Abwurf) oder 20 − 5t = 0 \| + 5t, : 5, also t = 4.<br>Der Ball ist nach 4 s wieder am Boden. | Am Boden hat der Ball die Höhe null. Welche Gleichung entsteht daraus für t? | Setze h = 0: 20t − 5t² = 0. | Wir klammern t aus: t · (20 − 5t) = 0. Die Lösung t = 0 ist der Abwurf; löse also 20 − 5t = 0 nach t auf, achte auf das Vorzeichen und rechne, bis t allein steht.<br>_Fehlbild: vorzeichen_beim_umstellen, division_vergessen_ |

### quadrgl-faktor-04 · Nullprodukt · x(2x − 7) = 0

Aufgabe (`MULTI_PART`, `c3be2e88-1087-479f-bf95-9dbd732efa56`): Löse die Gleichung x · (2x − 7) = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: 0 · 2: 3,5 · Fehlbilder (known_errors): loesung_null_verloren, vorzeichen_aus_klammer, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Ein Produkt ist null, wenn ein Faktor null ist.<br>x = 0 oder 2x − 7 = 0 \| + 7, : 2, also x = 3,5.<br>Kleinere Lösung: 0. Größere Lösung: 3,5. | Links steht ein Produkt aus zwei Faktoren, rechts steht null. Was folgt daraus für die einzelnen Faktoren? | Setze jeden der beiden Faktoren einzeln gleich null. Aus dem zweiten Faktor wird die Gleichung 2x − 7 = 0. | Wir lösen 2x − 7 = 0: Rechne erst auf beiden Seiten + 7 und teile dann durch 2. Vergiss die Lösung aus dem Faktor x nicht.<br>_Fehlbild: division_vergessen, loesung_null_verloren_ |

### quadrgl-faktor-06 · Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3

Aufgabe (`NUMERIC`, `90635757-ba7c-4bde-bd7c-04bd79bf8c35`): Die Gleichung 2x² + bx = 0 hat die Lösungen x = 0 und x = 3.<br>Welchen Wert hat b? Gib das Ergebnis exakt an.

Antwort: -6 · Fehlbilder (known_errors): vorzeichen_aus_klammer, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x ausklammern: x · (2x + b) = 0.<br>Die Lösung 3 macht den zweiten Faktor null: 2 · 3 + b = 0, also b = −6.<br>Probe: 2x² − 6x = 2x · (x − 3), Lösungen 0 und 3.<br>b = -6. | Du kennst beide Lösungen und suchst die Zahl b. Überlege, wie die Gleichung nach dem Ausklammern aussieht. | Klammere x aus: x · (2x + b) = 0. | Die Lösung 3 macht den zweiten Faktor null, also setzen wir x = 3 ein: 2 · 3 + b = 0. Stell diese Gleichung nach b um und achte auf das Vorzeichen.<br>_Fehlbild: vorzeichen_aus_klammer_ |

