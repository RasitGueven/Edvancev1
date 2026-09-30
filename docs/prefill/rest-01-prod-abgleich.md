# rest-01: Abgleich mit Produktion (nur gelesen, 2026-09-30T12:09:39.874Z)

Die Migration wuerde heute **134** Felder aendern, davon **0** Ueberschreibungen; bei **0** Feldern steht in Prod schon ein anderer Wert (bleibt wegen Compare-and-set unangetastet).

## Kontext je Aufgabe

| # | Aufgabe | Status | Herkunft | Beanstandungen | Kennzeichen heute | Coach-Hinweise | Loesung nach Import geaendert |
|---|---|---|---|---|---|---|---|
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 9 | AFB I · Grundwert · 20 sind 10 % | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 10 | AFB I · Grundwert · 45 sind 10 % | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 13 | AFB I · Potenzen · 3^2 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 14 | AFB I · Potenzen · 5^2 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | draft | edvance_fundament_afb1 | 0 | {} | [] | nein |
| 23 | Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4) | draft | edvance_k8_binom | 0 | {} | [] | nein |
| 24 | Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2) | draft | edvance_k8_binom | 0 | {} | [] | nein |
| 25 | Gemischt · Sachkontext · Restfläche | draft | edvance_k8_binom | 0 | {} | [] | nein |
| 26 | Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)² | draft | edvance_k8_binom | 0 | {} | [] | nein |
| 27 | Gemischt · vereinfachen · (x + 4)² - x² - 16 | draft | edvance_k8_binom | 0 | {} | [] | nein |
| 28 | Gemischt · zwei Quadrate · (x + 3)² - (x - 3)² | draft | edvance_k8_binom | 0 | {} | [] | nein |

## Feld fuer Feld

