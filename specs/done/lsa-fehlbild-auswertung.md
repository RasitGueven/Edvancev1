---
id: lsa-fehlbild-auswertung
type: code
repo: edvancev1
branch: spec/lsa-fehlbild-auswertung
depends_on: []
gates:
  - bash tools/neuaufbau-test.sh
  - psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/checks/fehlbild_auswertung.PRUEFUNG.sql
---

## Ziel

Die erfassten Fehlbilder abfragbar machen — für zwei Leser mit verschiedenem Bedarf.
`af1_fehlbild_capture` schreibt `lsa_responses.fehlbild_slug`, aber niemand kann die Werte lesen. Ohne diese Auswertung weiss die LSA, *warum* ein Kind falsch liegt, und kann es niemandem sagen.

Zwei RPCs, **eine** Migration. Getrennt gebaut würden sie auseinanderlaufen.

## Kontext

- `af1_fehlbild_capture` setzt `lsa_responses.fehlbild_slug` über `lsa_fehlbild_match`.
- `fehlbild_labels` (A20) ist die Registry: `slug`, `klartext`, `erklaerung`.
- `known_errors` in `task_solutions.acceptance` ist bewusst schemafrei (A11). Die Auswertung muss mit unbekannten Schlüsseln umgehen, ohne zu brechen.
- Zugriff über SECURITY-DEFINER-RPCs. `lsa_responses` hat keinen anon/authenticated-Grant. Muster: A21 (`a21_freigabe_muster`).
- `abgabeart` unterscheidet `antwort` / `weiss_nicht` / `leer` (seit A13).
- Neue Migration nach dem üblichen Schema, Historie append-only.

**Vor dem Bauen lesen, nicht annehmen:** A20 und `af1_fehlbild_capture` im Original. Weicht die Wirklichkeit von diesem Kontext ab — Widerspruch benennen und stoppen, nicht überbrücken.

## Akzeptanz

### RPC 1 — `lsa_fehlbild_report(p_session_id uuid)` (Coach)

Operative Sicht, nach Skill gruppiert. Je Zeile:
`skill_key`, `fehlbild_slug`, `klartext`, `anzahl`, `anteil` (Anteil an den falschen Antworten dieses Skills).

- Antworten ohne `fehlbild_slug` erscheinen als eigene Zeile mit `slug = null` und `klartext = 'nicht zugeordnet'` — sie verschwinden nicht stillschweigend.
- Sortierung: Skill aufsteigend, darin Anzahl absteigend.
- `abgabeart in ('weiss_nicht','leer')` zählt **nicht** als falsche Antwort.

### RPC 2 — `lsa_fehlbild_auswertung(p_session_id uuid)` (Report)

Diagnostische Sicht, über die ganze Sitzung. Je Zeile:
`fehlbild_slug`, `klartext`, `anzahl`, `aufgaben` (verschiedene Aufgaben), `skills` (Array), `skill_uebergreifend`, `einstufung`.

- `einstufung = 'befund'` genau dann, wenn `anzahl >= 2 AND aufgaben >= 2`. Sonst `'beobachtung'`.
- `skill_uebergreifend = true` bei ≥ 2 verschiedenen Skills.
- Slug nicht in `fehlbild_labels`: Zeile erscheint, `klartext is null`. Kein INNER JOIN.

**Warum getrennt von RPC 1:** RPC 1 gruppiert nach Skill und macht damit skillübergreifende Muster unsichtbar — dasselbe Fehlbild in Brüchen *und* Gleichungen ist der stärkste Befund, erscheint dort aber als zwei unabhängige Zeilen. Der Elternreport braucht die Sitzungssicht.

### Sicherheit

Beide RPCs: `revoke ... from public`, `grant execute` an `authenticated` und `service_role`, analog A21. Keine Lösungsdaten aus `task_solutions` in der Rückgabe.

### Prüfskript

`supabase/checks/fehlbild_auswertung.PRUEFUNG.sql`

**Ohne Zeitstempel im Namen** — der Gleichstand von Migration und Prüfskript war bei `a21_freigabe_muster` die Ursache der Verwechslung. **Kein `\ir`** auf die Migration; das Skript läuft gegen eine bereits migrierte Datenbank.

**Legt seine Testdaten selbst an.** Es läuft auf einer leeren Neuaufbau-Datenbank — vorhandene Daten gibt es dort nicht.

**Fasst sich selbst in `BEGIN; … ROLLBACK;` ein.** Die Datenbank überlebt zwischen Läufen, und einen Runner, der die Kapselung übernimmt, gibt es nicht. Ohne Rollback kollidieren die Testdaten beim zweiten Lauf mit denen des ersten.

| # | Fall | Erwartung |
|---|---|---|
| 1 | Summe `anzahl` je Skill (RPC 1) | = Zahl der falschen Antworten dieses Skills |
| 2 | 1 Vorkommen | `einstufung = 'beobachtung'` |
| 3 | 2 Vorkommen, **dieselbe** Aufgabe | `'beobachtung'`, `aufgaben = 1` |
| 4 | 2 Vorkommen, 2 Aufgaben | `'befund'` |
| 5 | 3 Vorkommen über 2 Skills | `skill_uebergreifend = true` |
| 6 | Slug nicht in `fehlbild_labels` | Zeile erscheint, `klartext is null` |
| 7 | Falsche Antwort ohne Slug | eigene Zeile, `'nicht zugeordnet'` |
| 8 | Sitzung ohne Falschantworten | leeres Ergebnis, kein Fehler |
| 9 | Unbekannte Sitzungs-ID | leeres Ergebnis, kein Fehler |
| 10 | `weiss_nicht` / `leer` in der Sitzung | zählen nicht als falsch |

**Negativkontrolle:** Fall 3 schlägt an, wenn jemand die Einstufungsregel auf `anzahl >= 2` verkürzt. Fall 6, wenn jemand den Registry-Join auf INNER JOIN vereinfacht. Beide stehen im Prüfskript, nicht in der Funktion.

### Schnappschuss

Nach dem Schreiben der Migration `bash tools/schema-snapshot.sh`, `supabase/schema-erwartet.sql` mitcommitten. Der Diff dieser Datei ist die lesbare Schemaänderung des PRs. Läuft lokal, keine Produktionszugänge nötig.

## Nicht-Ziele

- Kein Frontend, keine Reportseite, keine Textbausteine.
- Keine Änderung an `af1_fehlbild_capture` oder an der Erfassung.
- Keine Änderung an `fehlbild_labels` oder deren Inhalt. Fehlende Slugs sind ein Befund für Lena.
- Keine Aggregation über mehrere Sitzungen.
- Kein Zugriff auf Produktion.
- Kein `src/lib/**`.
- Keine Interpretationsschwellen ausser `befund` / `beobachtung`.
- **Kein TypeScript.** Dieser Job ist SQL.
