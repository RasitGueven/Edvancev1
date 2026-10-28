#!/usr/bin/env bash
# reihe1a-wegwerf-db.sh — Wegwerf-DB und pgTAP-Lauf für Bauauftrag A der Sessionreihe 1.
#
#   R1A_SOCKET=<socket-ordner> R1A_PGTAP=<pgtap--x.y.z.sql> bash tools/reihe1a-wegwerf-db.sh [aufbau|tests [muster]]
#
# aufbau: leere DB r1a_test, supabase/test-grundlage.sql, alle Migrationen in Reihenfolge, supabase/seed.sql,
#         pgTAP ins Schema extensions — wie der CI-Job (schema.yml).
# tests:  jede supabase/tests/*.test.sql (oder nur die, deren Name auf <muster> passt) wie in der CI: grün, wenn
#         psql ohne Fehler endet und kein "not ok" / "# Looks like" ausgibt. Eine Kopie je Test, in der die Zeile
#         `create extension … pgtap` ersetzt ist; ../migrations zeigt auf supabase/migrations (für \ir).
# Eigener Cluster: R1A_PORT (Standard 55461) und R1A_SOCKET; PGDATABASE & Co. werden geleert, jeder Aufruf nennt die
# DB ausdrücklich; nie edvance_shadow, nie Produktion.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${R1A_SOCKET:?R1A_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${R1A_PORT:-55461}" PGUSER=postgres
DB=r1a_test

aufbau() {
  local pgtap="${R1A_PGTAP:?R1A_PGTAP (pgtap--x.y.z.sql) fehlt}"
  dropdb --if-exists "$DB" 2>/dev/null; createdb "$DB"
  psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
  for f in $(ls supabase/migrations/*.sql | sort); do
    if ! out=$(psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f "$f" 2>&1); then
      echo "FEHLER in $f"; echo "$out" | grep -E 'ERROR|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
    fi
  done
  psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/seed.sql >/dev/null
  psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -c "create schema if not exists extensions" \
    -c "set search_path = extensions, public" -f "$pgtap" >/dev/null
  echo "aufgebaut: $(ls supabase/migrations/*.sql | wc -l) Migrationen"
}

tests() {
  local muster="${1:-}" tmp gruen=0 rot=0 f b out
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
  mkdir -p "$tmp/supabase/tests"; ln -s "$PWD/supabase/migrations" "$tmp/supabase/migrations"; ln -s "$PWD/tools" "$tmp/tools"
  cp -r supabase/tests/. "$tmp/supabase/tests/"
  for f in $(ls supabase/tests/*.test.sql | sort); do
    b=$(basename "$f" .test.sql)
    [[ -n "$muster" && "$b" != *$muster* ]] && continue
    sed -i 's/^ *create extension if not exists pgtap.*$/set search_path = public, extensions;/I' "$tmp/supabase/tests/$b.test.sql"
    if out=$(cd "$tmp/supabase/tests" && PGOPTIONS='-c search_path=public,extensions -c jit=off' \
               psql -X -q -t -A -v ON_ERROR_STOP=1 "postgresql:///$DB" -f "$b.test.sql" 2>&1) \
       && ! grep -qE '^not ok|^# Looks like' <<<"$out"; then
      gruen=$((gruen + 1)); echo "  ok   $b ($(grep -cE '^ok ' <<<"$out"))"
    else
      rot=$((rot + 1)); echo "  ROT  $b"; grep -E '^not ok|^#|ERROR' <<<"$out" | head -8 | sed 's/^/       /' || true
    fi
  done
  echo "grün $gruen, rot $rot"
}

case "${1:-aufbau}" in
  aufbau) aufbau ;;
  tests) tests "${2:-}" ;;
  *) echo "aufbau | tests [muster]"; exit 2 ;;
esac
