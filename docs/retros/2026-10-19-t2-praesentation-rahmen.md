# Retro 19.10.2026 – T2 · Rahmen der Tablet-Präsentation

## Gebaut
- `src/components/edvance/praesentation/`:
  - `Praesentation.tsx`: Ebene per `createPortal` unter `<body>` (`.tp`, `role="dialog"`), `tp-offen` an
    `<html>`, Escape schließt, `LoadingPulse` beim Laden, `EmptyState` ohne Rechnung, Rechnung einmal per
    `useMemo` (`bauePraesentation`, `Bausteinsatz`). Ohne Pakete rechnet sie mit `[]`: nur die Empfehlung fehlt.
  - `useStationen.ts`: aktuelle Station, `entered`/`motion-complete`, Sprung, Intro verabschieden ohne Sprung
    (Logik wie `selectStage`/`measureStage`/`jumpTo`/`retireIntro` im Dummy).
  - `Kopf.tsx`, `Leiste.tsx` (Eddie), `Intro.tsx`, `Logo.tsx`, `Kicker.tsx`, `stationProps.ts`.
  - `Station1.tsx`–`Station4.tsx` als Hüllen (Kicker und Titel; 01 mit Kopfsatz wie `Seite1.tsx`).
  - `vorschau/main.tsx` + `vorschau/praesentation.html` (ohne Router, Anmeldung, Supabase-Client).
- `src/styles/praesentation/`: `rahmen.css` (Ebene, Einrasten, Kopf, Leiste, Szene, Bewegungsvariablen,
  Keyframes), `intro.css`, leere `station1–4.css`, ein Import in `globals.css`.
- `ReportPage.tsx`: Knopf „Präsentation“ als erster in den Aktionen, `?ansicht=praesentation`, Pakete einmal
  je Seite für R7 und Präsentation, Schließen entfernt nur `ansicht`.
- Ansichtstests `playwright.praesentation.config.ts`, `e2e-praesentation/` (alle Fälle × 9 Maße, Bewegung und
  Bedienung bei 820×1180 und 1180×820), Fotos unter `docs/report/praesentation/abnahme/t2/`.
- INV-4.12 in `inv4-praesentation.test.ts`, CLAUDE.md §11 „Tablet-Präsentation (LSA)“ und ein Satz bei den
  Design-Invarianten.

## Entscheidungen
- Die `<section>` je Station legt der Rahmen an; Stationen bekommen nur die festen Props. So tragen die
  Zustände der Bewegung Klassen an der Section, ohne dass T3/T4 den Rahmen ändern.
- Ansichtstests über Datenattribute (`data-tp-pflicht`, `-liste`, `-zeile`, `-bereiche`, `-beschriftung`,
  `-kurve`) statt über Klassen der Stationen. Ohne die Attribute laufen die Prüfungen leer.
- Abschneiden zählt nur innerhalb der Station; der eigene `overflow: hidden` der Station würde sonst jeden
  Überlauf verstecken. Gegengeprüft mit absichtlich zu hohem und zu breitem Inhalt.
- WebKit nur per `TP_WEBKIT=1` (in WSL fehlen Systembibliotheken).

## Gelernt
- `.tp button { font: inherit }` sticht Klassen wie `.tp-marke` aus → Reset mit `:where(.tp)`.
- Playwright führt Tests einer Datei nur mit `fullyParallel` auf mehrere Worker.
- Dateien im Worktree während eines Laufs ändern → Vite lädt neu, Tests brechen mit „Execution context was
  destroyed“. Während der Ansichtstests nichts editieren.
- jsdom: eine per `hidden` ausgeblendete Region hat für `getByRole` keinen Namen mehr.

## Offen
- `docs/report/praesentation/offene-punkte-t2.md` (Verträge für T3/T4, WebKit, Port 5185 belegt, libasound).
