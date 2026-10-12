# Hinweise E3 · Vorschau (KI-Entwurf, alles `entwurf`)

Erzeugt von `node tools/hinweise-e3.mjs vorschau`. Quelle: `tools/hinweise-e3/<skill>.mjs`, Bestand:
`docs/prefill/hinweise-e3-snapshot.json` (Prod, dbread 12.10.2026). Jede Zahl ist von
`node tools/hinweise-e3.mjs pruefen` nachgerechnet. Nicht von Hand ändern.

## gleichung_einschrittig

### gleichung-einschrittig-03 · Gleichungen · Einschrittig · 3x = 18

Aufgabe (`NUMERIC`, `152bcdcd-897b-452b-9a8f-402375540a3f`): Löse die Gleichung. Gib den Wert für x an.<br>3x = 18

Antwort: 6 · Fehlbilder (known_errors): falsche_gegenoperation

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | In 3x = 18 wird x mit 3 multipliziert. Teile deshalb beide Seiten durch 3.<br>_Fehlbild: falsche_gegenoperation_ | Wir teilen beide Seiten durch 3: x = 18 : 3. Rechne die Division aus. |

### gleichung-einschrittig-06 · Gleichungen · Einschrittig · 4x = 24

Aufgabe (`NUMERIC`, `fbd28765-b198-4ff6-bdbe-de9ccc5202de`): Löse die Gleichung. Gib den Wert für x an.<br>4x = 24

Antwort: 6 · Fehlbilder (known_errors): falsche_gegenoperation

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | In 4x = 24 wird x mit 4 multipliziert. Teile deshalb beide Seiten durch 4.<br>_Fehlbild: falsche_gegenoperation_ | Wir teilen beide Seiten durch 4: x = 24 : 4. Rechne die Division aus. |

### gleichung-einschrittig-04 · Gleichungen · Einschrittig · x + 12 = 20

Aufgabe (`NUMERIC`, `d19c8070-85d9-44cc-b4cc-eac3e06010d0`): Löse die Gleichung. Gib den Wert für x an.<br>x + 12 = 20

Antwort: 8 · Fehlbilder (known_errors): falsche_gegenoperation, seiten_verwechselt

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | Zu x wird 12 addiert. Ziehe deshalb auf beiden Seiten 12 ab.<br>_Fehlbild: falsche_gegenoperation_ | Wir ziehen auf beiden Seiten 12 ab: x = 20 − 12. Rechne die Differenz genau in dieser Reihenfolge aus.<br>_Fehlbild: seiten_verwechselt_ |

### gleichung-einschrittig-01 · Gleichungen · Einschrittig · x + 7 = 12

Aufgabe (`NUMERIC`, `bfd877b9-cd3e-490c-82ad-0274b4f85a8b`): Löse die Gleichung. Gib den Wert für x an.<br>x + 7 = 12

Antwort: 5 · Fehlbilder (known_errors): falsche_gegenoperation, seiten_verwechselt

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | Zu x wird 7 addiert. Ziehe deshalb auf beiden Seiten 7 ab.<br>_Fehlbild: falsche_gegenoperation_ | Wir ziehen auf beiden Seiten 7 ab: x = 12 − 7. Rechne die Differenz genau in dieser Reihenfolge aus.<br>_Fehlbild: seiten_verwechselt_ |

### gleichung-einschrittig-02 · Gleichungen · Einschrittig · x − 4 = 9

Aufgabe (`NUMERIC`, `4f6f7cdd-3415-4185-8eae-95083d061b71`): Löse die Gleichung. Gib den Wert für x an.<br>x − 4 = 9

Antwort: 13 · Fehlbilder (known_errors): falsche_gegenoperation, seiten_verwechselt

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | Von x wird 4 abgezogen. Addiere deshalb auf beiden Seiten 4.<br>_Fehlbild: falsche_gegenoperation, seiten_verwechselt_ | Wir addieren auf beiden Seiten 4: x = 9 + 4. Rechne die Summe aus. |

### gleichung-einschrittig-05 · Gleichungen · Einschrittig · x − 9 = 6

Aufgabe (`NUMERIC`, `6fc6928a-6ae3-4c32-9c2e-b9a20451b97c`): Löse die Gleichung. Gib den Wert für x an.<br>x − 9 = 6

Antwort: 15 · Fehlbilder (known_errors): seiten_verwechselt, falsche_gegenoperation

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung mit x gemacht wird und wie du sie rückgängig machst. | Von x wird 9 abgezogen. Addiere deshalb auf beiden Seiten 9.<br>_Fehlbild: falsche_gegenoperation, seiten_verwechselt_ | Wir addieren auf beiden Seiten 9: x = 6 + 9. Rechne die Summe aus. |

## gleichung_quadr_anzahl

### quadrgl-anzahl-04 · Anzahl der Lösungen · 2x² − 8x + 8 = 0

Aufgabe (`NUMERIC`, `0c3d2396-131a-4cba-bd07-4597d92500cf`): Wie viele Lösungen hat die Gleichung 2x² − 8x + 8 = 0?<br>Gib die Anzahl als ganze Zahl an (0, 1 oder 2).

