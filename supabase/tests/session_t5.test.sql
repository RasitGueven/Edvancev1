-- ============================================================================
-- T5: Coach im Testlauf (Bauauftrag Session-Rahmen P1, Paket T5; Entscheidungen Rasit 12.10.2026).
--
--   1) skill_pruefung_session, echte Session: gleiches Ergebnis wie skill_pruefung_lesen, kein Entwurf.
--   2) skill_pruefung_session, Testlauf: Entwurf mit Erwartung und Kriterium; dieselbe Menge wie
--      pruefung_aufs_tablet (session_pruefung_frage_sitzung), erste Zeile = Frage auf dem Tablet.
--   3) Zugriff: fremder Coach, Schuelerkonto, Konto ohne Profil -> 42501; Admin geht.
--   4) termin_session_anlegen durch den eingeteilten Coach, nur Testkonten -> Testlauf-Session.
--   5) Anderer Coach -> 42501; Termin mit echtem Kind -> echte Session wie bisher.
--   6) Trigger: direktes INSERT/UPDATE durch den Coach 42501, nach dem Start 55000, echtes Kind 22023;
--      die Ausnahme greift nur mit allen drei Bedingungen (a) Einstellung, (b) Raum und Zeit, (c) Coach der Zeile.
--   7) Die Einstellung ist nach termin_session_anlegen zurueckgenommen (auch nach einem Abbruch).
-- Zusicherungen mit „echt“ sind vor und nach T5 gruen (unveraendert); vor T5 rot sind die Zusicherungen zu
-- skill_pruefung_session (Funktion fehlt) und die Coach-Testlauf-Faelle in 4 und 6 (Ausnahme fehlt).
-- Die Coach-Faelle in 4/5/7 laufen am naechsten Betriebstag ab heute (tagc); dafuer steht slots_jetzt fuer Coaches in
-- der Testtransaktion auf tagc 12:00 (Coaches rechnen sonst mit now()). Kein skip, an jedem Tag lauffaehig.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(52);

\ir session_a2_fixture.sql

-- Ergebnis eines Aufrufs oder sein Fehlercode (damit ein Lauf gegen den Stand vor T5 alle Zusicherungen zeigt).
create or replace function pg_temp.versuch(p_sql text) returns text language plpgsql as $$
declare v text;
begin
  execute p_sql into v;
  return v;
exception when others then
  return sqlstate;
end $$;
-- Fingerabdruck einer Pruefragen-Liste (Reihenfolge und alle Spalten).
create or replace function pg_temp.liste(p_sql text) returns text language plpgsql as $$
declare v text;
begin
  execute format('select coalesce(md5(string_agg(to_jsonb(x)::text, ''|'' order by n)), ''leer'') || ''/'' || count(*)
                    from (select x, row_number() over () n from (%s) x) y(x, n)', p_sql) into v;
  return v;
exception when others then
  return sqlstate;
end $$;
-- Konto mit allen drei Claims (auth.uid() liest request.jwt.claim.sub vor request.jwt.claims).
create or replace function pg_temp.wer(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', coalesce(uid::text, ''), true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

-- ── 1) und 2) Pruefragen ────────────────────────────────────────────────────
-- zz_a2_k1: Entwurf (aelter) und geprueft (neuer); zz_a2_k2: Entwurf (aelter) und zwei freigegebene; zz_a2_s1: keine.
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle, angelegt) values
  ('zz_a2_k1', 'ZZ T5 Entwurf k1', 'ZZ Erwartung k1', 'ZZ Kriterium k1', 'entwurf', 'ki', now() - interval '3 days'),
  ('zz_a2_k1', 'ZZ T5 Geprueft k1', 'ZZ Erwartung g1', 'ZZ Kriterium g1', 'geprueft', 'ki', now() - interval '1 day'),
  ('zz_a2_k2', 'ZZ T5 Entwurf k2', 'E', 'K', 'entwurf', 'ki', now() - interval '3 days'),
  ('zz_a2_k2', 'ZZ T5 Freigegeben k2 neu', 'E2', 'K2', 'freigegeben', 'mensch', now() - interval '1 day'),
  ('zz_a2_k2', 'ZZ T5 Freigegeben k2 alt', 'E1', 'K1', 'freigegeben', 'mensch', now() - interval '2 days'),
  ('zz_a2_n1', 'ZZ T5 Entwurf n1', 'En', 'Kn', 'entwurf', 'ki', now() - interval '1 day');
