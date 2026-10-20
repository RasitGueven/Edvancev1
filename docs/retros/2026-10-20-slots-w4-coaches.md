# Retro 20.10.2026 · Slots W4 · Coaches: Schichten als Block

**Branch:** `feat/rasit-slots-w4-coaches` · **Auftrag:** `docs/slots/Bauauftrag-Slots-Wochenplan-v2.md` (W4) ·
**Dummy:** `docs/slots/slots-dummy-v2.html` · **Grundlage:** W1 (`docs/api/DATENVERTRAG.md` 10.6), W2, W3. Keine Migration.

## Gebaut
- **Blockbildung** (`coaches/coaches.model.ts`, rein): benachbarte Uhrzeiten in der Liste der aktiven `zeiten`, gleicher
  Coach, Wochentag, Raum und gleiches Ende bilden einen Block; Lücke oder anderer Raum trennt. Je Wochentag gilt die
  Schicht am Tag der gewählten Woche, künftige Schichten bilden Blöcke mit „ab“. Dazu Zielraum-Prüfung und die
  Konfliktsätze aus den Hinweisen `raum:HH:MM` / `coach:HH:MM`.
- **Reiter Coaches** (`CoachesReiter.tsx`, `CoachKarte.tsx`): je Coach eine Karte (Name, Std. pro Woche, Blöcke mit
  Raum, Kindern mit Stammplatz, „Raum ändern“, „Entfernen“), Abweichungen der Woche als Verweis ins Slot-Panel; daneben
  „Schicht eintragen“ (`SchichtEintragen.tsx`, `stammschicht_block_anlegen` mit von/bis).
- **Dialoge:** „Raum der Schicht ändern“ (`RaumWechselDialog.tsx`: neuer Raum, gültig ab = nächster Montag, Satz
  „Kinder hängen am Raum …“, Kästchen Standard aus, gesperrt mit Grund bei besetztem Zielraum) und „Schicht
  entfernen“ (`EntfernenDialog.tsx`: Satz „… kein Coach“, Datum, `stammschicht_beenden` je Stunde).
- Tests: `coaches.model.test.ts` (Blockbildung, Zielraum, Konfliktsätze), `coaches.test.tsx` (Anlegen mit von/bis,
  Konfliktsatz, Raum ändern mit/ohne Kinder, gesperrter Zielraum, Entfernen über Dialog, Teilfehler).

## Entscheidungen
- Kinderzahl als Summe je Stunde, benannt „Kinder mit Stammplatz“ (ein Kind hat je Wochentag einen Stammplatz, SL008; Randfall A-/B-Woche offen).
- Abweichungen öffnen das Slot-Panel im Reiter Coaches statt über die alte Termin-Adresse.
- Abweichungen vom Dummy mit Grund in `docs/slots/offene-punkte-w4.md`.

## Offen
- `docs/slots/offene-punkte-w4.md` (u. a. Kinder distinct je Block, atomares Entfernen).

## Zweitprüfung (nachgezogen)
- Wortlaut zurück auf „Kinder“ (Auftrag), A-/B-Randfall als offener Punkt.
- Blöcke, die vor dem Standarddatum enden, ohne Aktionen („läuft aus“); Datum nach dem Ende in den Dialogen gesperrt.
- Standarddatum = max(nächster Montag, spätestes `gueltig_ab` des Blocks); „ab“ = erster Termin am Wochentag;
  Konfliktsatz nimmt die am Prüfdatum gültige Schicht; Ende einer inaktiven Uhrzeit = Beginn + 1 h; Abweichungszeile
  über i18n.
- Server-Befund (annullierte Schichten zählen als belegt) in offene-punkte-w4 Nr. 7 für die Foundation notiert.