Antwort: 1 · Fehlbilder (known_errors): vorzeichen_potenz, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Durch 2 teilen: x² − 4x + 4 = 0, p = −4, q = 4.<br>D = (−2)² − 4 = 0.<br>D = 0: Es gibt genau eine Lösung (x = 2).<br>Anzahl: 1. | Die Anzahl der Lösungen erkennst du an der Diskriminante. Prüf zuerst, ob die Gleichung schon die Normalform x² + px + q = 0 hat. | Teile die ganze Gleichung durch 2: x² − 4x + 4 = 0.<br>_Fehlbild: division_vergessen_ | Jetzt ist p = −4 und q = 4, also D = (−2)² − 4. Denk daran, dass das Quadrat einer negativen Zahl positiv ist, und überlege, was D für die Anzahl bedeutet.<br>_Fehlbild: vorzeichen_potenz_ |

### quadrgl-anzahl-01 · Anzahl der Lösungen · x² + 4x + 5 = 0

Aufgabe (`NUMERIC`, `a549083d-c72d-44d6-9aba-a138ad6d2dc0`): Wie viele Lösungen hat die Gleichung x² + 4x + 5 = 0?<br>Gib die Anzahl als ganze Zahl an (0, 1 oder 2).

Antwort: 0 · Fehlbilder (known_errors): halbieren_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = 4, q = 5.<br>D = (p/2)² − q = 2² − 5 = −1.<br>D < 0: Unter der Wurzel stünde eine negative Zahl, es gibt keine Lösung.<br>Anzahl: 0. | Die Anzahl der Lösungen hängt davon ab, was in der p-q-Formel unter der Wurzel steht. Wie heißt dieser Teil? | Lies p und q ab: p = 4 und q = 5. Berechne damit die Diskriminante D = (p/2)² − q. | Wir halbieren p und rechnen D = 2² − 5. Schau dann, ob D positiv, null oder negativ ist; davon hängt die Anzahl der Lösungen ab.<br>_Fehlbild: halbieren_vergessen_ |

### quadrgl-anzahl-05 · Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²

Aufgabe (`NUMERIC`, `95077a87-7e8a-4463-83b0-dbbf6facc879`): Ein rechteckiges Feld wird mit 20 m Zaun eingezäunt und soll 25 m² Fläche haben. Für seine Breite x in Metern gilt x · (10 − x) = 25.<br>Wie viele Lösungen hat diese Gleichung? Gib die Anzahl als ganze Zahl an (0, 1 oder 2).

Antwort: 1 · Fehlbilder (known_errors): vorzeichen_potenz, halbieren_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x · (10 − x) = 25<br>10x − x² = 25 \| + x² − 10x<br>0 = x² − 10x + 25, also p = −10, q = 25.<br>D = (−5)² − 25 = 0.<br>D = 0: genau eine Lösung (x = 5, das Feld ist ein Quadrat).<br>Anzahl: 1. | Bring die Gleichung zuerst in die Normalform x² + px + q = 0. Dann entscheidet die Diskriminante über die Anzahl. | Multipliziere aus: 10x − x² = 25. Bring alles nach rechts, damit x² mit Plus dasteht: 0 = x² − 10x + 25. | Mit p = −10 und q = 25 ist p/2 = −5, also D = (−5)² − 25. Denk daran, dass das Quadrat einer negativen Zahl positiv ist.<br>_Fehlbild: halbieren_vergessen, vorzeichen_potenz_ |

### quadrgl-anzahl-03 · Diskriminante · x² − 5x − 6 = 0

Aufgabe (`NUMERIC`, `ef911123-949d-4ea9-a61d-beef95cc8dc0`): Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 5x − 6 = 0.<br>Gib das Ergebnis exakt an.

Antwort: 12,25 · Fehlbilder (known_errors): halbieren_vergessen, vorzeichen_potenz

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = −5, q = −6.<br>D = (−2,5)² − (−6) = 6,25 + 6.<br>D = 12,25. | Die Formel für D steht schon in der Aufgabe. Du brauchst dafür nur p und q aus der Gleichung. | Lies p und q mit ihren Vorzeichen ab: p = −5 und q = −6. Setze beide in D = (p/2)² − q ein. | Wir halbieren p: p/2 = −2,5, also D = (−2,5)² − (−6). Das Quadrat einer negativen Zahl ist positiv, und minus (−6) heißt plus 6.<br>_Fehlbild: halbieren_vergessen, vorzeichen_potenz_ |

### quadrgl-anzahl-02 · Diskriminante · x² − 6x + 8 = 0

Aufgabe (`NUMERIC`, `9f9ab204-2b5e-49d7-aaab-28ddc96ea8b5`): Berechne die Diskriminante D = (p/2)² − q der Gleichung x² − 6x + 8 = 0.<br>Gib das Ergebnis exakt an.

Antwort: 1 · Fehlbilder (known_errors): halbieren_vergessen, vorzeichen_potenz

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = −6, q = 8.<br>D = (−6/2)² − 8 = (−3)² − 8 = 9 − 8.<br>D = 1. | Die Formel für D steht schon in der Aufgabe. Du brauchst dafür nur p und q aus der Gleichung. | Lies p und q mit ihren Vorzeichen ab: p = −6 und q = 8. Setze beide in D = (p/2)² − q ein. | Wir halbieren p: p/2 = −3, also D = (−3)² − 8. Denk daran, dass das Quadrat einer negativen Zahl positiv ist.<br>_Fehlbild: halbieren_vergessen, vorzeichen_potenz_ |

