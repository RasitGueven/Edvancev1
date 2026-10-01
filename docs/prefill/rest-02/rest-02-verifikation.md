# Verifikation rest-02

Aufgaben: 47 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| competency_process | 0 | 0 | 0 | 47 |
| est_duration_sec | 47 | 0 | 0 | 0 |
| curriculum_grade | 47 | 0 | 0 | 0 |
| cluster_id | 47 | 0 | 0 | 0 |
| competency_content | 47 | 0 | 0 | 0 |
| needs_image | 47 | 0 | 0 | 0 |
| solution | 47 | 0 | 0 | 0 |
| hints | 47 | 0 | 0 | 0 |
| typical_errors | 47 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.est_duration_sec | 47 | 47 | 0 | 0 |
| tasks.curriculum_grade | 47 | 47 | 0 | 0 |
| tasks.cluster_id | 47 | 47 | 0 | 0 |
| tasks.needs_image | 47 | 47 | 0 | 0 |
| task_solutions.solution | 47 | 47 | 0 | 0 |
| task_solutions.hints | 47 | 47 | 0 | 0 |
| task_solutions.typical_errors | 47 | 47 | 0 | 0 |
| tasks.competency_content | 47 | 47 | 0 | 0 |
| tasks.competency_process | 47 | 0 | 47 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Sachkontext · Dezimal · Kanne: 1.25+0.4 = 33/20 (soll 33/20)
- ok  #2 Sachkontext · Dezimal · Laufstrecke zusammen: 2.4+1.85 = 17/4 (soll 17/4)
- ok  #3 Sachkontext · Dezimal · Rucksackinhalt: 3.2-0.85 = 47/20 (soll 47/20)
- ok  #4 Sachkontext · Dezimal · Erde abfüllen: 7.5/2.5 = 3 (soll 3)
- ok  #5 Sachkontext · Dezimal · Saft verteilen: 1.5/0.25 = 6 (soll 6)
- ok  #6 Sachkontext · Dezimal · Schnur teilen: 4.8/0.6 = 8 (soll 8)
- ok  #7 Sachkontext · Dezimal · Fliese: 0.3*0.4 = 3/25 (soll 3/25)
- ok  #8 Sachkontext · Dezimal · Wasserhahn: 0.25*12 = 3 (soll 3)
- ok  #9 Sachkontext · Maßstab · Grundriss: 4*100/100 = 4 (soll 4)
- ok  #10 Sachkontext · Maßstab · Lageplan: 18*200/100 = 36 (soll 36)
- ok  #11 Sachkontext · Maßstab · Radtour: 9*50000/100000 = 9/2 (soll 9/2)
- ok  #12 Sachkontext · Flächen · Lieferschein: 350/100 = 7/2 (soll 7/2)
- ok  #13 Sachkontext · Flächen · Pflanzplan: 5*100 = 500 (soll 500)
- ok  #14 Sachkontext · Flächen · Stadtkarte: 20000/10000 = 2 (soll 2)
- ok  #15 Sachkontext · Gemischt · Bauanleitung: 2.06*100 = 206 (soll 206)
- ok  #16 Sachkontext · Gemischt · Etikett: 1.04*1000 = 1040 (soll 1040)
- ok  #17 Sachkontext · Gemischt · Tagesplan: 3.25*60 = 195 (soll 195)
- ok  #18 Sachkontext · Längen · Fensterbreite: 145/100 = 29/20 (soll 29/20)
- ok  #19 Sachkontext · Längen · Laufstrecke: 3.5*1000 = 3500 (soll 3500)
- ok  #20 Sachkontext · Längen · Wegweiser: 1250/1000 = 5/4 (soll 5/4)
- ok  #21 Sachkontext · Massen · Ladeliste: 2.5*1000 = 2500 (soll 2500)
- ok  #22 Sachkontext · Massen · Mehl abwiegen: 1.5*1000 = 1500 (soll 1500)
- ok  #23 Sachkontext · Massen · Versandschein: 3200/1000 = 16/5 (soll 16/5)
- ok  #24 Sachkontext · Volumen · Datenblatt: 45*1 = 45 (soll 45)
- ok  #25 Sachkontext · Volumen · Gießkanne: 2.5*1000 = 2500 (soll 2500)
- ok  #26 Sachkontext · Volumen · Messbecher: 750/1000 = 3/4 (soll 3/4)
- ok  #27 Sachkontext · Zeit · Fahrzeit: 135/60 = 9/4 (soll 9/4)
- ok  #28 Sachkontext · Zeit · Programmheft: 144/60 = 12/5 (soll 12/5)
- ok  #29 Sachkontext · Zeit · Turnierplan: 210/60 = 7/2 (soll 7/2)
- ok  #30 Sachkontext · Proportionalität · Bühnenaufbau: 6*4/8 = 3 (soll 3)
- ok  #31 Sachkontext · Proportionalität · Drucker: 20/5*12 = 48 (soll 48)
- ok  #32 Sachkontext · Proportionalität · Suppe: 600/4*10 = 1500 (soll 1500)
- ok  #33 Sachkontext · Grundwert · Bestellung: 45/0.25 = 180 (soll 180)
- ok  #34 Sachkontext · Grundwert · Bücherei: 36/0.15 = 240 (soll 240)
- ok  #35 Sachkontext · Grundwert · Chor: 21/0.35 = 60 (soll 60)
- ok  #36 Sachkontext · Prozentsatz · Fragebögen: 24/200*100 = 12 (soll 12)
- ok  #37 Sachkontext · Prozentsatz · Instrument: 15/25*100 = 60 (soll 60)
- ok  #38 Sachkontext · Prozentsatz · Regenmesser: 8/50*100 = 16 (soll 16)
- ok  #39 Sachkontext · Prozentwert · Chorstimmen: 80*0.35 = 28 (soll 28)
- ok  #40 Sachkontext · Prozentwert · Konzertkarte: 24*0.25 = 6 (soll 6)
- ok  #41 Sachkontext · Prozentwert · Schulweg: 250*0.12 = 30 (soll 30)
- ok  #42 Sachkontext · Veränderung · Fahrrad: 320*0.75 = 240 (soll 240)
- ok  #43 Sachkontext · Veränderung · Teich: 80*0.9 = 72 (soll 72)
- ok  #44 Sachkontext · Veränderung · Verein: 240*1.15 = 276 (soll 276)
- ok  #45 Sachkontext · Runden · Haushaltsbuch: round(47.38,0) = 47 (soll 47)
- ok  #46 Sachkontext · Runden · Protokoll: round(3.456,2) = 173/50 (soll 173/50)
- ok  #47 Sachkontext · Runden · Urkunde: round(12.47,1) = 25/2 (soll 25/2)

