#!/usr/bin/env bash
# sf1-wegwerf-db.sh — Wegwerf-DB für SF-1 S2 (Lehrplan je Schulform, Pakete ohne eigenen Plan).
#
#   bash tools/sf1-wegwerf-db.sh <fixture-ordner>
#
# Die Fixture ist ein read-only Abzug aus Prod (dbread, \copy … csv header, ohne generierte Spalten), je Tabelle
# <name>.csv: schulen schul_themenplan schul_klassenarbeiten themen skills skill_kante skill_thema thema_einstieg.
# Sie wird nicht eingecheckt.
# Ablauf: alle Migrationen ohne S2 + seed, Fixture, Stand „vorher“ (Pakete und Paket-Skills 2026/27 und 2027/28),
# dann S2, Stand „nachher“, dann tools/sf1-pruefung.sql (Regression Gymnasien mit Plan, Prüfabfrage, Rollback).
# Eigener Cluster: SF1_PORT (Standard 55471), SF1_SOCKET; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${SF1_SOCKET:?SF1_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${SF1_PORT:-55471}" PGUSER=postgres
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"
S2='20261113153241_sf1_klp_themenplan.sql 20261113153302_sf1_pakete_klp.sql'
TABS='schulen schul_themenplan schul_klassenarbeiten themen skills skill_kante skill_thema thema_einstieg'
DB=sf1_s2

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
}

dropdb --if-exists "$DB" 2>/dev/null; createdb "$DB"
psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
for f in $(ls supabase/migrations/*.sql | sort); do
  case " $S2 " in *" $(basename "$f") "*) continue ;; esac
  spiele "$f" "$DB"
done
spiele supabase/seed.sql "$DB"
schema() { pg_dump -s -n public "postgresql:///$DB" | grep -vE '^--|^$|restrict ' | sort; }
A=$(mktemp); B=$(mktemp)
schema > "$A"

lade=$(mktemp); trap 'rm -f "$lade" "$A" "$B"' EXIT
{
  echo "set session_replication_role = replica;"
  echo "truncate $(echo $TABS | sed 's/\([a-z_]*\)/public.\1/g; s/ /, /g') cascade;"
  for t in $TABS; do echo "\\copy public.$t ($(head -1 "$FIX/$t.csv")) from '$FIX/$t.csv' csv header"; done
} > "$lade"
spiele "$lade" "$DB"

psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 <<'SQL'
create schema sf1_vergleich;
create table sf1_vergleich.vorher_pakete as
  select sj, p.* from unnest(array['2026/27', '2027/28']) sj cross join lateral public.lsa_pakete_roh(sj) p;
create table sf1_vergleich.vorher_skills as
  select sj, s.* from unnest(array['2026/27', '2027/28']) sj cross join lateral public.lsa_paket_skills_roh(sj) s;
SQL
for m in $S2; do spiele "supabase/migrations/$m" "$DB"; done
psql -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/sf1-pruefung.sql

# Rollback: beide zurück (umgekehrte Reihenfolge); Schema public = Stand vor S2 (Vergleich liegt in sf1_vergleich).
spiele supabase/rollback/20261113153302_sf1_pakete_klp.sql "$DB"
spiele supabase/rollback/20261113153241_sf1_klp_themenplan.sql "$DB"
schema > "$B"
if diff -q "$A" "$B" >/dev/null; then echo '== Rollback: Schema = Stand vor S2'; else echo 'FEHLER: Rollback weicht ab'; diff "$A" "$B" | head -20; exit 1; fi
