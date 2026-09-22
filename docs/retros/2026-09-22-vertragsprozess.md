# Retro 2026-09-22 — Vertragsprozess

Branch `feat/vertraege-prozess` (von `origin/dev`), Worktree `../Edvancev1-vertraege`.

## Gebaut

**Datenbank**
- `20260922120000_vertraege_prozess` (live eingespielt, zusammen mit dem
  History-Eintrag in einer Transaktion):
  - `tiers`: 199,90 / 269,90 / 349,90 €
  - `leads`: `erstgespraech_at`, `erstgespraech_standort`, `rejected_at`,
    `rejection_reason`, `rejection_note`, Status `vertrag`; `rejected_at` setzt
    der vorhandene Status-Trigger
  - `vertraege` mit Status-Zeitstempeln, eingefrorenem Preis (Trigger aus `tiers`),
    automatischer Mandatsreferenz, `iban_masked`
  - `vertrag_bankdaten` (volle IBAN, nur Admin), `vertrag_einstellungen`
    (Gläubiger-ID), `vertrag_dokumente` (Katalog mit Version),
    `vertrag_zustimmungen`, `vertrag_unterschriften`, `vertrag_versand`
  - RPCs `vertrag_starten`, `vertrag_versand_protokollieren`,
    `vertrag_abschliessen`, `vertrag_ablehnen` — idempotent, Statuswechsel nur
    über sie (Guard-Trigger)
- `20260922130000_vertraege_rpc_admin_sperre`: Admin-Sperre der RPCs auch für
  Aufrufer ohne Profilzeile. **Noch nicht eingespielt.**
- Prüfskript `supabase/checks/vertraege_prozess.PRUEFUNG.sql` (rollt zurück).

**Frontend**
- Lead-Board: Termin-Modal, Ablehnen mit Pflichtgrund in allen Spalten,
  „Vertrag starten“ + Report-Link in „Analyse abgeschlossen“, Nachfass-Hinweis
  ab 7 Tagen ab `lsa_fertig_at`. Board, Karte und Filter über i18n (`leads`).
- `/admin/vertraege`, `/admin/vertraege/:id`, `/admin/vertraege/:id/unterlagen`
  (i18n `vertraege`). Spaltenraster, Overflow-Menü, Filterleiste und
  Konversion sind gemeinsame Bausteine beider Boards.

## Entscheidungen
- E-Mail-Versand deaktiviert mit Tooltip (kein Anbieter im Projekt), Ausdruck
  über die Druckansicht statt PDF-Bibliothek.
- Verträge und volle IBAN nur für Admins; Coaches sehen „Vertrag starten“
  deaktiviert mit Hinweis.
- „In Schüler konvertieren“ wandert vom Lead-Board auf die Karte „Abgeschlossen“.
- Häkchen werden mit Klick-Zeitpunkt lokal gehalten und erst mit der
  Unterschrift in einem RPC-Aufruf geschrieben — kein halber Zustand.
- Nachfass-Hinweis nie ab dem Anlagedatum: Bestandsleads ohne `lsa_fertig_at`
  bekommen keinen Hinweis, und die Zeitzeile in dieser Spalte bleibt neutral.
- Datenschutzhinweise zum Vertrag sind eine eigene Datei und ein eigener
  Datensatz, getrennt von der LSA-Einwilligung.

## Stolpersteine
- Versionskollision: `20260922100000` war schon durch
  `item_freigabe_pruefrecht` belegt (live, Branch `feat/item-freigabe`).
  `db-migrate.sh` hätte die Vertragsmigration still übersprungen. Umbenannt auf
  `…120000`.
- `get_my_role()` liefert für Nutzer ohne Profil `NULL`; `<> 'admin'` greift
  dann nicht. Gefunden durch Test 9 der PRUEFUNG, behoben in `…130000`.
- `disabled:pointer-events-none` am Button schluckt den `title`-Tooltip — der
  Tooltip steht deshalb am umschließenden `span`.

## Offen
- `20260922130000` einspielen, danach PRUEFUNG erneut laufen lassen.
- E-Mail-Versand (Anbieter, Secret, Domain) und echte PDF-Anhänge.
- Rechtstexte statt Platzhaltern; Gläubiger-ID in `vertrag_einstellungen`.
- Browser-Test des gesamten Flows im Preview.
- Schülerakte auf Basis von `vertraege`.
