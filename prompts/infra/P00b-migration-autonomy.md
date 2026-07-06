# P00b — Migration Autonomy: sichere autonome DB-Migrationen

> **Self-contained Claude-Code-Spec. Voraussetzung: P00 ist gemergt.** Ausführen im Repo-Root:
> `claude -p "$(cat prompts/infra/P00b-migration-autonomy.md)"`
> Ziel: Claude Code kann Migrationen schreiben UND selbst beweisen, dass sie sicher sind — gegen eine wegwerfbare lokale DB. Das Ausrollen auf Remote/Prod bleibt bewusst ein Menschen-/CI-Schritt.

---

## Kernprinzip (nicht verhandelbar)

**Local anwenden = autonom. Remote/Prod anwenden = niemals im Agenten.**
Migrationen sind die einzige irreversible Fehlerklasse: ein force-gepushter Branch ist ärgerlich, eine auf Prod gelaufene Migration ist weg. Deshalb: Der Agent baut + beweist die Migration lokal; `supabase db push` (Remote) läuft ausschließlich über CI gegen Staging-zuerst, ausgelöst durch Menschen-Merge.

## Voraussetzungen prüfen (Phase 0)
- `command -v docker` und `docker info` — Docker-Daemon muss laufen (Supabase local braucht ihn). Fehlt Docker: STOP, in Retro notieren „Docker Desktop erforderlich", Spec nicht weiter ausführen.
- `command -v supabase` — CLI vorhanden? Sonst via `npx supabase` nutzen und in allen Skripten `supabase` → `npx supabase` anpassen.
- `supabase/config.toml` vorhanden? Falls nicht: `supabase init` (legt supabase/ an; bestehende migrations/ bleiben unberührt).
- CLI-Kommandos gegen die installierte Version verifizieren (`supabase --help`, `supabase db --help`) BEVOR du Skripte schreibst — Flags können je Version abweichen. Diese Spec nutzt: `supabase start/stop`, `supabase db reset`, `supabase db diff`, `supabase db lint --level error`, `supabase test db`, `supabase migration new`, `supabase migration up`.

---

## Phase 1 — Guard erweitern: local erlauben, remote hart blocken

Ersetze in `.claude/hooks/guard-bash.sh` das Muster `'supabase +db +reset'` NICHT durch ein pauschales Verbot, sondern ergänze eine gezielte Remote-Sperre. Neue/geänderte Patterns:

```bash
# Remote-Push/-Anwendung im Agenten IMMER blocken:
'supabase +db +push'
'supabase +migration +up[^|;&]*--linked'
'supabase +db +reset[^|;&]*(--linked|--db-url)'
'supabase +db +push[^|;&]*--linked'
# gefährliche generische Muster bleiben (force-push, rm -rf, DROP/TRUNCATE ...)
```
Wichtig: `supabase db reset` OHNE `--linked`/`--db-url` (= local) NICHT mehr blocken — genau das ist der sichere Pfad. Entferne dazu das alte pauschale `'supabase +db +reset'`-Pattern.

In `.claude/hooks/guard-paths.sh`: Die Schema-Zonen-Sperre (`supabase/migrations/`, `supabase/schema.sql`) bleibt, aber das Opt-in wird verfeinert. Bisher: `ALLOW_MIGRATIONS=1`. Neu: zusätzlich prüfen, dass ein lokaler Stack läuft, sonst Warnung:
```bash
if echo "$FILE" | grep -Eq '(supabase/migrations/|supabase/schema\.sql)'; then
  if [ "$ALLOW_MIGRATIONS" != "1" ]; then
    echo "guard-paths: $FILE ist Schema-Zone. Nur in Migrations-Sessions (ALLOW_MIGRATIONS=1 via claude-migrate.sh)." >&2
    exit 2
  fi
fi
```

**Commit:** `feat(infra): migration guards (local erlaubt, remote gesperrt)`

---

## Phase 2 — Migrations-Test-Harness