select pg_temp.kind('ZZ T5 Pia echt') as k_pe, pg_temp.kind('ZZ T5 Pia test', true) as k_pt \gset
select pg_temp.neue_session(array[:'k_pe']::uuid[], 20) as s_qe \gset
select pg_temp.neue_session(array[:'k_pt']::uuid[], 20, true) as s_qt \gset

select pg_temp.act_as(:'coach_a');
select is(pg_temp.liste(format('select id, skill_key, frage, erwartung, kriterium, quelle from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_k2')),
          pg_temp.liste($$select * from skill_pruefung_lesen('zz_a2_k2')$$),
          '1 echt: zz_a2_k2 gleich skill_pruefung_lesen (Zeilen, Spalten, Reihenfolge)');
select is(pg_temp.versuch(format('select string_agg(frage, '','') from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_k2')),
          'ZZ T5 Freigegeben k2 alt,ZZ T5 Freigegeben k2 neu', '1 echt: nur freigegeben, aelteste zuerst');
select is(pg_temp.liste(format('select id, skill_key, frage, erwartung, kriterium, quelle from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_k1')),
          pg_temp.liste($$select * from skill_pruefung_lesen('zz_a2_k1')$$), '1 echt: zz_a2_k1 gleich skill_pruefung_lesen');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_k1')), '0',
          '1 echt: Entwurf und geprueft fehlen');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_n1')), '0',
          '1 echt: reiner Entwurf fehlt');
select is(pg_temp.liste(format('select id, skill_key, frage, erwartung, kriterium, quelle from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_s1')),
          pg_temp.liste($$select * from skill_pruefung_lesen('zz_a2_s1')$$), '1 echt: Skill ohne Pruefrage gleich (leer)');

select is(pg_temp.versuch(format($$select frage || '|' || erwartung || '|' || kriterium from skill_pruefung_session(%L, %L)
                                  where frage like '%%Entwurf%%'$$, :'s_qt', 'zz_a2_n1')),
          'ZZ T5 Entwurf n1|En|Kn', '2 Testlauf: Entwurfsfrage mit Erwartung und Kriterium');
select is(pg_temp.versuch(format('select string_agg(frage, '','') from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')),
          'ZZ T5 Freigegeben k2 alt,ZZ T5 Freigegeben k2 neu,ZZ T5 Entwurf k2', '2 Testlauf: freigegeben vor Entwurf');
select is(pg_temp.versuch(format('select string_agg(frage, '','') from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k1')),
          'ZZ T5 Geprueft k1,ZZ T5 Entwurf k1', '2 Testlauf: geprueft vor Entwurf');
-- freigegeben (Rasit 14.10.): serverseitig status = 'freigegeben'; Entwurf und geprueft -> false.
select is(pg_temp.versuch(format($$select string_agg(frage || ':' || freigegeben, ',') from skill_pruefung_session(%L, %L)$$, :'s_qt', 'zz_a2_k2')),
          'ZZ T5 Freigegeben k2 alt:true,ZZ T5 Freigegeben k2 neu:true,ZZ T5 Entwurf k2:false',
          '2 Testlauf: freigegebene Fragen true, Entwurfsfrage false');
select is(pg_temp.versuch(format($$select string_agg(frage || ':' || freigegeben, ',') from skill_pruefung_session(%L, %L)$$, :'s_qt', 'zz_a2_k1')),
          'ZZ T5 Geprueft k1:false,ZZ T5 Entwurf k1:false', '2 Testlauf: geprueft ist nicht freigegeben');
select is(pg_temp.versuch(format($$select bool_and(freigegeben)::text from skill_pruefung_session(%L, %L)$$, :'s_qe', 'zz_a2_k2')),
          'true', '1 echt: freigegeben immer true');
-- Dieselbe Menge wie pruefung_aufs_tablet: je Skill gibt es Zeilen genau dann, wenn die Frage aufs Tablet darf, die
-- erste Zeile ist die Frage der Hilfe (und damit die auf dem Tablet), und es sind alle Pruefragen des Skills.
select pg_temp.act_as(:'admin');
create temp table t5_menge as
select sk,
       pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', sk)) as n_rpc,
       (select count(*)::text from skill_pruefung p where p.skill_key = sk) as n_alle,
       pg_temp.versuch(format('select frage from skill_pruefung_session(%L, %L) limit 1', :'s_qt', sk)) as erste,
       session_pruefung_frage_sitzung(:'s_qt', sk) as hilfe
  from unnest(array['zz_a2_k1', 'zz_a2_k2', 'zz_a2_n1', 'zz_a2_s1', 'zz_a2_v1']) sk;
