-- W3-6 Trockenlauf gegen die echte DB: begin -> Migration 20261003092850 ->
-- drei simulierte Sitzungen mit eigenen Testdaten (ZZ-Leads) -> rollback.
-- Nichts bleibt stehen. Aus dem Repo-Wurzelverzeichnis starten:
--   set -a; . ./.env; set +a
--   psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -f supabase/checks/lsa_thema_einstieg_trockenlauf.PRUEFUNG.sql
-- Nur VOR dem Einspielen sinnvoll (danach existiert lsa_lead_von_schueler schon).
\set ON_ERROR_STOP 1
\pset pager off
select current_database() = 'postgres' as ist_ziel \gset
\if :ist_ziel
\else
  \echo 'current_database() ist nicht postgres - Abbruch.'
  \quit
\endif
begin;
set local lock_timeout = '3s';
set local statement_timeout = '180s';

select current_database() as db, now() as jetzt \gx

\i supabase/migrations/20261003092850_lsa_thema_einstieg.sql

select thema_key, string_agg(skill_key, ', ' order by skill_key) as einstieg
  from thema_einstieg group by 1 order by 1;

-- Als Admin handeln (bestehendes Admin-Profil, nur in dieser Transaktion).
select set_config('request.jwt.claims',
  json_build_object('sub', (select id from profiles where role = 'admin' order by created_at limit 1),
                    'role', 'authenticated')::text, true) is not null as als_admin;

create function pg_temp.kind(p_name text, p_klasse int, p_aktuell text, p_behandelt text[], p_schule uuid)
returns uuid language plpgsql as $$
declare v_lead uuid; v_student uuid;
begin
  insert into leads (full_name, class_level, status, schule_id)
  values (p_name, p_klasse, 'contacted', p_schule) returning id into v_lead;
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  values (v_lead, 'mathematik', p_aktuell, 'aktuell', 'gespraech');
  insert into lead_themen (lead_id, fach, thema_key, status, quelle)
  select v_lead, 'mathematik', b, 'behandelt', 'schulplan' from unnest(p_behandelt) b;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (class_level, is_provisional, lead_id)
  values (p_klasse, true, v_lead) returning id into v_student;
  return v_student;
end $$;

create function pg_temp.antwort(p_task uuid, p_richtig boolean) returns jsonb language sql as $$
  select case
    when t.input_type = 'MC' then
      case when p_richtig then jsonb_build_object('selected', s.correct_answers)
           else '{"selected":["zz"]}'::jsonb end
    when t.input_type = 'MULTI_PART' then
      (select jsonb_object_agg(k, case when p_richtig then v -> 0 else '"999999"'::jsonb end)
         from jsonb_each(s.correct_answers) e(k, v))
    else jsonb_build_object('value', case when p_richtig then s.correct_answers ->> 0 else '999999' end)
  end
  from tasks t join task_solutions s on s.task_id = t.id where t.id = p_task
$$;

create function pg_temp.offen(p_sess uuid) returns uuid language sql as $$
  select a.task_id from lsa_ausgegeben a
   where a.session_id = p_sess
     and not exists (select 1 from lsa_responses r where r.session_id = p_sess and r.task_id = a.task_id)
   limit 1
$$;

create temp table ablauf (sitzung text, nr int, minute numeric, skill_key text, klasse int,
                          input_type text, antwort text, urteil text, phase text);

create function pg_temp.lauf(p_name text, p_student uuid, p_klasse int, p_muster text, p_schritt interval)
returns void language plpgsql as $$
declare
  v_t0 timestamptz := date_trunc('minute', now());
  v_sess uuid; v_task uuid; v_sk text; v_prev text; i int := 0;
  v_ein text[]; v_raum text[]; v_beh text[]; v_phase text;
