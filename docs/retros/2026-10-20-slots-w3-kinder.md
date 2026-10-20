# Retro 20.10.2026 · Slots W3 · Kinder und Stammplatz-Dialog

**Branch:** `feat/rasit-slots-w3-kinder` · **Auftrag:** `docs/slots/Bauauftrag-Slots-Wochenplan-v2.md` (W3) ·
**Dummy:** `docs/slots/slots-dummy-v2.html` · **Grundlage:** W1 (`docs/api/DATENVERTRAG.md` 10.6), W2. Keine Migration.

## Gebaut
- **Kinderliste** (`kinder/`): Spalten Kind (mit „Test“) · Paket · Stammplatz („Mo 14:00 · A1 (A-Woche)“, Altbestand
  „Raum: automatisch“) · Coach (aus der Schicht, sonst „keine Schicht“) · Planbilanz · Aktion (Stammplatz vergeben,
  wie bisher weiterführen, Raum festlegen, Ändern). Filter Alle · Ohne Stammplatz · Testkonten zeigen (Standard an),
  ohne Stammplatz oben; Logik in `kinder.model.ts`.
- **Stammplatz-Dialog** (`dialoge/StammplatzDialog.tsx`, Teile `StammplatzRaeume.tsx`, `stammplatz.model.ts`):
  Wochentag, Uhrzeit, Takt, gültig ab; A/B-Hinweis mit der KW des ersten Termins; je aktivem Raum eine Karte aus
  `stammplatz_vorschau` (Coach, „n von 5 frei am …“, gesperrt bei voll und ohne Coach mit Satz); „Die nächsten Termine“
  mit Kennzeichen geplant / entfällt / kein Betrieb / andere Woche und Grund als Satz; Planbilanz-Vorschau darunter.
  Speichern über `stammplatz_vergeben` bzw. `stammplatz_aendern` mit `raum_id`, beim Ändern geht `ersetzt` an beide
  Vorschauen.
- **Kind-Seite:** Raum und Coach je Stammplatz, Altbestand mit „Raum festlegen“ (derselbe Dialog).
- Aufgeräumt: `termin/TerminKarten.tsx` (Re-Export aus W2), `dialoge/FreiRaster.tsx`, `kinder/OhneStammplatzListe.tsx`.
- Tests: `kinder/kinder.test.tsx` (Liste, Filter, Kind-Seite), `dialoge/StammplatzDialog.test.tsx` (Raum-Karten, jeder
  Grund als Satz, A/B-Hinweis KW 45/46, Speichern vergeben/ändern mit `raum_id`, `raum_fehlt` als Satz);
  `dialoge.test.tsx` (Abnahmefall 9) auf den neuen Dialog umgestellt.

## Entscheidungen
- Räume und Uhrzeiten aus `slots_einstellungen` (aktiv am Datum „gültig ab“), Stand je Raum aus einem
  `stammplatz_vorschau`-Aufruf pro Raum; die Vorschau des gewählten Raums ist zugleich „Die nächsten Termine“.
- Abweichungen vom Dummy mit Grund in `docs/slots/offene-punkte-w3.md`.

## Offen
- `docs/slots/offene-punkte-w3.md`.
