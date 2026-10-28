-- ============================================================================
-- Reihe 1 · D2 Übung zuhause, Offen-Regeln, „Zeig's mir“, Fragen an den Coach (Bauauftrag D, D2.4).
--
--   1) home_uebung_melden speichert nie Antworten: keine Spalte dafür, Signatur ohne Antwort; nur das Kind selbst
--   2) eine Wertung zuhause über aufgabe_werten lässt alle Tabellen unverändert (Zeilenzahlen vorher/nachher);
--      melden ändert nur home_uebung und xp_events — kein Befund, keine Stufe, kein Plan
--   3) home_uebung_kurz zählt seit der letzten abgeschlossenen Session vor Ort; Coach und Admin lesen, fremde Kinder nie
--   4) zeigs_mir: Vorschlag nur bei mindestens zwei Quests und nicht sicher; höchstens einer je Kind und Session;
--      Entscheidung nur Coach der Session oder Admin
--   5) kompetenz_offen: Regeln 1–6 an einem kleinen Katalog; Übung zuhause ändert keinen Zustand
--   6) home_pfad: XP aus der Übung, Wochen mit Übung, Serie
--   7) Fragen an den Coach
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set admin 'dddddddd-d200-4000-8000-000000000001'
\set coach 'dddddddd-d200-4000-8000-000000000002'
\set fremd 'dddddddd-d200-4000-8000-000000000003'
\set k1    'dddddddd-d200-4000-8000-000000000004'
\set k2    'dddddddd-d200-4000-8000-000000000005'
\set k3    'dddddddd-d200-4000-8000-000000000006'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'd2-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'coach', 'coach'), (:'fremd', 'fremd'), (:'k1', 'k1'), (:'k2', 'k2'), (:'k3', 'k3')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'd2-admin@test.local', 'admin', 'ZZ Admin'), (:'coach', 'd2-coach@test.local', 'coach', 'ZZ Coach'),
  (:'fremd', 'd2-fremd@test.local', 'coach', 'ZZ Fremd'),
  (:'k1', 'd2-k1@test.local', 'student', 'Batu Test'), (:'k2', 'd2-k2@test.local', 'student', 'Mira Test'),
  (:'k3', 'd2-k3@test.local', 'student', 'Elif Test');

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;
create or replace function pg_temp.kind(p_profil uuid, p_ende date default current_date + 300) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Kind', 'ZZ', 'vertrag', 9) returning id into v_lead;
  insert into students (class_level, profile_id) values (9, p_profil) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname)
  select v_lead, 'abgeschlossen', case when p_ende < current_date then 'ausgelaufen' else 'aktiv' end, now(),
         date_trunc('month', current_date)::date - 30, 'vor_ort', v_st,
         date_trunc('month', current_date)::date - case when p_ende < current_date then 365 else 0 end, p_ende,
         date_trunc('month', current_date)::date + 13,
         t.id, 12, tl.einheiten, 'Mathematik', 9, 'ZZ', 'Kind'
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = 12 where t.name = 'Basic';
  return v_st;
end $$;
-- Zeilenzahl aller Tabellen in public (für „nichts ändert sich“).
create or replace function pg_temp.zeilen() returns table (t text, n bigint) language plpgsql as $$
declare r record;
begin
  for r in select c.relname from pg_class c where c.relnamespace = 'public'::regnamespace and c.relkind = 'r' order by 1 loop
    t := r.relname; execute format('select count(*) from public.%I', r.relname) into n; return next;
  end loop;
end $$;

select pg_temp.kind(:'k1') as s1 \gset
select pg_temp.kind(:'k2') as s2 \gset
select pg_temp.kind(:'k3', current_date - 30) as s3 \gset
-- now() steht in der Testtransaktion still: Meldungen werden nach jedem Aufruf zwei Minuten zurückgeschoben, damit die
-- 60-Sekunden-Sperre gegen Wiederholungen sie nicht verschluckt. Dafür ist die Append-only-Sperre hier aus (Test 1 prüft sie).
alter table home_uebung disable trigger home_uebung_append_only;
create or replace function pg_temp.melden(p_kind_uid uuid, p_skill text, p_anzahl int, p_dauer int) returns void language plpgsql as $$
begin
  perform pg_temp.als(p_kind_uid);
  perform home_uebung_melden(p_skill, p_anzahl, p_dauer);
  update home_uebung set am = am - interval '2 minutes' where am > now() - interval '1 minute';