select pg_temp.act_as(:'coach_a');
alter table t5_menge add column tablet text;
update t5_menge set tablet = pg_temp.versuch(format('select pruefung_aufs_tablet(%L, %L, %L) ->> ''aktiv''', :'s_qt', :'k_pt', sk));
select is((select string_agg(sk || ':' || n_rpc || ':' || tablet, ',' order by sk) from t5_menge),
          'zz_a2_k1:2:true,zz_a2_k2:3:true,zz_a2_n1:1:true,zz_a2_s1:0:P0002,zz_a2_v1:0:P0002',
          '2 Testlauf: Zeilen genau dann, wenn pruefung_aufs_tablet die Frage auflegt');
select is((select count(*)::int from t5_menge where n_rpc <> n_alle), 0, '2 Testlauf: alle Pruefragen des Skills');
select is((select count(*)::int from t5_menge where erste is distinct from hilfe), 0,
          '2 Testlauf: erste Zeile = session_pruefung_frage_sitzung (Frage auf dem Tablet)');
select pg_temp.act_as(pg_temp.tablet(1));
select is((tablet_stand()) -> 'pruefung' ->> 'frage', (select erste from t5_menge where sk = 'zz_a2_n1'),
          '2 Testlauf: das Tablet zeigt die erste Zeile (zuletzt aufgelegt: zz_a2_n1)');

-- ── 3) Zugriff ───────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach_b');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')), '42501',
          '3 fremder Coach -> 42501');
select pg_temp.act_as(:'schueler');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')), '42501',
          '3 Schuelerkonto -> 42501');
select pg_temp.act_as(pg_temp.tablet(1));
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')), '42501',
          '3 Tablet-Konto -> 42501');
select pg_temp.act_as(:'ohne');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')), '42501',
          '3 Konto ohne Profil -> 42501');
select pg_temp.act_as(:'admin');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', :'s_qt', 'zz_a2_k2')), '3',
          '3 Admin -> alle drei im Testlauf');
select is(pg_temp.liste(format('select id, skill_key, frage, erwartung, kriterium, quelle from skill_pruefung_session(%L, %L)', :'s_qe', 'zz_a2_k2')),
          pg_temp.liste($$select * from skill_pruefung_lesen('zz_a2_k2')$$), '3 Admin, echt: gleich skill_pruefung_lesen');
select is(pg_temp.versuch(format('select count(*)::text from skill_pruefung_session(%L, %L)', gen_random_uuid(), 'zz_a2_k2')),
          'P0002', '3 unbekannte Session -> P0002 (wie session_coach_pruefen)');
select is((select array_to_string(proargnames, ',') from pg_proc where proname = 'skill_pruefung_session'),
          'p_session_id,p_skill_key,id,skill_key,frage,erwartung,kriterium,quelle,freigegeben',
          '1 Spalten: wie skill_pruefung_lesen plus freigegeben, kein status');
select is(pg_temp.versuch($$select has_function_privilege('anon', 'skill_pruefung_session(uuid,text)', 'execute')::text$$), 'false',
          '3 anon hat kein EXECUTE');
select is(pg_temp.versuch($$select has_function_privilege('authenticated', 'skill_pruefung_session(uuid,text)', 'execute')::text$$),
          'true', '3 authenticated hat EXECUTE');
select set_config('request.jwt.claims', '', true);

-- ── Termin-Grundlage ─────────────────────────────────────────────────────────
-- Raum T5 mit Coach A (Mo–Fr, alle Zeiten), Raum T5b mit Coach B.
-- Tage: tagc = naechster Betriebstag ab heute (Coach-Faelle), tag1/tag2 = die zwei Betriebstage danach (Admin/System
-- ueber p_jetzt). Alle liegen in den Vertraegen der A2-Kinder (bis Ende des Monats + 7).
select (select d::date from generate_series(current_date, current_date + 90, interval '1 day') d
         where public.betriebstag(d::date) order by d limit 1) as tagc \gset
select (select d::date from generate_series(:'tagc'::date + 1, :'tagc'::date + 90, interval '1 day') d
         where public.betriebstag(d::date) order by d limit 1) as tag1,
       (select d::date from generate_series(:'tagc'::date + 1, :'tagc'::date + 90, interval '1 day') d
         where public.betriebstag(d::date) order by d offset 1 limit 1) as tag2 \gset
