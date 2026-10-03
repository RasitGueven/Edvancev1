# Verifikation k9-potenz

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
| correct_answers | 18 | 0 | 0 | 0 |
| solution | 24 | 0 | 0 | 0 |
| typical_errors | 24 | 0 | 0 | 0 |
| parts[].afb | 12 | 0 | 0 | 0 |
| parts[].competency_content | 12 | 0 | 0 | 0 |
| correct_answers[].antwort | 12 | 0 | 0 | 0 |

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
| tasks.competency_content | 18 | 18 | 0 | 0 |
| tasks.competency_process | 18 | 18 | 0 | 0 |
| task_solutions.correct_answers | 18 | 18 | 0 | 0 |
| parts[].afb | 12 | 12 | 0 | 0 |
| parts[].competency_content | 12 | 12 | 0 | 0 |
| parts[].antwort | 12 | 12 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Potenzgesetze · 2³ · 2⁴ = 2ⁿ: 3+4 = 7 (soll 7)
- ok  #1 Potenzgesetze · 2³ · 2⁴ = 2ⁿ: 3*4 = 12 (soll 12)
- ok  #1 Potenzgesetze · 2³ · 2⁴ = 2ⁿ: 2^7 = 128 (soll 128)
- ok  #2 Potenzgesetze · (3²)⁴ = 3ⁿ: 2*4 = 8 (soll 8)
- ok  #2 Potenzgesetze · (3²)⁴ = 3ⁿ: 2+4 = 6 (soll 6)
- ok  #2 Potenzgesetze · (3²)⁴ = 3ⁿ: 3^8 = 6561 (soll 6561)
- ok  #3 Potenzgesetze · (a⁴)³ : a⁵ = aⁿ: 4*3-5 = 7 (soll 7)
- ok  #3 Potenzgesetze · (a⁴)³ : a⁵ = aⁿ: 4+3-5 = 2 (soll 2)
- ok  #3 Potenzgesetze · (a⁴)³ : a⁵ = aⁿ: 4*3+5 = 17 (soll 17)
- ok  #4 Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ: 5 = 5 (soll 5)
- ok  #4 Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ: 5+5 = 10 (soll 10)
- ok  #4 Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ: 10^5 = 100000 (soll 100000)
- ok  #5 Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang: 2^5*2^3 = 256 (soll 256)
- ok  #5 Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang: 2^15 = 32768 (soll 32768)
- ok  #5 Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang: 2*8 = 16 (soll 16)
- ok  #5 Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang: 8 = 8 (soll 8)
- ok  #6 Potenzgesetze · großer Würfel in kleine Würfel zerlegt: 4*3-3 = 9 (soll 9)
- ok  #6 Potenzgesetze · großer Würfel in kleine Würfel zerlegt: 3 = 3 (soll 3)
- ok  #6 Potenzgesetze · großer Würfel in kleine Würfel zerlegt: 12/3 = 4 (soll 4)
- ok  #6 Potenzgesetze · großer Würfel in kleine Würfel zerlegt: 2^9 = 512 (soll 512)
- ok  #7 Negative Hochzahl · 2⁻³: 1/2^3 = 1/8 (soll 1/8)
- ok  #7 Negative Hochzahl · 2⁻³: 0-2^3 = -8 (soll -8)
- ok  #7 Negative Hochzahl · 2⁻³: 2*(0-3) = -6 (soll -6)
- ok  #8 Negative Hochzahl · 10⁻²: 1/10^2 = 1/100 (soll 1/100)
- ok  #8 Negative Hochzahl · 10⁻²: 0-10^2 = -100 (soll -100)
- ok  #8 Negative Hochzahl · 10⁻²: 10*(0-2) = -20 (soll -20)
- ok  #8 Negative Hochzahl · 10⁻²: 1/10 = 1/10 (soll 1/10)
- ok  #9 Negative Hochzahl · 4⁻¹ · 4³: 4^2 = 16 (soll 16)
- ok  #9 Negative Hochzahl · 4⁻¹ · 4³: 0-4*4^3 = -256 (soll -256)
- ok  #9 Negative Hochzahl · 4⁻¹ · 4³: 1/4^3 = 1/64 (soll 1/64)
- ok  #10 Negative Hochzahl · (1/2)⁻² + 5⁰: 2^2+1 = 5 (soll 5)
- ok  #10 Negative Hochzahl · (1/2)⁻² + 5⁰: 0-1/4+1 = 3/4 (soll 3/4)
- ok  #10 Negative Hochzahl · (1/2)⁻² + 5⁰: 4+0 = 4 (soll 4)
- ok  #10 Negative Hochzahl · (1/2)⁻² + 5⁰: 0-1+0 = -1 (soll -1)
- ok  #11 Negative Hochzahl · Halbierung alle 4 Stunden: 1/2^5 = 1/32 (soll 1/32)
- ok  #11 Negative Hochzahl · Halbierung alle 4 Stunden: 0-2^5 = -32 (soll -32)
- ok  #11 Negative Hochzahl · Halbierung alle 4 Stunden: 1/(2*5) = 1/10 (soll 1/10)
- ok  #12 Negative Hochzahl · Faktor zwischen 2³ und 2⁻²: 2^3*2^2 = 32 (soll 32)
- ok  #12 Negative Hochzahl · Faktor zwischen 2³ und 2⁻²: 2^1 = 2 (soll 2)
- ok  #12 Negative Hochzahl · Faktor zwischen 2³ und 2⁻²: 2^3/(0-4) = -2 (soll -2)
- ok  #12 Negative Hochzahl · Faktor zwischen 2³ und 2⁻²: 2^3-1/2^2 = 31/4 (soll 31/4)
- ok  #13 Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ: 6 = 6 (soll 6)
- ok  #13 Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ: 0-6 = -6 (soll -6)
- ok  #13 Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ: 7 = 7 (soll 7)
- ok  #13 Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ: 5 = 5 (soll 5)
- ok  #14 Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ: 0-4 = -4 (soll -4)
- ok  #14 Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ: 4 = 4 (soll 4)
- ok  #14 Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ: 0-5 = -5 (soll -5)
- ok  #14 Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ: 0-3 = -3 (soll -3)
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: 7.2/10^3 = 9/1250 (soll 9/1250)
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: 7.2*10^3 = 7200 (soll 7200)
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: 7.2/10^2 = 9/125 (soll 9/125)
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: 7.2/10^4 = 9/12500 (soll 9/12500)
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: 0-7.2*10^3 = -7200 (soll -7200)
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: 4.05*10^5 = 405000 (soll 405000)
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: 4.05/10^5 = 81/2000000 (soll 81/2000000)
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: 4.05*10^4 = 40500 (soll 40500)
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: 4.05*10^6 = 4050000 (soll 4050000)
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: 4.05*10*5 = 405/2 (soll 405/2)
- ok  #17 Zehnerpotenz · Durchmesser eines roten Blutkörperchens: 0-6 = -6 (soll -6)
- ok  #17 Zehnerpotenz · Durchmesser eines roten Blutkörperchens: 6 = 6 (soll 6)
- ok  #17 Zehnerpotenz · Durchmesser eines roten Blutkörperchens: 0-7 = -7 (soll -7)
- ok  #17 Zehnerpotenz · Durchmesser eines roten Blutkörperchens: 0-5 = -5 (soll -5)
- ok  #18 Zehnerpotenz · Viren auf der Länge eines Sandkorns: 10^7/10^3 = 10000 (soll 10000)
- ok  #18 Zehnerpotenz · Viren auf der Länge eines Sandkorns: 1/10^4 = 1/10000 (soll 1/10000)
- ok  #18 Zehnerpotenz · Viren auf der Länge eines Sandkorns: 10^3 = 1000 (soll 1000)
- ok  #18 Zehnerpotenz · Viren auf der Länge eines Sandkorns: 10^5 = 100000 (soll 100000)
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 1: 3*2 = 6 (soll 6)
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 1: 3+2 = 5 (soll 5)
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 2: 4-6 = -2 (soll -2)
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 2: 4*(0-6) = -24 (soll -24)
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 2: 2 = 2 (soll 2)
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 1: 8/2 = 4 (soll 4)
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 1: 8*2 = 16 (soll 16)
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 2: 6-2 = 4 (soll 4)
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 2: 6/2 = 3 (soll 3)
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 2: 6+2 = 8 (soll 8)
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 1: 5*4/10 = 2 (soll 2)
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 1: 5*4 = 20 (soll 20)
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 2: 3+5+1 = 9 (soll 9)
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 2: 3+5 = 8 (soll 8)
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 2: 3*5 = 15 (soll 15)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 1: 3/6*10 = 5 (soll 5)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 1: 3/6 = 1/2 (soll 1/2)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 1: 3*6 = 18 (soll 18)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 2: 5+2-1 = 6 (soll 6)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 2: 5+2 = 7 (soll 7)
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 2: 5-2 = 3 (soll 3)
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 1: 3*6/10 = 9/5 (soll 9/5)
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 1: 3*6 = 18 (soll 18)
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 2: 8+1+1 = 10 (soll 10)
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 2: 8+1 = 9 (soll 9)
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 2: 8*1 = 8 (soll 8)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 1: 1.5/3*10 = 5 (soll 5)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 1: 1.5/3 = 1/2 (soll 1/2)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 1: 1.5*3 = 9/2 (soll 9/2)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 2: 11-8-1 = 2 (soll 2)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 2: 11-8 = 3 (soll 3)
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 2: 11+8 = 19 (soll 19)

