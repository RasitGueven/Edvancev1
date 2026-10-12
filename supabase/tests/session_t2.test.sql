-- ============================================================================
-- T2: Testlauf-Schalter, kein Lernpfad im Testlauf, drei Haertungen
-- (Bauauftrag Session-Rahmen P1, Paket T2).
--
--   1) session_testlauf_setzen: Admin setzt und nimmt vor dem Start; nach dem Start 55000;
--      Coach und Konto ohne Profil 42501; echtes Kind gebucht -> 22023 wie bisher.
--   2) pfad_entscheiden, eingriff_notieren (Stufe 4), pfad_tiefer, mastery_entscheiden:
--      echte Session schreibt wie vorher; Testlauf schreibt keine Zeile in lernpfad oder
--      lernpfad_protokoll, aber dasselbe Session-Ereignis.
--   3) erklaer_status_setzen und lsa_uebernahme mit NULL; authoring_review_meta ohne anon.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(54);

\ir session_a2_fixture.sql

-- Fingerabdruck des Lernpfads eines Kindes (Zeilen und Inhalt).
create or replace function pg_temp.pfad(p_kind uuid) returns text language sql as $$
  select coalesce((select md5(string_agg(to_jsonb(l)::text, '|' order by l.skill_key))
                     from lernpfad l where l.student_id = p_kind), '-')
      || '/' || (select count(*) from lernpfad_protokoll p where p.student_id = p_kind)
$$;
-- Payload des letzten Session-Ereignisses eines Typs.
create or replace function pg_temp.ereignis(p_s uuid, p_typ text) returns jsonb language sql as $$
  select e.payload from session_ereignisse e where e.session_id = p_s and e.typ = p_typ order by e.id desc limit 1
$$;

-- ── 1) Schalter ───────────────────────────────────────────────────────────
select pg_temp.kind_mit('ZZ T2 Test', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_t0,
       pg_temp.kind_mit('ZZ T2 Echt', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_e0
\gset
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ T2 Schalter', now() + interval '1 day')
returning id as s_sch \gset
insert into session_students (session_id, student_id) values (:'s_sch', :'k_t0');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ T2 Echt gebucht', now() + interval '1 day')
returning id as s_echt \gset
insert into session_students (session_id, student_id) values (:'s_echt', :'k_e0');

select lives_ok(format('select session_testlauf_setzen(%L, true)', :'s_sch'), '1 Admin setzt Testlauf vor dem Start');
select is((select testlauf from coaching_sessions where id = :'s_sch'), true, '1 Testlauf ist an');
select lives_ok(format('select session_testlauf_setzen(%L, false)', :'s_sch'), '1 Admin nimmt Testlauf vor dem Start');
select is((select testlauf from coaching_sessions where id = :'s_sch'), false, '1 Testlauf ist aus');
select throws_ok(format('select session_testlauf_setzen(%L, true)', :'s_echt'), '22023', 'Testlauf: nur mit Testkonten',
                 '1 echtes Kind gebucht -> 22023 (Trigger, wie bisher)');
select throws_ok(format('select session_testlauf_setzen(%L, true)', gen_random_uuid()), 'P0002', null,
                 '1 unbekannte Session -> P0002');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('select session_testlauf_setzen(%L, true)', :'s_sch'), '42501', null, '1 Coach der Session -> 42501');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select session_testlauf_setzen(%L, true)', :'s_sch'), '42501', null, '1 Konto ohne Profil -> 42501');

-- Nach dem Start: weder setzen noch nehmen.
select pg_temp.act_as(:'admin');
select session_testlauf_setzen(:'s_sch', true);
select pg_temp.act_as(:'coach_a');
select session_starten(:'s_sch') is not null as gestartet \gset
select pg_temp.act_as(:'admin');
select throws_ok(format('select session_testlauf_setzen(%L, false)', :'s_sch'), '55000', 'session_testlauf_setzen: Session ist schon gestartet',
                 '1 nach dem Start nehmen -> 55000');
select throws_ok(format('select session_testlauf_setzen(%L, true)', :'s_sch'), '55000', null,
                 '1 nach dem Start setzen (auch derselbe Wert) -> 55000');
select is((select testlauf from coaching_sessions where id = :'s_sch'), true, '1 Testlauf bleibt nach dem Start, wie er war');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('select session_testlauf_setzen(%L, false)', :'s_sch'), '42501', null,
                 '1 Coach nach dem Start -> 42501 (Tor vor der Startpruefung)');
select set_config('request.jwt.claims', '', true);

