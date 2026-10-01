# Verifikation rest-01

Aufgaben: 28 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| cluster_id | 22 | 0 | 0 | 0 |
| needs_image | 22 | 0 | 0 | 0 |
| solution | 28 | 0 | 0 | 0 |
| hints | 28 | 0 | 0 | 0 |
| typical_errors | 28 | 0 | 0 | 0 |
| est_duration_sec | 6 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.cluster_id | 22 | 22 | 0 | 0 |
| tasks.needs_image | 22 | 22 | 0 | 0 |
| task_solutions.solution | 28 | 28 | 0 | 0 |
| task_solutions.hints | 28 | 28 | 0 | 0 |
| task_solutions.typical_errors | 28 | 28 | 0 | 0 |
| tasks.est_duration_sec | 6 | 6 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm: 10*6/2 = 30 (soll 30)
- ok  #2 AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm: 6*4/2 = 12 (soll 12)
- ok  #3 AFB I · Flächeneinheiten · 5 cm² in mm²: 5*100 = 500 (soll 500)
- ok  #4 AFB I · Flächeneinheiten · 8 cm² in mm²: 8*100 = 800 (soll 800)
- ok  #5 AFB I · Gemischte Schreibweise · 1,4 m in cm: 1.4*100 = 140 (soll 140)
- ok  #6 AFB I · Gemischte Schreibweise · 2,5 m in cm: 2.5*100 = 250 (soll 250)
- ok  #7 AFB I · Gleichung · 4x + 3 = 3x + 11: 4*8+3-(3*8+11) = 0 (soll 0)
- ok  #8 AFB I · Gleichung · 6x + 2 = 5x + 8: 6*6+2-(5*6+8) = 0 (soll 0)
- ok  #9 AFB I · Grundwert · 20 sind 10 %: 20/0.1 = 200 (soll 200)
- ok  #10 AFB I · Grundwert · 45 sind 10 %: 45/0.1 = 450 (soll 450)
- ok  #11 AFB I · Maßstab · 1:100, 5 cm auf dem Plan: 5*100 = 500 (soll 500)
- ok  #12 AFB I · Maßstab · 1:200, 3 cm auf dem Plan: 3*200 = 600 (soll 600)
- ok  #13 AFB I · Potenzen · 3^2: 3^2 = 9 (soll 9)
- ok  #14 AFB I · Potenzen · 5^2: 5^2 = 25 (soll 25)
- ok  #15 AFB I · Prozentuale Veränderung · 200 um 10 % größer: 200*1.1 = 220 (soll 220)
- ok  #16 AFB I · Prozentuale Veränderung · 400 um 10 % größer: 400*1.1 = 440 (soll 440)
- ok  #17 AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm: 2*3*5 = 30 (soll 30)
- ok  #18 AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm: 4*2*6 = 48 (soll 48)
- ok  #19 AFB I · Volumeneinheiten · 2 dm³ in cm³: 2*1000 = 2000 (soll 2000)
- ok  #20 AFB I · Volumeneinheiten · 5 dm³ in cm³: 5*1000 = 5000 (soll 5000)
- ok  #21 AFB I · Vorrang · -6 + 4 · 2: -6+4*2 = 2 (soll 2)
- ok  #22 AFB I · Vorrang · -8 + 5 · 3: -8+5*3 = 7 (soll 7)
- ok  #23 Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4): (3x - 2)² - (x + 4)(x - 4) ≡ Option a (gespeichert ["a"])
- ok  #24 Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2): (x + 5)² - (x + 2)(x - 2) ≡ Option a (gespeichert ["a"])
- ok  #25 Gemischt · Sachkontext · Restfläche: (x+3)^2-(x-1)^2 ≡ Option b (gespeichert ["b"])
- ok  #26 Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)²: (x + 6)(x - 6) + (x + 2)² ≡ Option b (gespeichert ["b"])
- ok  #27 Gemischt · vereinfachen · (x + 4)² - x² - 16: (x + 4)² - x² - 16 ≡ Option b (gespeichert ["b"])
- ok  #28 Gemischt · zwei Quadrate · (x + 3)² - (x - 3)²: (x + 3)² - (x - 3)² ≡ Option c (gespeichert ["c"])

## Blind-Abgleich (docs/prefill/rest-01/rest-01-blind.json)

- ok  #1 AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm: Loeser 30 · gespeichert ["30"]
- ok  #2 AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm: Loeser 12 · gespeichert ["12"]
- ok  #3 AFB I · Flächeneinheiten · 5 cm² in mm²: Loeser 500 · gespeichert ["500"]
- ok  #4 AFB I · Flächeneinheiten · 8 cm² in mm²: Loeser 800 · gespeichert ["800"]
- ok  #5 AFB I · Gemischte Schreibweise · 1,4 m in cm: Loeser 140 · gespeichert ["140"]
- ok  #6 AFB I · Gemischte Schreibweise · 2,5 m in cm: Loeser 250 · gespeichert ["250"]
- ok  #7 AFB I · Gleichung · 4x + 3 = 3x + 11: Loeser 8 · gespeichert ["8"]
- ok  #8 AFB I · Gleichung · 6x + 2 = 5x + 8: Loeser 6 · gespeichert ["6"]
- ok  #9 AFB I · Grundwert · 20 sind 10 %: Loeser 200 · gespeichert ["200"]
- ok  #10 AFB I · Grundwert · 45 sind 10 %: Loeser 450 · gespeichert ["450"]
- ok  #11 AFB I · Maßstab · 1:100, 5 cm auf dem Plan: Loeser 500 · gespeichert ["500"]
- ok  #12 AFB I · Maßstab · 1:200, 3 cm auf dem Plan: Loeser 600 · gespeichert ["600"]
- ok  #13 AFB I · Potenzen · 3^2: Loeser 9 · gespeichert ["9"]
- ok  #14 AFB I · Potenzen · 5^2: Loeser 25 · gespeichert ["25"]
- ok  #15 AFB I · Prozentuale Veränderung · 200 um 10 % größer: Loeser 220 · gespeichert ["220"]
- ok  #16 AFB I · Prozentuale Veränderung · 400 um 10 % größer: Loeser 440 · gespeichert ["440"]
- ok  #17 AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm: Loeser 30 · gespeichert ["30"]
- ok  #18 AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm: Loeser 48 · gespeichert ["48"]
- ok  #19 AFB I · Volumeneinheiten · 2 dm³ in cm³: Loeser 2000 · gespeichert ["2000"]
- ok  #20 AFB I · Volumeneinheiten · 5 dm³ in cm³: Loeser 5000 · gespeichert ["5000"]
- ok  #21 AFB I · Vorrang · -6 + 4 · 2: Loeser 2 · gespeichert ["2"]
- ok  #22 AFB I · Vorrang · -8 + 5 · 3: Loeser 7 · gespeichert ["7"]
- ok  #23 Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4): Loeser a · gespeichert ["a"]
- ok  #24 Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2): Loeser a · gespeichert ["a"]
- ok  #25 Gemischt · Sachkontext · Restfläche: Loeser b · gespeichert ["b"]
- ok  #26 Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)²: Loeser b · gespeichert ["b"]
- ok  #27 Gemischt · vereinfachen · (x + 4)² - x² - 16: Loeser b · gespeichert ["b"]
- ok  #28 Gemischt · zwei Quadrate · (x + 3)² - (x - 3)²: Loeser c · gespeichert ["c"]
