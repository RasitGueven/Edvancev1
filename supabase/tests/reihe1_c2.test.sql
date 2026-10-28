-- ============================================================================
-- Reihe 1 · C2 Phasen und Auswahl (docs/reihe1/Bauauftrag-C-Session-Workflow.md C2.7; Konzept §2.4–2.5, §9)
--
-- Auftrag A (aufgabe_ziehen, _zwilling, _meta, _gezeigt) und D (zeigs_mir_offen) als Attrappen NUR in dieser
-- Transaktion: Rolle steht im source_ref der Testaufgaben ('c2r-<rolle>-<skill>-n'), Stufe = difficulty.
--   W) Warm-up mit Reihe: Abruf zuerst, dann Voraussetzungen des heutigen Ziels, ohne Hinweise
--   F) Fälligkeit: Abruf nach 1, 2, 4 Sessions; Fehler setzt auf 1; am längsten überfällig zuerst
--   B) Lösungsbeispiel (Rolle beispiel) wird gemeldet und kommt nie wieder
--   Z) Zwilling nach falscher Antwort (gleiche Rolle und Stufe)
--   T) Transfer erst ab sicherer Stufe 3, Hinweise nur Stufe 1
--   R) Recap ohne Hinweise und ohne Beleg, keine Termin-Wahl
--   G) Generalprobe: nur ungesehene Instanzen, ohne Hinweise und Rückmeldung, dann sicher/noch üben
--   M) Zeig's mir nur nach Coach-Übernahme
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(38);

\ir session_a2_fixture.sql

-- ── Attrappen der Aufträge A und D ─────────────────────────────────────────
create table pg_temp.gezeigt (kind uuid, task uuid, session uuid);
create table pg_temp.zeigs (kind uuid, skill_key text, entscheidung text);
create or replace function public.aufgabe_ziehen(p_kind uuid, p_skill text, p_rolle text, p_stufe int default null,
                                      p_ausschluss uuid[] default '{}') returns uuid language sql as $$
  select t.id from tasks t where t.skill_key = p_skill and t.source_ref like 'c2r-' || p_rolle || '-%'
     and (p_stufe is null or t.difficulty = p_stufe) and not (t.id = any (p_ausschluss))
   order by t.source_ref limit 1
$$;
create or replace function public.aufgabe_zwilling(p_kind uuid, p_task uuid, p_rolle text default null) returns uuid language sql as $$
  select t.id from tasks t, tasks o where o.id = p_task and t.skill_key = o.skill_key and t.difficulty = o.difficulty
     and t.id <> o.id and split_part(t.source_ref, '-', 2) = split_part(o.source_ref, '-', 2)
   order by t.source_ref desc limit 1
$$;
create or replace function public.aufgabe_meta(p_task uuid)
returns table (skill_key text, kernidee_key text, bauform_key text, rolle text, stufe int) language sql as $$
  select t.skill_key, 'K1', 'ZZ', split_part(t.source_ref, '-', 2), t.difficulty from tasks t where t.id = p_task
$$;
create or replace function public.aufgabe_gezeigt(p_kind uuid, p_task uuid, p_session uuid) returns void language sql as $$
  insert into pg_temp.gezeigt values (p_kind, p_task, p_session)
$$;
create or replace function public.zeigs_mir_offen(p_kind uuid, p_session uuid)
returns table (skill_key text, vorschlag_am timestamptz, entscheidung text, entschieden_von uuid) language sql as $$
  select z.skill_key, now(), z.entscheidung, null::uuid from pg_temp.zeigs z where z.kind = p_kind
$$;

select pg_temp.aufgaben(sk, 6, 'ready', '{session}', 'c2r-warmup-' || sk) from unnest(array['zz_a2_v1', 'zz_a2_v2', 'zz_a2_k2']) sk;
select pg_temp.aufgaben(sk, n, 'ready', '{session}', 'c2r-' || r || '-' || sk)
  from unnest(array['zz_a2_s1', 'zz_a2_s2']) sk,
       (values ('uebung', 10), ('beispiel', 5), ('transfer', 5), ('recap', 5), ('generalprobe', 10)) v(r, n);