-- ── 2a) „Eine Stufe tiefer“ (pfad_entscheiden -> pfad_tiefer) ──────────────
-- Wie A2 Fall 4: zwei Fehler im Warm-up -> Entscheidungssignal -> Coach bestaetigt.
select pg_temp.kind_mit('ZZ T2 Mila echt', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_me,
       pg_temp.kind_mit('ZZ T2 Mila test', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_mt
\gset

select pg_temp.neue_session(array[:'k_me']::uuid[], 6) as s_pe \gset
select pg_temp.checkin(:'s_pe', 1);
select pg_temp.lauf(:'s_pe', 1, 4, false);
select pg_temp.pfad(:'k_me') as pe_vor \gset
select pg_temp.act_as(:'coach_a');
select lives_ok(format($$select pfad_entscheiden(%L, %L, 'tiefer')$$, :'s_pe', :'k_me'), '2a echt: Coach bestaetigt eine Stufe tiefer');
select isnt(pg_temp.pfad(:'k_me'), :'pe_vor'::text, '2a echt: Lernpfad geaendert');
select is((select count(*)::int from lernpfad_protokoll where session_id = :'s_pe' and aktion = 'pfad_tiefer'), 1,
          '2a echt: eine Protokollzeile pfad_tiefer');
select pg_temp.ereignis(:'s_pe', 'entscheidung_pfad') as pe_ev \gset
select is((select stand_system from lernpfad where student_id = :'k_me' and skill_key = 'zz_a2_v1'), 'aktiv', '2a echt: Voraussetzung aktiv');
select pg_temp.schritt(:'s_pe', 1) ->> 'skill_key' as pe_next \gset
select is(:'pe_next'::text, 'zz_a2_v1', '2a echt: naechster Schritt eine Stufe tiefer');

select pg_temp.neue_session(array[:'k_mt']::uuid[], 6, true) as s_pt \gset
select is((select testlauf from coaching_sessions where id = :'s_pt'), true, '2a Testlauf-Session');
select pg_temp.checkin(:'s_pt', 1);
select pg_temp.lauf(:'s_pt', 1, 4, false);
select pg_temp.pfad(:'k_mt') as pt_vor \gset
select pg_temp.act_as(:'coach_a');
select lives_ok(format($$select pfad_entscheiden(%L, %L, 'tiefer')$$, :'s_pt', :'k_mt'), '2a Testlauf: Coach bestaetigt eine Stufe tiefer');
select is(pg_temp.pfad(:'k_mt'), :'pt_vor'::text, '2a Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');
select is((select count(*)::int from lernpfad_protokoll where session_id = :'s_pt'), 0, '2a Testlauf: kein Protokoll mit dieser Session');
select is(pg_temp.ereignis(:'s_pt', 'entscheidung_pfad'), :'pe_ev'::jsonb, '2a Testlauf: dasselbe Ereignis entscheidung_pfad');
select is(pg_temp.ereignis(:'s_pt', 'signal_erledigt'), pg_temp.ereignis(:'s_pe', 'signal_erledigt'),
          '2a Testlauf: dasselbe Ereignis signal_erledigt');
-- Offener Punkt T2-1: Der Planer liest „tiefer“ aus lernpfad/lernpfad_protokoll. Ohne Zeile
-- bleibt der naechste Schritt im Testlauf beim bisherigen Skill. Haelt den Stand fest; kippt,
-- sobald der Planer die Entscheidung aus der Session liest (dann Erwartung auf zz_a2_v1).
select pg_temp.schritt(:'s_pt', 1) ->> 'skill_key' as pt_next \gset
select diag('2a Testlauf: naechster Schritt nach „tiefer“ = ' || coalesce(:'pt_next', 'NULL') || ' (echt: ' || :'pe_next' || ')');
select is(:'pt_next'::text, 'zz_a2_s1', '2a Testlauf: naechster Schritt bleibt beim bisherigen Skill (offener Punkt T2-1)');

-- ── 2b) Eingriff Stufe 4 (eingriff_notieren -> pfad_tiefer) ────────────────
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_t2_fb', 'ZZ T2 Fehlbild', now());
select pg_temp.kind_mit('ZZ T2 Ben echt', 'zz_a2_terme', '{zz_a2_v1}', '{zz_a2_s1}') as k_be,
       pg_temp.kind_mit('ZZ T2 Ben test', 'zz_a2_terme', '{zz_a2_v1}', '{zz_a2_s1}', true) as k_bt
\gset
insert into lernpfad (student_id, skill_key, stand_system, quelle)
select k, 'zz_a2_v2', 'noch_nicht_sicher', 'lsa' from unnest(array[:'k_be', :'k_bt']::uuid[]) k;

select pg_temp.neue_session(array[:'k_be']::uuid[], 20) as s_ee \gset
select pg_temp.checkin(:'s_ee', 1);
select pg_temp.schritt(:'s_ee', 1) ->> 'skill_key' as ee_vor_next \gset
select pg_temp.pfad(:'k_be') as ee_vor \gset
select pg_temp.act_as(:'coach_a');
select lives_ok(format($$select eingriff_notieren(%L, %L, 4, 'zz_t2_fb')$$, :'s_ee', :'k_be'), '2b echt: Stufe 4 notiert');
select isnt(pg_temp.pfad(:'k_be'), :'ee_vor'::text, '2b echt: Lernpfad geaendert');
select is((select anlass || ':' || skill_key from lernpfad_protokoll where session_id = :'s_ee' and aktion = 'pfad_tiefer'),
          'eingriff:zz_a2_v2', '2b echt: pfad_tiefer(anlass = eingriff) protokolliert');
select pg_temp.ereignis(:'s_ee', 'eingriff') as ee_ev1, pg_temp.ereignis(:'s_ee', 'entscheidung_pfad') as ee_ev2 \gset

select pg_temp.neue_session(array[:'k_bt']::uuid[], 20, true) as s_et \gset
select pg_temp.checkin(:'s_et', 1);
select pg_temp.schritt(:'s_et', 1) ->> 'skill_key' as et_vor_next \gset
select is(:'et_vor_next'::text, :'ee_vor_next'::text, '2b Testlauf: vor dem Eingriff derselbe Skill wie echt');
select pg_temp.pfad(:'k_bt') as et_vor \gset
select pg_temp.act_as(:'coach_a');
select lives_ok(format($$select eingriff_notieren(%L, %L, 4, 'zz_t2_fb')$$, :'s_et', :'k_bt'), '2b Testlauf: Stufe 4 notiert');
select is(pg_temp.pfad(:'k_bt'), :'et_vor'::text, '2b Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');
select is(pg_temp.ereignis(:'s_et', 'eingriff'), :'ee_ev1'::jsonb, '2b Testlauf: dasselbe Ereignis eingriff');
select is(pg_temp.ereignis(:'s_et', 'entscheidung_pfad'), :'ee_ev2'::jsonb,
          '2b Testlauf: dasselbe Ereignis entscheidung_pfad (mit Voraussetzung)');

-- ── 2c) pfad_tiefer direkt ─────────────────────────────────────────────────
select pg_temp.pfad(:'k_bt') as pd_vor \gset
select pg_temp.act_as(:'coach_a');
select is(pfad_tiefer(:'k_bt', 'zz_a2_s1', :'s_et', null, 'eingriff'), 'zz_a2_v2', '2c Testlauf: pfad_tiefer liefert das Ziel wie echt');
select is(pg_temp.pfad(:'k_bt'), :'pd_vor'::text, '2c Testlauf: pfad_tiefer schreibt nichts');
select throws_ok(format($$select pfad_tiefer(%L, 'zz_a2_s1', %L, null, 'quatsch')$$, :'k_bt', :'s_et'), '22023', null,
                 '2c Testlauf: Pruefungen bleiben (ungueltiger Anlass -> 22023)');
