# Verifikation k8-vorlauf

Aufgaben: 12 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| hints | 0 | 0 | 0 | 12 |
| afb | 12 | 0 | 0 | 0 |
| est_duration_sec | 12 | 0 | 0 | 0 |
| curriculum_grade | 12 | 0 | 0 | 0 |
| cluster_id | 12 | 0 | 0 | 0 |
| competency_content | 12 | 0 | 0 | 0 |
| competency_process | 12 | 0 | 0 | 0 |
| needs_image | 12 | 0 | 0 | 0 |
| parts[].afb | 12 | 0 | 0 | 0 |
| parts[].competency_content | 12 | 0 | 0 | 0 |
| correct_answers[].antwort | 12 | 0 | 0 | 0 |
| solution | 12 | 0 | 0 | 0 |
| typical_errors | 12 | 0 | 0 | 0 |
| correct_answers | 6 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 12 | 12 | 0 | 0 |
| tasks.est_duration_sec | 12 | 12 | 0 | 0 |
| tasks.curriculum_grade | 12 | 12 | 0 | 0 |
| tasks.cluster_id | 12 | 12 | 0 | 0 |
| tasks.needs_image | 12 | 12 | 0 | 0 |
| task_solutions.solution | 12 | 12 | 0 | 0 |
| task_solutions.hints | 12 | 0 | 12 | 0 |
| task_solutions.typical_errors | 12 | 12 | 0 | 0 |
| parts[].afb | 12 | 12 | 0 | 0 |
| parts[].competency_content | 12 | 12 | 0 | 0 |
| parts[].antwort | 12 | 12 | 0 | 0 |
| tasks.competency_content | 6 | 6 | 0 | 0 |
| tasks.competency_process | 6 | 6 | 0 | 0 |
| task_solutions.correct_answers | 6 | 6 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Koordinaten · Punkt ablesen · 1. Quadrant Teil 1: 4 = 4 (soll 4)
- ok  #1 Koordinaten · Punkt ablesen · 1. Quadrant Teil 2: 3 = 3 (soll 3)
- ok  #2 Koordinaten · Punkt ablesen · 2. Quadrant Teil 1: -4 = -4 (soll -4)
- ok  #2 Koordinaten · Punkt ablesen · 2. Quadrant Teil 2: 2 = 2 (soll 2)
- ok  #3 Koordinaten · Punkt ablesen · 3. Quadrant Teil 1: -2 = -2 (soll -2)
- ok  #3 Koordinaten · Punkt ablesen · 3. Quadrant Teil 2: -5 = -5 (soll -5)
- ok  #4 Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit Teil 1: 3 = 3 (soll 3)
- ok  #4 Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit Teil 2: -2-1/2 = -5/2 (soll -5/2)
- ok  #5 Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks Teil 1: -4 = -4 (soll -4)
- ok  #5 Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks Teil 2: 2 = 2 (soll 2)
- ok  #6 Koordinaten · Sachkontext · Fahrt auf der Seekarte Teil 1: -2+6 = 4 (soll 4)
- ok  #6 Koordinaten · Sachkontext · Fahrt auf der Seekarte Teil 2: 1-4 = -3 (soll -3)
- ok  #7 Einsetzen · negativer Wert · 2 · x + 5: 2·(-4)+5 = -3 (soll -3)
- ok  #8 Einsetzen · negativer Wert und Vorrang · 5 - 3 · x: 5-3·(-2) = 11 (soll 11)
- ok  #9 Einsetzen · Potenz im Term · 3 · x²: 3·(-2)^2 = 12 (soll 12)
- ok  #10 Einsetzen · Potenz und Produkt · x² - 2 · x: (-3)^2-2·(-3) = 15 (soll 15)
- ok  #11 Einsetzen · Formel mit zwei Variablen · Fläche des Dreiecks: 7·5:2 = 35/2 (soll 35/2)
- ok  #12 Einsetzen · Sachformel · Grad Celsius in Grad Fahrenheit: 1.8·(-10)+32 = 14 (soll 14)

## Blind-Abgleich (docs/prefill/k8-vorlauf-blind.json)

- ok  #1 Koordinaten · Punkt ablesen · 1. Quadrant Teil 1: Loeser 4 · gespeichert ["4","+4"]
- ok  #1 Koordinaten · Punkt ablesen · 1. Quadrant Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #2 Koordinaten · Punkt ablesen · 2. Quadrant Teil 1: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #2 Koordinaten · Punkt ablesen · 2. Quadrant Teil 2: Loeser 2 · gespeichert ["2","+2"]
- ok  #3 Koordinaten · Punkt ablesen · 3. Quadrant Teil 1: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #3 Koordinaten · Punkt ablesen · 3. Quadrant Teil 2: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #4 Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit Teil 1: Loeser 3 · gespeichert ["3","+3"]
- ok  #4 Koordinaten · Punkt ablesen · 4. Quadrant, halbe Einheit Teil 2: Loeser -2.5 · gespeichert ["-2,5","-2.5","−2,5","- 2,5"]
- ok  #5 Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks Teil 1: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #5 Koordinaten · Rückrichtung · vierter Eckpunkt eines Rechtecks Teil 2: Loeser 2 · gespeichert ["2","+2"]
- ok  #6 Koordinaten · Sachkontext · Fahrt auf der Seekarte Teil 1: Loeser 4 · gespeichert ["4","+4"]
- ok  #6 Koordinaten · Sachkontext · Fahrt auf der Seekarte Teil 2: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #7 Einsetzen · negativer Wert · 2 · x + 5: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #8 Einsetzen · negativer Wert und Vorrang · 5 - 3 · x: Loeser 11 · gespeichert ["11","+11"]
- ok  #9 Einsetzen · Potenz im Term · 3 · x²: Loeser 12 · gespeichert ["12","+12"]
- ok  #10 Einsetzen · Potenz und Produkt · x² - 2 · x: Loeser 15 · gespeichert ["15","+15"]
- ok  #11 Einsetzen · Formel mit zwei Variablen · Fläche des Dreiecks: Loeser 17.5 · gespeichert ["17,5","17.5"]
- ok  #12 Einsetzen · Sachformel · Grad Celsius in Grad Fahrenheit: Loeser 14 · gespeichert ["14","+14"]