insert into reihe_kernideen (skill_key, kernidee_key, nr, titel) values
  ('zz_a2_s1', 'K1', 901, 'ZZ s1'), ('zz_a2_s2', 'K1', 902, 'ZZ s2');

-- Reihe ab heute; p_ka = Datum der Arbeit oder null (rollierend).
create function pg_temp.reihe(p_kind uuid, p_ka date default null) returns void language plpgsql as $$
declare v uuid;
begin
  insert into reihen (student_id, thema_keys, ka_datum, start) values (p_kind, '{zz_a2_terme}', p_ka, reihe_heute())
  returning id into v;
  perform reihe_planen(v, 'start', 'Test');
end $$;
-- Kind war in der alten Session anwesend (Grundlage für Abruf).
create function pg_temp.anwesend(p_s uuid, p_kind uuid) returns void language plpgsql as $$
begin
  set local session_replication_role = replica;
  insert into session_students (session_id, student_id, attendance) values (p_s, p_kind, 'present');
  set local session_replication_role = origin;
end $$;
-- Schritt holen und eine Aufgabe jeder Art (aufgabe, recap, generalprobe) beantworten.
create function pg_temp.mach(p_s uuid, p_richtig boolean) returns jsonb language plpgsql as $$
declare v jsonb := pg_temp.schritt(p_s, 1);
begin
  if v ->> 'task_id' is not null and v ->> 'art' <> 'beispiel' then
    perform pg_temp.act_as(pg_temp.tablet(1));
    perform antwort_abgeben(p_s, (v ->> 'task_id')::uuid, null, case when p_richtig then '"7"' else '"0"' end::jsonb);
  end if;
  return v;
end $$;
create function pg_temp.letzter(p_s uuid) returns session_schritte language sql as $$
  select * from session_schritte where session_id = p_s order by id desc limit 1
$$;

-- ── W) Warm-up mit Reihe ───────────────────────────────────────────────────
select pg_temp.kind_mit('ZZ C2 Ada', 'zz_a2_terme', '{}', '{zz_a2_k2}') as k_a \gset
select pg_temp.anwesend(:'s_alt', :'k_a');
select pg_temp.reihe(:'k_a');
select pg_temp.neue_session(array[:'k_a']::uuid[], 1) as s_a \gset
select pg_temp.checkin(:'s_a', 1);
select pg_temp.schritt(:'s_a', 1) as w1 \gset
select is(:'w1'::jsonb ->> 'phase', 'warmup', 'W1 Warm-up');
select is((pg_temp.letzter(:'s_a')).grund_code || ':' || (:'w1'::jsonb ->> 'skill_key'), 'warmup_abruf:zz_a2_k2', 'W2 zuerst der fällige Abruf');
select ok(not (:'w1'::jsonb ->> 'hinweise_erlaubt')::boolean and (:'w1'::jsonb ->> 'hinweise_max')::int = 0, 'W3 Warm-up ohne Hinweis-Knopf');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select hinweis_abrufen(%L, %L, 1)', :'s_a', :'w1'::jsonb ->> 'task_id'), '22023', null, 'W4 hinweis_abrufen im Warm-up gesperrt');
select pg_temp.antwort(:'s_a', 1, true);
select pg_temp.loese(:'s_a', 1, true) as w2 \gset
select is((pg_temp.letzter(:'s_a')).grund_code, 'warmup_voraussetzung', 'W5 dann eine Voraussetzung des heutigen Ziels');
select ok(:'w2'::jsonb ->> 'skill_key' in ('zz_a2_v1', 'zz_a2_v2'), 'W6 Voraussetzung von zz_a2_s1 (heute im Plan)');
select pg_temp.loese(:'s_a', 1, true) as w3 \gset
select is(:'w3'::jsonb ->> 'phase', 'warmup', 'W7 dritte Warm-up-Aufgabe');

