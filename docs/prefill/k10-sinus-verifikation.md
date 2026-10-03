# Verifikation k10-sinus

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
| correct_answers | 23 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| parts[].afb | 15 | 0 | 0 | 0 |
| parts[].competency_content | 15 | 0 | 0 | 0 |
| correct_answers[].antwort | 15 | 0 | 0 | 0 |

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
| tasks.competency_content | 23 | 23 | 0 | 0 |
| tasks.competency_process | 23 | 23 | 0 | 0 |
| task_solutions.correct_answers | 23 | 23 | 0 | 0 |
| parts[].afb | 15 | 15 | 0 | 0 |
| parts[].competency_content | 15 | 15 | 0 | 0 |
| parts[].antwort | 15 | 15 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 sin 150° · exakter Wert: (1/2) = 1/2 (soll 1/2)
- ok  #1 sin 150° · exakter Wert: 0-(1/2) = -1/2 (soll -1/2)
- ok  #1 sin 150° · exakter Wert: round((0-7148764296291646314363860973966299893729/10000000000000000000000000000000000000000),2) = -71/100 (soll -71/100)
- ok  #2 cos 200° · gerundet: round((0-4698463103929541920270546386623657349681/5000000000000000000000000000000000000000),2) = -47/50 (soll -47/50)
- ok  #2 cos 200° · gerundet: round((4698463103929541920270546386623657349681/5000000000000000000000000000000000000000),2) = 47/50 (soll 47/50)
- ok  #2 cos 200° · gerundet: round((974375350014011820709495802669048395163/2000000000000000000000000000000000000000),2) = 49/100 (soll 49/100)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 1: round((0-1/2),2) = -1/2 (soll -1/2)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 1: round((1/2),2) = 1/2 (soll 1/2)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 1: round((0-4330127018922193233818615853764680917357/5000000000000000000000000000000000000000),2) = -87/100 (soll -87/100)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 2: round((0-4330127018922193233818615853764680917357/5000000000000000000000000000000000000000),2) = -87/100 (soll -87/100)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 2: round((4330127018922193233818615853764680917357/5000000000000000000000000000000000000000),2) = 87/100 (soll 87/100)
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 2: round((0-1/2),2) = -1/2 (soll -1/2)
- ok  #4 Winkel aus cos α = −0,6 · zweites Viertel: round((317174744114610053242139031397733526643979/2500000000000000000000000000000000000000),1) = 1269/10 (soll 1269/10)
- ok  #4 Winkel aus cos α = −0,6 · zweites Viertel: round((132825255885389946757860968602266473356021/2500000000000000000000000000000000000000),1) = 531/10 (soll 531/10)
- ok  #4 Winkel aus cos α = −0,6 · zweites Viertel: round((317174744114610053242139031397733526643979/2500000000000000000000000000000000000000)*(3.14159265358979323846264338327950288)/180,1) = 11/5 (soll 11/5)
- ok  #5 Rückrichtung · zweiter Winkel mit sin α = sin 50°: 180-50 = 130 (soll 130)
- ok  #5 Rückrichtung · zweiter Winkel mit sin α = sin 50°: 360-50 = 310 (soll 310)
- ok  #5 Rückrichtung · zweiter Winkel mit sin α = sin 50°: 180+50 = 230 (soll 230)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 1: round((4/5),2) = 4/5 (soll 4/5)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 1: round(0-(4/5),2) = -4/5 (soll -4/5)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 1: round(1-0.6^2,2) = 16/25 (soll 16/25)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 2: round(360+(0-92174744114610053242139031397733526643979/2500000000000000000000000000000000000000),2) = 32313/100 (soll 32313/100)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 2: round(180+(92174744114610053242139031397733526643979/2500000000000000000000000000000000000000),2) = 21687/100 (soll 21687/100)
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 2: round(2*(3.14159265358979323846264338327950288)+(0-92174744114610053242139031397733526643979/2500000000000000000000000000000000000000)*(3.14159265358979323846264338327950288)/180,2) = 141/25 (soll 141/25)
- ok  #7 60° als Vielfaches von π: 60/180 = 1/3 (soll 1/3)
- ok  #7 60° als Vielfaches von π: 60/360 = 1/6 (soll 1/6)
- ok  #7 60° als Vielfaches von π: 180/60 = 3 (soll 3)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50*(3.14159265358979323846264338327950288)/180,2) = 87/100 (soll 87/100)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50*(3.14)/180,2) = 87/100 (soll 87/100)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50*180/(3.14159265358979323846264338327950288),2) = 286479/100 (soll 286479/100)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50*180/(3.14),2) = 71656/25 (soll 71656/25)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50/180,2) = 7/25 (soll 7/25)
- ok  #8 50° im Bogenmaß · Dezimalzahl: round(50/180,2) = 7/25 (soll 7/25)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*180/(3.14159265358979323846264338327950288),1) = 1146/5 (soll 1146/5)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*180/(3.14),1) = 2293/10 (soll 2293/10)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*(3.14159265358979323846264338327950288)/180,2) = 7/100 (soll 7/100)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*(3.14)/180,2) = 7/100 (soll 7/100)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*180,1) = 720 (soll 720)
- ok  #9 x = 4 im Bogenmaß · in Grad: round(4*180,1) = 720 (soll 720)
- ok  #10 x = 5π/4 im Bogenmaß · in Grad: 5/4*180 = 225 (soll 225)
- ok  #10 x = 5π/4 im Bogenmaß · in Grad: 5/4*360 = 450 (soll 450)
- ok  #10 x = 5π/4 im Bogenmaß · in Grad: round(5/4*(3.14159265358979323846264338327950288)*(3.14159265358979323846264338327950288)/180,2) = 7/100 (soll 7/100)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130*(3.14159265358979323846264338327950288)/180,2) = 227/100 (soll 227/100)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130*(3.14)/180,2) = 227/100 (soll 227/100)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130*180/(3.14159265358979323846264338327950288),2) = 148969/20 (soll 148969/20)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130*180/(3.14),2) = 745223/100 (soll 745223/100)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(360/130*2*(3.14159265358979323846264338327950288),2) = 87/5 (soll 87/5)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(360/130*2*(3.14),2) = 1739/100 (soll 1739/100)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130/180,2) = 18/25 (soll 18/25)
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: round(130/180,2) = 18/25 (soll 18/25)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5/3*180/(3.14159265358979323846264338327950288),1) = 191/2 (soll 191/2)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5/3*180/(3.14),1) = 191/2 (soll 191/2)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5*3*180/(3.14159265358979323846264338327950288),1) = 4297/5 (soll 4297/5)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5*3*180/(3.14),1) = 8599/10 (soll 8599/10)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5/3*(3.14159265358979323846264338327950288)/180,2) = 3/100 (soll 3/100)
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: round(5/3*(3.14)/180,2) = 3/100 (soll 3/100)
- ok  #13 Funktionswert · sin(7π/6): (0-1/2) = -1/2 (soll -1/2)
- ok  #13 Funktionswert · sin(7π/6): (1/2) = 1/2 (soll 1/2)
- ok  #13 Funktionswert · sin(7π/6): round((63926038524973307064628397765727631761/1000000000000000000000000000000000000000),2) = 3/50 (soll 3/50)
- ok  #14 Funktionswert · sin(π/3) gerundet: round((4330127018922193233818615853764680917357/5000000000000000000000000000000000000000),2) = 87/100 (soll 87/100)
- ok  #14 Funktionswert · sin(π/3) gerundet: round((91380138142738764254193480349946660711/5000000000000000000000000000000000000000),2) = 1/50 (soll 1/50)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 1: 90/180 = 1/2 (soll 1/2)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 1: 270/180 = 3/2 (soll 3/2)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 1: 90 = 90 (soll 90)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 2: 270/180 = 3/2 (soll 3/2)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 2: 90/180 = 1/2 (soll 1/2)
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 2: 270 = 270 (soll 270)
- ok  #16 Funktionswert · sin(5) mit Vorzeichen: round((0-383569709865255387557261762462397589341/400000000000000000000000000000000000000),2) = -24/25 (soll -24/25)
- ok  #16 Funktionswert · sin(5) mit Vorzeichen: round((871557427476581735580642708374735513777/10000000000000000000000000000000000000000),2) = 9/100 (soll 9/100)
- ok  #16 Funktionswert · sin(5) mit Vorzeichen: round(0-(0-383569709865255387557261762462397589341/400000000000000000000000000000000000000),2) = 24/25 (soll 24/25)
- ok  #17 Rückrichtung · zweite Stelle mit sin x = sin(π/5): 1-1/5 = 4/5 (soll 4/5)
- ok  #17 Rückrichtung · zweite Stelle mit sin x = sin(π/5): 1+1/5 = 6/5 (soll 6/5)
- ok  #17 Rückrichtung · zweite Stelle mit sin x = sin(π/5): 2-1/5 = 9/5 (soll 9/5)
- ok  #18 Anzahl der Nullstellen in [0; 20]: round(20/(3.14159265358979323846264338327950288)+1,4) = 36831/5000 (soll 36831/5000)
- ok  #18 Anzahl der Nullstellen in [0; 20]: round(20/1+1,4) = 21 (soll 21)
- ok  #18 Anzahl der Nullstellen in [0; 20]: round(20/180+1,4) = 11111/10000 (soll 11111/10000)
- ok  #19 Amplitude · f(x) = 3·sin(2x): 3 = 3 (soll 3)
- ok  #19 Amplitude · f(x) = 3·sin(2x): 2*3 = 6 (soll 6)
- ok  #19 Amplitude · f(x) = 3·sin(2x): 3/2 = 3/2 (soll 3/2)
- ok  #20 Periode · f(x) = sin(4x) als Vielfaches von π: 2/4 = 1/2 (soll 1/2)
- ok  #20 Periode · f(x) = sin(4x) als Vielfaches von π: 4 = 4 (soll 4)
- ok  #20 Periode · f(x) = sin(4x) als Vielfaches von π: 2*4 = 8 (soll 8)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2*(3.14159265358979323846264338327950288)/0.5,2) = 1257/100 (soll 1257/100)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2*(3.14)/0.5,2) = 314/25 (soll 314/25)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2*(3.14159265358979323846264338327950288)*0.5,2) = 157/50 (soll 157/50)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2*(3.14)*0.5,2) = 157/50 (soll 157/50)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(0.5,2) = 1/2 (soll 1/2)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(0.5,2) = 1/2 (soll 1/2)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2/0.5,2) = 4 (soll 4)
- ok  #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: round(2/0.5,2) = 4 (soll 4)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 1: 4 = 4 (soll 4)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 1: 0-4 = -4 (soll -4)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 1: 2*4 = 8 (soll 8)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 2: 2/2 = 1 (soll 1)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 2: 2*2 = 4 (soll 4)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 2: 1/2 = 1/2 (soll 1/2)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 1: 1.5 = 3/2 (soll 3/2)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 1: 2*1.5 = 3 (soll 3)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 1: 1.5/2 = 3/4 (soll 3/4)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 2: 2*(3.14159265358979323846264338327950288)/(3.14159265358979323846264338327950288) = 2 (soll 2)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 2: round((3.14159265358979323846264338327950288),2) = 157/50 (soll 157/50)
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 2: (3.14159265358979323846264338327950288)/(2*(3.14159265358979323846264338327950288)) = 1/2 (soll 1/2)
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 1: 2.5 = 5/2 (soll 5/2)
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 1: 2.5-(0-2.5) = 5 (soll 5)
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 2: 2*(3.14159265358979323846264338327950288)/(2*(3*(3.14159265358979323846264338327950288)/8-(3.14159265358979323846264338327950288)/8)) = 4 (soll 4)
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 2: 2*(3*(3.14159265358979323846264338327950288)/8-(3.14159265358979323846264338327950288)/8)/(2*(3.14159265358979323846264338327950288)) = 1/4 (soll 1/4)
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 2: 2*(3.14159265358979323846264338327950288)/(3*(3.14159265358979323846264338327950288)/8-(3.14159265358979323846264338327950288)/8) = 8 (soll 8)
- ok  #25 Riesenrad · größte Höhe der Gondel: 20+18 = 38 (soll 38)
- ok  #25 Riesenrad · größte Höhe der Gondel: 18 = 18 (soll 18)
- ok  #25 Riesenrad · größte Höhe der Gondel: 2*18 = 36 (soll 36)
- ok  #26 Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser: 1.8-(0-1.8) = 18/5 (soll 18/5)
- ok  #26 Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser: 1.8 = 9/5 (soll 9/5)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2*(3.14159265358979323846264338327950288)/0.2,1) = 157/5 (soll 157/5)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2*(3.14)/0.2,1) = 157/5 (soll 157/5)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2*(3.14159265358979323846264338327950288)*0.2,1) = 13/10 (soll 13/10)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2*(3.14)*0.2,1) = 13/10 (soll 13/10)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2/0.2,1) = 10 (soll 10)
- ok  #27 Riesenrad · Dauer einer Umdrehung: round(2/0.2,1) = 10 (soll 10)
- ok  #28 Tageslänge · 50 Tage nach Frühlingsanfang: round(4.3*(1515685125790553944589177459057291156627/2000000000000000000000000000000000000000)+12.2,1) = 31/2 (soll 31/2)
- ok  #28 Tageslänge · 50 Tage nach Frühlingsanfang: round(4.3*(37523169916809200564133152340818995997/2500000000000000000000000000000000000000)+12.2,1) = 123/10 (soll 123/10)
- ok  #28 Tageslänge · 50 Tage nach Frühlingsanfang: round(4.3*0.8+12.2,1) = 78/5 (soll 78/5)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(2*(3.14159265358979323846264338327950288)/3,2) = 209/100 (soll 209/100)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(2*(3.14)/3,2) = 209/100 (soll 209/100)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(3,2) = 3 (soll 3)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(3,2) = 3 (soll 3)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(2*(3.14159265358979323846264338327950288)*3,2) = 377/20 (soll 377/20)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(2*(3.14)*3,2) = 471/25 (soll 471/25)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(1.2,2) = 6/5 (soll 6/5)
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: round(1.2,2) = 6/5 (soll 6/5)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 1: (6.5-1.5)/2 = 5/2 (soll 5/2)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 1: (6.5-1.5)/2 = 5/2 (soll 5/2)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 1: 6.5-1.5 = 5 (soll 5)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 1: 6.5-1.5 = 5 (soll 5)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 2: (6.5+1.5)/2 = 4 (soll 4)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 2: (6.5+1.5)/2 = 4 (soll 4)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 2: (6.5-1.5)/2 = 5/2 (soll 5/2)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 2: (6.5-1.5)/2 = 5/2 (soll 5/2)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*(3.14159265358979323846264338327950288)/(2*6.2),2) = 51/100 (soll 51/100)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*(3.14)/(2*6.2),2) = 51/100 (soll 51/100)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*6.2/(2*(3.14159265358979323846264338327950288)),2) = 197/100 (soll 197/100)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*6.2/(2*(3.14)),2) = 197/100 (soll 197/100)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*(3.14159265358979323846264338327950288)/6.2,2) = 101/100 (soll 101/100)
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: round(2*(3.14)/6.2,2) = 101/100 (soll 101/100)

