# SP-1b · Offene Befunde

## B1 · NS-4 Stufe 2 und 3 ohne Klartext (N1)

Die vorgegebene Beschreibung („… ihr Abstand ist gerade; der Scheitel hat ganze Koordinaten …“) ist nach der
Zweitprüfung (`klartext-pruefung.md`) unvollständig: Der Generator (`scripts/bauformen/bauformen/ns_4.py`,
`angenehm()` mit |e| ≤ 9) lässt nur Nullstellen-Abstände **2, 4 oder 6** zu; „Abstand gerade“ ließe z. B. −5 und 3
(Abstand 8) erwarten, das nie vorkommt. Weil der Text für Stufe 2 verbindlich vorgegeben war, ist er nicht geändert
und nicht eingespielt worden; die Ansicht zeigt für NS-4 weiter die Generator-Regel.

**Vorschlag:** in beiden Stufen „ihr Abstand ist 2, 4 oder 6“ statt „ihr Abstand ist gerade“; danach erneute Prüfung
und eine kleine Datenmigration.
