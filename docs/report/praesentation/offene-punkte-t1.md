# T1 · Offene Punkte und Zahlen

Stand 19.10.2026, Branch `feat/rasit-praesentation-daten`. Zahlen aus Prod (dbread, nur lesend), gerechnet
mit `bauePraesentation` (darin `baueElternbericht` aus R7-1) und dem Katalog vom 19.10. (130 Skills).
Auswahl der Analysen über die ID, je genau eine Sitzung. Keine Namen.

## Analysen (Melden)

Zählweise in den Klammern: sicher · Übungsbedarf ohne übersprungen · übersprungen.

| Analyse | Klasse | sicher | Übungsbedarf (R7) | davon übersprungen | untersucht | Katalog |
|---|---|---|---|---|---|---|
| 6d868c5f (Ilkay) | 10 | 11 | 16 | 0 | 27 | 130 (bis Kl. 10) |
| c84ba103 | 8 | 12 | 10 | **1** | 22 | 73 (bis Kl. 8) |
| 09cf8baa | 9 | 1 | 5 | 0 | 6 | 115 (bis Kl. 9) |

Alle Werte gleich den R7-1-Zahlen in `docs/report/r7/offene-punkte-r7-1.md`, Ilkay gleich Anhang C.

**Zeilen** (sicher · Übungsbedarf · übersprungen, untersucht von vorhanden):

| Feld | 6d868c5f | c84ba103 | 09cf8baa |
|---|---|---|---|
| Brüche & Dezimalzahlen | 2·3·0, 5 von 8 | 3·1·0, 4 von 8 | – |
| Prozent & Dreisatz | 1·3·0, 4 von 9 | 2·0·0, 2 von 9 | – |
| Terme & Gleichungen | 2·2·0, 4 von 23 | 1·2·**1**, 4 von 19 | – |
| Geometrie | 1·5·0, 6 von 40 | 3·3·0, 6 von 16 | – |
| Größen | 3·2·0, 5 von 6 | 2·2·0, 4 von 6 | – |
| Zahlen & Rechnen | 2·1·0, 3 von 14 | 1·1·0, 2 von 5 | 1·5·0, 6 von 14 |

**Ebenen** (Klassenangabe, sicher · Übungsbedarf · übersprungen):

- 6d868c5f: Weiterführende Themen · 7/8 · 4·8·0; Grundlagen · 5/6 · 7·8·0
- c84ba103: Aktueller Unterrichtsstoff · 7/8 · 4·4·**1**; Grundlagen · 5/6 · 8·5·0
- 09cf8baa: Aktueller Unterrichtsstoff · 9/10 · 1·4·0; Grundlagen · 5/6 · 0·1·0