## Blind-Abgleich (docs/prefill/k9-potenz-blind.json)

- ok  #1 Potenzgesetze · 2³ · 2⁴ = 2ⁿ: Loeser 7 · gespeichert ["7","+7"]
- ok  #2 Potenzgesetze · (3²)⁴ = 3ⁿ: Loeser 8 · gespeichert ["8","+8"]
- ok  #3 Potenzgesetze · (a⁴)³ : a⁵ = aⁿ: Loeser 7 · gespeichert ["7","+7"]
- ok  #4 Potenzgesetze · 2⁵ · 5⁵ = 10ⁿ: Loeser 5 · gespeichert ["5","+5"]
- ok  #5 Potenzgesetze · Zellkultur verdoppelt sich drei Stunden lang: Loeser 256 · gespeichert ["256","+256"]
- ok  #6 Potenzgesetze · großer Würfel in kleine Würfel zerlegt: Loeser 9 · gespeichert ["9","+9"]
- ok  #7 Negative Hochzahl · 2⁻³: Loeser 0.125 · gespeichert ["0,125","+0,125","0.125","+0.125","1/8","+1/8"]
- ok  #8 Negative Hochzahl · 10⁻²: Loeser 0.01 · gespeichert ["0,01","+0,01","0.01","+0.01","1/100","+1/100"]
- ok  #9 Negative Hochzahl · 4⁻¹ · 4³: Loeser 16 · gespeichert ["16","+16"]
- ok  #10 Negative Hochzahl · (1/2)⁻² + 5⁰: Loeser 5 · gespeichert ["5","+5"]
- ok  #11 Negative Hochzahl · Halbierung alle 4 Stunden: Loeser 0.03125 · gespeichert ["0,03125","+0,03125","0.03125","+0.03125","1/32","+1/32"]
- ok  #12 Negative Hochzahl · Faktor zwischen 2³ und 2⁻²: Loeser 32 · gespeichert ["32","+32"]
- ok  #13 Zehnerpotenz · 3 200 000 = 3,2 · 10ⁿ: Loeser 6 · gespeichert ["6","+6"]
- ok  #14 Zehnerpotenz · 0,00045 = 4,5 · 10ⁿ: Loeser -4 · gespeichert ["-4","−4","- 4"]
- ok  #15 Zehnerpotenz · 7,2 · 10⁻³ als Dezimalzahl: Loeser 0.0072 · gespeichert ["0,0072","+0,0072","0.0072","+0.0072"]
- ok  #16 Zehnerpotenz · 4,05 · 10⁵ als Zahl: Loeser 405000 · gespeichert ["405000","+405000"]
- ok  #17 Zehnerpotenz · Durchmesser eines roten Blutkörperchens: Loeser -6 · gespeichert ["-6","−6","- 6"]
- ok  #18 Zehnerpotenz · Viren auf der Länge eines Sandkorns: Loeser 10000 · gespeichert ["10000","+10000"]
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 1: Loeser 6 · gespeichert ["6","+6"]
- ok  #19 Wissenschaftliche Schreibweise · (3 · 10⁴) · (2 · 10⁻⁶) Teil 2: Loeser -2 · gespeichert ["-2","−2","- 2"]
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 1: Loeser 4 · gespeichert ["4","+4"]
- ok  #20 Wissenschaftliche Schreibweise · (8 · 10⁶) : (2 · 10²) Teil 2: Loeser 4 · gespeichert ["4","+4"]
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 1: Loeser 2 · gespeichert ["2","+2"]
- ok  #21 Wissenschaftliche Schreibweise · (5 · 10³) · (4 · 10⁵) normieren Teil 2: Loeser 9 · gespeichert ["9","+9"]
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 1: Loeser 5 · gespeichert ["5","+5"]
- ok  #22 Wissenschaftliche Schreibweise · (3 · 10⁵) : (6 · 10⁻²) normieren Teil 2: Loeser 6 · gespeichert ["6","+6"]
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 1: Loeser 1.8 · gespeichert ["1,8","+1,8","1.8","+1.8"]
- ok  #23 Wissenschaftliche Schreibweise · Lichtweg in einer Minute Teil 2: Loeser 10 · gespeichert ["10","+10"]
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 1: Loeser 5 · gespeichert ["5","+5"]
- ok  #24 Wissenschaftliche Schreibweise · Licht von der Sonne zur Erde Teil 2: Loeser 2 · gespeichert ["2","+2"]
