# Runbook: DB-Migrationen

Wie eine Schema-Änderung ab jetzt läuft — vom Agenten bis auf Prod.

## Kernprinzip

**Schreibende DB-Änderungen laufen ausschließlich über versionierte Migrationen.**
Kein freies `ALTER`/`DROP` gegen die Remote-DB. Eine Migration ist nachvollziehbar
und wiederholbar; ein Ad-hoc-Statement im SQL-Editor ist es nicht — und genau
daraus ist der Zustand entstanden, den P00b+ aufräumen musste
(siehe `docs/audits/SCHEMA-ABGLEICH.md`).

**Arbeitsteilung:**

| | Agent / lokal | Mensch / CI |
|---|---|---|
| Migration schreiben | ✅ | |
| Lokal beweisen (`migrate-verify.sh`) | ✅ | |
| Auf Prod anwenden (`db push`) | ❌ **gesperrt** | ✅ |

Der Agent darf die lokale Wegwerf-DB beliebig neu aufbauen. Das Anwenden auf Prod
ist ein bewusster Schritt eines Menschen — abgesichert durch `.claude/hooks/guard-bash.sh`.

## Struktur

```
supabase/
  migrations/
    20250101000000_baseline.sql   ← konsolidierter Struktur-Stand (generiert)
    20260711120000_api_role_grants.sql
    <neue Migrationen kommen hier dazu>
  seed.sql                        ← idempotente Katalogdaten
  tests/
    inv1_mastery_gate.test.sql    ← pgTAP: FernUSG-Invariante
  migrations_archive/             ← die 43 historischen Inkremente, NICHT mehr ausgeführt
```

Die 43 Altdateien in `migrations_archive/` sind **nicht replay-fähig** (sie setzen ein
handgebautes Basis-Schema voraus, das nie als Migration existierte). Sie bleiben nur
zur Nachvollziehbarkeit liegen. **Nichts daraus wieder aktivieren.**

## Eine Migration machen

1. **Neue Datei anlegen:**
   ```bash
   npx supabase migration new <sprechender_name>
   ```
   Das erzeugt `supabase/migrations/<timestamp>_<name>.sql`. Nie eine bestehende
   Migration ändern — die ist auf Prod eventuell schon gelaufen.

2. **SQL schreiben.** Jede neue Tabelle braucht sofort RLS + Policies (CLAUDE.md §7).

3. **Lokal beweisen:**
   ```bash
   bash scripts/db/migrate-verify.sh
   ```
   Die Kette ist: `db reset` → `db lint` → `pgTAP` → Drift-Check → `typecheck` + `test`.
   Erst wenn das grün ist, ist die Migration PR-reif. Der `db reset` baut die DB
   **komplett neu** aus den Migrationen — das ist der eigentliche Beweis.

4. **PR nach `dev`.** Diff der Migration reviewen.

5. **Nach dem Merge: Prod.** Bewusst, von Hand:
   ```bash
   npx supabase link --project-ref <ref>
   npx supabase db push
   ```
   `db push` schreibt in `supabase_migrations.schema_migrations` mit — dadurch ist
   erstmals nachvollziehbar, welche Migration auf Prod gelaufen ist.

## Voraussetzung: Prod-Zugang

`.env` braucht einen **funktionierenden** `DATABASE_URL`. Stand heute steht dort noch
der Dashboard-Platzhalter `[YOUR-PASSWORD]`.

Wichtig: der Direkt-Host `db.<ref>.supabase.co` löst **nur auf IPv6** auf. Aus WSL2
(keine IPv6-Route) ist er nicht erreichbar. Nimm den **IPv4-Pooler** (Supavisor,
Session-Mode) aus dem Supabase-Dashboard → *Connect*:

```
postgresql://postgres.<ref>:<passwort>@aws-<N>-<region>.pooler.supabase.com:5432/postgres
```

Prüfen, ohne etwas zu schreiben:
```bash
python3 scripts/db/db_introspect.py     # liest den Ist-Zustand read-only
```

## Prod erstmalig aufsetzen (einmalig, P00b+ Phase 4)

Prod hat **kein** Migrations-Tracking und einen Struktur-Stand, der nie geprüft
wurde. Die Daten sind wegwerfbar, deshalb: sauberer Strich.

> ⚠️ **Der Reset löscht ALLE Prod-Daten.** Bewusst ausführen.

```bash
# 1. Ist-Zustand sichern (Beweisstück, falls doch etwas gebraucht wird)
npx supabase link --project-ref <ref>
npx supabase db dump --file prod-backup-$(date +%F).sql

# 2. Prod aus den Migrationen neu aufbauen
npx supabase db reset --linked

# 3. Verifizieren
python3 scripts/db/db_introspect.py     # 35 Relationen, schema_migrations gefüllt
```

Danach ist Prod = `supabase/migrations/`, und `schema_migrations` trackt das.

## Warum `20260711120000_api_role_grants.sql` existiert

Ohne diese Migration ist eine frisch gebaute DB **funktionsunfähig**:
`anon`/`authenticated`/`service_role` bekommen auf von `postgres` angelegten Tabellen
**kein** SELECT/INSERT/UPDATE/DELETE (Postgres vergibt Tabellenrechte über
`ALTER DEFAULT PRIVILEGES` abhängig vom anlegenden Rollennamen). Jeder App-Query
scheiterte mit `permission denied for table …`.

In der alten Prod-DB fiel das nie auf, weil sie nie aus Migrationen gebaut wurde.
Die Migration setzt die Grants **und** die Default-Privileges für künftige Tabellen —
sonst hätte jede neue Migration denselben Defekt wieder.

## Was der Agent NICHT darf

`guard-bash.sh` blockt (bzw. soll blocken — siehe `AUTONOMY_NOTES.md`):
- `supabase db push` — Remote-Apply
- alles mit `--linked` — richtet das Kommando gegen Remote
- `--db-url` auf einen nicht-lokalen Host
- freies `DROP`/`TRUNCATE TABLE` per `psql` gegen eine DB

Lokales `supabase db reset` ist **erlaubt** — die lokale DB ist wegwerfbar, und ohne
Reset gibt es keinen Beweis.