### quadrgl-anzahl-06 · Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung

Aufgabe (`NUMERIC`, `56540a88-7b9e-4935-8702-26f9415e9d14`): Für welchen Wert von q hat die Gleichung x² + 6x + q = 0 genau eine Lösung?<br>Gib q exakt an.

Antwort: 9 · Fehlbilder (known_errors): halbieren_vergessen, betrag_fehler

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Genau eine Lösung heißt D = 0.<br>D = (6/2)² − q = 9 − q = 0, also q = 9.<br>Probe: x² + 6x + 9 = (x + 3)², einzige Lösung x = −3.<br>q = 9. | Überlege, welchen Wert die Diskriminante haben muss, wenn es genau eine Lösung gibt. | Genau eine Lösung heißt D = 0. Stell D für diese Gleichung auf: D = (6/2)² − q. | Wir rechnen (6/2)² aus; diese Zahl minus q muss null ergeben. Stell nach q um und setz dein q zur Probe ein: Ergibt sich wirklich null?<br>_Fehlbild: halbieren_vergessen, betrag_fehler_ |

## gleichung_quadr_faktor

### quadrgl-faktor-03 · Ausklammern · 3x² = 12x

Aufgabe (`MULTI_PART`, `d7d81e80-6776-4308-a690-29675f7882d4`): Löse die Gleichung 3x² = 12x.<br>Gib die Lösungen exakt an.

Antwort: 1: 0 · 2: 4 · Fehlbilder (known_errors): loesung_null_verloren, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| 3x² = 12x \| − 12x<br>3x² − 12x = 0<br>3x ausklammern: 3x · (x − 4) = 0.<br>3x = 0, also x = 0, oder x − 4 = 0, also x = 4.<br>Kleinere Lösung: 0. Größere Lösung: 4. | Gesucht sind alle x, für die beide Seiten gleich sind. Teile nicht durch x, sonst geht eine Lösung verloren; bring lieber alles auf eine Seite.<br>_Fehlbild: loesung_null_verloren_ | Bring 12x auf die linke Seite: 3x² − 12x = 0. | Wir klammern 3x aus: 3x · (x − 4) = 0. Setze jeden Faktor gleich null, löse beide kleinen Gleichungen und trag die kleinere Lösung zuerst ein. |

### quadrgl-faktor-01 · Ausklammern · x² − 5x = 0

Aufgabe (`MULTI_PART`, `b47ef7d3-1933-416f-8fe8-edcbc8fe8929`): Löse die Gleichung x² − 5x = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: 0 · 2: 5 · Fehlbilder (known_errors): loesung_null_verloren, vorzeichen_aus_klammer

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x ausklammern: x · (x − 5) = 0.<br>Ein Produkt ist null, wenn ein Faktor null ist: x = 0 oder x − 5 = 0, also x = 5.<br>Kleinere Lösung: 0. Größere Lösung: 5. | Gesucht sind alle Zahlen für x, die die Gleichung erfüllen. Schau, ob in beiden Summanden derselbe Faktor steckt. | Klammere x aus. Was bleibt von x² − 5x in der Klammer übrig? | Wir klammern x aus: x · (x − 5) = 0. Setze beide Faktoren gleich null, überlege bei x − 5 genau, wann die Klammer null wird, und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: loesung_null_verloren, vorzeichen_aus_klammer_ |

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
| Ein Produkt ist null, wenn ein Faktor null ist.<br>x = 0 oder 2x − 7 = 0 \| + 7, : 2, also x = 3,5.<br>Kleinere Lösung: 0. Größere Lösung: 3,5. | Links steht ein Produkt aus zwei Faktoren, rechts steht null. Was folgt daraus für die einzelnen Faktoren? | Setze jeden der beiden Faktoren einzeln gleich null. Aus dem zweiten Faktor wird die Gleichung 2x − 7 = 0. | Wir lösen 2x − 7 = 0: Rechne erst auf beiden Seiten + 7 und teile dann durch 2. Vergiss die Lösung aus dem Faktor x nicht und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: division_vergessen, loesung_null_verloren_ |

### quadrgl-faktor-06 · Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3

Aufgabe (`NUMERIC`, `90635757-ba7c-4bde-bd7c-04bd79bf8c35`): Die Gleichung 2x² + bx = 0 hat die Lösungen x = 0 und x = 3.<br>Welchen Wert hat b? Gib das Ergebnis exakt an.

Antwort: -6 · Fehlbilder (known_errors): vorzeichen_aus_klammer, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x ausklammern: x · (2x + b) = 0.<br>Die Lösung 3 macht den zweiten Faktor null: 2 · 3 + b = 0, also b = −6.<br>Probe: 2x² − 6x = 2x · (x − 3), Lösungen 0 und 3.<br>b = -6. | Du kennst beide Lösungen und suchst die Zahl b. Überlege, wie die Gleichung nach dem Ausklammern aussieht. | Klammere x aus: x · (2x + b) = 0. | Die Lösung 3 macht den zweiten Faktor null, also setzen wir x = 3 ein: 2 · 3 + b = 0. Stell diese Gleichung nach b um und achte auf das Vorzeichen.<br>_Fehlbild: vorzeichen_aus_klammer_ |

