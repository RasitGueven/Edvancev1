# Prüfung Klartext-Nachzug SP1b

Geprüft: `docs/freigabe/sp1b/klartext-nachzug.json` gegen die Generatoren
`scripts/bauformen/bauformen/{ein_1,ko_1,ex_2,np_4,ns_4,ns_5,sch_3}.py` (`parameter()`,
`angenehm()`, `stufen`, `text`) und die erzeugten Aufgaben `docs/reihe1/A/bauformen/<KEY>.json`.

## Zusammenfassung

- 13 Stufen geprüft: 11 bestätigt, 2 strittig (NS-4 Stufe 2 und 3, gleicher Befund). Titel SCH-3
  bestätigt.
- Alle Beispiele kommen wörtlich als `frage` der genannten Stufe vor (KO-1: Punkt mit diesen
  Parametern in der Stufe vorhanden, Frage ist dort stufenunabhängig).
- Keine Mengenschreibweise, kein ∈, keine geschweiften Klammern, keine Platzhalter in den Texten.
- Strittig ist nur NS-4: Die Beschreibung verschweigt, dass der Abstand der Nullstellen höchstens 6
  ist (Generator verlangt |e| ≤ 9 für den Scheitel, also Abstand 2, 4 oder 6). „Zwischen −5 und 5“
  lässt sonst z. B. −5 und 3 (Abstand 8) erwarten, die nie vorkommen.
- Titel SCH-3 „Hoch- oder Tiefpunkt und seine Lage bestimmen“ passt: Die Aufgabe fragt
  „Hochpunkt oder Tiefpunkt, und wo liegt er?“, gewählt werden Art und Lage S(d | e).

## Tabelle

| Bauform | Stufe | Ergebnis | Befund |
|---|---|---|---|
| EIN-1 | 1 | bestätigt | Generator: a = 1, x aus 1, 3, 4, 5, 6. Daten: x = 1, 3, 4, 5, 6, a = 1. Beispiel f(5) für x² − 7x − 4 vorhanden. Nicht erwähnt (nicht prüfrelevant): Ergebnis höchstens 99 vom Nullpunkt entfernt, b von −9 bis 9 ohne 0, c von −9 bis 9. |
| EIN-1 | 2 | bestätigt | Generator: a = 1, x aus −1, −3, −4, −5, −6. Daten passen. Beispiel f(−3) für x² + 7x − 5 vorhanden. |
| EIN-1 | 3 | bestätigt | Generator: a aus −3, −2, 2, 3, x aus −1, −3, −4, −5. Daten passen. Beispiel f(−5) für −2x² + 7x − 4 vorhanden (Ergebnis −89). |
| KO-1 | 1 | bestätigt | Generator: x, y von 1 bis 5, Beträge verschieden. Punkt (2 \| 3) in Stufe 1 vorhanden. |
| KO-1 | 2 | bestätigt | Genau eine Koordinate negativ, Beträge 1 bis 5 und verschieden, nie 0 (`angenehm()` prüft x und y ≠ 0). Punkt (3 \| −5) in Stufe 2 vorhanden. |
| KO-1 | 3 | bestätigt | Beide negativ, −1 bis −5, Beträge verschieden. Punkt (−1 \| −3) in Stufe 3 vorhanden. |
| EX-2 | 3 | bestätigt | Generator: b aus 10, 20, 30, c von 1 bis 20; Scheitel bei t = b/10, also ganze Sekunde. Beispiel (b = 10, c = 4) wörtlich vorhanden. |
| EX-2 | 4 | bestätigt | b aus 5, 15, 25, 35, c von 1 bis 20; t = 0,5 / 1,5 / 2,5 / 3,5. Beispiel (b = 25, c = 2) wörtlich vorhanden. |
| NP-4 | 4 | bestätigt | Generator: a von 1 bis 4, b von −15 bis 15 ohne 0, b/a höchstens 12 vom Nullpunkt entfernt (Daten: max. 12). Beispiel „Löse 3x² = 4x.“ vorhanden. Hinweis zur Formulierung: bei a = 1 steht vor x² sichtbar keine Zahl; „mit einer Zahl davor (1 bis 4)“ ist dafür leicht ungenau. „Ganzzahlig oder ein Bruch“ schließt nichts aus (der Generator bevorzugt bei a > 1 nur Brüche). |
| NS-4 | 2 | strittig | Richtig: p, q ganzzahlig von −5 bis 5, nie 0, nie Gegenzahlen, Abstand gerade, a = 1, drei Parabeln. Es fehlt: Scheitel höchstens 9 von der x-Achse (|e| ≤ 9), daher Abstand nur 2, 4 oder 6 (Daten: genau diese). Vorschlag: „ihr Abstand ist 2, 4 oder 6“. Beispiel −4 und 2 (Abstand 6) vorhanden. |
| NS-4 | 3 | strittig | Wie Stufe 2 (gleicher fehlender Abstand höchstens 6); a = −1 oder 1, Öffnung im Text: stimmt. Beispiel „… und ist nach unten geöffnet?“ wörtlich vorhanden. |
| NS-5 | 3 | bestätigt | Generator: a aus −2, −1, 1, 2; d von −5 bis 5 ohne 0; e von −8 bis 8 ohne 0; |d| ≠ |e|. Scheitel also nie auf einer Achse, Antwort keine oder zwei; vier Bausteine (eine richtige, drei falsche). Beispiel (x + 1)² − 3 vorhanden. Nicht erwähnt (nicht prüfrelevant): Zahlenbereiche von d und e, Beträge von d und e verschieden. |
| SCH-3 | Titel | bestätigt | „Hoch- oder Tiefpunkt und seine Lage bestimmen“ entspricht der Frage „Hat f(x) = … einen Hochpunkt oder einen Tiefpunkt, und wo liegt er?“ mit Bausteinen zu Art und S(d \| e). |
