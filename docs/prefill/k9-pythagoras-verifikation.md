# Verifikation k9-pythagoras

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

- ok  #1 Hypotenuse · Katheten 6 cm und 8 cm: (10) = 10 (soll 10)
- ok  #1 Hypotenuse · Katheten 6 cm und 8 cm: 6^2+8^2 = 100 (soll 100)
- ok  #1 Hypotenuse · Katheten 6 cm und 8 cm: 6+8 = 14 (soll 14)
- ok  #1 Hypotenuse · Katheten 6 cm und 8 cm: round((52915026221291811810032315072785208514205/10000000000000000000000000000000000000000),2) = 529/100 (soll 529/100)
- ok  #2 Hypotenuse · Katheten 5 cm und 7 cm, gerundet: round((86023252670426267717294735350497136320275/10000000000000000000000000000000000000000),2) = 43/5 (soll 43/5)
- ok  #2 Hypotenuse · Katheten 5 cm und 7 cm, gerundet: 5^2+7^2 = 74 (soll 74)
- ok  #2 Hypotenuse · Katheten 5 cm und 7 cm, gerundet: 5+7 = 12 (soll 12)
- ok  #2 Hypotenuse · Katheten 5 cm und 7 cm, gerundet: round((48989794855663561963945681494117827839318/10000000000000000000000000000000000000000),2) = 49/10 (soll 49/10)
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: (15/2) = 15/2 (soll 15/2)
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: 4.5^2+6^2 = 225/4 (soll 225/4)
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: 4.5+6 = 21/2 (soll 21/2)
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: round((45825756949558400065880471937280084889844/10000000000000000000000000000000000000000),2) = 229/50 (soll 229/50)
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: round((158745078663875435430096945218355625542615/40000000000000000000000000000000000000000),2) = 397/100 (soll 397/100)
- ok  #4 Hypotenuse · Katheten 12 cm und 0,35 m: (37) = 37 (soll 37)
- ok  #4 Hypotenuse · Katheten 12 cm und 0,35 m: round((48020412326426352750220429493489762710731898/4000000000000000000000000000000000000000000),2) = 1201/100 (soll 1201/100)
- ok  #4 Hypotenuse · Katheten 12 cm und 0,35 m: 12^2+35^2 = 1369 (soll 1369)
- ok  #4 Hypotenuse · Katheten 12 cm und 0,35 m: 12+35 = 47 (soll 47)
- ok  #5 Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten: round((98488578017961047217462114149176244816961/10000000000000000000000000000000000000000),1) = 49/5 (soll 49/5)
- ok  #5 Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten: 9^2+4^2 = 97 (soll 97)
- ok  #5 Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten: 9+4 = 13 (soll 13)
- ok  #5 Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten: round((80622577482985496523666132303037711311343/10000000000000000000000000000000000000000),1) = 81/10 (soll 81/10)
- ok  #6 Hypotenuse · Abkürzung über ein Feld: round(120+50-(130),0) = 40 (soll 40)
- ok  #6 Hypotenuse · Abkürzung über ein Feld: round((130),0) = 130 (soll 130)
- ok  #6 Hypotenuse · Abkürzung über ein Feld: round(120+50-(1090871211463571441150215448737290187280513/10000000000000000000000000000000000000000),0) = 61 (soll 61)
- ok  #7 Kathete · Hypotenuse 13 cm, Kathete 5 cm: (12) = 12 (soll 12)
- ok  #7 Kathete · Hypotenuse 13 cm, Kathete 5 cm: round((139283882771841193384677389285132937061943/10000000000000000000000000000000000000000),2) = 1393/100 (soll 1393/100)
- ok  #7 Kathete · Hypotenuse 13 cm, Kathete 5 cm: 13^2-5^2 = 144 (soll 144)
- ok  #7 Kathete · Hypotenuse 13 cm, Kathete 5 cm: 13-5 = 8 (soll 8)
- ok  #8 Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet: round((71414284285428499979993998113672652787661/10000000000000000000000000000000000000000),2) = 357/50 (soll 357/50)
- ok  #8 Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet: round((122065556157337029518978552566229541360871/10000000000000000000000000000000000000000),2) = 1221/100 (soll 1221/100)
- ok  #8 Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet: round(10^2-7^2,2) = 51 (soll 51)
- ok  #8 Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet: round(10-7,2) = 3 (soll 3)
- ok  #9 Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm: (6) = 6 (soll 6)
- ok  #9 Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm: round((174928556845359014126224586326367492295641/20000000000000000000000000000000000000000),2) = 35/4 (soll 35/4)
- ok  #9 Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm: 7.5^2-4.5^2 = 36 (soll 36)
- ok  #9 Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm: 7.5-4.5 = 3 (soll 3)
- ok  #10 Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm: 7*(24)/2 = 84 (soll 84)
- ok  #10 Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm: (24) = 24 (soll 24)
- ok  #10 Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm: 7*(24) = 168 (soll 168)
- ok  #10 Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm: round(7*(259615099714943391040703583282765081553059/10000000000000000000000000000000000000000)/2,2) = 9087/100 (soll 9087/100)
- ok  #11 Kathete · Drachen an 60 m Schnur: round((545435605731785720575107724368645093640256/10000000000000000000000000000000000000000),1) = 109/2 (soll 109/2)
- ok  #11 Kathete · Drachen an 60 m Schnur: round((65),1) = 65 (soll 65)
- ok  #11 Kathete · Drachen an 60 m Schnur: 60^2-25^2 = 2975 (soll 2975)
- ok  #11 Kathete · Drachen an 60 m Schnur: round(60-25,1) = 35 (soll 35)
- ok  #12 Kathete · Höhe eines abgespannten Mastes: (24)+2 = 26 (soll 26)
- ok  #12 Kathete · Höhe eines abgespannten Mastes: (24) = 24 (soll 24)
- ok  #12 Kathete · Höhe eines abgespannten Mastes: round((259615099714943391040703583282765081553059/10000000000000000000000000000000000000000)+2,2) = 699/25 (soll 699/25)
- ok  #12 Kathete · Höhe eines abgespannten Mastes: 25-7+2 = 20 (soll 20)
- ok  #13 Umkehrung · längste Seite zu 9 cm und 12 cm: (15) = 15 (soll 15)
- ok  #13 Umkehrung · längste Seite zu 9 cm und 12 cm: 9^2+12^2 = 225 (soll 225)
- ok  #13 Umkehrung · längste Seite zu 9 cm und 12 cm: 9+12 = 21 (soll 21)
- ok  #13 Umkehrung · längste Seite zu 9 cm und 12 cm: round((79372539331937717715048472609177812771307/10000000000000000000000000000000000000000),2) = 397/50 (soll 397/50)
- ok  #14 Umkehrung · welches der vier Dreiecke ist rechtwinklig?: 2 = 2 (soll 2)
- ok  #14 Umkehrung · welches der vier Dreiecke ist rechtwinklig?: 3 = 3 (soll 3)
- ok  #14 Umkehrung · welches der vier Dreiecke ist rechtwinklig?: 4 = 4 (soll 4)
- ok  #15 Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm: 6^2+7^2-9^2 = 4 (soll 4)
- ok  #15 Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm: 6^2+9^2-7^2 = 68 (soll 68)
- ok  #15 Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm: 2*6+2*7-2*9 = 8 (soll 8)
- ok  #15 Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm: 6^2+7^2 = 85 (soll 85)
- ok  #16 Umkehrung · wie viel länger müsste die längste Seite sein?: round((188679622641132076226413207552452814339672/40000000000000000000000000000000000000000)-4.5,2) = 11/50 (soll 11/50)
- ok  #16 Umkehrung · wie viel länger müsste die längste Seite sein?: 2.5^2+4^2-4.5^2 = 2 (soll 2)
- ok  #16 Umkehrung · wie viel länger müsste die längste Seite sein?: round((188679622641132076226413207552452814339672/40000000000000000000000000000000000000000),2) = 118/25 (soll 118/25)
- ok  #16 Umkehrung · wie viel länger müsste die längste Seite sein?: round(4.7-4.5,2) = 1/5 (soll 1/5)
- ok  #17 Umkehrung · rechte Ecke beim Abstecken: (2) = 2 (soll 2)
- ok  #17 Umkehrung · rechte Ecke beim Abstecken: 1.2^2+1.6^2 = 4 (soll 4)
- ok  #17 Umkehrung · rechte Ecke beim Abstecken: 1.2+1.6 = 14/5 (soll 14/5)
- ok  #17 Umkehrung · rechte Ecke beim Abstecken: round((264575131106459059050161575363926042571025/250000000000000000000000000000000000000000),2) = 53/50 (soll 53/50)
- ok  #18 Umkehrung · Latte um wie viele Zentimeter kürzen?: 510-(500) = 10 (soll 10)
- ok  #18 Umkehrung · Latte um wie viele Zentimeter kürzen?: (500) = 500 (soll 500)
- ok  #18 Umkehrung · Latte um wie viele Zentimeter kürzen?: 5.1-(5) = 1/10 (soll 1/10)
- ok  #18 Umkehrung · Latte um wie viele Zentimeter kürzen?: (5.1^2-(3^2+4^2))*100 = 101 (soll 101)
- ok  #19 Abstand · P(1|2) und Q(4|6): (5) = 5 (soll 5)
- ok  #19 Abstand · P(1|2) und Q(4|6): 3^2+4^2 = 25 (soll 25)
- ok  #19 Abstand · P(1|2) und Q(4|6): 3+4 = 7 (soll 7)
- ok  #20 Abstand · zwei Punkte aus der Abbildung: (10) = 10 (soll 10)
- ok  #20 Abstand · zwei Punkte aus der Abbildung: 6^2+8^2 = 100 (soll 100)
- ok  #20 Abstand · zwei Punkte aus der Abbildung: 6+8 = 14 (soll 14)
- ok  #20 Abstand · zwei Punkte aus der Abbildung: round((52915026221291811810032315072785208514205/10000000000000000000000000000000000000000),2) = 529/100 (soll 529/100)
- ok  #21 Abstand · P(−2|3) und Q(4|−5) über die Achsen: (10) = 10 (soll 10)
- ok  #21 Abstand · P(−2|3) und Q(4|−5) über die Achsen: round((28284271247461900976033774484193961571393/10000000000000000000000000000000000000000),2) = 283/100 (soll 283/100)
- ok  #21 Abstand · P(−2|3) und Q(4|−5) über die Achsen: 6^2+8^2 = 100 (soll 100)
- ok  #21 Abstand · P(−2|3) und Q(4|−5) über die Achsen: 6+8 = 14 (soll 14)
- ok  #22 Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet: round((58309518948453004708741528775455830765213/10000000000000000000000000000000000000000),2) = 583/100 (soll 583/100)
- ok  #22 Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet: round((14142135623730950488016887242096980785696/10000000000000000000000000000000000000000),2) = 141/100 (soll 141/100)
- ok  #22 Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet: 5^2+3^2 = 34 (soll 34)
- ok  #22 Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet: 5+3 = 8 (soll 8)
- ok  #23 Abstand · Hafen und Leuchtturm auf einer Karte: round((92195444572928873100022742817627931572468/10000000000000000000000000000000000000000),1) = 46/5 (soll 46/5)
- ok  #23 Abstand · Hafen und Leuchtturm auf einer Karte: round((22360679774997896964091736687312762354406/10000000000000000000000000000000000000000),1) = 11/5 (soll 11/5)
- ok  #23 Abstand · Hafen und Leuchtturm auf einer Karte: 7^2+6^2 = 85 (soll 85)
- ok  #23 Abstand · Hafen und Leuchtturm auf einer Karte: 7+6 = 13 (soll 13)
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: 0-2+(8) = 6 (soll 6)
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: (8) = 8 (soll 8)
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: 0-2+(10-6) = 2 (soll 2)
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: 0-2+(10^2-6^2) = 62 (soll 62)
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: round(0-2+(91651513899116800131760943874560169779689/10000000000000000000000000000000000000000),2) = 717/100 (soll 717/100)
- ok  #25 Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm: (13) = 13 (soll 13)
- ok  #25 Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm: 12+5 = 17 (soll 17)
- ok  #25 Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm: 12^2+5^2 = 169 (soll 169)
- ok  #25 Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm: round((109087121146357144115021544873729018728051/10000000000000000000000000000000000000000),2) = 1091/100 (soll 1091/100)
- ok  #26 Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm: round((51961524227066318805823390245176171008284/10000000000000000000000000000000000000000),2) = 26/5 (soll 26/5)
- ok  #26 Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm: round((67082039324993690892275210061938287063218/10000000000000000000000000000000000000000),2) = 671/100 (soll 671/100)
- ok  #26 Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm: round(6^2-3^2,2) = 27 (soll 27)
- ok  #26 Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm: round(6-3,2) = 3 (soll 3)
- ok  #27 Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm: round((123288280059379529005003847629084884504712/10000000000000000000000000000000000000000),1) = 123/10 (soll 123/10)
- ok  #27 Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm: round((72111025509279785862384425349409918925025/10000000000000000000000000000000000000000),1) = 36/5 (soll 36/5)
- ok  #27 Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm: 4^2+6^2+10^2 = 152 (soll 152)
- ok  #27 Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm: 4+6+10 = 20 (soll 20)
- ok  #28 Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm: round(8*(69282032302755091741097853660234894677712/10000000000000000000000000000000000000000)/2,2) = 2771/100 (soll 2771/100)
- ok  #28 Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm: round(8*(69282032302755091741097853660234894677712/10000000000000000000000000000000000000000),2) = 5543/100 (soll 5543/100)
- ok  #28 Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm: round((69282032302755091741097853660234894677712/10000000000000000000000000000000000000000),2) = 693/100 (soll 693/100)
- ok  #28 Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm: round(8*(89442719099991587856366946749251049417624/10000000000000000000000000000000000000000)/2,2) = 1789/50 (soll 1789/50)
- ok  #29 Anwendung · Leiter an einer Wand: (24/5) = 24/5 (soll 24/5)
- ok  #29 Anwendung · Leiter an einer Wand: round((1298075498574716955203517916413825407765297/250000000000000000000000000000000000000000),2) = 519/100 (soll 519/100)
- ok  #29 Anwendung · Leiter an einer Wand: 5^2-1.4^2 = 576/25 (soll 576/25)
- ok  #29 Anwendung · Leiter an einer Wand: 5-1.4 = 18/5 (soll 18/5)
- ok  #30 Anwendung · Leiterfuß näher an die Wand rücken: round(((435889894354067355223698198385961565913700/250000000000000000000000000000000000000000)-(312249899919919910292344656046989723053647/250000000000000000000000000000000000000000))*100,0) = 49 (soll 49)
- ok  #30 Anwendung · Leiterfuß näher an die Wand rücken: round((312249899919919910292344656046989723053647/250000000000000000000000000000000000000000)*100,0) = 125 (soll 125)
- ok  #30 Anwendung · Leiterfuß näher an die Wand rücken: round((1.7-1.2)*100,0) = 50 (soll 50)
- ok  #30 Anwendung · Leiterfuß näher an die Wand rücken: round(((1379311422413372171665059787960239316342675/250000000000000000000000000000000000000000)-(1345362404707371031716308546217040419387096/250000000000000000000000000000000000000000))*100,0) = 14 (soll 14)

