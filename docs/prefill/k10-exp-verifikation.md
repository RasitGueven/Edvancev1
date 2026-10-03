# Verifikation k10-exp

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
| correct_answers | 26 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| parts[].afb | 8 | 0 | 0 | 0 |
| parts[].competency_content | 8 | 0 | 0 | 0 |
| correct_answers[].antwort | 8 | 0 | 0 | 0 |

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
| tasks.competency_content | 26 | 26 | 0 | 0 |
| tasks.competency_process | 26 | 26 | 0 | 0 |
| task_solutions.correct_answers | 26 | 26 | 0 | 0 |
| parts[].afb | 8 | 8 | 0 | 0 |
| parts[].competency_content | 8 | 8 | 0 | 0 |
| parts[].antwort | 8 | 8 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Wachstumsfaktor · Zunahme um 4 %: 1+4/100 = 26/25 (soll 26/25)
- ok  #1 Wachstumsfaktor · Zunahme um 4 %: 1+4/10 = 7/5 (soll 7/5)
- ok  #1 Wachstumsfaktor · Zunahme um 4 %: 4/100 = 1/25 (soll 1/25)
- ok  #2 Abnahmefaktor · Abnahme um 15 %: 1-15/100 = 17/20 (soll 17/20)
- ok  #2 Abnahmefaktor · Abnahme um 15 %: 15/100 = 3/20 (soll 3/20)
- ok  #2 Abnahmefaktor · Abnahme um 15 %: 1+15/100 = 23/20 (soll 23/20)
- ok  #3 Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte: round(500*1.06^4,2) = 15781/25 (soll 15781/25)
- ok  #3 Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte: 500+4*500*6/100 = 620 (soll 620)
- ok  #3 Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte: 500*1.06*4 = 2120 (soll 2120)
- ok  #3 Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte: round(500*1.6^4,2) = 16384/5 (soll 16384/5)
- ok  #4 Exponentiell fortsetzen · 40, 60, 90, …: 90*(60/40)^2 = 405/2 (soll 405/2)
- ok  #4 Exponentiell fortsetzen · 40, 60, 90, …: 90+2*(90-60) = 150 (soll 150)
- ok  #4 Exponentiell fortsetzen · 40, 60, 90, …: 90*(60/40)*2 = 270 (soll 270)
- ok  #5 Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88: (1-0.88)*100 = 12 (soll 12)
- ok  #5 Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88: 0.88*100 = 88 (soll 88)
- ok  #6 Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre: round(2000*1.03^5-(2000+5*2000*3/100),2) = 371/20 (soll 371/20)
- ok  #6 Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre: round(2000*1.03^5,2) = 46371/20 (soll 46371/20)
- ok  #6 Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre: round(2000*1.03^5-2000,2) = 6371/20 (soll 6371/20)
- ok  #6 Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre: round(2000*1.3^5-(2000+5*2000*3/100),2) = 256293/50 (soll 256293/50)
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 1: 250 = 250 (soll 250)
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 1: 1.08 = 27/25 (soll 27/25)
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 2: (1.08-1)*100 = 8 (soll 8)
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 2: 1.08*100 = 108 (soll 108)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 1: 200 = 200 (soll 200)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 1: 1-10/100 = 9/10 (soll 9/10)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 2: 1-10/100 = 9/10 (soll 9/10)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 2: 10/100 = 1/10 (soll 1/10)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 2: 1+10/100 = 11/10 (soll 11/10)
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 2: 200 = 200 (soll 200)
- ok  #9 Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ: 80*1/0.5^2 = 320 (soll 320)
- ok  #9 Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ: 80*(0-0.5^2) = -20 (soll -20)
- ok  #9 Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ: 80*0.5*(0-2) = -80 (soll -80)
- ok  #10 Punkte ablesen · f(3) aus zwei Punkten des Graphen: 2*3^3 = 54 (soll 54)
- ok  #10 Punkte ablesen · f(3) aus zwei Punkten des Graphen: 3*2^3 = 24 (soll 24)
- ok  #10 Punkte ablesen · f(3) aus zwei Punkten des Graphen: 2+3*(6-2) = 14 (soll 14)
- ok  #10 Punkte ablesen · f(3) aus zwei Punkten des Graphen: 2*3*3 = 18 (soll 18)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 1: 3/(2) = 3/2 (soll 3/2)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 1: 3/(12/3) = 3/4 (soll 3/4)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 1: (2) = 2 (soll 2)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 2: (2) = 2 (soll 2)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 2: 12/3 = 4 (soll 4)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 2: (12-3)/(3-1) = 9/2 (soll 9/2)
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 2: 3/(2) = 3/2 (soll 3/2)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 1: 360/((3/2))^2 = 160 (soll 160)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 1: 360-(810-360) = -90 (soll -90)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 1: (3/2) = 3/2 (soll 3/2)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 2: (3/2) = 3/2 (soll 3/2)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 2: 810/360 = 9/4 (soll 9/4)
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 2: 360/((3/2))^2 = 160 (soll 160)
- ok  #13 Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren: 64*((1/2)^3) = 8 (soll 8)
- ok  #13 Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren: 64*0.5^15 = 1/512 (soll 1/512)
- ok  #13 Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren: 64*0.5*3 = 96 (soll 96)
- ok  #14 Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden: 300*((2/1)^3) = 2400 (soll 2400)
- ok  #14 Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden: 300*2^12 = 1228800 (soll 1228800)
- ok  #14 Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden: 300+3*300 = 1200 (soll 1200)
- ok  #14 Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden: 300*2*3 = 1800 (soll 1800)
- ok  #15 Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage: 8*4 = 32 (soll 32)
- ok  #15 Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage: 4 = 4 (soll 4)
- ok  #16 Verdopplung durch Probieren · 12 % pro Jahr: round((1386294361119890618834464242916353136151/2000000000000000000000000000000000000000)/(1133286853070031747382983199071575867369/10000000000000000000000000000000000000000),4) = 61163/10000 (soll 61163/10000)
- ok  #16 Verdopplung durch Probieren · 12 % pro Jahr: round(100/12,4) = 83333/10000 (soll 83333/10000)
- ok  #16 Verdopplung durch Probieren · 12 % pro Jahr: round((1386294361119890618834464242916353136151/2000000000000000000000000000000000000000)/(911607783969773131058590125772573165987/5000000000000000000000000000000000000000),4) = 19009/5000 (soll 19009/5000)
- ok  #17 Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden: 12/3 = 4 (soll 4)
- ok  #17 Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden: 3 = 3 (soll 3)
- ok  #17 Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden: round(12*50/87.5,2) = 343/50 (soll 343/50)
- ok  #18 Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren: round(500*(5039684199579492659068842429112913402281/500000000000000000000000000000000000000),0) = 5040 (soll 5040)
- ok  #18 Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren: round(500*2^10,0) = 512000 (soll 512000)
- ok  #18 Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren: round(500+500*10/3,0) = 2167 (soll 2167)
- ok  #18 Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren: round(500*(12570133745218283521861316893273405563761/1250000000000000000000000000000000000000),0) = 5028 (soll 5028)
- ok  #19 Probieren · 3ˣ = 81: 4 = 4 (soll 4)
- ok  #19 Probieren · 3ˣ = 81: 81/3 = 27 (soll 27)
- ok  #20 Probieren mit negativer Lösung · 2ˣ = 1/8: 0-3 = -3 (soll -3)
- ok  #20 Probieren mit negativer Lösung · 2ˣ = 1/8: 3 = 3 (soll 3)
- ok  #20 Probieren mit negativer Lösung · 2ˣ = 1/8: 1/8/2 = 1/16 (soll 1/16)
- ok  #21 Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20: round((14978661367769954967176117880712703878383/5000000000000000000000000000000000000000)/(101366277027041095494503278866087284143/250000000000000000000000000000000000000),2) = 739/100 (soll 739/100)
- ok  #21 Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20: round(20/1.5,2) = 1333/100 (soll 1333/100)
- ok  #21 Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20: round((101366277027041095494503278866087284143/250000000000000000000000000000000000000)/(14978661367769954967176117880712703878383/5000000000000000000000000000000000000000),2) = 7/50 (soll 7/50)
- ok  #22 Logarithmus · 2,5 · 1,04ˣ = 4: round((4700036292457355536509370311483420647009/10000000000000000000000000000000000000000)/(49025891441601620336501120713899867287/1250000000000000000000000000000000000000),2) = 599/50 (soll 599/50)
- ok  #22 Logarithmus · 2,5 · 1,04ˣ = 4: round((1386294361119890618834464242916353136151/1000000000000000000000000000000000000000)/(9555114450274363614527281083391309652797/10000000000000000000000000000000000000000),2) = 29/20 (soll 29/20)
- ok  #22 Logarithmus · 2,5 · 1,04ˣ = 4: round(4/2.5/1.04,2) = 77/50 (soll 77/50)
- ok  #23 Rückrichtung · 2ˣ = c hat die Lösung x = −4: 1/2^4 = 1/16 (soll 1/16)
- ok  #23 Rückrichtung · 2ˣ = c hat die Lösung x = −4: 0-2^4 = -16 (soll -16)
- ok  #23 Rückrichtung · 2ˣ = c hat die Lösung x = −4: 2*(0-4) = -8 (soll -8)
- ok  #24 Erst teilen, dann probieren · 3 · 2ˣ = 3/32: 0-5 = -5 (soll -5)
- ok  #24 Erst teilen, dann probieren · 3 · 2ˣ = 3/32: 5 = 5 (soll 5)
- ok  #24 Erst teilen, dann probieren · 3 · 2ˣ = 3/32: round((0-236712361413161685569091537036835713573/100000000000000000000000000000000000000)/(1791759469228055000812477358380702272723/1000000000000000000000000000000000000000),2) = -33/25 (soll -33/25)
- ok  #24 Erst teilen, dann probieren · 3 · 2ˣ = 3/32: 1/32/2 = 1/64 (soll 1/64)
- ok  #25 Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €: round((101366277027041095494503278866087284143/250000000000000000000000000000000000000)/(3049385260589500191585900263947791163/62500000000000000000000000000000000000),4) = 5194/625 (soll 5194/625)
- ok  #25 Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €: (1500-1000)/(1000*5/100) = 10 (soll 10)
- ok  #25 Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €: round((101366277027041095494503278866087284143/250000000000000000000000000000000000000)/(101366277027041095494503278866087284143/250000000000000000000000000000000000000),4) = 1 (soll 1)
- ok  #26 Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg: round((0-1386294361119890618834464242916353136151/1000000000000000000000000000000000000000)/(0-406297323744437282964222395673535600221/2500000000000000000000000000000000000000),4) = 853/100 (soll 853/100)
- ok  #26 Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg: round((0-1386294361119890618834464242916353136151/1000000000000000000000000000000000000000)/(0-18971199848858813020399783392200150710291/10000000000000000000000000000000000000000),4) = 7307/10000 (soll 7307/10000)
- ok  #26 Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg: (80-20)/(80*15/100) = 5 (soll 5)
- ok  #27 Bestand · Fische, jedes Jahr auf 80 %, unter 500: round((0-1386294361119890618834464242916353136151/1000000000000000000000000000000000000000)/(0-1115717756571048778831475451549172516873/5000000000000000000000000000000000000000),4) = 31063/5000 (soll 31063/5000)
- ok  #27 Bestand · Fische, jedes Jahr auf 80 %, unter 500: round((0-1386294361119890618834464242916353136151/1000000000000000000000000000000000000000)/(0-2011797390542625468250949166532734549407/1250000000000000000000000000000000000000),4) = 4307/5000 (soll 4307/5000)
- ok  #27 Bestand · Fische, jedes Jahr auf 80 %, unter 500: round((2000-500)/(2000-0.8*2000),4) = 15/4 (soll 15/4)
- ok  #28 Zerfall · Halbwertszeit 6 Stunden, unter 10 %: round(6*(0-23025850929940456840179914546843642076011/10000000000000000000000000000000000000000)/(0-1386294361119890618834464242916353136151/2000000000000000000000000000000000000000),4) = 49829/2500 (soll 49829/2500)
- ok  #28 Zerfall · Halbwertszeit 6 Stunden, unter 10 %: round((0-23025850929940456840179914546843642076011/10000000000000000000000000000000000000000)/(0-1386294361119890618834464242916353136151/2000000000000000000000000000000000000000),4) = 33219/10000 (soll 33219/10000)
- ok  #28 Zerfall · Halbwertszeit 6 Stunden, unter 10 %: round(6*0.9/0.5,4) = 54/5 (soll 54/5)
- ok  #29 Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl: round(2020+(235566071312766909077588218941043410137/2000000000000000000000000000000000000000)/(148886124937506548354097449781863518539/10000000000000000000000000000000000000000),4) = 20279109/10000 (soll 20279109/10000)
- ok  #29 Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl: round((235566071312766909077588218941043410137/2000000000000000000000000000000000000000)/(148886124937506548354097449781863518539/10000000000000000000000000000000000000000),4) = 79109/10000 (soll 79109/10000)
- ok  #29 Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl: round(2020+(9000-8000)/(8000*1.5/100),4) = 20283333/10000 (soll 20283333/10000)
- ok  #30 Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %: round((9162907318741550651835272117680110714501/10000000000000000000000000000000000000000)/(118505597236459805628994096576223573663/2500000000000000000000000000000000000000),4) = 193301/10000 (soll 193301/10000)
- ok  #30 Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %: round((9162907318741550651835272117680110714501/10000000000000000000000000000000000000000)/(3049385260589500191585900263947791163/62500000000000000000000000000000000000),4) = 93901/5000 (soll 93901/5000)
- ok  #30 Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %: (5000-2000)/(2000*8/100-5000*3/100)+1 = 301 (soll 301)