`scripts/migrate-verify.sh` (ausführbar) — der Beweis, dass eine Migration sicher ist. Läuft ausschließlich lokal:
```bash
#!/bin/bash
# Beweist eine lokale Migration: reset -> lint -> pgTAP/RLS-Tests -> Drift-Check -> App-Tests
set -euo pipefail

echo "== 1/6 Local stack sicherstellen =="
supabase status >/dev/null 2>&1 || supabase start

echo "== 2/6 db reset (LOCAL) — wendet alle Migrations frisch an =="
supabase db reset   # KEIN --linked/--db-url => lokal, wegwerfbar

echo "== 3/6 Idempotenz — zweiter reset muss identisch durchlaufen =="
supabase db reset

echo "== 4/6 Schema-Lint (Fehlerlevel) =="
supabase db lint --level error

echo "== 5/6 DB-Tests (pgTAP: RLS + FernUSG-Policies) =="
supabase test db

echo "== 6/6 Drift-Check — Migrations vs. deklarierter Zustand müssen deckungsgleich sein =="
DIFF=$(supabase db diff 2>/dev/null || true)
if [ -n "$DIFF" ]; then
  echo "DRIFT: db diff ist nicht leer — Migrations und Schema divergieren:" >&2
  echo "$DIFF" >&2
  exit 1
fi

echo "== App-Testsuite gegen migriertes Schema =="
npm run -s typecheck
npm run -s test

echo "OK: Migration lokal verifiziert. Remote-Push ist NICHT Teil dieses Laufs."
```

**Commit:** `feat(infra): migrate-verify harness (local proof)`

---

## Phase 3 — RLS-/FernUSG-Policy-Tests als pgTAP

Lege pgTAP-Tests unter `supabase/tests/` an (via `supabase test new <name>`). Nutze die Basejump Test-Helpers (`supabase/test-helpers`), falls nicht vorhanden: als SQL-Extension-Setup in einer Test-Fixture einbinden und in Retro dokumentieren.

Mindest-Testfälle (das sind die DB-seitigen Gegenstücke zu den INV-Tests aus P00):
- **RLS-MASTERY:** Als `student`- und `parent`-Rolle ist jedes direkte INSERT/UPDATE auf die Mastery-Tabelle verboten; nur `coach` (bzw. der definierte Coach-Pfad) darf schreiben. → schützt FernUSG-Coach-only-Gate auf DB-Ebene, auch wenn eine künftige Migration die Policy versehentlich lockert.
- **RLS-CROSS-STUDENT:** Ein `student` kann keine Daten eines anderen `student` lesen (DSGVO / Minderjährigenschutz).
- **RLS-PARENT-SCOPE:** Ein `parent` sieht ausschließlich die eigenen Kinder.
- **RLS-HOMEQUEST:** Home-Quest-Abschluss schreibt nur Gamification-Tabellen, nie Mastery/Lernpfad (DB-seitige Absicherung von INV-2).

Discovery zuerst: reale Tabellen-/Policy-Namen per `supabase db dump --schema public` oder Migrationen ermitteln, dann Tests gegen die echten Namen schreiben. Verletzt eine dieser Prüfungen den Ist-Zustand: Test als erwartet-fehlschlagend markieren + prominent in Retro unter „⚠️ RLS-LÜCKE", NICHT eigenmächtig Policies ändern.

**Commit:** `test(rls): pgTAP policy tests (FernUSG + DSGVO)`

---

## Phase 4 — Migrations-Wrapper

`scripts/claude-migrate.sh` (ausführbar) — autonome Migrations-Session mit erzwungenem Local-Target:
```bash
#!/bin/bash
# Autonome Migration: ./scripts/claude-migrate.sh prompts/migrations/<spec>.md
set -euo pipefail
SPEC="${1:?Usage: claude-migrate.sh <spec.md>}"
command -v docker >/dev/null && docker info >/dev/null 2>&1 || { echo "Docker-Daemon nicht erreichbar."; exit 1; }
git diff --quiet && git diff --cached --quiet || { echo "Working tree nicht sauber."; exit 1; }
BRANCH="migrate/$(basename "$SPEC" .md)-$(date +%Y%m%d-%H%M)"
git checkout -b "$BRANCH"
supabase status >/dev/null 2>&1 || supabase start
touch .claude/autonomous
export ALLOW_MIGRATIONS=1
# Sicherheitsnetz: verhindert versehentliches Linken in dieser Session
export SUPABASE_DB_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
trap 'rm -f .claude/autonomous; unset ALLOW_MIGRATIONS' EXIT
claude -p "$(cat "$SPEC")" --permission-mode acceptEdits
echo "Migration gebaut auf $BRANCH. Jetzt: ./scripts/migrate-verify.sh lokal grün? -> PR nach dev."
```
Permission-Modus mit `claude --help` gegen die installierte Version verifizieren.

**Commit:** `feat(infra): claude-migrate wrapper (local-forced)`

