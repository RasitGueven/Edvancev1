# Verifikation k9-aehnlich

Aufgaben: 24 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| hints | 0 | 0 | 0 | 24 |
| afb | 24 | 0 | 0 | 0 |
| est_duration_sec | 24 | 0 | 0 | 0 |
| curriculum_grade | 24 | 0 | 0 | 0 |
| cluster_id | 24 | 0 | 0 | 0 |
| competency_content | 24 | 0 | 0 | 0 |
| competency_process | 24 | 0 | 0 | 0 |
| needs_image | 24 | 0 | 0 | 0 |
| correct_answers | 24 | 0 | 0 | 0 |
| solution | 24 | 0 | 0 | 0 |
| typical_errors | 24 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 24 | 24 | 0 | 0 |
| tasks.est_duration_sec | 24 | 24 | 0 | 0 |
| tasks.curriculum_grade | 24 | 24 | 0 | 0 |
| tasks.cluster_id | 24 | 24 | 0 | 0 |
| tasks.needs_image | 24 | 24 | 0 | 0 |
| task_solutions.solution | 24 | 24 | 0 | 0 |
| task_solutions.hints | 24 | 0 | 24 | 0 |
| task_solutions.typical_errors | 24 | 24 | 0 | 0 |
| tasks.competency_content | 24 | 24 | 0 | 0 |
| tasks.competency_process | 24 | 24 | 0 | 0 |
| task_solutions.correct_answers | 24 | 24 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Streckfaktor · 4 cm werden 10 cm: 10/4 = 5/2 (soll 5/2)
- ok  #1 Streckfaktor · 4 cm werden 10 cm: 4/10 = 2/5 (soll 2/5)
- ok  #1 Streckfaktor · 4 cm werden 10 cm: 10-4 = 6 (soll 6)
- ok  #2 Bildlänge · 3,5 cm mit k = 4: 3.5*4 = 14 (soll 14)
- ok  #2 Bildlänge · 3,5 cm mit k = 4: 3.5+4 = 15/2 (soll 15/2)
- ok  #2 Bildlänge · 3,5 cm mit k = 4: 3.5/4 = 7/8 (soll 7/8)
- ok  #3 Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm: 6*9/12 = 9/2 (soll 9/2)
- ok  #3 Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm: 6*12/9 = 8 (soll 8)
- ok  #3 Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm: 6-(12-9) = 3 (soll 3)
- ok  #4 Rückrichtung · Original aus 7 cm Bild und k = 2,5: 7/2.5 = 14/5 (soll 14/5)
- ok  #4 Rückrichtung · Original aus 7 cm Bild und k = 2,5: 7*2.5 = 35/2 (soll 35/2)
- ok  #4 Rückrichtung · Original aus 7 cm Bild und k = 2,5: 7-2.5 = 9/2 (soll 9/2)
- ok  #5 Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert: 13*27/9 = 39 (soll 39)
- ok  #5 Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert: 13+(27-9) = 31 (soll 31)
- ok  #5 Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert: 27/9 = 3 (soll 3)
- ok  #5 Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert: round(13*9/27,2) = 433/100 (soll 433/100)
- ok  #6 Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm: 5*45/(5+6+7) = 25/2 (soll 25/2)
- ok  #6 Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm: 5+(45-18)/3 = 14 (soll 14)
- ok  #6 Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm: 5/(45/18) = 2 (soll 2)
- ok  #6 Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm: 45/18 = 5/2 (soll 5/2)
- ok  #7 Bildfläche · 6 cm² mit k = 3: 6*3^2 = 54 (soll 54)
- ok  #7 Bildfläche · 6 cm² mit k = 3: 6*3 = 18 (soll 18)
- ok  #7 Bildfläche · 6 cm² mit k = 3: 6*2*3 = 36 (soll 36)
- ok  #8 Volumen · 5 cm³ mit k = 2: 5*2^3 = 40 (soll 40)
- ok  #8 Volumen · 5 cm³ mit k = 2: 5*2 = 10 (soll 10)
- ok  #8 Volumen · 5 cm³ mit k = 2: 5*2^2 = 20 (soll 20)
- ok  #8 Volumen · 5 cm³ mit k = 2: 5*3*2 = 30 (soll 30)
- ok  #9 Streckfaktor aus 12 cm² und 75 cm²: (5/2) = 5/2 (soll 5/2)
- ok  #9 Streckfaktor aus 12 cm² und 75 cm²: 75/12 = 25/4 (soll 25/4)
- ok  #9 Streckfaktor aus 12 cm² und 75 cm²: (2/5) = 2/5 (soll 2/5)
- ok  #9 Streckfaktor aus 12 cm² und 75 cm²: 75/12/2 = 25/8 (soll 25/8)
- ok  #10 Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm: 32*(6/4)^3 = 108 (soll 108)
- ok  #10 Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm: 32*6/4 = 48 (soll 48)
- ok  #10 Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm: 32*(6/4)^2 = 72 (soll 72)
- ok  #10 Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm: round(32*(4/6)^3,2) = 237/25 (soll 237/25)
- ok  #11 Farbe · Wandbild mit 2,5-mal so langen Seiten: 0.4*2.5^2 = 5/2 (soll 5/2)
- ok  #11 Farbe · Wandbild mit 2,5-mal so langen Seiten: 0.4*2.5 = 1 (soll 1)
- ok  #11 Farbe · Wandbild mit 2,5-mal so langen Seiten: 0.4*2*2.5 = 2 (soll 2)
- ok  #11 Farbe · Wandbild mit 2,5-mal so langen Seiten: 2.5^2 = 25/4 (soll 25/4)
- ok  #12 Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter: 0.2*50^3/1000 = 25 (soll 25)
- ok  #12 Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter: 0.2*50/1000 = 1/100 (soll 1/100)
- ok  #12 Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter: 0.2*50^2/1000 = 1/2 (soll 1/2)
- ok  #12 Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter: 0.2*50^3 = 25000 (soll 25000)
- ok  #13 Erster Strahlensatz · SD aus SA, SC und SB: 4*7.5/3 = 10 (soll 10)
- ok  #13 Erster Strahlensatz · SD aus SA, SC und SB: 4*3/7.5 = 8/5 (soll 8/5)
- ok  #13 Erster Strahlensatz · SD aus SA, SC und SB: 4+(7.5-3) = 17/2 (soll 17/2)
- ok  #14 Erster Strahlensatz · SC aus SA, SB und SD: 2*15/5 = 6 (soll 6)
- ok  #14 Erster Strahlensatz · SC aus SA, SB und SD: 5*15/2 = 75/2 (soll 75/2)
- ok  #14 Erster Strahlensatz · SC aus SA, SB und SD: 2+(15-5) = 12 (soll 12)
- ok  #15 Erster Strahlensatz · Teilstück BD: 5*6/4 = 15/2 (soll 15/2)
- ok  #15 Erster Strahlensatz · Teilstück BD: 5*6/(4+6) = 3 (soll 3)
- ok  #15 Erster Strahlensatz · Teilstück BD: 5*(4+6)/4 = 25/2 (soll 25/2)
- ok  #15 Erster Strahlensatz · Teilstück BD: 6+(5-4) = 7 (soll 7)
- ok  #16 Erster Strahlensatz · BD aus SC, SD und AC: 12*3/9 = 4 (soll 4)
- ok  #16 Erster Strahlensatz · BD aus SC, SD und AC: 12*3/(9-3) = 6 (soll 6)
- ok  #16 Erster Strahlensatz · BD aus SC, SD und AC: 12*(9-3)/9 = 8 (soll 8)
- ok  #17 Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen: 300*360/240 = 450 (soll 450)
- ok  #17 Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen: 300*360/(240+360) = 180 (soll 180)
- ok  #17 Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen: 300*(240+360)/240 = 750 (soll 750)
- ok  #17 Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen: 360+(300-240) = 420 (soll 420)
- ok  #18 Erster Strahlensatz · Metallgestell mit parallelen Streben: 3-3*1/2.5 = 9/5 (soll 9/5)
- ok  #18 Erster Strahlensatz · Metallgestell mit parallelen Streben: 3*1/2.5 = 6/5 (soll 6/5)
- ok  #18 Erster Strahlensatz · Metallgestell mit parallelen Streben: 3*1/(2.5-1) = 2 (soll 2)
- ok  #18 Erster Strahlensatz · Metallgestell mit parallelen Streben: 2.5-1 = 3/2 (soll 3/2)
- ok  #19 Zweiter Strahlensatz · CD aus SA, SC und AB: 3*5/2 = 15/2 (soll 15/2)
- ok  #19 Zweiter Strahlensatz · CD aus SA, SC und AB: 3*2/5 = 6/5 (soll 6/5)
- ok  #19 Zweiter Strahlensatz · CD aus SA, SC und AB: 3+(5-2) = 6 (soll 6)
- ok  #20 Zweiter Strahlensatz · SA aus den Parallelstrecken: 10*3/7.5 = 4 (soll 4)
- ok  #20 Zweiter Strahlensatz · SA aus den Parallelstrecken: 10*7.5/3 = 25 (soll 25)
- ok  #20 Zweiter Strahlensatz · SA aus den Parallelstrecken: 10-(7.5-3) = 11/2 (soll 11/2)
- ok  #21 Zweiter Strahlensatz · CD aus SA, AC und AB: 4*(5+3)/5 = 32/5 (soll 32/5)
- ok  #21 Zweiter Strahlensatz · CD aus SA, AC und AB: 4*3/5 = 12/5 (soll 12/5)
- ok  #21 Zweiter Strahlensatz · CD aus SA, AC und AB: 4*5/(5+3) = 5/2 (soll 5/2)
- ok  #21 Zweiter Strahlensatz · CD aus SA, AC und AB: 4+3 = 7 (soll 7)
- ok  #22 Zweiter Strahlensatz · AB aus SB, BD und CD: 7*6/(6+4.5) = 4 (soll 4)
- ok  #22 Zweiter Strahlensatz · AB aus SB, BD und CD: 7*4.5/6 = 21/4 (soll 21/4)
- ok  #22 Zweiter Strahlensatz · AB aus SB, BD und CD: 7*(6+4.5)/6 = 49/4 (soll 49/4)
- ok  #22 Zweiter Strahlensatz · AB aus SB, BD und CD: 7-4.5 = 5/2 (soll 5/2)
- ok  #23 Zweiter Strahlensatz · Baumhöhe über den Schatten: 1.5*12/2 = 9 (soll 9)
- ok  #23 Zweiter Strahlensatz · Baumhöhe über den Schatten: 2*12/1.5 = 16 (soll 16)
- ok  #23 Zweiter Strahlensatz · Baumhöhe über den Schatten: 1.5+(12-2) = 23/2 (soll 23/2)
- ok  #24 Zweiter Strahlensatz · Baumhöhe über einen Peilstab: 1.6*(2.5+10)/2.5 = 8 (soll 8)
- ok  #24 Zweiter Strahlensatz · Baumhöhe über einen Peilstab: 1.6*10/2.5 = 32/5 (soll 32/5)
- ok  #24 Zweiter Strahlensatz · Baumhöhe über einen Peilstab: 1.6*2.5/(2.5+10) = 8/25 (soll 8/25)
- ok  #24 Zweiter Strahlensatz · Baumhöhe über einen Peilstab: 1.6+10 = 58/5 (soll 58/5)