begin
  v_sess := (public.lsa_start(p_student, p_klasse, 'Mathematik', 'adaptiv', v_t0) ->> 'session_id')::uuid;
  select array_agg(te.skill_key) into v_ein
    from thema_einstieg te join lsa_sessions s on s.thema_key = te.thema_key where s.id = v_sess;
  v_raum := coalesce(v_ein, '{}') || array(select a.skill_key from unnest(v_ein) e(sk), public.lsa_abschluss(e.sk) a);
  select array_agg(te.skill_key) into v_beh
    from lead_themen lt join thema_einstieg te on te.thema_key = lt.thema_key
   where lt.lead_id = public.lsa_lead_von_schueler(p_student) and lt.status = 'behandelt';
  v_task := pg_temp.offen(v_sess);
  loop
    i := i + 1;
    exit when v_task is null or i > length(p_muster);
    v_sk := (select skill_key from tasks where id = v_task);
    v_phase := case when v_sk = v_prev then 'Zweitbeleg'
                    when v_sk = any (v_ein) then 'T'
                    when v_sk = any (v_raum) then 'Tiefe'
                    when v_sk = any (v_beh) then 'Breite a'
                    else 'Breite b / Rest' end;
    perform public.lsa_submit(v_sess, v_task, pg_temp.antwort(v_task, substr(p_muster, i, 1) = 'r'),
                              1000, v_t0 + i * p_schritt);
    insert into ablauf
    select p_name, i, round(extract(epoch from (i - 1) * p_schritt) / 60, 1), v_sk, s.klasse_herkunft,
           t.input_type, substr(p_muster, i, 1),
           (select zustand || case when offen then ' (offen)' else '' end
              from lsa_skill_urteil where session_id = v_sess and skill_key = v_sk),
           v_phase
      from tasks t join skills s on s.skill_key = t.skill_key where t.id = v_task;
    v_prev := v_sk;
    v_task := pg_temp.offen(v_sess);
  end loop;
  insert into ablauf (sitzung, nr, phase, skill_key)
  values (p_name, i, 'Ende', coalesce((select skill_key from tasks where id = v_task), '— nichts mehr —'));
end $$;

-- Sitzung 0: heutiger Stand — die fkt_linear_*-Aufgaben sind noch draft,
-- Phase T entfaellt, die Sitzung beginnt in der Breite.
select pg_temp.lauf('S0 Kl8 linfkt heute',
  pg_temp.kind('ZZ Trockenlauf W3-6 S0', 8, 'lineare_funktionen', array['zinsrechnung','terme_gleichungen'],
               '07ae78ae-17b9-46c2-9a59-8a5be2290d81'),
  8, 'rrrr', '1 minute');

-- Ab hier wie nach Lenas Freigabe: Linear- und Zins-Aufgaben transaktionslokal
-- auf ready (faellt mit dem rollback weg).
update tasks set status = 'ready'
 where status = 'draft' and (skill_key like 'fkt_linear\_%' or skill_key like 'prozent\_zins\_%');

-- Sitzung 1: Klasse 8, Thema Lineare Funktionen, traegt durchgehend.
select pg_temp.lauf('S1 Kl8 linfkt traegt',
  pg_temp.kind('ZZ Trockenlauf W3-6 S1', 8, 'lineare_funktionen', array['zinsrechnung','terme_gleichungen'],
               '07ae78ae-17b9-46c2-9a59-8a5be2290d81'),
  8, 'rrrrrrrr', '1 minute');

-- Sitzung 2: Klasse 8, Thema Lineare Funktionen, bricht und steigt ab.
select pg_temp.lauf('S2 Kl8 linfkt bricht',
  pg_temp.kind('ZZ Trockenlauf W3-6 S2', 8, 'lineare_funktionen', array['zinsrechnung','terme_gleichungen'],
               '07ae78ae-17b9-46c2-9a59-8a5be2290d81'),
  8, 'ffffffrffrffrrffffrr', '50 seconds');

-- Sitzung 3: Klasse 7, Thema Zinsrechnung, bricht tief, ohne Schule.
select pg_temp.lauf('S3 Kl7 zins bricht tief',
  pg_temp.kind('ZZ Trockenlauf W3-6 S3', 7, 'zinsrechnung', array[]::text[], null),
  7, repeat('f', 30), '75 seconds');

select sitzung, nr, minute, phase, skill_key, klasse, input_type, antwort, urteil
  from ablauf order by sitzung, nr, phase = 'Ende';

select sitzung, count(*) filter (where klasse > case when sitzung like '%Kl7%' then 7 else 8 end) as ueber_klasse
  from ablauf where phase <> 'Ende' and skill_key is not null group by 1 order by 1;

rollback;

select count(*) as zz_leads_nach_rollback from leads where full_name like 'ZZ Trockenlauf W3-6%';