end $$;
-- Inhalt (nicht nur Zeilenzahl) der Tabellen, an denen Befund, Stufe und Plan hängen.
create or replace function pg_temp.inhalt() returns text language sql as $$
  select md5(coalesce((select string_agg(row_to_json(l)::text, '|' order by l.id) from lernpfad l), '')
          || coalesce((select string_agg(row_to_json(b)::text, '|' order by b.id) from lernpfad_belege b), '')
          || coalesce((select string_agg(row_to_json(u)::text, '|' order by u.session_id, u.skill_key) from lsa_skill_urteil u), '')
          || coalesce((select string_agg(row_to_json(q)::text, '|' order by q.id) from quests q), ''))
$$;

-- Kleiner Katalog: z_a (Kl. 7) → z_b (Kl. 9, Thema z_thema) → z_c (Kl. 10); z_d (Kl. 10, ohne Voraussetzung);
-- z_e (Kl. 10) braucht z_d; z_f (Kl. 10) braucht z_g (Kl. 10, ohne Voraussetzung, sicher).
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('z_a', 'ZZ A', 'Mathematik', 7, 1), ('z_b', 'ZZ B', 'Mathematik', 9, 2), ('z_c', 'ZZ C', 'Mathematik', 10, 3),
  ('z_d', 'ZZ D', 'Mathematik', 10, 1), ('z_e', 'ZZ E', 'Mathematik', 10, 2), ('z_f', 'ZZ F', 'Mathematik', 10, 2),
  ('z_g', 'ZZ G', 'Mathematik', 10, 1);
insert into skill_kante (skill_key, voraussetzt_skill_key) values ('z_b', 'z_a'), ('z_c', 'z_b'), ('z_e', 'z_d'), ('z_f', 'z_g');
insert into themen (thema_key, fach, klasse, label, stufe, sort) select 'z_thema', 'Mathematik', 9, 'ZZ Thema', stufe, 9999
  from themen limit 1;
insert into skill_thema (skill_key, thema_key) values ('z_b', 'z_thema');
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select l.id, 'Mathematik', 'z_thema', 'aktuell', 'gespraech' from leads l where l.converted_student_id = :'s1';
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'s1', 'z_g', 'sicher', 'lsa'), (:'s1', 'z_b', 'noch_nicht_sicher', 'lsa');
-- z_h (Kl. 10, braucht z_c) gehört nur zum Thema einer bevorstehenden Klassenarbeit; z_i (Kl. 10) zu einer geschriebenen.
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values
  ('z_h', 'ZZ H', 'Mathematik', 10, 4), ('z_i', 'ZZ I', 'Mathematik', 10, 4);
insert into skill_kante (skill_key, voraussetzt_skill_key) values ('z_h', 'z_c'), ('z_i', 'z_c');
insert into themen (thema_key, fach, klasse, label, stufe, sort) select 'z_ka', 'Mathematik', 9, 'ZZ KA', stufe, 9998 from themen limit 1;
insert into themen (thema_key, fach, klasse, label, stufe, sort) select 'z_alt', 'Mathematik', 9, 'ZZ alt', stufe, 9997 from themen limit 1;
insert into skill_thema (skill_key, thema_key) values ('z_h', 'z_ka'), ('z_i', 'z_alt');
insert into lead_klassenarbeiten (lead_id, fach, schuljahr, nr, datum, thema_keys, status, quelle)
select l.id, 'mathematik', '2026/27', 1, current_date + 10, array['z_ka'], 'bevorstehend', 'admin' from leads l where l.converted_student_id = :'s1';
insert into lead_klassenarbeiten (lead_id, fach, schuljahr, nr, datum, thema_keys, status, quelle)
select l.id, 'mathematik', '2026/27', 2, current_date - 10, array['z_alt'], 'geschrieben', 'admin' from leads l where l.converted_student_id = :'s1';

-- ── 1) Melden ───────────────────────────────────────────────────────────────
select is((select count(*)::int from information_schema.columns
            where table_schema = 'public' and table_name = 'home_uebung'
              and column_name ~* '(antwort|eingabe|richtig|ergebnis|fehlbild|korrekt|correct)'), 0,
          '1 home_uebung hat keine Spalte für Antworten oder Richtigkeit');
