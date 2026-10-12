-- ============================================================================
-- T4: Testlauf wie echt im Plan, Pruefragen, Auswahl-Regel, Beleg, Schalter, kein_ziel
-- (Bauauftrag Session-Rahmen P1, Paket T4; Entscheidungen Rasit 12.10.2026).
--
--   1) „Tiefer gehen“ (pfad_entscheiden, eingriff_notieren Stufe 4): im Testlauf springt der Plan wie in der
--      echten Session, ohne Zeile in lernpfad/lernpfad_protokoll; Fall Thema und Fall Lernpfad.
--   2) Pruefrage: im Testlauf auch im Entwurf (Tablet, Coach-Sicht, aufs Tablet legen); echt nur freigegeben.
--   3) Auswahl: session_im_pool, lsa_im_pool, erklaer_checks gleich der bisherigen Inline-Regel.
--   4) lernpfad_beleg: im Testlauf keine Zeile; echt wie bisher.
--   5) coaching_sessions.testlauf direkt: vor dem Start wie bisher, danach 55000.
--   6) kein_ziel als erster Schritt: genau eine Zeile in session_schritte, auch nach dem naechsten Takt.
-- Zusicherungen mit „echt“ sind vor und nach T4 gruen (unveraendert); die Testlauf-Zusicherungen zu 1, 2, 4, 5
-- und 6 sind vor T4 rot.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(57);

\ir session_a2_fixture.sql

-- Fingerabdruck des Lernpfads eines Kindes (Zeilen und Inhalt) und seiner Belege.
create or replace function pg_temp.pfad(p_kind uuid) returns text language sql as $$
  select coalesce((select md5(string_agg(to_jsonb(l)::text, '|' order by l.skill_key))
                     from lernpfad l where l.student_id = p_kind), '-')
      || '/' || (select count(*) from lernpfad_protokoll p where p.student_id = p_kind)
      || '/' || (select count(*) from lernpfad_belege b where b.student_id = p_kind)
$$;
-- Ergebnis eines Aufrufs oder sein Fehlercode (damit ein Lauf gegen den alten Stand alle Zusicherungen zeigt).
create or replace function pg_temp.versuch(p_sql text) returns text language plpgsql as $$
declare v text;
begin
  execute p_sql into v;
  return v;
exception when others then
  return sqlstate;
end $$;
-- Zielliste ohne Kind-spezifische Spalten (zum Vergleich echt/Testlauf).
create or replace function pg_temp.ziel(p_s uuid, p_kind uuid) returns text language sql as $$
  select string_agg(z.skill_key || ':' || z.rolle || ':' || z.stand || ':' || z.offen, ',' order by z.reihenfolge)
    from session_zielliste(p_s, p_kind) z
$$;

