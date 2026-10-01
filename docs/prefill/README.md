# Vorbefüllung für Lenas Prüfung

Ziel: Lena soll in der Item-Pflege nur noch prüfen und korrigieren, nichts mehr neu eintragen.

**VERA8 wird nie vorbefüllt und erscheint nicht im Lena-Board** (Entscheidung zu PR #176). Die Definition steht
einmal zentral in `src/lib/authoring/vera8.json` bzw. `vera8.ts`: `tasks.source = 'VERA8_IQB'`. Die VERA8-Sperre
wirkt an drei Stellen:

- Der Generator lehnt Chargen mit VERA8-Aufgaben ab.
- Jede Anweisung einer Prefill-Migration trägt `source is distinct from 'VERA8_IQB'`.
- `verify-tasks.mjs --prefill` schlägt fehl, wenn eine Charge oder eine Prefill-Migration VERA8 anfassen könnte.

## Charge `k8-vorlauf` (12 NEUE Aufgaben, nicht aus dem Bestand)

Die Vorlauf-Knoten `geo_koordinaten` und `term_einsetzen` bekommen je sechs Aufgaben, alle vorbefüllt (`status = 'draft'`).
Weil die Aufgaben neu entstehen, erzeugt `tools/vorlauf-build.mjs` statt `prefill-build.mjs` die Migration
`20261001120554_aufgaben_k8_vorlauf.sql`. Dazu kommen der Snapshot (Rohzustand) und die CSV. `verify-tasks.mjs --prefill`
prüft wie gewohnt. Befunde, Einspiel-Reihenfolge und Prüfprotokoll stehen in `befunde-k8-vorlauf.md`.

## Dateien der Charge `mathe8-pilot` (18 Binom-Aufgaben)

| Datei | Inhalt |
|---|---|
| `bestandsaufnahme.md` | VERA8-Definition, Felder der Item-Pflege, erlaubte Werte, Leerstand je Feld, Lücken in der UI |
| `mathe8-pilot.json` | **Quelle** der Charge: Werte, Sicherheit, Begründung, Leer-Gründe und maschinelle Prüfangaben |
| `mathe8-pilot-snapshot.json` | Stand der 18 Aufgaben in der DB beim Erzeugen (nur gelesen) |
| `mathe8-pilot.csv` | Für Lena: Aufgabe-ID, Teilaufgabe, Feld, neuer Wert, Unsicherheit/Begründung, dazu die bewusst leeren Felder |
| `mathe8-pilot-blind.json` | Antworten eines unabhängigen Lösers, der die Lösungen nicht gesehen hat |
| `mathe8-pilot-verifikation.md` | Prüfprotokoll von `verify-tasks.mjs --prefill` |
| `mathe8-pilot-dbcheck.sql` | Rein lesend: der berechnete Endstand gegen die DB-Validatoren. Ergebnis 30.09.: alle 18 Zeilen durchgehend `t` |
| `befunde.md` | Befundliste für Lena und Rasit |
| `vorschlag-prefill-marker.sql` | Vorschlag „vorbefüllt vs. geprüft". **Nicht einspielen** ohne Freigabe (Auth/RLS). |

Stand der Migrationen (30.09.2026):

| Datei | Inhalt | Stand |
|---|---|---|
| `20260930130000_freigabe_cluster_ohne_vera8.sql` | „Alle geprüften freigeben" erfasst kein VERA8 | **eingespielt** (History-Eintrag, Definition per pg_proc bestätigt) |
| `20260930140000_tasks_vorbefuellt.sql` | Kennzeichen `tasks.vorbefuellt` / `vorbefuellt_am` | **eingespielt** (Spalten, CHECK und Rechte bestätigt) |
| `20260930150000_prefill_mathe8_pilot.sql` | Pilot-Daten (18 Binom-Aufgaben) | **eingespielt** am 30.09. — Ergebnis in `mathe8-pilot-eingespielt.md` (Versionsausnahme von #180, siehe Kopfkommentar) |
| `20260930150100_prefill_rest_01.sql` | Restbestand Charge 1: 28 Aufgaben (6 Binom, 22 fundament_afb1) | **eingespielt** — `rest-01/` |
| `20260930150200_prefill_rest_02.sql` | Restbestand Charge 2: 47 Sachaufgaben (fundament_kontext) | **eingespielt** — `rest-02/` |

Ab dem Restbestand liegt jede Charge in `docs/prefill/<charge>/`: Quelle, Snapshot, CSV, Blind-Antworten,
Verifikation, Prod-Abgleich (vorher), Nachweis (nachher), Befunde.

**Stand 30.09.2026 (Board ohne VERA8: 362 Aufgaben):**

- Alle 93 offenen Aufgaben (`draft`) sind vorbefüllt und gekennzeichnet.
  - 46 davon sind vollständig.
  - 47 haben ein bewusst leeres Feld (Prozesskompetenz bei Sachaufgaben).
  - Lücken ohne Grund: 0.
- Nicht vorbefüllt sind 269 Aufgaben mit `ready`, `beanstandet` oder `review`. Sie hat ein Mensch bereits bearbeitet
  oder freigegeben. Bei `ready` wären neue Hinweise sofort für Schüler:innen sichtbar, ohne Lenas Prüfung.

Die Pilot-Datei ersetzt `20260930120000_prefill_mathe8_pilot` (Versionskollision mit S2b, nie eingespielt).
Sie wird aus der JSON-Quelle erzeugt; bitte nicht von Hand editieren.

Vor dem Einspielen:
- `mathe8-pilot-prod-abgleich.md`: nur lesend gegen Prod — welche Felder die Migration heute ändern würde
  und wo Prod schon andere Werte hat.
- Wegwerf-DB (lokaler Socket): alle Migrationen in Dateireihenfolge, dann der Pilot mit den echten Daten aus dem
  Snapshot, CSV-Abgleich, zweiter Lauf ohne Änderung.

## Neu erzeugen und prüfen

```bash
node tools/prefill-build.mjs docs/prefill/mathe8-pilot.json docs/prefill/mathe8-pilot-snapshot.json \
     20260930150000 prefill_mathe8_pilot
node tools/verify-tasks.mjs --prefill docs/prefill/mathe8-pilot.json \
     --snapshot docs/prefill/mathe8-pilot-snapshot.json \
     --migration supabase/migrations/20260930150000_prefill_mathe8_pilot.sql \
     --blind docs/prefill/mathe8-pilot-blind.json --bericht docs/prefill/mathe8-pilot-verifikation.md
```

Der Prüfer braucht weder LLM noch DB noch `node_modules`. Exit 1 bei Charge-Fehlern.

## Einspielen (nach Freigabe)

Ziel-DB-Check, dann die Migration in **einer** Transaktion, dann der History-Eintrag. Der DB-Namens-Check steht nur
hier in der Kette, nicht in der Migration (CI spielt in `neuaufbau` ein).

```bash
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f supabase/migrations/20260930150000_prefill_mathe8_pilot.sql && echo "insert into supabase_migrations.schema_migrations (version, name, statements) values ('20260930150000', 'prefill_mathe8_pilot', array[:'stmt']) on conflict (version) do nothing;" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v stmt="$(cat supabase/migrations/20260930150000_prefill_mathe8_pilot.sql)"
```

Nach jeder Schemaänderung: `bash tools/schema-snapshot.sh` (lesender Abzug der Ziel-DB, kein lokales Postgres)
und `supabase/schema-erwartet.sql` committen.

Die Daten-Migration ist idempotent: Jedes UPDATE ist ein Compare-and-set (`/*cas*/`: Feld leer ODER exakter alter
Wert), dazu `status = 'draft'` und „nicht VERA8"; das Kennzeichen entsteht in derselben Anweisung.
