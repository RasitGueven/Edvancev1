# Verifikation k9-bedingt

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
| parts[].afb | 28 | 0 | 0 | 0 |
| parts[].competency_content | 28 | 0 | 0 | 0 |
| correct_answers[].antwort | 28 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| correct_answers | 18 | 0 | 0 | 0 |

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
| parts[].afb | 28 | 28 | 0 | 0 |
| parts[].competency_content | 28 | 28 | 0 | 0 |
| parts[].antwort | 28 | 28 | 0 | 0 |
| tasks.competency_content | 18 | 18 | 0 | 0 |
| tasks.competency_process | 18 | 18 | 0 | 0 |
| task_solutions.correct_answers | 18 | 18 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 1: 110-48 = 62 (soll 62)
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 1: 108-48 = 60 (soll 60)
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 1: 110+48 = 158 (soll 158)
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 2: 108-48 = 60 (soll 60)
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 2: 110-48 = 62 (soll 62)
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 2: 108+48 = 156 (soll 156)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 1: 160-72 = 88 (soll 88)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 1: 126-72 = 54 (soll 54)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 1: 160+72 = 232 (soll 232)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 2: 126-72 = 54 (soll 54)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 2: 160-72 = 88 (soll 88)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 2: 126+72 = 198 (soll 198)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 3: 300-160-(126-72) = 86 (soll 86)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 3: 300-160 = 140 (soll 140)
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 3: 126-(126-72) = 72 (soll 72)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 1: 140-86 = 54 (soll 54)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 1: 120-86 = 34 (soll 34)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 1: 140+86 = 226 (soll 226)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 2: round((140-86)/250,2) = 11/50 (soll 11/50)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 2: round((120-86)/250,2) = 7/50 (soll 7/50)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 2: round(250/(140-86),2) = 463/100 (soll 463/100)
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 2: round((140-86)/250*100,1) = 108/5 (soll 108/5)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 1: 400*60/100*5/100 = 12 (soll 12)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 1: 400*5/100 = 20 (soll 20)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 1: 400*60/100*50/100 = 120 (soll 120)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 2: 26-400*60/100*5/100 = 14 (soll 14)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 2: 26+400*60/100*5/100 = 38 (soll 38)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 2: 26-400*5/100 = 6 (soll 6)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 3: 400*40/100-(26-400*60/100*5/100) = 146 (soll 146)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 3: (400-26)-(26-400*60/100*5/100) = 360 (soll 360)
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 3: 400*40/100 = 160 (soll 160)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 1: 0.65-0.18 = 47/100 (soll 47/100)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 1: 0.30-0.18 = 3/25 (soll 3/25)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 1: 0.65+0.18 = 83/100 (soll 83/100)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 2: 0.30-0.18 = 3/25 (soll 3/25)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 2: 0.65-0.18 = 47/100 (soll 47/100)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 2: 0.30+0.18 = 12/25 (soll 12/25)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 3: 1-0.65-(0.30-0.18) = 23/100 (soll 23/100)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 3: 1-0.65 = 7/20 (soll 7/20)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 3: (1-0.30)-(0.30-0.18) = 29/50 (soll 29/50)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 4: 400*(0.30-0.18) = 48 (soll 48)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 4: 400*(0.65-0.18) = 188 (soll 188)
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 4: 400*1.2 = 480 (soll 480)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 1: 33-150*40/100*25/100 = 18 (soll 18)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 1: 150*40/100-150*40/100*25/100 = 45 (soll 45)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 1: 33+150*40/100*25/100 = 48 (soll 48)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 2: 150-150*40/100-(33-150*40/100*25/100) = 72 (soll 72)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 2: 150-33 = 117 (soll 117)
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 2: 150-33-(33-150*40/100*25/100) = 99 (soll 99)
- ok  #7 P(Haustier | Junge) · Dezimalzahl: round(60/90,2) = 67/100 (soll 67/100)
- ok  #7 P(Haustier | Junge) · Dezimalzahl: round(60/200,2) = 3/10 (soll 3/10)
- ok  #7 P(Haustier | Junge) · Dezimalzahl: round(60/108,2) = 14/25 (soll 14/25)
- ok  #7 P(Haustier | Junge) · Dezimalzahl: round(90/60,2) = 3/2 (soll 3/2)
- ok  #8 P(Lieferant B | fehlerhaft) · Prozent: round(11/29*100,1) = 379/10 (soll 379/10)
- ok  #8 P(Lieferant B | fehlerhaft) · Prozent: round(11/500*100,1) = 11/5 (soll 11/5)
- ok  #8 P(Lieferant B | fehlerhaft) · Prozent: round(11/200*100,1) = 11/2 (soll 11/2)
- ok  #8 P(Lieferant B | fehlerhaft) · Prozent: round(29/11*100,1) = 1318/5 (soll 1318/5)
- ok  #9 P(Schwimmen | Erwachsene) · gekürzter Bruch: 18/50 = 9/25 (soll 9/25)
- ok  #9 P(Schwimmen | Erwachsene) · gekürzter Bruch: 18/120 = 3/20 (soll 3/20)
- ok  #9 P(Schwimmen | Erwachsene) · gekürzter Bruch: 18/60 = 3/10 (soll 3/10)
- ok  #9 P(Schwimmen | Erwachsene) · gekürzter Bruch: 50/18 = 25/9 (soll 25/9)
- ok  #10 P(Popcorn | Kind) · erst ergänzen: round((105-45)/(250-150),2) = 3/5 (soll 3/5)
- ok  #10 P(Popcorn | Kind) · erst ergänzen: round((105-45)/250,2) = 6/25 (soll 6/25)
- ok  #10 P(Popcorn | Kind) · erst ergänzen: round((105-45)/105,2) = 57/100 (soll 57/100)
- ok  #10 P(Popcorn | Kind) · erst ergänzen: round((105-45)/(250-105),2) = 41/100 (soll 41/100)
- ok  #11 Bibliothek · verlängerte Romane in Prozent: round((180-96)/(600-240)*100,1) = 233/10 (soll 233/10)
- ok  #11 Bibliothek · verlängerte Romane in Prozent: round((180-96)/600*100,1) = 14 (soll 14)
- ok  #11 Bibliothek · verlängerte Romane in Prozent: round((180-96)/180*100,1) = 467/10 (soll 467/10)
- ok  #11 Bibliothek · verlängerte Romane in Prozent: round((600-240)/(180-96)*100,1) = 2143/5 (soll 2143/5)
- ok  #12 Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge): round(100*70/100/160,2) = 11/25 (soll 11/25)
- ok  #12 Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge): round(70/100,2) = 7/10 (soll 7/10)
- ok  #12 Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge): round(100*70/100/250,2) = 7/25 (soll 7/25)
- ok  #12 Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge): round(100*70/100,2) = 70 (soll 70)
- ok  #13 Erwartete Anzahl bei Unabhängigkeit: 120*90/200 = 54 (soll 54)
- ok  #13 Erwartete Anzahl bei Unabhängigkeit: 120/200*90/200 = 27/100 (soll 27/100)
- ok  #13 Erwartete Anzahl bei Unabhängigkeit: 200*(120/200+90/200) = 210 (soll 210)
- ok  #14 P(A | B) und P(A) vergleichen · Prozentpunkte: round(63/120*100-90/200*100,1) = 15/2 (soll 15/2)
- ok  #14 P(A | B) und P(A) vergleichen · Prozentpunkte: round(90/200*100-63/200*100,1) = 27/2 (soll 27/2)
- ok  #14 P(A | B) und P(A) vergleichen · Prozentpunkte: round(63/90*100-120/200*100,1) = 10 (soll 10)
- ok  #15 Fehlende Zahl für Unabhängigkeit · Pflanzen: 120*117/180 = 78 (soll 78)
- ok  #15 Fehlende Zahl für Unabhängigkeit · Pflanzen: 117 = 117 (soll 117)
- ok  #15 Fehlende Zahl für Unabhängigkeit · Pflanzen: 117/300*120 = 234/5 (soll 234/5)
- ok  #16 Befall im Gewächshaus und Freiland · Prozentpunkte: round(24/90*100-18/150*100,1) = 147/10 (soll 147/10)
- ok  #16 Befall im Gewächshaus und Freiland · Prozentpunkte: round(24-18,1) = 6 (soll 6)
- ok  #16 Befall im Gewächshaus und Freiland · Prozentpunkte: round(24/240*100-18/240*100,1) = 5/2 (soll 5/2)
- ok  #16 Befall im Gewächshaus und Freiland · Prozentpunkte: round(27-12,1) = 15 (soll 15)
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 1: 400*35/100*55/100 = 77 (soll 77)
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 1: 35/100*55/100 = 77/400 (soll 77/400)
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 1: 400*(35+55)/100 = 360 (soll 360)
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 2: 95-400*35/100*55/100 = 18 (soll 18)
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 2: 95+400*35/100*55/100 = 172 (soll 172)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 1: (500-200)*30/100 = 90 (soll 90)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 1: 200*30/100 = 60 (soll 60)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 1: 500*30/100 = 150 (soll 150)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 2: 30-(114-200*30/100)/(500-200)*100 = 12 (soll 12)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 2: 200*30/100-(114-200*30/100) = 6 (soll 6)
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 2: 200*30/100/500*100-(114-200*30/100)/500*100 = 6/5 (soll 6/5)
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 1: 1000*2/100 = 20 (soll 20)
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 1: 1000*20/100 = 200 (soll 200)
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 2: 1000*2/100*90/100 = 18 (soll 18)
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 2: 1000*90/100 = 900 (soll 900)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 1: 5000-5000*4/100 = 4800 (soll 4800)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 1: 5000*4/100 = 200 (soll 200)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 1: 5000-5000*40/100 = 3000 (soll 3000)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 2: (5000-5000*4/100)*3/100 = 144 (soll 144)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 2: 5000*3/100 = 150 (soll 150)
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 2: (5000-5000*4/100)*30/100 = 1440 (soll 1440)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 1: 1000*2/100*90/100+1000*98/100*5/100 = 67 (soll 67)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 1: 1000*2/100*90/100+1000*5/100 = 68 (soll 68)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 1: 1000*2/100*90/100 = 18 (soll 18)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 2: round(18/67*100,1) = 269/10 (soll 269/10)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 2: round(90,1) = 90 (soll 90)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 2: round(18/1000*100,1) = 9/5 (soll 9/5)
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 2: round(18/68*100,1) = 53/2 (soll 53/2)
- ok  #22 Schnelltest · 1 % Befall, Anteil wirklich befallen: round(10000*1/100*95/100/(10000*1/100*95/100+10000*99/100*2/100)*100,1) = 162/5 (soll 162/5)
- ok  #22 Schnelltest · 1 % Befall, Anteil wirklich befallen: round(95,1) = 95 (soll 95)
- ok  #22 Schnelltest · 1 % Befall, Anteil wirklich befallen: round(10000*1/100*95/100/10000*100,2) = 19/20 (soll 19/20)
- ok  #22 Schnelltest · 1 % Befall, Anteil wirklich befallen: round(95/(95+10000*2/100)*100,1) = 161/5 (soll 161/5)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 1: 2000*5/100*80/100+2000*95/100*4/100 = 156 (soll 156)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 1: 2000*5/100*80/100+2000*4/100 = 160 (soll 160)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 1: 2000*5/100*80/100 = 80 (soll 80)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 2: round(80/156*100,1) = 513/10 (soll 513/10)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 2: round(80,1) = 80 (soll 80)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 2: round(80/2000*100,1) = 4 (soll 4)
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 2: round(156/80*100,1) = 195 (soll 195)
- ok  #24 Schweißnähte · Anteil echter Fehler ohne Gesamtzahl: round(1000*4/100*95/100/(1000*4/100*95/100+1000*96/100*10/100)*100,1) = 142/5 (soll 142/5)
- ok  #24 Schweißnähte · Anteil echter Fehler ohne Gesamtzahl: round(95,1) = 95 (soll 95)
- ok  #24 Schweißnähte · Anteil echter Fehler ohne Gesamtzahl: round(1000*4/100*95/100/1000*100,1) = 19/5 (soll 19/5)
- ok  #24 Schweißnähte · Anteil echter Fehler ohne Gesamtzahl: round(38/(38+1000*10/100)*100,1) = 55/2 (soll 55/2)
- ok  #25 Abgeschnittene Achse · gezeichnetes Verhältnis: (52-44)/(48-44) = 2 (soll 2)
- ok  #25 Abgeschnittene Achse · gezeichnetes Verhältnis: round(52/48,2) = 27/25 (soll 27/25)
- ok  #25 Abgeschnittene Achse · gezeichnetes Verhältnis: round(52/48,1) = 11/10 (soll 11/10)
- ok  #25 Abgeschnittene Achse · gezeichnetes Verhältnis: 52-48 = 4 (soll 4)
- ok  #26 Abgeschnittene Achse · tatsächliches Verhältnis: round(75/60,2) = 5/4 (soll 5/4)
- ok  #26 Abgeschnittene Achse · tatsächliches Verhältnis: round((75-50)/(60-50),2) = 5/2 (soll 5/2)
- ok  #26 Abgeschnittene Achse · tatsächliches Verhältnis: round(75-60,2) = 15 (soll 15)
- ok  #26 Abgeschnittene Achse · tatsächliches Verhältnis: round(60/75,2) = 4/5 (soll 4/5)
- ok  #27 Absolut oder relativ · Radfahrer an zwei Schulen: 22/88*100-36/240*100 = 10 (soll 10)
- ok  #27 Absolut oder relativ · Radfahrer an zwei Schulen: 36-22 = 14 (soll 14)
- ok  #27 Absolut oder relativ · Radfahrer an zwei Schulen: 22/88-36/240 = 1/10 (soll 1/10)
- ok  #28 Schlagzeile mit vertauschter Bedingung · Kettenriss: round(30/400*100,1) = 15/2 (soll 15/2)
- ok  #28 Schlagzeile mit vertauschter Bedingung · Kettenriss: round(30/40*100,1) = 75 (soll 75)
- ok  #28 Schlagzeile mit vertauschter Bedingung · Kettenriss: round(30/1200*100,1) = 5/2 (soll 5/2)
- ok  #28 Schlagzeile mit vertauschter Bedingung · Kettenriss: round(30,1) = 30 (soll 30)
- ok  #29 Absolut oder relativ · Diebstähle je 1000 Einwohner: 18/4000*1000-45/15000*1000 = 3/2 (soll 3/2)
- ok  #29 Absolut oder relativ · Diebstähle je 1000 Einwohner: 45-18 = 27 (soll 27)
- ok  #29 Absolut oder relativ · Diebstähle je 1000 Einwohner: 18/4000-45/15000 = 3/2000 (soll 3/2000)
- ok  #30 Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis: (3*54-66)/2 = 48 (soll 48)
- ok  #30 Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis: 0 = 0 (soll 0)
- ok  #30 Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis: 3*54-66 = 96 (soll 96)

