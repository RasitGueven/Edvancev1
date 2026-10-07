# Retro 06.10.2026 – Session-Rahmen C1: Coach-Live-Sicht mit Beispieldaten

## Gebaut
- Ansichtsmodell `src/types/coachLive.ts` und die einzige Datenquelle `src/lib/session/coachLive.ts`
  (Beispieldaten der fünf Dummy-Kinder, Aktionen mit R1/A1-Namen, Gerüst `ausServer` für C2).
- `useRaumLive` mit Abfrage alle 4 s (kein Realtime).
- Route `/coach/session/:id/live` als Fokus-Seite außerhalb jeder Layout-Route (Coach, Admin).
- Sechs Zeitpunkte nach dem Dummy, Schublade mit Mastery-Prüfung, Pfad-Entscheidung und Interventionsleiter.
- Tests 1–7 plus Durchklick der Beispielleiste; Bildschirmfotos unter `docs/screenshots/session-c1/`.

## Entscheidungen
- Regeln (Warteschlange, Zeitleiste, Stundenziel, Absendbarkeit, Abschluss) als reine Funktionen in
  `coachLiveLogik.ts`; die Datenquelle setzt dieselben Regeln durch wie später der Server.
- Fehlende Tokens nicht erfunden, sondern über Deckkraft vorhandener Tokens gelöst (offene-punkte-c1 Nr. 1).

## Offen
- Siehe `docs/session/offene-punkte-c1.md` (Bausteinkatalog, Briefing-Funktion, Tokens, Fehler-Codes, Einstieg).
