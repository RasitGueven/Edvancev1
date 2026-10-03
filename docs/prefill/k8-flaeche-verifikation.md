# Verifikation k8-flaeche

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

- ok  #1 Trapez · a = 8 cm, c = 4 cm, h = 5 cm: (8+4)/2*5 = 30 (soll 30)
- ok  #1 Trapez · a = 8 cm, c = 4 cm, h = 5 cm: 8*5 = 40 (soll 40)
- ok  #1 Trapez · a = 8 cm, c = 4 cm, h = 5 cm: 4*5 = 20 (soll 20)
- ok  #1 Trapez · a = 8 cm, c = 4 cm, h = 5 cm: (8+4)*5 = 60 (soll 60)
- ok  #2 Trapez · a = 10 cm, c = 6 cm, h = 7 cm: (10+6)/2*7 = 56 (soll 56)
- ok  #2 Trapez · a = 10 cm, c = 6 cm, h = 7 cm: 10*7 = 70 (soll 70)
- ok  #2 Trapez · a = 10 cm, c = 6 cm, h = 7 cm: 6*7 = 42 (soll 42)
- ok  #2 Trapez · a = 10 cm, c = 6 cm, h = 7 cm: (10+6)*7 = 112 (soll 112)
- ok  #2 Trapez · a = 10 cm, c = 6 cm, h = 7 cm: 10+6/2*7 = 31 (soll 31)
- ok  #3 Trapez · gleichschenklig, Schenkel als Ablenker: (11+5)/2*4 = 32 (soll 32)
- ok  #3 Trapez · gleichschenklig, Schenkel als Ablenker: (11+5)/2*5 = 40 (soll 40)
- ok  #3 Trapez · gleichschenklig, Schenkel als Ablenker: 11*4 = 44 (soll 44)
- ok  #3 Trapez · gleichschenklig, Schenkel als Ablenker: 5*4 = 20 (soll 20)
- ok  #3 Trapez · gleichschenklig, Schenkel als Ablenker: (11+5)*4 = 64 (soll 64)
- ok  #4 Trapez · Dezimalmaße: (6.5+3.5)/2*4.2 = 21 (soll 21)
- ok  #4 Trapez · Dezimalmaße: 6.5*4.2 = 273/10 (soll 273/10)
- ok  #4 Trapez · Dezimalmaße: 3.5*4.2 = 147/10 (soll 147/10)
- ok  #4 Trapez · Dezimalmaße: (6.5+3.5)*4.2 = 42 (soll 42)
- ok  #4 Trapez · Dezimalmaße: 6.5+3.5/2*4.2 = 277/20 (soll 277/20)
- ok  #5 Trapez · Sachkontext · Dachfläche: (12+8)/2*5 = 50 (soll 50)
- ok  #5 Trapez · Sachkontext · Dachfläche: 12*5 = 60 (soll 60)
- ok  #5 Trapez · Sachkontext · Dachfläche: 8*5 = 40 (soll 40)
- ok  #5 Trapez · Sachkontext · Dachfläche: (12+8)*5 = 100 (soll 100)
- ok  #6 Trapez · Sachkontext · Grundstückspreis: (32+24)/2*18*150 = 75600 (soll 75600)
- ok  #6 Trapez · Sachkontext · Grundstückspreis: 32*18*150 = 86400 (soll 86400)
- ok  #6 Trapez · Sachkontext · Grundstückspreis: 24*18*150 = 64800 (soll 64800)
- ok  #6 Trapez · Sachkontext · Grundstückspreis: (32+24)*18*150 = 151200 (soll 151200)
- ok  #7 Drachenviereck · e = 8 cm, f = 6 cm: 8*6/2 = 24 (soll 24)
- ok  #7 Drachenviereck · e = 8 cm, f = 6 cm: 8*6 = 48 (soll 48)
- ok  #7 Drachenviereck · e = 8 cm, f = 6 cm: 8+6 = 14 (soll 14)
- ok  #8 Raute · e = 10 cm, f = 7 cm: 10*7/2 = 35 (soll 35)
- ok  #8 Raute · e = 10 cm, f = 7 cm: 10*7 = 70 (soll 70)
- ok  #8 Raute · e = 10 cm, f = 7 cm: 10+7 = 17 (soll 17)
- ok  #9 Raute · Seitenlänge als Ablenker: 24*10/2 = 120 (soll 120)
- ok  #9 Raute · Seitenlänge als Ablenker: 24*10 = 240 (soll 240)
- ok  #9 Raute · Seitenlänge als Ablenker: 13*13 = 169 (soll 169)
- ok  #9 Raute · Seitenlänge als Ablenker: 4*13 = 52 (soll 52)
- ok  #10 Drachenviereck · Dezimalmaße: 7.5*4.8/2 = 18 (soll 18)
- ok  #10 Drachenviereck · Dezimalmaße: 7.5*4.8 = 36 (soll 36)
- ok  #10 Drachenviereck · Dezimalmaße: 7.5+4.8 = 123/10 (soll 123/10)
- ok  #11 Drachen · Sachkontext · Papierdrachen: 90*60/2 = 2700 (soll 2700)
- ok  #11 Drachen · Sachkontext · Papierdrachen: 90*60 = 5400 (soll 5400)
- ok  #11 Drachen · Sachkontext · Papierdrachen: 90+60 = 150 (soll 150)
- ok  #12 Raute · Sachkontext · vierzig Fliesen: 40*20*12/2 = 4800 (soll 4800)
- ok  #12 Raute · Sachkontext · vierzig Fliesen: 40*20*12 = 9600 (soll 9600)
- ok  #12 Raute · Sachkontext · vierzig Fliesen: 40*(20+12) = 1280 (soll 1280)
- ok  #13 Haus-Form · Rechteck mit aufgesetztem Dreieck: 8*5+8*3/2 = 52 (soll 52)
- ok  #13 Haus-Form · Rechteck mit aufgesetztem Dreieck: 8*5 = 40 (soll 40)
- ok  #13 Haus-Form · Rechteck mit aufgesetztem Dreieck: 8*3/2 = 12 (soll 12)
- ok  #13 Haus-Form · Rechteck mit aufgesetztem Dreieck: 8*5+8*3 = 64 (soll 64)
- ok  #14 L-Form · Rechteck mit ausgeschnittener Ecke: 10*8-4*3 = 68 (soll 68)
- ok  #14 L-Form · Rechteck mit ausgeschnittener Ecke: 10*8 = 80 (soll 80)
- ok  #14 L-Form · Rechteck mit ausgeschnittener Ecke: 2*(10+8) = 36 (soll 36)
- ok  #15 Rechteck mit angesetztem Trapez: 6*4+(6+2)/2*3 = 36 (soll 36)
- ok  #15 Rechteck mit angesetztem Trapez: 6*4 = 24 (soll 24)
- ok  #15 Rechteck mit angesetztem Trapez: (6+2)/2*3 = 12 (soll 12)
- ok  #15 Rechteck mit angesetztem Trapez: 6*4+6*3 = 42 (soll 42)
- ok  #15 Rechteck mit angesetztem Trapez: 6*4+2*3 = 30 (soll 30)
- ok  #15 Rechteck mit angesetztem Trapez: 6*4+(6+2)*3 = 48 (soll 48)
- ok  #16 Quadrat mit ausgeschnittener Raute: 10*10-6*4/2 = 88 (soll 88)
- ok  #16 Quadrat mit ausgeschnittener Raute: 10*10 = 100 (soll 100)
- ok  #16 Quadrat mit ausgeschnittener Raute: 10*10-6*4 = 76 (soll 76)
- ok  #16 Quadrat mit ausgeschnittener Raute: 6*4/2 = 12 (soll 12)
- ok  #17 Sachkontext · Rasen um ein dreieckiges Beet: 12*9-4*3/2 = 102 (soll 102)
- ok  #17 Sachkontext · Rasen um ein dreieckiges Beet: 12*9 = 108 (soll 108)
- ok  #17 Sachkontext · Rasen um ein dreieckiges Beet: 12*9-4*3 = 96 (soll 96)
- ok  #17 Sachkontext · Rasen um ein dreieckiges Beet: 2*(12+9) = 42 (soll 42)
- ok  #18 Sachkontext · Giebelwand mit Fenster: 9*6+9*4/2-1.5*1.2 = 351/5 (soll 351/5)
- ok  #18 Sachkontext · Giebelwand mit Fenster: 9*6+9*4/2 = 72 (soll 72)
- ok  #18 Sachkontext · Giebelwand mit Fenster: 9*6-1.5*1.2 = 261/5 (soll 261/5)
- ok  #18 Sachkontext · Giebelwand mit Fenster: 9*6+9*4-1.5*1.2 = 441/5 (soll 441/5)
- ok  #19 Term · Rechteck x mal 5: x*5 ≡ Option b (gespeichert ["b"])
- ok  #20 Term · Rechteck (x + 3) mal 4: 4*(x+3) ≡ Option c (gespeichert ["c"])
- ok  #21 Term · Dreieck mit Grundseite x + 4: (x+4)*6/2 ≡ Option b (gespeichert ["b"])
- ok  #22 Term · Rechteck mit angesetztem Quadrat: x*4+4*4 ≡ Option c (gespeichert ["c"])
- ok  #23 Term · Sachkontext · Terrasse 3 m länger als breit: (4+3)*4 = 28 (soll 28)
- ok  #23 Term · Sachkontext · Terrasse 3 m länger als breit: 4+3*4 = 16 (soll 16)
- ok  #23 Term · Sachkontext · Terrasse 3 m länger als breit: (4+3)+4 = 11 (soll 11)
- ok  #23 Term · Sachkontext · Terrasse 3 m länger als breit: 2*((4+3)+4) = 22 (soll 22)
- ok  #24 Term · Sachkontext · Beet doppelt so lang wie breit: 2*3.5*3.5 = 49/2 (soll 49/2)
- ok  #24 Term · Sachkontext · Beet doppelt so lang wie breit: 2*3.5+3.5 = 21/2 (soll 21/2)
- ok  #24 Term · Sachkontext · Beet doppelt so lang wie breit: 2*(2*3.5+3.5) = 21 (soll 21)
- ok  #25 Rückrichtung · Höhe im Parallelogramm: 42/7 = 6 (soll 6)
- ok  #25 Rückrichtung · Höhe im Parallelogramm: 42*7 = 294 (soll 294)
- ok  #25 Rückrichtung · Höhe im Parallelogramm: 2*42/7 = 12 (soll 12)
- ok  #26 Rückrichtung · Höhe im Dreieck: 2*30/12 = 5 (soll 5)
- ok  #26 Rückrichtung · Höhe im Dreieck: 30/12 = 5/2 (soll 5/2)
- ok  #26 Rückrichtung · Höhe im Dreieck: 30*12/2 = 180 (soll 180)
- ok  #27 Rückrichtung · Höhe im Trapez: 63/((12+6)/2) = 7 (soll 7)
- ok  #27 Rückrichtung · Höhe im Trapez: 63/12*2 = 21/2 (soll 21/2)
- ok  #27 Rückrichtung · Höhe im Trapez: 63/6*2 = 21 (soll 21)
- ok  #27 Rückrichtung · Höhe im Trapez: 63/(12+6) = 7/2 (soll 7/2)
- ok  #28 Rückrichtung · fehlende parallele Seite im Trapez: 2*40/5-9 = 7 (soll 7)
- ok  #28 Rückrichtung · fehlende parallele Seite im Trapez: 40/5 = 8 (soll 8)
- ok  #28 Rückrichtung · fehlende parallele Seite im Trapez: 2*40/5 = 16 (soll 16)
- ok  #29 Rückrichtung · Sachkontext · Beet als Parallelogramm: 18/4.5 = 4 (soll 4)
- ok  #29 Rückrichtung · Sachkontext · Beet als Parallelogramm: 18*4.5 = 81 (soll 81)
- ok  #29 Rückrichtung · Sachkontext · Beet als Parallelogramm: 2*18/4.5 = 8 (soll 8)
- ok  #30 Rückrichtung · Sachkontext · dreieckiges Segel: 2*7.5/3 = 5 (soll 5)
- ok  #30 Rückrichtung · Sachkontext · dreieckiges Segel: 7.5/3 = 5/2 (soll 5/2)
- ok  #30 Rückrichtung · Sachkontext · dreieckiges Segel: 7.5*3/2 = 45/4 (soll 45/4)

## Blind-Abgleich (kein Loeser)