## Blind-Abgleich (docs/prefill/k10-sinus-blind.json)

- ok  #1 sin 150° · exakter Wert: Loeser 0.5 · gespeichert ["0,5","+0,5","0.5","+0.5"]
- ok  #2 cos 200° · gerundet: Loeser -0.94 · gespeichert ["-0,94","−0,94","- 0,94","-0.94","−0.94","- 0.94"]
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 1: Loeser -0.5 · gespeichert ["-0,50","−0,50","- 0,50","-0.50","−0.50","- 0.50","-0,5","−0,5","- 0,5","-0.5","−0.5","- 0.5"]
- ok  #3 Punkt auf dem Einheitskreis · α = 240° Teil 2: Loeser -0.87 · gespeichert ["-0,87","−0,87","- 0,87","-0.87","−0.87","- 0.87"]
- ok  #4 Winkel aus cos α = −0,6 · zweites Viertel: Loeser 126.9 · gespeichert ["126,9","126.9","126,9 °","126,9°"]
- ok  #5 Rückrichtung · zweiter Winkel mit sin α = sin 50°: Loeser 130 · gespeichert ["130","130 °","130°"]
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 1: Loeser 0.8 · gespeichert ["0,80","+0,80","0.80","+0.80","0,8","+0,8","0.8","+0.8"]
- ok  #6 Rückrichtung · Punkt mit y = −0,6 im vierten Viertel Teil 2: Loeser 323.13 · gespeichert ["323,13","+323,13","323.13","+323.13"]
- ok  #7 60° als Vielfaches von π: Loeser 1/3 · gespeichert ["1/3","+1/3"]
- ok  #8 50° im Bogenmaß · Dezimalzahl: Loeser 0.87 · gespeichert ["0,87","+0,87","0.87","+0.87"]
- info #9 x = 4 im Bogenmaß · in Grad: Loeser nennt die Aufgabe nicht eindeutig (Mit π-Taste 229.2, mit π ≈ 3,14 aber 229.3 – beide Wege sind erlaubt und liefern verschiedene gerundete Ergebnisse.)
- ok  #10 x = 5π/4 im Bogenmaß · in Grad: Loeser 225 · gespeichert ["225","225 °","225°"]
- ok  #11 Bogenlänge · Karussellsitz dreht sich um 130°: Loeser 2.27 · gespeichert ["2,27","2.27","2,27 m","2,27m"]
- ok  #12 Rückrichtung · Winkel aus Bogen 5 cm am Kreis mit r = 3 cm: Loeser 95.5 · gespeichert ["95,5","95.5","95,5 °","95,5°"]
- ok  #13 Funktionswert · sin(7π/6): Loeser -0.5 · gespeichert ["-0,5","−0,5","- 0,5","-0.5","−0.5","- 0.5"]
- ok  #14 Funktionswert · sin(π/3) gerundet: Loeser 0.87 · gespeichert ["0,87","+0,87","0.87","+0.87"]
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 1: Loeser 1/2 · gespeichert ["0,5","+0,5","0.5","+0.5","1/2","+1/2"]
- ok  #15 Hoch- und Tiefpunkt in [0; 2π] als Vielfache von π Teil 2: Loeser 3/2 · gespeichert ["1,5","+1,5","1.5","+1.5","3/2","+3/2"]
- ok  #16 Funktionswert · sin(5) mit Vorzeichen: Loeser -0.96 · gespeichert ["-0,96","−0,96","- 0,96","-0.96","−0.96","- 0.96"]
- ok  #17 Rückrichtung · zweite Stelle mit sin x = sin(π/5): Loeser 4/5 · gespeichert ["0,8","+0,8","0.8","+0.8","4/5","+4/5"]
- ok  #18 Anzahl der Nullstellen in [0; 20]: Loeser 7 · gespeichert ["7","+7"]
- ok  #19 Amplitude · f(x) = 3·sin(2x): Loeser 3 · gespeichert ["3","+3"]
- ok  #20 Periode · f(x) = sin(4x) als Vielfaches von π: Loeser 1/2 · gespeichert ["0,5","+0,5","0.5","+0.5","1/2","+1/2"]
- info #21 Periode · f(x) = 2·sin(0,5x) als Dezimalzahl: Loeser nennt die Aufgabe nicht eindeutig (Mit π-Taste 12.57, mit π ≈ 3,14 aber 12.56 – beide Wege sind erlaubt und liefern verschiedene Ergebnisse.)
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 1: Loeser 4 · gespeichert ["4","+4"]
- ok  #22 Größter Wert und Periode · f(x) = −4·sin(2x) Teil 2: Loeser 1 · gespeichert ["1","+1"]
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 1: Loeser 1.5 · gespeichert ["1,5","+1,5","1.5","+1.5"]
- ok  #23 Rückrichtung · a und b aus Amplitude 1,5 und Periode π Teil 2: Loeser 2 · gespeichert ["2","+2"]
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 1: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5"]
- ok  #24 Rückrichtung · a und b aus Hoch- und Tiefpunkt Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #25 Riesenrad · größte Höhe der Gondel: Loeser 38 · gespeichert ["38","38 m","38m"]
- ok  #26 Gezeiten · Unterschied zwischen Hoch- und Niedrigwasser: Loeser 3.6 · gespeichert ["3,6","3.6","3,6 m","3,6m"]
- ok  #27 Riesenrad · Dauer einer Umdrehung: Loeser 31.4 · gespeichert ["31,4","31.4","31,4 min","31,4min"]
- ok  #28 Tageslänge · 50 Tage nach Frühlingsanfang: Loeser 15.5 · gespeichert ["15,5","15.5","15,5 h","15,5h"]
- ok  #29 Schaukel · b aus der Schwingungsdauer 3 s: Loeser 2.09 · gespeichert ["2,09","+2,09","2.09","+2.09"]
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 1: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5"]
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #30 Gezeiten · Modell w(t) = a·sin(b·t) + d aufstellen Teil 3: Loeser 0.51 · gespeichert ["0,51","+0,51","0.51","+0.51"]
