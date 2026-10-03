# Verifikation k9-koerper

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

- ok  #1 Prisma · Volumen eines Dreiecksprismas: 1/2*6*4*10 = 120 (soll 120)
- ok  #1 Prisma · Volumen eines Dreiecksprismas: 6*4*10 = 240 (soll 240)
- ok  #1 Prisma · Volumen eines Dreiecksprismas: 1/2*6*4 = 12 (soll 12)
- ok  #2 Prisma · Oberfläche eines Dreiecksprismas: 2*(1/2*3*4)+(3+4+5)*8 = 108 (soll 108)
- ok  #2 Prisma · Oberfläche eines Dreiecksprismas: 1/2*3*4+(3+4+5)*8 = 102 (soll 102)
- ok  #2 Prisma · Oberfläche eines Dreiecksprismas: 2*(3*4)+(3+4+5)*8 = 120 (soll 120)
- ok  #2 Prisma · Oberfläche eines Dreiecksprismas: 1/2*3*4*8 = 48 (soll 48)
- ok  #3 Prisma · Volumen mit Trapez als Grundfläche: (8+5)/2*4*12 = 312 (soll 312)
- ok  #3 Prisma · Volumen mit Trapez als Grundfläche: (8+5)*4*12 = 624 (soll 624)
- ok  #3 Prisma · Volumen mit Trapez als Grundfläche: (8+5)/2*4 = 26 (soll 26)
- ok  #4 Prisma · Höhe aus Volumen und Dreiecksgrundfläche: 180/(1/2*8*5) = 9 (soll 9)
- ok  #4 Prisma · Höhe aus Volumen und Dreiecksgrundfläche: 180/(8*5) = 9/2 (soll 9/2)
- ok  #4 Prisma · Höhe aus Volumen und Dreiecksgrundfläche: 180*(1/2*8*5) = 3600 (soll 3600)
- ok  #5 Prisma · Wassertrog mit dreieckigem Querschnitt: 1/2*6*4*20 = 240 (soll 240)
- ok  #5 Prisma · Wassertrog mit dreieckigem Querschnitt: 6*4*20 = 480 (soll 480)
- ok  #5 Prisma · Wassertrog mit dreieckigem Querschnitt: 1/2*60*40*200 = 240000 (soll 240000)
- ok  #5 Prisma · Wassertrog mit dreieckigem Querschnitt: 1/2*60*40*2 = 2400 (soll 2400)
- ok  #6 Prisma · Höhe aus der Oberfläche: (288-2*(1/2*6*8))/(6+8+10) = 10 (soll 10)
- ok  #6 Prisma · Höhe aus der Oberfläche: (288-1/2*6*8)/(6+8+10) = 11 (soll 11)
- ok  #6 Prisma · Höhe aus der Oberfläche: (288-2*6*8)/(6+8+10) = 8 (soll 8)
- ok  #6 Prisma · Höhe aus der Oberfläche: 288/(1/2*6*8) = 12 (soll 12)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round((3.14159265358979323846264338327950288)*3^2*10,2) = 14137/50 (soll 14137/50)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round((3.14)*3^2*10,2) = 1413/5 (soll 1413/5)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round((3.14159265358979323846264338327950288)*6^2*10,2) = 113097/100 (soll 113097/100)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round((3.14)*6^2*10,2) = 5652/5 (soll 5652/5)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round(3^2*10,2) = 90 (soll 90)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round(3^2*10,2) = 90 (soll 90)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round(2*(3.14159265358979323846264338327950288)*3^2+2*(3.14159265358979323846264338327950288)*3*10,2) = 6126/25 (soll 6126/25)
- ok  #7 Zylinder · Volumen, Radius 3 cm: round(2*(3.14)*3^2+2*(3.14)*3*10,2) = 6123/25 (soll 6123/25)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round(2*(3.14159265358979323846264338327950288)*4^2+2*(3.14159265358979323846264338327950288)*4*5,2) = 22619/100 (soll 22619/100)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round(2*(3.14)*4^2+2*(3.14)*4*5,2) = 5652/25 (soll 5652/25)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round(2*(3.14159265358979323846264338327950288)*8^2+2*(3.14159265358979323846264338327950288)*8*5,2) = 13069/20 (soll 13069/20)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round(2*(3.14)*8^2+2*(3.14)*8*5,2) = 16328/25 (soll 16328/25)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round((3.14159265358979323846264338327950288)*4^2+2*(3.14159265358979323846264338327950288)*4*5,2) = 17593/100 (soll 17593/100)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round((3.14)*4^2+2*(3.14)*4*5,2) = 4396/25 (soll 4396/25)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round((3.14159265358979323846264338327950288)*4^2*5,2) = 25133/100 (soll 25133/100)
- ok  #8 Zylinder · Oberfläche, Durchmesser 8 cm: round((3.14)*4^2*5,2) = 1256/5 (soll 1256/5)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14159265358979323846264338327950288)*1.5^2*3.2,2) = 1131/50 (soll 1131/50)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14)*1.5^2*3.2,2) = 2261/100 (soll 2261/100)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14159265358979323846264338327950288)*2*1.5*3.2,2) = 754/25 (soll 754/25)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14)*2*1.5*3.2,2) = 1507/50 (soll 1507/50)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14159265358979323846264338327950288)*0.75^2*3.2,2) = 113/20 (soll 113/20)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round((3.14)*0.75^2*3.2,2) = 113/20 (soll 113/20)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round(1.5^2*3.2,2) = 36/5 (soll 36/5)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round(1.5^2*3.2,2) = 36/5 (soll 36/5)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round(2*(3.14159265358979323846264338327950288)*1.5^2+2*(3.14159265358979323846264338327950288)*1.5*3.2,2) = 443/10 (soll 443/10)
- ok  #9 Zylinder · Volumen, Radius 1,5 m: round(2*(3.14)*1.5^2+2*(3.14)*1.5*3.2,2) = 4427/100 (soll 4427/100)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14159265358979323846264338327950288)*0.4^2+2*(3.14159265358979323846264338327950288)*0.4*0.9,2) = 327/100 (soll 327/100)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14)*0.4^2+2*(3.14)*0.4*0.9,2) = 327/100 (soll 327/100)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14159265358979323846264338327950288)*0.4^2+2*(3.14159265358979323846264338327950288)*0.4*90,2) = 1136/5 (soll 1136/5)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14)*0.4^2+2*(3.14)*0.4*90,2) = 5677/25 (soll 5677/25)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round((3.14159265358979323846264338327950288)*0.4^2+2*(3.14159265358979323846264338327950288)*0.4*0.9,2) = 69/25 (soll 69/25)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round((3.14)*0.4^2+2*(3.14)*0.4*0.9,2) = 69/25 (soll 69/25)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14159265358979323846264338327950288)*0.2^2+2*(3.14159265358979323846264338327950288)*0.2*0.9,2) = 69/50 (soll 69/50)
- ok  #10 Zylinder · Oberfläche in m² bei gemischten Einheiten: round(2*(3.14)*0.2^2+2*(3.14)*0.2*0.9,2) = 69/50 (soll 69/50)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14159265358979323846264338327950288)*0.6^2*1.5*1000,0) = 1696 (soll 1696)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14)*0.6^2*1.5*1000,0) = 1696 (soll 1696)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14159265358979323846264338327950288)*1.2^2*1.5*1000,0) = 6786 (soll 6786)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14)*1.2^2*1.5*1000,0) = 6782 (soll 6782)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14159265358979323846264338327950288)*0.6^2*1.5,2) = 17/10 (soll 17/10)
- ok  #11 Zylinder · Wassertank in Litern: round((3.14)*0.6^2*1.5,2) = 17/10 (soll 17/10)
- ok  #11 Zylinder · Wassertank in Litern: round(0.6^2*1.5*1000,0) = 540 (soll 540)
- ok  #11 Zylinder · Wassertank in Litern: round(0.6^2*1.5*1000,0) = 540 (soll 540)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/((3.14159265358979323846264338327950288)*5^2),1) = 127/10 (soll 127/10)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/((3.14)*5^2),1) = 127/10 (soll 127/10)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/((3.14159265358979323846264338327950288)*10^2),1) = 16/5 (soll 16/5)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/((3.14)*10^2),1) = 16/5 (soll 16/5)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(100/((3.14159265358979323846264338327950288)*5^2),1) = 13/10 (soll 13/10)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(100/((3.14)*5^2),1) = 13/10 (soll 13/10)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/5^2,1) = 40 (soll 40)
- ok  #12 Zylinder · Dosenhöhe für einen Liter: round(1000/5^2,1) = 40 (soll 40)
- ok  #13 Pyramide · Volumen einer quadratischen Pyramide: 1/3*6^2*10 = 120 (soll 120)
- ok  #13 Pyramide · Volumen einer quadratischen Pyramide: 6^2*10 = 360 (soll 360)
- ok  #13 Pyramide · Volumen einer quadratischen Pyramide: 6^2 = 36 (soll 36)
- ok  #14 Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe: 8^2+4*(1/2*8*5) = 144 (soll 144)
- ok  #14 Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe: 8^2+4*(1/2*8*3) = 112 (soll 112)
- ok  #14 Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe: 8^2+4*(8*5) = 224 (soll 224)
- ok  #14 Pyramide · Oberfläche mit Körperhöhe und Seitenhöhe: 1/3*8^2*3 = 64 (soll 64)
- ok  #15 Pyramide · Volumen mit rechteckiger Grundfläche: 1/3*4.5*3.2*5 = 24 (soll 24)
- ok  #15 Pyramide · Volumen mit rechteckiger Grundfläche: 4.5*3.2*5 = 72 (soll 72)
- ok  #15 Pyramide · Volumen mit rechteckiger Grundfläche: 4.5*3.2 = 72/5 (soll 72/5)
- ok  #16 Pyramide · Oberfläche mit rechteckiger Grundfläche: 10*4+2*(1/2*10*10)+2*(1/2*4*11) = 184 (soll 184)
- ok  #16 Pyramide · Oberfläche mit rechteckiger Grundfläche: 10*4+2*(1/2*10*11)+2*(1/2*4*10) = 190 (soll 190)
- ok  #16 Pyramide · Oberfläche mit rechteckiger Grundfläche: 10*4+2*(10*10)+2*(4*11) = 328 (soll 328)
- ok  #16 Pyramide · Oberfläche mit rechteckiger Grundfläche: 2*(1/2*10*10)+2*(1/2*4*11) = 144 (soll 144)
- ok  #17 Pyramide · Dachfläche eines Pyramidendachs: 4*(1/2*6*5) = 60 (soll 60)
- ok  #17 Pyramide · Dachfläche eines Pyramidendachs: 4*(6*5) = 120 (soll 120)
- ok  #17 Pyramide · Dachfläche eines Pyramidendachs: 4*(1/2*6*4) = 48 (soll 48)
- ok  #17 Pyramide · Dachfläche eines Pyramidendachs: 6^2+4*(1/2*6*5) = 96 (soll 96)
- ok  #18 Pyramide · Grundkante aus Volumen und Höhe: round((8),2) = 8 (soll 8)
- ok  #18 Pyramide · Grundkante aus Volumen und Höhe: round((138564064605510183482195707320469789355424/30000000000000000000000000000000000000000),2) = 231/50 (soll 231/50)
- ok  #18 Pyramide · Grundkante aus Volumen und Höhe: round(3*192/9,2) = 64 (soll 64)
- ok  #18 Pyramide · Grundkante aus Volumen und Höhe: round(3*192/9/2,2) = 32 (soll 32)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*(3.14159265358979323846264338327950288)*3^2*8,2) = 377/5 (soll 377/5)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*(3.14)*3^2*8,2) = 1884/25 (soll 1884/25)
- ok  #19 Kegel · Volumen, Radius 3 cm: round((3.14159265358979323846264338327950288)*3^2*8,2) = 22619/100 (soll 22619/100)
- ok  #19 Kegel · Volumen, Radius 3 cm: round((3.14)*3^2*8,2) = 5652/25 (soll 5652/25)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*3^2*8,2) = 24 (soll 24)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*3^2*8,2) = 24 (soll 24)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*(3.14159265358979323846264338327950288)*1.5^2*8,2) = 377/20 (soll 377/20)
- ok  #19 Kegel · Volumen, Radius 3 cm: round(1/3*(3.14)*1.5^2*8,2) = 471/25 (soll 471/25)
- ok  #20 Kegel · Mantellinie aus Radius und Höhe: round((13),2) = 13 (soll 13)
- ok  #20 Kegel · Mantellinie aus Radius und Höhe: round(5^2+12^2,2) = 169 (soll 169)
- ok  #20 Kegel · Mantellinie aus Radius und Höhe: round((109087121146357144115021544873729018728051/10000000000000000000000000000000000000000),2) = 1091/100 (soll 1091/100)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14159265358979323846264338327950288)*6^2+(3.14159265358979323846264338327950288)*6*10,2) = 30159/100 (soll 30159/100)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14)*6^2+(3.14)*6*10,2) = 7536/25 (soll 7536/25)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14159265358979323846264338327950288)*12^2+(3.14159265358979323846264338327950288)*12*10,2) = 41469/50 (soll 41469/50)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14)*12^2+(3.14)*12*10,2) = 20724/25 (soll 20724/25)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14159265358979323846264338327950288)*6*10,2) = 377/2 (soll 377/2)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round((3.14)*6*10,2) = 942/5 (soll 942/5)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round(6^2+6*10,2) = 96 (soll 96)
- ok  #21 Kegel · Oberfläche aus Durchmesser und Mantellinie: round(6^2+6*10,2) = 96 (soll 96)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14159265358979323846264338327950288)*8^2+(3.14159265358979323846264338327950288)*8*(10),2) = 45239/100 (soll 45239/100)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14)*8^2+(3.14)*8*(10),2) = 11304/25 (soll 11304/25)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14159265358979323846264338327950288)*8^2+(3.14159265358979323846264338327950288)*8*6,2) = 17593/50 (soll 17593/50)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14)*8^2+(3.14)*8*6,2) = 8792/25 (soll 8792/25)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14159265358979323846264338327950288)*8^2+(3.14159265358979323846264338327950288)*8*(8^2+6^2),2) = 135717/50 (soll 135717/50)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14)*8^2+(3.14)*8*(8^2+6^2),2) = 67824/25 (soll 67824/25)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14159265358979323846264338327950288)*8^2+(3.14159265358979323846264338327950288)*8*(52915026221291811810032315072785208514205/10000000000000000000000000000000000000000),2) = 6681/20 (soll 6681/20)
- ok  #22 Kegel · Oberfläche aus Radius und Höhe: round((3.14)*8^2+(3.14)*8*(52915026221291811810032315072785208514205/10000000000000000000000000000000000000000),2) = 8347/25 (soll 8347/25)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*(3.14159265358979323846264338327950288)*3^2*12,0) = 113 (soll 113)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*(3.14)*3^2*12,0) = 113 (soll 113)
- ok  #23 Kegel · Trichter in Millilitern: round((3.14159265358979323846264338327950288)*3^2*12,0) = 339 (soll 339)
- ok  #23 Kegel · Trichter in Millilitern: round((3.14)*3^2*12,0) = 339 (soll 339)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*(3.14159265358979323846264338327950288)*6^2*12,0) = 452 (soll 452)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*(3.14)*6^2*12,0) = 452 (soll 452)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*3^2*12,0) = 36 (soll 36)
- ok  #23 Kegel · Trichter in Millilitern: round(1/3*3^2*12,0) = 36 (soll 36)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14159265358979323846264338327950288)*8^2*(15),2) = 100531/100 (soll 100531/100)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14)*8^2*(15),2) = 5024/5 (soll 5024/5)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14159265358979323846264338327950288)*8^2*(187882942280559359990452048386989635247523/10000000000000000000000000000000000000000),2) = 6296/5 (soll 6296/5)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14)*8^2*(187882942280559359990452048386989635247523/10000000000000000000000000000000000000000),2) = 125857/100 (soll 125857/100)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14159265358979323846264338327950288)*8^2*17,2) = 22787/20 (soll 22787/20)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round(1/3*(3.14)*8^2*17,2) = 113877/100 (soll 113877/100)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round((3.14159265358979323846264338327950288)*8^2*(15),2) = 301593/100 (soll 301593/100)
- ok  #24 Kegel · Volumen aus Mantellinie und Radius: round((3.14)*8^2*(15),2) = 15072/5 (soll 15072/5)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*(3.14159265358979323846264338327950288)*6^3,2) = 45239/50 (soll 45239/50)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*(3.14)*6^3,2) = 22608/25 (soll 22608/25)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4*(3.14159265358979323846264338327950288)*6^2,2) = 45239/100 (soll 45239/100)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4*(3.14)*6^2,2) = 11304/25 (soll 11304/25)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*(3.14159265358979323846264338327950288)*3^3,2) = 1131/10 (soll 1131/10)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*(3.14)*3^3,2) = 2826/25 (soll 2826/25)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*6^3,2) = 288 (soll 288)
- ok  #25 Kugel · Volumen, Radius 6 cm: round(4/3*6^3,2) = 288 (soll 288)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*(3.14159265358979323846264338327950288)*5^2,2) = 7854/25 (soll 7854/25)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*(3.14)*5^2,2) = 314 (soll 314)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*(3.14159265358979323846264338327950288)*10^2,2) = 31416/25 (soll 31416/25)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*(3.14)*10^2,2) = 1256 (soll 1256)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4/3*(3.14159265358979323846264338327950288)*5^3,2) = 2618/5 (soll 2618/5)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4/3*(3.14)*5^3,2) = 52333/100 (soll 52333/100)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*5^2,2) = 100 (soll 100)
- ok  #26 Kugel · Oberfläche, Durchmesser 10 cm: round(4*5^2,2) = 100 (soll 100)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14159265358979323846264338327950288)*2.5^3,2) = 1309/20 (soll 1309/20)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14)*2.5^3,2) = 3271/50 (soll 3271/50)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14159265358979323846264338327950288)*3*2.5,2) = 1571/50 (soll 1571/50)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14)*3*2.5,2) = 157/5 (soll 157/5)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4*(3.14159265358979323846264338327950288)*2.5^2,2) = 3927/50 (soll 3927/50)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4*(3.14)*2.5^2,2) = 157/2 (soll 157/2)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14159265358979323846264338327950288)*1.25^3,2) = 409/50 (soll 409/50)
- ok  #27 Kugel · Volumen, Radius 2,5 m: round(4/3*(3.14)*1.25^3,2) = 409/50 (soll 409/50)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14159265358979323846264338327950288)*0.4^2,2) = 201/100 (soll 201/100)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14)*0.4^2,2) = 201/100 (soll 201/100)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14159265358979323846264338327950288)*40^2,2) = 2010619/100 (soll 2010619/100)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14)*40^2,2) = 20096 (soll 20096)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4/3*(3.14159265358979323846264338327950288)*0.4^3,2) = 27/100 (soll 27/100)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4/3*(3.14)*0.4^3,2) = 27/100 (soll 27/100)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14159265358979323846264338327950288)*0.2^2,2) = 1/2 (soll 1/2)
- ok  #28 Kugel · Oberfläche in m², Radius 40 cm: round(4*(3.14)*0.2^2,2) = 1/2 (soll 1/2)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14159265358979323846264338327950288)*2^3,1) = 67/2 (soll 67/2)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14)*2^3,1) = 67/2 (soll 67/2)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14159265358979323846264338327950288)*4^3,1) = 2681/10 (soll 2681/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14)*4^3,1) = 2679/10 (soll 2679/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4*(3.14159265358979323846264338327950288)*2^2,1) = 503/10 (soll 503/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4*(3.14)*2^2,1) = 251/5 (soll 251/5)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14159265358979323846264338327950288)*20^3/100,1) = 3351/10 (soll 3351/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*(3.14)*20^3/100,1) = 3349/10 (soll 3349/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*2^3,1) = 107/10 (soll 107/10)
- ok  #29 Kugel · kugelförmiger Behälter in Litern: round(4/3*2^3,1) = 107/10 (soll 107/10)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14159265358979323846264338327950288)*3^2*10+1/2*4/3*(3.14159265358979323846264338327950288)*3^3,2) = 33929/100 (soll 33929/100)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14)*3^2*10+1/2*4/3*(3.14)*3^3,2) = 8478/25 (soll 8478/25)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14159265358979323846264338327950288)*3^2*10+4/3*(3.14159265358979323846264338327950288)*3^3,2) = 9896/25 (soll 9896/25)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14)*3^2*10+4/3*(3.14)*3^3,2) = 9891/25 (soll 9891/25)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14159265358979323846264338327950288)*6^2*10+1/2*4/3*(3.14159265358979323846264338327950288)*6^3,2) = 39584/25 (soll 39584/25)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14)*6^2*10+1/2*4/3*(3.14)*6^3,2) = 39564/25 (soll 39564/25)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14159265358979323846264338327950288)*3^2*10,2) = 14137/50 (soll 14137/50)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round((3.14)*3^2*10,2) = 1413/5 (soll 1413/5)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round(3^2*10+1/2*4/3*3^3,2) = 108 (soll 108)
- ok  #30 Kugel · Halbkugel auf einem Zylinder: round(3^2*10+1/2*4/3*3^3,2) = 108 (soll 108)

## Blind-Abgleich (kein Loeser)


## Hinweis Blind-Abgleich

Der Blind-Abgleich steht für diese Charge NICHT in diesem Bericht: verify-prefill wertet eine Löser-Antwort
nur als gleich, wenn sie alle hinterlegten Werte abdeckt. Bei den π-Aufgaben mit zwei Rechenwegen (π-Taste
und 3,14) nennt der Löser einen Wert, das ergäbe 11 Schein-Abweichungen. Maßgeblich ist das Gate
`node tools/verify-tasks.mjs --from-file docs/prefill/k9-koerper.json --answers-from docs/prefill/k9-koerper-blind.json --min-pass 1.0`:
30/30, 100 %. Die 3,14-Werte, die der Löser zusätzlich genannt hat, stehen alle in correct_answers (geprüft).