select is((select pg_get_function_identity_arguments('public.home_uebung_melden'::regproc)),
          'p_skill text, p_anzahl integer, p_dauer_sek integer', '1 die Meldung nimmt keine Antwort an');
select pg_temp.als(:'coach');
select throws_ok($$select home_uebung_melden('z_b', 5, 300)$$, '42501', null, '1 Coach meldet keine Übung');
select pg_temp.als(:'admin');
select throws_ok($$select home_uebung_melden('z_b', 5, 300)$$, '42501', null, '1 Admin meldet keine Übung');
select pg_temp.als(:'k1');
select throws_ok($$select home_uebung_melden('gibt_es_nicht', 5, 300)$$, '22023', null, '1 unbekannter Skill');
select throws_ok($$select home_uebung_melden('z_b', 0, 300)$$, '22023', null, '1 Anzahl mindestens 1');
select throws_ok($$select home_uebung_melden('z_b', 5, 10)$$, '22023', null, '1 fünf Aufgaben in zehn Sekunden: zu kurz');
select throws_ok($$select home_uebung_melden('z_e', 5, 300)$$, '22023', null, '1 gesperrter Skill: keine Quest');
reset role;
select pg_temp.als(:'k3');
select throws_ok($$select home_uebung_melden('z_d', 5, 300)$$, '42501', null, '1 ohne laufenden Vertrag keine Meldung');
reset role;
set local role authenticated;
select pg_temp.als(:'k1');
select is((select count(*)::int from home_uebung), 0, '1 das Kind liest home_uebung nicht direkt');
select throws_ok($$insert into home_uebung (student_id, skill_key, aufgaben, dauer_sek) values (gen_random_uuid(), 'z_b', 1, 60)$$,
                 '42501', null, '1 das Kind schreibt nicht direkt');
select throws_ok(format('select home_darf_lesen(%L)', :'s1'), '42501', null, '1 interne Hilfe nicht aufrufbar');
reset role;
set local role anon;
select throws_ok($$select home_uebung_melden('z_b', 5, 300)$$, '42501', null, '1 anon: gesperrt');
reset role;

-- ── 2) Nichts ändert sich ───────────────────────────────────────────────────
reset role;
select to_regprocedure('public.aufgabe_werten(uuid,jsonb)') is null as attrappe \gset
\if :attrappe
  -- A ist noch nicht auf dev: Attrappe nur in dieser Transaktion (Konzept §9).
  create function public.aufgabe_werten(p_task uuid, p_antwort jsonb)
  returns table (richtig boolean, fehlbild_key text, rueckmeldung text) language sql stable as $f$ select true, null::text, null::text $f$;
  select gen_random_uuid() as werte_task \gset
\else
  -- Mit A wertet das Kind zuhause nur ziehbare Instanzen der Rolle home (Konzept §3.1, §9): eine anlegen.
  select set_config('request.jwt.claims', '{"role":"service_role"}', true);
  insert into bauformen (schluessel, skill_key, format, rollen, steckbrief, status)
  values ('ZH-1', 'z_b', 'zahl', '{home}', '{}', 'zur_pruefung') returning id as hb, version as hb_v \gset
  update bauformen set status = 'freigegeben' where id = :'hb';
  insert into tasks (content_type, input_type, status, is_active, question, skill_key, est_duration_sec, source, source_ref,
                     einsatz, bauform_id, bauform_version, stufe, rolle, pruefmaschine)
  values ('exercise', 'NUMERIC', 'ready', true, 'ZZ D2 home', 'z_b', 60, 'test', 'd2-home-1', '{session}', :'hb', :'hb_v', 1,
          'home', '{"1": {"ok": true}}')
  returning id as werte_task \gset
\endif
create temp table vorher as select * from pg_temp.zeilen();
select pg_temp.als(:'k1');
select count(*) from aufgabe_werten(:'werte_task', '{"eingabe":{"text":"2·3·3"}}'::jsonb);
reset role;
select is((select count(*)::int from pg_temp.zeilen() z join vorher v using (t) where z.n <> v.n), 0,
          '2 eine Wertung über aufgabe_werten ändert keine Tabelle');