## gleichung_quadr_formel

### quadrgl-formel-03 · p-q-Formel · 2x² − 4x − 6 = 0

Aufgabe (`MULTI_PART`, `1f2a206f-1f63-4866-b446-c8305de6b725`): Löse die Gleichung 2x² − 4x − 6 = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: -1 · 2: 3 · Fehlbilder (known_errors): pq_vorzeichen, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Durch 2 teilen: x² − 2x − 3 = 0, also p = −2, q = −3.<br>x = 1 ± √(1 + 3) = 1 ± 2.<br>Kleinere Lösung: -1. Größere Lösung: 3. | Für die p-q-Formel darf vor x² keine Zahl stehen. Was musst du deshalb zuerst tun? | Teile die ganze Gleichung durch 2: x² − 2x − 3 = 0.<br>_Fehlbild: division_vergessen_ | Jetzt ist p = −2 und q = −3, also x = 1 ± √(1 + 3). Rechne die Wurzel aus, dann einmal minus und einmal plus, und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: pq_vorzeichen_ |

### quadrgl-formel-05 · p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²

Aufgabe (`NUMERIC`, `1271aabc-2cc1-4b2e-a6c5-d7512c7a38ee`): Ein Rechteck ist 4 cm länger als breit. Sein Flächeninhalt beträgt 60 cm².<br>Wie lang ist die längere Seite des Rechtecks? Gib das Ergebnis exakt an.

Antwort: 10 · Fehlbilder (known_errors): falsche_groesse_beantwortet, pq_vorzeichen, wurzel_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Breite x, Länge x + 4: x · (x + 4) = 60<br>x² + 4x − 60 = 0, p = 4, q = −60.<br>x = −2 ± √(4 + 60) = −2 ± 8, also x = 6 oder x = −10; eine Breite ist positiv.<br>Breite 6 cm, längere Seite 6 cm + 4 cm = 10 cm. | Gefragt ist die längere Seite. Nenne die Breite x und überlege, wie du die Länge mit x ausdrückst. | Die Länge ist x + 4, also x · (x + 4) = 60; bring alles auf eine Seite: x² + 4x − 60 = 0. | Mit p = 4 und q = −60 ergibt die p-q-Formel x = −2 ± √(4 + 60). Nur die positive Breite ist sinnvoll; rechne danach + 4, denn gefragt ist die längere Seite.<br>_Fehlbild: falsche_groesse_beantwortet, pq_vorzeichen_ |

### quadrgl-formel-06 · p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²

Aufgabe (`NUMERIC`, `5b36238f-c64c-4578-bd63-55249f185c78`): Ein rechteckiges Beet ist 20 m lang und 15 m breit. Rundherum wird ein Weg angelegt, der überall gleich breit ist. Beet und Weg zusammen bedecken 500 m².<br>Wie breit ist der Weg? Gib das Ergebnis exakt an.

Antwort: 2,5 · Fehlbilder (known_errors): pq_vorzeichen, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Wegbreite x: (20 + 2x) · (15 + 2x) = 500<br>300 + 70x + 4x² = 500<br>4x² + 70x − 200 = 0 \| : 4<br>x² + 17,5x − 50 = 0, p = 17,5, q = −50.<br>x = −8,75 ± √(76,5625 + 50) = −8,75 ± 11,25, also x = 2,5 oder x = −20; eine Breite ist positiv.<br>Der Weg ist 2,5 m breit. | Nenne die Wegbreite x. Überlege, wie lang und wie breit Beet und Weg zusammen sind. | Der Weg liegt auf beiden Seiten, also sind Beet und Weg zusammen 20 + 2x lang und 15 + 2x breit: (20 + 2x) · (15 + 2x) = 500. | Ausmultiplizieren, 500 abziehen und durch 4 teilen ergibt x² + 17,5x − 50 = 0, also x = −8,75 ± √(76,5625 + 50). Nur die positive Breite ist sinnvoll.<br>_Fehlbild: division_vergessen, pq_vorzeichen_ |

### quadrgl-formel-01 · p-q-Formel · x² + 2x − 15 = 0

Aufgabe (`MULTI_PART`, `b6e77404-2577-4e03-b4ce-cb61a5f6a5f9`): Löse die Gleichung x² + 2x − 15 = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: -5 · 2: 3 · Fehlbilder (known_errors): pq_vorzeichen, wurzel_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = 2, q = −15.<br>x = −p/2 ± √((p/2)² − q) = −1 ± √(1 + 15) = −1 ± 4.<br>Kleinere Lösung: -5. Größere Lösung: 3. | Die Gleichung hat schon die Normalform x² + px + q = 0. Welche Formel löst solche Gleichungen? | Lies p und q ab: p = 2 und q = −15. Achte beim Ablesen auf die Vorzeichen. | Wir setzen ein: x = −1 ± √(1 + 15). Rechne die Wurzel aus, dann einmal minus und einmal plus, und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: pq_vorzeichen, wurzel_vergessen_ |

