# P00b+ — Schema-Abgleich, Migrations-Umzug & DB-Autonomie

> BEAUFSICHTIGT ausführen (fasst zum ersten Mal die DB-Struktur an). `./scripts/claude-auto.sh prompts/infra/P00b-plus-schema-abgleich.md`
> Voraussetzung: Docker läuft (`docker info` ok), P00 gemergt.
> Ziel: (1) Ist-Zustand DB vs. Code abgleichen, (2) Root-migrations/ → supabase/migrations/ umziehen, (3) DB frisch + getrackt aufsetzen, (4) Agenten-fähigen Migrations-Flow etablieren — sodass Rasit künftig DB-Änderungen per Agent + Migration machen kann.
> Kontext: DB-Daten sind WEGWERFBAR. Es gibt keine schema_migrations-Tracking-Tabelle. Code erwartet Spalten/Tabellen (task_type, task_assets), die die echte DB nicht hat. Ziel ist ein sauberer Strich, keine behutsame Nachzieh-Migration.

## Kernprinzip (nicht verhandelbar)
**Schreibende DB-Änderungen NUR über versionierte Migrationsdateien — nie durch freie ad-hoc-SQL-Statements gegen die Remote-DB.** Der Agent baut + testet Migrationen lokal gegen Docker-Postgres. Das Anwenden auf Remote/Prod passiert über einen expliziten, kontrollierten Schritt (siehe Phase 5), NICHT durch beiläufige Statements. Grund: Eine Migration ist nachvollziehbar und wiederholbar; ein freies DROP/ALTER im Lauf ist unkontrolliert und unauffindbar.

## Grants (VOR Start in .claude/settings.local.json prüfen)
Nötig: `Bash(docker *)`, `Bash(supabase *)`, `Bash(npx supabase *)`, `Bash(psql *)`, `Bash(python3 *)`, `Bash(command -v *)`. KEIN curl/pip/sudo. Falls supabase-CLI fehlt: über `npx supabase` nutzen.

## DB-Zugang
Der Connection-String (Prod, wegwerfbar) liegt in `.env` als `DATABASE_URL` bzw. wie im Repo üblich. Der Lauf liest ihn NUR für: (a) Ist-Zustand-Abfrage (read), (b) den kontrollierten Reset in Phase 4. Niemals für freie Schreib-Statements.

## Phase 0 — Voraussetzungen (STOP bei Fehlschlag)
- `docker info` ok? Sonst STOP.
- supabase-CLI verfügbar (`supabase --help` oder `npx supabase --help`)? CLI-Kommandos gegen die installierte Version verifizieren BEVOR Skripte geschrieben werden (Flags variieren je Version).
- `.env` mit DB-Connection-String vorhanden? Sonst STOP, Rasit bereitstellen lassen.

