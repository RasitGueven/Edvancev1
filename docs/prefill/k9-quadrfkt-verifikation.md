# Verifikation k9-quadrfkt

Aufgaben: 30 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| hints | 0 | 0 | 0 | 30 |
| afb | 30 | 0 | 0 | 0 |
| est_duration_sec | 30 | 0 | 0 | 0 |
| curriculum_grade | 30 | 0 | 0 | 0 |
| cluster_id | 30 | 0 | 0 | 0 |
| competency_content | 30 | 0 | 0 | 0 |
| competency_process | 30 | 0 | 0 | 0 |
| needs_image | 30 | 0 | 0 | 0 |
| correct_answers | 16 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| parts[].afb | 28 | 0 | 0 | 0 |
| parts[].competency_content | 28 | 0 | 0 | 0 |
| correct_answers[].antwort | 28 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 30 | 30 | 0 | 0 |
| tasks.est_duration_sec | 30 | 30 | 0 | 0 |
| tasks.curriculum_grade | 30 | 30 | 0 | 0 |
| tasks.cluster_id | 30 | 30 | 0 | 0 |
| tasks.needs_image | 30 | 30 | 0 | 0 |
| task_solutions.solution | 30 | 30 | 0 | 0 |
| task_solutions.hints | 30 | 0 | 30 | 0 |
| task_solutions.typical_errors | 30 | 30 | 0 | 0 |
| tasks.competency_content | 16 | 16 | 0 | 0 |
| tasks.competency_process | 16 | 16 | 0 | 0 |
| task_solutions.correct_answers | 16 | 16 | 0 | 0 |
| parts[].afb | 28 | 28 | 0 | 0 |
| parts[].competency_content | 28 | 28 | 0 | 0 |
| parts[].antwort | 28 | 28 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3: 2*(4-1)^2+3 = 21 (soll 21)
- ok  #1 Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3: (2*(4-1))^2+3 = 39 (soll 39)
- ok  #1 Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3: 2*(2*(4-1))+3 = 15 (soll 15)
- ok  #2 Verschiebung nach oben · aus der Abbildung: 3 = 3 (soll 3)
- ok  #2 Verschiebung nach oben · aus der Abbildung: 2 = 2 (soll 2)
- ok  #3 Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5: 3*(-2-1)^2-5 = 22 (soll 22)
- ok  #3 Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5: 3*(0-9)-5 = -32 (soll -32)
- ok  #3 Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5: (3*(-2-1))^2-5 = 76 (soll 76)
- ok  #4 Streckfaktor · Parabel durch P(5|35): (35-3)/(5-1)^2 = 2 (soll 2)
- ok  #4 Streckfaktor · Parabel durch P(5|35): (35-3)/(2*(5-1)) = 4 (soll 4)
- ok  #4 Streckfaktor · Parabel durch P(5|35): (35+3)/(5-1)^2 = 19/8 (soll 19/8)
- ok  #5 Funktionswert · Wasserstrahl 5 m von der Düse: -0.5*(5-2)^2+5 = 1/2 (soll 1/2)
- ok  #5 Funktionswert · Wasserstrahl 5 m von der Düse: (-0.5*(5-2))^2+5 = 29/4 (soll 29/4)
- ok  #5 Funktionswert · Wasserstrahl 5 m von der Düse: -0.5*(2*(5-2))+5 = 2 (soll 2)
- ok  #6 Streckfaktor · aus Scheitel und Punkt in der Abbildung: (5-(-3))/(5-1)^2 = 1/2 (soll 1/2)
- ok  #6 Streckfaktor · aus Scheitel und Punkt in der Abbildung: (5-(-3))/(2*(5-1)) = 1 (soll 1)
- ok  #6 Streckfaktor · aus Scheitel und Punkt in der Abbildung: (5-1)^2/(5-(-3)) = 2 (soll 2)
- ok  #6 Streckfaktor · aus Scheitel und Punkt in der Abbildung: (5-3)/(5-1)^2 = 1/8 (soll 1/8)
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 1: 3 = 3 (soll 3)
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 1: -3 = -3 (soll -3)
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 2: 1 = 1 (soll 1)
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 2: 3 = 3 (soll 3)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 1: -2 = -2 (soll -2)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 1: -3 = -3 (soll -3)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 1: 2 = 2 (soll 2)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 2: -3 = -3 (soll -3)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 2: -2 = -2 (soll -2)
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 2: 3 = 3 (soll 3)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 1: -4 = -4 (soll -4)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 1: 4 = 4 (soll 4)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 1: -5 = -5 (soll -5)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 2: -5 = -5 (soll -5)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 2: -4 = -4 (soll -4)
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 2: 5 = 5 (soll 5)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 1: 6 = 6 (soll 6)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 1: -6 = -6 (soll -6)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 1: 4 = 4 (soll 4)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 2: 4 = 4 (soll 4)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 2: 6 = 6 (soll 6)
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 2: 4-2 = 2 (soll 2)
- ok  #11 Scheitelpunkt · Brückenbogen Teil 1: 25 = 25 (soll 25)
- ok  #11 Scheitelpunkt · Brückenbogen Teil 1: -25 = -25 (soll -25)
- ok  #11 Scheitelpunkt · Brückenbogen Teil 1: 12.5 = 25/2 (soll 25/2)
- ok  #11 Scheitelpunkt · Brückenbogen Teil 2: 12.5 = 25/2 (soll 25/2)
- ok  #11 Scheitelpunkt · Brückenbogen Teil 2: 25 = 25 (soll 25)
- ok  #12 Rückrichtung · c aus dem Scheitel S(2|−1): (-2)^2-1 = 3 (soll 3)
- ok  #12 Rückrichtung · c aus dem Scheitel S(2|−1): 0-2^2-1 = -5 (soll -5)
- ok  #12 Rückrichtung · c aus dem Scheitel S(2|−1): 2^2+1 = 5 (soll 5)
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 1: 6/2 = 3 (soll 3)
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 1: -6/2 = -3 (soll -3)
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 1: 6 = 6 (soll 6)
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 2: 5-3^2 = -4 (soll -4)
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 2: 5+3^2 = 14 (soll 14)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 1: -4/2 = -2 (soll -2)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 1: 4/2 = 2 (soll 2)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 1: -4 = -4 (soll -4)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 2: 1-2^2 = -3 (soll -3)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 2: 1+2^2 = 5 (soll 5)
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 2: 1-4^2 = -15 (soll -15)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 1: 4/2 = 2 (soll 2)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 1: -4/2 = -2 (soll -2)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 1: 4 = 4 (soll 4)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 2: 2*(0-2^2)+3 = -5 (soll -5)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 2: 2*2^2+3 = 11 (soll 11)
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 2: 3-2^2 = -1 (soll -1)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 1: 5/2 = 5/2 (soll 5/2)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 1: -5/2 = -5/2 (soll -5/2)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 1: 5 = 5 (soll 5)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 2: 2-(5/2)^2 = -17/4 (soll -17/4)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 2: 2+(5/2)^2 = 33/4 (soll 33/4)
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 2: 2-5^2 = -23 (soll -23)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 1: 20/2 = 10 (soll 10)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 1: -20/2 = -10 (soll -10)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 1: 20 = 20 (soll 20)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 2: -0.1*(0-10^2)+1.5 = 23/2 (soll 23/2)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 2: -0.1*10^2+1.5 = -17/2 (soll -17/2)
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 2: -0.1*(0-20^2)+1.5 = 83/2 (soll 83/2)
- ok  #18 Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle: 7-3^2 = -2 (soll -2)
- ok  #18 Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle: 7+3^2 = 16 (soll 16)
- ok  #18 Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle: -6 = -6 (soll -6)
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 1: 1-(3) = -2 (soll -2)
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 1: -1-(3) = -4 (soll -4)
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 2: 1+(3) = 4 (soll 4)
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 2: -1+(3) = 2 (soll 2)
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 1: 1-(2) = -1 (soll -1)
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 1: -1-(2) = -3 (soll -3)
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 2: 1+(2) = 3 (soll 3)
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 2: -1+(2) = 1 (soll 1)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 1: -5 = -5 (soll -5)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 1: -1 = -1 (soll -1)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 1: 5 = 5 (soll 5)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 2: 3 = 3 (soll 3)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 2: -3 = -3 (soll -3)
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 2: 7.5 = 15/2 (soll 15/2)
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 1: -1-(2) = -3 (soll -3)
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 1: 1-(2) = -1 (soll -1)
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 2: -1+(2) = 1 (soll 1)
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 2: 1+(2) = 3 (soll 3)
- ok  #23 Nullstelle · wann der Ball den Boden trifft: round(1.2+(339116499156263406953227816331298455259787/250000000000000000000000000000000000000000),2) = 64/25 (soll 64/25)
- ok  #23 Nullstelle · wann der Ball den Boden trifft: round(-1.2+(339116499156263406953227816331298455259787/250000000000000000000000000000000000000000),2) = 4/25 (soll 4/25)
- ok  #23 Nullstelle · wann der Ball den Boden trifft: round(1.2+(254950975679639241501411205451139099478188/250000000000000000000000000000000000000000),2) = 111/50 (soll 111/50)
- ok  #24 Rückrichtung · Scheitelhöhe aus den Nullstellen: (2+1)*(2-5) = -9 (soll -9)
- ok  #24 Rückrichtung · Scheitelhöhe aus den Nullstellen: (5-1)/2 = 2 (soll 2)
- ok  #24 Rückrichtung · Scheitelhöhe aus den Nullstellen: (4+1)*(4-5) = -5 (soll -5)
- ok  #25 Größter Funktionswert · f(x) = −(x − 4)² + 7: 7 = 7 (soll 7)
- ok  #25 Größter Funktionswert · f(x) = −(x − 4)² + 7: 4 = 4 (soll 4)
- ok  #25 Größter Funktionswert · f(x) = −(x − 4)² + 7: -7 = -7 (soll -7)
- ok  #26 Kleinster Funktionswert · f(x) = x² − 8x + 10: 10-4^2 = -6 (soll -6)
- ok  #26 Kleinster Funktionswert · f(x) = x² − 8x + 10: 10+4^2 = 26 (soll 26)
- ok  #26 Kleinster Funktionswert · f(x) = x² − 8x + 10: 4 = 4 (soll 4)
- ok  #27 Größter Funktionswert · f(x) = −2x² + 12x − 5: -2*(0-3^2)-5 = 13 (soll 13)
- ok  #27 Größter Funktionswert · f(x) = −2x² + 12x − 5: -2*3^2-5 = -23 (soll -23)
- ok  #27 Größter Funktionswert · f(x) = −2x² + 12x − 5: 3 = 3 (soll 3)
- ok  #27 Größter Funktionswert · f(x) = −2x² + 12x − 5: 3^2-5 = 4 (soll 4)
- ok  #28 Zahlenrätsel · Summe 20, größtes Produkt: 10*(20-10) = 100 (soll 100)
- ok  #28 Zahlenrätsel · Summe 20, größtes Produkt: 10 = 10 (soll 10)
- ok  #28 Zahlenrätsel · Summe 20, größtes Produkt: 0-10^2 = -100 (soll -100)
- ok  #29 Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1: -5*(0-2^2)+1 = 21 (soll 21)
- ok  #29 Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1: 2 = 2 (soll 2)
- ok  #29 Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1: -5*2^2+1 = -19 (soll -19)
- ok  #29 Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1: (-5*2)^2+20*2+1 = 141 (soll 141)
- ok  #30 Größte Fläche · 40 m Zaun an einer Mauer: 10*(40-2*10) = 200 (soll 200)
- ok  #30 Größte Fläche · 40 m Zaun an einer Mauer: 10 = 10 (soll 10)
- ok  #30 Größte Fläche · 40 m Zaun an einer Mauer: 10*10 = 100 (soll 100)

