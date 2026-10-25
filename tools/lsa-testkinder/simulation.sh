#!/usr/bin/env bash
# simulation.sh — alle Testkinder im CI-Neuaufbau, vorher/nachher einer Migration (LSA-V2, LSA-L2).
#
#   bash tools/lsa-testkinder/simulation.sh [<migration.sql> [<variante.sql> …]]
#   POOLS="neuaufbau prod" (Standard): neuaufbau = neuaufbau-fixture.sql (drei Aufgaben je Skill),
#                                      prod      = l2-fixture.sql (der freigegebene Prod-Pool, LSA-L2)
#
# Nur lokal: baut eine Grundlage-DB im lokalen Postgres (wie tools/neuaufbau-test.sh: Grundlage, alle Migrationen
# außer der genannten, seed.sql) und daraus je Stand eine Kopie: „vorher“ ohne die Migration, „nachher“ mit ihr,
# dazu je Variante eine Kopie, die statt der Migration die Variante einspielt (etwa die Migration mit einer anderen
# Konstante). Je Stand und Pool laufen Fixture, erzeugen.sql und die Auswertung (auswertung.sql, l2-auswertung.sql)
# in EINER Transaktion, die am Ende zurückgerollt wird — so teilen sich die Pools eine DB. Nie gegen Prod.
#
# Hinweis: Seit LSA-L2 liegt die LSA-V2-Migration in der Grundlage; auswertung.sql braucht ihre lsa_ausblick_knoten.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
MIG="${1:-$(ls supabase/migrations/*_lsa_l2_wiederholung.sql | tail -1)}"
shift || true
VARIANTEN=("$@")
POOLS="${POOLS:-neuaufbau prod}"
# Nur das lokale Postgres (wie neuaufbau-test.sh); DATABASE_URL (Prod) wird nie benutzt.
case "${PGHOST:-}" in *supabase*) echo "Nur gegen ein lokales Postgres."; exit 1 ;; esac
unset DATABASE_URL
T=$(pwd)/tools/lsa-testkinder

GRUND=lsasim_grundlage
dropdb --if-exists "$GRUND" >/dev/null 2>&1; createdb "$GRUND"
psql -q -d "$GRUND" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
for f in $(ls supabase/migrations/*.sql | sort); do
  [[ "$f" == "$MIG" ]] && continue
  psql -q -d "$GRUND" -v ON_ERROR_STOP=1 -f "$f" >/dev/null 2>&1 || { echo "Migration scheitert: $f"; exit 1; }
done
psql -q -d "$GRUND" -v ON_ERROR_STOP=1 -f supabase/seed.sql >/dev/null 2>&1

kopie() {  # $1 = DB, $2 = Migration oder leer
  dropdb --if-exists "$1" >/dev/null 2>&1; createdb -T "$GRUND" "$1"
  [[ -z "$2" ]] || psql -q -d "$1" -v ON_ERROR_STOP=1 -f "$2" >/dev/null || { echo "Migration scheitert: $2"; exit 1; }
}

lauf() {  # $1 = DB, $2 = Titel
  local pool fixture skript
  for pool in $POOLS; do
    case "$pool" in neuaufbau) fixture=$T/neuaufbau-fixture.sql ;; prod) fixture=$T/l2-fixture.sql ;;
                    *) echo "Unbekannter Pool: $pool"; exit 1 ;; esac
    echo; echo "══ $2 · Pool $pool"
    skript=$(mktemp)
    # Feste Sitzungs-ids (statt gen_random_uuid): Die Auswahl mischt gleichrangige Aufgaben über
    # md5(Sitzung || Aufgabe). So bekommt jedes Kind in jedem Stand dieselbe Sitzung, und vorher/nachher vergleicht
    # nur die Änderung, nicht den Zufall. Zurückgerollt wie alles andere.
    { echo 'begin;'; echo 'create sequence zz_lsasim_sitzung;'
      echo "alter table lsa_sessions alter column id set default md5('lsasim-' || nextval('zz_lsasim_sitzung'))::uuid;"
      echo '\o /dev/null'; echo "\\i $fixture"; echo "\\i $T/erzeugen.sql"; echo '\o'
      echo "\\i $T/auswertung.sql"; echo "\\i $T/l2-auswertung.sql"; echo 'rollback;'; } > "$skript"
    psql -X -q -d "$1" -v ON_ERROR_STOP=1 -f "$skript" 2>&1 | grep -vE 'NOTICE|HINWEIS|^DETAIL|^CONTEXT' || true
    rm -f "$skript"
  done
}

kopie lsasim_vorher ""; kopie lsasim_nachher "$MIG"
lauf lsasim_vorher "vorher (ohne $(basename "$MIG"))"
lauf lsasim_nachher "nachher (mit $(basename "$MIG"))"
for i in "${!VARIANTEN[@]}"; do
  kopie "lsasim_variante$i" "${VARIANTEN[$i]}"
  lauf "lsasim_variante$i" "Variante $(basename "${VARIANTEN[$i]}")"
done
