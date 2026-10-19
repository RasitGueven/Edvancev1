#!/usr/bin/env bash
# l1-wegwerf-db.sh — Wegwerf-DB für L1 (Lenas Rückfragen vom 19.10.2026). Muster: tools/p1-wegwerf-db.sh.
#
#   L1_SOCKET=<socket-ordner> bash tools/l1-wegwerf-db.sh <fixture-ordner>
#
# Ablauf: Basis ohne die beiden L1-Migrationen + seed, Prod-Fixture laden, Rasits Profil anlegen,
# M1 → Prüfskript (M2 steht aus) → M2 → Prüfskript → M1 + M2 ein zweites Mal (ändert nichts) → Prüfskript,
# danach tools/l1-wertung.sql (lsa_fehlbild_match / lsa_is_correct / lsa_grade für jeden neuen Fehlerwert).
#
# Die Fixture ist ein read-only Abzug der Inhaltstabellen aus Prod (dbread, \copy … csv header, ohne generierte
# Spalten), je Tabelle <name>.csv. Sie wird nicht eingecheckt.
# Eigener Cluster: L1_PORT (Standard 55497) und L1_SOCKET; PGDATABASE & Co. werden geleert, jeder psql-Aufruf nennt
# die DB ausdrücklich; nie edvance_shadow, nie Produktion.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST="${L1_SOCKET:?L1_SOCKET (Socket-Verzeichnis des eigenen Clusters) fehlt}" PGPORT="${L1_PORT:-55497}" PGUSER=postgres
export PGOPTIONS='-c search_path=public,extensions -c jit=off'
FIX="$(cd "${1:?Fixture-Ordner fehlt}" && pwd)"
M1=20261019100100_l1_lena_fehlbilder.sql
M2=20261019100200_l1_lena_rueckfragen_freigeben.sql
TABS='skills skill_kante themen skill_thema thema_einstieg skill_voraussetzung skill_clusters process_competencies microskills
      tasks task_solutions task_figures task_pruef_ausschluss task_pruefung_ausgang task_pruefungen task_reviews
      pruef_einstellungen task_admin_protokoll fehlbild_familien fehlbild_labels'
DB=l1_test

spiele() {
  if ! out=$(psql -q -X "postgresql:///$2" -v ON_ERROR_STOP=1 -f "$1" 2>&1); then
    echo "FEHLER in $1"; echo "$out" | grep -E 'ERROR|FEHLER|psql:|CONTEXT|DETAIL|HINT' | head -12; exit 1
  fi
  grep -E 'NOTICE' <<<"$out" | sed "s#^#  [$(basename "$1")] #" || true
}
stand() {
  psql -X -tA "postgresql:///$DB" -c "select md5(string_agg(x, '|' order by x)) from (
      select t.id || t.status || coalesce(t.reviewed_by::text, '') || coalesce(t.question, '') || coalesce(s.acceptance::text, '')
             || coalesce(s.solution, '') || coalesce(s.hints::text, '') || coalesce(a.ausgang::text, '') as x
        from public.tasks t left join public.task_solutions s on s.task_id = t.id
        left join public.task_pruefung_ausgang a on a.task_id = t.id
      union all select slug || coalesce(klartext, '') || coalesce(familie, '') from public.fehlbild_labels
      union all select schluessel || coalesce(elterntext, '') from public.fehlbild_familien
      union all select id::text || coalesce(antwort, '') || coalesce(beantwortet_von::text, '') from public.task_pruefungen
      union all select count(*)::text from public.task_admin_protokoll) z"
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
  echo "insert into auth.users (id, email) values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'l1-rasit@edvance.invalid') on conflict do nothing;"
  echo "insert into public.profiles (id, email, role, full_name) values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'l1-rasit@edvance.invalid', 'admin', 'Rasit Güven') on conflict do nothing;"
} > "$lade"
spiele "$lade" "$DB" >/dev/null
echo "Fixture: $(psql -X -tA "postgresql:///$DB" -c 'select count(*) from public.tasks') Aufgaben, Stand $(stand)"

echo "M1:"; spiele "supabase/migrations/$M1" "$DB"
spiele supabase/checks/l1_rueckfragen.PRUEFUNG.sql "$DB"
echo "M2:"; spiele "supabase/migrations/$M2" "$DB"
spiele supabase/checks/l1_rueckfragen.PRUEFUNG.sql "$DB"
vorher=$(stand)
echo "Zweiter Lauf:"
spiele "supabase/migrations/$M1" "$DB"
spiele "supabase/migrations/$M2" "$DB"
nachher=$(stand)
[ "$vorher" = "$nachher" ] && echo "  zweiter Lauf ändert nichts ($nachher)" || { echo "  ZWEITER LAUF ÄNDERT ETWAS"; exit 1; }
spiele supabase/checks/l1_rueckfragen.PRUEFUNG.sql "$DB"
echo "Wertung:"; psql -X -q "postgresql:///$DB" -v ON_ERROR_STOP=1 -f tools/l1-wertung.sql
