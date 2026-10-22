-- ============================================================================
-- LSA-R2: durchgeklickte LSA erkennen (Migration 20261022131037_lsa_durchklicken,
-- Bauauftrag docs/lsa/Bauauftrag-LSA-R2.md).
--
-- Schwellen (Rasit, 22.10.2026): schnell < 5 s; nicht auswertbar ab 5 schnell falschen in Folge oder
-- ab 10 Antworten mit mindestens 40 % schnell falsch; Hinweis an das Kind nach 3 schnellen Abgaben in
-- Folge (ohne „Weiss ich nicht“), einmal je LSA.
--
--   D1 Rechte: admin ja, Coach nur mit aktiver Akte, Schueler nein, anon ohne Ausfuehrungsrecht
--   D2 Klickfolge (2–3 s, falsch) wird ab Aufgabe 10 nicht auswertbar, Grund 'folge'; eine reine Klickkette
--      schon bei der fuenften
--   D3 Die Anteilsregel greift erst ab 10 Antworten (auch genau 40 %)
--   D4 Langsames, schwaches Profil mit viel WN (auch schnellem WN) bleibt auswertbar
--   D5 WN unterbricht eine Folge (schnell falsch und Hinweis)
--   D6 Multi-Part zaehlt einmal
--   D7 lsa_finish schreibt auswertbar, nicht_auswertbar_grund und result_summary.durchklick
--   D8 Alte (schon abgeschlossene) Sitzungen bleiben auswertbar, kein Backfill
--   D9 platz_submit: hinweis_tempo genau einmal (auch nach Unterbrechung und neuer Folge), ok und next
--      unveraendert
--
-- Die Antworten fuer D2–D8 werden direkt eingetragen, mit fester Abgabezeit je Aufgabe: innerhalb einer
-- Transaktion haetten sonst alle Zeilen dieselbe now()-Zeit. D9 laeuft ueber platz_submit; danach
-- rueckt der Test die Zeiten der bisherigen Zeilen eine Minute zurueck, wie bei echten Abgaben.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(43);

\ir lsa_l1_fixture.sql

-- 20 Zahl-Aufgaben (richtig: 7) und 6 Mehrteiler (richtig: 7 und 8).
create temp table zz_dk_aufgabe (nr int, id uuid, typ text);
insert into zz_dk_aufgabe
select n, pg_temp.l1_aufgabe('dk-' || n, 'NUMERIC', '["7"]'), 'NUMERIC' from generate_series(1, 20) n;
insert into zz_dk_aufgabe
select 100 + n, pg_temp.l1_aufgabe('dk-mp-' || n, 'MULTI_PART', '{"1":["7"],"2":["8"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},{"nr":2,"kind":"short_input","prompt":"Teil b"}]'), 'MULTI_PART'
  from generate_series(1, 6) n;

-- Je Sitzung ein eigenes Kind (eine laufende LSA je Kind und Fach).
create function pg_temp.sitzung(p_status text default 'in_progress') returns uuid language sql as $$
  insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
  values (pg_temp.l1_kind('ZZ DK ' || gen_random_uuid()), 'Mathematik', 8, '{}', now() - interval '30 minutes',
          p_status, 'adaptiv')
  returning id
$$;

-- Haengt Abgaben an, je Zeichen eine Aufgabe, eine Minute nach der vorigen:
--   f schnell falsch (2,0 / 2,5 / 3,0 s)   r schnell richtig (2,5 s)   R langsam richtig (11 s)
--   F langsam falsch (60 s)   w WN schnell (1 s)   W WN langsam (50 s)
--   m Mehrteiler schnell (2,5 s), Teil a falsch, Teil b richtig
create function pg_temp.abgaben(p_s uuid, p_muster text) returns void language plpgsql as $$
declare
  c text; v_n int; v_task uuid; v_am timestamptz; v_ms int;
begin
  foreach c in array regexp_split_to_array(p_muster, '') loop
    v_n := (select count(distinct task_id) from lsa_responses where session_id = p_s);
    v_am := timestamptz '2026-01-01 08:00' + make_interval(mins => v_n);
    select a.id into v_task from zz_dk_aufgabe a
     where a.typ = case when c = 'm' then 'MULTI_PART' else 'NUMERIC' end
       and not exists (select 1 from lsa_responses r where r.session_id = p_s and r.task_id = a.id)
     order by a.nr limit 1;
    v_ms := case c when 'f' then 2000 + (v_n % 3) * 500 when 'r' then 2500 when 'R' then 11000
                   when 'F' then 60000 when 'w' then 1000 when 'W' then 50000 when 'm' then 2500 end;
    if c = 'm' then
      insert into lsa_responses (session_id, task_id, part_nr, response, abgabeart, correct, duration_ms, created_at)
      values (p_s, v_task, 1, '{"text":"1"}', 'antwort', false, v_ms, v_am),
             (p_s, v_task, 2, '{"text":"8"}', 'antwort', true, v_ms, v_am);
    else
      insert into lsa_responses (session_id, task_id, response, abgabeart, correct, duration_ms, created_at)
      values (p_s, v_task,
              case when c in ('w', 'W') then '{"dont_know":true}'::jsonb
                   when c in ('r', 'R') then '{"text":"7"}' else '{"text":"1"}' end,
              case when c in ('w', 'W') then 'weiss_nicht' else 'antwort' end,
              case when c in ('w', 'W') then null else c in ('r', 'R') end,
              v_ms, v_am);
    end if;
  end loop;
