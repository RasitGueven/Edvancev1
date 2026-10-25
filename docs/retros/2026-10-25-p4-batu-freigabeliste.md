# Retro P4 · Batus Freigabeliste im Prüflauf und auf /admin (25.10.2026)

Auftrag Rasit: Die Aufgaben der Freigabeliste (`docs/lsa/freigabeliste-batu-1025.md`, 48 Freigaben in 24
Bereichen) sollen in Lenas Prüfansicht wieder mit Enter nacheinander abgefragt werden, nur die nötigen; im
Admin-Dashboard soll nachvollziehbar sein, was noch offen ist.

## Gebaut

- **Migration `20261025210952_p4_batu_freigabeliste`** (nur Daten): `pruef_soll` anlass `batu_lsa`, Soll 2, davon
  1 ohne MC, für alle 24 Bereiche. Die 13 in P3 ruhenden Zeilen werden wieder aktiv, 11 kommen neu dazu
  (Zinsen, Winkel im Dreieck, Ausblick, `term_ausklammern`, `gleichung_quadr_formel`). sort: KA2 310–340
  (`term_binom_quadrat` 460 → 305), Rückblick 410–570, Ausblick 910–950. Pilot-Flag für die Entwürfe ohne Flag
  (Winkel im Dreieck, Zinsen, Ausblick: in Prod 48 Aufgaben).
  Lenas Lauf (`src/lib/pruefung/lauf.ts`) war schon bedarfsgesteuert; er braucht nur die Sollzeilen.
- **Admin `/admin` → Karte „Batus Freigabeliste“** (`src/pages/admin/heute/FreigabelisteListe.tsx`,
  `freigabelisteModel.ts`):
  - Zahl: fehlende Freigaben, je Bereich max(Soll − freigegeben, Rest), heute 48.
  - Je Block: Anzahl Bereiche, was Lena noch prüfen muss, und welche Bereiche nur noch eine Aufgabe ohne MC
    brauchen.
  - Was Lena mit „passt“ geprüft hat, startet als Freigabe-Reihe in der Admin-Prüfansicht (Enter je Aufgabe).
- Tests: `p4_batu_freigabeliste` (6), `p3_vorschau_pruefen` an den neuen Stand angepasst,
  `freigabelisteModel.test.ts` (4).

## Entscheidungen

- **Anlass `batu_lsa` wiederverwendet**, kein neuer: Der LSA-Reiter kennt ihn schon (`bereich.ts`), keine Änderung
  an Lenas Oberfläche.
- **Blöcke über sort-Bereiche** statt eigener Spalte; in der Migration und im Model dokumentiert.

## Offen

- **Migration einspielen** (Prod-Schreibzugriff, Rasit).
- `term_ausklammern` hat keinen Entwurf ohne MC: Lena kann den Bereich nicht schließen, bis eine neue Aufgabe
  ohne MC da ist. Die Karte zeigt „ohne MC fehlt“, sobald die MC-Aufgaben geprüft sind.
- **Lokale pgTAP-Läufe:** 27 Prüfungen sind auf `dev` lokal rot, mit und ohne P4 dieselben; maßgeblich ist die CI.
