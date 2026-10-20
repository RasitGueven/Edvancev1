# R7-10 · Offene Punkte und Textänderungen

Stand 20.10.2026, Branch `feat/rasit-report-r7-deutung`. „Was die Grafik zeigt“ nennt ein Feld nur
noch ab zwei direkt geprüften Bereichen (`MIN_GEPRUEFT_DEUTUNG = 2`), der Coach-Satz steht nie allein,
und die Umriss-Kästchen haben einen kräftigeren Rand (`--color-eb-weg-ring`, 0,8).

## Abnahme-Material

- Druck-Tests aller Fälle: `EB_PORT=5192 EB_AUSGABE=docs/report/r7/abnahme/r7-10 npx playwright test -c
  playwright.elternbericht.config.ts`: 24 von 24 grün, PDFs unter `docs/report/r7/abnahme/r7-10/<fall>.pdf`.
- Bildschirmfotos Seite 2 (Druckmedium, Faktor 2) unter `fotos/`: `seite2-abgestuft.png`, `seite2-ilkay.png`.

## Textänderungen „Was die Grafik zeigt“ (alt → neu)

Coach-Satz C = „Ob dahinter ein gemeinsames Muster liegt, prüft der Coach in den ersten Sitzungen.“

| Fall | alt | neu |
|---|---|---|
| abgestuft | Überwiegend sicher waren die Themenfelder Terme & Gleichungen und Brüche & Dezimalzahlen. Den meisten Übungsbedarf zeigten die Themenfelder Geometrie und Zahlen & Rechnen. C | Überwiegend sicher war das Themenfeld Terme & Gleichungen. Den meisten Übungsbedarf zeigten die Themenfelder Geometrie und Zahlen & Rechnen. C |
| klasse7, spaeter | Überwiegend sicher war das Themenfeld Größen. Den meisten Übungsbedarf zeigten die Themenfelder Brüche & Dezimalzahlen und Prozent & Dreisatz. C | Den meisten Übungsbedarf zeigten die Themenfelder Brüche & Dezimalzahlen und Prozent & Dreisatz. C |
| sechsFelderMitUebung, alleFelder, fazitLang | Den meisten Übungsbedarf zeigten die Themenfelder Brüche & Dezimalzahlen und Prozent & Dreisatz. C | Den meisten Übungsbedarf zeigte das Themenfeld Brüche & Dezimalzahlen. C |

Alle anderen Fälle wörtlich unverändert, darunter `ilkay` (jedes Feld ≥ 3 geprüft, im Test
festgehalten). `ohneKatalog` hat keinen Bogen. In keinem Fixture-Fall entfällt der Absatz; das deckt
ein synthetischer Fall im Test ab (drei Felder mit je einem Bereich Übungsbedarf).

## Offen

- **Umriss-Einrückung 0,7 statt 0,8.** `Profil.tsx` rückt die Umriss-Kästchen um die halbe Randstärke
  ein (`UMRISS = 0.7`). Der Rand ist jetzt 0,8 breit und steht damit je Seite 0,05 pt über die
  Kästchenbreite hinaus. Sichtbar nicht, die kleinste Lücke ist 1 pt. Profil.tsx stand nicht im
  Umfang; wer es glatt haben will: `UMRISS = 0.8` und in `Seite2.test.tsx` `breite - 0.8`.
- **Felder mit nur einem Urteil fallen still heraus.** Bei
  `klasse7`/`spaeter` verschwindet „Größen“ (1 sicher) aus dem Sicher-Satz; damit steht dort kein
  positiver Satz mehr. Gewollt nach Entscheidung 1, aber für die Eltern ein Ton-Unterschied.
- `abgestuftMitOffen` und `abgestuftLang` unverändert („Zahlen & Rechnen“ hat dort ≥ 2 geprüft).
- Ob 0,8 pt `--color-eb-weg-ring` auf Papier reicht, zeigt erst ein echter Ausdruck.