end $$;

create function pg_temp.stand(p_s uuid) returns jsonb language sql as $$
  select public.lsa_durchklick_stand(p_s)
$$;

select pg_temp.act_as(:'admin');

-- D1 Rechte ----------------------------------------------------------------
select pg_temp.sitzung() as s1 \gset
select is(pg_temp.stand(:'s1') - 'schwellen',
          '{"antworten": 0, "schnell_falsch": 0, "anteil_schnell_falsch": 0, "folge_schnell_falsch_max": 0,
            "folge_schnell_aktuell": 0, "nicht_auswertbar": false, "grund": null}'::jsonb,
          'D1 admin: leere Sitzung, alles 0, auswertbar');
select is(pg_temp.stand(:'s1') -> 'schwellen',
          '{"schnell_ms": 5000, "folge": 5, "anteil": 0.40, "min_antworten": 10, "hinweis_folge": 3}'::jsonb,
          'D1 die Schwellen stehen in der Funktion');
select pg_temp.act_as(:'tablet');
select throws_ok(format('select public.lsa_durchklick_stand(%L)', :'s1'), '42501', null,
                 'D1 Schueler (Platz-Konto): 42501');
select pg_temp.act_as(:'admin');
-- Coach: mit aktiver Akte (Vertrag ohne Trigger angelegt, wie session_a1) ja, ohne nein.
\set coach 'b1e1b1e1-0003-4000-8000-000000000001'
insert into auth.users (id, email, instance_id, aud, role)
values (:'coach', 'dk-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'coach', 'dk-coach@test.local', 'coach', 'ZZ DK Coach');
set local session_replication_role = replica;
insert into vertraege (lead_id, student_id, status, vertrag_status, abgeschlossen_am, vertragsbeginn, vertrag_ende,
                       widerruf_bis)
select st.lead_id, st.id, 'abgeschlossen', 'aktiv',
       (date_trunc('month', current_date) - interval '2 months')::date,
       (date_trunc('month', current_date) - interval '1 month')::date,
       (date_trunc('month', current_date) + interval '11 months')::date - 1,
       (date_trunc('month', current_date) - interval '1 month')::date + 14
  from lsa_sessions l join students st on st.id = l.student_id where l.id = :'s1';
set local session_replication_role = origin;
select pg_temp.sitzung() as s_fremd \gset
select pg_temp.act_as(:'coach');
select is(pg_temp.stand(:'s1') ->> 'antworten', '0', 'D1 Coach mit aktiver Akte: darf');
select throws_ok(format('select public.lsa_durchklick_stand(%L)', :'s_fremd'), '42501', null,
                 'D1 Coach ohne aktive Akte: 42501');
select pg_temp.act_as(:'admin');
select ok(has_function_privilege('authenticated', 'public.lsa_durchklick_stand(uuid)', 'execute')
          and not has_function_privilege('anon', 'public.lsa_durchklick_stand(uuid)', 'execute'),
          'D1 authenticated ja, anon nein');

-- D2 Klickfolge ------------------------------------------------------------
-- Vier schnell falsche, eine langsam richtige, dann wieder schnell falsch: die Folge erreicht 5 bei Aufgabe 10.
select pg_temp.abgaben(:'s1', 'ffffRffff');
select is(pg_temp.stand(:'s1') ->> 'antworten', '9', 'D2 nach Aufgabe 9: neun Antworten');
select is(pg_temp.stand(:'s1') ->> 'folge_schnell_falsch_max', '4', 'D2 nach Aufgabe 9: laengste Folge 4');
select is(pg_temp.stand(:'s1') ->> 'nicht_auswertbar', 'false', 'D2 nach Aufgabe 9: noch auswertbar');
select pg_temp.abgaben(:'s1', 'f');
select is(pg_temp.stand(:'s1') ->> 'nicht_auswertbar', 'true', 'D2 ab Aufgabe 10: nicht auswertbar');
select is(pg_temp.stand(:'s1') ->> 'grund', 'folge', 'D2 Grund folge (Folge vor Anteil)');
select is(pg_temp.stand(:'s1') ->> 'schnell_falsch', '9', 'D2 neun schnell falsch');

select pg_temp.sitzung() as s1b \gset
select pg_temp.abgaben(:'s1b', 'ffff');
select is(pg_temp.stand(:'s1b') ->> 'nicht_auswertbar', 'false', 'D2 reine Klickkette: nach vier noch auswertbar');
select pg_temp.abgaben(:'s1b', 'f');
select is(pg_temp.stand(:'s1b') ->> 'grund', 'folge', 'D2 … bei der fuenften nicht auswertbar, Grund folge');

-- D3 Anteil erst ab 10 Antworten ---------------------------------------------
select pg_temp.sitzung() as s2 \gset
select pg_temp.abgaben(:'s2', 'ffRffRffR');
select is(pg_temp.stand(:'s2') ->> 'anteil_schnell_falsch', '0.67', 'D3 9 Antworten, 67 % schnell falsch');
select is(pg_temp.stand(:'s2') ->> 'nicht_auswertbar', 'false', 'D3 … unter 10 Antworten greift der Anteil nicht');
select pg_temp.abgaben(:'s2', 'f');
select is(pg_temp.stand(:'s2') ->> 'nicht_auswertbar', 'true', 'D3 bei 10 Antworten (70 %) nicht auswertbar');
select is(pg_temp.stand(:'s2') ->> 'grund', 'anteil', 'D3 Grund anteil');
select pg_temp.sitzung() as s3 \gset
select pg_temp.abgaben(:'s3', 'ffRRRfRRRR');
select is(pg_temp.stand(:'s3') ->> 'nicht_auswertbar', 'false', 'D3 30 % bei 10 Antworten: auswertbar');
select pg_temp.abgaben(:'s3', 'f');
select is(pg_temp.stand(:'s3') -> 'anteil_schnell_falsch', '0.36'::jsonb, 'D3 4 von 11 = 36 %');
select is(pg_temp.stand(:'s3') ->> 'nicht_auswertbar', 'false', 'D3 … auswertbar');
select pg_temp.sitzung() as s3b \gset
select pg_temp.abgaben(:'s3b', 'ffRRRffRRR');
select is(pg_temp.stand(:'s3b') ->> 'grund', 'anteil', 'D3 genau 40 % bei 10 Antworten: nicht auswertbar');

-- D4 Langsam und schwach, viel WN --------------------------------------------
select pg_temp.sitzung() as s4 \gset
select pg_temp.abgaben(:'s4', 'FwFwFWwFFwwFFwFWFFww');
select is(pg_temp.stand(:'s4') - 'schwellen',
          '{"antworten": 20, "schnell_falsch": 0, "anteil_schnell_falsch": 0, "folge_schnell_falsch_max": 0,
            "folge_schnell_aktuell": 0, "nicht_auswertbar": false, "grund": null}'::jsonb,
          'D4 20 Antworten, 10 WN (8 davon in 1 s), alles Falsche langsam: auswertbar, kein Hinweis');

