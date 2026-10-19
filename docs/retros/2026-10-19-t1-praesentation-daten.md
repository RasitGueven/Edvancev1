# Retro 19.10.2026 – T1 · Daten für die Tablet-Präsentation der LSA

## Gebaut
- Anforderung und Dummy V7 unter `docs/report/praesentation/` (`Anforderung.md`, `dummy-v7.html`).
- Typen in `src/types/praesentation.ts` (`PraesentationDaten`, `Tp*`), Export über `src/types/index.ts`.
- Rechnung unter `src/lib/report/praesentation/`:
  - `einstellungen.ts`: `UEBERSPRUNGEN_ANZEIGE = 'kombiniert'`.
  - `praesentation.ts`: `bauePraesentation` ruft `baueElternbericht` genau einmal und teilt Zahlen,
    Zeilen, Ebenen nach `nicht_angesetzt` auf; Stufen je Schwerpunkt; `anzeigeZahlen` für beide
    Zählweisen; `{ fehlt: 'kompetenzen' | 'katalog' }`.
  - `ueberblick.ts` (zwei Karten in 01), `empfehlung.ts` (Paketname aus `tiers`, nie ein Preis),
    `kurve.ts` (Logo-Kurve aus dem Dummy-Skript, Punkte für 0–4 Schwerpunkte).
  - `fixtures.ts`: `PRAESENTATION_FAELLE` = `FAELLE` plus `uebersprungen`, `einSchwerpunkt`,
    `zweiSchwerpunkte`, `dreiSchwerpunkte`, `laeuftNoch`.
- Namespace `praesentation` (Anhang A wörtlich, 84 Texte), Tokens `--color-tp-*` (Anhang B, 14 Werte),
  Invariante INV-4.11 in `src/test/invariants/inv4-praesentation.test.ts`.

## Entscheidungen
- Übersprungen wird nur über den Schlüssel aus `kompetenzen` erkannt und von R7-Zahlen abgezogen; keine
  eigene Zählung gegen den Katalog. Der Gleichheitstest läuft über alle Fälle gegen `baueElternbericht`.
- `fehlt` unterscheidet nach der Eingabe, weil `baueElternbericht` in beiden Fällen nur `null` liefert.
- Überblicksregel neu geschrieben: R7-3 war noch nicht auf dev.
- `export type * from './praesentation'` in `src/types/index.ts`, sonst über 400 Zeilen.

## Ergebnis
- Alle Kontrollwerte aus Anhang C stimmen (ilkay, uebersprungen, alleFelder, klasse10neu), keine
  Abweichung. Prod-Analysen 6d868c5f, c84ba103, 09cf8baa gleich den R7-1-Zahlen.
- Prod: 9 `nicht_angesetzt` in 5 von 12 echten Analysen; 10 Bereiche mit Übungsbedarf und einzelner
  „Weiß ich nicht"-Antwort (Grundlage Abnahme 8). `leer` kommt in Prod nicht vor.

## Offen
- `docs/report/praesentation/offene-punkte-t1.md`: doppelte Überblicksregel nach R7-3, Klassenangabe
  bei Lücke („5–10"), Punktfarben Anhang B vs. Dummy, Dummy nicht im Browser angesehen.