-- ── B) Lösungsbeispiel ─────────────────────────────────────────────────────
select pg_temp.schritt(:'s_a', 1) as b1 \gset
select is(:'b1'::jsonb ->> 'art' || ':' || (:'b1'::jsonb ->> 'rolle'), 'beispiel:beispiel', 'B1 neuer Skill: Lösungsbeispiel mit Rolle beispiel');
select ok(exists (select 1 from pg_temp.gezeigt where task = (:'b1'::jsonb ->> 'task_id')::uuid and session = :'s_a'), 'B2 an aufgabe_gezeigt gemeldet');
select ok((:'b1'::jsonb ->> 'task_id')::uuid = any (session_ausschluss(gen_random_uuid(), :'k_a')), 'B3 dasselbe Beispiel ist für jede spätere Session ausgeschlossen');

-- ── Z) Zwilling nach falscher Antwort ──────────────────────────────────────
select pg_temp.loese(:'s_a', 1, false) as z0 \gset
select is(:'z0'::jsonb ->> 'rolle', 'uebung', 'Z1 ähnliche Aufgabe mit Rolle uebung');
select pg_temp.schritt(:'s_a', 1) as z1 \gset
select is((pg_temp.letzter(:'s_a')).grund_code, 'zwilling', 'Z2 nach falscher Antwort der Zwilling');
select is((select difficulty from tasks where id = (:'z1'::jsonb ->> 'task_id')::uuid),
          (select difficulty from tasks where id = (:'z0'::jsonb ->> 'task_id')::uuid), 'Z3 gleiche Stufe');
select isnt(:'z1'::jsonb ->> 'task_id', :'z0'::jsonb ->> 'task_id', 'Z4 andere Instanz');

-- ── T) Transfer erst ab sicherer Stufe 3 ───────────────────────────────────
select ok(not exists (select 1 from session_schritte where session_id = :'s_a' and rolle = 'transfer'), 'T1 vor sicherer Stufe 3 kein Transfer');
select pg_temp.antwort(:'s_a', 1, true);
set local session_replication_role = replica;
insert into session_antworten (session_id, student_id, task_id, teil, versuch_nr, eingabe, ergebnis, hinweisstufe_max, phase, eingemischt)
select :'s_alt', :'k_a', t.id, null, 1, '"7"', 'richtig', 0, 'kern', false
  from tasks t where t.source_ref like 'c2r-uebung-zz_a2_s1-%' and t.difficulty = 3 limit 1;
set local session_replication_role = origin;
select pg_temp.schritt(:'s_a', 1) as t1 \gset
select is(:'t1'::jsonb ->> 'rolle', 'transfer', 'T2 sicher auf Stufe 3: Transfer');
select is((:'t1'::jsonb ->> 'hinweise_max')::int, 1, 'T3 Transfer mit Hinweisen nur Stufe 1');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select hinweis_abrufen(%L, %L, 2)', :'s_a', :'t1'::jsonb ->> 'task_id'), '22023', null, 'T4 Hinweisstufe 2 im Transfer gesperrt');
select pg_temp.antwort(:'s_a', 1, true);

-- ── R) Recap ───────────────────────────────────────────────────────────────
select pg_temp.uhr(:'s_a', 52);
select pg_temp.schritt(:'s_a', 1) as r1 \gset
select is(:'r1'::jsonb ->> 'art', 'recap', 'R1 kurz vor dem Check-out: Recap');
select ok(not (:'r1'::jsonb ->> 'hinweise_erlaubt')::boolean, 'R2 Recap ohne Hinweise');
select count(*) as belege_vor from lernpfad_belege where student_id = :'k_a' \gset
select pg_temp.act_as(pg_temp.tablet(1));
select antwort_abgeben(:'s_a', (:'r1'::jsonb ->> 'task_id')::uuid, null, '"7"');
select is((select count(*) from lernpfad_belege where student_id = :'k_a'), :'belege_vor'::bigint, 'R3 Recap bucht keinen Beleg');
select pg_temp.mach(:'s_a', true) from generate_series(1, 2);
select is(pg_temp.schritt(:'s_a', 1) ->> 'art', 'fertig', 'R4 nach dem Recap fertig');
select ok(not exists (select 1 from session_schritte where session_id = :'s_a' and art = 'termin'), 'R5 keine Termin-Wahl');