-- Uhr fuer Coaches: termin_session_anlegen rechnet fuer sie mit now() (p_jetzt gilt nur fuer Admin/System). Damit die
-- Coach-Faelle an jedem Tag laufen, steht die Uhr in dieser Transaktion fuer Coaches auf tagc 12:00 (Berlin); fuer
-- Admin/System bleibt p_jetzt wie in der Prod-Fassung (rollback am Ende; Muster wie betriebstag in slots_festschreiben).
select format($f$create or replace function public.slots_jetzt(p_jetzt timestamp with time zone)
  returns timestamp with time zone language sql stable security definer set search_path = public, pg_temp as $b$
  select case when public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin'
              then coalesce(p_jetzt, now())
              else (%L::date + time '12:00') at time zone 'Europe/Berlin' end; $b$$f$, :'tagc') \gexec
insert into raeume (name, aktiv_ab) values ('ZZ T5 Raum', '2026-01-01'), ('ZZ T5 Raum b', '2026-01-01');
insert into stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab)
select c.coach, w, z.id, (select id from raeume where name = c.raum), date '2026-01-01'
  from (values (:'coach_a'::uuid, 'ZZ T5 Raum'), (:'coach_b'::uuid, 'ZZ T5 Raum b')) c(coach, raum),
       generate_series(1, 5) w, slot_zeiten z where z.inaktiv_ab is null;
create or replace function pg_temp.zeit(p_stunde int) returns uuid language sql as $$
  select id from public.slot_zeiten where beginn = make_time(p_stunde, 0, 0) and inaktiv_ab is null
$$;
create or replace function pg_temp.raum(p_name text) returns uuid language sql as $$
  select id from public.raeume where name = p_name
$$;
-- Termin eines Kindes (Zusatz) am Tag p_datum zur Stunde p_stunde.
create or replace function pg_temp.termin_fuer(p_kind uuid, p_datum date, p_stunde int) returns void language sql as $$
  insert into public.kind_termine (student_id, vertrag_id, datum, slot_zeit_id, herkunft)
  select p_kind, (select v.id from public.vertraege v where v.student_id = p_kind order by v.vertragsbeginn desc limit 1),
         p_datum, pg_temp.zeit(p_stunde), 'zusatz'
$$;
-- Termin festschreiben und danach (eigenes Statement, neuer Snapshot) testlauf der Session lesen; sonst SQLSTATE.
create or replace function pg_temp.anlegen(p_datum date, p_stunde int, p_raum text, p_jetzt timestamptz default null)
returns text language plpgsql as $$
declare v_id uuid;
begin
  if p_jetzt is null then
    v_id := (public.termin_session_anlegen(p_datum, pg_temp.zeit(p_stunde), pg_temp.raum(p_raum)) ->> 'session_id')::uuid;
  else
    v_id := (public.termin_session_anlegen(p_datum, pg_temp.zeit(p_stunde), pg_temp.raum(p_raum), p_jetzt) ->> 'session_id')::uuid;
  end if;
  return (select cs.testlauf::text from public.coaching_sessions cs where cs.id = v_id);
exception when others then
  return sqlstate;
end $$;
select pg_temp.kind('ZZ T5 Tim test', true) as k_t1, pg_temp.kind('ZZ T5 Tea test', true) as k_t2,
       pg_temp.kind('ZZ T5 Rio echt') as k_r1 \gset
select pg_temp.termin_fuer(:'k_t1', :'tagc', 14);
select pg_temp.termin_fuer(:'k_t2', :'tagc', 14);
select pg_temp.termin_fuer(:'k_r1', :'tagc', 15);

-- ── 4) und 5) termin_session_anlegen am Tag (tagc) ────────────────────────────
select pg_temp.wer(:'coach_b');
select is(pg_temp.anlegen(:'tagc', 14, 'ZZ T5 Raum'), '42501', '5 anderer Coach: Testtermin im fremden Raum -> 42501');
select pg_temp.wer(:'coach_a');
select is(pg_temp.anlegen(:'tagc', 14, 'ZZ T5 Raum'), 'true', '4 eingeteilter Coach: Testtermin festschreiben -> testlauf');
select is(coalesce(current_setting('edvance.testlauf_anlegen', true), ''), '', '7 Einstellung nach dem Aufruf zurueckgenommen');
select coalesce((select id::text from coaching_sessions where raum_id = pg_temp.raum('ZZ T5 Raum') and slot_zeit_id = pg_temp.zeit(14)
           and scheduled_at = public.slots_termin_beginn(:'tagc', pg_temp.zeit(14))), '') as s_ct \gset
