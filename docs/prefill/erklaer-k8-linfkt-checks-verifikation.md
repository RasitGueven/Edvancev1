# Verifikation erklaer-k8-linfkt-checks

Aufgaben: 3 · Charge-Fehler: **0** · Bestands-Befunde: 0 · Ueberschreibungen: 0

## Feldtabelle (was die Migration auf dem Snapshot-Stand tut)

| Feld | neu | ueberschrieben | ergaenzt | bewusst leer (Kennzeichen) |
|---|---|---|---|---|
| hints | 0 | 0 | 0 | 3 |
| afb | 3 | 0 | 0 | 0 |
| est_duration_sec | 3 | 0 | 0 | 0 |
| curriculum_grade | 3 | 0 | 0 | 0 |
| cluster_id | 3 | 0 | 0 | 0 |
| competency_content | 3 | 0 | 0 | 0 |
| competency_process | 3 | 0 | 0 | 0 |
| needs_image | 3 | 0 | 0 | 0 |
| correct_answers | 3 | 0 | 0 | 0 |
| solution | 3 | 0 | 0 | 0 |
| typical_errors | 3 | 0 | 0 | 0 |

## Ueberschreibungen (alt → neu)

- keine

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 3 | 3 | 0 | 0 |
| tasks.est_duration_sec | 3 | 3 | 0 | 0 |
| tasks.curriculum_grade | 3 | 3 | 0 | 0 |
| tasks.cluster_id | 3 | 3 | 0 | 0 |
| tasks.needs_image | 3 | 3 | 0 | 0 |
| task_solutions.solution | 3 | 3 | 0 | 0 |
| task_solutions.hints | 3 | 0 | 3 | 0 |
| task_solutions.typical_errors | 3 | 3 | 0 | 0 |
| tasks.competency_content | 3 | 3 | 0 | 0 |
| tasks.competency_process | 3 | 3 | 0 | 0 |
| task_solutions.correct_answers | 3 | 3 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Check · Steigung am Graphen ablesen: (6-(-2))/(1-(-1)) = 4 (soll 4)
- ok  #1 Check · Steigung am Graphen ablesen: (1-(-1))/(6-(-2)) = 1/4 (soll 1/4)
- ok  #1 Check · Steigung am Graphen ablesen: 2/8 = 1/4 (soll 1/4)
- ok  #2 Check · Steigung aus zwei Punkten · negative Koordinaten: (4-(-2))/(1-(-3)) = 3/2 (soll 3/2)
- ok  #2 Check · Steigung aus zwei Punkten · negative Koordinaten: (4-(-2))/(-3-1) = -3/2 (soll -3/2)
- ok  #2 Check · Steigung aus zwei Punkten · negative Koordinaten: 6/(-4) = -3/2 (soll -3/2)
- ok  #2 Check · Steigung aus zwei Punkten · negative Koordinaten: (1-(-3))/(4-(-2)) = 2/3 (soll 2/3)
- ok  #3 Check · Punkt aus Steigung und Punkt: 1+3*(5-2) = 10 (soll 10)
- ok  #3 Check · Punkt aus Steigung und Punkt: 1+3 = 4 (soll 4)
- ok  #3 Check · Punkt aus Steigung und Punkt: 3*5 = 15 (soll 15)
- ok  #3 Check · Punkt aus Steigung und Punkt: 1+(5-2)/3 = 2 (soll 2)

## Blind-Abgleich (docs/prefill/erklaer-k8-linfkt-checks-blind.json)

- ok  #1 Check · Steigung am Graphen ablesen: Loeser 4 · gespeichert ["4","+4"]
- ok  #2 Check · Steigung aus zwei Punkten · negative Koordinaten: Loeser 1.5 · gespeichert ["3/2","+3/2","1,5","+1,5","1.5","+1.5"]
- ok  #3 Check · Punkt aus Steigung und Punkt: Loeser 10 · gespeichert ["10","+10"]