-- ── 1a) „Tiefer“ nach dem Entscheidungssignal, Fall Thema (wie T2 2a) ─────────
select pg_temp.kind_mit('ZZ T4 Mila echt', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_me,
       pg_temp.kind_mit('ZZ T4 Mila test', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_mt
\gset
select pg_temp.neue_session(array[:'k_me']::uuid[], 6) as s_pe \gset
select pg_temp.checkin(:'s_pe', 1);
select pg_temp.lauf(:'s_pe', 1, 4, false);
select pg_temp.act_as(:'coach_a');
select pfad_entscheiden(:'s_pe', :'k_me', 'tiefer');
select pg_temp.ziel(:'s_pe', :'k_me') as pe_ziel \gset
select pg_temp.schritt(:'s_pe', 1) ->> 'skill_key' as pe_next \gset
select is(:'pe_next'::text, 'zz_a2_v1', '1a echt: naechster Schritt eine Stufe tiefer');
select is((select count(*)::int from lernpfad_protokoll where session_id = :'s_pe' and aktion = 'pfad_tiefer'), 1,
          '1a echt: eine Protokollzeile pfad_tiefer');
select string_agg(x ->> 'skill_key', ',') as pe_lauf from pg_temp.lauf(:'s_pe', 1, 3, true) x \gset

select pg_temp.neue_session(array[:'k_mt']::uuid[], 6, true) as s_pt \gset
select pg_temp.checkin(:'s_pt', 1);
select pg_temp.lauf(:'s_pt', 1, 4, false);
select pg_temp.pfad(:'k_mt') as pt_vor \gset
select pg_temp.act_as(:'coach_a');
select pfad_entscheiden(:'s_pt', :'k_mt', 'tiefer');
select is(pg_temp.ziel(:'s_pt', :'k_mt'), :'pe_ziel'::text, '1a Testlauf: nach „tiefer“ dieselbe Zielliste wie echt');
select pg_temp.schritt(:'s_pt', 1) ->> 'skill_key' as pt_next \gset
select is(:'pt_next'::text, 'zz_a2_v1', '1a Testlauf: naechster Schritt eine Stufe tiefer (zz_a2_s1 -> zz_a2_v1)');
select is(pg_temp.pfad(:'k_mt'), :'pt_vor'::text, '1a Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');
select is((select count(*)::int from lernpfad_protokoll where session_id = :'s_pt'), 0, '1a Testlauf: kein Protokoll der Session');
-- Weiter wie echt: drei weitere Schritte, dieselben Skills.
select is((select string_agg(x ->> 'skill_key', ',') from pg_temp.lauf(:'s_pt', 1, 3, true) x), :'pe_lauf'::text,
          '1a Testlauf: die naechsten drei Schritte wie echt');
select is(pg_temp.pfad(:'k_mt'), :'pt_vor'::text, '1a Testlauf: auch danach kein Lernpfad');

-- ── 1b) Eingriff Stufe 4 (eingriff_notieren -> pfad_tiefer), Fall Thema (wie T2 2b) ─
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_t4_fb', 'ZZ T4 Fehlbild', now());
select pg_temp.kind_mit('ZZ T4 Ben echt', 'zz_a2_terme', '{zz_a2_v1}', '{zz_a2_s1}') as k_be,
       pg_temp.kind_mit('ZZ T4 Ben test', 'zz_a2_terme', '{zz_a2_v1}', '{zz_a2_s1}', true) as k_bt
\gset
insert into lernpfad (student_id, skill_key, stand_system, quelle)
select k, 'zz_a2_v2', 'noch_nicht_sicher', 'lsa' from unnest(array[:'k_be', :'k_bt']::uuid[]) k;
select pg_temp.neue_session(array[:'k_be']::uuid[], 20) as s_ee \gset
select pg_temp.checkin(:'s_ee', 1);
select pg_temp.schritt(:'s_ee', 1) ->> 'skill_key' as ee_vor_next \gset
select pg_temp.act_as(:'coach_a');
select eingriff_notieren(:'s_ee', :'k_be', 4, 'zz_t4_fb');
select pg_temp.ziel(:'s_ee', :'k_be') as ee_ziel \gset
select pg_temp.antwort(:'s_ee', 1, true);
select pg_temp.schritt(:'s_ee', 1) ->> 'skill_key' as ee_next \gset
select isnt(:'ee_next'::text, :'ee_vor_next'::text, '1b echt: nach dem Eingriff ein anderer Skill');

select pg_temp.neue_session(array[:'k_bt']::uuid[], 20, true) as s_et \gset
select pg_temp.checkin(:'s_et', 1);
select pg_temp.schritt(:'s_et', 1) ->> 'skill_key' as et_vor_next \gset
select pg_temp.pfad(:'k_bt') as et_vor \gset
select pg_temp.act_as(:'coach_a');
select eingriff_notieren(:'s_et', :'k_bt', 4, 'zz_t4_fb');
select is(pg_temp.ziel(:'s_et', :'k_bt'), :'ee_ziel'::text, '1b Testlauf: nach dem Eingriff dieselbe Zielliste wie echt');
select pg_temp.antwort(:'s_et', 1, true);
select is(pg_temp.schritt(:'s_et', 1) ->> 'skill_key', :'ee_next'::text, '1b Testlauf: naechster Schritt wie echt');
select is(pg_temp.pfad(:'k_bt'), :'et_vor'::text, '1b Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');

-- Eingriff, bei dem pfad_tiefer scheitert (alle Voraussetzungen sicher): Ereignis ohne Voraussetzung, Plan bleibt.
select pg_temp.kind_mit('ZZ T4 Eva test', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}', true) as k_ft \gset
select pg_temp.neue_session(array[:'k_ft']::uuid[], 20, true) as s_ft \gset
select pg_temp.checkin(:'s_ft', 1);
select pg_temp.ziel(:'s_ft', :'k_ft') as ft_vor \gset
select pg_temp.act_as(:'coach_a');
select eingriff_notieren(:'s_ft', :'k_ft', 4, 'zz_t4_fb');
select is((select count(*)::int from session_ereignisse where session_id = :'s_ft' and typ = 'entscheidung_pfad'
            and payload ? 'fehler' and not payload ? 'voraussetzung'), 1, '1b Testlauf: gescheiterter Eingriff ohne Voraussetzung');
select is(pg_temp.ziel(:'s_ft', :'k_ft'), :'ft_vor'::text, '1b Testlauf: gescheiterter Eingriff aendert den Plan nicht');
select set_config('request.jwt.claims', '', true);
select is(pg_temp.versuch(format($$select md5(string_agg(to_jsonb(x)::text, '|' order by x.skill_key)) from lernpfad_sicht(%L, null) x$$, :'k_ft')),
          (select md5(string_agg(to_jsonb(l)::text, '|' order by l.skill_key)) from lernpfad l where l.student_id = :'k_ft'),
          '1 lernpfad_sicht ohne Session: genau lernpfad (alle Spalten)');

-- ── 1c) Fall Lernpfad (kein Thema): naechste Luecke ──────────────────────────
select pg_temp.kind_mit('ZZ T4 Lia echt', null, '{zz_a2_v2}') as k_le,
       pg_temp.kind_mit('ZZ T4 Lia test', null, '{zz_a2_v2}', '{}', true) as k_lt