select is((select testlauf::text || ':' || coach_id::text || ':' || status from coaching_sessions where id = nullif(:'s_ct', '')::uuid),
          'true:' || :'coach_a' || ':upcoming', '4 Session mit testlauf = true, Coach A, upcoming');
select is((select string_agg(student_id::text, ',' order by student_id) from session_students where session_id = nullif(:'s_ct', '')::uuid),
          (select string_agg(k::text, ',' order by k) from unnest(array[:'k_t1', :'k_t2']::uuid[]) k),
          '4 beide Testkonten sind in der Testlauf-Session gebucht');
-- 7: Im selben Zug (gleiche Transaktion, gleicher Coach) ohne Systemweg: direktes INSERT mit testlauf -> 42501.
select throws_ok(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id, testlauf)
                           values (%L, 'ZZ T5 direkt', now() + interval '101 hours', %L, %L, true)$f$,
                        :'coach_a', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(17)),
                 '42501', 'Testlauf: nur Admin', '7 danach in derselben Transaktion: direktes INSERT -> 42501');
-- 5: Termin mit echtem Kind durch den eingeteilten Coach -> echte Session wie bisher.
select is(pg_temp.anlegen(:'tagc', 15, 'ZZ T5 Raum'), 'false', '5 echtes Kind: echte Session wie bisher');
select is(coalesce(current_setting('edvance.testlauf_anlegen', true), ''), '', '7 auch nach einer echten Session zurueckgenommen');
-- 7: Nach einem Abbruch (Systemaufruf, Trigger lehnt ab) ist die Einstellung ebenfalls weg.
select pg_temp.als_system();
select set_config('request.jwt.claim.sub', '', true), set_config('request.jwt.claim.role', 'service_role', true);
select pg_temp.termin_fuer(:'k_t1', :'tag1', 16);
select throws_ok(format($f$select termin_session_anlegen(%L, %L, %L, %L)$f$,
                        :'tag1', pg_temp.zeit(16), pg_temp.raum('ZZ T5 Raum'), (:'tag1'::date + time '12:00') at time zone 'Europe/Berlin'),
                 '42501', 'termin_session_anlegen: Testtermin, nur Admin', '5 Systemaufruf: Testtermin -> 42501 testlauf_nur_admin (wie bisher)');
select is(coalesce(current_setting('edvance.testlauf_anlegen', true), ''), '', '7 nach dem Abbruch zurueckgenommen');
-- Admin (fester Tag ueber p_jetzt): wie bisher Testlauf bzw. echt.
select pg_temp.wer(:'admin');
select is(pg_temp.anlegen(:'tag1', 16, 'ZZ T5 Raum', (:'tag1'::date + time '12:00') at time zone 'Europe/Berlin'), 'true',
          '4 Admin: Testtermin -> Testlauf (wie bisher)');
select pg_temp.termin_fuer(:'k_r1', :'tag2', 16);
select is(pg_temp.anlegen(:'tag2', 16, 'ZZ T5 Raum', (:'tag2'::date + time '12:00') at time zone 'Europe/Berlin'), 'false',
          '5 Admin: echtes Kind -> echte Session (wie bisher)');

-- ── 6) Trigger direkt ───────────────────────────────────────────────────────
-- Ohne Systemweg: Coach legt direkt eine Testlauf-Session an -> 42501.
select pg_temp.wer(:'coach_a');
select throws_ok(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id, testlauf)
                           values (%L, 'ZZ T5 direkt', now() + interval '102 hours', %L, %L, true)$f$,
                        :'coach_a', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(18)),
                 '42501', 'Testlauf: nur Admin', '6 Coach: direktes INSERT mit testlauf -> 42501');
select lives_ok(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id)
                          values (%L, 'ZZ T5 echt direkt', now() + interval '103 hours', %L, %L)$f$,
                       :'coach_a', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(18)),
                '6 echt: INSERT ohne testlauf wie bisher');
