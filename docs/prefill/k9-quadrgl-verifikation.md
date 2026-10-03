# Verifikation k9-quadrgl

Aufgaben: 24 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| hints | 0 | 0 | 0 | 24 |
| afb | 24 | 0 | 0 | 0 |
| est_duration_sec | 24 | 0 | 0 | 0 |
| curriculum_grade | 24 | 0 | 0 | 0 |
| cluster_id | 24 | 0 | 0 | 0 |
| competency_content | 24 | 0 | 0 | 0 |
| competency_process | 24 | 0 | 0 | 0 |
| needs_image | 24 | 0 | 0 | 0 |
| parts[].afb | 24 | 0 | 0 | 0 |
| parts[].competency_content | 24 | 0 | 0 | 0 |
| correct_answers[].antwort | 24 | 0 | 0 | 0 |
| solution | 24 | 0 | 0 | 0 |
| typical_errors | 24 | 0 | 0 | 0 |
| correct_answers | 12 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 24 | 24 | 0 | 0 |
| tasks.est_duration_sec | 24 | 24 | 0 | 0 |
| tasks.curriculum_grade | 24 | 24 | 0 | 0 |
| tasks.cluster_id | 24 | 24 | 0 | 0 |
| tasks.needs_image | 24 | 24 | 0 | 0 |
| task_solutions.solution | 24 | 24 | 0 | 0 |
| task_solutions.hints | 24 | 0 | 24 | 0 |
| task_solutions.typical_errors | 24 | 24 | 0 | 0 |
| parts[].afb | 24 | 24 | 0 | 0 |
| parts[].competency_content | 24 | 24 | 0 | 0 |
| parts[].antwort | 24 | 24 | 0 | 0 |
| tasks.competency_content | 12 | 12 | 0 | 0 |
| tasks.competency_process | 12 | 12 | 0 | 0 |
| task_solutions.correct_answers | 12 | 12 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Wurzelziehen · x² = 49 Teil 1: -(7) = -7 (soll -7)
- ok  #1 Wurzelziehen · x² = 49 Teil 1: (7) = 7 (soll 7)
- ok  #1 Wurzelziehen · x² = 49 Teil 1: -49 = -49 (soll -49)
- ok  #1 Wurzelziehen · x² = 49 Teil 2: (7) = 7 (soll 7)
- ok  #1 Wurzelziehen · x² = 49 Teil 2: 49 = 49 (soll 49)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 1: -(3) = -3 (soll -3)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 1: (3) = 3 (soll 3)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 1: -(6) = -6 (soll -6)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 1: -18/2 = -9 (soll -9)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 2: (3) = 3 (soll 3)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 2: (6) = 6 (soll 6)
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 2: 18/2 = 9 (soll 9)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 1: 2-(5) = -3 (soll -3)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 1: -2-(5) = -7 (soll -7)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 1: 2+(5) = 7 (soll 7)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 1: 2-25 = -23 (soll -23)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 2: 2+(5) = 7 (soll 7)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 2: -2+(5) = 3 (soll 3)
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 2: 2+25 = 27 (soll 27)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 1: round(-(44721359549995793928183473374625524708812/10000000000000000000000000000000000000000),2) = -447/100 (soll -447/100)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 1: round((44721359549995793928183473374625524708812/10000000000000000000000000000000000000000),2) = 447/100 (soll 447/100)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 1: round(-(77459666924148337703585307995647992216658/10000000000000000000000000000000000000000),2) = -31/4 (soll -31/4)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 1: round(-60/3,2) = -20 (soll -20)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 2: round((44721359549995793928183473374625524708812/10000000000000000000000000000000000000000),2) = 447/100 (soll 447/100)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 2: round((77459666924148337703585307995647992216658/10000000000000000000000000000000000000000),2) = 31/4 (soll 31/4)
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 2: round(60/3,2) = 20 (soll 20)
- ok  #5 Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²: (7) = 7 (soll 7)
- ok  #5 Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²: round((98994949366116653416118210694678865499877/10000000000000000000000000000000000000000),2) = 99/10 (soll 99/10)
- ok  #5 Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²: 98/2 = 49 (soll 49)
- ok  #5 Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²: (14) = 14 (soll 14)
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: (11)-3 = 8 (soll 8)
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: (11)+3 = 14 (soll 14)
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: (11) = 11 (soll 11)
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: round((105830052442583623620064630145570417028410/10000000000000000000000000000000000000000),2) = 529/50 (soll 529/50)
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: 121-3 = 118 (soll 118)
- ok  #7 Ausklammern · x² − 5x = 0 Teil 1: 0 = 0 (soll 0)
- ok  #7 Ausklammern · x² − 5x = 0 Teil 1: 5 = 5 (soll 5)
- ok  #7 Ausklammern · x² − 5x = 0 Teil 1: -5 = -5 (soll -5)
- ok  #7 Ausklammern · x² − 5x = 0 Teil 2: 5 = 5 (soll 5)
- ok  #7 Ausklammern · x² − 5x = 0 Teil 2: 0 = 0 (soll 0)
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 1: -5 = -5 (soll -5)
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 1: -3 = -3 (soll -3)
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 2: 3 = 3 (soll 3)
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 2: 5 = 5 (soll 5)
- ok  #9 Ausklammern · 3x² = 12x Teil 1: 0 = 0 (soll 0)
- ok  #9 Ausklammern · 3x² = 12x Teil 1: 12/3 = 4 (soll 4)
- ok  #9 Ausklammern · 3x² = 12x Teil 2: 12/3 = 4 (soll 4)
- ok  #9 Ausklammern · 3x² = 12x Teil 2: 12 = 12 (soll 12)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 1: 0 = 0 (soll 0)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 1: 7/2 = 7/2 (soll 7/2)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 1: -7/2 = -7/2 (soll -7/2)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 2: 7/2 = 7/2 (soll 7/2)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 2: 7 = 7 (soll 7)
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 2: 0 = 0 (soll 0)
- ok  #11 Nullprodukt · Ball landet wieder, h = 20t − 5t²: 20/5 = 4 (soll 4)
- ok  #11 Nullprodukt · Ball landet wieder, h = 20t − 5t²: 20 = 20 (soll 20)
- ok  #11 Nullprodukt · Ball landet wieder, h = 20t − 5t²: -20/5 = -4 (soll -4)
- ok  #12 Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3: -2*3 = -6 (soll -6)
- ok  #12 Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3: 2*3 = 6 (soll 6)
- ok  #12 Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3: -2*3^2 = -18 (soll -18)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 1: -(2)/2 - (4) = -5 (soll -5)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 1: (2)/2 - (4) = -3 (soll -3)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 1: -(2)/2 - ((2/2)^2+15) = -17 (soll -17)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 2: -(2)/2 + (4) = 3 (soll 3)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 2: (2)/2 + (4) = 5 (soll 5)
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 2: -(2)/2 + ((2/2)^2+15) = 15 (soll 15)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 1: -(-6)/2 - (2) = 1 (soll 1)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 1: (-6)/2 - (2) = -5 (soll -5)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 1: -(-6)/2 - ((6/2)^2-5) = -1 (soll -1)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 2: -(-6)/2 + (2) = 5 (soll 5)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 2: (-6)/2 + (2) = -1 (soll -1)
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 2: -(-6)/2 + ((6/2)^2-5) = 7 (soll 7)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 1: -(-2)/2 - (2) = -1 (soll -1)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 1: (-2)/2 - (2) = -3 (soll -3)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 1: round(-(-4)/2 - (31622776601683793319988935444327185337195/10000000000000000000000000000000000000000),2) = -29/25 (soll -29/25)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 2: -(-2)/2 + (2) = 3 (soll 3)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 2: (-2)/2 + (2) = 1 (soll 1)
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 2: round(-(-4)/2 + (31622776601683793319988935444327185337195/10000000000000000000000000000000000000000),2) = 129/25 (soll 129/25)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 1: round(-(4)/2 - (22360679774997896964091736687312762354406/10000000000000000000000000000000000000000),2) = -106/25 (soll -106/25)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 1: round((4)/2 - (22360679774997896964091736687312762354406/10000000000000000000000000000000000000000),2) = -6/25 (soll -6/25)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 1: round(-(4)/2 - ((4/2)^2+1),2) = -7 (soll -7)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 2: round(-(4)/2 + (22360679774997896964091736687312762354406/10000000000000000000000000000000000000000),2) = 6/25 (soll 6/25)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 2: round((4)/2 + (22360679774997896964091736687312762354406/10000000000000000000000000000000000000000),2) = 106/25 (soll 106/25)
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 2: round(-(4)/2 + ((4/2)^2+1),2) = 3 (soll 3)
- ok  #17 p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²: -(4)/2 + (8) + 4 = 10 (soll 10)
- ok  #17 p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²: (4)/2 + (8) + 4 = 14 (soll 14)
- ok  #17 p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²: -(4)/2 + (8) = 6 (soll 6)
- ok  #17 p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²: -(4)/2 + ((4/2)^2+60) + 4 = 66 (soll 66)
- ok  #18 p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²: -(35/2)/2 + (45/4) = 5/2 (soll 5/2)
- ok  #18 p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²: (35/2)/2 + (45/4) = 20 (soll 20)
- ok  #18 p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²: round(-(70)/2 + (377491721763537484861834240347305852911109/10000000000000000000000000000000000000000),2) = 11/4 (soll 11/4)
- ok  #19 Anzahl der Lösungen · x² + 4x + 5 = 0: 0 = 0 (soll 0)
- ok  #19 Anzahl der Lösungen · x² + 4x + 5 = 0: 2 = 2 (soll 2)
- ok  #20 Diskriminante · x² − 6x + 8 = 0: (-6/2)^2-8 = 1 (soll 1)
- ok  #20 Diskriminante · x² − 6x + 8 = 0: 0-(6/2)^2-8 = -17 (soll -17)
- ok  #20 Diskriminante · x² − 6x + 8 = 0: 6^2-8 = 28 (soll 28)
- ok  #21 Diskriminante · x² − 5x − 6 = 0: (-5/2)^2+6 = 49/4 (soll 49/4)
- ok  #21 Diskriminante · x² − 5x − 6 = 0: 0-(5/2)^2+6 = -1/4 (soll -1/4)
- ok  #21 Diskriminante · x² − 5x − 6 = 0: 5^2+6 = 31 (soll 31)
- ok  #22 Anzahl der Lösungen · 2x² − 8x + 8 = 0: 1 = 1 (soll 1)
- ok  #22 Anzahl der Lösungen · 2x² − 8x + 8 = 0: 2 = 2 (soll 2)
- ok  #22 Anzahl der Lösungen · 2x² − 8x + 8 = 0: 0 = 0 (soll 0)
- ok  #23 Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²: 1 = 1 (soll 1)
- ok  #23 Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²: 0 = 0 (soll 0)
- ok  #23 Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²: 2 = 2 (soll 2)
- ok  #24 Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung: (6/2)^2 = 9 (soll 9)
- ok  #24 Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung: 0-(6/2)^2 = -9 (soll -9)
- ok  #24 Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung: 6^2 = 36 (soll 36)

