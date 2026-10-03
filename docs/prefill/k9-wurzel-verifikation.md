# Verifikation k9-wurzel

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
| correct_answers | 29 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| parts[].afb | 2 | 0 | 0 | 0 |
| parts[].competency_content | 2 | 0 | 0 | 0 |
| correct_answers[].antwort | 2 | 0 | 0 | 0 |

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
| tasks.competency_content | 29 | 29 | 0 | 0 |
| tasks.competency_process | 29 | 29 | 0 | 0 |
| task_solutions.correct_answers | 29 | 29 | 0 | 0 |
| parts[].afb | 2 | 2 | 0 | 0 |
| parts[].competency_content | 2 | 2 | 0 | 0 |
| parts[].antwort | 2 | 2 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Quadratwurzel · Zahl, die quadriert 225 ergibt: (15) = 15 (soll 15)
- ok  #1 Quadratwurzel · Zahl, die quadriert 225 ergibt: 225^2 = 50625 (soll 50625)
- ok  #1 Quadratwurzel · Zahl, die quadriert 225 ergibt: 225/2 = 225/2 (soll 225/2)
- ok  #2 Quadratwurzel · √0,49: (7/10) = 7/10 (soll 7/10)
- ok  #2 Quadratwurzel · √0,49: 0.07 = 7/100 (soll 7/100)
- ok  #2 Quadratwurzel · √0,49: 7 = 7 (soll 7)
- ok  #2 Quadratwurzel · √0,49: 0.49/2 = 49/200 (soll 49/200)
- ok  #3 Quadratwurzel · √(9/16): (3/4) = 3/4 (soll 3/4)
- ok  #3 Quadratwurzel · √(9/16): (3)/16 = 3/16 (soll 3/16)
- ok  #3 Quadratwurzel · √(9/16): 9/16/2 = 9/32 (soll 9/32)
- ok  #4 Quadratwurzel · √0,0016: (1/25) = 1/25 (soll 1/25)
- ok  #4 Quadratwurzel · √0,0016: 0.4 = 2/5 (soll 2/5)
- ok  #4 Quadratwurzel · √0,0016: 0.004 = 1/250 (soll 1/250)
- ok  #4 Quadratwurzel · √0,0016: 0.0016/2 = 1/1250 (soll 1/1250)
- ok  #5 Quadratwurzel · Seite eines Quadrats mit 2,25 m²: (3/2)*100 = 150 (soll 150)
- ok  #5 Quadratwurzel · Seite eines Quadrats mit 2,25 m²: (3/2) = 3/2 (soll 3/2)
- ok  #5 Quadratwurzel · Seite eines Quadrats mit 2,25 m²: 0.15*100 = 15 (soll 15)
- ok  #5 Quadratwurzel · Seite eines Quadrats mit 2,25 m²: 2.25/2*100 = 225/2 (soll 225/2)
- ok  #6 Quadratwurzel · Zaun um einen Platz mit 1296 m²: 4*(36) = 144 (soll 144)
- ok  #6 Quadratwurzel · Zaun um einen Platz mit 1296 m²: (36) = 36 (soll 36)
- ok  #6 Quadratwurzel · Zaun um einen Platz mit 1296 m²: 4*1296/2 = 2592 (soll 2592)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 1: (7) = 7 (soll 7)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 1: 49 = 49 (soll 49)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 1: 50/2 = 25 (soll 25)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 2: (8) = 8 (soll 8)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 2: 64 = 64 (soll 64)
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 2: 50/2+1 = 26 (soll 26)
- ok  #8 Näherung · √10 auf eine Stelle: round((31622776601683793319988935444327185337195/10000000000000000000000000000000000000000),1) = 16/5 (soll 16/5)
- ok  #8 Näherung · √10 auf eine Stelle: round((31622776601683793319988935444327185337195/10000000000000000000000000000000000000000)-0.05,1) = 31/10 (soll 31/10)
- ok  #8 Näherung · √10 auf eine Stelle: round(10/2,1) = 5 (soll 5)
- ok  #9 Näherung · √30 auf zwei Stellen: round((54772255750516611345696978280080213395274/10000000000000000000000000000000000000000),2) = 137/25 (soll 137/25)
- ok  #9 Näherung · √30 auf zwei Stellen: round((54772255750516611345696978280080213395274/10000000000000000000000000000000000000000)-0.005,2) = 547/100 (soll 547/100)
- ok  #9 Näherung · √30 auf zwei Stellen: round(30/2,2) = 15 (soll 15)
- ok  #10 Näherung · √0,9 auf zwei Stellen: round((94868329805051379959966806332981556011586/100000000000000000000000000000000000000000),2) = 19/20 (soll 19/20)
- ok  #10 Näherung · √0,9 auf zwei Stellen: round(0.9/2,2) = 9/20 (soll 9/20)
- ok  #10 Näherung · √0,9 auf zwei Stellen: round((94868329805051379959966806332981556011586/100000000000000000000000000000000000000000)-0.005,2) = 47/50 (soll 47/50)
- ok  #11 Näherung · Seite eines Beets mit 11 m²: round((33166247903553998491149327366706866839270/10000000000000000000000000000000000000000),2) = 83/25 (soll 83/25)
- ok  #11 Näherung · Seite eines Beets mit 11 m²: round((33166247903553998491149327366706866839270/10000000000000000000000000000000000000000)-0.005,2) = 331/100 (soll 331/100)
- ok  #11 Näherung · Seite eines Beets mit 11 m²: round(11/2,2) = 11/2 (soll 11/2)
- ok  #11 Näherung · Seite eines Beets mit 11 m²: round((33166247903553998491149327366706866839270/10000000000000000000000000000000000000000),1) = 33/10 (soll 33/10)
- ok  #12 Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern: round((24494897427831780981972840747058913919659/10000000000000000000000000000000000000000)*100,4) = 244949/1000 (soll 244949/1000)
- ok  #12 Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern: round((24494897427831780981972840747058913919659/10000000000000000000000000000000000000000)*100,4) = 244949/1000 (soll 244949/1000)
- ok  #12 Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern: round((24494897427831780981972840747058913919659/10000000000000000000000000000000000000000),2) = 49/20 (soll 49/20)
- ok  #12 Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern: round(6/2*100,4) = 300 (soll 300)
- ok  #13 Irrational · Anzahl unter fünf Zahlen: 1+1 = 2 (soll 2)
- ok  #13 Irrational · Anzahl unter fünf Zahlen: 1+1+1 = 3 (soll 3)
- ok  #13 Irrational · Anzahl unter fünf Zahlen: 1+1+1+1 = 4 (soll 4)
- ok  #14 Rational · 0,375 als gekürzter Bruch: 1000/125 = 8 (soll 8)
- ok  #14 Rational · 0,375 als gekürzter Bruch: 1000 = 1000 (soll 1000)
- ok  #14 Rational · 0,375 als gekürzter Bruch: 1000/5 = 200 (soll 200)
- ok  #14 Rational · 0,375 als gekürzter Bruch: 1000/25 = 40 (soll 40)
- ok  #15 Rational · 0,4545… als gekürzter Bruch: 99/9 = 11 (soll 11)
- ok  #15 Rational · 0,4545… als gekürzter Bruch: 99 = 99 (soll 99)
- ok  #15 Rational · 0,4545… als gekürzter Bruch: 100/5 = 20 (soll 20)
- ok  #16 Rational · Anzahl unter sechs Zahlen: 1+1+1+1 = 4 (soll 4)
- ok  #16 Rational · Anzahl unter sechs Zahlen: 1+1+1 = 3 (soll 3)
- ok  #16 Rational · Anzahl unter sechs Zahlen: 1+1 = 2 (soll 2)
- ok  #16 Rational · Anzahl unter sechs Zahlen: 1+1+1+1+1 = 5 (soll 5)
- ok  #17 Irrational · Fliesen mit rationaler Seitenlänge: 1+1+1 = 3 (soll 3)
- ok  #17 Irrational · Fliesen mit rationaler Seitenlänge: 1+1+1+1 = 4 (soll 4)
- ok  #17 Irrational · Fliesen mit rationaler Seitenlänge: 1 = 1 (soll 1)
- ok  #18 Irrational · rationale Wurzeln von 1 bis 60: (7) = 7 (soll 7)
- ok  #18 Irrational · rationale Wurzeln von 1 bis 60: 60-(7) = 53 (soll 53)
- ok  #18 Irrational · rationale Wurzeln von 1 bis 60: 0 = 0 (soll 0)
- ok  #19 Wurzelgesetz · √2 · √8: (4) = 4 (soll 4)
- ok  #19 Wurzelgesetz · √2 · √8: 2*8 = 16 (soll 16)
- ok  #19 Wurzelgesetz · √2 · √8: 2*8/2 = 8 (soll 8)
- ok  #20 Wurzelgesetz · √50 : √2: (5) = 5 (soll 5)
- ok  #20 Wurzelgesetz · √50 : √2: 50/2 = 25 (soll 25)
- ok  #20 Wurzelgesetz · √50 : √2: 50/2/2 = 25/2 (soll 25/2)
- ok  #21 Wurzel einer Summe · √(36 + 64): (10) = 10 (soll 10)
- ok  #21 Wurzel einer Summe · √(36 + 64): (6)+(8) = 14 (soll 14)
- ok  #21 Wurzel einer Summe · √(36 + 64): 36+64 = 100 (soll 100)
- ok  #21 Wurzel einer Summe · √(36 + 64): (36+64)/2 = 50 (soll 50)
- ok  #22 Wurzel einer Summe · √(1,44 + 0,81): (3/2) = 3/2 (soll 3/2)
- ok  #22 Wurzel einer Summe · √(1,44 + 0,81): (6/5)+(9/10) = 21/10 (soll 21/10)
- ok  #22 Wurzel einer Summe · √(1,44 + 0,81): 1.44+0.81 = 9/4 (soll 9/4)
- ok  #22 Wurzel einer Summe · √(1,44 + 0,81): (1.44+0.81)/2 = 9/8 (soll 9/8)
- ok  #23 Wurzelgesetz · Rechteck √8 m mal √18 m: (12) = 12 (soll 12)
- ok  #23 Wurzelgesetz · Rechteck √8 m mal √18 m: 8*18 = 144 (soll 144)
- ok  #23 Wurzelgesetz · Rechteck √8 m mal √18 m: round(2*((28284271247461900976033774484193961571393/10000000000000000000000000000000000000000)+(42426406871192851464050661726290942357090/10000000000000000000000000000000000000000)),2) = 707/50 (soll 707/50)
- ok  #23 Wurzelgesetz · Rechteck √8 m mal √18 m: round((50990195135927848300282241090227819895637/10000000000000000000000000000000000000000),2) = 51/10 (soll 51/10)
- ok  #24 Wurzel einer Summe · ein Beet so groß wie zwei: (5) = 5 (soll 5)
- ok  #24 Wurzel einer Summe · ein Beet so groß wie zwei: (3)+(4) = 7 (soll 7)
- ok  #24 Wurzel einer Summe · ein Beet so groß wie zwei: 9+16 = 25 (soll 25)
- ok  #24 Wurzel einer Summe · ein Beet so groß wie zwei: (9+16)/2 = 25/2 (soll 25/2)
- ok  #25 Teilweise Wurzel ziehen · √72 = a · √2: (6) = 6 (soll 6)
- ok  #25 Teilweise Wurzel ziehen · √72 = a · √2: 72/2 = 36 (soll 36)
- ok  #25 Teilweise Wurzel ziehen · √72 = a · √2: 72/2/2 = 18 (soll 18)
- ok  #25 Teilweise Wurzel ziehen · √72 = a · √2: round((84852813742385702928101323452581884714180/10000000000000000000000000000000000000000),2) = 849/100 (soll 849/100)
- ok  #26 Teilweise Wurzel ziehen · √48 = a · √3: (4) = 4 (soll 4)
- ok  #26 Teilweise Wurzel ziehen · √48 = a · √3: 48/3 = 16 (soll 16)
- ok  #26 Teilweise Wurzel ziehen · √48 = a · √3: 48/3/2 = 8 (soll 8)
- ok  #26 Teilweise Wurzel ziehen · √48 = a · √3: round((69282032302755091741097853660234894677712/10000000000000000000000000000000000000000),2) = 693/100 (soll 693/100)
- ok  #27 Teilweise Wurzel ziehen · √200 = a · √2: (10) = 10 (soll 10)
- ok  #27 Teilweise Wurzel ziehen · √200 = a · √2: 200/2 = 100 (soll 100)
- ok  #27 Teilweise Wurzel ziehen · √200 = a · √2: round((141421356237309504880168872420969807856967/10000000000000000000000000000000000000000),2) = 707/50 (soll 707/50)
- ok  #28 Teilweise Wurzel ziehen · √18 · √6 = a · √3: (6) = 6 (soll 6)
- ok  #28 Teilweise Wurzel ziehen · √18 · √6 = a · √3: 18*6/3 = 36 (soll 36)
- ok  #28 Teilweise Wurzel ziehen · √18 · √6 = a · √3: 18*6/3/2 = 18 (soll 18)
- ok  #28 Teilweise Wurzel ziehen · √18 · √6 = a · √3: round((103923048454132637611646780490352342016568/10000000000000000000000000000000000000000),2) = 1039/100 (soll 1039/100)
- ok  #29 Teilweise Wurzel ziehen · Spielplatz mit 180 m²: (6) = 6 (soll 6)
- ok  #29 Teilweise Wurzel ziehen · Spielplatz mit 180 m²: 180/5 = 36 (soll 36)
- ok  #29 Teilweise Wurzel ziehen · Spielplatz mit 180 m²: 180/5/2 = 18 (soll 18)
- ok  #29 Teilweise Wurzel ziehen · Spielplatz mit 180 m²: round((134164078649987381784550420123876574126437/10000000000000000000000000000000000000000),2) = 671/50 (soll 671/50)
- ok  #30 Rückrichtung · 6 · √3 = √b: 6^2*3 = 108 (soll 108)
- ok  #30 Rückrichtung · 6 · √3 = √b: 6*3 = 18 (soll 18)
- ok  #30 Rückrichtung · 6 · √3 = √b: 2*6*3 = 36 (soll 36)