-- D5 WN unterbricht -----------------------------------------------------------
select pg_temp.sitzung() as s5 \gset
select pg_temp.abgaben(:'s5', 'ffffwffff');
select is(pg_temp.stand(:'s5') ->> 'folge_schnell_falsch_max', '4', 'D5 vier, WN, vier: laengste Folge 4');
select is(pg_temp.stand(:'s5') ->> 'nicht_auswertbar', 'false', 'D5 … auswertbar');
select pg_temp.abgaben(:'s5', 'w');
select is(pg_temp.stand(:'s5') ->> 'folge_schnell_aktuell', '0', 'D5 schnelles WN setzt die Hinweis-Folge auf 0');
select pg_temp.abgaben(:'s5', 'rf');
select is(pg_temp.stand(:'s5') ->> 'folge_schnell_aktuell', '2', 'D5 danach zaehlt schnell richtig wie schnell falsch');

-- D6 Multi-Part zaehlt einmal ---------------------------------------------------
select pg_temp.sitzung() as s6 \gset
select pg_temp.abgaben(:'s6', 'mmmm');
select is((select count(*) from lsa_responses where session_id = :'s6'), 8::bigint, 'D6 vier Mehrteiler, acht Zeilen');
select is(pg_temp.stand(:'s6') ->> 'antworten', '4', 'D6 … vier Antworten');
select is(pg_temp.stand(:'s6') ->> 'folge_schnell_falsch_max', '4', 'D6 … Folge 4, nicht 8 (ein falscher Teil reicht)');
select is(pg_temp.stand(:'s6') ->> 'nicht_auswertbar', 'false', 'D6 … noch auswertbar');