drop table vorher;
create temp table vorher as select * from pg_temp.zeilen();
select pg_temp.inhalt() as inhalt_vorher \gset
select pg_temp.melden(:'k1', 'z_b', 5, 300);
reset role;
select is(pg_temp.inhalt(), :'inhalt_vorher', '2 Inhalt von lernpfad, Belegen, LSA-Urteilen und Quests unverändert');
select is((select string_agg(z.t, ',' order by z.t) from pg_temp.zeilen() z join vorher v using (t) where z.n <> v.n),
          'home_uebung,student_progress,xp_events',
          '2 melden ändert nur home_uebung und die XP (xp_events, student_progress): kein Befund, keine Stufe, kein Plan');
select is((select sum(xp)::int from xp_events where student_id = :'s1' and reason = 'home_uebung'), 10, '2 10 XP je Quest');
select is((select stand_system from lernpfad where student_id = :'s1' and skill_key = 'z_b'), 'noch_nicht_sicher',
          '2 der Befund bleibt unverändert');

-- ── 3) Kurzfassung seit der letzten Session ─────────────────────────────────
-- Eine abgeschlossene Session gestern, Batu war da; eine Meldung davor zählt nicht. Laufzustand wie session_abschliessen.
select set_config('edvance.session_rpc', '1', true);
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am, beendet_am)
values (:'coach', 'ZZ Raum', now() - interval '1 day 1 hour', 'done', now() - interval '1 day 1 hour', now() - interval '1 day')
returning id as alt \gset
insert into session_students (session_id, student_id, attendance) values (:'alt', :'s1', 'present');
select set_config('edvance.session_rpc', '', true);
update home_uebung set am = now() - interval '2 days' where student_id = :'s1';
select pg_temp.melden(:'k1', 'z_b', 5, 300);
select pg_temp.melden(:'k1', 'z_b', 4, 200);
select pg_temp.melden(:'k1', 'z_a', 5, 250);
-- Wiederholung derselben Quest innerhalb von 60 s bucht nichts.
select home_uebung_melden('z_b', 5, 300);
select home_uebung_melden('z_b', 5, 300);
select results_eq($$select skill_key, quests, aufgaben, dauer_sek from home_uebung_kurz((select get_my_student_id()))$$,
                  $$values ('z_b'::text, 3, 14, 800), ('z_a'::text, 1, 5, 250)$$,
                  '3 seit der letzten Session: z_b 3×, z_a 1× (die doppelte Meldung zählt einmal)');
select is((select quests from home_uebung_kurz(get_my_student_id(), '-infinity') where skill_key = 'z_b'), 4,
          '3 mit p_seit: auch die ältere Meldung');
select throws_ok(format('select * from home_uebung_kurz(%L)', :'s2'), '42501', null, '3 ein Kind liest nie die Übung eines anderen');
reset role;
select pg_temp.als(:'admin');
select is((select count(*)::int from home_uebung_kurz(:'s1')), 2, '3 Admin liest');
reset role;
select akte_aktiv(:'s1') as akte \gset
select pg_temp.als(:'coach');
select is((select count(*)::int > 0 from home_uebung_kurz(:'s1')), :'akte'::boolean, '3 Coach liest genau bei aktiver Akte');
reset role;
-- Fehlte das Kind in der letzten Session (unexcused), zählt sie nicht als Grenze.
select set_config('edvance.session_rpc', '1', true);
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am, beendet_am)
values (:'coach', 'ZZ Raum', now() - interval '3 hours', 'done', now() - interval '3 hours', now() - interval '150 minutes')
returning id as weg \gset
select set_config('edvance.session_rpc', '', true);
insert into session_students (session_id, student_id, attendance) values (:'weg', :'s1', 'unexcused');
select pg_temp.als(:'k1');
select is((select sum(quests)::int from home_uebung_kurz(get_my_student_id())), 4, '3 eine verpasste Session setzt die Zählung nicht zurück');
reset role;

