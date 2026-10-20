# Retro 20.10.2026 · Slots W1 · Stammplatz am Raum

**Branch:** `feat/rasit-slots-w1-raum` · **Migration:** `20261020150943_slots_w1_raum` · **Auftrag:**
`docs/slots/Bauauftrag-Slots-Wochenplan-v2.md` (W1) · **Dummy:** `docs/slots/slots-dummy-v2.html`

## Gebaut
- `stammplaetze.raum_id`; Planung je Raum (`slots_plan_rechnen`, `termine_planen`), fester Termin im vollen oder
  geschlossenen Raum bleibt ohne Raum (`slot_zuteilung`, Grund `raum_voll` / `raum_zu`).
- Prüfung je Raum (`slots_stammplatz_gruende`), `stammplatz_vergeben` mit Raum je Zeile, `stammplatz_aendern` und
  `zusatztermin_buchen` mit `p_raum_id` (DROP + CREATE, Grants wie vorher).
- Neu: `stammplatz_vorschau`, `slots_kandidaten_alle`, `stammschicht_block_anlegen`, `stammschicht_raum_wechseln`.
- Erweitert für W2–W4: `slots_woche` (Kennzahlen mit Testkonten, Räume ohne Coach, `coach_name`, `laeuft`),
  `slots_termin`/`slots_tag` (Räume mit Kindern ohne Coach), Stammplatz mit Raum und Coach, Kinder je Stammschicht.
- Wrapper in `src/lib/supabase/slotplan.ts`, Typen in `src/types/slotplanRaum.ts`; `src/types/slotplan.ts` unter 400
  Zeilen durch Auslagern der Dialog- und Ergebnistypen nach `slotplanDialoge.ts`. Hinweise `raum_fehlt`, `von_bis`,
  `gleicher_raum` in `fehler.ts` und `de/slots.json`.
- pgTAP `slots_w1` (101 Zusicherungen); die bestehenden Slot-Tests prüfen weiter den Altbestand ohne Raum.

## Entscheidungen
- Raumpflicht über `slots_raum_pflicht()`: die Altbestand-Tests schalten sie in ihrer Transaktion ab, statt jeden
  Aufruf umzuschreiben. Damit bleibt „Stammplatz ohne Raum verhält sich wie vorher“ durch die alten Tests belegt.
- Bereits geplante Termine bleiben beim Raumwechsel ohne Kinder stehen und zeigen „kein Coach“ (Bauauftrag W4 Nr. 4).

## Offen
`docs/slots/offene-punkte-w1.md`.
