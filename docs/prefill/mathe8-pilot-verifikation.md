# Verifikation mathe8-pilot

Aufgaben: 25 · Charge-Fehler: **0** · Bestands-Befunde: 6

## Vollstaendigkeit je Feld

| Feld | vorher leer | jetzt befuellt | bewusst leer | ungeklaert |
|---|---|---|---|---|
| tasks.afb | 4 | 4 | 0 | 0 |
| tasks.curriculum_grade | 2 | 0 | 2 | 0 |
| task_solutions.solution | 25 | 24 | 1 | 0 |
| task_solutions.hints | 25 | 23 | 2 | 0 |
| task_solutions.typical_errors | 25 | 23 | 2 | 0 |
| task_solutions.coach_hints | 25 | 0 | 25 | 0 |
| parts[].afb | 4 | 4 | 0 | 0 |
| parts[].competency_content | 4 | 4 | 0 | 0 |
| parts[].antwort | 4 | 4 | 0 | 0 |
| tasks.est_duration_sec | 22 | 21 | 1 | 0 |
| tasks.competency_process | 3 | 1 | 2 | 0 |
| task_solutions.correct_answers | 2 | 0 | 2 | 0 |
| tasks.unit | 3 | 0 | 3 | 0 |
| tasks.needs_image | 3 | 0 | 3 | 0 |
| tasks.input_type | 1 | 0 | 1 | 0 |

## Charge-Fehler (Gate)

- keine

## Bestands-Befunde (gesetzte Werte, nicht ueberschrieben)

- #2 Aussagen zur proportionalen Zuordnung: MC ohne Optionen in question_payload
- #3 Berechne x: NUMERIC-Antwort ["x = 9"] enthaelt "x =" — Eingabe "9" wird als falsch gewertet
- #3 Berechne x: nachgerechneter Wert 9 fehlt in correct_answers ["x = 9"]
- #18 Eiscafé: Teil 2 (mc): Antwort ["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."] ist keine Options-ID — nie richtig wertbar
- #18 Eiscafé: Teil 2: correct_answers enthaelt Kodiertext ["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."]
- #18 Eiscafé: Blind-Loeser a ≠ gespeichert ["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."]

## Nachrechnung (exakt, Skript)

- ok  #1 Andere Länder - andere Noten Teil 1: 30/50*5+1 = 4 (soll 4)
- ok  #1 Andere Länder - andere Noten Teil 2: round(90/100*5+1,1) = 11/2 (soll 11/2)
- ok  #1 Andere Länder - andere Noten Teil 2: round(89/100*5+1,1) = 11/2 (soll 11/2)
- ok  #1 Andere Länder - andere Noten Teil 4: Formel P/M*9+1 an 3 Stellen und alle Antwort-Varianten
- ok  #3 Berechne x: 8*9 = 72 (soll 72)
- ok  #4 Binomische Formel · Quadrat · (2x + 3)²: (2x + 3)² ≡ Option a (gespeichert ["a"])
- ok  #5 Binomische Formel · Quadrat · (3x - 4)²: (3x - 4)² ≡ Option d (gespeichert ["d"])
- ok  #6 Binomische Formel · Quadrat · (x - 5)²: (x - 5)² ≡ Option b (gespeichert ["b"])
- ok  #7 Binomische Formel · Quadrat · (x + 3)²: (x + 3)² ≡ Option c (gespeichert ["c"])
- ok  #8 Binomische Formel · Rückrichtung · x² + 20x + 100: x² + 20x + 100 ≡ Option b (gespeichert ["b"])
- ok  #9 Binomische Formel · Sachkontext · quadratisches Beet: (x+4)^2 ≡ Option a (gespeichert ["a"])
- ok  #10 Dritte binomische Formel · (2x - 9)(2x + 9): (2x - 9)(2x + 9) ≡ Option d (gespeichert ["d"])
- ok  #11 Dritte binomische Formel · (3x + 5)(3x - 5): (3x + 5)(3x - 5) ≡ Option a (gespeichert ["a"])
- ok  #12 Dritte binomische Formel · (x - 7)(x + 7): (x - 7)(x + 7) ≡ Option c (gespeichert ["c"])
- ok  #13 Dritte binomische Formel · (x + 4)(x - 4): (x + 4)(x - 4) ≡ Option a (gespeichert ["a"])
- ok  #14 Dritte binomische Formel · geschicktes Rechnen · 102 · 98: (100+2)*(100-2) = 9996 (soll 9996)
- ok  #15 Dritte binomische Formel · Sachkontext · Grundstück: (x+5)(x-5) ≡ Option c (gespeichert ["c"])
- ok  #16 Druckmaschinen Teil 1: 90000/(60000/4) = 6 (soll 6)
- ok  #16 Druckmaschinen Teil 2: 60000/(2*60000/4) = 2 (soll 2)
- ok  #17 Eindeutig: 3*2+32-(17*2+4) = 0 (soll 0)
- ok  #17 Eindeutig: 3+32*0.5-(17+4*0.5) = 0 (soll 0)
- ok  #17 Eindeutig: (7+2)-(7+2) = 0 (soll 0)
- ok  #18 Eiscafé Teil 1: 4*0.80+0.50 = 37/10 (soll 37/10)
- ok  #18 Eiscafé Teil 2: 4.50/5 = 9/10 (soll 9/10)
- ok  #19 Faktorisieren · Differenz von Quadraten · x² - 25: x² - 25 ≡ Option a (gespeichert ["a"])
- ok  #20 Faktorisieren · gemeinsamer Faktor und Quadrat · 3x² + 12x + 12: 3x² + 12x + 12 ≡ Option c (gespeichert ["c"])
- ok  #21 Faktorisieren · gemeinsamer Faktor zuerst · 2x² - 18: 2x² - 18 ≡ Option b (gespeichert ["b"])
- ok  #22 Faktorisieren · geschicktes Rechnen · 47² - 43²: 47^2-43^2 = 360 (soll 360)
- ok  #23 Faktorisieren · vollständiges Quadrat · x² + 8x + 16: x² + 8x + 16 ≡ Option b (gespeichert ["b"])
- ok  #24 Faktorisieren · zweistufig · x⁴ - 16: x⁴ - 16 ≡ Option b (gespeichert ["b"])
- ok  #25 Fliesen: 50*0.16/0.2 = 40 (soll 40)
- ok  #25 Fliesen: 50*0.2/0.16 = 125/2 (soll 125/2)