-- Mit gesetzter Einstellung (simuliert den Systemweg): nur mit (b) und (c).
create or replace function pg_temp.mit_weg(p_sql text) returns text language plpgsql as $$
declare v text;
begin
  perform set_config('edvance.testlauf_anlegen', '1', true);
  begin
    execute p_sql;
    v := 'ok';
  exception when others then
    v := sqlstate;
  end;
  perform set_config('edvance.testlauf_anlegen', '', true);
  return v;
end $$;
select is(pg_temp.mit_weg(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id, testlauf)
                                    values (%L, 'ZZ T5 weg', now() + interval '104 hours', %L, %L, true)$f$,
                                 :'coach_a', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(19))),
          'ok', '6 Systemweg, Raum und Zeit, Coach der Zeile -> erlaubt');
select is(pg_temp.mit_weg(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, slot_zeit_id, testlauf)
                                    values (%L, 'ZZ T5 weg', now() + interval '105 hours', %L, true)$f$,
                                 :'coach_a', pg_temp.zeit(19))),
          '42501', '6 Systemweg ohne raum_id -> 42501');
select is(pg_temp.mit_weg(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, testlauf)
                                    values (%L, 'ZZ T5 weg', now() + interval '106 hours', %L, true)$f$,
                                 :'coach_a', pg_temp.raum('ZZ T5 Raum'))),
          '42501', '6 Systemweg ohne slot_zeit_id -> 42501');
select is(pg_temp.mit_weg(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id, testlauf)
                                    values (%L, 'ZZ T5 weg', now() + interval '107 hours', %L, %L, true)$f$,
                                 :'coach_b', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(19))),
          '42501', '6 Systemweg, aber Session eines anderen Coaches -> 42501');
select pg_temp.wer(:'schueler');
select is(pg_temp.mit_weg(format($f$insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id, testlauf)
                                    values (%L, 'ZZ T5 weg', now() + interval '108 hours', %L, %L, true)$f$,
                                 :'schueler', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(19))),
          '42501', '6 Systemweg, Schuelerkonto als coach_id -> 42501');
-- UPDATE von testlauf: nur Admin, auch mit Einstellung.
select pg_temp.wer(:'admin');
insert into coaching_sessions (coach_id, room, scheduled_at, raum_id, slot_zeit_id)
values (:'coach_a', 'ZZ T5 Schalter', now() + interval '109 hours', pg_temp.raum('ZZ T5 Raum'), pg_temp.zeit(19))
returning id as s_sch \gset
insert into session_students (session_id, student_id) values (:'s_sch', :'k_t1');
select pg_temp.wer(:'coach_a');
select throws_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_sch'), '42501', null,
                 '6 Coach: UPDATE testlauf -> 42501');
select is(pg_temp.mit_weg(format('update coaching_sessions set testlauf = true where id = %L', :'s_sch')), '42501',
          '6 Coach: UPDATE testlauf auch mit Einstellung -> 42501');
select pg_temp.wer(:'admin');
select lives_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_sch'), '6 Admin: UPDATE vor dem Start wie bisher');
-- Start direkt (wie session_starten ueber den Session-Systemweg).
select set_config('edvance.session_rpc', '1', true);
update coaching_sessions set status = 'active', gestartet_am = now() where id = :'s_sch';
select set_config('edvance.session_rpc', '', true);
select throws_ok(format('update coaching_sessions set testlauf = false where id = %L', :'s_sch'), '55000',
                 'Testlauf: Session ist schon gestartet', '6 Admin: nach dem Start -> 55000');
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'coach_a', 'ZZ T5 echt', now() + interval '110 hours')
returning id as s_re \gset
insert into session_students (session_id, student_id) values (:'s_re', :'k_r1');
select throws_ok(format('update coaching_sessions set testlauf = true where id = %L', :'s_re'), '22023',
                 'Testlauf: nur mit Testkonten', '6 Admin: Testlauf mit echtem Kind -> 22023');
select is(coalesce(current_setting('edvance.testlauf_anlegen', true), ''), '', '7 am Ende ist keine Einstellung gesetzt');

-- ── Hinweis testlauf_nur_admin ───────────────────────────────────────────────
select ok(pg_get_functiondef('public.termin_session_anlegen(date,uuid,uuid,timestamptz)'::regprocedure) like '%testlauf_nur_admin%',
          '5 der Hinweis testlauf_nur_admin bleibt fuer alle anderen Aufrufer');

select set_config('request.jwt.claims', '', true), set_config('request.jwt.claim.sub', '', true),
       set_config('request.jwt.claim.role', '', true);
select * from finish();
rollback;
