-- T4 Vergleich vorher/nachher in derselben Wegwerf-DB (Bauauftrag Session-Rahmen P1, Paket T4).
--
-- Aufruf auf einer Wegwerf-DB mit dem Stand VOR T4 (alle Migrationen bis 20261013151404, seed.sql), aus docs/session:
--   psql "<conninfo>" -v ON_ERROR_STOP=1 -q -t -A -v ausgabe=/pfad/ -f t4-vergleich.sql
-- Ablauf in einer einzigen Transaktion: Fixture und Szenarien anlegen, messen (-> :ausgabe/t4-vorher.txt),
-- auf den Savepoint zurueck, die fuenf T4-Migrationen einspielen, dieselben Szenarien messen
-- (-> :ausgabe/t4-nachher.txt), alles zurueckrollen. Danach: diff t4-vorher.txt t4-nachher.txt.
-- Gleiche Aufgaben, Kinder und IDs; nur die Sessions entstehen je Lauf neu (IDs und Zeiten werden normalisiert).
--
-- Gemessen wird, was sich fuer echte Sessions nicht aendern darf (Entscheidungen 1 bis 5), und die Auswahl auch
-- im Testlauf (Entscheidung 3). Nicht gemessen: das erste Warten ohne vorigen Schritt (Entscheidung 6, gewollt
-- anders) und testlauf nach dem Start (Entscheidung 5, gewollt anders).

begin;
\ir ../../supabase/tests/session_a2_fixture.sql

-- IDs und Zeitstempel normalisieren (Sessions entstehen je Lauf neu).
create or replace function pg_temp.norm(p text) returns text language sql as $$
  select regexp_replace(regexp_replace(coalesce(p, 'NULL'),
           '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', 'ID', 'g'),
           '\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?([+-]\d{2}(:\d{2})?)?', 'ZEIT', 'g')
$$;
create or replace function pg_temp.ref(p uuid) returns text language sql as $$
  select coalesce((select source_ref from tasks where id = p), 'NULL')
$$;
-- Fehlercode eines Aufrufs (oder 'ok: <Ergebnis>').
create or replace function pg_temp.code(p_sql text) returns text language plpgsql as $$
declare v text;
begin
  execute p_sql into v;
  return 'ok: ' || pg_temp.norm(v);
exception when others then
  return sqlstate;
end $$;

-- ── Daten (bleiben ueber den Savepoint) ─────────────────────────────────────
-- Aufgaben in jedem Status, je mit und ohne Ausschluss; Einsatz session, lsa, check.
select pg_temp.aufgaben('zz_a2_s2', 2, st, '{lsa,session,check}', 'a2-t4v-' || st)
  from unnest(array['ready', 'draft', 'review', 'rueckfrage', 'beanstandet']) st;
