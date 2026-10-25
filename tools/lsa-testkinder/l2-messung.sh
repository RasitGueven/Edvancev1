#!/usr/bin/env bash
# l2-messung.sh — Laufzeit „Weiter“ (tools/lsa-weiter-messung.sql, wie LSA-D) in den DBs, die simulation.sh gebaut hat.
#
#   bash tools/lsa-testkinder/simulation.sh && bash tools/lsa-testkinder/l2-messung.sh
#
# Je Stand (lsasim_vorher, lsasim_nachher) und Fall eine Transaktion, die zurückgerollt wird. Seed 0.42.
#   echt   = l2-fixture.sql (der freigegebene Prod-Pool), Kind ohne Testkonto (nur 'ready')
#   test   = neuaufbau-fixture.sql (drei Aufgaben je Skill) und die Entwürfe aus den Migrationen, Testkonto
# richtig 0.1 (schwach) und 0.9 (stark). Nur lokal, nie gegen Prod.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
case "${PGHOST:-}" in *supabase*) echo "Nur gegen ein lokales Postgres."; exit 1 ;; esac
unset DATABASE_URL
T=$(pwd)/tools

for db in lsasim_vorher lsasim_nachher; do
  for fall in "echt l2-fixture.sql false" "test neuaufbau-fixture.sql true"; do
    set -- $fall
    for richtig in 0.1 0.9; do
      echo "══ $db · $1 · richtig $richtig"
      { echo 'begin;'; echo '\o /dev/null'; echo "\\i $T/lsa-testkinder/$2"; echo "select setseed(0.42);"; echo '\o'
        echo "\\i $T/lsa-weiter-messung.sql"; echo 'rollback;'; } |
        psql -X -q -d "$db" -v ON_ERROR_STOP=1 -v pool="$3" -v richtig="$richtig" -f - 2>&1 |
        grep -A3 -E '^ *abgaben|ERROR' | sed -n '1,4p'
    done
  done
done