## Blind-Abgleich (docs/prefill/k10-exp-blind.json)

- ok  #1 Wachstumsfaktor · Zunahme um 4 %: Loeser 1.04 · gespeichert ["1,04","+1,04","1.04","+1.04"]
- ok  #2 Abnahmefaktor · Abnahme um 15 %: Loeser 0.85 · gespeichert ["0,85","+0,85","0.85","+0.85"]
- ok  #3 Fortschreiben · 500 bei 6 % Zunahme, 4 Schritte: Loeser 631.24 · gespeichert ["631,24","+631,24","631.24","+631.24"]
- ok  #4 Exponentiell fortsetzen · 40, 60, 90, …: Loeser 202.5 · gespeichert ["202,5","+202,5","202.5","+202.5"]
- ok  #5 Prozentsatz aus Faktor · Wert einer Maschine, Faktor 0,88: Loeser 12 · gespeichert ["12","12 %","12%"]
- ok  #6 Zinseszins gegen einfache Zinsen · 2000 € zu 3 %, 5 Jahre: Loeser 18.55 · gespeichert ["18,55","18.55","18,55 €","18,55€"]
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 1: Loeser 250 · gespeichert ["250","+250"]
- ok  #7 Term lesen · f(x) = 250 · 1,08ˣ Teil 2: Loeser 8 · gespeichert ["8","+8"]
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 1: Loeser 200 · gespeichert ["200","+200"]
- ok  #8 Term aufstellen · Anfangswert 200, Abnahme 10 % Teil 2: Loeser 0.9 · gespeichert ["0,9","+0,9","0.9","+0.9"]
- ok  #9 Funktionswert · f(−2) bei f(x) = 80 · 0,5ˣ: Loeser 320 · gespeichert ["320","+320"]
- ok  #10 Punkte ablesen · f(3) aus zwei Punkten des Graphen: Loeser 54 · gespeichert ["54","+54"]
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 1: Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5","3/2","+3/2"]
- ok  #11 Term aus zwei Punkten · Abbildung, Punkte bei x = 1 und x = 3 Teil 2: Loeser 2 · gespeichert ["2","+2"]
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 1: Loeser 160 · gespeichert ["160","+160"]
- ok  #12 Term aufstellen · Bakterien nach 2 und 4 Stunden Teil 2: Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5"]
- ok  #13 Halbwertszeit · 64 g, 5 Jahre, nach 15 Jahren: Loeser 8 · gespeichert ["8","8 g","8g"]
- ok  #14 Verdopplungszeit · 300, alle 4 Stunden, nach 12 Stunden: Loeser 2400 · gespeichert ["2400","+2400"]
- ok  #15 Zeit aus Menge · 400 mg auf 25 mg, Halbwertszeit 8 Tage: Loeser 32 · gespeichert ["32","32 Tage","32Tage"]
- ok  #16 Verdopplung durch Probieren · 12 % pro Jahr: Loeser 7 · gespeichert ["7","7 Jahre","7Jahre"]
- ok  #17 Halbwertszeit bestimmen · Medikament, 12,5 % nach 12 Stunden: Loeser 4 · gespeichert ["4","4 h","4h"]
- ok  #18 Verdopplungszeit · Population 500, alle 3 Jahre, nach 10 Jahren: Loeser 5040 · gespeichert ["5040","+5040"]
- ok  #19 Probieren · 3ˣ = 81: Loeser 4 · gespeichert ["4","+4"]
- ok  #20 Probieren mit negativer Lösung · 2ˣ = 1/8: Loeser -3 · gespeichert ["-3","−3","- 3"]
- ok  #21 Logarithmus · Bakterien verzwanzigfachen sich, 1,5ˣ = 20: Loeser 7.39 · gespeichert ["7,39","+7,39","7.39","+7.39"]
- ok  #22 Logarithmus · 2,5 · 1,04ˣ = 4: Loeser 11.98 · gespeichert ["11,98","+11,98","11.98","+11.98"]
- ok  #23 Rückrichtung · 2ˣ = c hat die Lösung x = −4: Loeser 0.0625 · gespeichert ["0,0625","+0,0625","0.0625","+0.0625","1/16","+1/16"]
- ok  #24 Erst teilen, dann probieren · 3 · 2ˣ = 3/32: Loeser -5 · gespeichert ["-5","−5","- 5"]
- ok  #25 Kapital · 1000 € zu 5 %, erstmals mindestens 1500 €: Loeser 9 · gespeichert ["9","9 Jahre","9Jahre"]
- ok  #26 Abbau · 80 mg, 15 % pro Stunde, höchstens 20 mg: Loeser 9 · gespeichert ["9","9 h","9h"]
- ok  #27 Bestand · Fische, jedes Jahr auf 80 %, unter 500: Loeser 7 · gespeichert ["7","7 Jahre","7Jahre"]
- ok  #28 Zerfall · Halbwertszeit 6 Stunden, unter 10 %: Loeser 20 · gespeichert ["20","20 h","20h"]
- ok  #29 Einwohner · Gemeinde 8000, 1,5 % pro Jahr, Jahreszahl: Loeser 2028 · gespeichert ["2028","+2028"]
- ok  #30 Zwei Anlagen · 2000 € zu 8 % überholt 5000 € zu 3 %: Loeser 20 · gespeichert ["20","20 Jahre","20Jahre"]