## Blind-Abgleich (docs/prefill/k9-pythagoras-blind.json)

- ok  #1 Hypotenuse · Katheten 6 cm und 8 cm: Loeser 10 · gespeichert ["10","10 cm","10cm"]
- ok  #2 Hypotenuse · Katheten 5 cm und 7 cm, gerundet: Loeser 8.60 · gespeichert ["8,60","8.60","8,6","8.6","8,60 cm","8,60cm","8,6 cm","8,6cm"]
- ok  #3 Hypotenuse · Katheten 4,5 cm und 6 cm: Loeser 7.5 · gespeichert ["7,5","7.5","7,5 cm","7,5cm"]
- ok  #4 Hypotenuse · Katheten 12 cm und 0,35 m: Loeser 37 · gespeichert ["37","37 cm","37cm"]
- ok  #5 Hypotenuse · Boot 9 km nach Norden, 4 km nach Osten: Loeser 9.8 · gespeichert ["9,8","9.8","9,8 km","9,8km"]
- ok  #6 Hypotenuse · Abkürzung über ein Feld: Loeser 40 · gespeichert ["40","40 m","40m"]
- ok  #7 Kathete · Hypotenuse 13 cm, Kathete 5 cm: Loeser 12 · gespeichert ["12","12 cm","12cm"]
- ok  #8 Kathete · Hypotenuse 10 cm, Kathete 7 cm, gerundet: Loeser 7.14 · gespeichert ["7,14","7.14","7,14 cm","7,14cm"]
- ok  #9 Kathete · Hypotenuse 7,5 cm, Kathete 4,5 cm: Loeser 6 · gespeichert ["6","6 cm","6cm"]
- ok  #10 Kathete · Flächeninhalt aus Hypotenuse 25 cm und Kathete 7 cm: Loeser 84 · gespeichert ["84","84 cm²","84cm²"]
- ok  #11 Kathete · Drachen an 60 m Schnur: Loeser 54.5 · gespeichert ["54,5","54.5","54,5 m","54,5m"]
- ok  #12 Kathete · Höhe eines abgespannten Mastes: Loeser 26 · gespeichert ["26","26 m","26m"]
- ok  #13 Umkehrung · längste Seite zu 9 cm und 12 cm: Loeser 15 · gespeichert ["15","15 cm","15cm"]
- ok  #14 Umkehrung · welches der vier Dreiecke ist rechtwinklig?: Loeser 2 · gespeichert ["2","+2"]
- ok  #15 Umkehrung · Abstand zur Rechtwinkligkeit bei 6, 7, 9 cm: Loeser 4 · gespeichert ["4","4 cm²","4cm²"]
- ok  #16 Umkehrung · wie viel länger müsste die längste Seite sein?: Loeser 0.22 · gespeichert ["0,22","0.22","0,22 cm","0,22cm"]
- ok  #17 Umkehrung · rechte Ecke beim Abstecken: Loeser 2 · gespeichert ["2","2 m","2m"]
- ok  #18 Umkehrung · Latte um wie viele Zentimeter kürzen?: Loeser 10 · gespeichert ["10","10 cm","10cm"]
- ok  #19 Abstand · P(1|2) und Q(4|6): Loeser 5 · gespeichert ["5","+5"]
- ok  #20 Abstand · zwei Punkte aus der Abbildung: Loeser 10 · gespeichert ["10","+10"]
- ok  #21 Abstand · P(−2|3) und Q(4|−5) über die Achsen: Loeser 10 · gespeichert ["10","+10"]
- ok  #22 Abstand · zwei Punkte über die Achsen aus der Abbildung, gerundet: Loeser 5.83 · gespeichert ["5,83","+5,83","5.83","+5.83"]
- ok  #23 Abstand · Hafen und Leuchtturm auf einer Karte: Loeser 9.2 · gespeichert ["9,2","9.2","9,2 km","9,2km"]
- ok  #24 Abstand · fehlende Koordinate aus dem Abstand: Loeser 6 · gespeichert ["6","+6"]
- ok  #25 Anwendung · Diagonale eines Rechtecks 12 cm × 5 cm: Loeser 13 · gespeichert ["13","13 cm","13cm"]
- ok  #26 Anwendung · Höhe eines gleichseitigen Dreiecks mit 6 cm: Loeser 5.20 · gespeichert ["5,20","5.20","5,2","5.2","5,20 cm","5,20cm","5,2 cm","5,2cm"]
- ok  #27 Anwendung · Raumdiagonale eines Quaders 4 × 6 × 10 cm: Loeser 12.3 · gespeichert ["12,3","12.3","12,3 cm","12,3cm"]
- ok  #28 Anwendung · Flächeninhalt eines gleichseitigen Dreiecks mit 8 cm: Loeser 27.71 · gespeichert ["27,71","27.71","27,71 cm²","27,71cm²"]
- ok  #29 Anwendung · Leiter an einer Wand: Loeser 4.8 · gespeichert ["4,8","4.8","4,8 m","4,8m"]
- ok  #30 Anwendung · Leiterfuß näher an die Wand rücken: Loeser 49 · gespeichert ["49","49 cm","49cm"]