## Blind-Abgleich (docs/prefill/mathe8-pilot-blind.json)

- ok  #1 Andere Länder - andere Noten Teil 1: Loeser 4 · gespeichert ["4","4,0"]
- ok  #1 Andere Länder - andere Noten Teil 2: Loeser 90;89 · gespeichert ["90","89"]
- info #1 Andere Länder - andere Noten Teil 3: Loeser nennt die Aufgabe nicht eindeutig (Freitext)
- ok  #1 Andere Länder - andere Noten Teil 4: Loeser P/M*9+1 · gespeichert ["Note = erreichte Punktzahl / Maximalpunktzahl · 9 + 1","erreichte Punktzahl / Maximalpunktzahl · 9 + 1"]
- info #2 Aussagen zur proportionalen Zuordnung: Loeser nennt die Aufgabe nicht eindeutig (Abbildung und Optionen fehlen)
- ok  #3 Berechne x: Loeser 9 · gespeichert ["x = 9"]
- ok  #4 Binomische Formel · Quadrat · (2x + 3)²: Loeser a · gespeichert ["a"]
- ok  #5 Binomische Formel · Quadrat · (3x - 4)²: Loeser d · gespeichert ["d"]
- ok  #6 Binomische Formel · Quadrat · (x - 5)²: Loeser b · gespeichert ["b"]
- ok  #7 Binomische Formel · Quadrat · (x + 3)²: Loeser c · gespeichert ["c"]
- ok  #8 Binomische Formel · Rückrichtung · x² + 20x + 100: Loeser b · gespeichert ["b"]
- ok  #9 Binomische Formel · Sachkontext · quadratisches Beet: Loeser a · gespeichert ["a"]
- ok  #10 Dritte binomische Formel · (2x - 9)(2x + 9): Loeser d · gespeichert ["d"]
- ok  #11 Dritte binomische Formel · (3x + 5)(3x - 5): Loeser a · gespeichert ["a"]
- ok  #12 Dritte binomische Formel · (x - 7)(x + 7): Loeser c · gespeichert ["c"]
- ok  #13 Dritte binomische Formel · (x + 4)(x - 4): Loeser a · gespeichert ["a"]
- ok  #14 Dritte binomische Formel · geschicktes Rechnen · 102 · 98: Loeser 9996 · gespeichert ["9996"]
- ok  #15 Dritte binomische Formel · Sachkontext · Grundstück: Loeser c · gespeichert ["c"]
- ok  #16 Druckmaschinen Teil 1: Loeser 6 · gespeichert ["6"]
- ok  #16 Druckmaschinen Teil 2: Loeser 2 · gespeichert ["2"]
- info #17 Eindeutig: Loeser nennt die Aufgabe nicht eindeutig (Text bricht ab, keine Aufgabenstellung (Gleichungen von Selina und Jasmin fehlen))
- ok  #18 Eiscafé Teil 1: Loeser 3.7 · gespeichert ["3,70"]
- ABWEICHUNG #18 Eiscafé Teil 2: Loeser a · gespeichert ["Eiscafé Arnoldo ist angekreuzt","UND","Lösungsweg, bei dem der Preis für eine Kugel Eis im Eiscafé Venezia oder der Gesamtpreis für fünf Kugeln im Eiscafé Arnoldo berechnet wurde."]
- ok  #19 Faktorisieren · Differenz von Quadraten · x² - 25: Loeser a · gespeichert ["a"]
- ok  #20 Faktorisieren · gemeinsamer Faktor und Quadrat · 3x² + 12x + 12: Loeser c · gespeichert ["c"]
- ok  #21 Faktorisieren · gemeinsamer Faktor zuerst · 2x² - 18: Loeser b · gespeichert ["b"]
- ok  #22 Faktorisieren · geschicktes Rechnen · 47² - 43²: Loeser 360 · gespeichert ["360"]
- ok  #23 Faktorisieren · vollständiges Quadrat · x² + 8x + 16: Loeser b · gespeichert ["b"]
- ok  #24 Faktorisieren · zweistufig · x⁴ - 16: Loeser b · gespeichert ["b"]
- ok  #25 Fliesen: Loeser 40 · gespeichert ["40"]
