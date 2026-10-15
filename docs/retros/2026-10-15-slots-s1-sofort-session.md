# Retro 15.10.2026 — Slots S1: Sofort-Session und Buchbarkeit mit Grund

## Gebaut
- **Datenbank** (`20261015093534_slots_s1_sofort_session.sql`, nur neue Funktionen, keine bestehende geändert):
  - `kinder_buchbar(p_datum, p_session_id)`: je Kind ein Grund (`kein_vertrag`, `widerrufen`, `vertrag_ab`,
    `vertrag_beendet`, `keine_einheit`, `schon_termin`, `art_konflikt`, `ok`) mit Datum als Detail.
  - `sofort_session_anlegen(p_coach_id, p_raum_id, p_student_ids)`: Einzel-Session ab jetzt (auf die Minute), Raumname
    als `room`, Leitung Coach oder Admin, nur Testkinder → Testlauf, danach `termine_planen` je echtem Kind.
  - `session_leitung()`, `stundenplan_woche(p_montag)`. Alle nur Admin, EXECUTE nur `authenticated`.
- **Frontend-Lib:** `src/lib/supabase/stundenplan.ts`, Typen `src/types/stundenplan.ts`, Fehlerabbildung in
  `src/lib/slots/fehler.ts` erweitert, Texte `slots.json` (`fehler.*`, `buchbar.*`). `sessionRpc` gibt `detail` weiter.
- **Doku:** Datenvertrag Abschnitt 12, `docs/slots/offene-punkte-s1.md`.

## Entscheidungen beim Bauen
- **Vertrags-Codes nur, wenn `session_platz_zugang` nein sagt.** Damit gilt die Gleichheit mit dem Trigger ZG001 durch
  den Aufbau; welcher der vier Codes, erklärt nur den Grund. Rest: `kein_vertrag`.
- **Brückentag → `keine_einheit`** (kein Vertrag zum Abrechnen, wie SL006 bei Zusatzterminen).
- **`p_session_id`:** Eigene Buchung (Einzel oder festgeschriebener Slot-Termin) zählt weder als Termin noch als
  Einheit; `p_datum` muss der Tag der Session sein (aus der Zweitprüfung).
- **Antwort zu `slots_fest_belegt`:** Ja, Einzelbuchungen zählen mit (über `slots_einzelbuchungen`, im Zeitraum
  `vertragsbeginn..vertrag_ende`, Zustände planned/present/unexcused). Testläufe nie.

## Geprüft
- pgTAP `slots_s1`: 65 Zusicherungen. Volle Suite in eigener Wegwerf-DB (Port 55461) wie in der CI: alle grün außer
  den 8 aus `bekannt-rot.txt`.
- Fundstück beim Testen: `kt.session_id is distinct from p_session_id` war bei zwei NULL falsch — ein Stammplatz-Termin
  ohne Session galt nicht als `schon_termin`. Behoben, Test deckt es.
- Zweitprüfung durch frische Instanz (Rechte, Einheiten): nichts Blockierendes. Befund `p_session_id` behoben, Rest
  dokumentiert (offene Punkte 12–17).
- `npm ci && npm run typecheck && npm run lint && npm run test` grün.

## Offen
- Siehe `docs/slots/offene-punkte-s1.md`, vor allem Gruppengröße > 5 und die Oberfläche (Stundenplan, Dialog).
- Einspielen erst nach „S1 einspielen“.