insert into task_pruef_ausschluss (task_id, grund) select id, 'ZZ T4V' from tasks where source_ref like 'a2-t4v-%-1';
select pg_temp.act_as(:'admin');
select erklaer_kernidee_speichern(null, 'zz_a2_s2', 1, 'ZZ T4V Kernidee', 'mensch') as kern_v \gset
select set_config('request.jwt.claims', '', true);
insert into erklaer_check (kernidee_id, task_id, reihenfolge)
select :'kern_v', t.id, row_number() over (order by t.source_ref) from tasks t where t.source_ref like 'a2-t4v-%';
-- Pruefragen: k1 nur Entwurf, k2 Entwurf und freigegeben, v1 geprueft.
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle, angelegt) values
  ('zz_a2_k1', 'ZZ T4V Entwurf k1', 'E', 'K', 'entwurf', 'ki', now() - interval '2 days'),
  ('zz_a2_k2', 'ZZ T4V Entwurf k2', 'E', 'K', 'entwurf', 'ki', now() - interval '2 days'),
  ('zz_a2_k2', 'ZZ T4V Freigegeben k2', 'E', 'K', 'freigegeben', 'mensch', now() - interval '1 day'),
  ('zz_a2_v1', 'ZZ T4V Geprueft v1', 'E', 'K', 'geprueft', 'mensch', now() - interval '1 day');
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_t4v_fb', 'ZZ T4V Fehlbild', now());
-- Kinder (echt) in verschiedenen Lagen.
select pg_temp.kind_mit('ZZ T4V Mila', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_mila,
       pg_temp.kind_mit('ZZ T4V Ben', 'zz_a2_terme', '{zz_a2_v1}', '{zz_a2_s1}') as k_ben,
       pg_temp.kind_mit('ZZ T4V Lia', null, '{zz_a2_v2}') as k_lia,
       pg_temp.kind_mit('ZZ T4V Kim', 'zz_a2_quad', '{zz_a2_k2}', '{zz_a2_k1}') as k_kim,
       pg_temp.kind_mit('ZZ T4V Ida', 'zz_a2_linear', '{}', '{zz_a2_v2}') as k_ida,
       pg_temp.kind('ZZ T4V Pia') as k_pia,
       pg_temp.kind('ZZ T4V Ole') as k_ole
\gset
insert into lernpfad (student_id, skill_key, stand_system, quelle) values
  (:'k_ben', 'zz_a2_v2', 'noch_nicht_sicher', 'lsa'), (:'k_lia', 'zz_a2_s1', 'noch_nicht_sicher', 'lsa'),
  (:'k_kim', 'zz_a2_k1', 'kandidat', 'session'), (:'k_ida', 'zz_a2_n1', 'aktiv', 'coach'),
  (:'k_pia', 'zz_a2_k1', 'kandidat', 'session'), (:'k_pia', 'zz_a2_k2', 'kandidat', 'session'),
  (:'k_pia', 'zz_a2_v1', 'kandidat', 'session');
update lernpfad set stand_coach = 'gemeistert', coach_grund = 'ZZ T4V', coach_von = :'coach_a', coach_am = now()
 where student_id = :'k_kim' and skill_key = 'zz_a2_k2';
create temp table t4v_kinder as
select * from (values ('Mila', :'k_mila'::uuid), ('Ben', :'k_ben'::uuid), ('Lia', :'k_lia'::uuid), ('Kim', :'k_kim'::uuid),
                      ('Ida', :'k_ida'::uuid), ('Pia', :'k_pia'::uuid), ('Ole', :'k_ole'::uuid)) v(name, id);
-- LSA-Kinder: echt und Testkonto, Thema mit Entwuerfen (wie lsa_pool_testkonten).
select pg_temp.kind('ZZ T4V Lsa echt') as k_lsa_e, pg_temp.kind('ZZ T4V Lsa test', true) as k_lsa_t \gset
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select l.id, 'mathematik', 'zz_a2_terme', 'aktuell', 'gespraech' from leads l
 where l.converted_student_id in (:'k_lsa_e', :'k_lsa_t');

-- ── Messung ───────────────────────────────────────────────────────────────
create or replace function pg_temp.schritte(p_s uuid) returns text language sql as $$
  select string_agg(x.art || '/' || x.phase || '/' || coalesce(x.skill_key, '-') || '/' || pg_temp.ref(x.task_id)
                    || '/' || coalesce(x.modus, '-') || '/' || x.eingemischt || '/' || coalesce(x.grund_code, '-')
                    || '/' || coalesce(x.schwierigkeit::text, '-'), E'\n    ' order by x.id)
    from session_schritte x where x.session_id = p_s
$$;
create or replace function pg_temp.pfad(p_kind uuid) returns text language sql as $$
  select coalesce(string_agg(l.skill_key || '=' || l.stand_system || '/' || coalesce(l.stand_coach, '-') || '/' || l.quelle
                             || '/' || pg_temp.norm(l.belege::text), ', ' order by l.skill_key), '-')
      || ' | protokoll ' || (select count(*) from lernpfad_protokoll p where p.student_id = p_kind)
      || ' | belege ' || (select count(*) from lernpfad_belege b where b.student_id = p_kind)
    from lernpfad l where l.student_id = p_kind
$$;
create or replace function pg_temp.ziel(p_s uuid, p_kind uuid) returns text language sql as $$
  select coalesce(string_agg(z.reihenfolge || ':' || z.skill_key || ':' || z.rolle || ':' || z.stand || ':' || z.offen, ', '
                             order by z.reihenfolge), '-')
    from session_zielliste(p_s, p_kind) z
$$;

create or replace function pg_temp.messen() returns setof text language plpgsql as $$
declare
  k record; th text; s uuid; v text; l jsonb; t uuid; i int;
begin
  -- 3 Auswahl: jede Testaufgabe x Schalter, Pool session/lsa; erklaer_checks je Kernidee.
  return query
    select 'pool ' || x.source_ref || ' tl=' || coalesce(v.tl::text, 'null') || ' session=' || session_im_pool(x.id, v.tl)
           || ' lsa=' || lsa_im_pool(x.id, v.tl)
      from tasks x cross join (values (false), (true), (null::boolean)) v(tl)
     where x.source = 'test' order by x.source_ref, v.tl nulls last;
  return query
    select 'checks ' || ek.skill_key || '/' || ek.nr || ' tl=' || v.tl || ' '
           || coalesce((select string_agg(pg_temp.ref(c), ',') from unnest(erklaer_checks(ek.id, v.tl)) c), '-')
      from erklaer_kernidee ek cross join (values (false), (true)) v(tl)
     where ek.skill_key like 'zz_a2_%' order by ek.skill_key, ek.nr, v.tl;

  -- 1 Planer ohne Session: ziel_fertigkeiten_core je Kind x Thema, naechste_luecke_core je Kind.
  for k in select * from t4v_kinder order by name loop
    for th in select thema_key from themen where thema_key like 'zz_a2_%' order by 1 loop
      return next 'ziel_fertigkeiten_core ' || k.name || ' ' || th || ': '
        || coalesce((select string_agg(z.reihenfolge || ':' || z.skill_key || ':' || z.rolle || ':' || coalesce(z.stand_system, '-')
                                       || ':' || coalesce(z.stand_coach, '-') || ':' || z.stand || ':' || z.pruefung_faellig, ', '
                                       order by z.reihenfolge)
                       from ziel_fertigkeiten_core(k.id, th) z), '-');
    end loop;
    return next 'naechste_luecke_core ' || k.name || ': '
      || coalesce((select string_agg(n.skill_key || ':' || coalesce(n.thema_key, '-') || ':' || n.stand_system || ':' || n.quelle, ', ')
                     from naechste_luecke_core(k.id) n), '-');
  end loop;

  -- 1/6 Echte Session Mila: Warm-up falsch, „tiefer“, weiter.
  s := pg_temp.neue_session(array[(select id from t4v_kinder where name = 'Mila')], 6);
  perform pg_temp.checkin(s, 1);
  perform pg_temp.lauf(s, 1, 4, false);
  return next 'Mila ziel vor tiefer: ' || pg_temp.ziel(s, (select id from t4v_kinder where name = 'Mila'));
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  perform pfad_entscheiden(s, (select id from t4v_kinder where name = 'Mila'), 'tiefer');
  return next 'Mila ziel nach tiefer: ' || pg_temp.ziel(s, (select id from t4v_kinder where name = 'Mila'));
  perform pg_temp.lauf(s, 1, 6, true);
  return next 'Mila schritte:' || E'\n    ' || pg_temp.schritte(s);
  return next 'Mila pfad: ' || pg_temp.pfad((select id from t4v_kinder where name = 'Mila'));
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  return next 'Mila session_kind_live: ' || pg_temp.norm(session_kind_live(s, (select id from t4v_kinder where name = 'Mila'))::text);

  -- 1/6 Echte Session Ben: Eingriff Stufe 4.
  s := pg_temp.neue_session(array[(select id from t4v_kinder where name = 'Ben')], 20);
  perform pg_temp.checkin(s, 1);
  perform pg_temp.schritt(s, 1);
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  perform eingriff_notieren(s, (select id from t4v_kinder where name = 'Ben'), 4, 'zz_t4v_fb');
  return next 'Ben ziel nach Eingriff: ' || pg_temp.ziel(s, (select id from t4v_kinder where name = 'Ben'));
  perform pg_temp.antwort(s, 1, true);
  perform pg_temp.lauf(s, 1, 5, false);
  return next 'Ben schritte:' || E'\n    ' || pg_temp.schritte(s);
  return next 'Ben pfad: ' || pg_temp.pfad((select id from t4v_kinder where name = 'Ben'));

  -- 1 Echte Session Lia: Fall Lernpfad, „tiefer“.
  s := pg_temp.neue_session(array[(select id from t4v_kinder where name = 'Lia')], 20);
  perform pg_temp.checkin(s, 1);
  return next 'Lia ziel vor tiefer: ' || pg_temp.ziel(s, (select id from t4v_kinder where name = 'Lia'));
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  perform pfad_entscheiden(s, (select id from t4v_kinder where name = 'Lia'), 'tiefer');
  return next 'Lia ziel nach tiefer: ' || pg_temp.ziel(s, (select id from t4v_kinder where name = 'Lia'));
  perform pg_temp.lauf(s, 1, 4, true);
  return next 'Lia schritte:' || E'\n    ' || pg_temp.schritte(s);
  return next 'Lia pfad: ' || pg_temp.pfad((select id from t4v_kinder where name = 'Lia'));

  -- Kim und Ida: Session ohne Eingriff (Kandidat, gemeistert, Erklaersequenz).
  for k in select * from t4v_kinder where name in ('Kim', 'Ida') order by name loop
    s := pg_temp.neue_session(array[k.id], 20);
    perform pg_temp.checkin(s, 1);
    return next k.name || ' ziel: ' || pg_temp.ziel(s, k.id);
    perform pg_temp.lauf(s, 1, 5, true);
    return next k.name || ' schritte:' || E'\n    ' || pg_temp.schritte(s);
  end loop;

  -- 2 Pruefragen echt: Coach-Sicht, aufs Tablet, Tablet.
  s := pg_temp.neue_session(array[(select id from t4v_kinder where name = 'Pia')], 20);
  insert into session_ereignisse (session_id, student_id, typ, payload)
  select s, (select id from t4v_kinder where name = 'Pia'), 'signal', jsonb_build_object('art', 'kandidat', 'skill_key', sk)
    from unnest(array['zz_a2_k1', 'zz_a2_k2', 'zz_a2_v1']) sk;
  return next 'Pia session_kind_live: ' || pg_temp.norm(session_kind_live(s, (select id from t4v_kinder where name = 'Pia'))::text);
  foreach th in array array['zz_a2_k1', 'zz_a2_k2', 'zz_a2_v1', 'zz_a2_s1'] loop
    perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
    return next 'Pia pruefung_aufs_tablet ' || th || ': '
      || pg_temp.code(format('select pruefung_aufs_tablet(%L, %L, %L)::text', s, (select id from t4v_kinder where name = 'Pia'), th));
    perform pg_temp.act_as(pg_temp.tablet(1));
    return next 'Pia tablet_stand ' || th || ': ' || pg_temp.norm((tablet_stand() -> 'pruefung')::text);
  end loop;

  -- 4 lernpfad_beleg echt: Folge von Belegen.
  s := pg_temp.neue_session(array[(select id from t4v_kinder where name = 'Ole')], 20);
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  for i in 1 .. 6 loop
    return next 'Ole lernpfad_beleg ' || i || ': ' || pg_temp.code(format(
      'select lernpfad_beleg(%L, %L, %L, %L, %L)', (select id from t4v_kinder where name = 'Ole'), 'zz_a2_s2', s,
      (array['richtig', 'falsch', 'richtig', 'teilweise', 'richtig', 'richtig'])[i], i = 3));
  end loop;
  return next 'Ole lernpfad_beleg quatsch: ' || pg_temp.code(format(
    'select lernpfad_beleg(%L, %L, %L, %L, false)', (select id from t4v_kinder where name = 'Ole'), 'zz_a2_s2', s, 'quatsch'));
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000003');
  return next 'Ole lernpfad_beleg fremder Coach: ' || pg_temp.code(format(
    'select lernpfad_beleg(%L, %L, %L, %L, false)', (select id from t4v_kinder where name = 'Ole'), 'zz_a2_s2', s, 'richtig'));
  return next 'Ole pfad: ' || pg_temp.pfad((select id from t4v_kinder where name = 'Ole'));

  -- 5 testlauf vor dem Start (direkt): Admin setzt/nimmt, Coach, echtes Kind.
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000001');
  insert into coaching_sessions (coach_id, room, scheduled_at)
  values ('a2a2a2a2-0001-4000-8000-000000000002', 'ZZ T4V Schalter', now() + interval '1 day') returning id into s;
  insert into session_students (session_id, student_id) values (s, (select id from t4v_kinder where name = 'Ole'));
  return next 'Schalter echtes Kind setzen: ' || pg_temp.code(format('update coaching_sessions set testlauf = true where id = %L returning testlauf::text', s));
  delete from session_students where session_id = s;
  insert into session_students (session_id, student_id) values (s, (select id from students where id in
    (select converted_student_id from leads where full_name = 'ZZ T4V Lsa test')));
  return next 'Schalter Admin setzen: ' || pg_temp.code(format('update coaching_sessions set testlauf = true where id = %L returning testlauf::text', s));
  return next 'Schalter Admin nehmen: ' || pg_temp.code(format('update coaching_sessions set testlauf = false where id = %L returning testlauf::text', s));
  perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000002');
  return next 'Schalter Coach setzen: ' || pg_temp.code(format('update coaching_sessions set testlauf = true where id = %L returning testlauf::text', s));
  perform set_config('request.jwt.claims', '', true);

  -- 3 LSA-Auswahl (lsa_select_next_core): echtes Kind und Testkonto, je acht Antworten.
  for k in select * from (values ('Lsa echt'), ('Lsa test')) v(name) loop
    perform pg_temp.act_as('a2a2a2a2-0001-4000-8000-000000000001');
    -- Feste LSA-ID je Kind: die Auswahl streut innerhalb eines Skills ueber md5(session_id || task_id).
    execute format('alter table lsa_sessions alter column id set default %L::uuid',
                   case k.name when 'Lsa echt' then 'a2a2a2a2-0009-4000-8000-000000000001'
                               else 'a2a2a2a2-0009-4000-8000-000000000002' end);
    l := lsa_start((select converted_student_id from leads where full_name = 'ZZ T4V ' || k.name), 8, 'Mathematik', 'adaptiv');
    v := '';
    for i in 1 .. 8 loop
      select a.task_id into t from lsa_ausgegeben a where a.session_id = (l ->> 'session_id')::uuid
         and not exists (select 1 from lsa_responses r where r.session_id = a.session_id and r.task_id = a.task_id)
       order by a.task_id limit 1;
      exit when t is null;
      v := v || pg_temp.ref(t) || ',';
      perform lsa_submit((l ->> 'session_id')::uuid, t, case when i % 3 = 0 then '{"text": "7"}' else '{"text": "0"}' end::jsonb);
    end loop;
    return next 'LSA ' || k.name || ' Folge: ' || v || ' ausgegeben '
      || (select count(*) from lsa_ausgegeben a where a.session_id = (l ->> 'session_id')::uuid);
    perform lsa_finish((l ->> 'session_id')::uuid);
  end loop;
  perform set_config('request.jwt.claims', '', true);
end $$;

savepoint vor_t4;
\o :ausgabe/t4-vorher.txt
select * from pg_temp.messen();
\o
rollback to savepoint vor_t4;

\ir ../../supabase/migrations/20261013160412_t4_pfad_testlauf.sql
\ir ../../supabase/migrations/20261013160957_t4_pruefung_testlauf.sql
\ir ../../supabase/migrations/20261013161533_t4_pool_regel.sql
\ir ../../supabase/migrations/20261013162108_t4_beleg_und_schalter.sql
\ir ../../supabase/migrations/20261013162641_t4_kein_ziel_schritt.sql

\o :ausgabe/t4-nachher.txt
select * from pg_temp.messen();
\o
rollback;