## Blind-Abgleich (docs/prefill/k9-quadrgl-blind.json)

- ok  #1 Wurzelziehen · x² = 49 Teil 1: Loeser -7 · gespeichert ["-7","−7","- 7"]
- ok  #1 Wurzelziehen · x² = 49 Teil 2: Loeser 7 · gespeichert ["7","+7"]
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 1: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #2 Wurzelziehen · 2x² − 18 = 0 Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 1: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #3 Wurzelziehen · (x − 2)² = 25 Teil 2: Loeser 7 · gespeichert ["7","+7"]
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 1: Loeser -4.47 · gespeichert ["-4,47","−4,47","- 4,47","-4.47","−4.47","- 4.47"]
- ok  #4 Wurzelziehen · 3x² = 60, gerundet Teil 2: Loeser 4.47 · gespeichert ["4,47","+4,47","4.47","+4.47"]
- ok  #5 Wurzelziehen · Rechteck doppelt so lang wie breit, 98 m²: Loeser 7 · gespeichert ["7","7 m","7m"]
- ok  #6 Wurzelziehen · Quadratseite um 3 cm verlängert, 121 cm²: Loeser 8 · gespeichert ["8","8 cm","8cm"]
- ok  #7 Ausklammern · x² − 5x = 0 Teil 1: Loeser 0 · gespeichert ["0"]
- ok  #7 Ausklammern · x² − 5x = 0 Teil 2: Loeser 5 · gespeichert ["5","+5"]
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 1: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #8 Nullprodukt · (x − 3)(x + 5) = 0 Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #9 Ausklammern · 3x² = 12x Teil 1: Loeser 0 · gespeichert ["0"]
- ok  #9 Ausklammern · 3x² = 12x Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 1: Loeser 0 · gespeichert ["0"]
- ok  #10 Nullprodukt · x(2x − 7) = 0 Teil 2: Loeser 3.5 · gespeichert ["3,5","+3,5","3.5","+3.5"]
- ok  #11 Nullprodukt · Ball landet wieder, h = 20t − 5t²: Loeser 4 · gespeichert ["4","4 s","4s"]
- ok  #12 Nullprodukt rückwärts · 2x² + bx = 0 mit Lösung 3: Loeser -6 · gespeichert ["-6","−6","- 6"]
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 1: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #13 p-q-Formel · x² + 2x − 15 = 0 Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 1: Loeser 1 · gespeichert ["1","+1"]
- ok  #14 p-q-Formel · x² − 6x + 5 = 0 Teil 2: Loeser 5 · gespeichert ["5","+5"]
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 1: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #15 p-q-Formel · 2x² − 4x − 6 = 0 Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 1: Loeser -4.24 · gespeichert ["-4,24","−4,24","- 4,24","-4.24","−4.24","- 4.24"]
- ok  #16 p-q-Formel · x² + 4x − 1 = 0, gerundet Teil 2: Loeser 0.24 · gespeichert ["0,24","+0,24","0.24","+0.24"]
- ok  #17 p-q-Formel · Rechteck 4 cm länger als breit, 60 cm²: Loeser 10 · gespeichert ["10","10 cm","10cm"]
- ok  #18 p-q-Formel · Weg um ein Beet 20 m × 15 m, 500 m²: Loeser 2.5 · gespeichert ["2,5","2.5","2,5 m","2,5m"]
- ok  #19 Anzahl der Lösungen · x² + 4x + 5 = 0: Loeser 0 · gespeichert ["0"]
- ok  #20 Diskriminante · x² − 6x + 8 = 0: Loeser 1 · gespeichert ["1","+1"]
- ok  #21 Diskriminante · x² − 5x − 6 = 0: Loeser 12.25 · gespeichert ["12,25","+12,25","12.25","+12.25"]
- ok  #22 Anzahl der Lösungen · 2x² − 8x + 8 = 0: Loeser 1 · gespeichert ["1","+1"]
- ok  #23 Anzahl der Lösungen · Zaun 20 m, Fläche 25 m²: Loeser 1 · gespeichert ["1","+1"]
- ok  #24 Diskriminante rückwärts · x² + 6x + q = 0 mit genau einer Lösung: Loeser 9 · gespeichert ["9","+9"]