\gset
insert into lernpfad (student_id, skill_key, stand_system, quelle)
select k, 'zz_a2_s1', 'noch_nicht_sicher', 'lsa' from unnest(array[:'k_le', :'k_lt']::uuid[]) k;
select pg_temp.neue_session(array[:'k_le']::uuid[], 20) as s_le \gset
select pg_temp.checkin(:'s_le', 1);
select pg_temp.ziel(:'s_le', :'k_le') as le_vor \gset
select pg_temp.act_as(:'coach_a');
select pfad_entscheiden(:'s_le', :'k_le', 'tiefer');
select pg_temp.ziel(:'s_le', :'k_le') as le_nach \gset
select isnt(:'le_nach'::text, :'le_vor'::text, '1c echt: Luecke nach „tiefer“ geaendert');
select pg_temp.schritt(:'s_le', 1) ->> 'skill_key' as le_next \gset
select pg_temp.neue_session(array[:'k_lt']::uuid[], 20, true) as s_lt \gset
select pg_temp.checkin(:'s_lt', 1);
select is(pg_temp.ziel(:'s_lt', :'k_lt'), :'le_vor'::text, '1c Testlauf: vor „tiefer“ dieselbe Luecke wie echt');
select pg_temp.pfad(:'k_lt') as lt_vor \gset
select pg_temp.act_as(:'coach_a');
select pfad_entscheiden(:'s_lt', :'k_lt', 'tiefer');
select is(pg_temp.ziel(:'s_lt', :'k_lt'), :'le_nach'::text, '1c Testlauf: nach „tiefer“ dieselbe Luecke wie echt');
select is(pg_temp.schritt(:'s_lt', 1) ->> 'skill_key', :'le_next'::text,
          '1c Testlauf: naechster Schritt wie echt');
select is(pg_temp.pfad(:'k_lt'), :'lt_vor'::text, '1c Testlauf: keine Zeile in lernpfad oder lernpfad_protokoll');

-- ── 2) Pruefrage im Testlauf auch im Entwurf ─────────────────────────────────
-- zz_a2_k1: aelterer Entwurf; zz_a2_k2: Entwurf (aelter) und freigegeben (neuer).
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle, angelegt) values
  ('zz_a2_k1', 'ZZ T4 Entwurf k1', 'E', 'K', 'entwurf', 'ki', now() - interval '2 days'),
  ('zz_a2_k2', 'ZZ T4 Entwurf k2', 'E', 'K', 'entwurf', 'ki', now() - interval '2 days'),
  ('zz_a2_k2', 'ZZ T4 Freigegeben k2', 'E', 'K', 'freigegeben', 'mensch', now() - interval '1 day');
select pg_temp.kind('ZZ T4 Pia echt') as k_pe, pg_temp.kind('ZZ T4 Pia test', true) as k_pt \gset
insert into lernpfad (student_id, skill_key, stand_system, quelle)
select k, sk, 'kandidat', 'session' from unnest(array[:'k_pe', :'k_pt']::uuid[]) k, unnest(array['zz_a2_k1', 'zz_a2_k2']) sk;
select pg_temp.neue_session(array[:'k_pe']::uuid[], 20) as s_qe \gset
select pg_temp.neue_session(array[:'k_pt']::uuid[], 20, true) as s_qt \gset
insert into session_ereignisse (session_id, student_id, typ, payload)
select s, k, 'signal', jsonb_build_object('art', 'kandidat', 'skill_key', 'zz_a2_k1')
  from (values (:'s_qe'::uuid, :'k_pe'::uuid), (:'s_qt'::uuid, :'k_pt'::uuid)) v(s, k);