-- ── 4) Zeig's mir ───────────────────────────────────────────────────────────
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach', 'ZZ Raum', now() + interval '1 hour', 'upcoming', null) returning id as heute \gset
insert into session_students (session_id, student_id, attendance) values (:'heute', :'s1', 'present'), (:'heute', :'s2', 'present');
select pg_temp.als(:'fremd');
select throws_ok(format('select * from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), '42501', null, '4 fremder Coach: kein Zugriff');
select pg_temp.als(:'k1');
select throws_ok(format('select * from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), '42501', null, '4 das Kind: kein Zugriff');
select throws_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'uebernehmen')$$, :'s1', :'heute'), '42501', null,
                 '4 das Kind entscheidet nicht');
select pg_temp.als(:'coach');
select results_eq(format('select skill_key from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), $$values ('z_b'::text)$$,
                  '4 Vorschlag: z_b (3× geübt, noch nicht sicher; z_a nur 1×)');
select is((select count(*)::int from zeigs_mir_offen(:'s2', :'heute')), 0, '4 ohne Übung kein Vorschlag');
select is((select count(*)::int from zeigs_mir_offen(:'s1', :'heute')), 1, '4 zweiter Abruf: derselbe eine Vorschlag');
select throws_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_a', 'uebernehmen')$$, :'s1', :'heute'), '55000', null,
                 '4 nur der vorgeschlagene Skill');
select throws_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'vielleicht')$$, :'s1', :'heute'), '22023', null,
                 '4 nur uebernehmen oder nicht_heute');
select lives_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'uebernehmen')$$, :'s1', :'heute'), '4 Coach übernimmt');
select results_eq(format('select entscheidung, entschieden_von from zeigs_mir_offen(%L, %L)', :'s1', :'heute'),
                  format($$values ('uebernehmen'::text, %L::uuid)$$, :'coach'), '4 gespeichert mit Coach');
select lives_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'nicht_heute')$$, :'s1', :'heute'), '4 änderbar: nicht heute');
reset role;
select pg_temp.als(:'fremd');
select throws_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'uebernehmen')$$, :'s1', :'heute'), '42501', null,
                 '4 fremder Coach entscheidet nicht');
reset role;
select is(zeigs_mir_uebernommen(:'s1', :'heute'), null::text, '4 für C: nicht übernommen (nicht heute)');
select pg_temp.als(:'coach');
select zeigs_mir_entscheiden(:'s1', :'heute', 'z_b', 'uebernehmen');
reset role;
select is(zeigs_mir_uebernommen(:'s1', :'heute'), 'z_b', '4 für C: übernommen z_b');
set local role authenticated;
select throws_ok(format('select zeigs_mir_uebernommen(%L, %L)', :'s1', :'heute'), '42501', null, '4 die Hilfe für C ist intern');
reset role;
select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set beendet_am = now(), status = 'done' where id = :'heute';
select set_config('edvance.session_rpc', '', true);
select pg_temp.als(:'coach');
select throws_ok(format($$select zeigs_mir_entscheiden(%L, %L, 'z_b', 'nicht_heute')$$, :'s1', :'heute'), '55000', null,
                 '4 nach Session-Ende nicht mehr änderbar');
reset role;
select is((select count(*)::int from zeigs_mir where student_id = :'s1' and session_id = :'heute'), 1,
          '4 höchstens ein Vorschlag je Kind und Session');
update lernpfad set stand_system = 'sicher' where student_id = :'s1' and skill_key = 'z_b';
insert into coaching_sessions (coach_id, room, scheduled_at, status) values (:'coach', 'ZZ Raum', now() + interval '2 hours', 'upcoming')
returning id as spaeter \gset
insert into session_students (session_id, student_id, attendance) values (:'spaeter', :'s1', 'present');
select pg_temp.als(:'coach');
select is((select count(*)::int from zeigs_mir_offen(:'s1', :'spaeter')), 0, '4 sicher: kein Vorschlag');
reset role;
update lernpfad set stand_system = 'noch_nicht_sicher' where student_id = :'s1' and skill_key = 'z_b';

-- ── 5) Offen-Regeln ─────────────────────────────────────────────────────────
select pg_temp.als(:'k1');
create temp table offen as select * from kompetenz_offen(get_my_student_id()) where skill_key like 'z\_%';
select results_eq($$select skill_key, zustand, grund from offen order by skill_key$$,
  $$values ('z_a'::text, 'nicht_angeschaut'::text, 'grundlage'::text),   -- Regel 3 (und 5)
           ('z_b', 'noch_nicht_sicher', 'befund'),                         -- Regel 4 vor Regel 2
           ('z_c', 'nicht_angeschaut', 'grundlage'),                       -- Voraussetzung des KA-Stoffs (Regel 3)
           ('z_d', 'nicht_angeschaut', 'start'),                           -- ohne Voraussetzung
           ('z_e', 'gesperrt', null),                                      -- Voraussetzung ohne Befund
           ('z_f', 'nicht_angeschaut', 'voraussetzungen'),                 -- Regel 1
           ('z_g', 'sicher', 'befund'),
           ('z_h', 'nicht_angeschaut', 'aktuell'),                         -- Thema einer bevorstehenden KA (Regel 2)
           ('z_i', 'gesperrt', null)$$,                                    -- KA schon geschrieben: kein aktueller Stoff
  '5 Zustände und Gründe nach Anforderung Themenbaum §3');