-- D7 lsa_finish -----------------------------------------------------------------
select lives_ok(format('select public.lsa_finish(%L)', :'s1'), 'D7 lsa_finish der Klickfolge');
select is((select auswertbar from lsa_sessions where id = :'s1'), false, 'D7 Klickfolge: auswertbar = false');
select is((select nicht_auswertbar_grund ->> 'grund' from lsa_sessions where id = :'s1'), 'folge',
          'D7 nicht_auswertbar_grund mit Grund folge');
select is((select result_summary -> 'durchklick' from lsa_sessions where id = :'s1'),
          (select nicht_auswertbar_grund from lsa_sessions where id = :'s1'),
          'D7 result_summary.durchklick = nicht_auswertbar_grund');
select public.lsa_finish(:'s4');
select ok((select auswertbar and nicht_auswertbar_grund is null and status = 'completed'
                  and result_summary -> 'durchklick' ->> 'nicht_auswertbar' = 'false'
             from lsa_sessions where id = :'s4'),
          'D7 langsames Profil: auswertbar, kein Grund, durchklick in result_summary');

-- D8 Alte Sitzungen ---------------------------------------------------------------
select pg_temp.sitzung('completed') as s7 \gset
update lsa_sessions set result_summary = '{"answered": 10}', completed_at = now() where id = :'s7';
select pg_temp.abgaben(:'s7', 'ffffffffff');
select is(pg_temp.stand(:'s7') ->> 'nicht_auswertbar', 'true', 'D8 alte Klick-Sitzung: der Stand sagt nicht auswertbar');
select ok((select auswertbar and nicht_auswertbar_grund is null from lsa_sessions where id = :'s7'),
          'D8 … die Spalte bleibt true (Default, kein Backfill)');
select is(public.lsa_finish(:'s7'), '{"answered": 10}'::jsonb, 'D8 lsa_finish gibt das alte result_summary zurueck');
select is((select auswertbar from lsa_sessions where id = :'s7'), true, 'D8 … und aendert auswertbar nicht');

-- D9 platz_submit: hinweis_tempo --------------------------------------------------
select pg_temp.l1_kind('Ida ZZ DK') as kind2 \gset
insert into lsa_sessions (student_id, subject, grade, item_ids, started_at, status, modus)
values (:'kind2', 'Mathematik', 8,
        (select array_agg(id order by nr) from zz_dk_aufgabe where typ = 'NUMERIC' and nr <= 12),
        now() - interval '5 minutes', 'in_progress', 'fest')
returning id as s8 \gset
select public.platz_assign(:'tablet', :'s8');
select pg_temp.act_as(:'tablet');

-- Gibt Aufgabe nr ab und rueckt danach die Zeiten der Sitzung eine Minute zurueck; liefert die Antwort.
create function pg_temp.platz(p_s uuid, p_nr int, p_resp jsonb, p_ms int) returns jsonb language plpgsql as $$
declare v jsonb;
begin
  v := public.platz_submit((select id from zz_dk_aufgabe where nr = p_nr), p_resp, p_ms);
  update lsa_responses set created_at = created_at - interval '1 minute' where session_id = p_s;
  return v;
end $$;

select is(array(select pg_temp.platz(:'s8', n, r::jsonb, ms) ->> 'hinweis_tempo'
                  from (values (1, '{"text":"1"}', 2000), (2, '{"text":"7"}', 2000), (3, '{"dont_know":true}', 1000),
                               (4, '{"text":"7"}', 2000), (5, '{"text":"1"}', 2000), (6, '{"text":"7"}', 2000),
                               (7, '{"text":"1"}', 2000), (8, '{"text":"1"}', 30000), (9, '{"text":"1"}', 2000),
                               (10, '{"text":"7"}', 2000), (11, '{"text":"1"}', 2000)) v(n, r, ms) order by n),
          array['false', 'false', 'false', 'false', 'false', 'true', 'false', 'false', 'false', 'false', 'false'],
          'D9 schnell, schnell, WN, dann drei schnelle: Hinweis bei der dritten; nach langsamer Abgabe und neuer '
            || 'Folge nicht noch einmal');
select ok((select hinweis_tempo_am is not null from lsa_sessions where id = :'s8'), 'D9 hinweis_tempo_am gesetzt');
select is((select array_agg(k order by k) from jsonb_object_keys(pg_temp.platz(:'s8', 12, '{"text":"1"}', 2000)) k),
          array['hinweis_tempo', 'next', 'ok'], 'D9 Antwort: ok, next und hinweis_tempo, sonst nichts');

select * from finish();
rollback;