## Blind-Abgleich (docs/prefill/k9-wurzel-blind.json)

- ok  #1 Quadratwurzel · Zahl, die quadriert 225 ergibt: Loeser 15 · gespeichert ["15","+15"]
- ok  #2 Quadratwurzel · √0,49: Loeser 0.7 · gespeichert ["0,7","+0,7","0.7","+0.7"]
- ok  #3 Quadratwurzel · √(9/16): Loeser 0.75 · gespeichert ["0,75","+0,75","0.75","+0.75","3/4","+3/4"]
- ok  #4 Quadratwurzel · √0,0016: Loeser 0.04 · gespeichert ["0,04","+0,04","0.04","+0.04"]
- ok  #5 Quadratwurzel · Seite eines Quadrats mit 2,25 m²: Loeser 150 · gespeichert ["150","150 cm","150cm"]
- ok  #6 Quadratwurzel · Zaun um einen Platz mit 1296 m²: Loeser 144 · gespeichert ["144","144 m","144m"]
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 1: Loeser 7 · gespeichert ["7","+7"]
- ok  #7 Näherung · √50 zwischen zwei ganzen Zahlen Teil 2: Loeser 8 · gespeichert ["8","+8"]
- ok  #8 Näherung · √10 auf eine Stelle: Loeser 3.2 · gespeichert ["3,2","+3,2","3.2","+3.2"]
- ok  #9 Näherung · √30 auf zwei Stellen: Loeser 5.48 · gespeichert ["5,48","+5,48","5.48","+5.48"]
- ok  #10 Näherung · √0,9 auf zwei Stellen: Loeser 0.95 · gespeichert ["0,95","+0,95","0.95","+0.95"]
- ok  #11 Näherung · Seite eines Beets mit 11 m²: Loeser 3.32 · gespeichert ["3,32","3.32","3,32 m","3,32m"]
- ok  #12 Näherung · Teppich mit 6 m², Seite in ganzen Zentimetern: Loeser 245 · gespeichert ["245","245 cm","245cm"]
- ok  #13 Irrational · Anzahl unter fünf Zahlen: Loeser 2 · gespeichert ["2","+2"]
- ok  #14 Rational · 0,375 als gekürzter Bruch: Loeser 8 · gespeichert ["8","+8"]
- ok  #15 Rational · 0,4545… als gekürzter Bruch: Loeser 11 · gespeichert ["11","+11"]
- ok  #16 Rational · Anzahl unter sechs Zahlen: Loeser 4 · gespeichert ["4","+4"]
- ok  #17 Irrational · Fliesen mit rationaler Seitenlänge: Loeser 3 · gespeichert ["3","+3"]
- ok  #18 Irrational · rationale Wurzeln von 1 bis 60: Loeser 7 · gespeichert ["7","+7"]
- ok  #19 Wurzelgesetz · √2 · √8: Loeser 4 · gespeichert ["4","+4"]
- ok  #20 Wurzelgesetz · √50 : √2: Loeser 5 · gespeichert ["5","+5"]
- ok  #21 Wurzel einer Summe · √(36 + 64): Loeser 10 · gespeichert ["10","+10"]
- ok  #22 Wurzel einer Summe · √(1,44 + 0,81): Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5"]
- ok  #23 Wurzelgesetz · Rechteck √8 m mal √18 m: Loeser 12 · gespeichert ["12","12 m²","12m²"]
- ok  #24 Wurzel einer Summe · ein Beet so groß wie zwei: Loeser 5 · gespeichert ["5","5 m","5m"]
- ok  #25 Teilweise Wurzel ziehen · √72 = a · √2: Loeser 6 · gespeichert ["6","+6"]
- ok  #26 Teilweise Wurzel ziehen · √48 = a · √3: Loeser 4 · gespeichert ["4","+4"]
- ok  #27 Teilweise Wurzel ziehen · √200 = a · √2: Loeser 10 · gespeichert ["10","+10"]
- ok  #28 Teilweise Wurzel ziehen · √18 · √6 = a · √3: Loeser 6 · gespeichert ["6","+6"]
- ok  #29 Teilweise Wurzel ziehen · Spielplatz mit 180 m²: Loeser 6 · gespeichert ["6","+6"]
- ok  #30 Rückrichtung · 6 · √3 = √b: Loeser 108 · gespeichert ["108","+108"]