select is((session_kind_live(:'s_qe', :'k_pe') -> 'mastery_kandidat' ->> 'pruefung_vorhanden'), 'false',
          '2 echt: nur Entwurf -> pruefung_vorhanden false');
select is((session_kind_live(:'s_qt', :'k_pt') -> 'mastery_kandidat' ->> 'pruefung_vorhanden'), 'true',
          '2 Testlauf: Entwurf -> pruefung_vorhanden true');
select pg_temp.act_as(:'coach_a');
select throws_ok(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_k1')$$, :'s_qe', :'k_pe'), 'P0002', null,
                 '2 echt: Entwurf nicht aufs Tablet (P0002 wie bisher)');
select is(pg_temp.versuch(format($$select pruefung_aufs_tablet(%L, %L, 'zz_a2_k1') ->> 'aktiv'$$, :'s_qt', :'k_pt')), 'true',
          '2 Testlauf: Entwurf aufs Tablet');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung' ->> 'frage', 'ZZ T4 Entwurf k1', '2 Testlauf: Tablet zeigt die Frage im Entwurf');
select pg_temp.act_as(:'coach_a');
select pruefung_aufs_tablet(:'s_qt', :'k_pt', 'zz_a2_k2');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung' ->> 'frage', 'ZZ T4 Freigegeben k2', '2 Testlauf: freigegebene Frage geht vor');
-- Echt: freigegebene Frage wie bisher (Tablet 1 der echten Session).
select pg_temp.neue_session(array[:'k_pe']::uuid[], 20) as s_qe2 \gset
select pg_temp.act_as(:'coach_a');
select is((pruefung_aufs_tablet(:'s_qe2', :'k_pe', 'zz_a2_k2')) ->> 'aktiv', 'true', '2 echt: freigegebene Frage aufs Tablet');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung' ->> 'frage', 'ZZ T4 Freigegeben k2', '2 echt: Tablet zeigt die freigegebene Frage');
select set_config('request.jwt.claims', '', true);
select is(pg_temp.versuch(format('select session_pruefung_frage_sitzung(%L, %L)', :'s_qe2', 'zz_a2_k1')), null,
          '2 echt: Hilfe liefert keinen Entwurf');
select is(pg_temp.versuch(format('select session_pruefung_frage_sitzung(%L, %L)', :'s_qe2', 'zz_a2_k2')),
          session_pruefung_frage('zz_a2_k2'), '2 echt: Hilfe gleich session_pruefung_frage');

-- ── 3) Auswahl: dieselbe Menge wie die bisherige Inline-Regel ─────────────────
-- Aufgaben in jedem Status, je mit und ohne Ausschluss (hand), Einsatz session/lsa/check.
select pg_temp.aufgaben('zz_a2_s2', 2, st, '{lsa,session,check}', 'a2-t4-' || st)
  from unnest(array['ready', 'draft', 'review', 'rueckfrage', 'beanstandet']) st;
insert into task_pruef_ausschluss (task_id, grund)
select id, 'ZZ T4' from tasks where source_ref like 'a2-t4-%-1';
create temp table t4_alt as
select t.id, tl,
       exists (select 1 from tasks x where x.id = t.id and coalesce(x.is_active, false) and not coalesce(x.is_tutorial, false)
                 and x.content_type = 'exercise' and 'session' = any (x.einsatz)
                 and exists (select 1 from task_solutions s where s.task_id = x.id
                               and lsa_has_answers(x.input_type, x.parts, s.correct_answers))
                 and (x.status = 'ready' or (tl and x.status in ('draft', 'review', 'rueckfrage')
                                              and pruef_ausschluss(x.id) is null))) as sess,
       exists (select 1 from tasks x where x.id = t.id and coalesce(x.is_active, false) and not coalesce(x.is_tutorial, false)
                 and x.content_type = 'exercise' and 'lsa' = any (x.einsatz)
                 and exists (select 1 from task_solutions s where s.task_id = x.id
                               and lsa_has_answers(x.input_type, x.parts, s.correct_answers))
                 and (x.status = 'ready' or (tl and x.status in ('draft', 'review', 'rueckfrage')
                                              and pruef_ausschluss(x.id) is null))) as lsa
  from tasks t cross join (values (false), (true), (null::boolean)) v(tl)
 where t.source = 'test';
