# Zweitprüfung A6 Gleichungen (14 Datenmigrationen, Migration …151646_reihe1_a6_gleichungen_schluessel_prueffragen)

Frischer Subagent ohne Kontext (28.10.2026). Er hat alle Lösungsmengen-Instanzen (WZ-2, WZ-3, NP-1, NP-4, PQ-2) mit
einem eigenen Bruch-Löser nachgerechnet: alle Lösungen richtig, kein Fehlbild gleich der Lösung. Stichproben PQ-3,
PQ-4, DI-1/2/3, WZ-4, WZ-5, NP-3 von Hand: genau die markierte Zeile ist falsch, genau eine Reihenfolge, genau eine
vertretbare Option. Stufen und Rollen wie im Katalog. `session_bewerten` nimmt „−3“, „+17“, „56,25“.
Die zusätzliche FK-Zeile in sieben LSA-Tests ist transaktionslokal und harmlos.

| # | Befund | Abarbeitung |
|---|---|---|
| 1 | **P1:** WZ-3-Hinweise bei c < 0 („Die Klammer ist √c oder −√c“) lehren das Fehlbild, bei c = 0 „= −0“ | Hinweise je Fall (c < 0, c = 0, c > 0). Neu erzeugt |
| 2 | P2: Umstell-Fehlbild in PQ-1/PQ-2 Stufe 4 nie aktiv (verdrängt) | Stufe 4 prüft es zuerst; PQ-1 S4 jetzt 16/16 |
| 3 | P2: viele Katalog-Fehlbilder selten eingebbar (Antwort irrational); „nur eine Lösung“ fehlte | WZ-2: ein Drittel der Zahlen so gewählt, dass auch das Umstell-Fehlbild rational ist (13 statt 2). PQ-2: `qf_nur_eine_loesung` dazu; Zahlentripel, bei denen auch „q mit falschem Vorzeichen“ rational ist (8 statt 3). Der Rest ist durch den Zahlenraum begrenzt; ohne Fehlbild greift „Eine Lösung fehlt noch“ bzw. die allgemeine Rückmeldung |
| 4 | P2: NP-3 richtige Begründung immer „a“; PQ-3 Fehlerarten ungleich | NP-3 mischt die Begründungen; PQ-3 wählt erst die Fehlerart (10/6/8/8). Neue Blindlöser |
| 5 | P2: PQ-4-Hinweise verraten die Reihenfolge | Hinweise als Fragen ohne die Schritte zu nennen |
| 6 | P3: PQ-1-Rückmeldung passt nicht bei p > 0 | „p ist die Zahl vor x, zusammen mit dem Rechenzeichen davor.“ |
| 7 | P3: WZ-3-Rückmeldung `qf_wurzel_aus_negativ` unklar | „Ein Quadrat ist nie negativ. Hat die Gleichung dann überhaupt eine Lösung?“ |
| 8 | P3: Hinweise nah an der Antwort (WZ-4, WZ-5, NP-4), „+ 5“ in WZ-2 | umformuliert |
| 9 | P3: WZ-4-Ablenker „keine Quadratzahl“ falsch bei Quadratzahlen | anderer Ablenker bei Quadratzahlen. Neuer Blindlöser |
| 10 | P3: Fraunces hat kein ₁, ₂, √ (Fallback-Schrift im Player) | offen, gehört zum Player (Bericht) |
| 11 | P3: Prüffragen 3 und 6 im selben Kontext wie NP-3/PQ-3 | neue Kontexte (Nullprodukt allgemein, Flugbahn) |
| 12 | P3: `generator_hash` deckt `formen.py` nicht ab | bekannt; die betroffenen Bauformen sind in diesem Lauf frisch erzeugt (Bericht) |
