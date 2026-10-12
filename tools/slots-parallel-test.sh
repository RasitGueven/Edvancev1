#!/usr/bin/env bash
# slots-parallel-test.sh — Bauauftrag Slots, SL1 Test 6: Kapazität beim Speichern.
#
#   bash tools/slots-parallel-test.sh
#
# Baut eine Wegwerf-DB (tools/slots-wegwerf-db.sh), legt einen Slot mit genau einem freien Platz an
# (Raum 1 offen, Raum 2 fällt aus, vier Kinder gebucht) und bucht dann in zwei parallelen psql-Sitzungen
# zwei verschiedene Kinder auf diesen letzten Platz. Sitzung A hält ihre Transaktion zwei Sekunden offen.
# Erwartet: A bucht, B wartet auf die Sperre (Entscheidung 16) und bekommt danach SL001.
# Nur lokal (Port 55450); edvance_shadow und Produktion werden nie angefasst.
set -euo pipefail
unset PGDATABASE DATABASE_URL PGSERVICE
export PGHOST=/tmp/claude-1000 PGPORT=55450 PGUSER=postgres
DB=sl1_parallel
bash tools/slots-wegwerf-db.sh "$DB" >/dev/null
URL="postgresql:///$DB"
ADMIN=eeeeeeee-5100-4000-8000-000000000001

psql -X -q -v ON_ERROR_STOP=1 "$URL" <<SQL >/dev/null
insert into auth.users (id, email, instance_id, aud, role) values
  ('$ADMIN', 'sl1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  ('eeeeeeee-5100-4000-8000-000000000002', 'sl1-coach-a@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  ('eeeeeeee-5100-4000-8000-000000000003', 'sl1-coach-b@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  ('$ADMIN', 'sl1-admin@test.local', 'admin', 'ZZ Admin'),
  ('eeeeeeee-5100-4000-8000-000000000002', 'sl1-coach-a@test.local', 'coach', 'Coach Anna'),
  ('eeeeeeee-5100-4000-8000-000000000003', 'sl1-coach-b@test.local', 'coach', 'Coach Ben');
insert into raeume (name, aktiv_ab) values ('Raum 1', '2026-01-01'), ('Raum 2', '2026-01-01');
insert into stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab)
select c, 4, (select id from slot_zeiten where beginn = '16:00'), (select id from raeume where name = r), '2026-01-01'
  from (values ('eeeeeeee-5100-4000-8000-000000000002'::uuid, 'Raum 1'), ('eeeeeeee-5100-4000-8000-000000000003'::uuid, 'Raum 2')) x(c, r);

select set_config('request.jwt.claim.sub', '$ADMIN', false), set_config('request.jwt.claim.role', 'authenticated', false);
-- Sechs Kinder mit Vertrag; Do 16.03.2028, 16 Uhr: Raum 2 fällt aus (Kapazität 5), vier Kinder gebucht.
do \$\$
declare v_lead uuid; v_st uuid; i int;
begin
  for i in 1 .. 6 loop
    insert into leads (full_name, first_name, status, class_level) values ('Par' || i || ' Kind', 'Par' || i, 'vertrag', 8)
    returning id into v_lead;
    insert into students (class_level) values (8) returning id into v_st;
    insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                           vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, kind_vorname)
    select v_lead, 'abgeschlossen', 'aktiv', now(), '2027-08-01', 'vor_ort', v_st, '2027-09-01', '2028-08-31', '2027-09-14',
           t.id, 12, 38, 'Mathematik', 'Par' || i
      from tiers t where t.name = 'Basic';
  end loop;
end \$\$;
select termin_coach_setzen('2028-03-16', (select id from slot_zeiten where beginn = '16:00'), (select id from raeume where name = 'Raum 2'),
                           null, '2028-03-13 09:12 Europe/Berlin');
select zusatztermin_buchen(v.student_id, '2028-03-16', (select id from slot_zeiten where beginn = '16:00'), '2028-03-13 09:12 Europe/Berlin')
  from vertraege v where v.kind_vorname in ('Par1', 'Par2', 'Par3', 'Par4');
SQL

kind() { psql -X -tA "$URL" -c "select student_id from vertraege where kind_vorname = '$1'"; }
K5=$(kind Par5); K6=$(kind Par6)
ZEIT=$(psql -X -tA "$URL" -c "select id from slot_zeiten where beginn = '16:00'")
echo "Ausgangslage: Kapazität $(psql -X -tA "$URL" -c "select slot_kapazitaet('2028-03-16', '$ZEIT')"), belegt $(psql -X -tA "$URL" -c "select slot_belegt('2028-03-16', '$ZEIT')")"

buchen() {  # $1 = Name, $2 = Kind, $3 = Wartezeit in der offenen Transaktion
  psql -X -tA -v ON_ERROR_STOP=1 "$URL" 2>&1 <<SQL | sed "s/^/  [$1] /"
\set VERBOSITY verbose
\set SHOW_CONTEXT never
begin;
select set_config('request.jwt.claim.sub', '$ADMIN', true), set_config('request.jwt.claim.role', 'authenticated', true) \g /dev/null
select 'Start ' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
select 'gebucht: ' || (zusatztermin_buchen('$2', '2028-03-16', '$ZEIT', '2028-03-13 09:12 Europe/Berlin') ->> 'termin_id') ||
       ' um ' || to_char(clock_timestamp(), 'HH24:MI:SS.MS');
select pg_sleep($3) \g /dev/null
commit;
SQL
}

buchen A "$K5" 2 > /tmp/claude-1000/sl1-parallel-a.txt &
sleep 0.5
buchen B "$K6" 0 > /tmp/claude-1000/sl1-parallel-b.txt || true
echo "  [B] Antwort $(date +%H:%M:%S.%3N) (wartete auf die Sperre von A)" >> /tmp/claude-1000/sl1-parallel-b.txt
wait
cat /tmp/claude-1000/sl1-parallel-a.txt /tmp/claude-1000/sl1-parallel-b.txt | grep -vE '^\s*\[.\] (BEGIN|COMMIT|ROLLBACK|LOCATION:.*)?$'
echo "Ende: belegt $(psql -X -tA "$URL" -c "select slot_belegt('2028-03-16', '$ZEIT')") von $(psql -X -tA "$URL" -c "select slot_kapazitaet('2028-03-16', '$ZEIT')")"
ok_a=$(grep -c 'gebucht:' /tmp/claude-1000/sl1-parallel-a.txt || true)
sl001_b=$(grep -c 'SL001\|Slot voll' /tmp/claude-1000/sl1-parallel-b.txt || true)
rm -f /tmp/claude-1000/sl1-parallel-a.txt /tmp/claude-1000/sl1-parallel-b.txt
if [ "$ok_a" -ge 1 ] && [ "$sl001_b" -ge 1 ]; then echo "ERGEBNIS: ok — A bucht den letzten Platz, B bekommt SL001"; else echo "ERGEBNIS: FEHLER"; exit 1; fi