select ok((select count(*) from t4_alt) > 300, '3 Kontrolle: mehr als 100 Aufgaben je Schalterwert');
select ok((select count(*) filter (where tl and sess and (select status from tasks where id = a.id) <> 'ready') from t4_alt a) = 3,
          '3 Kontrolle: im Testlauf genau drei nicht freigegebene (draft, review, rueckfrage ohne Ausschluss)');
select is((select count(*)::int from t4_alt a where session_im_pool(a.id, a.tl) is distinct from a.sess), 0,
          '3 session_im_pool gleich der bisherigen Regel (echt, Testlauf, null)');
select is((select count(*)::int from t4_alt a where lsa_im_pool(a.id, a.tl) is distinct from a.lsa), 0,
          '3 lsa_im_pool gleich der bisherigen Regel (echt, Testlauf, null)');
-- erklaer_checks: Check-Aufgaben in jedem Status an einer neuen Kernidee (Entwurf).
select pg_temp.act_as(:'admin');
select erklaer_kernidee_speichern(null, 'zz_a2_s2', 1, 'ZZ T4 Kernidee', 'mensch') as kern_n1 \gset
select set_config('request.jwt.claims', '', true);
insert into erklaer_check (kernidee_id, task_id, reihenfolge)
select :'kern_n1', t.id, row_number() over (order by t.source_ref)
  from tasks t where t.source_ref like 'a2-t4-%';
select is(erklaer_checks(:'kern_n1', false),
          (select array_agg(c.task_id order by c.reihenfolge) from erklaer_check c join tasks t on t.id = c.task_id
            where c.kernidee_id = :'kern_n1' and coalesce(t.is_active, true) and t.status = 'ready' and 'check' = any (t.einsatz)),
          '3 erklaer_checks echt: nur ready');
select is(erklaer_checks(:'kern_n1', true),
          (select array_agg(c.task_id order by c.reihenfolge) from erklaer_check c join tasks t on t.id = c.task_id
            where c.kernidee_id = :'kern_n1' and coalesce(t.is_active, true) and 'check' = any (t.einsatz)
              and (t.status = 'ready' or (t.status in ('draft', 'review', 'rueckfrage') and pruef_ausschluss(t.id) is null))),
          '3 erklaer_checks Testlauf: gleich der bisherigen Regel');
select is(cardinality(erklaer_checks(:'kern_n1', true)) - cardinality(erklaer_checks(:'kern_n1', false)), 3,
          '3 erklaer_checks Testlauf: drei mehr (draft, review, rueckfrage ohne Ausschluss)');

-- ── 4) lernpfad_beleg ─────────────────────────────────────────────────────
select pg_temp.kind('ZZ T4 Ole echt') as k_oe, pg_temp.kind('ZZ T4 Ole test', true) as k_ot \gset
select pg_temp.neue_session(array[:'k_oe']::uuid[], 20) as s_oe \gset
select pg_temp.neue_session(array[:'k_ot']::uuid[], 20, true) as s_ot \gset
select pg_temp.pfad(:'k_ot') as ot_vor \gset
select pg_temp.act_as(:'coach_a');
select is(lernpfad_beleg(:'k_oe', 'zz_a2_s2', :'s_oe', 'richtig', false), 'aktiv', '4 echt: Beleg gebucht, Stand aktiv');
select is((select count(*)::int from lernpfad_belege where student_id = :'k_oe' and session_id = :'s_oe'), 1, '4 echt: eine Belegzeile');
select is((select stand_system from lernpfad where student_id = :'k_oe' and skill_key = 'zz_a2_s2'), 'aktiv', '4 echt: Lernpfad-Zeile aktiv');
select is(lernpfad_beleg(:'k_ot', 'zz_a2_s2', :'s_ot', 'richtig', false), 'offen', '4 Testlauf: unveraenderter Stand (ohne Zeile offen)');
select is(pg_temp.pfad(:'k_ot'), :'ot_vor'::text, '4 Testlauf: keine Zeile in lernpfad oder lernpfad_belege');
select throws_ok(format($$select lernpfad_beleg(%L, 'zz_a2_s2', %L, 'quatsch', false)$$, :'k_ot', :'s_ot'), '22023', null,
                 '4 Testlauf: Pruefungen wie bisher (22023)');
