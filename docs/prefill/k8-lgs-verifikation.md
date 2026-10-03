# Verifikation k8-lgs

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
| parts[].afb | 56 | 0 | 0 | 0 |
| parts[].competency_content | 56 | 0 | 0 | 0 |
| correct_answers[].antwort | 56 | 0 | 0 | 0 |
| solution | 30 | 0 | 0 | 0 |
| typical_errors | 30 | 0 | 0 | 0 |
| correct_answers | 4 | 0 | 0 | 0 |

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
| parts[].afb | 56 | 56 | 0 | 0 |
| parts[].competency_content | 56 | 56 | 0 | 0 |
| parts[].antwort | 56 | 56 | 0 | 0 |
| tasks.competency_content | 4 | 4 | 0 | 0 |
| tasks.competency_process | 4 | 4 | 0 | 0 |
| task_solutions.correct_answers | 4 | 4 | 0 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- keine

## Nachrechnung (exakt, Skript)

- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 2: ((-1)*(17)-(3)*(1))/((-1)*(2)-(3)*(1)) = 4 (soll 4)
- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 1: ((1)*(2)-(17)*(1))/((-1)*(2)-(3)*(1)) = 3 (soll 3)
- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 1: 16/5 = 16/5 (soll 16/5)
- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 1: 17-2 = 15 (soll 15)
- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 2: 16/5+1 = 21/5 (soll 21/5)
- ok  #1 Einsetzungsverfahren · y steht frei · Klammer Teil 2: 15+1 = 16 (soll 16)
- ok  #2 Einsetzungsverfahren · x steht frei Teil 2: ((1)*(20)-(1)*(0))/((1)*(3)-(1)*(-2)) = 4 (soll 4)
- ok  #2 Einsetzungsverfahren · x steht frei Teil 1: ((0)*(3)-(20)*(-2))/((1)*(3)-(1)*(-2)) = 8 (soll 8)
- ok  #2 Einsetzungsverfahren · x steht frei Teil 1: 2*20 = 40 (soll 40)
- ok  #2 Einsetzungsverfahren · x steht frei Teil 1: 20/5 = 4 (soll 4)
- ok  #2 Einsetzungsverfahren · x steht frei Teil 2: 20 = 20 (soll 20)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 2: ((-2)*(7)-(4)*(-3))/((-2)*(-1)-(4)*(1)) = 1 (soll 1)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 1: ((-3)*(-1)-(7)*(1))/((-2)*(-1)-(4)*(1)) = 2 (soll 2)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 1: (7+3)/2 = 5 (soll 5)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 1: 7-3 = 4 (soll 4)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 2: 2*5-3 = 7 (soll 7)
- ok  #3 Einsetzungsverfahren · Minusklammer Teil 2: 2*4-3 = 5 (soll 5)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 2: ((1)*(3)-(3)*(11))/((1)*(-4)-(3)*(2)) = 3 (soll 3)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 1: ((11)*(-4)-(3)*(2))/((1)*(-4)-(3)*(2)) = 5 (soll 5)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 1: 11-2*5 = 1 (soll 1)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 1: 11-2*(-3) = 17 (soll 17)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 2: (33-3)/6 = 5 (soll 5)
- ok  #4 Einsetzungsverfahren · erst umstellen Teil 2: -(-30/(-10)) = -3 (soll -3)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 2: ((1)*(360)-(6)*(50))/((1)*(9)-(6)*(1)) = 20 (soll 20)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 1: ((50)*(9)-(360)*(1))/((1)*(9)-(6)*(1)) = 30 (soll 30)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 1: (360-6*50)/(9-6) = 20 (soll 20)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 1: 50-7.5 = 85/2 (soll 85/2)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 2: 50-20 = 30 (soll 30)
- ok  #5 Einsetzungsverfahren · Sachkontext · Kinokarten Teil 2: (360-300)/8 = 15/2 (soll 15/2)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 2: ((1)*(36)-(2)*(6))/((1)*(1)-(2)*(-1)) = 8 (soll 8)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 1: ((6)*(1)-(36)*(-1))/((1)*(1)-(2)*(-1)) = 14 (soll 14)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 1: 10+6 = 16 (soll 16)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 1: (36-6)/3 = 10 (soll 10)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 2: (36-6)/3 = 10 (soll 10)
- ok  #6 Einsetzungsverfahren · Zahlenrätsel Teil 2: 10+6 = 16 (soll 16)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 2: ((-2)*(4)-(-1)*(1))/((-2)*(1)-(-1)*(1)) = 7 (soll 7)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 1: ((1)*(1)-(4)*(1))/((-2)*(1)-(-1)*(1)) = 3 (soll 3)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 1: (4-1)/2 = 3/2 (soll 3/2)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 1: 4+1 = 5 (soll 5)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 2: 2*1.5+1 = 4 (soll 4)
- ok  #7 Gleichsetzungsverfahren · beide nach y aufgelöst Teil 2: 5+4 = 9 (soll 9)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 2: ((-3)*(6)-(-1)*(-2))/((-3)*(1)-(-1)*(1)) = 10 (soll 10)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 1: ((-2)*(1)-(6)*(1))/((-3)*(1)-(-1)*(1)) = 4 (soll 4)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 1: (6-2)/2 = 2 (soll 2)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 1: 6+2 = 8 (soll 8)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 2: 2+6 = 8 (soll 8)
- ok  #8 Gleichsetzungsverfahren · Konstante mit Minus Teil 2: 8+6 = 14 (soll 14)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 2: ((2)*(-5)-(-1)*(7))/((2)*(1)-(-1)*(1)) = -1 (soll -1)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 1: ((7)*(1)-(-5)*(1))/((2)*(1)-(-1)*(1)) = 4 (soll 4)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 1: -(-12/(-3)) = -4 (soll -4)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 1: -12/(-2) = 6 (soll 6)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 2: -4-5 = -9 (soll -9)
- ok  #9 Gleichsetzungsverfahren · negativer Koeffizient Teil 2: 6-5 = 1 (soll 1)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 2: ((1)*(4)-(2)*(5))/((1)*(-1)-(2)*(1)) = 2 (soll 2)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 1: ((5)*(-1)-(4)*(1))/((1)*(-1)-(2)*(1)) = 3 (soll 3)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 1: -(-9/(-3)) = -3 (soll -3)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 1: -9/(-1) = 9 (soll 9)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 2: -(-3)+5 = 8 (soll 8)
- ok  #10 Gleichsetzungsverfahren · erst nach y auflösen Teil 2: -9+5 = -4 (soll -4)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 2: ((-2)*(11)-(-1)*(5))/((-2)*(1)-(-1)*(1)) = 17 (soll 17)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 1: ((5)*(1)-(11)*(1))/((-2)*(1)-(-1)*(1)) = 6 (soll 6)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 1: (11-5)/2 = 3 (soll 3)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 1: 11+5 = 16 (soll 16)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 2: 2*3+5 = 11 (soll 11)
- ok  #11 Gleichsetzungsverfahren · Sachkontext · zwei Tarife Teil 2: 16+11 = 27 (soll 27)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 2: ((1)*(4)-(1)*(12))/((1)*(-2)-(1)*(2)) = 2 (soll 2)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 1: ((12)*(-2)-(4)*(2))/((1)*(-2)-(1)*(2)) = 8 (soll 8)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 1: (12-4)/2 = 4 (soll 4)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 1: 12+4 = 16 (soll 16)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 2: (12-4)/2 = 4 (soll 4)
- ok  #13 Additionsverfahren · y fällt direkt weg Teil 2: (12-16)/2 = -2 (soll -2)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 2: ((3)*(-2)-(1)*(18))/((3)*(-2)-(1)*(2)) = 3 (soll 3)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 1: ((18)*(-2)-(-2)*(2))/((3)*(-2)-(1)*(2)) = 4 (soll 4)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 1: (18-(-2))/4 = 5 (soll 5)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 1: 18+(-2) = 16 (soll 16)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 2: (18-3*5)/2 = 3/2 (soll 3/2)
- ok  #14 Additionsverfahren · negative rechte Seite Teil 2: (18-3*16)/2 = -15 (soll -15)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 2: ((2)*(5)-(1)*(13))/((2)*(1)-(1)*(3)) = 3 (soll 3)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 1: ((13)*(1)-(5)*(3))/((2)*(1)-(1)*(3)) = 2 (soll 2)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 1: 5-8 = -3 (soll -3)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 1: 5-23 = -18 (soll -18)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 2: 13-5 = 8 (soll 8)
- ok  #15 Additionsverfahren · eine Gleichung mal Faktor Teil 2: 13+10 = 23 (soll 23)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 2: ((4)*(5)-(2)*(5))/((4)*(-1)-(2)*(3)) = -1 (soll -1)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 1: ((5)*(-1)-(5)*(3))/((4)*(-1)-(2)*(3)) = 2 (soll 2)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 1: (5+5)/10 = 1 (soll 1)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 1: (5-15)/10 = -1 (soll -1)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 2: 2*1-5 = -3 (soll -3)
- ok  #16 Additionsverfahren · Faktor selbst finden Teil 2: 2*(-1)-5 = -7 (soll -7)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 2: ((2)*(20)-(1)*(34))/((2)*(2)-(1)*(3)) = 6 (soll 6)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 1: ((34)*(2)-(20)*(3))/((2)*(2)-(1)*(3)) = 8 (soll 8)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 1: (34-2*8)/3 = 6 (soll 6)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 1: 20-2*(-14) = 48 (soll 48)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 2: 20-2*6 = 8 (soll 8)
- ok  #17 Additionsverfahren · Sachkontext · Eintrittspreise Teil 2: 20-34 = -14 (soll -14)
- ok  #19 LGS grafisch · Schnittpunkt ablesen Teil 2: ((-1)*(4)-(1/2)*(1))/((-1)*(1)-(1/2)*(1)) = 3 (soll 3)
- ok  #19 LGS grafisch · Schnittpunkt ablesen Teil 1: ((1)*(1)-(4)*(1))/((-1)*(1)-(1/2)*(1)) = 2 (soll 2)
- ok  #19 LGS grafisch · Schnittpunkt ablesen Teil 1: 3 = 3 (soll 3)
- ok  #19 LGS grafisch · Schnittpunkt ablesen Teil 2: 2 = 2 (soll 2)
- ok  #20 LGS grafisch · flache Gerade Teil 2: ((-1/2)*(5)-(1)*(-1))/((-1/2)*(1)-(1)*(1)) = 1 (soll 1)
- ok  #20 LGS grafisch · flache Gerade Teil 1: ((-1)*(1)-(5)*(1))/((-1/2)*(1)-(1)*(1)) = 4 (soll 4)
- ok  #20 LGS grafisch · flache Gerade Teil 1: 1 = 1 (soll 1)
- ok  #20 LGS grafisch · flache Gerade Teil 2: 4 = 4 (soll 4)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 2: ((-1)*(-2)-(1/2)*(1))/((-1)*(1)-(1/2)*(1)) = -1 (soll -1)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 1: ((1)*(1)-(-2)*(1))/((-1)*(1)-(1/2)*(1)) = -2 (soll -2)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 1: -1 = -1 (soll -1)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 1: 2 = 2 (soll 2)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 2: -2 = -2 (soll -2)
- ok  #21 LGS grafisch · Schnittpunkt im dritten Quadranten Teil 2: 1 = 1 (soll 1)
- ok  #23 LGS grafisch · Sachkontext · zwei Tarife Teil 2: ((-1)*(4)-(-1/2)*(2))/((-1)*(1)-(-1/2)*(1)) = 6 (soll 6)
- ok  #23 LGS grafisch · Sachkontext · zwei Tarife Teil 1: ((2)*(1)-(4)*(1))/((-1)*(1)-(-1/2)*(1)) = 4 (soll 4)
- ok  #23 LGS grafisch · Sachkontext · zwei Tarife Teil 1: 6 = 6 (soll 6)
- ok  #23 LGS grafisch · Sachkontext · zwei Tarife Teil 2: 4 = 4 (soll 4)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 3: ((1)*(460)-(3)*(120))/((1)*(5)-(3)*(1)) = 50 (soll 50)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 2: ((120)*(5)-(460)*(1))/((1)*(5)-(3)*(1)) = 70 (soll 70)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 2: (460-3*120)/(5-3) = 50 (soll 50)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 2: -(-140/(-2)) = -70 (soll -70)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 3: 120-50 = 70 (soll 70)
- ok  #25 LGS Sachaufgabe · Eintrittskarten · System wählen Teil 3: 120-(-70) = 190 (soll 190)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 3: ((1)*(420)-(12)*(30))/((1)*(18)-(12)*(1)) = 10 (soll 10)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 2: ((30)*(18)-(420)*(1))/((1)*(18)-(12)*(1)) = 20 (soll 20)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 2: (420-12*30)/(18-12) = 10 (soll 10)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 2: -(-120/(-6)) = -20 (soll -20)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 3: 30-10 = 20 (soll 20)
- ok  #26 LGS Sachaufgabe · Mischung · System wählen Teil 3: 30-(-20) = 50 (soll 50)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 3: ((3)*(2)-(1)*(26))/((3)*(-1)-(1)*(1)) = 5 (soll 5)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 2: ((26)*(-1)-(2)*(1))/((3)*(-1)-(1)*(1)) = 7 (soll 7)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 2: 6+2 = 8 (soll 8)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 2: (26-2)/4 = 6 (soll 6)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 3: (26-2)/4 = 6 (soll 6)
- ok  #27 LGS Sachaufgabe · Zahlenrätsel · System wählen Teil 3: 6-2 = 4 (soll 4)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 3: ((-2)*(7)-(-3/2)*(4))/((-2)*(1)-(-3/2)*(1)) = 16 (soll 16)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 2: ((4)*(1)-(7)*(1))/((-2)*(1)-(-3/2)*(1)) = 6 (soll 6)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 2: (7-4)/2 = 3/2 (soll 3/2)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 2: 7-4 = 3 (soll 3)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 3: 2*1.5+4 = 7 (soll 7)
- ok  #28 LGS Sachaufgabe · zwei Tarife · System wählen Teil 3: 2*3+4 = 10 (soll 10)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 2: ((2)*(40)-(3)*(35))/((2)*(2)-(3)*(3)) = 5 (soll 5)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 1: ((35)*(2)-(40)*(3))/((2)*(2)-(3)*(3)) = 10 (soll 10)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 1: (40-3*10)/2 = 5 (soll 5)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 1: (35-3*13)/2 = -2 (soll -2)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 2: (3*40-2*35)/5 = 10 (soll 10)
- ok  #29 LGS Sachaufgabe · Eintrittspreise · selbst aufstellen Teil 2: (105-40)/5 = 13 (soll 13)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 2: ((2)*(5)-(1)*(34))/((2)*(-1)-(1)*(2)) = 6 (soll 6)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 1: ((34)*(-1)-(5)*(2))/((2)*(-1)-(1)*(2)) = 11 (soll 11)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 1: 14.5+5 = 39/2 (soll 39/2)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 1: 7.25+5 = 49/4 (soll 49/4)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 2: (34-5)/2 = 29/2 (soll 29/2)
- ok  #30 LGS Sachaufgabe · Rechteck · selbst aufstellen Teil 2: (34-5)/4 = 29/4 (soll 29/4)

## Blind-Abgleich (kein Loeser)

