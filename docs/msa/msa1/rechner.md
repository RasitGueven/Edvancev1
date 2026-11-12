# MSA-1 · M4.1 Rechner-Kennzeichen

Grundlage: die 30 Aufgaben aus dem Bericht MSA-0 §2, die nur zu schwer waren, weil das Rechner-Kennzeichen fehlte
(`docs/msa/anhang/niveau-nicht-passend.csv`, `rechner_konflikt = ja`). Nach M2 sind alle 30 noch aktiv.
Ein frischer Subagent hat jede Aufgabe selbst durchgerechnet und gefragt: Ist sie ohne Taschenrechner, nur mit Stift
und Zettel, zumutbar? Nur wo er „Rechner nötig“ bestätigt, setzt die Migration
`20261112173124_msa1_taschenrechner` das Kennzeichen `tasks.taschenrechner = true` (das Feld des eingebauten LSA-Rechners).

Ergebnis: **15 Rechner nötig**, 15 ohne Rechner zumutbar (bleiben unverändert).

| id | Skill | Status | Urteil | Begründung (ein Satz) |
|---|---|---|---|---|
| `f7e14298` | fkt_exp_wachstum | draft | ohne zumutbar | Zweimaliges Quadrieren von 1,06 (1,1236 und dann 1,2625) und Malnehmen mit 500 ergibt 631,24 und ist in unter drei Minuten schriftlich machbar, wenn auch rechenintensiv. |
| `2fbd2563` | fkt_quadr_nullstellen | draft | ohne zumutbar | Nach der Lösungsformel genügt es zu wissen, dass √184 zwischen 13,55 und 13,65 liegt (13,55² ≈ 183,6), damit t = (12 + √184)/10 auf 2,56 rundet. |
| `285e2d3e` | geo_koerper_kegel | draft | ohne zumutbar | Mit s = 10 cm (Pythagoras 6-8-10) und π ≈ 3,14 ist O = π·8·18 = 144·3,14 = 452,16 eine einzige glatte Multiplikation. |
| `62b5810c` | geo_koerper_kugel | draft | ohne zumutbar | Mit r = 2 dm und π ≈ 3,14 ist V = 4/3·3,14·8 ≈ 33,5 eine kurze Rechnung mit kleinen Zahlen. |
| `ec4153b3` | geo_koerper_kugel | draft | ohne zumutbar | Mit π ≈ 3,14 ergibt sich V = 90π + 18π = 108·3,14 = 339,12 als eine einzige Multiplikation. |
| `23fcb661` | geo_kreis_rueck | draft | ohne zumutbar | Der Radius r = 20 : 3,14 ≈ 6,37 ist eine einzelne schriftliche Division. |
| `b450d36c` | geo_kreis_rueck | draft | ohne zumutbar | Der Durchmesser d = 200 : 3,14 ≈ 63,69 ist eine einzelne schriftliche Division. |
| `cbc04c90` | geo_kreis_rueck | draft | ohne zumutbar | Aus dem Umfang 480 cm folgt d = 480 : 3,14 ≈ 152,9 und damit aufgerundet 153 durch eine einzelne Division mit grober Rundung. |
| `dce69732` | geo_kreis_sektor | draft | ohne zumutbar | Mit r = 13 cm ist A = 169·3,14 : 12 = 530,66 : 12 ≈ 44,22 eine Multiplikation und eine Division. |
| `16d86280` | geo_pythagoras_abstand | draft | ohne zumutbar | Die Abstandsrechnung führt auf eine Wurzel wie √85 und nur eine Stelle nach dem Komma ist gefragt, die sich durch Eingrenzen (9,2² = 84,64; 9,3² = 86,49) schnell ergibt; die Abbildung fehlt in den Daten. |
| `208e0467` | geo_pythagoras_anwendung | draft | ohne zumutbar | Die Höhe ist √(25 − 1,96) = √23,04 = 4,8 und damit eine glatte Quadratzahl-Rechnung (4,8² = 23,04). |
| `58c917d7` | geo_pythagoras_anwendung | draft | ohne zumutbar | h = √27 liegt wegen 5,2² = 27,04 knapp unter 5,2 und rundet auf 5,20, was sich mit einer einzigen Quadrierung prüfen lässt. |
| `75194d46` | geo_pythagoras_hypotenuse | draft | ohne zumutbar | √74 liegt nahe bei 8,6 (8,6² = 73,96) und lässt sich mit einem Newton-Schritt oder Eingrenzen auf 8,60 festlegen. |
| `379ce518` | geo_pythagoras_kathete | draft | ohne zumutbar | √51 lässt sich durch Eingrenzen (7,14² ≈ 50,98 und 7,145² ≈ 51,05) auf 7,14 festlegen, was in wenigen Minuten machbar ist. |
| `1a311c06` | geo_pythagoras_umkehrung | draft | ohne zumutbar | Mit c = √(6,25 + 16) = √22,25 genügt die Eingrenzung 4,715² ≈ 22,23 < 22,25 < 4,725², um 4,72 − 4,5 ≈ 0,22 zu erhalten. |
| `0054a031` | fkt_exp_anwendung | draft | Rechner nötig | Um 0,5^(n/6) < 0,1 zu entscheiden, muss man 2^(10/3) ≈ 10,08 gegen 10 prüfen, also mit einem gebrochenen Exponenten rechnen, den nur Logarithmus oder Wertetabelle liefert. |
| `167c44e0` | fkt_exp_anwendung | draft | Rechner nötig | Es müsste 0,85 etwa neunmal hintereinander mit sich multipliziert werden (0,85^8 ≈ 0,272 und 0,85^9 ≈ 0,232), was mit Stift und Zettel weit über drei Minuten dauert. |
| `380b85ad` | fkt_exp_anwendung | draft | Rechner nötig | Man müsste 1,05^8 ≈ 1,4775 und 1,05^9 ≈ 1,5513 durch neun aufeinanderfolgende Multiplikationen mit 1,05 bestimmen, was zu aufwendig ist. |
| `3e496b46` | fkt_exp_halbwert | draft | Rechner nötig | Man müsste 1,12^6 ≈ 1,974 und 1,12^7 ≈ 2,211 durch sieben Multiplikationen mit 1,12 ermitteln, wobei 6 Jahre nur knapp unter 2 liegen. |
| `a21f48d2` | geo_pythagoras_anwendung | draft | Rechner nötig | A = 16·√3 verlangt √3 auf mindestens vier Stellen (1,7321), um 27,71 statt 27,72 zu sichern, was ohne Taschenrechner nicht in angemessener Zeit ermittelbar ist. |
| `17b68c02` | geo_trigo_anwendung | draft | Rechner nötig | x = 25 / tan 9° verlangt den Tangens eines krummen Winkels, der nur mit Taschenrechner oder Wertetabelle bestimmbar ist. |
| `32f15d20` | geo_trigo_anwendung | draft | Rechner nötig | Die Höhe 500·8/√10064 verlangt √10064 ≈ 100,32 auf fünf Stellen und eine anschließende Division ohne gerundete Zwischenergebnisse, was zu aufwendig ist. |
| `52d18200` | geo_trigo_anwendung | draft | Rechner nötig | Die Steigung 100·tan 8° ≈ 14,1 braucht den Tangens eines krummen Winkels, der nur mit Taschenrechner oder Tabelle bestimmbar ist. |
| `13d6dc4d` | geo_trigo_seite | draft | Rechner nötig | c = 4,5 / sin 28° benötigt den Sinus von 28°, der ohne Taschenrechner nicht bestimmbar ist. |
| `33bdde50` | geo_trigo_seite | draft | Rechner nötig | b = 8,4·sin 52° benötigt den Sinus von 52°, der ohne Taschenrechner nicht bestimmbar ist. |
| `6778b0b4` | geo_trigo_seite | draft | Rechner nötig | A = ½·(12·sin 38°)·(12·cos 38°) benötigt Sinus und Cosinus von 38° auf vier Stellen genau, was nur mit Taschenrechner geht. |
| `3ba41acb` | geo_trigo_verhaeltnis | draft | Rechner nötig | Die Aufgabe verlangt ausdrücklich sin 35° auf vier Nachkommastellen mit dem Taschenrechner. |
| `7a00ab4b` | geo_trigo_winkel | draft | Rechner nötig | Der Winkel folgt aus arcsin(2,4/5,2) ≈ 27,5° und braucht die Umkehrfunktion des Sinus, die nur mit Taschenrechner oder Tabelle bestimmbar ist. |
| `a8e2cd6c` | geo_trigo_winkel | draft | Rechner nötig | Mit b = 9 cm ist α = arctan(6/9) ≈ 33,7°, wofür die Umkehrfunktion des Tangens nötig ist. |
| `ccd00ca0` | geo_trigo_winkel | draft | Rechner nötig | Mit sin α = 3/5 muss arcsin 0,6 ≈ 36,9° bestimmt werden, was ohne Taschenrechner oder Tabelle nicht auf eine Nachkommastelle möglich ist. |

Grenzfälle laut Subagent (als „ohne zumutbar“ eingestuft, bewusst nicht geändert): Wurzel auf zwei Stellen durch
Eingrenzen (`geo_pythagoras_*`), 500 · 1,06⁴, Lösungsformel mit √184. Bei strengerer Lesart wären sie „Rechner
nötig“; das entscheidet das Prüfziel MSA im Folgeauftrag. Volle Urteile: `rechner-urteil.json`.
