#!/usr/bin/env bash
# lsa-v-abzug.sh — Daten für die Simulation LSA-V (supabase/tests/lsa_v_simulation.test.sql) aus Prod.
#
#   bash tools/lsa-v-abzug.sh <ausgabe.sql>
#
# Liest nur über dbread. Inhalt, keine Namen, keine IDs von Personen:
#   zz_v_plan     FWG-Plan Mathematik Klasse 9 und 10 (Position, thema_key, uv_titel, halbjahr)
#   zz_v_bestand  je Aufgabe im Testpool (lsa_im_pool(id, true)): Skill, Sondierrang, MC ja/nein und ob sie
#                 auch im Pool echter Kinder liegt (lsa_im_pool(id, false)). Kein Aufgabentext.
#   zz_v_profil   Zustand je Skill aus lsa_skill_urteil der Sitzung 6220b7e8 (nur Schlüssel und Zustand)
#   zz_v_themen   Themen des Leads dieser Sitzung (thema_key, status), Fach Mathematik
# Den Graphen (skills, skill_kante, skill_thema, thema_einstieg, themen) bringen die Migrationen mit; er war
# am 22.10.2026 zeilengleich mit Prod.
#
# Die Ausgabe enthält Diagnosedaten eines (Test-)Kontos. Wohin sie gehört (Repo oder nur lokal), entscheidet Rasit;
# der Test liest sie per \ir als supabase/tests/lsa_v_daten.sql.
set -euo pipefail
out="${1:?Ausgabedatei fehlt}"
sitzung=6220b7e8-ea4c-4d77-88e9-b2a728102e4e
q() { dbread -X -tA -c "$1"; }
{
  echo "-- Erzeugt von tools/lsa-v-abzug.sh am $(date -u +%Y-%m-%d) aus Prod (dbread, nur lesend)."
  echo
  echo "create temp table zz_v_plan (klasse int, position int, thema_key text, uv_titel text, halbjahr int) on commit drop;"
  echo "insert into zz_v_plan values"
  q "select string_agg(format('  (%s, %s, %L, %L, %s)', p.klasse, p.position, p.thema_key, p.uv_titel,
                              coalesce(p.halbjahr::text, 'null')), E',\n' order by p.klasse, p.position) || ';'
       from schul_themenplan p join schulen s on s.id = p.schule_id
      where s.name = 'Friedrich-Wilhelm-Gymnasium' and lower(p.fach) = 'mathematik' and p.klasse in (9, 10)"
  echo
  echo "create temp table zz_v_bestand (skill_key text, sondierrang int, mc boolean, echt boolean) on commit drop;"
  echo "insert into zz_v_bestand values"
  q "with b as (select t.skill_key, t.sondierrang, t.input_type = 'MC' as mc, public.lsa_im_pool(t.id, false) as echt
                  from tasks t where t.skill_key is not null and public.lsa_im_pool(t.id, true)),
          z as (select format('(%L,%s,%s,%s)', skill_key, coalesce(sondierrang::text, 'null'), mc::text, echt::text) as v,
                       row_number() over (order by skill_key, sondierrang nulls last, mc, echt) as n from b)
     select string_agg(zeile, E',\n' order by g) || ';'
       from (select (n - 1) / 5 as g, '  ' || string_agg(v, ', ' order by n) as zeile from z group by 1) x"
  echo
  echo "create temp table zz_v_profil (skill_key text primary key, zustand text) on commit drop;"
  echo "insert into zz_v_profil values"
  q "select string_agg(format('  (%L, %L)', skill_key, zustand), E',\n' order by skill_key) || ';'
       from lsa_skill_urteil where session_id = '$sitzung'"
  echo
  echo "create temp table zz_v_themen (thema_key text, status text) on commit drop;"
  echo "insert into zz_v_themen values"
  q "select string_agg(format('  (%L, %L)', lt.thema_key, lt.status), E',\n' order by lt.status, lt.thema_key) || ';'
       from lead_themen lt
      where lower(lt.fach) = 'mathematik'
        and lt.lead_id = (select coalesce(st.lead_id, (select l.id from leads l where l.converted_student_id = st.id))
                            from lsa_sessions s join students st on st.id = s.student_id where s.id = '$sitzung')"
} > "$out"
echo "$out: $(wc -l < "$out") Zeilen"
