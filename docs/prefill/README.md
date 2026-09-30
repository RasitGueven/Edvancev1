# Vorbefüllung für Lenas Prüfung

Ziel: Lena soll in der Item-Pflege nur noch prüfen und korrigieren, nichts mehr neu eintragen.

**VERA8 wird nie vorbefüllt und erscheint nicht im Lena-Board** (Entscheidung zu PR #176). Die Definition steht
einmal zentral in `src/lib/authoring/vera8.json` bzw. `vera8.ts`: `tasks.source = 'VERA8_IQB'`. Die VERA8-Sperre
wirkt an drei Stellen:

- Der Generator lehnt Chargen mit VERA8-Aufgaben ab.
- Jede Anweisung einer Prefill-Migration trägt `source is distinct from 'VERA8_IQB'`.
- `verify-tasks.mjs --prefill` schlägt fehl, wenn eine Charge oder eine Prefill-Migration VERA8 anfassen könnte.

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

Zwei Migrationen, beide **nicht eingespielt**:

- `supabase/migrations/20260930120000_prefill_mathe8_pilot.sql`: die Daten. Sie wird aus der JSON-Quelle erzeugt;
  bitte nicht von Hand editieren.
- `supabase/migrations/20260930130000_freigabe_cluster_ohne_vera8.sql`: „Alle geprüften freigeben" im Board erfasst
  kein VERA8 mehr.

## Neu erzeugen und prüfen

```bash
node tools/prefill-build.mjs docs/prefill/mathe8-pilot.json docs/prefill/mathe8-pilot-snapshot.json \
     20260930120000 prefill_mathe8_pilot
node tools/verify-tasks.mjs --prefill docs/prefill/mathe8-pilot.json \
     --snapshot docs/prefill/mathe8-pilot-snapshot.json \
     --migration supabase/migrations/20260930120000_prefill_mathe8_pilot.sql \
     --blind docs/prefill/mathe8-pilot-blind.json --bericht docs/prefill/mathe8-pilot-verifikation.md
```

Der Prüfer braucht weder LLM noch DB noch `node_modules`. Exit 1 bei Charge-Fehlern.

## Einspielen (macht Rasit)

Ziel-DB-Check, dann jede Migration in **einer** Transaktion mit anschließendem History-Eintrag. Der DB-Namens-Check
steht nur hier in der Kette, nicht in den Migrationen: CI spielt sie in eine DB namens `neuaufbau` ein.

```bash
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f supabase/migrations/20260930120000_prefill_mathe8_pilot.sql && echo "insert into supabase_migrations.schema_migrations (version, name, statements) values ('20260930120000', 'prefill_mathe8_pilot', array[:'stmt']) on conflict (version) do nothing;" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v stmt="$(cat supabase/migrations/20260930120000_prefill_mathe8_pilot.sql)" && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f supabase/migrations/20260930130000_freigabe_cluster_ohne_vera8.sql && echo "insert into supabase_migrations.schema_migrations (version, name, statements) values ('20260930130000', 'freigabe_cluster_ohne_vera8', array[:'stmt']) on conflict (version) do nothing;" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v stmt="$(cat supabase/migrations/20260930130000_freigabe_cluster_ohne_vera8.sql)"
```

Danach `bash tools/schema-snapshot.sh` laufen lassen und `supabase/schema-erwartet.sql` committen. Ohne neuen
Snapshot meldet der Schema-Job in CI die neue `freigabe_cluster`-Fassung als Abweichung. Ein Hook sperrt das
Handeditieren der Datei, und das Skript nutzt eine lokale DB.

Die Daten-Migration ist idempotent. Jedes UPDATE prüft „Feld ist leer", `status = 'draft'` und „nicht VERA8", ein
zweiter Lauf ändert also nichts.
