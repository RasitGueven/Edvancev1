# Bericht Bauauftrag SP-1c · NF-2, NS-4, Prüfmaschine

Stand 12.11.2026. Protokoll `fortschritt.md`, Platzhalter-Liste `platzhalter.md`, Zweitprüfung NS-4 `ns4-pruefung.md`.
Schließt SP-1b B1 und B2 (`../sp1b/offen.md`).

## Was gebaut wurde

| Teil | Inhalt | Beleg |
|---|---|---|
| C1 | Prüfmaschine (Prüfung 5) sucht Platzhalter `{name}` in jedem Kindtext: Aufgabe, Hinweise, Lösungsweg, Fehlbild-Rückmeldungen, `warum.frage`, `warum.bausteine`. Ein Treffer im Steckbrief macht alle Instanzen rot (Bauform verdächtig). Mengenklammern zählen nicht. Neuer Prüfmodus `tools/bauform.sh --alle --platzhalter` (schreibt nichts). | pytest 19/19 (3 neue Negativkontrollen); Lauf vorher: 1 Treffer (NF-2), nachher 0 |
| C2 | NF-2 Version 2: „Warum zieht man das Quadrat der halben Zahl wieder ab?“, Baustein a ohne Zahl. Instanzen inhaltlich gleich, v1 fällt über die Versionsbedingung aus der Ziehung. | Prüfmaschine 84/84, Blindlöser 10/10, Zweitprüfung ohne Befund |
| C3 | NS-4 Stufe 2 und 3 in Klartext („Abstand 2, 4 oder 6“), Stufe 3 ausgeschrieben. | Zweitprüfung bestätigt |
| C4 | `alle-47.spec.ts` ohne Ausnahmen: Klartext in allen 47 Stufen-Karten, kein Platzhalter in Beispiel-Karten und im `warum`. | Ansichtstests 91/91 |

## Migrationen (eingespielt)

| Version | Inhalt | Prüfabfrage nach dem Einspielen (dbread) |
|---|---|---|
| `20261112130215_reihe1_bauform_nf_2` | NF-2 v2 (Steckbrief + 84 Instanzen) | NF-2 v2, `zur_pruefung`, 84 grün, `warum.frage` ohne „{“, 46 × v1 |
| `20261112130334_sp1c_ns4_klartext` | NS-4 S2/S3 Klartext und Beispiel | 112 von 112 Stufen mit Klartext |

Endstand: 47 Bauformen `zur_pruefung`, 46 × Version 1, NF-2 Version 2, keine Prüfung, kein Kommentar.

## Gates

typecheck, lint, Vitest 3374/3374, pytest 19/19, Ansichtstests 91/91 (47 übersprungen: Textabgleich nur bei 1440 × 900).

## Offene Punkte

1. **Lena prüft NF-2 neu** (Version 2); bisher gab es keine Prüfung, also geht nichts verloren.
2. In der Vorschau-Ziehung von NF-2 ist keine Beispiel-Instanz dabei; das „Warum?“ prüft der Ansichtstest deshalb
   über die Daten (`steckbrief.warum`), die Karte selbst nur bei Bauformen mit Beispiel-Instanz in der Ziehung.
3. Aus SP-1 weiter offen: O1 (Planung liest keine Aufgabenzeit).
