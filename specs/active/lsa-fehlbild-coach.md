---
id: lsa-fehlbild-coach
type: code
repo: edvancev1
branch: spec/lsa-fehlbild-coach
depends_on: []
gates:
  - npm run typecheck
  - bash tools/neuaufbau-test.sh
  - bash tools/schema-snapshot.sh
---

## Ziel

Der Coach soll je Schüler sehen, welche Fehlertypen wie oft aufgetreten sind,
gruppiert nach Skill. Die Daten werden bereits erfasst (`af1_fehlbild_capture`
schreibt `lsa_responses.fehlbild_slug`), sind aber nirgends abfragbar.

Ohne diese Auswertung ist der diagnostische Kern der LSA unsichtbar: die Analyse
weiss, *warum* ein Kind falsch liegt, kann es aber niemandem sagen.

## Kontext

- `af1_fehlbild_capture` setzt beim Schreiben einer Antwort `lsa_responses.fehlbild_slug`
  über `lsa_fehlbild_match`.
- `fehlbild_labels` (aus A20) ist die Registry: `slug`, `klartext`, `erklaerung`.
- `known_errors` in `task_solutions.acceptance` ist bewusst schemafrei (Entscheidung A11).
  Die Auswertung muss mit unbekannten Schlüsseln umgehen, ohne zu brechen.
- Zugriff läuft über SECURITY-DEFINER-RPCs. `lsa_responses` hat keinen anon/authenticated-Grant.
  Das Muster steht in A21 (`a21_freigabe_muster`) — daran halten.
- Neue Migration nach dem üblichen Schema. Die Historie ist append-only.

## Akzeptanz

- RPC `lsa_fehlbild_report(p_session_id uuid)` liefert je Zeile:
  `skill_key`, `fehlbild_slug`, `klartext`, `anzahl`, `anteil` (Anteil an den
  falschen Antworten dieses Skills)
- Antworten ohne `fehlbild_slug` erscheinen als eigene Zeile mit `slug = null` und
  `klartext = 'nicht zugeordnet'` — sie verschwinden nicht stillschweigend
- Sortierung: Skill aufsteigend, darin Anzahl absteigend
- `revoke ... from public`, `grant execute` an `authenticated` und `service_role`,
  analog A21
- Ein Prüfskript `supabase/checks/<zeitstempel>_fehlbild_report.PRUEFUNG.sql`, das
  gegen vorhandene Daten prüft: Summe der Anzahlen je Skill = Zahl der falschen
  Antworten dieses Skills. Nicht in die Migration einbauen — Prüfungen gegen Daten
  können auf einer leeren Datenbank nicht bestehen.
- `supabase/schema-erwartet.sql` neu erzeugt und mitcommittet

## Nicht-Ziele

- Kein Frontend. Nur die RPC.
- Keine Änderung an `af1_fehlbild_capture` oder an der Erfassung
- Keine Änderung an `fehlbild_labels` oder deren Inhalt
- Keine Aggregation über mehrere Sitzungen hinweg — eine Sitzung, ein Bericht
