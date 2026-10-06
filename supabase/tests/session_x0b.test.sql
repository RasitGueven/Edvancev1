-- ============================================================================
-- Session-Rahmen P1, Paket X0b: Rollenpruefungen NULL-sicher
-- (Migrationen 20261008100000 und 20261008100100).
--
-- get_my_role() liefert NULL fuer ein Konto ohne Zeile in profiles. Ein Tor wie
-- "if get_my_role() <> 'admin' then raise" feuert dann nicht. Hier wird je
-- umgestellter Funktion geprueft, dass es jetzt feuert, dass Admin und Coach
-- weiter durchkommen, und ein Waechter sucht in pg_proc nach neuen Faellen.
--
-- Eigene Fixtures, alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: Wegwerf-DB aus allen Migrationen + pgTAP,
--       PGOPTIONS='-c search_path=public,extensions')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(28);

-- --- Konten ----------------------------------------------------------------
\set admin_uid '0b000000-0000-4000-8000-00000000000a'
\set coach_uid '0b000000-0000-4000-8000-00000000000c'
\set kind_uid  '0b000000-0000-4000-8000-00000000000d'
\set ohne_uid  '0b000000-0000-4000-8000-0000000000ff'
\set leer      '0b000000-0000-4000-8000-000000000000'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'x0b-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'x0b-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'x0b-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  -- angemeldet, aber ohne Profil: get_my_role() liefert NULL
  (:'ohne_uid',  'x0b-ohne@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'x0b-admin@test.local', 'admin',   'X0b Admin'),
  (:'coach_uid', 'x0b-coach@test.local', 'coach',   'X0b Coach'),
  (:'kind_uid',  'x0b-kind@test.local',  'student', 'X0b Kind');
insert into students (profile_id, class_level) values (:'kind_uid', 8);
insert into microskills (cluster_id, code, name, class_level)
select c.id, 'X0B-TEST', 'X0b Testskill', 8 from skill_clusters c order by c.sort_order limit 1;

select (select id from students where profile_id = :'kind_uid')            as sid,
       (select id from microskills where code = 'X0B-TEST')                as mid,
       (select id from process_competencies order by sort_order limit 1)   as cid
\gset

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
end $$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;
grant execute on function pg_temp.fehler(text) to authenticated;

-- Die Funktionsaufrufe, je einmal mit Platzhalter-IDs. Ohne Tor scheitern sie
-- erst spaeter (P0002 "nicht gefunden") oder laufen durch, nie mit 42501.
create temp table aufrufe (fn text, aufruf text);
insert into aufrufe values
  ('audit_log_schreiben',    $$select public.audit_log_schreiben('x0b', 'test', null)$$),
  ('lead_delete',            format($$select public.lead_delete(%L)$$, :'leer')),
  ('platz_assign',           format($$select public.platz_assign(%L, %L)$$, :'leer', :'leer')),
  ('platz_release',          format($$select public.platz_release(%L)$$, :'leer')),
  ('lead_assessment_upsert', format($$select public.lead_assessment_upsert(%L, 'parent', 'x', '{}')$$, :'leer')),
  ('slot_assign',            format($$select public.slot_assign(%L, %L)$$, :'leer', :'leer')),
  ('slot_release',           format($$select public.slot_release(%L)$$, :'leer')),
  ('task_preview_payload',   format($$select public.task_preview_payload(%L)$$, :'leer')),
  ('task_solution_get',      format($$select public.task_solution_get(%L)$$, :'leer')),
  ('notiz_anlegen',          format($$select public.notiz_anlegen(%L, 'lernen', 'x')$$, :'leer'));
grant select on aufrufe to authenticated;

-- ============================================================================
-- 1 · Angemeldet ohne Profil -> 42501 an jeder umgestellten Funktion
-- ============================================================================
select pg_temp.act_as(:'ohne_uid');
select ok(public.get_my_role() is null and auth.uid() is not null,
          'Fixture: angemeldet, get_my_role() ist NULL');
set local role authenticated;

select is(pg_temp.fehler(aufruf), '42501', fn || ': ohne Profil -> 42501')
  from aufrufe order by fn;

-- enforce_mastery_gate ist ein Trigger. Er wirft ohne errcode (P0001); das
-- bleibt, X0b aendert nur die Bedingung. Ohne RLS (postgres), damit wirklich
-- der Trigger antwortet und nicht die Policy.
reset role;
select pg_temp.act_as(:'ohne_uid');
select throws_ok(
  format($f$insert into student_competency_mastery (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 100, true)$f$, :'sid', :'mid', :'cid'),
  'Mastered darf nur durch Coach gesetzt werden (FernUSG)',
  'enforce_mastery_gate: ohne Profil -> mastered=true abgelehnt');

-- ============================================================================
-- 2 · Systemaufrufe
-- Kein Systemweg ruft diese Funktionen (Bestandsaufnahme im PR). Ein
-- service_role-Aufruf hat kein Profil und faellt deshalb jetzt ebenfalls durch.
-- Fuer den Mastery-Trigger ist das gewollt (inv1: der Trigger ist der Backstop
-- gegen service_role).
-- ============================================================================
select pg_temp.als_system();
select ok(public.ist_systemaufruf(), 'Fixture: Systemaufruf erkannt');
select is(pg_temp.fehler(format($$select public.lead_delete(%L)$$, :'leer')), '42501',
          'lead_delete: Systemaufruf ohne Profil -> 42501 (kein Systemweg)');
select throws_ok(
  format($f$insert into student_competency_mastery (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 100, true)$f$, :'sid', :'mid', :'cid'),
  'Mastered darf nur durch Coach gesetzt werden (FernUSG)',
  'enforce_mastery_gate: service_role setzt kein mastered=true');

-- ============================================================================
-- 3 · Stichproben je Familie: Admin und Coach wie vorher
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'admin_uid');
select is(pg_temp.fehler(format($$select public.lead_delete(%L)$$, :'leer')), 'P0002',
          'Admin: lead_delete kommt am Tor vorbei (Lead nicht gefunden)');