-- ── F) Fälligkeit 1 → 2 → 4 ────────────────────────────────────────────────
select pg_temp.kind_mit('ZZ C2 Fe', null, '{}') as k_f \gset
create table pg_temp.ss (nr int, id uuid);
insert into pg_temp.ss select g, gen_random_uuid() from generate_series(1, 8) g;
set local session_replication_role = replica;
insert into coaching_sessions (id, room, scheduled_at, status) select id, 'ZZ C2 F', now() - (30 - nr) * interval '1 day', 'done' from pg_temp.ss;
insert into session_students (session_id, student_id, attendance) select id, :'k_f', 'present' from pg_temp.ss;
insert into lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
select :'k_f', 'zz_a2_v1', id, 'richtig', false from pg_temp.ss where nr = 1;
set local session_replication_role = origin;
create function pg_temp.f(p_nr int) returns int language sql as $$
  select f.abstand from session_abruf_faellig((select id from pg_temp.ss where nr = p_nr), (select student_id from session_students
    where session_id = (select id from pg_temp.ss where nr = 1) limit 1)) f where f.skill_key = 'zz_a2_v1'
$$;
create function pg_temp.abruf(p_nr int, p_richtig boolean) returns void language plpgsql as $$
begin
  set local session_replication_role = replica;
  insert into session_antworten (session_id, student_id, task_id, teil, versuch_nr, eingabe, ergebnis, hinweisstufe_max, phase, eingemischt)
  select s.id, ss.student_id, (select id from tasks where source_ref = 'c2r-warmup-zz_a2_v1-1'), null, 1, '"7"',
         case when p_richtig then 'richtig' else 'falsch' end, 0, 'warmup', false
    from pg_temp.ss s join session_students ss on ss.session_id = s.id where s.nr = p_nr;
  insert into lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
  select ss.student_id, 'zz_a2_v1', s.id, case when p_richtig then 'richtig' else 'falsch' end, false
    from pg_temp.ss s join session_students ss on ss.session_id = s.id where s.nr = p_nr;
  set local session_replication_role = origin;
end $$;
select is(pg_temp.f(2), 1, 'F1 nur Beleg in Session 1: in Session 2 fällig');
select pg_temp.abruf(2, true);
select ok(pg_temp.f(3) is null and pg_temp.f(4) = 2, 'F2 richtiger Abruf in Session 2: wieder in Session 4');
select pg_temp.abruf(4, true);
select ok(pg_temp.f(7) is null and pg_temp.f(8) = 4, 'F3 richtiger Abruf in Session 4: wieder in Session 8');
select pg_temp.abruf(5, false);
select is(pg_temp.f(6), 1, 'F4 ein Fehler setzt den Abstand auf 1');
set local session_replication_role = replica;
insert into lernpfad_belege (student_id, skill_key, session_id, ergebnis, hinweis_genutzt)
select :'k_f', 'zz_a2_k2', id, 'richtig', false from pg_temp.ss where nr = 6;
set local session_replication_role = origin;
select is((select string_agg(skill_key, ',' order by ueberfaellig desc, skill_key) from session_abruf_faellig((select id from pg_temp.ss where nr = 8), :'k_f')),
          'zz_a2_v1,zz_a2_k2', 'F5 mehr fällig als Plätze: der am längsten überfällige zuerst (nicht alphabetisch)');

