# Vorbefüllung für Lenas Prüfung

Ziel: Lena soll in der Item-Pflege nur noch prüfen und korrigieren, nichts mehr neu eintragen.

## Dateien der Charge `mathe8-pilot`

| Datei | Inhalt |
|---|---|
| `bestandsaufnahme.md` | Welche Felder Lena sieht und bearbeitet, erlaubte Werte, Leerstand je Feld, Lücken in der UI |
| `mathe8-pilot.json` | **Quelle** der Charge: Werte, Sicherheit, Begründung, Leer-Gründe und maschinelle Prüfangaben |
| `mathe8-pilot-snapshot.json` | Stand der 25 Aufgaben in der DB beim Erzeugen (nur gelesen) |
| `mathe8-pilot.csv` | Für Lena: Aufgabe-ID, Teilaufgabe, Feld, neuer Wert, Unsicherheit/Begründung, dazu die bewusst leeren Felder |
| `mathe8-pilot-blind.json` | Antworten eines unabhängigen Lösers, der die Lösungen nicht gesehen hat |
| `mathe8-pilot-verifikation.md` | Prüfprotokoll von `verify-tasks.mjs --prefill` |
| `mathe8-pilot-dbcheck.sql` | Rein lesend: der aus Snapshot + Charge berechnete Endstand gegen die DB-Validatoren (`lsa_parts_valid`, `lsa_answers_valid`, `lsa_has_answers`) — Ergebnis 30.09.: alles `t`, außer `has_answers` bei #2 und #17 (bewusst leer) |
| `befunde.md` | Befundliste für Lena und Rasit |
| `vorschlag-prefill-marker.sql` | Vorschlag „vorbefüllt vs. geprüft". **Nicht einspielen** ohne Freigabe (Auth/RLS). |

Die Migration liegt in `supabase/migrations/20260930120000_prefill_mathe8_pilot.sql`. Sie wird aus der JSON-Quelle
erzeugt; bitte nicht von Hand editieren.

## Neu erzeugen und prüfen

```bash
node tools/prefill-build.mjs docs/prefill/mathe8-pilot.json docs/prefill/mathe8-pilot-snapshot.json \
     20260930120000 prefill_mathe8_pilot
node tools/verify-tasks.mjs --prefill docs/prefill/mathe8-pilot.json \
     --snapshot docs/prefill/mathe8-pilot-snapshot.json --blind docs/prefill/mathe8-pilot-blind.json \
     --bericht docs/prefill/mathe8-pilot-verifikation.md
```

Der Prüfer braucht weder LLM noch DB noch `node_modules`. Exit 1 bei Charge-Fehlern.

## Einspielen (macht Rasit)

Ziel-DB-Check, dann die Migration in **einer** Transaktion, dann der Eintrag in die History:

```bash
psql "$DATABASE_URL" -tAc "select current_database()" | grep -qx postgres && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction -f supabase/migrations/20260930120000_prefill_mathe8_pilot.sql && echo "insert into supabase_migrations.schema_migrations (version, name, statements) values ('20260930120000', 'prefill_mathe8_pilot', array[:'stmt']) on conflict (version) do nothing;" | psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v stmt="$(cat supabase/migrations/20260930120000_prefill_mathe8_pilot.sql)"
```

Die Datei ist idempotent. Jedes UPDATE prüft „Feld ist leer" und `status = 'draft'`, ein zweiter Lauf ändert also
nichts. Die DB-Validatoren wurden vorab schon rein lesend auf den berechneten Endstand angewandt
(`mathe8-pilot-dbcheck.sql`).
