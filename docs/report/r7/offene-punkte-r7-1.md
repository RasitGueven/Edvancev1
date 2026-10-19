# R7-1 · Offene Punkte und Zahlen

Stand 19.10.2026, Branch `feat/rasit-report-r7-daten`. Zahlen aus Prod (dbread, nur lesend), gerechnet
mit `baueElternbericht` und dem Katalog vom 19.10. (130 Skills, Klasse 5–10).

## Zahlen für die Abnahme (Entscheidung 4 und 7)

| Analyse | Klasse | untersucht | sicher | Übungsbedarf | Katalog | nicht untersucht |
|---|---|---|---|---|---|---|
| 6d868c5f (Ilkay, 20.09.) | 10 | 27 | 11 | 16 | 130 (bis Kl. 10) | 103 |
| c84ba103 (25.09.) | 8 | 22 | 12 | 10 | 73 (bis Kl. 8) | 51 |
| 09cf8baa (12.10., Reelle Zahlen) | 9 | 6 | 1 | 5 | 115 (bis Kl. 9) | 109 |

Zum Vergleich der R6-Nenner (Summe der sechs Familien, unabhängig von der Klasse immer 89):

| Analyse | untersucht | sicher | Übungsbedarf | Katalog | nicht untersucht |
|---|---|---|---|---|---|
| 6d868c5f | 25 | 9 | 16 | 89 | 64 |
| c84ba103 | 21 | 11 | 10 | 89 | 68 |
| 09cf8baa | 0 | 0 | 0 | 89 | 89 |

- Ilkay: Das Muster E7 nennt „25 von 41“. Die 25 sind die R6-Familienzählung, in der `potenzen` und
  `runden_ueberschlag` fehlen (beide sicher, daher 9 statt 11 sicher). Die 41 sind ein älterer
  Familienbestand; heute sind es 89.
- 09cf8baa: Alle sechs geprüften Bereiche liegen in Wurzeln/Potenzen. Der R6-Nenner sieht davon keinen.

**Profilzeilen** (untersucht / vorhanden, sicher, Übungsbedarf):

| Feld | 6d868c5f | c84ba103 | 09cf8baa |
|---|---|---|---|
| Brüche & Dezimalzahlen | 5/8 (2, 3) | 4/8 (3, 1) | 0/8 |
| Prozent & Dreisatz | 4/9 (1, 3) | 2/9 (2, 0) | 0/9 |
| Terme & Gleichungen | 4/23 (2, 2) | 4/19 (1, 3) | 0/23 |
| Geometrie | 6/40 (1, 5) | 6/16 (3, 3) | 0/35 |
| Größen | 5/6 (3, 2) | 4/6 (2, 2) | 0/6 |
| Zahlen & Rechnen | 3/14 (2, 1) | 2/5 (1, 1) | 6/14 (1, 5) |
| Funktionen | 0/20 | 0/5 | 0/10 |
| Daten & Zufall | 0/10 | 0/5 | 0/10 |

**Pyramide** (Ebene, Stufe, Zahl der Bereiche):

- 6d868c5f: Weiterführende Themen · Klasse 7/8 · 12 (4 sicher, 8 Übungsbedarf); Grundlagen · Klasse
  5/6 · 15 (7, 8). Zwei Ebenen, wie im Bauauftrag vorhergesagt.
- c84ba103: Aktueller Unterrichtsstoff · Klasse 7/8 · 9 (4, 5); Grundlagen · Klasse 5/6 · 13 (8, 5).
- 09cf8baa: Aktueller Unterrichtsstoff · Klasse 9/10 · 5 (1, 4); Grundlagen · Klasse 5/6 · 1 (0, 1).

Eine abgeschlossene Analyse aus Klasse 9/10 mit drei Ebenen gibt es in Prod noch nicht (Abnahme
Punkt 6); der Fall `klasse10neu` zeigt sie synthetisch.

**Schwerpunkte** (* = gemischt):

- 6d868c5f: Geometrie*, Brüche & Dezimalzahlen*, Größen*, Prozent & Dreisatz*; danach Terme &
  Gleichungen, Zahlen & Rechnen. Genau die Vorhersage im Bauauftrag (Entscheidung 7).