### quadrgl-formel-04 · p-q-Formel · x² + 4x − 1 = 0, gerundet

Aufgabe (`MULTI_PART`, `725448a1-10e2-4e88-beb8-fe57f6e54d06`): Löse die Gleichung x² + 4x − 1 = 0.<br>Runde die Lösungen auf zwei Stellen nach dem Komma.

Antwort: 1: -4,24 · 2: 0,24 · Fehlbilder (known_errors): wurzel_vergessen, pq_vorzeichen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = 4, q = −1.<br>x = −2 ± √(4 + 1) = −2 ± √5, √5 ≈ 2,236.<br>Kleinere Lösung: -4,24. Größere Lösung: 0,24. | Die Gleichung hat schon die Normalform x² + px + q = 0. Welche Formel löst solche Gleichungen? | Lies p und q ab: p = 4 und q = −1. Achte beim Ablesen auf die Vorzeichen. | Wir setzen ein: x = −2 ± √(4 + 1) = −2 ± √5. Rechne √5 mit dem Taschenrechner, dann minus und plus; runde auf zwei Stellen nach dem Komma, kleinere Lösung zuerst.<br>_Fehlbild: pq_vorzeichen, wurzel_vergessen_ |

### quadrgl-formel-02 · p-q-Formel · x² − 6x + 5 = 0

Aufgabe (`MULTI_PART`, `43f39bc1-e7b4-48e6-8b77-ff8e41e77142`): Löse die Gleichung x² − 6x + 5 = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: 1 · 2: 5 · Fehlbilder (known_errors): wurzel_vergessen, pq_vorzeichen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| p = −6, q = 5.<br>x = −p/2 ± √((p/2)² − q) = 3 ± √(9 − 5) = 3 ± 2.<br>Kleinere Lösung: 1. Größere Lösung: 5. | Die Gleichung hat schon die Normalform x² + px + q = 0. Welche Formel löst solche Gleichungen? | Lies p und q ab: p = −6 und q = 5. Achte beim Ablesen auf die Vorzeichen. | Wir setzen ein: x = 3 ± √(9 − 5), denn −p/2 ist hier positiv. Rechne die Wurzel aus, dann einmal minus und einmal plus, und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: pq_vorzeichen, wurzel_vergessen_ |

## gleichung_quadr_wurzel

### quadrgl-wurzel-03 · Wurzelziehen · (x − 2)² = 25

Aufgabe (`MULTI_PART`, `504bbd98-9c80-4124-a66a-9dc7b6651bb9`): Löse die Gleichung (x − 2)² = 25.<br>Gib die Lösungen exakt an.

Antwort: 1: -3 · 2: 7 · Fehlbilder (known_errors): negative_loesung_vergessen, vorzeichen_aus_klammer, wurzel_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| (x − 2)² = 25<br>x − 2 = 5 oder x − 2 = −5 \| + 2<br>x = 7 oder x = −3.<br>Kleinere Lösung: -3. Größere Lösung: 7. | Links steht ein Quadrat, rechts eine Zahl. Welche Zahlen ergeben quadriert 25? | Zieh auf beiden Seiten die Wurzel; dabei entstehen zwei Gleichungen: x − 2 = 5 oder x − 2 = −5.<br>_Fehlbild: negative_loesung_vergessen_ | Wir lösen beide Gleichungen, indem wir auf beiden Seiten + 2 rechnen. Achte auf das Vorzeichen und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: vorzeichen_aus_klammer_ |

### quadrgl-wurzel-02 · Wurzelziehen · 2x² − 18 = 0

Aufgabe (`MULTI_PART`, `4d1a2438-3610-4dc9-b5be-8d35cb5199bd`): Löse die Gleichung 2x² − 18 = 0.<br>Gib die Lösungen exakt an.

Antwort: 1: -3 · 2: 3 · Fehlbilder (known_errors): negative_loesung_vergessen, falsche_gegenoperation, wurzel_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| 2x² − 18 = 0 \| + 18<br>2x² = 18 \| : 2<br>x² = 9<br>x = −√9 oder x = √9.<br>Kleinere Lösung: -3. Größere Lösung: 3. | In der Gleichung steht x nur als x². Bring x² allein auf eine Seite und zieh dann die Wurzel. | Rechne auf beiden Seiten + 18: 2x² = 18. | Wir teilen durch 2: x² = 9. Jetzt ziehst du die Wurzel; denk an beide Vorzeichen und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: falsche_gegenoperation, wurzel_vergessen, negative_loesung_vergessen_ |

### quadrgl-wurzel-04 · Wurzelziehen · 3x² = 60, gerundet

Aufgabe (`MULTI_PART`, `cd6693f5-cc93-4628-baf9-f45436706641`): Löse die Gleichung 3x² = 60.<br>Runde die Lösungen auf zwei Stellen nach dem Komma.