## Blind-Abgleich (docs/prefill/rest-02/rest-02-blind.json)

- ok  #1 Sachkontext · Dezimal · Kanne: Loeser 1.65 · gespeichert ["1,65"]
- ok  #2 Sachkontext · Dezimal · Laufstrecke zusammen: Loeser 4.25 · gespeichert ["4,25"]
- ok  #3 Sachkontext · Dezimal · Rucksackinhalt: Loeser 2.35 · gespeichert ["2,35"]
- ok  #4 Sachkontext · Dezimal · Erde abfüllen: Loeser 3 · gespeichert ["3"]
- ok  #5 Sachkontext · Dezimal · Saft verteilen: Loeser 6 · gespeichert ["6"]
- ok  #6 Sachkontext · Dezimal · Schnur teilen: Loeser 8 · gespeichert ["8"]
- ok  #7 Sachkontext · Dezimal · Fliese: Loeser 0.12 · gespeichert ["0,12"]
- ok  #8 Sachkontext · Dezimal · Wasserhahn: Loeser 3 · gespeichert ["3"]
- ok  #9 Sachkontext · Maßstab · Grundriss: Loeser 4 · gespeichert ["4"]
- ok  #10 Sachkontext · Maßstab · Lageplan: Loeser 36 · gespeichert ["36"]
- ok  #11 Sachkontext · Maßstab · Radtour: Loeser 4.5 · gespeichert ["4,5"]
- ok  #12 Sachkontext · Flächen · Lieferschein: Loeser 3.5 · gespeichert ["3,5"]
- ok  #13 Sachkontext · Flächen · Pflanzplan: Loeser 500 · gespeichert ["500"]
- ok  #14 Sachkontext · Flächen · Stadtkarte: Loeser 2 · gespeichert ["2"]
- ok  #15 Sachkontext · Gemischt · Bauanleitung: Loeser 206 · gespeichert ["206"]
- ok  #16 Sachkontext · Gemischt · Etikett: Loeser 1040 · gespeichert ["1040"]
- ok  #17 Sachkontext · Gemischt · Tagesplan: Loeser 195 · gespeichert ["195"]
- ok  #18 Sachkontext · Längen · Fensterbreite: Loeser 1.45 · gespeichert ["1,45"]
- ok  #19 Sachkontext · Längen · Laufstrecke: Loeser 3500 · gespeichert ["3500"]
- ok  #20 Sachkontext · Längen · Wegweiser: Loeser 1.25 · gespeichert ["1,25"]
- ok  #21 Sachkontext · Massen · Ladeliste: Loeser 2500 · gespeichert ["2500"]
- ok  #22 Sachkontext · Massen · Mehl abwiegen: Loeser 1500 · gespeichert ["1500"]
- ok  #23 Sachkontext · Massen · Versandschein: Loeser 3.2 · gespeichert ["3,2"]
- ok  #24 Sachkontext · Volumen · Datenblatt: Loeser 45 · gespeichert ["45"]
- ok  #25 Sachkontext · Volumen · Gießkanne: Loeser 2500 · gespeichert ["2500"]
- ok  #26 Sachkontext · Volumen · Messbecher: Loeser 0.75 · gespeichert ["0,75"]
- ok  #27 Sachkontext · Zeit · Fahrzeit: Loeser 2.25 · gespeichert ["2,25"]
- ok  #28 Sachkontext · Zeit · Programmheft: Loeser 2.4 · gespeichert ["2,4"]
- ok  #29 Sachkontext · Zeit · Turnierplan: Loeser 3.5 · gespeichert ["3,5"]
- ok  #30 Sachkontext · Proportionalität · Bühnenaufbau: Loeser 3 · gespeichert ["3"]
- ok  #31 Sachkontext · Proportionalität · Drucker: Loeser 48 · gespeichert ["48"]
- ok  #32 Sachkontext · Proportionalität · Suppe: Loeser 1500 · gespeichert ["1500"]
- ok  #33 Sachkontext · Grundwert · Bestellung: Loeser 180 · gespeichert ["180"]
- ok  #34 Sachkontext · Grundwert · Bücherei: Loeser 240 · gespeichert ["240"]
- ok  #35 Sachkontext · Grundwert · Chor: Loeser 60 · gespeichert ["60"]
- ok  #36 Sachkontext · Prozentsatz · Fragebögen: Loeser 12 · gespeichert ["12"]
- ok  #37 Sachkontext · Prozentsatz · Instrument: Loeser 60 · gespeichert ["60"]
- ok  #38 Sachkontext · Prozentsatz · Regenmesser: Loeser 16 · gespeichert ["16"]
- ok  #39 Sachkontext · Prozentwert · Chorstimmen: Loeser 28 · gespeichert ["28"]
- ok  #40 Sachkontext · Prozentwert · Konzertkarte: Loeser 6 · gespeichert ["6"]
- ok  #41 Sachkontext · Prozentwert · Schulweg: Loeser 30 · gespeichert ["30"]
- ok  #42 Sachkontext · Veränderung · Fahrrad: Loeser 240 · gespeichert ["240"]
- ok  #43 Sachkontext · Veränderung · Teich: Loeser 72 · gespeichert ["72"]
- ok  #44 Sachkontext · Veränderung · Verein: Loeser 276 · gespeichert ["276"]
- ok  #45 Sachkontext · Runden · Haushaltsbuch: Loeser 47 · gespeichert ["47"]
- ok  #46 Sachkontext · Runden · Protokoll: Loeser 3.46 · gespeichert ["3,46"]
- ok  #47 Sachkontext · Runden · Urkunde: Loeser 12.5 · gespeichert ["12,5"]