## Blind-Abgleich (docs/prefill/k9-aehnlich-blind.json)

- ok  #1 Streckfaktor · 4 cm werden 10 cm: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5"]
- ok  #2 Bildlänge · 3,5 cm mit k = 4: Loeser 14 · gespeichert ["14","14 cm","14cm"]
- ok  #3 Verkleinerung · Seite b aus a = 12 cm, a′ = 9 cm: Loeser 4.5 · gespeichert ["4,5","4.5","4,5 cm","4,5cm"]
- ok  #4 Rückrichtung · Original aus 7 cm Bild und k = 2,5: Loeser 2.8 · gespeichert ["2,8","2.8","2,8 cm","2,8cm"]
- ok  #5 Foto · 9 cm × 13 cm auf 27 cm Breite vergrößert: Loeser 39 · gespeichert ["39","39 cm","39cm"]
- ok  #6 Rückrichtung · kürzeste Seite aus dem Bildumfang 45 cm: Loeser 12.5 · gespeichert ["12,5","12.5","12,5 cm","12,5cm"]
- ok  #7 Bildfläche · 6 cm² mit k = 3: Loeser 54 · gespeichert ["54","54 cm²","54cm²"]
- ok  #8 Volumen · 5 cm³ mit k = 2: Loeser 40 · gespeichert ["40","40 cm³","40cm³"]
- ok  #9 Streckfaktor aus 12 cm² und 75 cm²: Loeser 2.5 · gespeichert ["2,5","+2,5","2.5","+2.5"]
- ok  #10 Volumen · ähnliche Quader mit Kanten 4 cm und 6 cm: Loeser 108 · gespeichert ["108","108 cm³","108cm³"]
- ok  #11 Farbe · Wandbild mit 2,5-mal so langen Seiten: Loeser 2.5 · gespeichert ["2,5","2.5","2,5 l","2,5l"]
- ok  #12 Modell · Tank im Maßstab 1 : 50 fasst 0,2 Liter: Loeser 25 · gespeichert ["25","25 m³","25m³"]
- ok  #13 Erster Strahlensatz · SD aus SA, SC und SB: Loeser 10 · gespeichert ["10","10 cm","10cm"]
- ok  #14 Erster Strahlensatz · SC aus SA, SB und SD: Loeser 6 · gespeichert ["6","6 cm","6cm"]
- ok  #15 Erster Strahlensatz · Teilstück BD: Loeser 7.5 · gespeichert ["7,5","7.5","7,5 cm","7,5cm"]
- ok  #16 Erster Strahlensatz · BD aus SC, SD und AC: Loeser 4 · gespeichert ["4","4 cm","4cm"]
- ok  #17 Erster Strahlensatz · zwei Straßen mit parallelen Querstraßen: Loeser 450 · gespeichert ["450","450 m","450m"]
- ok  #18 Erster Strahlensatz · Metallgestell mit parallelen Streben: Loeser 1.8 · gespeichert ["1,8","1.8","1,8 m","1,8m"]
- ok  #19 Zweiter Strahlensatz · CD aus SA, SC und AB: Loeser 7.5 · gespeichert ["7,5","7.5","7,5 cm","7,5cm"]
- ok  #20 Zweiter Strahlensatz · SA aus den Parallelstrecken: Loeser 4 · gespeichert ["4","4 cm","4cm"]
- ok  #21 Zweiter Strahlensatz · CD aus SA, AC und AB: Loeser 6.4 · gespeichert ["6,4","6.4","6,4 cm","6,4cm"]
- ok  #22 Zweiter Strahlensatz · AB aus SB, BD und CD: Loeser 4 · gespeichert ["4","4 cm","4cm"]
- ok  #23 Zweiter Strahlensatz · Baumhöhe über den Schatten: Loeser 9 · gespeichert ["9","9 m","9m"]
- ok  #24 Zweiter Strahlensatz · Baumhöhe über einen Peilstab: Loeser 8 · gespeichert ["8","8 m","8m"]