Antwort: 1: -4,47 · 2: 4,47 · Fehlbilder (known_errors): wurzel_vergessen, negative_loesung_vergessen, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| 3x² = 60 \| : 3<br>x² = 20<br>x = −√20 oder x = √20, √20 ≈ 4,472.<br>Kleinere Lösung: -4,47. Größere Lösung: 4,47. | Bring x² allein auf eine Seite und zieh dann die Wurzel. Denk daran, dass es zwei Lösungen gibt. | Teile beide Seiten durch 3: x² = 20.<br>_Fehlbild: division_vergessen_ | Wir ziehen die Wurzel: x = √20 oder x = −√20. Rechne √20 mit dem Taschenrechner, runde auf zwei Stellen nach dem Komma und trag die kleinere Lösung zuerst ein.<br>_Fehlbild: wurzel_vergessen, negative_loesung_vergessen_ |

### quadrgl-wurzel-06 · Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²

Aufgabe (`NUMERIC`, `3a42b89c-7f8a-4b64-94ff-d1d4ac576c32`): Verlängert man jede Seite eines Quadrats um 3 cm, so hat das neue Quadrat einen Flächeninhalt von 121 cm².<br>Wie lang war eine Seite des ursprünglichen Quadrats? Gib das Ergebnis exakt an.

Antwort: 8 · Fehlbilder (known_errors): falsche_groesse_beantwortet, vorzeichen_aus_klammer, wurzel_vergessen, quadrat_gliedweise

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Ursprüngliche Seite x: (x + 3)² = 121<br>x + 3 = 11 oder x + 3 = −11 \| − 3<br>x = 8 oder x = −14; eine Seitenlänge ist positiv.<br>Die Seite war 8 cm lang. | Nenne die ursprüngliche Seite x; die neue Seite ist dann um 3 cm länger. Stell mit dem Flächeninhalt eine Gleichung auf. | Die neue Seite ist x + 3, also gilt (x + 3)² = 121. Am schnellsten geht es, wenn du jetzt die Wurzel ziehst.<br>_Fehlbild: quadrat_gliedweise_ | Wir ziehen die Wurzel: x + 3 = 11 oder x + 3 = −11. Rechne auf beiden Seiten − 3; gefragt ist die ursprüngliche Seite, und nur eine positive Länge ist sinnvoll.<br>_Fehlbild: vorzeichen_aus_klammer, falsche_groesse_beantwortet_ |

### quadrgl-wurzel-05 · Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²

Aufgabe (`NUMERIC`, `bc0cdfe9-2416-4d02-a623-feb820083f07`): Ein rechteckiges Beet ist doppelt so lang wie breit. Sein Flächeninhalt beträgt 98 m².<br>Wie breit ist das Beet? Als Breite ist nur eine positive Lösung sinnvoll. Gib das Ergebnis exakt an.

Antwort: 7 · Fehlbilder (known_errors): falsche_gegenoperation, wurzel_vergessen, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| Breite x, Länge 2x: x · 2x = 98<br>2x² = 98 \| : 2<br>x² = 49<br>x = 7 oder x = −7; eine Breite ist positiv.<br>Das Beet ist 7 m breit. | Nenne die Breite x; dann kannst du auch die Länge mit x ausdrücken. Stell mit dem Flächeninhalt eine Gleichung auf. | Die Länge ist 2x, also gilt x · 2x = 98. | Wir fassen zusammen und teilen durch 2: 2x² = 98, also x² = 49. Zieh die Wurzel; als Breite zählt nur die positive Lösung.<br>_Fehlbild: division_vergessen, falsche_gegenoperation, wurzel_vergessen_ |

### quadrgl-wurzel-01 · Wurzelziehen · x² = 49

Aufgabe (`MULTI_PART`, `9264f90a-1f7b-4170-97da-198c1acc89a3`): Löse die Gleichung x² = 49.<br>Gib die Lösungen exakt an.

Antwort: 1: -7 · 2: 7 · Fehlbilder (known_errors): negative_loesung_vergessen, wurzel_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
| x² = 49 hat zwei Lösungen: x = √49 oder x = −√49.<br>√49 = 7.<br>Kleinere Lösung: -7. Größere Lösung: 7. | Gesucht sind alle Zahlen, die mit sich selbst multipliziert 49 ergeben. Denk daran, dass es mehr als eine gibt.<br>_Fehlbild: negative_loesung_vergessen_ | Zieh auf beiden Seiten die Wurzel. Dabei entstehen zwei Lösungen, eine positive und eine negative. | Wir erhalten x = √49 oder x = −√49. Rechne √49 aus und trag die kleinere Lösung zuerst ein. |

## gleichung_zweischrittig

### gleichung-zweischrittig-02 · Gleichungen · Zweischrittig · 2x + 4 = 20

Aufgabe (`NUMERIC`, `e8348c89-67cb-4650-be91-235e69321776`): Löse die Gleichung. Gib den Wert für x an.<br>2x + 4 = 20

Antwort: 8 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 4: 2x = 16. Links steht jetzt noch 2x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 2x = 16 teilen wir beide Seiten durch 2: x = 16 : 2. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

### gleichung-zweischrittig-01 · Gleichungen · Zweischrittig · 3x + 6 = 24