select is(pg_temp.fehler(format($$select public.platz_release(%L)$$, :'leer')), 'P0002',
          'Admin: platz_release kommt am Tor vorbei');
select isnt(public.audit_log_schreiben('x0b', 'test', null), null,
            'Admin: audit_log_schreiben schreibt');
select is(pg_temp.fehler(format($$select public.notiz_anlegen(%L, 'lernen', 'x')$$, :'leer')), 'P0002',
          'Admin: notiz_anlegen kommt am Tor vorbei (keine Akte)');

select pg_temp.act_as(:'coach_uid');
select is(pg_temp.fehler(format($$select public.platz_assign(%L, %L)$$, :'leer', :'leer')), '42501',
          'Coach: platz_assign bleibt Admin-Sache');
select is(public.task_solution_get(:'leer') ->> 'exists', 'false',
          'Coach: task_solution_get liefert wie vorher');
select is(pg_temp.fehler(format($$select public.slot_release(%L)$$, :'leer')), 'P0002',
          'Coach: slot_release kommt am Tor vorbei');
select is(pg_temp.fehler(format($$select public.lead_assessment_upsert(%L, 'parent', 'x', '{}')$$, :'leer')), 'P0002',
          'Coach: lead_assessment_upsert kommt am Tor vorbei');

select pg_temp.act_as(:'kind_uid');
select is(pg_temp.fehler(format($$select public.task_solution_get(%L)$$, :'leer')), '42501',
          'Kind: task_solution_get bleibt gesperrt');

reset role;
select pg_temp.act_as(:'kind_uid');
select throws_ok(
  format($f$insert into student_competency_mastery (student_id, microskill_id, competency_id, score, mastered)
            values (%L, %L, %L, 100, true)$f$, :'sid', :'mid', :'cid'),
  'Mastered darf nur durch Coach gesetzt werden (FernUSG)',
  'Kind: mastered=true bleibt abgelehnt');