## Phase 1 — Schema-Abgleich (read-only, der Ist-Zustand)
Erzeuge `scripts/db/schema_abgleich.py` (oder .sql + Auswertung), das drei Quellen vergleicht:
1. **Echte DB:** via information_schema alle Tabellen + Spalten + Typen + Enums abfragen (read-only).
2. **schema.sql** (Repo-Root): parsen, welche Tabellen/Spalten es definiert.
3. **migrations/** (Root, die 43 Dateien): welche Migration was anlegt/ändert.
Deliverable `docs/audits/SCHEMA-ABGLEICH.md`:
- Diff-Tabelle: Tabelle/Spalte × {in DB? in schema.sql? in migrations/?}
- Konkret die bekannten Lücken bestätigen: fehlt `task_type` in tasks? fehlt `task_assets`? Wie verhält sich `tasks.assets` (existiert) zu code-erwartetem `task_assets`?
- Empfehlung: Ist `schema.sql` die verlässlichste Wahrheit für den Neuaufbau, oder muss es erst aus migrations/ konsolidiert werden?
- **Kein Schreibzugriff in dieser Phase.** Nur Analyse.
Commit: `docs(db): schema-abgleich ist-zustand`

## Phase 2 — Supabase-Konvention & Migrations-Umzug
- `supabase init` falls supabase/config.toml fehlt (bestehende migrations/ bleiben unberührt).
- Root-`migrations/*.sql` → `supabase/migrations/` umziehen, mit korrektem Timestamp-Namensschema der Supabase-Konvention (`<timestamp>_<name>.sql`). Reihenfolge bewahren (die numerische Prefix-Ordnung der alten Dateien bestimmt die neue Timestamp-Reihenfolge).
- `schema.sql` → `supabase/schema.sql` (falls die Konvention es vorsieht) oder als Referenz behalten — gemäß dem, was Phase 1 als Wahrheit empfiehlt.
- Guards (guard-paths.sh) auf die NEUEN Pfade (`supabase/migrations/`) umstellen; alte Root-Pfade-Regel entfernen.
Commit: `refactor(db): migrations in supabase-konvention umgezogen`

## Phase 3 — Konsolidierte Baseline lokal beweisen (Docker)
- `supabase start` (lokaler Stack via Docker).
- `supabase db reset` (LOKAL, ohne --linked) — baut die DB aus supabase/migrations/ komplett neu auf. Muss fehlerfrei durchlaufen.
- `supabase db lint --level error` — keine Fehler.
- Verifizieren: Hat die lokal aufgebaute DB jetzt task_type, task_assets bzw. die vom Code erwartete Struktur? Diff gegen die Code-Erwartung dokumentieren.
- Falls die alten migrations/ inkonsistent sind (nicht sauber durchlaufen): eine konsolidierte Baseline-Migration aus schema.sql erzeugen, die den Ziel-Zustand herstellt. Dokumentieren, welcher Weg gewählt wurde.
Commit: `feat(db): konsolidierte baseline, lokal bewiesen`

## Phase 4 — Prod frisch aufsetzen (STOP-BESTÄTIGUNG PFLICHT)
**Die Daten sind wegwerfbar, aber der Reset löscht ALLES. Vor diesem Schritt HALT und explizite Bestätigung von Rasit einholen** — nicht still ausführen. Gib aus: „Ich werde jetzt die Prod-DB komplett neu aufsetzen (alle Daten weg). Fortfahren? Bestätige mit Ja." und WARTE.
Nach Bestätigung:
- schema_migrations-Tracking etablieren (Supabase-CLI legt es bei `db push` an) und die Baseline auf Prod anwenden.
- Verifizieren: Prod hat jetzt die konsolidierte Struktur, schema_migrations ist gefüllt.
Falls im beaufsichtigten Lauf keine interaktive Bestätigung möglich ist: Phase 4 NICHT ausführen, stattdessen die exakten Befehle in die RETRO schreiben, damit Rasit sie manuell ausführt.

## Phase 5 — Agenten-Migrations-Flow etablieren
- `scripts/db/migrate-verify.sh`: reset(local) → lint → pgTAP/RLS-Tests → Drift-Check (`supabase db diff` muss leer sein) → App-Tests. Der Beweis, dass eine Migration sicher ist, bevor sie live geht.
- pgTAP-Test für die FernUSG-Invariante INV-1 (Mastery-Trigger trg_enforce_mastery_gate: nur coach/admin dürfen student_competency_mastery schreiben) — als Regressionsschutz.
- Guard-Erweiterung: `supabase db push --linked` / remote-Anwendung bleibt im Agenten GESPERRT (nur local reset erlaubt). Remote-Push ist ein bewusster Menschen-/CI-Schritt.
- Runbook `docs/runbooks/DB-MIGRATIONEN.md`: Wie Rasit künftig eine Migration macht — Agent schreibt Migration + migrate-verify.sh grün → PR → nach Merge kontrollierter push auf Prod.

## Phase 6 — Beweis-Migration
Eine echte kleine Beispiel-Migration, die zeigt dass der Flow funktioniert — z.B. die im Schema-Abgleich gefundene Code/DB-Diskrepanz sauber schließen (falls task_type o.ä. wirklich fehlt). Lokal via migrate-verify.sh bewiesen. Das ist der Beleg, dass der Agent jetzt DB-Änderungen kann.

## Abnahme
- [ ] SCHEMA-ABGLEICH.md mit Diff-Tabelle (DB vs schema.sql vs migrations/)
- [ ] migrations/ in supabase/migrations/ umgezogen, Reihenfolge bewahrt, Guards auf neue Pfade
- [ ] Lokale DB baut fehlerfrei aus supabase/migrations/ (reset + lint grün)
- [ ] Prod-Reset NUR nach expliziter Bestätigung ODER Befehle in RETRO für manuelle Ausführung
- [ ] migrate-verify.sh vorhanden, INV-1 pgTAP-Test grün
- [ ] Remote-push im Agenten weiterhin gesperrt (nur local autonom)
- [ ] DB-MIGRATIONEN.md Runbook
- [ ] typecheck/lint/test grün · RETRO-P00b-plus.md