select pg_temp.act_as(:'coach_b');
select throws_ok(format($$select pfad_tiefer(%L, 'zz_a2_s1', %L, null, 'eingriff')$$, :'k_bt', :'s_et'), '42501', null,
                 '2c Testlauf: fremder Coach -> 42501 wie echt');

-- ── 2d) mastery_entscheiden ────────────────────────────────────────────────
update lernpfad set stand_system = 'kandidat' where student_id in (:'k_be', :'k_bt') and skill_key = 'zz_a2_v1';
select pg_temp.pfad(:'k_be') as me_vor, pg_temp.pfad(:'k_bt') as mt_vor \gset
select count(*) as ev_e from session_ereignisse where session_id = :'s_ee' \gset
select count(*) as ev_t from session_ereignisse where session_id = :'s_et' \gset
select pg_temp.act_as(:'coach_a');
select mastery_entscheiden(:'k_be', 'zz_a2_v1', 'gemeistert', null, :'s_ee') as m_echt \gset
select is((select stand_coach from lernpfad where student_id = :'k_be' and skill_key = 'zz_a2_v1'), 'gemeistert',
          '2d echt: stand_coach = gemeistert');
select is((select count(*)::int from lernpfad_protokoll where session_id = :'s_ee' and aktion = 'mastery'), 1, '2d echt: Protokollzeile mastery');
select mastery_entscheiden(:'k_bt', 'zz_a2_v1', 'gemeistert', null, :'s_et') as m_test \gset
select is(:'m_test'::jsonb, :'m_echt'::jsonb, '2d Testlauf: dieselbe Antwort');
select is(pg_temp.pfad(:'k_bt'), :'mt_vor'::text, '2d Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');
select is(array[(select count(*) from session_ereignisse where session_id = :'s_ee') - :ev_e,
                (select count(*) from session_ereignisse where session_id = :'s_et') - :ev_t]::int[], array[0, 0],
          '2d mastery_entscheiden schreibt in beiden Faellen kein Session-Ereignis');