| # | Aufgabe | Feld | Prod heute | Migration | Wirkung |
|---|---|---|---|---|---|
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | needs_image | — | false | setzt neu |
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | solution | — | A = g · h : 2 = 10 cm · 6 cm : 2 = 60 cm² : 2 = 30 cm². | setzt neu |
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | hints | [] | [{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?" | setzt neu |
| 1 | AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm | typical_errors | [] | [{"error":"Grundseite und Höhe werden addiert: 10 + 6 = 16.","socratic | setzt neu |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | needs_image | — | false | setzt neu |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | solution | — | A = g · h : 2 = 6 cm · 4 cm : 2 = 24 cm² : 2 = 12 cm². | setzt neu |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | hints | [] | [{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?" | setzt neu |
| 2 | AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm | typical_errors | [] | [{"error":"Grundseite und Höhe werden addiert: 6 + 4 = 10.","socratic_ | setzt neu |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | needs_image | — | false | setzt neu |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | solution | — | 1 cm² = 100 mm² (1 cm = 10 mm, also 10 · 10). 5 cm² = 5 · 100 mm² = 50 | setzt neu |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | hints | [] | [{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie  | setzt neu |
| 3 | AFB I · Flächeneinheiten · 5 cm² in mm² | typical_errors | [] | [{"error":"Die Einheit wird nicht umgerechnet: 5.","socratic_question" | setzt neu |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | needs_image | — | false | setzt neu |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | solution | — | 1 cm² = 100 mm² (1 cm = 10 mm, also 10 · 10). 8 cm² = 8 · 100 mm² = 80 | setzt neu |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | hints | [] | [{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie  | setzt neu |
| 4 | AFB I · Flächeneinheiten · 8 cm² in mm² | typical_errors | [] | [{"error":"Die Einheit wird nicht umgerechnet: 8.","socratic_question" | setzt neu |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | needs_image | — | false | setzt neu |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | solution | — | 1 m = 100 cm. 1,4 m = 1,4 · 100 cm = 140 cm. | setzt neu |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | hints | [] | [{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2," | setzt neu |
| 5 | AFB I · Gemischte Schreibweise · 1,4 m in cm | typical_errors | [] | [{"error":"Mit 10 statt mit 100 multipliziert: 14.","socratic_question | setzt neu |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | needs_image | — | false | setzt neu |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | solution | — | 1 m = 100 cm. 2,5 m = 2,5 · 100 cm = 250 cm. | setzt neu |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | hints | [] | [{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2," | setzt neu |
| 6 | AFB I · Gemischte Schreibweise · 2,5 m in cm | typical_errors | [] | [{"error":"Mit 10 statt mit 100 multipliziert: 25.","socratic_question | setzt neu |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | needs_image | — | false | setzt neu |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | solution | — | 4x + 3 = 3x + 11 / − 3x x + 3 = 11 / − 3 x = 8 Probe: 4 · 8 + 3 = 35 u | setzt neu |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | hints | [] | [{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichu | setzt neu |
| 7 | AFB I · Gleichung · 4x + 3 = 3x + 11 | typical_errors | [] | [{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Z | setzt neu |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | needs_image | — | false | setzt neu |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | solution | — | 6x + 2 = 5x + 8 / − 5x x + 2 = 8 / − 2 x = 6 Probe: 6 · 6 + 2 = 38 und | setzt neu |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | hints | [] | [{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichu | setzt neu |
| 8 | AFB I · Gleichung · 6x + 2 = 5x + 8 | typical_errors | [] | [{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Z | setzt neu |
| 9 | AFB I · Grundwert · 20 sind 10 % | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 9 | AFB I · Grundwert · 20 sind 10 % | needs_image | — | false | setzt neu |
| 9 | AFB I · Grundwert · 20 sind 10 % | solution | — | 10 % sind der zehnte Teil. Wenn 20 der zehnte Teil sind, ist die ganze | setzt neu |
| 9 | AFB I · Grundwert · 20 sind 10 % | hints | [] | [{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":" | setzt neu |
| 9 | AFB I · Grundwert · 20 sind 10 % | typical_errors | [] | [{"error":"Es wird 20 · 0,1 gerechnet statt geteilt: 2.","socratic_que | setzt neu |
| 10 | AFB I · Grundwert · 45 sind 10 % | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 10 | AFB I · Grundwert · 45 sind 10 % | needs_image | — | false | setzt neu |
| 10 | AFB I · Grundwert · 45 sind 10 % | solution | — | 10 % sind der zehnte Teil. Wenn 45 der zehnte Teil sind, ist die ganze | setzt neu |
| 10 | AFB I · Grundwert · 45 sind 10 % | hints | [] | [{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":" | setzt neu |
| 10 | AFB I · Grundwert · 45 sind 10 % | typical_errors | [] | [{"error":"Es wird 45 · 0,1 gerechnet statt geteilt: 4,5.","socratic_q | setzt neu |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | needs_image | — | false | setzt neu |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | solution | — | Maßstab 1:100 heißt: 1 cm auf dem Plan sind 100 cm in Wirklichkeit. 5  | setzt neu |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | hints | [] | [{"level":1,"text":"Was bedeutet der Maßstab 1:100 für 1 cm auf dem Pl | setzt neu |
| 11 | AFB I · Maßstab · 1:100, 5 cm auf dem Plan | typical_errors | [] | [{"error":"Mit 10 statt mit 100 multipliziert: 50 cm.","socratic_quest | setzt neu |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | needs_image | — | false | setzt neu |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | solution | — | Maßstab 1:200 heißt: 1 cm auf dem Plan sind 200 cm in Wirklichkeit. 3  | setzt neu |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | hints | [] | [{"level":1,"text":"Was bedeutet der Maßstab 1:200 für 1 cm auf dem Pl | setzt neu |
| 12 | AFB I · Maßstab · 1:200, 3 cm auf dem Plan | typical_errors | [] | [{"error":"Mit 20 statt mit 200 multipliziert: 60 cm.","socratic_quest | setzt neu |
| 13 | AFB I · Potenzen · 3^2 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 13 | AFB I · Potenzen · 3^2 | needs_image | — | false | setzt neu |
| 13 | AFB I · Potenzen · 3^2 | solution | — | 3² = 3 · 3 = 9. | setzt neu |
| 13 | AFB I · Potenzen · 3^2 | hints | [] | [{"level":1,"text":"Was bedeutet die kleine 2 oben an der 3?"},{"level | setzt neu |
| 13 | AFB I · Potenzen · 3^2 | typical_errors | [] | [{"error":"Basis mal Exponent gerechnet: 3 · 2 = 6.","socratic_questio | setzt neu |
| 14 | AFB I · Potenzen · 5^2 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 14 | AFB I · Potenzen · 5^2 | needs_image | — | false | setzt neu |
| 14 | AFB I · Potenzen · 5^2 | solution | — | 5² = 5 · 5 = 25. | setzt neu |
| 14 | AFB I · Potenzen · 5^2 | hints | [] | [{"level":1,"text":"Was bedeutet die kleine 2 oben an der 5?"},{"level | setzt neu |
| 14 | AFB I · Potenzen · 5^2 | typical_errors | [] | [{"error":"Basis mal Exponent gerechnet: 5 · 2 = 10.","socratic_questi | setzt neu |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | needs_image | — | false | setzt neu |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | solution | — | 10 % von 200 sind 20. Vergrößert: 200 + 20 = 220 (oder 200 · 1,1 = 220 | setzt neu |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | hints | [] | [{"level":1,"text":"Wie viel sind 10 % von 200?"},{"level":2,"text":"R | setzt neu |
| 15 | AFB I · Prozentuale Veränderung · 200 um 10 % größer | typical_errors | [] | [{"error":"Nur der Prozentwert wird angegeben: 20.","socratic_question | setzt neu |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | needs_image | — | false | setzt neu |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | solution | — | 10 % von 400 sind 40. Vergrößert: 400 + 40 = 440 (oder 400 · 1,1 = 440 | setzt neu |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | hints | [] | [{"level":1,"text":"Wie viel sind 10 % von 400?"},{"level":2,"text":"R | setzt neu |
| 16 | AFB I · Prozentuale Veränderung · 400 um 10 % größer | typical_errors | [] | [{"error":"Nur der Prozentwert wird angegeben: 40.","socratic_question | setzt neu |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | needs_image | — | false | setzt neu |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | solution | — | V = a · b · c = 2 cm · 3 cm · 5 cm = 30 cm³. | setzt neu |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | hints | [] | [{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"l | setzt neu |
| 17 | AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm | typical_errors | [] | [{"error":"Nur zwei Kanten werden multipliziert: 2 · 3 = 6.","socratic | setzt neu |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | cluster_id | — | 3156b22e-ad3b-46c8-8c76-4155176cc52a | setzt neu |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | needs_image | — | false | setzt neu |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | solution | — | V = a · b · c = 4 cm · 2 cm · 6 cm = 48 cm³. | setzt neu |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | hints | [] | [{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"l | setzt neu |
| 18 | AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm | typical_errors | [] | [{"error":"Nur zwei Kanten werden multipliziert: 4 · 2 = 8.","socratic | setzt neu |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | needs_image | — | false | setzt neu |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | solution | — | 1 dm³ = 1000 cm³ (1 dm = 10 cm, also 10 · 10 · 10). 2 dm³ = 2 · 1000 c | setzt neu |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | hints | [] | [{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie v | setzt neu |
| 19 | AFB I · Volumeneinheiten · 2 dm³ in cm³ | typical_errors | [] | [{"error":"Es wird wie bei Längen mit 10 multipliziert: 20.","socratic | setzt neu |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | needs_image | — | false | setzt neu |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | solution | — | 1 dm³ = 1000 cm³ (1 dm = 10 cm, also 10 · 10 · 10). 5 dm³ = 5 · 1000 c | setzt neu |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | hints | [] | [{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie v | setzt neu |
| 20 | AFB I · Volumeneinheiten · 5 dm³ in cm³ | typical_errors | [] | [{"error":"Es wird wie bei Längen mit 10 multipliziert: 50.","socratic | setzt neu |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | needs_image | — | false | setzt neu |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | solution | — | Punktrechnung vor Strichrechnung: 4 · 2 = 8. -6 + 8 = 2. | setzt neu |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | hints | [] | [{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{" | setzt neu |
| 21 | AFB I · Vorrang · -6 + 4 · 2 | typical_errors | [] | [{"error":"Das Minuszeichen vor der 6 wird übersehen: 6 + 8 = 14.","so | setzt neu |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | cluster_id | — | e7108c9a-d19e-4021-8499-55b4f3d5d70c | setzt neu |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | needs_image | — | false | setzt neu |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | solution | — | Punktrechnung vor Strichrechnung: 5 · 3 = 15. -8 + 15 = 7. | setzt neu |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | hints | [] | [{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{" | setzt neu |
| 22 | AFB I · Vorrang · -8 + 5 · 3 | typical_errors | [] | [{"error":"Das Minuszeichen vor der 8 wird übersehen: 8 + 15 = 23.","s | setzt neu |
| 23 | Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4) | est_duration_sec | — | 90 | setzt neu |
| 23 | Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4) | solution | — | (3x - 2)² = 9x² - 12x + 4 (zweite binomische Formel) (x + 4)(x - 4) =  | setzt neu |
| 23 | Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4) | hints | [] | [{"level":1,"text":"Welche binomischen Formeln stecken in den beiden T | setzt neu |
| 23 | Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4) | typical_errors | [] | [{"error":"Das Minus vor der Klammer wird nicht auf -16 angewendet: 8x | setzt neu |
| 24 | Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2) | est_duration_sec | — | 60 | setzt neu |
| 24 | Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2) | solution | — | (x + 5)² = x² + 10x + 25 (x + 2)(x - 2) = x² - 4 x² + 10x + 25 - (x² - | setzt neu |
| 24 | Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2) | hints | [] | [{"level":1,"text":"Welche binomischen Formeln stecken in den beiden T | setzt neu |
| 24 | Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2) | typical_errors | [] | [{"error":"Das Minus vor der Klammer wird nicht auf -4 angewendet: 10x | setzt neu |
| 25 | Gemischt · Sachkontext · Restfläche | est_duration_sec | — | 120 | setzt neu |
| 25 | Gemischt · Sachkontext · Restfläche | solution | — | Restfläche = Grundstück − Beet = (x + 3)² - (x - 1)² = x² + 6x + 9 - ( | setzt neu |
| 25 | Gemischt · Sachkontext · Restfläche | hints | [] | [{"level":1,"text":"Wie berechnest du die Restfläche aus der Fläche de | setzt neu |
| 25 | Gemischt · Sachkontext · Restfläche | typical_errors | [] | [{"error":"Beide Quadrate werden gliedweise gebildet: 9 − 1 = 8.","soc | setzt neu |
| 26 | Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)² | est_duration_sec | — | 60 | setzt neu |
| 26 | Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)² | solution | — | (x + 6)(x - 6) = x² - 36 (x + 2)² = x² + 4x + 4 x² - 36 + x² + 4x + 4  | setzt neu |
| 26 | Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)² | hints | [] | [{"level":1,"text":"Welche binomischen Formeln stecken in den beiden T | setzt neu |
| 26 | Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)² | typical_errors | [] | [{"error":"Das Vorzeichen von 36 wird falsch übernommen: 2x² + 4x + 40 | setzt neu |
| 27 | Gemischt · vereinfachen · (x + 4)² - x² - 16 | est_duration_sec | — | 60 | setzt neu |
| 27 | Gemischt · vereinfachen · (x + 4)² - x² - 16 | solution | — | (x + 4)² = x² + 8x + 16 x² + 8x + 16 - x² - 16 = 8x. | setzt neu |
| 27 | Gemischt · vereinfachen · (x + 4)² - x² - 16 | hints | [] | [{"level":1,"text":"Multipliziere (x + 4)² zuerst mit der ersten binom | setzt neu |
| 27 | Gemischt · vereinfachen · (x + 4)² - x² - 16 | typical_errors | [] | [{"error":"Das Quadrat wird gliedweise gebildet, der Mischterm fehlt:  | setzt neu |
| 28 | Gemischt · zwei Quadrate · (x + 3)² - (x - 3)² | est_duration_sec | — | 60 | setzt neu |
| 28 | Gemischt · zwei Quadrate · (x + 3)² - (x - 3)² | solution | — | (x + 3)² = x² + 6x + 9 (x - 3)² = x² - 6x + 9 x² + 6x + 9 - (x² - 6x + | setzt neu |
| 28 | Gemischt · zwei Quadrate · (x + 3)² - (x - 3)² | hints | [] | [{"level":1,"text":"Welche binomischen Formeln stecken in den beiden T | setzt neu |
| 28 | Gemischt · zwei Quadrate · (x + 3)² - (x - 3)² | typical_errors | [] | [{"error":"Die Quadrate werden gliedweise gebildet: 9 − 9 = 0.","socra | setzt neu |
