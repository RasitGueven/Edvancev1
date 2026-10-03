# Verifikation k8-linfkt

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

- ok  #1 Steigung · zwei Punkte · erster Quadrant: (8-2)/(3-1) = 3 (soll 3)
- ok  #1 Steigung · zwei Punkte · erster Quadrant: (3-1)/(8-2) = 1/3 (soll 1/3)
- ok  #1 Steigung · zwei Punkte · erster Quadrant: (8-2)/(1-3) = -3 (soll -3)
- ok  #2 Steigung · zwei Punkte · Punkt auf der y-Achse: (5-1)/(2-0) = 2 (soll 2)
- ok  #2 Steigung · zwei Punkte · Punkt auf der y-Achse: (2-0)/(5-1) = 1/2 (soll 1/2)
- ok  #2 Steigung · zwei Punkte · Punkt auf der y-Achse: (5-1)/(0-2) = -2 (soll -2)
- ok  #3 Steigung · zwei Punkte · fallende Gerade: (-2-4)/(2-(-1)) = -2 (soll -2)
- ok  #3 Steigung · zwei Punkte · fallende Gerade: (2-(-1))/(-2-4) = -1/2 (soll -1/2)
- ok  #3 Steigung · zwei Punkte · fallende Gerade: -(-2-4)/(2-(-1)) = 2 (soll 2)
- ok  #4 Steigung · zwei Punkte · Ergebnis als Bruch: (2-(-1))/(4-(-2)) = 1/2 (soll 1/2)
- ok  #4 Steigung · zwei Punkte · Ergebnis als Bruch: (4-(-2))/(2-(-1)) = 2 (soll 2)
- ok  #4 Steigung · zwei Punkte · Ergebnis als Bruch: (2-(-1))/(-2-4) = -1/2 (soll -1/2)
- ok  #5 Steigung · Sachkontext · Preis je Kilometer: (20-11)/(10-4) = 3/2 (soll 3/2)
- ok  #5 Steigung · Sachkontext · Preis je Kilometer: (10-4)/(20-11) = 2/3 (soll 2/3)
- ok  #5 Steigung · Sachkontext · Preis je Kilometer: 11/4 = 11/4 (soll 11/4)
- ok  #6 Steigung · Rückrichtung · Punkt aus Steigung: 3+2*(4-1) = 9 (soll 9)
- ok  #6 Steigung · Rückrichtung · Punkt aus Steigung: 3+(4-1)/2 = 9/2 (soll 9/2)
- ok  #6 Steigung · Rückrichtung · Punkt aus Steigung: 3+2 = 5 (soll 5)
- ok  #6 Steigung · Rückrichtung · Punkt aus Steigung: 2*4 = 8 (soll 8)
- ok  #7 y-Achsenabschnitt · aus der Gleichung: 3*0+5 = 5 (soll 5)
- ok  #7 y-Achsenabschnitt · aus der Gleichung: 3 = 3 (soll 3)
- ok  #8 y-Achsenabschnitt · fallende Gerade: -2*0+7 = 7 (soll 7)
- ok  #8 y-Achsenabschnitt · fallende Gerade: -2 = -2 (soll -2)
- ok  #8 y-Achsenabschnitt · fallende Gerade: 7/2 = 7/2 (soll 7/2)
- ok  #9 y-Achsenabschnitt · negativer Abschnitt: 4*0-6 = -6 (soll -6)
- ok  #9 y-Achsenabschnitt · negativer Abschnitt: 4 = 4 (soll 4)
- ok  #9 y-Achsenabschnitt · negativer Abschnitt: 6 = 6 (soll 6)
- ok  #9 y-Achsenabschnitt · negativer Abschnitt: 6/4 = 3/2 (soll 3/2)
- ok  #10 y-Achsenabschnitt · aus Steigung und Punkt: 4-2*3 = -2 (soll -2)
- ok  #10 y-Achsenabschnitt · aus Steigung und Punkt: 4+2*3 = 10 (soll 10)
- ok  #10 y-Achsenabschnitt · aus Steigung und Punkt: 2*3-4 = 2 (soll 2)
- ok  #11 y-Achsenabschnitt · Sachkontext · Grundpreis: 0.1*0+8 = 8 (soll 8)
- ok  #11 y-Achsenabschnitt · Sachkontext · Grundpreis: 0.1 = 1/10 (soll 1/10)
- ok  #11 y-Achsenabschnitt · Sachkontext · Grundpreis: -8/0.1 = -80 (soll -80)
- ok  #12 y-Achsenabschnitt · Sachkontext · Anfangswert: -4*0+120 = 120 (soll 120)
- ok  #12 y-Achsenabschnitt · Sachkontext · Anfangswert: -4 = -4 (soll -4)
- ok  #12 y-Achsenabschnitt · Sachkontext · Anfangswert: 120/4 = 30 (soll 30)
- ok  #13 Graph · y-Achsenabschnitt ablesen: 2*0+1 = 1 (soll 1)
- ok  #13 Graph · y-Achsenabschnitt ablesen: -1/2 = -1/2 (soll -1/2)
- ok  #13 Graph · y-Achsenabschnitt ablesen: (3-1)/1 = 2 (soll 2)
- ok  #14 Graph · Steigung ablesen · fallend: (1-2)/(1-0) = -1 (soll -1)
- ok  #14 Graph · Steigung ablesen · fallend: 1 = 1 (soll 1)
- ok  #14 Graph · Steigung ablesen · fallend: 2 = 2 (soll 2)
- ok  #15 Graph · Steigung ablesen · Bruch: (0-(-1))/(2-0) = 1/2 (soll 1/2)
- ok  #15 Graph · Steigung ablesen · Bruch: (2-0)/(0-(-1)) = 2 (soll 2)
- ok  #15 Graph · Steigung ablesen · Bruch: -1 = -1 (soll -1)
- ok  #16 Graph · Funktionswert ablesen: -2*2+3 = -1 (soll -1)
- ok  #16 Graph · Funktionswert ablesen: (3-2)/2 = 1/2 (soll 1/2)
- ok  #16 Graph · Funktionswert ablesen: 1 = 1 (soll 1)
- ok  #17 Graph · Rückrichtung · Stelle zu einem y-Wert: (1-(-2))/1.5 = 2 (soll 2)
- ok  #17 Graph · Rückrichtung · Stelle zu einem y-Wert: 1.5*1-2 = -1/2 (soll -1/2)
- ok  #17 Graph · Rückrichtung · Stelle zu einem y-Wert: 1 = 1 (soll 1)
- ok  #18 Graph · Sachkontext · Leihgebühr pro Stunde: (5-3)/(1-0) = 2 (soll 2)
- ok  #18 Graph · Sachkontext · Leihgebühr pro Stunde: 3 = 3 (soll 3)
- ok  #18 Graph · Sachkontext · Leihgebühr pro Stunde: 1/2 = 1/2 (soll 1/2)
- ok  #19 Funktionsgleichung · aus m und b · Funktionswert: 3*4-2 = 10 (soll 10)
- ok  #19 Funktionsgleichung · aus m und b · Funktionswert: -2*4+3 = -5 (soll -5)
- ok  #19 Funktionsgleichung · aus m und b · Funktionswert: 3*4+2 = 14 (soll 14)
- ok  #20 Funktionsgleichung · fallend · Funktionswert: -2*3+5 = -1 (soll -1)
- ok  #20 Funktionsgleichung · fallend · Funktionswert: 5*3-2 = 13 (soll 13)
- ok  #20 Funktionsgleichung · fallend · Funktionswert: -(-2*3+5) = 1 (soll 1)
- ok  #21 Funktionsgleichung · aus zwei Punkten · Funktionswert: (10-4)/(2-0)*5+4 = 19 (soll 19)
- ok  #21 Funktionsgleichung · aus zwei Punkten · Funktionswert: 4*5+3 = 23 (soll 23)
- ok  #21 Funktionsgleichung · aus zwei Punkten · Funktionswert: (10-4)/(0-2)*5+4 = -11 (soll -11)
- ok  #22 Funktionsgleichung · aus zwei Punkten · Achsenabschnitt: 1-(7-1)/(3-1)*1 = -2 (soll -2)
- ok  #22 Funktionsgleichung · aus zwei Punkten · Achsenabschnitt: 1+3 = 4 (soll 4)
- ok  #22 Funktionsgleichung · aus zwei Punkten · Achsenabschnitt: 1-(3-1)/(7-1) = 2/3 (soll 2/3)
- ok  #23 Funktionsgleichung · Sachkontext · Carsharing: 0.3*20+5 = 11 (soll 11)
- ok  #23 Funktionsgleichung · Sachkontext · Carsharing: 5*20+0.3 = 1003/10 (soll 1003/10)
- ok  #23 Funktionsgleichung · Sachkontext · Carsharing: 0.3*20 = 6 (soll 6)
- ok  #24 Funktionsgleichung · Sachkontext · Kerze: -1.5*6+24 = 15 (soll 15)
- ok  #24 Funktionsgleichung · Sachkontext · Kerze: 1.5*6+24 = 33 (soll 33)
- ok  #24 Funktionsgleichung · Sachkontext · Kerze: 1.5*6 = 9 (soll 9)
- ok  #25 Nullstelle · positive Steigung: 8/2 = 4 (soll 4)
- ok  #25 Nullstelle · positive Steigung: -8/2 = -4 (soll -4)
- ok  #25 Nullstelle · positive Steigung: 8 = 8 (soll 8)
- ok  #26 Nullstelle · negative Nullstelle: -6/3 = -2 (soll -2)
- ok  #26 Nullstelle · negative Nullstelle: 6/3 = 2 (soll 2)
- ok  #26 Nullstelle · negative Nullstelle: -6 = -6 (soll -6)
- ok  #26 Nullstelle · negative Nullstelle: 3*0+6 = 6 (soll 6)
- ok  #27 Nullstelle · negative Steigung: -10/(-4) = 5/2 (soll 5/2)
- ok  #27 Nullstelle · negative Steigung: -10/4 = -5/2 (soll -5/2)
- ok  #27 Nullstelle · negative Steigung: -4*0+10 = 10 (soll 10)
- ok  #28 Nullstelle · Steigung als Dezimalzahl: -3/0.5 = -6 (soll -6)
- ok  #28 Nullstelle · Steigung als Dezimalzahl: 3/0.5 = 6 (soll 6)
- ok  #28 Nullstelle · Steigung als Dezimalzahl: -3*0.5 = -3/2 (soll -3/2)
- ok  #29 Nullstelle · Sachkontext · Akku leer: -80/(-16) = 5 (soll 5)
- ok  #29 Nullstelle · Sachkontext · Akku leer: -16*0+80 = 80 (soll 80)
- ok  #29 Nullstelle · Sachkontext · Akku leer: -80/16 = -5 (soll -5)
- ok  #30 Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle: 0-3*2 = -6 (soll -6)
- ok  #30 Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle: 3*2 = 6 (soll 6)
- ok  #30 Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle: 2 = 2 (soll 2)