select throws_ok(format($$select mastery_entscheiden(%L, 'zz_a2_v1', 'vertagt', null, %L)$$, :'k_bt', :'s_et'), '22023', null,
                 '2d Testlauf: Pruefungen bleiben (Vertagen ohne Grund -> 22023)');

-- ── 3) Haertungen ──────────────────────────────────────────────────────────
update profiles set darf_pruefen = true where id = :'coach_b';
select k.id as kern, k.pruef_version as kern_v from erklaer_kernidee k where k.skill_key = 'zz_a2_n1' \gset
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select erklaer_status_setzen(%L, %L, null, %s)', 'kernidee', :'kern', :kern_v), '22023', null,
                 '3 erklaer_status_setzen: Pruefer ohne Admin, Status NULL -> 22023 (vorher 23502)');
select pg_temp.act_as(:'admin');
select throws_ok(format('select erklaer_status_setzen(%L, %L, null, %s)', 'kernidee', :'kern', :kern_v), '22023', null,
                 '3 erklaer_status_setzen: Admin, Status NULL -> 22023');
select throws_ok(format('select erklaer_status_setzen(null, %L, %L, %s)', :'kern', 'geprueft', :kern_v), '22023', null,
                 '3 erklaer_status_setzen: Objekt NULL -> 22023');
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select erklaer_status_setzen(%L, %L, %L, %s)', 'kernidee', :'kern', 'geprueft', :kern_v), '42501', null,
                 '3 erklaer_status_setzen: Pruefer nimmt Freigabe nicht zurueck (unveraendert 42501)');
select pg_temp.act_as(:'admin');
select lives_ok(format('select erklaer_status_setzen(%L, %L, %L, %s)', 'kernidee', :'kern', 'geprueft', :kern_v),
                '3 erklaer_status_setzen: Admin wie bisher');

select pg_temp.als_system();
insert into lsa_sessions (student_id, subject, grade, status, completed_at, modus)
values (:'k_e0', 'mathematik', 8, 'completed', now() - interval '1 day', 'adaptiv') returning id as lsa \gset
insert into lsa_skill_urteil (session_id, skill_key, zustand, belegt_direkt, offen, proben_anzahl)
values (:'lsa', 'zz_a2_s1', 'traegt_nicht', true, false, 3);
select pg_temp.act_as(:'admin');
select throws_ok(format('select lsa_uebernahme(%L, null)', :'lsa'), '22023', 'lsa_uebernahme: Schueler fehlt',
                 '3 lsa_uebernahme: Schueler NULL -> 22023');
select is(lsa_uebernahme(:'lsa', :'k_e0') ->> 'fokus_erzeugt', '1', '3 lsa_uebernahme: Admin mit Schueler wie bisher');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select lsa_uebernahme(%L, null)', :'lsa'), '42501', null, '3 lsa_uebernahme: ohne Profil bleibt 42501 (Tor zuerst)');

select is(has_function_privilege('anon', 'public.authoring_review_meta()', 'execute'), false,
          '3 authoring_review_meta: anon ohne EXECUTE');
select is(array[has_function_privilege('authenticated', 'public.authoring_review_meta()', 'execute'),
                has_function_privilege('service_role', 'public.authoring_review_meta()', 'execute')], array[true, true],
          '3 authoring_review_meta: authenticated und service_role behalten EXECUTE');
select pg_temp.act_as(:'admin');
set local role authenticated;
select ok((select count(*) > 0 from authoring_review_meta()), '3 authoring_review_meta: angemeldeter Admin liest wie bisher');
reset role;
set local role anon;
select throws_ok('select * from authoring_review_meta()', '42501', null, '3 authoring_review_meta: anon -> 42501');
reset role;

select * from finish();
rollback;
