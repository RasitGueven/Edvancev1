# Verifikation k8-stoch

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

- ok  #1 Median · ungerade Anzahl: 8 = 8 (soll 8)
- ok  #1 Median · ungerade Anzahl: 11 = 11 (soll 11)
- ok  #1 Median · ungerade Anzahl: (8+3+11+5+18)/5 = 9 (soll 9)
- ok  #2 Median · gerade Anzahl: (12+14)/2 = 13 (soll 13)
- ok  #2 Median · gerade Anzahl: (21+12)/2 = 33/2 (soll 33/2)
- ok  #2 Median · gerade Anzahl: (14+9+21+12+17+11)/6 = 14 (soll 14)
- ok  #3 Unteres Quartil · acht Werte: (6+6)/2 = 6 (soll 6)
- ok  #3 Unteres Quartil · acht Werte: (9+11)/2 = 10 (soll 10)
- ok  #3 Unteres Quartil · acht Werte: (15+15)/2 = 15 (soll 15)
- ok  #3 Unteres Quartil · acht Werte: (6+18)/2 = 12 (soll 12)
- ok  #4 Oberes Quartil · neun Werte: (10+10)/2 = 10 (soll 10)
- ok  #4 Oberes Quartil · neun Werte: 7 = 7 (soll 7)
- ok  #4 Oberes Quartil · neun Werte: (10+7)/2 = 17/2 (soll 17/2)
- ok  #5 Spannweite · Sachkontext · Morgentemperaturen: 7-(-5) = 12 (soll 12)
- ok  #5 Spannweite · Sachkontext · Morgentemperaturen: -5-7 = -12 (soll -12)
- ok  #6 Median · Sachkontext · Tore mit Ausreißer: (11+12)/2 = 23/2 (soll 23/2)
- ok  #6 Median · Sachkontext · Tore mit Ausreißer: (12+7+15+9+30+11+8+14+10+13)/10 = 129/10 (soll 129/10)
- ok  #6 Median · Sachkontext · Tore mit Ausreißer: (30+11)/2 = 41/2 (soll 41/2)
- ok  #7 Laplace · Würfel · größer als vier: 2/6 = 1/3 (soll 1/3)
- ok  #7 Laplace · Würfel · größer als vier: 2/4 = 1/2 (soll 1/2)
- ok  #7 Laplace · Würfel · größer als vier: 6/2 = 3 (soll 3)
- ok  #8 Laplace · Urne · rote Kugel: 3/(3+2) = 3/5 (soll 3/5)
- ok  #8 Laplace · Urne · rote Kugel: 3/2 = 3/2 (soll 3/2)
- ok  #8 Laplace · Urne · rote Kugel: 5/3 = 5/3 (soll 5/3)
- ok  #9 Laplace · Glücksrad · Primzahl: 5/12 = 5/12 (soll 5/12)
- ok  #9 Laplace · Glücksrad · Primzahl: 5/(12-5) = 5/7 (soll 5/7)
- ok  #9 Laplace · Glücksrad · Primzahl: 12/5 = 12/5 (soll 12/5)
- ok  #10 Laplace · Lostrommel · Niete: (40-6-10)/40 = 3/5 (soll 3/5)
- ok  #10 Laplace · Lostrommel · Niete: 24/16 = 3/2 (soll 3/2)
- ok  #10 Laplace · Lostrommel · Niete: 40/24 = 5/3 (soll 5/3)
- ok  #11 Laplace · Sachkontext · Tombola in Prozent: 30/150 = 1/5 (soll 1/5)
- ok  #11 Laplace · Sachkontext · Tombola in Prozent: 30/120 = 1/4 (soll 1/4)
- ok  #11 Laplace · Sachkontext · Tombola in Prozent: 150/30 = 5 (soll 5)
- ok  #12 Laplace · Rückrichtung · Gesamtzahl der Kugeln: 6/(2/5) = 15 (soll 15)
- ok  #12 Laplace · Rückrichtung · Gesamtzahl der Kugeln: 6+6*5/2 = 21 (soll 21)
- ok  #12 Laplace · Rückrichtung · Gesamtzahl der Kugeln: 6*2/5 = 12/5 (soll 12/5)
- ok  #13 Gegenereignis · Würfel · keine Sechs: 1-1/6 = 5/6 (soll 5/6)
- ok  #13 Gegenereignis · Würfel · keine Sechs: 1/6 = 1/6 (soll 1/6)
- ok  #14 Gegenereignis · Dezimalzahl: 1-0.35 = 13/20 (soll 13/20)
- ok  #14 Gegenereignis · Dezimalzahl: 0.35 = 7/20 (soll 7/20)
- ok  #15 Gegenereignis · Urne · keine blaue Kugel: 1-5/12 = 7/12 (soll 7/12)
- ok  #15 Gegenereignis · Urne · keine blaue Kugel: 5/12 = 5/12 (soll 5/12)
- ok  #15 Gegenereignis · Urne · keine blaue Kugel: 7/5 = 7/5 (soll 7/5)
- ok  #16 Gegenereignis · Glücksrad · weder rot noch blau: 1-(1/4+1/8) = 5/8 (soll 5/8)
- ok  #16 Gegenereignis · Glücksrad · weder rot noch blau: 1/4+1/8 = 3/8 (soll 3/8)
- ok  #16 Gegenereignis · Glücksrad · weder rot noch blau: 1-1/4 = 3/4 (soll 3/4)
- ok  #16 Gegenereignis · Glücksrad · weder rot noch blau: 1-1/8 = 7/8 (soll 7/8)
- ok  #16 Gegenereignis · Glücksrad · weder rot noch blau: 1-2/12 = 5/6 (soll 5/6)
- ok  #17 Gegenereignis · Sachkontext · keine Niete: (30+50)/200 = 2/5 (soll 2/5)
- ok  #17 Gegenereignis · Sachkontext · keine Niete: 120/200 = 3/5 (soll 3/5)
- ok  #17 Gegenereignis · Sachkontext · keine Niete: 80/120 = 2/3 (soll 2/3)
- ok  #18 Gegenereignis · Rückrichtung · Zahl der roten Kugeln: 30*(1-0.7) = 9 (soll 9)
- ok  #18 Gegenereignis · Rückrichtung · Zahl der roten Kugeln: 30*0.7 = 21 (soll 21)
- ok  #18 Gegenereignis · Rückrichtung · Zahl der roten Kugeln: 30/(1-0.7) = 100 (soll 100)
- ok  #19 Produktregel · Münze · zweimal Kopf: 1/2*1/2 = 1/4 (soll 1/4)
- ok  #19 Produktregel · Münze · zweimal Kopf: 1/2+1/2 = 1 (soll 1)
- ok  #20 Produktregel · Würfel · zweimal Sechs: 1/6*1/6 = 1/36 (soll 1/36)
- ok  #20 Produktregel · Würfel · zweimal Sechs: 1/6+1/6 = 1/3 (soll 1/3)
- ok  #21 Produktregel · Urne · mit Zurücklegen: 3/5*3/5 = 9/25 (soll 9/25)
- ok  #21 Produktregel · Urne · mit Zurücklegen: 3/5+3/5 = 6/5 (soll 6/5)
- ok  #21 Produktregel · Urne · mit Zurücklegen: 3/5*2/4 = 3/10 (soll 3/10)
- ok  #22 Produktregel · Urne · ohne Zurücklegen: 6/10*5/9 = 1/3 (soll 1/3)
- ok  #22 Produktregel · Urne · ohne Zurücklegen: 6/10*6/10 = 9/25 (soll 9/25)
- ok  #22 Produktregel · Urne · ohne Zurücklegen: 6/10+5/9 = 52/45 (soll 52/45)
- ok  #23 Produktregel · Sachkontext · zwei Gewinnlose: 3/10*2/9 = 1/15 (soll 1/15)
- ok  #23 Produktregel · Sachkontext · zwei Gewinnlose: 3/10*3/10 = 9/100 (soll 9/100)
- ok  #23 Produktregel · Sachkontext · zwei Gewinnlose: 3/10+2/9 = 47/90 (soll 47/90)
- ok  #24 Produktregel · Sachkontext · drei Stufen: 0.1*0.1*0.1 = 1/1000 (soll 1/1000)
- ok  #24 Produktregel · Sachkontext · drei Stufen: 0.1+0.1+0.1 = 3/10 (soll 3/10)
- ok  #25 Summenregel · Münze · genau einmal Kopf: 1/2*1/2+1/2*1/2 = 1/2 (soll 1/2)
- ok  #25 Summenregel · Münze · genau einmal Kopf: 1/2*1/2 = 1/4 (soll 1/4)
- ok  #25 Summenregel · Münze · genau einmal Kopf: (1/2+1/2)+(1/2+1/2) = 2 (soll 2)
- ok  #26 Summenregel · Urne · zwei Farben mit Zurücklegen: 3/5*2/5+2/5*3/5 = 12/25 (soll 12/25)
- ok  #26 Summenregel · Urne · zwei Farben mit Zurücklegen: 3/5*2/5 = 6/25 (soll 6/25)
- ok  #26 Summenregel · Urne · zwei Farben mit Zurücklegen: 3/5*2/4+2/5*3/4 = 3/5 (soll 3/5)
- ok  #27 Summenregel · Urne · gleiche Farbe ohne Zurücklegen: 4/10*3/9+6/10*5/9 = 7/15 (soll 7/15)
- ok  #27 Summenregel · Urne · gleiche Farbe ohne Zurücklegen: 6/10*5/9 = 1/3 (soll 1/3)
- ok  #27 Summenregel · Urne · gleiche Farbe ohne Zurücklegen: 4/10*3/9 = 2/15 (soll 2/15)
- ok  #27 Summenregel · Urne · gleiche Farbe ohne Zurücklegen: 4/10*4/10+6/10*6/10 = 13/25 (soll 13/25)
- ok  #28 Summenregel · Würfel · mindestens eine Sechs: 1-5/6*5/6 = 11/36 (soll 11/36)
- ok  #28 Summenregel · Würfel · mindestens eine Sechs: 5/6*5/6 = 25/36 (soll 25/36)
- ok  #28 Summenregel · Würfel · mindestens eine Sechs: 1/6+1/6 = 1/3 (soll 1/3)
- ok  #28 Summenregel · Würfel · mindestens eine Sechs: 1/6*5/6 = 5/36 (soll 5/36)
- ok  #29 Summenregel · Sachkontext · mindestens ein Gewinn: 1-0.8*0.8*0.8 = 61/125 (soll 61/125)
- ok  #29 Summenregel · Sachkontext · mindestens ein Gewinn: 0.8*0.8*0.8 = 64/125 (soll 64/125)
- ok  #29 Summenregel · Sachkontext · mindestens ein Gewinn: 0.2+0.2+0.2 = 3/5 (soll 3/5)
- ok  #30 Summenregel · Sachkontext · genau ein Gewinnlos: 3/10*7/9+7/10*3/9 = 7/15 (soll 7/15)
- ok  #30 Summenregel · Sachkontext · genau ein Gewinnlos: 3/10*7/9 = 7/30 (soll 7/30)
- ok  #30 Summenregel · Sachkontext · genau ein Gewinnlos: 3/10*7/10+7/10*3/10 = 21/50 (soll 21/50)

## Blind-Abgleich (kein Loeser)

