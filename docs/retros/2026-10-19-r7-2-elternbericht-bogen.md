# Retro 19.10.2026 – R7-2 · Druckbogen, Umschalter, Vorschau, Druck-Tests und Seite 1

## Gebaut
- `/admin/report/:sessionId?fassung=r7` zeigt den Eltern-Bericht als fünf A4-Seiten; ohne Parameter
  bleibt R6 unverändert. Knopf „Neue Fassung (Druck)“ / „Bisherige Fassung“ in den Aktionen, bei R7
  zusätzlich `listTiers()`. Hinweis „läuft noch“, Testlauf-Banner und Ausblick nur am Bildschirm.
- `ElternberichtBogen` rechnet einmal (`baueElternbericht`, `Bausteinsatz`) und reicht `SeitenProps`
  an `Seite1`–`Seite5`. Ohne direkt geprüfte Bereiche oder ohne Katalog: `EmptyState` statt Bogen.
- `Seite`: Kopf und Fuß als SVG in Seitenkoordinaten (1 Einheit = 1 pt), Inhalt im Fluss in
  `.eb-inhalt` (y 80–800). Schraffur-Pattern für Seite 2 einmal im Bogen.
- Seite 1 komplett: Kicker, Überschrift (Kopfsatz oder Ersatz), Kopfdaten, „Auf einen Blick“ mit drei
  Karten, Anliegen und Prüfweg (gleich hoch), Weg durch den Bericht (entfällt ab zwei Rückbezügen).
- Styles unter `src/styles/elternbericht/` (ein Import in `globals.css`), Druck randlos über
  `@page eb`, Vorfahren des Bogens im Druck als Blöcke (`:has(.eb-bogen)`), AppShell unverändert.
- Vorschau `vorschau/elternbericht.html` mit eigenem Einstieg, ohne Router, Anmeldung und
  Supabase-Client (läuft im Worktree ohne `.env`), nicht im Build.
- Druck-Tests `e2e-druck/` (eigene Konfiguration, Port und Ausgabe per Umgebung) über alle Fälle aus
  `FAELLE`: Schrift geladen, kein Überlauf, Kopf/Fuß ±1 pt, PDF mit fünf Seiten.
- INV-4.11 in `inv4-elternbericht.test.ts` (Glob über Komponenten und Styles), CLAUDE.md §11
  „Druckbogen Eltern-Bericht (R7)“ mit der INV-4.4-Ausnahme.

## Entscheidungen
- Kopf und Fuß als SVG statt absolut gesetzter HTML-Texte: Text steht dort auf seiner Grundlinie,
  Linien und Punkte haben genau die Maßblatt-Koordinaten, und der Druck-Test misst die gezeichneten
  Teile direkt.
- Abstände im Fluss aus den Grundlinien gerechnet (Ascent/Descent in Chromium gemessen) und danach
  nachgemessen; Rundungsreste über `position: relative; top` korrigiert, ohne den Fluss zu verschieben.
- Kartenstreifen als eigener Balken über dem Rand (wie im Muster), nicht als dicker oberer Rand.
- Der Hinweis ohne Bogen sitzt im Bogen selbst, damit die Rechnung nur einmal läuft und die
  Vorschau ihn auch zeigt; der Druck-Test prüft dort den Hinweis statt des PDFs.

## Ergebnis
- Seite 1 von `ilkay`: Grundlinien höchstens 0,4 pt neben dem Muster; im PDF Wortmarke, Chip,
  Kicker und Fuß auf 0,05 pt. Alle 13 Fälle grün, PDFs unter `docs/report/r7/abnahme/r7-2/`.
- Druck der Ansicht in der Admin-Hülle (Harness): fünf Seiten, randlos.

## Offen
- `docs/report/r7/offene-punkte-r7-2.md`: Kopfsätze abnehmen, Druck aus der App von Hand (Abnahme 2),
  Scroll-Verhalten unter 800 px, Druck-Tests nur lokal.