**Schwerpunkte** (* = gemischt, „Stoff aus"):

- 6d868c5f: Geometrie* (Klasse 5–8), Brüche & Dezimalzahlen* (5/6), Größen* (5/6), Prozent & Dreisatz* (7/8);
  danach Terme & Gleichungen, Zahlen & Rechnen
- c84ba103: Geometrie* (5–8), Größen* (5/6), Brüche & Dezimalzahlen* (5/6), Terme & Gleichungen* (7/8);
  danach Zahlen & Rechnen
- 09cf8baa: Zahlen & Rechnen* (**5–10**, siehe offener Punkt 2)

**Überblick** (Station 01):

- 6d868c5f: Schon gelungen = Größen, Zahlen & Rechnen · Gezielt üben = Geometrie, Brüche & Dezimalzahlen
- c84ba103: Schon gelungen = Brüche & Dezimalzahlen, Prozent & Dreisatz · Gezielt üben = Terme & Gleichungen,
  Geometrie (beide 3 mit Übungsbedarf, Gleichstand → Reihenfolge der Themenfelder)
- 09cf8baa: Schon gelungen leer → „Ein Bereich ist schon sicher: …" (1) · Gezielt üben = Zahlen & Rechnen

## Grundlage für Abnahme 8 (alle abgeschlossenen Sitzungen)

22 abgeschlossene echte Sitzungen, davon 12 mit direkten Urteilen; 1 Testlauf.

**(a) Verteilung von `zustand` bei `belegt_direkt`:**

| zustand | echt: Bereiche (Sitzungen) | davon offen | Testlauf: Bereiche |
|---|---|---|---|
| traegt | 93 (12) | 0 | 4 |
| traegt_nicht | 52 (11) | 3 | 6 |
| traegt_teilweise | 19 (9) | 0 | 2 |
| nicht_angesetzt | **9 (5)** | 0 | 1 |

**(b) direkt geprüfte Bereiche mit mindestens einer Antwort `weiss_nicht` oder `leer`**
(Join `lsa_responses.task_id → tasks.skill_key`, je Sitzung):

| zustand | echt: mit „Weiß ich nicht"/leer | von | Testlauf |
|---|---|---|---|
| traegt | 0 | 93 | 0 von 4 |
| traegt_nicht | 7 | 52 | 2 von 6 |
| traegt_teilweise | 3 | 19 | 1 von 2 |
| nicht_angesetzt | 9 | 9 | 1 von 1 |

- `leer` kommt in Prod bisher nicht vor: alle Treffer sind `weiss_nicht` (43 Antworten echt, 5 im Testlauf;
  284 bzw. 20 Antworten sonst).
- „Übersprungen" ist seltener als Übungsbedarf, aber nicht so selten wie in der Anforderung vermutet:
  9 Bereiche in 5 von 12 echten Analysen.
- Bereiche mit Übungsbedarf **und** einzelner „Weiß ich nicht"-Antwort, die die Präsentation ohne Zeichen
  zeigt: 10 echt (7 `traegt_nicht`, 3 `traegt_teilweise`). Das ist die Zahl für Abnahme 8.

## Abweichungen und offene Punkte

1. **Regel „Was die Grafik zeigt" (R7-3):** beim Bau nicht auf dev. Die Überblicksregel steht deshalb in
   `src/lib/report/praesentation/ueberblick.ts`. Kommt R7-3 mit einer eigenen reinen Funktion, eine von beiden
   entfernen (Anforderung, „Doppelte Regel").
2. **Klassenangabe mit Lücke:** 09cf8baa hat Übungsbedarf in 5/6 und 9/10, nicht in 7/8. `klassenAngabe`
   (R7-1) macht daraus „Klasse 5–10" und schließt 7/8 mit ein. Für Tablet und Papier gleich; ob die Spanne
   bei Lücken bleiben soll, entscheidet die Abnahme. Kein Eingriff in R7.
3. **Farben des Punktmusters:** Anhang B nennt für den Punkt `#D9988B` (kombiniert) bzw. `#B3A49B` (getrennt).
   Der Dummy hat für die Schraffur `#E8BFB5` bzw. `#E3D9D2`. Grund, Rand und Text stimmen mit dem Dummy überein.
   Übernommen wie Anhang B (Punkte brauchen mehr Kontrast als Streifen); T3 prüft es am Bild.
4. **Typen zusätzlich:** `TpSeite`, `TpKurvenPunkt` und `TpAnzeigeZahlen` in `src/types/praesentation.ts`,
   damit T3/T4 `src/types/**` nicht anfassen müssen. `src/types/index.ts` exportiert die Datei per
   `export type *` (sonst über 400 Zeilen).
5. **Hilfen zusätzlich:** `zustandAufTablet`, `uebersprungeneSchluessel`, `anteileZeile` und die Konstante
   `UEBERSPRUNGEN` in `praesentation.ts`; `KURVE_PFAD`, `KURVE_PFEIL`, `KURVE_START`, `VIEWBOX`, `punktBei`
   in `kurve.ts`.
6. **Dummy im Browser:** in dieser Session nicht angesehen — der Playwright-Screenshot im Worktree lieferte
   kein Bild (Chromium fehlt vermutlich, `npx playwright install chromium` nicht ausgeführt). Gelesen und
   nachgerechnet sind Skript und CSS: die Kurvenpunkte stimmen exakt (Abweichung 0,0 Prozentpunkte), die
   Farben in Punkt 3. Die Ansicht selbst prüft T2 mit den Ansichtstests.
7. **Zweite Probe mit „Weiß ich nicht" nach Fehlversuch:** zählt als Übungsbedarf ohne Zeichen
   (Anforderung, „Antwort-Ebene"); die Zahlen dazu stehen oben unter (b).