## Blind-Abgleich (docs/prefill/k8-linfkt-blind.json)

- ok  #1 Steigung · zwei Punkte · erster Quadrant: Loeser 3 · gespeichert ["3","+3"]
- ok  #2 Steigung · zwei Punkte · Punkt auf der y-Achse: Loeser 2 · gespeichert ["2","+2"]
- ok  #3 Steigung · zwei Punkte · fallende Gerade: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #4 Steigung · zwei Punkte · Ergebnis als Bruch: Loeser 0.5 · gespeichert ["1/2","+1/2","0,5","+0,5","0.5","+0.5"]
- ok  #5 Steigung · Sachkontext · Preis je Kilometer: Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5","1,50","+1,50","1.50","+1.50","1,5 €","1,5€","+1,5 €","+1,5€","1.5 €","1.5€","+1.5 €","+1.5€","1,50 €","1,50€","+1,50 €","+1,50€","1.50 €","1.50€","+1.50 €","+1.50€"]
- ok  #6 Steigung · Rückrichtung · Punkt aus Steigung: Loeser 9 · gespeichert ["9","+9"]
- ok  #7 y-Achsenabschnitt · aus der Gleichung: Loeser 5 · gespeichert ["5","+5"]
- ok  #8 y-Achsenabschnitt · fallende Gerade: Loeser 7 · gespeichert ["7","+7"]
- ok  #9 y-Achsenabschnitt · negativer Abschnitt: Loeser -6 · gespeichert ["-6","−6","- 6"]
- ok  #10 y-Achsenabschnitt · aus Steigung und Punkt: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #11 y-Achsenabschnitt · Sachkontext · Grundpreis: Loeser 8 · gespeichert ["8","+8","8 €","8€","+8 €","+8€"]
- ok  #12 y-Achsenabschnitt · Sachkontext · Anfangswert: Loeser 120 · gespeichert ["120","+120","120 cm","120cm","+120 cm","+120cm"]
- ok  #13 Graph · y-Achsenabschnitt ablesen: Loeser 1 · gespeichert ["1","+1"]
- ok  #14 Graph · Steigung ablesen · fallend: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #15 Graph · Steigung ablesen · Bruch: Loeser 0.5 · gespeichert ["1/2","+1/2","0,5","+0,5","0.5","+0.5"]
- ok  #16 Graph · Funktionswert ablesen: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #17 Graph · Rückrichtung · Stelle zu einem y-Wert: Loeser 2 · gespeichert ["2","+2"]
- ok  #18 Graph · Sachkontext · Leihgebühr pro Stunde: Loeser 2 · gespeichert ["2","+2","2 €","2€","+2 €","+2€"]
- ok  #19 Funktionsgleichung · aus m und b · Funktionswert: Loeser 10 · gespeichert ["10","+10"]
- ok  #20 Funktionsgleichung · fallend · Funktionswert: Loeser -1 · gespeichert ["-1","−1","- 1"]
- ok  #21 Funktionsgleichung · aus zwei Punkten · Funktionswert: Loeser 19 · gespeichert ["19","+19"]
- ok  #22 Funktionsgleichung · aus zwei Punkten · Achsenabschnitt: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #23 Funktionsgleichung · Sachkontext · Carsharing: Loeser 11 · gespeichert ["11","+11","11 €","11€","+11 €","+11€"]
- ok  #24 Funktionsgleichung · Sachkontext · Kerze: Loeser 15 · gespeichert ["15","+15","15 cm","15cm","+15 cm","+15cm"]
- ok  #25 Nullstelle · positive Steigung: Loeser 4 · gespeichert ["4","+4"]
- ok  #26 Nullstelle · negative Nullstelle: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #27 Nullstelle · negative Steigung: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5","5/2","+5/2"]
- ok  #28 Nullstelle · Steigung als Dezimalzahl: Loeser -6 · gespeichert ["-6","−6","- 6"]
- ok  #29 Nullstelle · Sachkontext · Akku leer: Loeser 5 · gespeichert ["5","+5","5 h","5h","+5 h","+5h"]
- ok  #30 Nullstelle · Rückrichtung · Achsenabschnitt aus Nullstelle: Loeser -6 · gespeichert ["-6","−6","- 6"]