- c84ba103: Geometrie*, Größen*, Brüche & Dezimalzahlen*, Terme & Gleichungen*; danach Zahlen & Rechnen.
- 09cf8baa: Zahlen & Rechnen*.

## Abweichungen

- **Schulform Ilkay:** Prod sagt „Gesamtschule“, das Muster „Gymnasium“. Die Fixture nimmt den
  echten Wert.
- **Vorzeichen:** `vorzeichen_*` gehört nach Entscheidung 5 zu „Zahlen & Rechnen“ (Inhaltsbereich
  `negative_zahlen`). Das Muster stellte „Vorrangregeln mit Vorzeichen“ unter „Terme & Gleichungen“.
- **`klassenAngabe` zusätzlich:** Kleine reine Funktion in `einordnung.ts` (Stufen → „Klasse 7/8“
  bzw. Spanne „7–10“), damit R7-4 `src/lib/**` nicht anfassen muss.
- **`--font-eb-marke`** steht wörtlich als `'Fraunces'` ohne Rückfall, wie im Auftrag. Fehlt die
  Schrift, nimmt der Browser seine Standardschrift. R7-2 prüft das beim Druck.
- **Ansprechpartner in der Fixture:** Name aus Prod (Platzvergabe), Mail wie im Muster
  (`rasit@edvanceacademy.de`, Mitarbeiter, keine Familiendaten). Keine Mail und kein Schulname der
  Familie in den Fixtures.

## Offene Punkte

1. **Nenner entscheiden** (Abnahme 4): „von 130 Bereichen des Katalogs bis Klasse 10“ bei Ilkay. Der
   Katalog zählt auch Skills, zu denen es noch keine LSA-Aufgabe gibt. Die Regel hängt an `zaehle()`
   in `src/lib/report/elternbericht/zaehlung.ts`.
2. **Reihenfolge der Schwerpunkte bestätigen** (Abnahme 5) am Ergebnis oben.
3. **Migration einspielen** nach dem Merge (Rasit, CLAUDE.md §10): `20261019080220_r7_kopf_entwuerfe`.
   Reine Datenzeilen, kein DDL; Syntax per `explain` read-only gegen Prod geprüft.
4. **Kopfsätze abnehmen** (Lena, `docs/report/r7/kopf-texte.md`). Bis dahin steht auf Seite 1 die
   Ersatzüberschrift.
5. **Doppelte Komposition:** `fixtures/basis.ts` setzt die Erzählung mit denselben reinen Funktionen
   zusammen wie `lsaReportErzaehlung.ts`, weil der Lesepfad den Supabase-Client lädt. Ändert sich die
   Komposition dort, muss die Fixture nachgezogen werden. Besser später: die Komposition als reine
   Funktion nach `src/lib/report/` ziehen und an beiden Stellen nutzen (Änderung am R6-Pfad, deshalb
   nicht in R7-1).
6. **Katalog in der Fixture** ist der Stand vom 19.10. Kommen Skills dazu, ändern sich die erwarteten
   Zahlen in `zaehlung.test.ts` (130, 103) nicht von selbst — sie hängen an der Fixture, nicht an Prod.
7. **Klasse 11+:** Es gibt keine Ebene „aktuell“; 9/10 landet bei „Weiterführende Themen“ mit der
   Spanne „Klasse 7–10“. Kein solcher Fall in Prod.
8. **Klasse unter 5:** `zaehle()` nähme dann `bisKlasse` < 5, der Katalog bestünde nur aus den
   untersuchten Bereichen. In Prod gibt es keine solche Sitzung; ungetestet (Zweitprüfung).

## Zweitprüfung

Frische Instanz, Schwerpunkt Zählung, Nenner, Ebenen: keine Fehler. Umgesetzt: `zaehle()` entdoppelt
selbst nach Schlüssel (vorher nur über `bereicheAus`), Test für einen Skill außerhalb des Katalogs.
Offen gelassen: Klasse unter 5 (Punkt 8).