## Blind-Abgleich (docs/prefill/k9-quadrfkt-blind.json)

- ok  #1 Funktionswert · f(4) bei f(x) = 2(x − 1)² + 3: Loeser 21 · gespeichert ["21","+21"]
- ok  #2 Verschiebung nach oben · aus der Abbildung: Loeser 3 · gespeichert ["3","+3"]
- ok  #3 Funktionswert · f(−2) bei f(x) = 3(x − 1)² − 5: Loeser 22 · gespeichert ["22","+22"]
- ok  #4 Streckfaktor · Parabel durch P(5|35): Loeser 2 · gespeichert ["2","+2"]
- ok  #5 Funktionswert · Wasserstrahl 5 m von der Düse: Loeser 0.5 · gespeichert ["0,5","0.5","0,5 m","0,5m"]
- ok  #6 Streckfaktor · aus Scheitel und Punkt in der Abbildung: Loeser 0.5 · gespeichert ["0,5","+0,5","0.5","+0.5"]
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 1: Loeser 3 · gespeichert ["3","+3"]
- ok  #7 Scheitelpunkt · y = (x − 3)² + 1 Teil 2: Loeser 1 · gespeichert ["1","+1"]
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 1: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #8 Scheitelpunkt · aus der Abbildung ablesen Teil 2: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 1: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #9 Scheitelpunkt · y = −2(x + 4)² − 5 Teil 2: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 1: Loeser 6 · gespeichert ["6","+6"]
- ok  #10 Scheitelpunkt · y = 4 − 2(x − 6)² Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #11 Scheitelpunkt · Brückenbogen Teil 1: Loeser 25 · gespeichert ["25","+25"]
- ok  #11 Scheitelpunkt · Brückenbogen Teil 2: Loeser 12.5 · gespeichert ["12,5","+12,5","12.5","+12.5"]
- ok  #12 Rückrichtung · c aus dem Scheitel S(2|−1): Loeser 3 · gespeichert ["3","+3"]
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 1: Loeser 3 · gespeichert ["3","+3"]
- ok  #13 Quadratische Ergänzung · y = x² − 6x + 5 Teil 2: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 1: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #14 Quadratische Ergänzung · y = x² + 4x + 1 Teil 2: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 1: Loeser 2 · gespeichert ["2","+2"]
- ok  #15 Quadratische Ergänzung · y = 2x² − 8x + 3 Teil 2: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 1: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5"]
- ok  #16 Quadratische Ergänzung · y = x² − 5x + 2 Teil 2: Loeser -4.25 · gespeichert ["-4,25","−4,25","- 4,25","-4.25","−4.25","- 4.25"]
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 1: Loeser 10 · gespeichert ["10","+10"]
- ok  #17 Quadratische Ergänzung · höchster Punkt einer Wurfbahn Teil 2: Loeser 11.5 · gespeichert ["11,5","+11,5","11.5","+11.5"]
- ok  #18 Problemlösen · Scheitelhöhe bei bekannter Scheitelstelle: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 1: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #19 Nullstellen · f(x) = x² − 2x − 8 Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 1: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #20 Nullstellen · f(x) = (x − 1)² − 4 Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 1: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #21 Nullstellen · aus der Abbildung ablesen Teil 2: Loeser 3 · gespeichert ["3","+3"]
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 1: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #22 Nullstellen · f(x) = 2x² + 4x − 6 Teil 2: Loeser 1 · gespeichert ["1","+1"]
- ok  #23 Nullstelle · wann der Ball den Boden trifft: Loeser 2.56 · gespeichert ["2,56","2.56","2,56 s","2,56s"]
- ok  #24 Rückrichtung · Scheitelhöhe aus den Nullstellen: Loeser -9 · gespeichert ["-9","−9","- 9"]
- ok  #25 Größter Funktionswert · f(x) = −(x − 4)² + 7: Loeser 7 · gespeichert ["7","+7"]
- ok  #26 Kleinster Funktionswert · f(x) = x² − 8x + 10: Loeser -6 · gespeichert ["-6","−6","- 6"]
- ok  #27 Größter Funktionswert · f(x) = −2x² + 12x − 5: Loeser 13 · gespeichert ["13","+13"]
- ok  #28 Zahlenrätsel · Summe 20, größtes Produkt: Loeser 100 · gespeichert ["100","+100"]
- ok  #29 Maximale Höhe · Wurfbahn h(t) = −5t² + 20t + 1: Loeser 21 · gespeichert ["21","21 m","21m"]
- ok  #30 Größte Fläche · 40 m Zaun an einer Mauer: Loeser 200 · gespeichert ["200","200 m²","200m²"]
