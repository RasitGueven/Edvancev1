#!/usr/bin/env bash
# ============================================================================
# migrate-verify — der Beweis, dass eine Migration sicher ist, BEVOR sie live geht.
#
# Laeuft ausschliesslich gegen die LOKALE Docker-DB. Er fasst Remote/Prod nicht
# an: das Anwenden auf Prod ist ein bewusster Menschen-/CI-Schritt
# (siehe docs/runbooks/DB-MIGRATIONEN.md).
#
# Kette:
#   1. reset  — DB komplett neu aus supabase/migrations/ + seed.sql aufbauen.
#               Faengt genau die Klasse Fehler, die uns P00b+ beschert hat:
#               Migrationen, die nur "on top" eines handgebauten Zustands laufen.
#   2. lint   — statische Schema-Fehler.
#   3. test   — pgTAP, u.a. INV-1 (FernUSG-Mastery-Gate).
#   4. diff   — Drift: die Migrationen muessen den Zustand VOLLSTAENDIG beschreiben.
#               Ist der Diff nicht leer, fehlt etwas in einer Migration.
#   5. app    — typecheck + Unit-Tests gegen das neue Schema.
#
# Usage: bash scripts/db/migrate-verify.sh
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/../.."

SB="npx supabase"
step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
fail() { printf '\n\033[31mmigrate-verify FEHLGESCHLAGEN: %s\033[0m\n' "$1" >&2; exit 1; }

step "1/5  DB aus supabase/migrations/ neu aufbauen (lokal)"
$SB db reset || fail "db reset — die Migrationskette laeuft nicht sauber durch"

step "2/5  Schema-Lint"
$SB db lint --level error || fail "db lint"

step "3/5  pgTAP (INV-1 FernUSG-Mastery-Gate)"
$SB test db || fail "pgTAP"

step "4/5  Drift-Check (db diff muss leer sein)"
DIFF="$($SB db diff 2>/dev/null || true)"
if echo "$DIFF" | grep -q '"diff":""'; then
  echo "kein Drift — die Migrationen beschreiben den Zustand vollstaendig."
else
  echo "$DIFF"
  fail "Drift: der DB-Zustand steht nicht vollstaendig in den Migrationen"
fi

step "5/5  App gegen das neue Schema"
npm run -s typecheck || fail "typecheck"
npm run -s test      || fail "unit tests"

printf '\n\033[32mmigrate-verify GRUEN — die Migration ist bereit fuer den PR.\033[0m\n'