-- ── G) Generalprobe (Arbeit morgen: heute ist die letzte Session) ──────────
select pg_temp.kind_mit('ZZ C2 Gül', 'zz_a2_terme', '{}') as k_g \gset
select pg_temp.anwesend(:'s_alt', :'k_g');
insert into session_ausgegeben (session_id, student_id, task_id, phase)
select :'s_alt', :'k_g', id, 'kern' from tasks where source_ref = 'c2r-generalprobe-zz_a2_s1-1';
select pg_temp.neue_session(array[:'k_g']::uuid[], 16) as s_g \gset
select pg_temp.reihe(:'k_g', reihe_heute() + 1);
select pg_temp.checkin(:'s_g', 1);
select pg_temp.schritt(:'s_g', 1) as g1 \gset
select is(:'g1'::jsonb ->> 'art', 'generalprobe', 'G1 Generalprobe');
select ok(not (:'g1'::jsonb ->> 'hinweise_erlaubt')::boolean and not (:'g1'::jsonb ->> 'rueckmeldung')::boolean, 'G2 ohne Hinweise und ohne Rückmeldung');
select isnt(:'g1'::jsonb ->> 'task_id', (select id::text from tasks where source_ref = 'c2r-generalprobe-zz_a2_s1-1'), 'G3 keine schon gesehene Instanz');
select pg_temp.act_as(pg_temp.tablet(1));
select ok(not (antwort_abgeben(:'s_g', (:'g1'::jsonb ->> 'task_id')::uuid, null, '"7"') ? 'ergebnis'), 'G4 Antwort ohne Rückmeldung');
select pg_temp.mach(:'s_g', false) from generate_series(1, 3);
select is(pg_temp.schritt(:'s_g', 1) ->> 'art', 'gp_ergebnis', 'G5 danach sicher / noch üben');
select ok(not exists (select 1 from session_schritte s join tasks t on t.id = s.task_id where s.session_id = :'s_g'
                       and s.art = 'generalprobe' and t.source_ref not like 'c2r-generalprobe-%' and t.source_ref not like 'c2r-transfer-%'),
          'G6 nur Instanzen der Rollen generalprobe und transfer');
select pg_temp.act_as(pg_temp.tablet(1));
select session_gp_waehlen(:'s_g', 'zz_a2_s2');
select pg_temp.schritt(:'s_g', 1);
select is((pg_temp.letzter(:'s_g')).grund_code, 'gp_ueben', 'G7 „noch üben“ startet eine Übungsrunde');

-- ── M) Zeig's mir ──────────────────────────────────────────────────────────
select pg_temp.kind_mit('ZZ C2 Mo', 'zz_a2_terme', '{}') as k_m \gset
select pg_temp.reihe(:'k_m');
insert into pg_temp.zeigs values (:'k_m', 'zz_a2_s2', 'nicht_heute');
select pg_temp.neue_session(array[:'k_m']::uuid[], 16) as s_m \gset
select pg_temp.checkin(:'s_m', 1);
select pg_temp.schritt(:'s_m', 1);
select isnt((pg_temp.letzter(:'s_m')).grund_code, 'zeigs_mir', 'M1 „Nicht heute“: keine Zeig''s-mir-Aufgabe');
select pg_temp.kind_mit('ZZ C2 Nia', 'zz_a2_terme', '{}') as k_n \gset
select pg_temp.reihe(:'k_n');
insert into pg_temp.zeigs values (:'k_n', 'zz_a2_s2', 'uebernehmen');
select pg_temp.neue_session(array[:'k_n']::uuid[], 16) as s_n \gset
select pg_temp.checkin(:'s_n', 1);
select pg_temp.schritt(:'s_n', 1) as m2 \gset
select is((pg_temp.letzter(:'s_n')).grund_code || ':' || (:'m2'::jsonb ->> 'skill_key'), 'zeigs_mir:zz_a2_s2', 'M2 übernommen: erste Kernaufgabe zu diesem Skill');
select ok(not (:'m2'::jsonb ->> 'hinweise_erlaubt')::boolean, 'M3 ohne Hinweis-Knopf');

select * from finish();
rollback;