select lives_ok($$select kompetenz_offen_merken(get_my_student_id())$$, '5 merken von Hand geht auch');
reset role;
-- Regel 6 über die Trigger, ohne merken: z_e2 (Kl. 10) wird offen, weil z_d sicher wird; dann fällt z_d wieder.
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('z_e2', 'ZZ E2', 'Mathematik', 10, 2);
insert into skill_kante (skill_key, voraussetzt_skill_key) values ('z_e2', 'z_d');
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'s1', 'z_d', 'sicher', 'session');
update lernpfad set stand_system = 'noch_nicht_sicher' where student_id = :'s1' and skill_key = 'z_d';
select is((select zustand || '/' || grund from kompetenz_offen_roh(:'s1') where skill_key = 'z_e2'),
          'nicht_angeschaut/voraussetzungen', '5 Regel 6 über Trigger: offen bleibt offen, ohne dass jemand merken aufruft');
-- Regel 6: Fällt z_g auf „noch nicht sicher“, bleibt z_f offen.
update lernpfad set stand_system = 'noch_nicht_sicher' where student_id = :'s1' and skill_key = 'z_g';
select pg_temp.als(:'k1');
select is((select zustand || '/' || grund from kompetenz_offen(get_my_student_id()) where skill_key = 'z_f'),
          'nicht_angeschaut/voraussetzungen', '5 Regel 6: einmal offen bleibt offen');
-- Übung zuhause ändert keinen Zustand (Abnahme 6).
create temp table vor_uebung as select * from kompetenz_offen(get_my_student_id());
select pg_temp.melden(:'k1', 'z_f', 5, 300);
select is((select count(*)::int from kompetenz_offen(get_my_student_id()) k join vor_uebung v using (skill_key)
            where k.zustand is distinct from v.zustand), 0, '5 eine Home-Quest ändert keinen Zustand');
select throws_ok(format('select * from kompetenz_offen(%L)', :'s2'), '42501', null, '5 fremdes Kind: kein Zugriff');
reset role;

-- ── 6) Pfad ─────────────────────────────────────────────────────────────────
select pg_temp.als(:'k1');
select results_eq($$select wochen_mit_uebung, serie_wochen, quests_diese_woche from home_pfad(get_my_student_id())$$,
                  $$values (case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 1 else 2 end,
                            case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 1 else 2 end,
                            case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 6 else 5 end)$$,
                  '6 Wochen mit Übung, Serie, Quests diese Woche');
reset role;

-- ── 7) Fragen an den Coach ──────────────────────────────────────────────────
select pg_temp.als(:'k1');
select eddie_frage_merken('Warum ist 1 keine Primzahl?') as frage \gset
select throws_ok($$select eddie_frage_merken('   ')$$, '22023', null, '7 leere Frage geht nicht');
select throws_ok(format('select * from coach_fragen_offen(%L)', :'s1'), '42501', null, '7 das Kind liest die Liste nicht');
reset role;
select pg_temp.als(:'fremd');
select throws_ok(format('select coach_frage_erledigt(%L)', :'frage'), '42501', null, '7 fremder Coach erledigt nichts')
 where not akte_aktiv(:'s1');
reset role;
select pg_temp.als(:'k2');
select throws_ok(format('select * from home_pfad(%L)', :'s1'), '42501', null, '7 fremdes Kind: kein Pfad');
reset role;
select pg_temp.als(:'admin');
select results_eq(format('select text from coach_fragen_offen(%L)', :'s1'), $$values ('Warum ist 1 keine Primzahl?'::text)$$,
                  '7 Admin sieht die Frage');