---

## Phase 5 — Stop-Gate für Migrations-Sessions erweitern

In `.claude/hooks/stop-gate.sh`: Wenn `ALLOW_MIGRATIONS=1` gesetzt ist, zusätzlich `scripts/migrate-verify.sh` verlangen, bevor der Agent sich für fertig erklären darf:
```bash
if [ "${ALLOW_MIGRATIONS:-0}" = "1" ]; then
  if ! bash scripts/migrate-verify.sh > /tmp/edvance-migrate.log 2>&1; then
    { echo "STOP-GATE (Migration): migrate-verify rot — NICHT fertig:"; tail -n 50 /tmp/edvance-migrate.log; } >&2
    exit 2
  fi
fi
```
(Der bestehende typecheck/test-Teil bleibt davor.)

**Commit:** `feat(infra): stop-gate erzwingt migrate-verify in migrations-sessions`

---

## Phase 6 — CI: Migration gegen Staging, dann Prod

`.github/workflows/db-migrate.yml` — der EINZIGE Ort, an dem Remote-Push passiert, ausgelöst durch Menschen-Merge:
```yaml
name: DB Migrate
on:
  push:
    branches: [dev, main]
jobs:
  verify-local:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: supabase db reset
      - run: supabase db lint --level error
      - run: supabase test db
  deploy-staging:
    needs: verify-local
    if: github.ref == 'refs/heads/dev'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase link --project-ref ${{ secrets.SUPABASE_STAGING_REF }}
      - run: supabase db push
        env: { SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_STAGING_DB_PASSWORD }} }
  deploy-prod:
    needs: verify-local
    if: github.ref == 'refs/heads/main'
    environment: production   # GitHub Environment mit Required Reviewer = manuelle Freigabe
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase link --project-ref ${{ secrets.SUPABASE_PROD_REF }}
      - run: supabase db push
        env: { SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_PROD_DB_PASSWORD }} }
```
Verifiziere `supabase/setup-cli`-Action-Name/Version per Websuche, falls der Lauf ihn nicht auflösen kann. Prod-Deploy hängt an einem GitHub Environment „production" mit Required Reviewer → niemand (kein Agent, kein Skript) rollt ungeprüft auf Prod aus.

**Commit:** `ci: db migrate (local verify -> staging -> prod mit freigabe)`

---

## Phase 7 — Doku

- CLAUDE.md ergänzen: Migrations-Workflow. Kernsätze: (1) Migrationen werden autonom nur via `claude-migrate.sh` gebaut, (2) `migrate-verify.sh` muss lokal grün sein, (3) Remote-Push NIE lokal/im Agenten — nur CI, (4) Prod braucht manuelle Freigabe im GitHub Environment.
- `docs/retros/RETRO-P00b.md`: was gebaut wurde, RLS-Testabdeckung, gefundene RLS-Lücken (falls), Docker/CLI-Versionsnotizen.
- Voraussetzungen-Doku für Rasit (was EINMALIG von Hand nötig ist): Staging-Supabase-Projekt anlegen; GitHub Secrets `SUPABASE_STAGING_REF/_DB_PASSWORD`, `SUPABASE_PROD_REF/_DB_PASSWORD` setzen; GitHub Environment „production" mit Required Reviewer konfigurieren.

**Commit:** `docs: migration autonomy`

---

## Abnahme-Checkliste (alles erfüllt, bevor du fertig meldest)

- [ ] `docker info` ok · `supabase start` ok · `supabase db reset` (local) läuft sauber
- [ ] `scripts/migrate-verify.sh` läuft komplett grün (reset ×2, lint, test db, kein Drift, typecheck, test)
- [ ] Guard-Selbsttest: (a) Bash mit `supabase db push` → blockiert; (b) Bash mit `supabase db reset --linked` → blockiert; (c) Bash mit `supabase db reset` (local) → NICHT blockiert
- [ ] pgTAP-Tests RLS-MASTERY / CROSS-STUDENT / PARENT-SCOPE / HOMEQUEST vorhanden und grün (oder Lücke in Retro dokumentiert)
- [ ] Stop-Gate erzwingt migrate-verify bei ALLOW_MIGRATIONS=1 (bewusst rote Testmigration → Fertig-Meldung wird verhindert → zurückrollen)
- [ ] CI-Workflow YAML-valide; Prod-Job hängt an Environment „production"
- [ ] RETRO-P00b + Voraussetzungen-Doku geschrieben