## Blind-Abgleich (docs/prefill/k9-bedingt-blind.json)

- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 1: Loeser 62 · gespeichert ["62","+62"]
- ok  #1 Vierfeldertafel · Haustier, zwei Felder Teil 2: Loeser 60 · gespeichert ["60","+60"]
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 1: Loeser 88 · gespeichert ["88","+88"]
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 2: Loeser 54 · gespeichert ["54","+54"]
- ok  #2 Vierfeldertafel · Bus und Stufe, drei Felder Teil 3: Loeser 86 · gespeichert ["86","+86"]
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 1: Loeser 54 · gespeichert ["54","+54"]
- ok  #3 Vierfeldertafel · Feld und relative Häufigkeit Teil 2: Loeser 0.22 · gespeichert ["0,22","+0,22","0.22","+0.22"]
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 1: Loeser 12 · gespeichert ["12","+12"]
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 2: Loeser 14 · gespeichert ["14","+14"]
- ok  #4 Vierfeldertafel · aus Prozentangaben, Werkstücke Teil 3: Loeser 146 · gespeichert ["146","+146"]
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 1: Loeser 0.47 · gespeichert ["0,47","+0,47","0.47","+0.47"]
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 2: Loeser 0.12 · gespeichert ["0,12","+0,12","0.12","+0.12"]
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 3: Loeser 0.23 · gespeichert ["0,23","+0,23","0.23","+0.23"]
- ok  #5 Vierfeldertafel · relative Häufigkeiten, Verkehrszählung Teil 4: Loeser 48 · gespeichert ["48","+48"]
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 1: Loeser 18 · gespeichert ["18","+18"]
- ok  #6 Vierfeldertafel · Instrument und Chor aus Prozentangaben Teil 2: Loeser 72 · gespeichert ["72","+72"]
- ok  #7 P(Haustier | Junge) · Dezimalzahl: Loeser 0.67 · gespeichert ["0,67","+0,67","0.67","+0.67"]
- ok  #8 P(Lieferant B | fehlerhaft) · Prozent: Loeser 37.9 · gespeichert ["37,9","+37,9","37.9","+37.9"]
- ok  #9 P(Schwimmen | Erwachsene) · gekürzter Bruch: Loeser 0.36 · gespeichert ["0,36","+0,36","0.36","+0.36","9/25","+9/25"]
- ok  #10 P(Popcorn | Kind) · erst ergänzen: Loeser 0.60 · gespeichert ["0,60","+0,60","0.60","+0.60","0,6","+0,6","0.6","+0.6"]
- ok  #11 Bibliothek · verlängerte Romane in Prozent: Loeser 23.3 · gespeichert ["23,3","+23,3","23.3","+23.3"]
- ok  #12 Rückrichtung · P(Junge | Haustier) aus P(Haustier | Junge): Loeser 0.44 · gespeichert ["0,44","+0,44","0.44","+0.44"]
- ok  #13 Erwartete Anzahl bei Unabhängigkeit: Loeser 54 · gespeichert ["54","+54"]
- ok  #14 P(A | B) und P(A) vergleichen · Prozentpunkte: Loeser 7.5 · gespeichert ["7,5","+7,5","7.5","+7.5"]
- ok  #15 Fehlende Zahl für Unabhängigkeit · Pflanzen: Loeser 78 · gespeichert ["78","+78"]
- ok  #16 Befall im Gewächshaus und Freiland · Prozentpunkte: Loeser 14.7 · gespeichert ["14,7","+14,7","14.7","+14.7"]
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 1: Loeser 77 · gespeichert ["77","+77"]
- ok  #17 Mensa und Unterstufe · Erwartung und Abweichung Teil 2: Loeser 18 · gespeichert ["18","+18"]
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 1: Loeser 90 · gespeichert ["90","+90"]
- ok  #18 Garten und Lastenrad · Unabhängigkeit und Abstand Teil 2: Loeser 12 · gespeichert ["12","+12"]
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 1: Loeser 20 · gespeichert ["20","+20"]
- ok  #19 Schnelltest · befallene und erkannte Proben Teil 2: Loeser 18 · gespeichert ["18","+18"]
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 1: Loeser 4800 · gespeichert ["4800","+4800"]
- ok  #20 Prüfgerät · intakte Teile und Fehlalarme Teil 2: Loeser 144 · gespeichert ["144","+144"]
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 1: Loeser 67 · gespeichert ["67","+67"]
- ok  #21 Schnelltest · positive Tests und Anteil wirklich befallen Teil 2: Loeser 26.9 · gespeichert ["26,9","+26,9","26.9","+26.9"]
- ok  #22 Schnelltest · 1 % Befall, Anteil wirklich befallen: Loeser 32.4 · gespeichert ["32,4","+32,4","32.4","+32.4"]
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 1: Loeser 156 · gespeichert ["156","+156"]
- ok  #23 Saatgut · positive Tests und Anteil befallen Teil 2: Loeser 51.3 · gespeichert ["51,3","+51,3","51.3","+51.3"]
- ok  #24 Schweißnähte · Anteil echter Fehler ohne Gesamtzahl: Loeser 28.4 · gespeichert ["28,4","+28,4","28.4","+28.4"]
- ok  #25 Abgeschnittene Achse · gezeichnetes Verhältnis: Loeser 2 · gespeichert ["2","+2"]
- ok  #26 Abgeschnittene Achse · tatsächliches Verhältnis: Loeser 1.25 · gespeichert ["1,25","+1,25","1.25","+1.25"]
- ok  #27 Absolut oder relativ · Radfahrer an zwei Schulen: Loeser 10 · gespeichert ["10","+10"]
- ok  #28 Schlagzeile mit vertauschter Bedingung · Kettenriss: Loeser 7.5 · gespeichert ["7,5","+7,5","7.5","+7.5"]
- ok  #29 Absolut oder relativ · Diebstähle je 1000 Einwohner: Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5"]
- ok  #30 Rückrichtung · Achsenbeginn aus dem gezeichneten Verhältnis: Loeser 48 · gespeichert ["48","+48"]