select lives_ok(format('select coach_frage_erledigt(%L)', :'frage'), '7 erledigt');
select is((select count(*)::int from coach_fragen_offen(:'s1')), 0, '7 danach keine offene Frage');
reset role;

-- ── 9) Befund aus der LSA (D2b) ─────────────────────────────────────────────
insert into lsa_sessions (student_id, subject, grade, item_ids, status, completed_at)
values (:'s2', 'Mathematik', 9, '{}', 'completed', now() - interval '1 day') returning id as lsa2 \gset
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
values (:'lsa2', 'z_d', 'traegt', true, false, 2), (:'lsa2', 'z_g', 'traegt_nicht', true, false, 2);
select results_eq(format($$select skill_key, zustand, grund from kompetenz_offen_roh(%L) where skill_key in ('z_d', 'z_e', 'z_g') order by 1$$, :'s2'),
  $$values ('z_d'::text, 'sicher'::text, 'befund'::text), ('z_e', 'nicht_angeschaut', 'voraussetzungen'), ('z_g', 'noch_nicht_sicher', 'befund')$$,
  '9 LSA-Urteile sind Befunde: traegt sicher, traegt_nicht noch nicht sicher');
insert into lernpfad (student_id, skill_key, stand_system, quelle) values (:'s2', 'z_g', 'sicher', 'session');
select is((select zustand from kompetenz_offen_roh(:'s2') where skill_key = 'z_g'), 'sicher', '9 lernpfad (Session) geht vor der LSA');
-- Testlauf-LSA (gibt es nur bei Testkonten): zählt beim Testkind.
update students set ist_test = true where id = :'s3';
insert into lsa_sessions (student_id, subject, grade, item_ids, status, completed_at, testlauf)
values (:'s3', 'Mathematik', 9, '{}', 'completed', now(), true) returning id as lsa3 \gset
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl) values (:'lsa3', 'z_d', 'traegt', true, false, 2);
select is((select zustand from kompetenz_offen_roh(:'s3') where skill_key = 'z_d'), 'sicher', '9 Testlauf zählt beim Testkind');

-- Jüngere LSA schlägt eine reine LSA-Zeile im Lernpfad; Kind über uebernommen_zu_student_id; nicht_angesetzt ist kein Befund.
insert into lernpfad (student_id, skill_key, stand_system, quelle, lsa_session_id) values (:'s2', 'z_a', 'sicher', 'lsa', :'lsa2');
insert into lsa_sessions (student_id, subject, grade, item_ids, status, completed_at)
values (:'s3', 'Mathematik', 9, '{}', 'completed', now()) returning id as lsa4 \gset
update lsa_sessions set uebernommen_zu_student_id = :'s2' where id = :'lsa4';
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
values (:'lsa4', 'z_a', 'traegt_nicht', true, false, 2), (:'lsa4', 'z_b', 'nicht_angesetzt', false, true, 0);
select is((select zustand from kompetenz_offen_roh(:'s2') where skill_key = 'z_a'), 'noch_nicht_sicher',
          '9 die jüngere LSA (übernommen auf das Kind) schlägt die ältere LSA-Zeile im Lernpfad');
select isnt((select zustand from kompetenz_offen_roh(:'s2') where skill_key = 'z_b'), 'noch_nicht_sicher',
            '9 nicht_angesetzt ist kein Befund');
-- Regel 6 bei Herabstufung über die LSA: z_e war offen (z_d sicher per LSA), dann trägt z_d in einer neuen LSA nicht.
select is((select zustand from kompetenz_offen_roh(:'s2') where skill_key = 'z_e'), 'nicht_angeschaut', '9 Grundlage: z_e offen');
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
values (:'lsa4', 'z_d', 'traegt_nicht', true, false, 2);
select is((select zustand || '/' || grund from kompetenz_offen_roh(:'s2') where skill_key = 'z_e'), 'nicht_angeschaut/voraussetzungen',
          '9 Regel 6: nach Herabstufung per LSA bleibt z_e offen');

-- ── 8) Append-only ──────────────────────────────────────────────────────────
alter table home_uebung enable trigger home_uebung_append_only;
select throws_ok($$update home_uebung set aufgaben = 1$$, '42501', null, '8 home_uebung: kein Update');
select throws_ok($$delete from home_uebung$$, '42501', null, '8 home_uebung: kein Delete');

select * from finish();
rollback;
