# Verifikation erklaer-k8-linfkt-checks

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
| correct_answers | 30 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |

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
| tasks.competency_content | 30 | 30 | 0 | 0 |
| tasks.competency_process | 30 | 30 | 0 | 0 |
| task_solutions.correct_answers | 30 | 30 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Check · Steigung am Graphen ablesen: (6-(-2))/(1-(-1)) = 4 (soll 4)
- ok  #1 Check · Steigung am Graphen ablesen: (1-(-1))/(6-(-2)) = 1/4 (soll 1/4)
- ok  #1 Check · Steigung am Graphen ablesen: 2/8 = 1/4 (soll 1/4)
- ok  #2 Check · Steigung am Graphen ablesen · Bruch: (4-(-2))/(2-(-2)) = 3/2 (soll 3/2)
- ok  #2 Check · Steigung am Graphen ablesen · Bruch: (2-(-2))/(4-(-2)) = 2/3 (soll 2/3)
- ok  #3 Check · Steigung aus zwei Punkten · negative Koordinaten: (4-(-2))/(1-(-3)) = 3/2 (soll 3/2)
- ok  #3 Check · Steigung aus zwei Punkten · negative Koordinaten: (4-(-2))/(-3-1) = -3/2 (soll -3/2)
- ok  #3 Check · Steigung aus zwei Punkten · negative Koordinaten: 6/(-4) = -3/2 (soll -3/2)
- ok  #3 Check · Steigung aus zwei Punkten · negative Koordinaten: (1-(-3))/(4-(-2)) = 2/3 (soll 2/3)
- ok  #4 Check · Steigung aus zwei Punkten · fallend: (-5-4)/(1-(-2)) = -3 (soll -3)
- ok  #4 Check · Steigung aus zwei Punkten · fallend: (-5-4)/(-2-1) = 3 (soll 3)
- ok  #4 Check · Steigung aus zwei Punkten · fallend: (1-(-2))/(-5-4) = -1/3 (soll -1/3)
- ok  #5 Check · Punkt aus Steigung und Punkt: 1+3*(5-2) = 10 (soll 10)
- ok  #5 Check · Punkt aus Steigung und Punkt: 1+3 = 4 (soll 4)
- ok  #5 Check · Punkt aus Steigung und Punkt: 3*5 = 15 (soll 15)
- ok  #5 Check · Punkt aus Steigung und Punkt: 1+(5-2)/3 = 2 (soll 2)
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: 2+4*(4-1) = 14 (soll 14)
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: 2+4 = 6 (soll 6)
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: 4*4 = 16 (soll 16)
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: 2+(4-1)/4 = 11/4 (soll 11/4)
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: 2+3/4 = 11/4 (soll 11/4)
- ok  #7 Check · y-Achsenabschnitt aus der Gleichung: -2*0+6 = 6 (soll 6)
- ok  #7 Check · y-Achsenabschnitt aus der Gleichung: -2 = -2 (soll -2)
- ok  #7 Check · y-Achsenabschnitt aus der Gleichung: 6/2 = 3 (soll 3)
- ok  #8 Check · y-Achsenabschnitt · negatives b: 5*0-4 = -4 (soll -4)
- ok  #8 Check · y-Achsenabschnitt · negatives b: 5 = 5 (soll 5)
- ok  #8 Check · y-Achsenabschnitt · negatives b: 0-(-4) = 4 (soll 4)
- ok  #8 Check · y-Achsenabschnitt · negatives b: 4/5 = 4/5 (soll 4/5)
- ok  #9 Check · b aus Steigung und Punkt: 5-3*2 = -1 (soll -1)
- ok  #9 Check · b aus Steigung und Punkt: 5+3*2 = 11 (soll 11)
- ok  #9 Check · b aus Steigung und Punkt: -(5-3*2) = 1 (soll 1)
- ok  #10 Check · b aus Steigung und Punkt · fallend: 1-(-2)*3 = 7 (soll 7)
- ok  #10 Check · b aus Steigung und Punkt · fallend: 1+(-2)*3 = -5 (soll -5)
- ok  #10 Check · b aus Steigung und Punkt · fallend: -(1-(-2)*3) = -7 (soll -7)
- ok  #11 Check · Startwert im Sachzusammenhang · Taxi: 2*0+4 = 4 (soll 4)
- ok  #11 Check · Startwert im Sachzusammenhang · Taxi: 2 = 2 (soll 2)
- ok  #11 Check · Startwert im Sachzusammenhang · Taxi: -4/2 = -2 (soll -2)
- ok  #12 Check · Startwert im Sachzusammenhang · Kerze: -3*0+15 = 15 (soll 15)
- ok  #12 Check · Startwert im Sachzusammenhang · Kerze: -3 = -3 (soll -3)
- ok  #12 Check · Startwert im Sachzusammenhang · Kerze: 15/3 = 5 (soll 5)
- ok  #13 Check · Gleichung aus m und b · negatives b: 4*3+(-3) = 9 (soll 9)
- ok  #13 Check · Gleichung aus m und b · negatives b: -3*3+4 = -5 (soll -5)
- ok  #13 Check · Gleichung aus m und b · negatives b: 4*3+3 = 15 (soll 15)
- ok  #14 Check · Gleichung aus m und b · fallend: -4*2+3 = -5 (soll -5)
- ok  #14 Check · Gleichung aus m und b · fallend: 3*2+(-4) = 2 (soll 2)
- ok  #14 Check · Gleichung aus m und b · fallend: -(-4*2+3) = 5 (soll 5)
- ok  #14 Check · Gleichung aus m und b · fallend: 4*2+3 = 11 (soll 11)
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: 3-(7-3)/(3-1)*1 = 1 (soll 1)
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: 3+2*1 = 5 (soll 5)
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: (7-3)/(3-1) = 2 (soll 2)
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: 3-1/2*1 = 5/2 (soll 5/2)
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: 3-1/2 = 5/2 (soll 5/2)
- ok  #16 Check · Gleichung aus zwei Punkten · einsetzen: (5-(-1))/(3-0)*4+(-1) = 7 (soll 7)
- ok  #16 Check · Gleichung aus zwei Punkten · einsetzen: (5-(-1))/(0-3)*4-1 = -9 (soll -9)
- ok  #16 Check · Gleichung aus zwei Punkten · einsetzen: 3/6*4-1 = 1 (soll 1)
- ok  #17 Check · Gleichung im Sachzusammenhang · Abnahme: -4*5+50 = 30 (soll 30)
- ok  #17 Check · Gleichung im Sachzusammenhang · Abnahme: 4*5+50 = 70 (soll 70)
- ok  #17 Check · Gleichung im Sachzusammenhang · Abnahme: 50*5-4 = 246 (soll 246)
- ok  #17 Check · Gleichung im Sachzusammenhang · Abnahme: 4*5 = 20 (soll 20)
- ok  #18 Check · Gleichung im Sachzusammenhang · Kosten: 15*6+20 = 110 (soll 110)
- ok  #18 Check · Gleichung im Sachzusammenhang · Kosten: 20*6+15 = 135 (soll 135)
- ok  #18 Check · Gleichung im Sachzusammenhang · Kosten: 15*6 = 90 (soll 90)
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: 2*0-3 = -3 (soll -3)
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: 2 = 2 (soll 2)
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: 0-(-3) = 3 (soll 3)
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: 3/2 = 3/2 (soll 3/2)
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: 3/2 = 3/2 (soll 3/2)
- ok  #20 Check · Steigung am Graphen ablesen · fallend: (-1-1)/(1-0) = -2 (soll -2)
- ok  #20 Check · Steigung am Graphen ablesen · fallend: 2/1 = 2 (soll 2)
- ok  #20 Check · Steigung am Graphen ablesen · fallend: 1/(-2) = -1/2 (soll -1/2)
- ok  #20 Check · Steigung am Graphen ablesen · fallend: 1/(-2) = -1/2 (soll -1/2)
- ok  #20 Check · Steigung am Graphen ablesen · fallend: 1 = 1 (soll 1)
- ok  #21 Check · y-Wert am Graphen ablesen: 2*1-4 = -2 (soll -2)
- ok  #21 Check · y-Wert am Graphen ablesen: 0-(-2) = 2 (soll 2)
- ok  #21 Check · y-Wert am Graphen ablesen: (1+4)/2 = 5/2 (soll 5/2)
- ok  #21 Check · y-Wert am Graphen ablesen: (1+4)/2 = 5/2 (soll 5/2)
- ok  #22 Check · Stelle x am Graphen ablesen: (-1-1)/(-0.5) = 4 (soll 4)
- ok  #22 Check · Stelle x am Graphen ablesen: -1 = -1 (soll -1)
- ok  #22 Check · Stelle x am Graphen ablesen: -0.5*(-1)+1 = 3/2 (soll 3/2)
- ok  #22 Check · Stelle x am Graphen ablesen: -0.5*(-1)+1 = 3/2 (soll 3/2)
- ok  #23 Check · Graph im Sachzusammenhang · Taxi: (7-4)/1 = 3 (soll 3)
- ok  #23 Check · Graph im Sachzusammenhang · Taxi: 4 = 4 (soll 4)
- ok  #23 Check · Graph im Sachzusammenhang · Taxi: 1/3 = 1/3 (soll 1/3)
- ok  #24 Check · Graph im Sachzusammenhang · Paket: (5-4)/2 = 1/2 (soll 1/2)
- ok  #24 Check · Graph im Sachzusammenhang · Paket: 4 = 4 (soll 4)
- ok  #24 Check · Graph im Sachzusammenhang · Paket: 2/1 = 2 (soll 2)
- ok  #25 Check · Nullstelle am Graphen ablesen · negativ: -2/0.5 = -4 (soll -4)
- ok  #25 Check · Nullstelle am Graphen ablesen · negativ: 0.5*0+2 = 2 (soll 2)
- ok  #25 Check · Nullstelle am Graphen ablesen · negativ: 0-(-4) = 4 (soll 4)
- ok  #26 Check · Nullstelle am Graphen ablesen: 6/2 = 3 (soll 3)
- ok  #26 Check · Nullstelle am Graphen ablesen: 2*0-6 = -6 (soll -6)
- ok  #26 Check · Nullstelle am Graphen ablesen: -(6/2) = -3 (soll -3)
- ok  #27 Check · Nullstelle berechnen: 12/3 = 4 (soll 4)
- ok  #27 Check · Nullstelle berechnen: 12 = 12 (soll 12)
- ok  #27 Check · Nullstelle berechnen: 12*3 = 36 (soll 36)
- ok  #27 Check · Nullstelle berechnen: -12/3 = -4 (soll -4)
- ok  #27 Check · Nullstelle berechnen: 3*0-12 = -12 (soll -12)
- ok  #28 Check · Nullstelle berechnen · fallend: -10/(-5) = 2 (soll 2)
- ok  #28 Check · Nullstelle berechnen · fallend: 10/(-5) = -2 (soll -2)
- ok  #28 Check · Nullstelle berechnen · fallend: -10 = -10 (soll -10)
- ok  #28 Check · Nullstelle berechnen · fallend: -5*0+10 = 10 (soll 10)
- ok  #29 Check · Nullstelle im Sachzusammenhang · Tank: -40/(-5) = 8 (soll 8)
- ok  #29 Check · Nullstelle im Sachzusammenhang · Tank: -5*0+40 = 40 (soll 40)
- ok  #29 Check · Nullstelle im Sachzusammenhang · Tank: 40/(-5) = -8 (soll -8)
- ok  #30 Check · Nullstelle im Sachzusammenhang · Guthaben: -30/(-2) = 15 (soll 15)
- ok  #30 Check · Nullstelle im Sachzusammenhang · Guthaben: -2*0+30 = 30 (soll 30)
- ok  #30 Check · Nullstelle im Sachzusammenhang · Guthaben: 30/(-2) = -15 (soll -15)