Aufgabe (`NUMERIC`, `7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992`): Löse die Gleichung. Gib den Wert für x an.<br>3x + 6 = 24

Antwort: 6 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 6: 3x = 18. Links steht jetzt noch 3x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 3x = 18 teilen wir beide Seiten durch 3: x = 18 : 3. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

### gleichung-zweischrittig-05 · Gleichungen · Zweischrittig · 3x + 9 = 30

Aufgabe (`NUMERIC`, `17f3e728-2249-42ba-b5bf-c2a4b344dd00`): Löse die Gleichung. Gib den Wert für x an.<br>3x + 9 = 30

Antwort: 7 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 9: 3x = 21. Links steht jetzt noch 3x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 3x = 21 teilen wir beide Seiten durch 3: x = 21 : 3. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

### gleichung-zweischrittig-04 · Gleichungen · Zweischrittig · 4x + 8 = 40

Aufgabe (`NUMERIC`, `b01451c0-53e5-4da7-9591-280448264835`): Löse die Gleichung. Gib den Wert für x an.<br>4x + 8 = 40

Antwort: 8 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 8: 4x = 32. Links steht jetzt noch 4x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 4x = 32 teilen wir beide Seiten durch 4: x = 32 : 4. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

### gleichung-zweischrittig-03 · Gleichungen · Zweischrittig · 5x + 10 = 45

Aufgabe (`NUMERIC`, `9d15a93e-961b-4569-be8b-c4482dc98301`): Löse die Gleichung. Gib den Wert für x an.<br>5x + 10 = 45

Antwort: 7 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 10: 5x = 35. Links steht jetzt noch 5x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 5x = 35 teilen wir beide Seiten durch 5: x = 35 : 5. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

### gleichung-zweischrittig-06 · Gleichungen · Zweischrittig · 6x + 12 = 42

Aufgabe (`NUMERIC`, `ff5710af-0c0a-47e5-9a57-b2a5bb4ef82d`): Löse die Gleichung. Gib den Wert für x an.<br>6x + 12 = 42

Antwort: 5 · Fehlbilder (known_errors): b_ignoriert, addiert_statt_subtrahiert, division_vergessen

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Gesucht ist die Zahl für x. Überlege, welche Rechnung du zuerst rückgängig machst: das Plus oder das Mal. | Rechne zuerst auf beiden Seiten − 12: 6x = 30. Links steht jetzt noch 6x, nicht x.<br>_Fehlbild: b_ignoriert, addiert_statt_subtrahiert_ | Aus 6x = 30 teilen wir beide Seiten durch 6: x = 30 : 6. Rechne die Division aus.<br>_Fehlbild: division_vergessen_ |

## term_ausklammern

### term-ausklammern-06 · Terme · Ausklammern · 12x + 18

Aufgabe (`MC`, `02b24419-d7e8-40b8-8b74-ef3b4e806b3f`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>12x + 18 = ?

Optionen: a) 6(2x + 18) · b) 6(2x + 6) · c) 6(2x + 3) · d) 3(4x + 6)

Antwort: c · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 12 und 18 beide ohne Rest teilen lassen. | Wir klammern 6 aus: Teile 12x und 18 jeweils durch 6 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

### term-ausklammern-03 · Terme · Ausklammern · 4x + 20

Aufgabe (`MC`, `81f97d0e-1e95-4bbd-bc6a-d05149786c58`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>4x + 20 = ?

Optionen: a) 4(x + 10) · b) 4(x + 5) · c) 2(2x + 10) · d) 4(x + 20)

Antwort: b · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 4 und 20 beide ohne Rest teilen lassen. | Wir klammern 4 aus: Teile 4x und 20 jeweils durch 4 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

### term-ausklammern-01 · Terme · Ausklammern · 4x + 8

Aufgabe (`MC`, `4baeeda9-3985-4a80-8fd0-ecf8bbcfd6af`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>4x + 8 = ?

Optionen: a) 2(2x + 4) · b) 4(x + 8) · c) 4(x + 4) · d) 4(x + 2)

Antwort: d · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 4 und 8 beide ohne Rest teilen lassen. | Wir klammern 4 aus: Teile 4x und 8 jeweils durch 4 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

### term-ausklammern-02 · Terme · Ausklammern · 6x + 12

Aufgabe (`MC`, `65841bd8-ee27-454f-b2a4-ea6f1bb0db33`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>6x + 12 = ?

Optionen: a) 6(x + 12) · b) 6(x + 4) · c) 6(x + 2) · d) 3(2x + 4)

Antwort: c · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 6 und 12 beide ohne Rest teilen lassen. | Wir klammern 6 aus: Teile 6x und 12 jeweils durch 6 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

### term-ausklammern-05 · Terme · Ausklammern · 8x + 12

Aufgabe (`MC`, `ea237a07-681d-4680-bcd0-d94316c899e9`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>8x + 12 = ?

Optionen: a) 2(4x + 6) · b) 4(2x + 12) · c) 4(2x + 6) · d) 4(2x + 3)

Antwort: d · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 8 und 12 beide ohne Rest teilen lassen. | Wir klammern 4 aus: Teile 8x und 12 jeweils durch 4 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

