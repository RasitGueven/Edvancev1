# Retro 20.10.2026 · Slots W2 · Wochenplan, Slot-Panel, Tagespanel

**Branch:** `feat/rasit-slots-w2-wochenplan` · **Auftrag:** `docs/slots/Bauauftrag-Slots-Wochenplan-v2.md` (W2) ·
**Dummy:** `docs/slots/slots-dummy-v2.html` · **Grundlage:** W1 (`docs/api/DATENVERTRAG.md` 10.6). Keine Migration.

## Gebaut
- **Reiter** Wochenplan · Kinder · Coaches · Einstellungen; der Reiter Stundenplan ist weg. `?reiter=stundenplan` und
  `/admin/schedule` landen im Wochenplan (Woche bleibt), `/admin/slots/termin/:datum/:zeitId` öffnet das Slot-Panel.
- **Kopf:** fünf Kennzahlen mit sichtbaren Testkonten (`wochenKennzahlen`), A-/B-Woche neben der Woche.
- **Raster:** je Zelle eine Zeile pro Raum (Punkte, „n/5“ bzw. „kein Coach“), Farbe nach `raumFarbe` (0 grau, 1–2 rot,
  3 gelb, 4–5 grün, Kinder ohne Coach rot gefüllt), „x frei“ / „läuft gerade“, vergangene Zellen gedämpft, Tage ohne
  Betrieb als eine Fläche, Zeile „Einzel“ aus `stundenplan_woche`. Seitlich scrollbar auf schmalen Breiten.
- **Panels** unter `src/pages/admin/slots/panel/`: `SlotPanel` (alle Aktionen der Termin-Seite, neu „+ Kind in …“,
  Session öffnen / Live-Sicht / Rückblick über `betriebAktion`, „Live“ je Kind bei laufender Session),
  `TagPanel` (je Stunde Räume mit Coach und freie Plätze, Einzel-Sessions an ihrer Uhrzeit, „+ Einzel-Session an
  diesem Tag planen“), `EinzelPanel` (Session-Karte mit Kinder zuweisen und Testlauf), `KindInRaumDialog`
  (`slots_kandidaten_alle`, einmalig → `zusatztermin_buchen(…, raum)`, jede Woche → `stammplatz_vergeben` mit Raum).
- Termin-Karten und Stundenplan-Bausteine nach `panel/` verschoben (Geschichte per `git mv`); `TerminPage` und
  `StundenplanReiter` entfernt.
- Tests: Farbe je Belegung, Kennzahlen, Panel-URL, Umleitungen, Panel über URL öffnen und mit Zurück schließen,
  „+ Kind“ je Modus mit Raum, gesperrte Kinder mit Satz, voller Raum, Live-Link nur bei laufender Session. Die alten
  Tests der Termin-Seite und des Stundenplans laufen gegen die Panels weiter. `slotsTexte.test.ts` prüft jetzt auch
  Schlüssel mit Ziffer im ersten Teil (`wochenplan2.*`).

## Entscheidungen
- Panels hängen an der URL. Das erste Panel ist ein eigener Schritt in der Geschichte (Zurück schließt), Wechsel
  zwischen Panels ersetzen ihn; direkt geöffnete Panels schließen per `replace` und behalten die Woche.
- `betriebAktion` wird mit einer aus dem Raum gebauten `BetriebZeile` aufgerufen statt nachgebaut; davor/danach
  (nicht am Termintag) entscheidet das Panel nur „Öffnen am Termintag“ bzw. „Rückblick“.
- `termin/TerminKarten.tsx` bleibt als Re-Export, damit W3 (`kind/KindKarten.tsx`) nicht an derselben Zeile kollidiert.

## Offen
`docs/slots/offene-punkte-w2.md`.
