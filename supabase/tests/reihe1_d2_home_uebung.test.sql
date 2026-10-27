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

insert into auth.users (id, email, instance_id, aud, role)
select u, 'd2-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'coach', 'coach'), (:'fremd', 'fremd'), (:'k1', 'k1'), (:'k2', 'k2')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'd2-admin@test.local', 'admin', 'ZZ Admin'), (:'coach', 'd2-coach@test.local', 'coach', 'ZZ Coach'),
  (:'fremd', 'd2-fremd@test.local', 'coach', 'ZZ Fremd'),
  (:'k1', 'd2-k1@test.local', 'student', 'Batu Test'), (:'k2', 'd2-k2@test.local', 'student', 'Mira Test');

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;
create or replace function pg_temp.kind(p_profil uuid) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values ('ZZ Kind', 'ZZ', 'vertrag', 9) returning id into v_lead;
  insert into students (class_level, profile_id) values (9, p_profil) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname)
  select v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 30, 'vor_ort', v_st,
         date_trunc('month', current_date)::date, current_date + 300, date_trunc('month', current_date)::date + 13,
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

-- ── 2) Nichts ändert sich ───────────────────────────────────────────────────
reset role;
select to_regprocedure('public.aufgabe_werten(uuid,jsonb)') is null as attrappe \gset
\if :attrappe
  -- A ist noch nicht auf dev: Attrappe nur in dieser Transaktion (Konzept §9).
  create function public.aufgabe_werten(p_task uuid, p_antwort jsonb)
  returns table (richtig boolean, fehlbild_key text, rueckmeldung text) language sql stable as $f$ select true, null::text, null::text $f$;
\endif
create temp table vorher as select * from pg_temp.zeilen();
select pg_temp.als(:'k1');
select count(*) from aufgabe_werten(gen_random_uuid(), '{"eingabe":{"text":"2·3·3"}}'::jsonb);
reset role;
select is((select count(*)::int from pg_temp.zeilen() z join vorher v using (t) where z.n <> v.n), 0,
          '2 eine Wertung über aufgabe_werten ändert keine Tabelle');
drop table vorher;
create temp table vorher as select * from pg_temp.zeilen();
select pg_temp.als(:'k1');
select home_uebung_melden('z_b', 5, 300);
reset role;
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
select pg_temp.als(:'k1');
select home_uebung_melden('z_b', 5, 300);
select home_uebung_melden('z_b', 4, 200);
select home_uebung_melden('z_a', 5, 250);
select results_eq($$select skill_key, quests, aufgaben, dauer_sek from home_uebung_kurz((select get_my_student_id()))$$,
                  $$values ('z_b'::text, 2, 9, 500), ('z_a'::text, 1, 5, 250)$$, '3 seit der letzten Session: z_b 2×, z_a 1×');
select is((select quests from home_uebung_kurz(get_my_student_id(), '-infinity') where skill_key = 'z_b'), 3,
          '3 mit p_seit: auch die ältere Meldung');
select throws_ok(format('select * from home_uebung_kurz(%L)', :'s2'), '42501', null, '3 ein Kind liest nie die Übung eines anderen');
reset role;
select pg_temp.als(:'admin');
select is((select count(*)::int from home_uebung_kurz(:'s1')), 2, '3 Admin liest');
reset role;

-- ── 4) Zeig's mir ───────────────────────────────────────────────────────────
insert into coaching_sessions (coach_id, room, scheduled_at, status, gestartet_am)
values (:'coach', 'ZZ Raum', now() + interval '1 hour', 'upcoming', null) returning id as heute \gset
insert into session_students (session_id, student_id, attendance) values (:'heute', :'s1', 'present'), (:'heute', :'s2', 'present');
select pg_temp.als(:'fremd');
select throws_ok(format('select * from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), '42501', null, '4 fremder Coach: kein Zugriff');
select pg_temp.als(:'k1');
select throws_ok(format('select * from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), '42501', null, '4 das Kind: kein Zugriff');
select pg_temp.als(:'coach');
select results_eq(format('select skill_key from zeigs_mir_offen(%L, %L)', :'s1', :'heute'), $$values ('z_b'::text)$$,
                  '4 Vorschlag: z_b (2× geübt, noch nicht sicher)');
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
           ('z_c', 'gesperrt', null),                                      -- Kl. 10, Voraussetzung nicht sicher
           ('z_d', 'nicht_angeschaut', 'start'),                           -- ohne Voraussetzung
           ('z_e', 'gesperrt', null),                                      -- Voraussetzung ohne Befund
           ('z_f', 'nicht_angeschaut', 'voraussetzungen'),                 -- Regel 1
           ('z_g', 'sicher', 'befund')$$,
  '5 Zustände und Gründe nach Anforderung Themenbaum §3');
select is(kompetenz_offen_merken(get_my_student_id()) > 0, true, '5 merken schreibt Offenes fest');
reset role;
-- Regel 6: Fällt z_g auf „noch nicht sicher“, bleibt z_f offen.
update lernpfad set stand_system = 'noch_nicht_sicher' where student_id = :'s1' and skill_key = 'z_g';
select pg_temp.als(:'k1');
select is((select zustand || '/' || grund from kompetenz_offen(get_my_student_id()) where skill_key = 'z_f'),
          'nicht_angeschaut/voraussetzungen', '5 Regel 6: einmal offen bleibt offen');
-- Übung zuhause ändert keinen Zustand (Abnahme 6).
create temp table vor_uebung as select * from kompetenz_offen(get_my_student_id());
select home_uebung_melden('z_c', 5, 300);
select is((select count(*)::int from kompetenz_offen(get_my_student_id()) k join vor_uebung v using (skill_key)
            where k.zustand is distinct from v.zustand), 0, '5 eine Home-Quest ändert keinen Zustand');
select throws_ok(format('select * from kompetenz_offen(%L)', :'s2'), '42501', null, '5 fremdes Kind: kein Zugriff');
reset role;

-- ── 6) Pfad ─────────────────────────────────────────────────────────────────
select pg_temp.als(:'k1');
select results_eq($$select wochen_mit_uebung, serie_wochen, quests_diese_woche from home_pfad(get_my_student_id())$$,
                  $$values (case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 1 else 2 end,
                            case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 1 else 2 end,
                            case when date_trunc('week', now() - interval '2 days') = date_trunc('week', now()) then 5 else 4 end)$$,
                  '6 Wochen mit Übung, Serie, Quests diese Woche');
reset role;

-- ── 7) Fragen an den Coach ──────────────────────────────────────────────────
select pg_temp.als(:'k1');
select eddie_frage_merken('Warum ist 1 keine Primzahl?') as frage \gset
select throws_ok($$select eddie_frage_merken('   ')$$, '22023', null, '7 leere Frage geht nicht');
select throws_ok(format('select * from coach_fragen_offen(%L)', :'s1'), '42501', null, '7 das Kind liest die Liste nicht');
reset role;
select pg_temp.als(:'admin');
select results_eq(format('select text from coach_fragen_offen(%L)', :'s1'), $$values ('Warum ist 1 keine Primzahl?'::text)$$,
                  '7 Admin sieht die Frage');
select lives_ok(format('select coach_frage_erledigt(%L)', :'frage'), '7 erledigt');
select is((select count(*)::int from coach_fragen_offen(:'s1')), 0, '7 danach keine offene Frage');
reset role;

select * from finish();
rollback;