select pg_temp.act_as(:'coach_b');
select throws_ok(format($$select lernpfad_beleg(%L, 'zz_a2_s2', %L, 'richtig', false)$$, :'k_ot', :'s_ot'), '42501', null,
                 '4 Testlauf: fremder Coach 42501 wie bisher');

-- ── 5) coaching_sessions.testlauf direkt ───────────────────────────────────
select pg_temp.act_as(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ T4 Schalter', now() + interval '1 day')
returning id as s_sch \gset
insert into session_students (session_id, student_id) values (:'s_sch', :'k_ot');
update coaching_sessions set testlauf = true where id = :'s_sch';
select is((select testlauf from coaching_sessions where id = :'s_sch'), true, '5 vor dem Start: Admin setzt direkt');
update coaching_sessions set testlauf = false where id = :'s_sch';
select is((select testlauf from coaching_sessions where id = :'s_sch'), false, '5 vor dem Start: Admin nimmt direkt');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_sch'), '42501', null,
                 '5 vor dem Start: Coach 42501 wie bisher');
select pg_temp.act_as(:'admin');
select throws_ok(format('update coaching_sessions set testlauf = false where id = %L', :'s_ot'), '55000', 'Testlauf: Session ist schon gestartet',
                 '5 nach dem Start: Admin nimmt direkt -> 55000');
select throws_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_oe'), '55000', null,
                 '5 nach dem Start: Admin setzt direkt -> 55000');
select lives_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_ot'),
                '5 nach dem Start: derselbe Wert ist keine Aenderung');
select pg_temp.act_as(:'coach_a');
select throws_ok(format('update coaching_sessions set testlauf = false where id = %L', :'s_ot'), '42501', null,
                 '5 nach dem Start: Coach 42501 (Tor vor der Startpruefung)');
select set_config('request.jwt.claims', '', true);

-- ── 6) kein_ziel als erster Schritt ────────────────────────────────────────
select pg_temp.kind_mit('ZZ T4 Kai echt', null, '{}') as k_ke, pg_temp.kind_mit('ZZ T4 Kai test', null, '{}', '{}', true) as k_kt \gset
select pg_temp.neue_session(array[:'k_ke']::uuid[], 0) as s_ke \gset
select pg_temp.checkin(:'s_ke', 1);
select is(pg_temp.schritt_tablet(:'s_ke', 1) ->> 'art', 'warten', '6 echt: erster Schritt wartet');
select is((select string_agg(art || '/' || phase || '/' || grund_code, ',') from session_schritte where session_id = :'s_ke'),
          'warten/kern/kein_ziel', '6 echt: eine Zeile kein_ziel');
select pg_temp.schritt_tablet(:'s_ke', 1);
select is((select count(*)::int from session_schritte where session_id = :'s_ke'), 1, '6 echt: naechster Takt ohne zweite Zeile');
select pg_temp.neue_session(array[:'k_kt']::uuid[], 0, true) as s_kt \gset
select pg_temp.checkin(:'s_kt', 1);
select pg_temp.schritt_tablet(:'s_kt', 1);
select pg_temp.schritt_tablet(:'s_kt', 1);
select is((select string_agg(art || '/' || phase || '/' || grund_code, ',') from session_schritte where session_id = :'s_kt'),
          'warten/kern/kein_ziel', '6 Testlauf: genau eine Zeile kein_ziel nach zwei Takten');
-- Warten vor dem Check-in (erster Schritt mit skill_key null) wird ebenso einmal eingetragen.
select pg_temp.kind('ZZ T4 Uli echt') as k_ue \gset
select pg_temp.neue_session(array[:'k_ue']::uuid[], 0) as s_ue \gset
select pg_temp.schritt_tablet(:'s_ue', 1);
select pg_temp.schritt_tablet(:'s_ue', 1);
select is((select string_agg(art || '/' || phase || '/' || grund_code, ',') from session_schritte where session_id = :'s_ue'),
          'warten/checkin/checkin_laeuft', '6 erstes Warten vor dem Check-in: eine Zeile');
-- Ein Warten mit Skill war schon vorher eine Zeile (unveraendert).
select ok(exists (select 1 from session_schritte where session_id = :'s_ee'), '6 echt: Schritte mit Skill wie bisher');

select * from finish();
rollback;
