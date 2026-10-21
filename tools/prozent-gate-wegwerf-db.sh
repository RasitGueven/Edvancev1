#!/usr/bin/env bash
# prozent-gate-wegwerf-db.sh — Wegwerf-DB für das Prozent-Gate (Teil 2 nach #294). Muster: tools/lena-rf-wegwerf-db.sh.
#
#   PZ_SOCKET=<socket-ordner> bash tools/prozent-gate-wegwerf-db.sh <fixture-ordner>
#
# Ablauf: Basis ohne die zwei Migrationen + seed, Prod-Fixture laden, alte Wertung festhalten
# (tools/lena-rf-abnahme.sql) → M1 → Prüfskript → M2 → Prüfskript → M1 + M2 ein zweites Mal (ändert nichts)
# → Prüfskript → Abnahme: alle Unterschiede alte/neue Wertung, dazu die Gate-Befunde vorher/nachher.
#
# Die Fixture ist ein read-only Abzug der Inhaltstabellen aus Prod (dbread, \copy … csv header, ohne generierte
# Spalten), je Tabelle <name>.csv. Sie wird nicht eingecheckt.
# Eigener Cluster: PZ_PORT (Standard 55499) und PZ_SOCKET; PGDATABASE & Co. werden geleert, jeder psql-Aufruf nennt
# die DB ausdrücklich; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${PZ_SOCKET:?PZ_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${PZ_PORT:-55499}" PGUSER=postgres
export PGOPTIONS='-c search_path=public,extensions -c jit=off'
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"
M1=20261021081417_prozent_gate.sql
M2=20261021081529_prozent_gate_daten.sql
CHECK=supabase/checks/prozent_gate.PRUEFUNG.sql
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung skill_clusters process_competencies microskills
      tasks task_solutions task_figures task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews
      pruef_einstellungen task_admin_protokoll fehlbild_familien fehlbild_labels'
DB=prozent_gate_test

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'NOTICE' <<<"$out" | sed -E "s#^psql:[^ ]+ NOTICE:  #  [$(basename "$1")] #" || true
}
stand() {
  psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(x, '|' order by x)) from (
      select t.id || t.status || coalesce(t.reviewed_by::text, '') || coalesce(s.acceptance::text, '')
             || coalesce(s.correct_answers::text, '') || coalesce(a.ausgang::text, '') as x
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
        left join public.task_pruefung_ausgang a on a.task_id = t.id
      union all select count(*)::text from public.task_admin_protokoll
      union all select md5(pg_get_functiondef('public.freigabe_gate_fehler'::regproc)
                           || pg_get_functiondef('public.prozent_gate_fehler'::regproc))) z"
}
befunde() {
  psql -X -tA "postgresql:///$DB" -c "select count(*) || ' Aufgabe(n), davon ' || count(*) filter (where t.status = 'ready') || ' ready'
      from public.tasks t join public.task_solutions s on s.task_id = t.id
     where public.prozent_gate_fehler(t.unit, s.acceptance, s.correct_answers) is not null"
}

dropdb --if-exists "$DB" 2>/dev/null; createdb "$DB"
psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
for f in $(ls supabase/migrations/*.sql | sort); do
  case "$(basename "$f")" in "$M1"|"$M2") continue ;; esac
  spiele "$f" "$DB" >/dev/null
done
spiele supabase/seed.sql "$DB" >/dev/null
lade=$(mktemp); trap 'rm -f "$lade"' EXIT
{
  echo "set session_replication_role = replica;"
  echo "truncate $(echo $TABS | sed 's/\([a-z_]*\)/public.\1/g; s/ /, /g') cascade;"
  for t in $TABS; do
    echo "\\copy public.$t ($(head -1 "$FIX/$t.csv")) from '$FIX/$t.csv' csv header"
  done
  echo "set session_replication_role = origin;"
} > "$lade"
spiele "$lade" "$DB" >/dev/null
echo "Fixture: $(psql -X -tA "postgresql:///$DB" -c 'select count(*) from public.tasks') Aufgaben"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -v phase=vorher -f tools/lena-rf-abnahme.sql

echo "M1:"; spiele "supabase/migrations/$M1" "$DB"; echo "  Gate-Befunde nach M1: $(befunde)"; spiele "$CHECK" "$DB"
echo "M2:"; spiele "supabase/migrations/$M2" "$DB"; echo "  Gate-Befunde nach M2: $(befunde)"; spiele "$CHECK" "$DB"
vorher=$(stand)
echo "Zweiter Lauf:"
for m in "$M1" "$M2"; do spiele "supabase/migrations/$m" "$DB"; done
nachher=$(stand)
[ "$vorher" = "$nachher" ] && echo "  zweiter Lauf ändert nichts ($nachher)" || { echo "  ZWEITER LAUF ÄNDERT ETWAS"; exit 1; }
spiele "$CHECK" "$DB"
echo "Abnahme:"
psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -v phase=nachher -v vergleich=1 -f tools/lena-rf-abnahme.sql
