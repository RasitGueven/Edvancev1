# Bericht Bauauftrag SP-1b · Nachzug Session-Aufgaben prüfen

Stand 12.11.2026. Protokoll `fortschritt.md`, Befunde `offen.md`.

## PRs in Merge-Reihenfolge

| # | PR | Inhalt | Stand |
|---|---|---|---|
| 1 | #399 | N1 Klartext-Nachzug (Datenmigration) | gemergt, eingespielt |
| 2 | #400 | N2 Namen typischer Fehler, N3 große Graph-Optionen | gemergt |
| 3 | – | N4 Abnahme, Rückfall je Stufe, Bericht (diese PR) | – |

## Migration

`20261112115143_sp1b_klartext_nachzug` (Skript `~/einspielen/SP1b-1-klartext-nachzug.sh`, Rollback unter
`supabase/rollback/`): Stufen-Klartext für EIN-1, KO-1, EX-2, NP-4, NS-5 (10 Stufen), Titel SCH-3. Zweitprüfung durch
frischen Subagenten (`klartext-pruefung.md`): 11 von 12 Stufen und Titel bestätigt, NS-4 S2/S3 strittig → nicht
eingespielt.

Prüfabfrage nach dem Einspielen (dbread): `klartext 110, stufen 112, v1 47, status zur_pruefung, SCH-3 „Hoch- oder
Tiefpunkt und seine Lage bestimmen“, Prüfungen 0, Kommentare 0`. Am Ende des Auftrags erneut: 47 Bauformen, alle
Version 1 und `zur_pruefung` (wie vorher), keine Prüfung, kein Kommentar.

## Abnahme

| Punkt | Beleg | Ergebnis |
|---|---|---|
| Stufen in Klartext bei allen 47 | `e2e-sessionpruefung/alle-47.spec.ts` (jede Bauform geöffnet, Stufen-Karte enthält die Klartexte, kein „∈“, keine geschweifte Klammer, kein Schlüssel) | 46 von 47; NS-4 zeigt die Generator-Regel (B1) |
| typische Fehler mit kurzem, zutreffendem Namen | Vitest `fehlbildName.test.ts` (50 Namen ≤ 60 Zeichen, kein Satz; Überschreibung nur NF-5) | ✓ |
| Graph-Optionen lesbar | `graph-optionen.spec.ts`: PAR-2, PAR-3, NS-4 je Option ≥ 280 px (1440 × 900) bzw. ≥ 230 px (1180 × 820), richtige markiert, Dialog mit Esc/Knopf und Fokus zurück; EIN-1, KO-1 unverändert; Fotos `abnahme/n3-*` | ✓ (zweispaltig statt dreispaltig, weil die Mindestbreite Vorrang hat) |
| keine Version, kein Neuöffnen | dbread vor und nach | ✓ |
| Fotos EIN-1, KO-1 Stufen vorher/nachher | `abnahme/n4-EIN-1-stufen-vorher-nachher.png`, `n4-KO-1-…` | ✓ |

Alle Ansichtstests 91/91 (dazu 47 übersprungen: der Textabgleich läuft nur bei 1440 × 900), typecheck, lint,
3374 Tests grün.

## Offene Punkte

1. **B1 · NS-4 Stufe 2/3:** vorgegebener Text unvollständig (nur Abstände 2, 4, 6); Vorschlag in `offen.md`.
2. **B2 · NF-2 „Warum?“ mit `({h})`, kindsichtbar:** braucht eine neue Version von NF-2 (Lena prüft neu) oder eine
   Änderung an `aufgabe_payload`; beides war hier verboten. Dringlichster Punkt.
3. **B3 · Korrektur zu SP-1:** ohne Klartext blieb die Stufenzeile leer; jetzt Rückfall auf die Steckbrief-Regel.
4. Aus SP-1 weiter offen: O1 (Planung liest keine Aufgabenzeit).