select pg_temp.act_as(:'coach_uid');
-- Ohne Tor haetten die Faelle oben schon Zeilen angelegt; die Gegenprobe gegen
-- den alten Stand soll hier nicht am Primaerschluessel abbrechen.
delete from student_competency_mastery where student_id = :'sid';
insert into student_competency_mastery (student_id, microskill_id, competency_id, score, mastered)
values (:'sid', :'mid', :'cid', 100, true);
select is((select mastered_by from student_competency_mastery where student_id = :'sid'), :'coach_uid'::uuid,
          'Coach: mastered=true geht durch und wird protokolliert');

-- ============================================================================
-- 4 · Waechter: keine unsichere Rollenpruefung in pg_proc
-- Ausnahmen: Familien von L5 (Lena-Board) und A2 (Session-Pakete), bis sie
-- umgestellt sind. Eintraege hier nur loeschen, nicht ergaenzen.
-- ============================================================================
create function pg_temp.unsichere_rollenpruefungen()
returns table (sig text, proname text, muster text) language sql stable as $w$
  with src as (
    select p.oid::regprocedure::text as sig, p.proname::text as proname, l.lanname,
           regexp_replace(p.prosrc, '--[^\n]*', '', 'g') as s
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      join pg_language l on l.oid = p.prolang
     where n.nspname = 'public' and l.lanname in ('plpgsql', 'sql')
  )
  select sig, proname, 'vergleich ohne coalesce' from src
   where s ~* '(?<!coalesce\()(public\.)?get_my_role\(\)\s*(not\s+in\M|<>|!=)'
  union all
  select sig, proname, '= ... and not' from src
   where s ~* '(?<!coalesce\()(public\.)?get_my_role\(\)\s*=\s*''[a-z_]+''\s+and\s+not\M'
  union all
  select sig, proname, 'not (get_my_role() = ...)' from src
   where s ~* '\mnot\s*\(\s*(public\.)?get_my_role\(\)\s*='
  union all
  select sig, proname, 'sql-hilfe liefert NULL' from src
   where lanname = 'sql' and s ~* '^\s*select\s+(public\.)?get_my_role\(\)\s*(=|<>|!=|not\s+in\M)'
  union all
  select sig, proname, 'variable ' || v[1] || ' ohne coalesce' from src,
         regexp_matches(s, '\m(\w+)\s+text\s*:=\s*(public\.)?get_my_role\(\)', 'gi') as v
   where s ~* ('(?<!coalesce\()\m' || v[1] || '\s*(not\s+in\M|<>|!=)')
$w$;

create function pg_temp.ausgenommen(p_name text) returns boolean language sql immutable as $a$
  select p_name ~ '^(pruef_|freigabe_|lena_)' or p_name = 'darf_pruefen'                        -- L5
      or p_name ~ '^(session_|tablet_|checkin_|lernpfad_|mastery_|skill_pruefung|erklaer_|quest_|push_token_)'
      or p_name in ('antwort_abgeben', 'hinweis_abrufen', 'raum_signale', 'signal_erledigen',
                    'eingriff_notieren', 'coach_raum_live', 'coach_kind_detail', 'einstellung_setzen',
                    'ziel_fertigkeiten', 'naechste_luecke', 'pfad_tiefer', 'hinweis_status_setzen',
                    'eltern_quest_wochenstand')                                                    -- A2
$a$;

select is(array(select sig || ' [' || muster || ']' from pg_temp.unsichere_rollenpruefungen()
                 where not pg_temp.ausgenommen(proname) order by 1),
          '{}'::text[],
          'Waechter: keine Rollenpruefung, die bei get_my_role() = NULL offen bleibt');

select diag('ausgenommen (L5/A2, noch offen): ' || coalesce(string_agg(sig || ' [' || muster || ']', ', ' order by sig), 'keine'))
  from pg_temp.unsichere_rollenpruefungen() where pg_temp.ausgenommen(proname);

-- Gegenprobe: der Waechter erkennt ein frisch angelegtes unsicheres Tor.
create function public.x0b_waechter_probe() returns void language plpgsql as $p$
begin
  if public.get_my_role() <> 'admin' then raise exception 'nur Admin'; end if;
end $p$;
select ok(exists (select 1 from pg_temp.unsichere_rollenpruefungen() where proname = 'x0b_waechter_probe'),
          'Waechter: Gegenprobe wird erkannt');

select * from finish();
rollback;
