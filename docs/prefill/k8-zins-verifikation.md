# Verifikation k8-zins

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

- ok  #1 Jahreszinsen · Guthaben 600 € zu 3 %: 600*3/100 = 18 (soll 18)
- ok  #1 Jahreszinsen · Guthaben 600 € zu 3 %: 600*3 = 1800 (soll 1800)
- ok  #1 Jahreszinsen · Guthaben 600 € zu 3 %: 600+600*3/100 = 618 (soll 618)
- ok  #2 Jahreszinsen · Guthaben 850 € zu 2 %: 850*2/100 = 17 (soll 17)
- ok  #2 Jahreszinsen · Guthaben 850 € zu 2 %: 850*2 = 1700 (soll 1700)
- ok  #2 Jahreszinsen · Guthaben 850 € zu 2 %: 850+850*2/100 = 867 (soll 867)
- ok  #3 Jahreszinsen · Guthaben 640 € zu 2,5 %: 640*2.5/100 = 16 (soll 16)
- ok  #3 Jahreszinsen · Guthaben 640 € zu 2,5 %: 640*2.5 = 1600 (soll 1600)
- ok  #3 Jahreszinsen · Guthaben 640 € zu 2,5 %: 640+640*2.5/100 = 656 (soll 656)
- ok  #4 Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %: 480+480*3.5/100 = 2484/5 (soll 2484/5)
- ok  #4 Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %: 480*3.5/100 = 84/5 (soll 84/5)
- ok  #4 Jahreszinsen · Kontostand nach einem Jahr · 480 € zu 3,5 %: 480+480*3.5 = 2160 (soll 2160)
- ok  #5 Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung: 900+900*6/100 = 954 (soll 954)
- ok  #5 Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung: 900*6/100 = 54 (soll 54)
- ok  #5 Jahreszinsen · Kredit 900 € zu 6 % · Rückzahlung: 900+900*6 = 6300 (soll 6300)
- ok  #6 Jahreszinsen · zwei Sparangebote vergleichen · 750 €: (750*1.5/100+5)-(750*2/100) = 5/4 (soll 5/4)
- ok  #6 Jahreszinsen · zwei Sparangebote vergleichen · 750 €: 750*2/100-750*1.5/100 = 15/4 (soll 15/4)
- ok  #6 Jahreszinsen · zwei Sparangebote vergleichen · 750 €: 750*1.5/100+5 = 65/4 (soll 65/4)
- ok  #7 Teilzinsen · 600 € zu 4 % für 3 Monate: 600*4/100*3/12 = 6 (soll 6)
- ok  #7 Teilzinsen · 600 € zu 4 % für 3 Monate: 600*4/100 = 24 (soll 24)
- ok  #7 Teilzinsen · 600 € zu 4 % für 3 Monate: 600*4/100*3/100 = 18/25 (soll 18/25)
- ok  #8 Teilzinsen · 800 € zu 3 % für 5 Monate: 800*3/100*5/12 = 10 (soll 10)
- ok  #8 Teilzinsen · 800 € zu 3 % für 5 Monate: 800*3/100 = 24 (soll 24)
- ok  #8 Teilzinsen · 800 € zu 3 % für 5 Monate: 800*3/100*5 = 120 (soll 120)
- ok  #8 Teilzinsen · 800 € zu 3 % für 5 Monate: 800*3/100*5/100 = 6/5 (soll 6/5)
- ok  #9 Teilzinsen · 720 € zu 5 % für 40 Tage: 720*5/100*40/360 = 4 (soll 4)
- ok  #9 Teilzinsen · 720 € zu 5 % für 40 Tage: 720*5/100 = 36 (soll 36)
- ok  #9 Teilzinsen · 720 € zu 5 % für 40 Tage: 720*5/100*40/100 = 72/5 (soll 72/5)
- ok  #9 Teilzinsen · 720 € zu 5 % für 40 Tage: 720*5/100*40 = 1440 (soll 1440)
- ok  #10 Teilzinsen · 900 € zu 2,5 % für 8 Monate: 900*2.5/100*8/12 = 15 (soll 15)
- ok  #10 Teilzinsen · 900 € zu 2,5 % für 8 Monate: 900*2.5/100 = 45/2 (soll 45/2)
- ok  #10 Teilzinsen · 900 € zu 2,5 % für 8 Monate: 900*2.5/100*8/100 = 9/5 (soll 9/5)
- ok  #10 Teilzinsen · 900 € zu 2,5 % für 8 Monate: round(900*2.5/100*0.67,2) = 377/25 (soll 377/25)
- ok  #11 Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage: round(500*12/100*50/360,2) = 833/100 (soll 833/100)
- ok  #11 Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage: 500*12/100 = 60 (soll 60)
- ok  #11 Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage: 500*12/100*50/100 = 30 (soll 30)
- ok  #11 Teilzinsen · überzogenes Konto · 500 € zu 12 % für 50 Tage: 500*12/100*0.14 = 42/5 (soll 42/5)
- ok  #12 Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate: 840+840*9/100*7/12 = 8841/10 (soll 8841/10)
- ok  #12 Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate: 840*9/100*7/12 = 441/10 (soll 441/10)
- ok  #12 Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate: 840+840*9/100 = 4578/5 (soll 4578/5)
- ok  #12 Teilzinsen · Fahrrad finanziert · 840 € zu 9 % für 7 Monate: 840+round(840*9/100*0.58,2) = 17677/20 (soll 17677/20)
- ok  #13 Rückrechnung · Kapital aus 28 € Zinsen bei 4 %: 28*100/4 = 700 (soll 700)
- ok  #13 Rückrechnung · Kapital aus 28 € Zinsen bei 4 %: 700*4/100 = 28 (soll 28)
- ok  #13 Rückrechnung · Kapital aus 28 € Zinsen bei 4 %: 28*4/100 = 28/25 (soll 28/25)
- ok  #13 Rückrechnung · Kapital aus 28 € Zinsen bei 4 %: 28/4 = 7 (soll 7)
- ok  #14 Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €: 15/500*100 = 3 (soll 3)
- ok  #14 Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €: 15/500 = 3/100 (soll 3/100)
- ok  #14 Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €: round(500/15,2) = 3333/100 (soll 3333/100)
- ok  #14 Rückrechnung · Zinssatz aus 15 € Zinsen bei 500 €: round(500/15,1) = 333/10 (soll 333/10)
- ok  #15 Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %: 21*100/3.5 = 600 (soll 600)
- ok  #15 Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %: 600*3.5/100 = 21 (soll 21)
- ok  #15 Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %: 21*3.5/100 = 147/200 (soll 147/200)
- ok  #15 Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %: 21*3.5 = 147/2 (soll 147/2)
- ok  #15 Rückrechnung · Kapital aus 21 € Zinsen bei 3,5 %: 21/3.5 = 6 (soll 6)
- ok  #16 Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €: 20.8/640*100 = 13/4 (soll 13/4)
- ok  #16 Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €: 20.8/640 = 13/400 (soll 13/400)
- ok  #16 Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €: round(640/20.8,2) = 3077/100 (soll 3077/100)
- ok  #16 Rückrechnung · Zinssatz aus 20,80 € Zinsen bei 640 €: round(640/20.8,1) = 154/5 (soll 154/5)
- ok  #17 Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %: 765/1.02 = 750 (soll 750)
- ok  #17 Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %: 750*1.02 = 765 (soll 765)
- ok  #17 Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %: 765-765*2/100 = 7497/10 (soll 7497/10)
- ok  #17 Rückrechnung · Einzahlung aus Kontostand 765 € bei 2 %: 765*1.02 = 7803/10 (soll 7803/10)
- ok  #18 Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück: (428-400)/400*100 = 7 (soll 7)
- ok  #18 Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück: 428/400*100 = 107 (soll 107)
- ok  #18 Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück: 28/400 = 7/100 (soll 7/100)
- ok  #18 Rückrechnung · Zinssatz eines Kredits · 400 € geliehen, 428 € zurück: round(28/428*100,2) = 327/50 (soll 327/50)
- ok  #19 Zinseszins · 500 € zu 4 % für 2 Jahre: 500*1.04^2 = 2704/5 (soll 2704/5)
- ok  #19 Zinseszins · 500 € zu 4 % für 2 Jahre: 500+2*500*4/100 = 540 (soll 540)
- ok  #19 Zinseszins · 500 € zu 4 % für 2 Jahre: 500*1.04^2-500 = 204/5 (soll 204/5)
- ok  #19 Zinseszins · 500 € zu 4 % für 2 Jahre: 500*1.4^2 = 980 (soll 980)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800*1.05^3 = 9261/10 (soll 9261/10)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800+3*800*5/100 = 920 (soll 920)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800*1.05^3-800 = 1261/10 (soll 1261/10)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800*1.158 = 4632/5 (soll 4632/5)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800*1.16 = 928 (soll 928)
- ok  #20 Zinseszins · 800 € zu 5 % für 3 Jahre: 800*1.5^3 = 2700 (soll 2700)
- ok  #21 Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %: 600*1.03^2-600 = 1827/50 (soll 1827/50)
- ok  #21 Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %: 2*600*3/100 = 36 (soll 36)
- ok  #21 Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %: 600*1.03^2 = 31827/50 (soll 31827/50)
- ok  #21 Zinseszins · Zinsen nach 2 Jahren · 600 € zu 3 %: 600*1.3^2-600 = 414 (soll 414)
- ok  #22 Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €: 4 = 4 (soll 4)
- ok  #22 Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €: 500*1.1^3 = 1331/2 (soll 1331/2)
- ok  #22 Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €: 500*1.1^4 = 14641/20 (soll 14641/20)
- ok  #22 Zinseszins · Laufzeit durch Probieren · 500 € zu 10 % über 700 €: (700-500)/(500*10/100)+1 = 5 (soll 5)
- ok  #23 Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €: 400*1.2*0.8 = 384 (soll 384)
- ok  #23 Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €: 400*(1+20/100-20/100) = 400 (soll 400)
- ok  #23 Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €: 400*0.8 = 320 (soll 320)
- ok  #23 Kombinierte Veränderung · Preis +20 %, dann −20 % · 400 €: 400*1.2 = 480 (soll 480)
- ok  #24 Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €: 5 = 5 (soll 5)
- ok  #24 Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €: 500*(1+5/100)^2 = 2205/4 (soll 2205/4)
- ok  #24 Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €: (551.25-500)/500*100/2 = 41/8 (soll 41/8)
- ok  #24 Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €: (551.25-500)/500*100 = 41/4 (soll 41/4)
- ok  #24 Zinseszins · Zinssatz gesucht · 500 € werden in 2 Jahren 551,25 €: 1.05 = 21/20 (soll 21/20)
- ok  #25 Potenzen · 4³: 4^3 = 64 (soll 64)
- ok  #25 Potenzen · 4³: 4*3 = 12 (soll 12)
- ok  #25 Potenzen · 4³: 3^4 = 81 (soll 81)
- ok  #26 Potenzen · 0,4²: 0.4^2 = 4/25 (soll 4/25)
- ok  #26 Potenzen · 0,4²: 0.4*2 = 4/5 (soll 4/5)
- ok  #26 Potenzen · 0,4²: 0.4^2*10 = 8/5 (soll 8/5)
- ok  #27 Potenzen · 2,5²: 2.5^2 = 25/4 (soll 25/4)
- ok  #27 Potenzen · 2,5²: 2.5*2 = 5 (soll 5)
- ok  #27 Potenzen · 2,5²: 2^2+0.5^2 = 17/4 (soll 17/4)
- ok  #28 Potenzen · 1,05²: 1.05^2 = 441/400 (soll 441/400)
- ok  #28 Potenzen · 1,05²: 1.05*2 = 21/10 (soll 21/10)
- ok  #28 Potenzen · 1,05²: 1^2+0.05^2 = 401/400 (soll 401/400)
- ok  #29 Potenzen · 1,05³: 1.05^3 = 9261/8000 (soll 9261/8000)
- ok  #29 Potenzen · 1,05³: 1.05*3 = 63/20 (soll 63/20)
- ok  #29 Potenzen · 1,05³: 1.05^2 = 441/400 (soll 441/400)
- ok  #30 Potenzen · Würfelvolumen · Kante 0,4 m: 0.4^3 = 8/125 (soll 8/125)
- ok  #30 Potenzen · Würfelvolumen · Kante 0,4 m: 0.4*3 = 6/5 (soll 6/5)
- ok  #30 Potenzen · Würfelvolumen · Kante 0,4 m: 0.4^3*10 = 16/25 (soll 16/25)

## Blind-Abgleich (kein Loeser)

