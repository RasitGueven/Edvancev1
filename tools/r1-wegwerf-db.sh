#!/usr/bin/env bash
# r1-wegwerf-db.sh — Wegwerf-DB für R1 vom 29.10.2026 (Lenas Rückfragen). Muster: tools/l1b-wegwerf-db.sh.
#
#   R1_SOCKET=<socket-ordner> bash tools/r1-wegwerf-db.sh <fixture-ordner>
#
# Ablauf: Basis ohne die R1-Migration + seed, Prod-Fixture laden, Rasits Profil anlegen, Migration → Prüfskript
# (Freigabe steht aus) → tools/r1-freigeben.sql → Prüfskript → Migration ein zweites Mal (ändert nichts) →
# Prüfskript → Rollback (Inhalte wie vorher).
#
# Die Fixture ist ein read-only Abzug der Inhaltstabellen aus Prod (dbread, \copy … csv header, ohne generierte
# Spalten), je Tabelle <name>.csv. Sie wird nicht eingecheckt.
# Eigener Cluster: R1_PORT (Standard 55521) und R1_SOCKET; PGDATABASE & Co. werden geleert, jeder psql-Aufruf nennt
# die DB ausdrücklich; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${R1_SOCKET:?R1_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${R1_PORT:-55521}" PGUSER=postgres
export PGOPTIONS='-c search_path=public,extensions -c jit=off'
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"
M=20261029091200_r1_lena_rueckfragen.sql
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung skill_clusters process_competencies microskills
      tasks task_solutions task_figures task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews
      pruef_einstellungen task_admin_protokoll fehlbild_familien fehlbild_labels pruef_soll'
DB=r1_test

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'NOTICE' <<<"$out" | sed "s#^#  [$(basename "$1")] #" || true
}
# Inhalt der sechs Aufgaben (ohne Status, Zeitstempel, pruef_version)
inhalt() {
  psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(x, '|' order by x)) from (
      select t.id || coalesce(t.question, '') || coalesce(t.question_payload::text, '') || t.parts::text
             || s.correct_answers::text || coalesce(s.acceptance::text, '') || s.typical_errors::text || t.einsatz::text as x
        from public.tasks t join public.task_solutions s on s.task_id = t.id
       where t.id in ('8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24', 'a61e8be9-b55f-4c43-9971-7b74e3d55a33',
                      'ffc76634-86ca-4c53-b816-d18d7f868443', '1bbce78e-f996-4c03-a78a-09b47f5c7445',
                      '158c874c-248c-40ed-b8b5-af3eb627517a', '6274f6a5-65e5-40f4-be09-36fa8931c424')) z"
}
stand() {
  psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(x, '|' order by x)) from (
      select t.id || t.status || coalesce(t.question, '') || coalesce(s.acceptance::text, '') || s.typical_errors::text
             || s.correct_answers::text as x
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
      union all select id::text || coalesce(antwort, '') || coalesce(beantwortet_von::text, '') from public.task_pruefungen) z"
}

dropdb --if-exists "$DB" 2>/dev/null; createdb "$DB"
psql -q -X "postgresql:///$DB" -v ON_ERROR_STOP=1 -f supabase/test-grundlage.sql >/dev/null
for f in $(ls supabase/migrations/*.sql | sort); do
  [ "$(basename "$f")" = "$M" ] && continue
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
  echo "insert into auth.users (id, email) values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'r1-rasit@edvance.invalid') on conflict do nothing;"
  echo "insert into public.profiles (id, email, role, full_name) values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'r1-rasit@edvance.invalid', 'admin', 'Rasit Güven') on conflict do nothing;"
} > "$lade"
spiele "$lade" "$DB" >/dev/null
vor=$(inhalt)
echo "Fixture: $(psql -X -tA "postgresql:///$DB" -c "select count(*) from public.tasks where status = 'rueckfrage'") Rückfragen, Inhalt $vor"

echo "Migration:"; spiele "supabase/migrations/$M" "$DB"
spiele supabase/checks/r1_rueckfragen.PRUEFUNG.sql "$DB"
echo "Freigabe:"; psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/r1-freigeben.sql
spiele supabase/checks/r1_rueckfragen.PRUEFUNG.sql "$DB"
vorher=$(stand)
echo "Zweiter Lauf:"; spiele "supabase/migrations/$M" "$DB"
nachher=$(stand)
[ "$vorher" = "$nachher" ] && echo "  zweiter Lauf ändert nichts ($nachher)" || { echo "  ZWEITER LAUF ÄNDERT ETWAS"; exit 1; }
spiele supabase/checks/r1_rueckfragen.PRUEFUNG.sql "$DB"
echo "Rollback:"; spiele "supabase/rollback/$M" "$DB"
[ "$(inhalt)" = "$vor" ] && echo "  Inhalt wie vor der Migration" || { echo "  ROLLBACK WEICHT AB"; exit 1; }