### term-ausklammern-04 · Terme · Ausklammern · 9x + 27

Aufgabe (`MC`, `b15b6be0-1b87-477d-bd88-23b095501581`): Klammere so weit wie möglich aus. Welcher Term ist richtig?<br>9x + 27 = ?

Optionen: a) 9(x + 3) · b) 3(3x + 9) · c) 9(x + 27) · d) 9(x + 9)

Antwort: a · Fehlbilder (known_errors): –

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Ausklammern heißt: Du suchst eine Zahl, die in beiden Summanden steckt. „So weit wie möglich“ heißt, du nimmst die größte solche Zahl. | Suche die größte Zahl, durch die sich 9 und 27 beide ohne Rest teilen lassen. | Wir klammern 9 aus: Teile 9x und 27 jeweils durch 9 und schreib die Ergebnisse in die Klammer. Rechne zur Probe die Klammer wieder aus und vergleiche mit den Antworten. |

## vorzeichen_add_sub

### vorzeichen-addieren-01 · Vorzeichen · Addieren · -3 - 5

Aufgabe (`NUMERIC`, `e96cd37d-0254-4051-bf2d-71a6f7fa2aaf`): Berechne.<br>-3 - 5 = ?

Antwort: -8 · Fehlbilder (known_errors): vorzeichen_ignoriert, mult_add_verwechslung, betrag_fehler

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei −3 und gehst 5 Schritte nach links. | Von der 0 bis −3 sind es schon 3 Schritte, dann kommen noch 5 dazu. Zähl beide zusammen; das Ergebnis bleibt negativ.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-05 · Vorzeichen · Addieren · -4 + 9

Aufgabe (`NUMERIC`, `17674b19-fe14-42ca-98db-6598fa8c5a3a`): Berechne.<br>-4 + 9 = ?

Antwort: 5 · Fehlbilder (known_errors): vorzeichen_ignoriert, betrag_fehler, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei −4 und gehst 9 Schritte nach rechts. | Nach 4 Schritten bist du bei 0. Es bleiben noch 9 − 4 Schritte nach rechts, also ins Plus.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-04 · Vorzeichen · Addieren · -6 - 2

Aufgabe (`NUMERIC`, `27f51c08-6a47-4ceb-b189-f5f07cbcf1cf`): Berechne.<br>-6 - 2 = ?

Antwort: -8 · Fehlbilder (known_errors): betrag_fehler, vorzeichen_ignoriert, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei −6 und gehst 2 Schritte nach links. | Von der 0 bis −6 sind es schon 6 Schritte, dann kommen noch 2 dazu. Zähl beide zusammen; das Ergebnis bleibt negativ.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-02 · Vorzeichen · Addieren · -7 + 4

Aufgabe (`NUMERIC`, `c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0`): Berechne.<br>-7 + 4 = ?

Antwort: -3 · Fehlbilder (known_errors): betrag_fehler, vorzeichen_ignoriert, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei −7 und gehst 4 Schritte nach rechts. | Mit 4 Schritten nach rechts kommst du nicht bis zur 0; es fehlen noch 7 − 4 Schritte. So weit liegst du links von der 0, also im Minus.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-07 · Vorzeichen · Addieren · -9 + 5

Aufgabe (`NUMERIC`, `3b44eada-3589-4bdb-a33b-2fb2ca0a1726`): Berechne.<br>-9 + 5 = ?

Antwort: -4 · Fehlbilder (known_errors): betrag_fehler, vorzeichen_ignoriert, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei −9 und gehst 5 Schritte nach rechts. | Mit 5 Schritten nach rechts kommst du nicht bis zur 0; es fehlen noch 9 − 5 Schritte. So weit liegst du links von der 0, also im Minus.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-03 · Vorzeichen · Addieren · 2 - 9

Aufgabe (`NUMERIC`, `3e6fb055-111e-4888-9177-d2b17dd0fc54`): Berechne.<br>2 - 9 = ?

Antwort: -7 · Fehlbilder (known_errors): betrag_fehler, vorzeichen_ignoriert, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei 2 und gehst 9 Schritte nach links. | Nach 2 Schritten bist du bei 0. Es bleiben noch 9 − 2 Schritte nach links, also ins Minus.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

### vorzeichen-addieren-06 · Vorzeichen · Addieren · 3 - 8

Aufgabe (`NUMERIC`, `738de19f-d3c9-43a0-b5ce-af6e30752c75`): Berechne.<br>3 - 8 = ?

Antwort: -5 · Fehlbilder (known_errors): betrag_fehler, vorzeichen_ignoriert, mult_add_verwechslung

| Lösungsweg | Stufe 1 · Denkanstoß | Stufe 2 · erster Schritt | Stufe 3 · bis kurz vor das Ergebnis |
|---|---|---|---|
|  | Stell dir die Rechnung am Zahlenstrahl vor. Wo startest du, und in welche Richtung gehst du? | Du startest bei 3 und gehst 8 Schritte nach links. | Nach 3 Schritten bist du bei 0. Es bleiben noch 8 − 3 Schritte nach links, also ins Minus.<br>_Fehlbild: vorzeichen_ignoriert, betrag_fehler_ |