## Blind-Abgleich (docs/prefill/erklaer-k8-linfkt-checks-blind.json)

- ok  #1 Check · Steigung am Graphen ablesen: Loeser 4 · gespeichert ["4","+4"]
- ok  #2 Check · Steigung am Graphen ablesen · Bruch: Loeser 1.5 · gespeichert ["3/2","+3/2","1,5","+1,5","1.5","+1.5"]
- ok  #3 Check · Steigung aus zwei Punkten · negative Koordinaten: Loeser 1.5 · gespeichert ["3/2","+3/2","1,5","+1,5","1.5","+1.5"]
- ok  #4 Check · Steigung aus zwei Punkten · fallend: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #5 Check · Punkt aus Steigung und Punkt: Loeser 10 · gespeichert ["10","+10"]
- ok  #6 Check · Punkt aus Steigung und Punkt · größere Steigung: Loeser 14 · gespeichert ["14","+14"]
- ok  #7 Check · y-Achsenabschnitt aus der Gleichung: Loeser 6 · gespeichert ["6","+6"]
- ok  #8 Check · y-Achsenabschnitt · negatives b: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #9 Check · b aus Steigung und Punkt: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #10 Check · b aus Steigung und Punkt · fallend: Loeser 7 · gespeichert ["7","+7"]
- ok  #11 Check · Startwert im Sachzusammenhang · Taxi: Loeser 4 · gespeichert ["4","+4"]
- ok  #12 Check · Startwert im Sachzusammenhang · Kerze: Loeser 15 · gespeichert ["15","+15"]
- ok  #13 Check · Gleichung aus m und b · negatives b: Loeser 9 · gespeichert ["9","+9"]
- ok  #14 Check · Gleichung aus m und b · fallend: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #15 Check · Gleichung aus zwei Punkten · b bestimmen: Loeser 1 · gespeichert ["1","+1"]
- ok  #16 Check · Gleichung aus zwei Punkten · einsetzen: Loeser 7 · gespeichert ["7","+7"]
- ok  #17 Check · Gleichung im Sachzusammenhang · Abnahme: Loeser 30 · gespeichert ["30","+30"]
- ok  #18 Check · Gleichung im Sachzusammenhang · Kosten: Loeser 110 · gespeichert ["110","+110"]
- ok  #19 Check · y-Achsenabschnitt am Graphen ablesen: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #20 Check · Steigung am Graphen ablesen · fallend: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #21 Check · y-Wert am Graphen ablesen: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #22 Check · Stelle x am Graphen ablesen: Loeser 4 · gespeichert ["4","+4"]
- ok  #23 Check · Graph im Sachzusammenhang · Taxi: Loeser 3 · gespeichert ["3","+3"]
- ok  #24 Check · Graph im Sachzusammenhang · Paket: Loeser 0.5 · gespeichert ["1/2","+1/2","0,5","+0,5","0.5","+0.5"]
- ok  #25 Check · Nullstelle am Graphen ablesen · negativ: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #26 Check · Nullstelle am Graphen ablesen: Loeser 3 · gespeichert ["3","+3"]
- ok  #27 Check · Nullstelle berechnen: Loeser 4 · gespeichert ["4","+4"]
- ok  #28 Check · Nullstelle berechnen · fallend: Loeser 2 · gespeichert ["2","+2"]
- ok  #29 Check · Nullstelle im Sachzusammenhang · Tank: Loeser 8 · gespeichert ["8","+8"]
- ok  #30 Check · Nullstelle im Sachzusammenhang · Guthaben: Loeser 15 · gespeichert ["15","+15"]
