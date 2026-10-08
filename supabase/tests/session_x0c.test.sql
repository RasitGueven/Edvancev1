-- ============================================================================
-- Session-Rahmen P1, Paket X0c: Zugangspruefungen NULL-sicher ueber get_my_role() hinaus.
--
-- X0b hat get_my_role() abgesichert. Andere NULL-Quellen sind get_my_student_id() und
-- auth.uid(): Ein Platz-Konto (platz_devices) ist ein Auth-User mit Rolle student ohne
-- students-Zeile, fuer jedes Tablet im Raum ist get_my_student_id() also NULL. Ein Tor wie
-- "if not (get_my_student_id() = p_student_id or ...) then raise" feuert dann nicht.
--
-- Die Bestandsaufnahme (docs/session/offene-punkte-x0c.md) fand keine offene Stelle mehr;
-- die Befunde aus X0b hat A2 geschlossen (20261008124412). Dieser Test haelt das fest:
--   A) Proben: Konto ohne Profil, Platz-Konto ohne Zuweisung und Coach ohne Bezug bekommen
--      an jeder Pruefung mit get_my_student_id()/auth.uid() 42501 bzw. false.
--   B) Platz-Konto mit Zuweisung: die Tablet-Aufrufe laufen (Datenvertrag 8).
--   C) Waechter: sucht die Muster in allen Funktionen und Policies.
--   D) Gegenprobe: nimmt den A2-Fix in erklaer_nachlesen testweise zurueck. Der Waechter
--      schlaegt an, die Proben aus A bekommen Zeilen statt 42501, Admin und Coach dasselbe.
--
-- Eigene Fixtures (session_a2_fixture), alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: Wegwerf-DB aus allen Migrationen + seed.sql + pgTAP,
--       PGOPTIONS='-c search_path=public,extensions')
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(39);

\ir session_a2_fixture.sql

-- SQLSTATE eines Aufrufs, "kein Fehler" wenn er durchlaeuft.
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;

select pg_temp.kind_mit('ZZ Lina X0c', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k1 \gset
select pg_temp.neue_session(array[:'k1']::uuid[], 1) as s \gset
select pg_temp.checkin(:'s', 1);

-- Die drei Konten der Proben: ohne Profil, Platz-Konto ohne Zuweisung, Coach ohne Bezug.
create temp table konten (nr int, konto text, uid uuid);
insert into konten values
  (1, 'ohne Profil', :'ohne'),
  (2, 'Platz-Konto ohne Zuweisung', pg_temp.tablet(5)),
  (3, 'Coach ohne Bezug', :'coach_b');

-- Die Pruefungen mit get_my_student_id()/auth.uid(), je mit dem Kind k1 der Session.
create temp table proben (fn text, aufruf text);
insert into proben values
  ('erklaer_nachlesen', format($$select public.erklaer_nachlesen(%L, 'zz_a2_n1')$$, :'k1')),
  ('erklaer_zugang',    format($$select public.erklaer_zugang(%L, %L)$$, :'s', :'k1')),
  ('session_naechster_schritt', format($$select public.session_naechster_schritt(%L, %L)$$, :'s', :'k1')),
  ('mein_lernpfad',     $$select * from public.mein_lernpfad()$$);

create function pg_temp.probe(p_uid uuid, p_sql text) returns text language plpgsql as $$
begin
  perform pg_temp.act_as(p_uid);
  return pg_temp.fehler(p_sql);
end $$;
-- Ergebnis eines Aufrufs als Text, NULL als 'NULL'.
create function pg_temp.wert(p_uid uuid, p_sql text) returns text language plpgsql as $$
declare r text;
begin
  perform pg_temp.act_as(p_uid);
  execute p_sql into r;
  return coalesce(r, 'NULL');
end $$;

-- ============================================================================
-- A · Proben: 42501 fuer alle drei Konten
-- ============================================================================
select pg_temp.act_as(pg_temp.tablet(5));
select ok(public.get_my_student_id() is null and public.get_my_role() = 'student',
          'A Fixture: Platz-Konto hat Rolle student und keine students-Zeile');

select is(pg_temp.probe(k.uid, p.aufruf), '42501', 'A ' || p.fn || ': ' || k.konto || ' -> 42501')
  from konten k cross join proben p order by p.fn, k.nr;

-- Coach ohne Session-Bezug: true ist gewollt (X0, jeder Coach bei aktiver Akte). Entscheidend ist,
-- dass nie NULL herauskommt.
select is(pg_temp.wert(k.uid, format('select public.lsa_may_act_for(%L)', :'k1')),
          case k.nr when 3 then 'true' else 'false' end,
          'A lsa_may_act_for: ' || k.konto || ' -> ' || case k.nr when 3 then 'true (akte_aktiv)' else 'false' end
          || ', nie NULL') from konten k order by k.nr;

-- ============================================================================
-- B · Platz-Konto mit Zuweisung: Tablet-Aufrufe wie bisher (Datenvertrag 8)
-- ============================================================================
select pg_temp.act_as(pg_temp.tablet(1));
select ok(public.get_my_student_id() is null, 'B Fixture: zugewiesenes Tablet hat ebenfalls keine students-Zeile');
select is(public.tablet_stand() ->> 'zugewiesen', 'true', 'B tablet_stand: zugewiesen');
select is(pg_temp.fehler(format('select public.session_naechster_schritt(%L, null)', :'s')), 'kein Fehler',
          'B session_naechster_schritt: laeuft fuer das eigene Kind');
select is(pg_temp.fehler($$select public.erklaer_nachlesen(null, 'zz_a2_n1')$$), 'kein Fehler',
          'B erklaer_nachlesen ohne Kind: laeuft');
select is(pg_temp.fehler($$select * from public.mein_lernpfad()$$), 'kein Fehler',
          'B mein_lernpfad: laeuft ueber die Tablet-Zuweisung');

-- ============================================================================
-- C · Waechter
-- NULL-Quellen: get_my_*(), auth.uid() und Variablen, die direkt daraus gesetzt werden.
-- Gesucht wird nur in Bedingungen, die direkt ein raise ausloesen. coalesce(...) und
-- exists (...) gelten als NULL-sicher und werden vorher entfernt.
--   R1  Quelle in <>, != oder not in            if get_my_student_id() <> p then raise
--   R2  Quelle in = / in innerhalb von not (...) if not (get_my_student_id() = p or ...) then raise
--   R3  SQL-Hilfe vom Typ boolean, die einen nackten Vergleich liefert
--   P   Policy: Quelle in is [not] distinct from, is null oder coalesce(..., true). Sonst
--       heisst NULL in einer Policy "verweigert", auch unter not (...).
-- Ausnahmen: Funktionen, die C3 gerade aendert, bis C3 sie uebernimmt. Eintraege nur loeschen.
-- ============================================================================
create function pg_temp.ohne_null_sichere(p text) returns text language plpgsql immutable as $f$
declare s text := p; a int; i int; d int;
begin
  loop
    a := regexp_instr(s, '\m(coalesce|exists)\s*\(', 1, 1, 0, 'i');
    exit when a = 0;
    i := regexp_instr(s, '\m(coalesce|exists)\s*\(', 1, 1, 1, 'i');
    d := 1;
    while i <= length(s) and d > 0 loop
      d := d + case substr(s, i, 1) when '(' then 1 when ')' then -1 else 0 end;
      i := i + 1;
    end loop;
    s := substr(s, 1, a - 1) || ' TRUE ' || substr(s, i);
  end loop;
  return s;
end $f$;

create function pg_temp.null_quellen(s text) returns text language sql immutable as $q$
  select '(?:(?:public\.)?get_my_\w+\(\)|auth\.uid\(\)'
         || coalesce((select string_agg('|\m' || v[1] || '\M', '')
                        from regexp_matches(s, '\m(\w+)\s+(?:text|uuid)\s*:=\s*(?:public\.)?(?:get_my_\w+\(\)|auth\.uid\(\))\s*;', 'gi') v), '')
         || ')'
$q$;

create function pg_temp.null_offene_pruefungen()
returns table (sig text, proname text, muster text) language sql stable as $w$
  with src as (
    select p.oid::regprocedure::text as sig, p.proname::text as proname, l.lanname,
           p.prorettype = 'boolean'::regtype as bool,
           regexp_replace(regexp_replace(p.prosrc, '--[^\n]*', '', 'g'), '\s+', ' ', 'g') as s
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      join pg_language l on l.oid = p.prolang
     where n.nspname = 'public' and l.lanname in ('plpgsql', 'sql')
  ), bed as (
    select sig, proname, pg_temp.null_quellen(s) as t, pg_temp.ohne_null_sichere(m[1]) as c
      from src, regexp_matches(s, '(?<!end )\m(?:if|elsif)\M([^;]*?)\mthen\M\s*(?:raise\M|perform public\.pruef_fehler)', 'gi') m
     where lanname = 'plpgsql'
  )
  select sig, proname, 'R1 <> / not in' from bed
   where c ~* (t || '\s*(<>|!=|not\s+in\M)') or c ~* ('(<>|!=)\s*' || t)
  union
  select sig, proname, 'R2 not (... = ...)' from bed
   where c ~* ('\mnot\s*\([^;]*(' || t || '\s*(=|in\M)|=\s*' || t || ')')
  union
  select sig, proname, 'R3 sql-hilfe vergleicht nackt' from src,
         lateral (select pg_temp.ohne_null_sichere(s) as c, pg_temp.null_quellen(s) as t) x
   where lanname = 'sql' and bool and x.c ~* '^\s*select\M' and x.c !~* '\mfrom\M'
     and (x.c ~* (x.t || '\s*(=|<>|!=|in\M|not\s+in\M)') or x.c ~* ('(=|<>|!=)\s*' || x.t))
$w$;

create function pg_temp.null_offene_policies()
returns table (pol text, muster text) language sql stable as $w$
  with p as (
    select schemaname || '.' || tablename || '.' || policyname as pol,
           regexp_replace(coalesce(qual, '') || ' ' || coalesce(with_check, ''), '\s+', ' ', 'g') as s,
           '(?:(?:public\.)?get_my_\w+\(\)|auth\.uid\(\))' as t
      from pg_policies where schemaname in ('public', 'storage')
  )
  select pol, 'P distinct from' from p
   where s ~* (t || '\s*is\s+(not\s+)?distinct\s+from') or s ~* ('distinct\s+from\s*' || t)
  union
  select pol, 'P is null' from p where s ~* (t || '\s*is\s+null')
  union
  select pol, 'P coalesce(..., true)' from p where s ~* ('coalesce\([^;]*' || t || '[^;]*,\s*true\s*\)')
$w$;

create function pg_temp.c3_ausnahme(p_name text) returns boolean language sql immutable as $a$
  select p_name = any (array[
    'coach_raum_live', 'coach_kind_detail', 'raum_signale',                 -- C3: Raum-Sicht
    'session_briefing', 'satz_vorschlaege',                                 -- C3: Briefing, Satz (C2)
    'session_naechster_schritt', 'session_schritt_planen', 'session_schritt',
    'session_schritt_oeffentlich', 'session_plan_warmup', 'session_plan_kern',
    'session_plan_checkout', 'session_zielliste'])                          -- C3: Planer-Hilfen
$a$;

select is(array(select sig || ' [' || muster || ']' from pg_temp.null_offene_pruefungen()
                 where not pg_temp.c3_ausnahme(proname) order by 1),
          '{}'::text[],
          'C Waechter: keine Pruefung, die bei get_my_student_id()/auth.uid() = NULL offen bleibt');
select diag('ausgenommen (C3, noch offen): ' || coalesce(string_agg(sig || ' [' || muster || ']', ', ' order by sig), 'keine'))
  from pg_temp.null_offene_pruefungen() where pg_temp.c3_ausnahme(proname);
select is(array(select pol || ' [' || muster || ']' from pg_temp.null_offene_policies() order by 1),
          '{}'::text[],
          'C Waechter: keine Policy, die bei NULL durchlaesst');

-- Gegenproben je Muster, und je eine sichere Schreibweise, die nicht anschlagen darf.
create function public.x0c_probe_r1(p uuid) returns void language plpgsql as $p$
begin
  if public.get_my_student_id() <> p then raise exception 'x' using errcode = '42501'; end if;
end $p$;
create function public.x0c_probe_r2(p uuid) returns void language plpgsql as $p$
begin
  if not (public.get_my_role() = 'admin' or public.get_my_student_id() = p) then raise exception 'x'; end if;
end $p$;
create function public.x0c_probe_var(p uuid) returns void language plpgsql as $p$
declare v_ich uuid := auth.uid();
begin
  if v_ich <> p then raise exception 'x'; end if;
end $p$;
create function public.x0c_probe_r3(p uuid) returns boolean language sql as $p$
  select public.get_my_student_id() = p
$p$;
create function public.x0c_probe_sicher(p uuid) returns boolean language plpgsql as $p$
begin
  if not coalesce(public.get_my_student_id() = p, false) then raise exception 'x'; end if;
  if public.get_my_student_id() is distinct from p then raise exception 'x'; end if;
  if not exists (select 1 from public.students where profile_id = auth.uid()) then raise exception 'x'; end if;
  return coalesce(public.get_my_student_id() = p, false);
end $p$;
create table public.x0c_probe_tab (student_id uuid);
alter table public.x0c_probe_tab enable row level security;
create policy x0c_probe_offen on public.x0c_probe_tab for select
  using (student_id is not distinct from public.get_my_student_id());

select is(array(select proname || ' ' || muster from pg_temp.null_offene_pruefungen()
                 where proname like 'x0c_probe%' order by 1),
          array['x0c_probe_r1 R1 <> / not in', 'x0c_probe_r2 R2 not (... = ...)',
                'x0c_probe_r3 R3 sql-hilfe vergleicht nackt', 'x0c_probe_var R1 <> / not in'],
          'C Gegenprobe: R1, R2, R3 und Variable erkannt, sichere Schreibweisen nicht');
select is(array(select pol || ' ' || muster from pg_temp.null_offene_policies() order by 1),
          array['public.x0c_probe_tab.x0c_probe_offen P distinct from'],
          'C Gegenprobe: Policy mit is not distinct from erkannt');
drop table public.x0c_probe_tab;
drop function public.x0c_probe_r1(uuid), public.x0c_probe_r2(uuid), public.x0c_probe_var(uuid),
              public.x0c_probe_r3(uuid), public.x0c_probe_sicher(uuid);

-- ============================================================================
-- D · Gegenprobe: A2-Fix in erklaer_nachlesen testweise zuruecknehmen
-- Vorher (Stand X0b): "if not (... or get_my_student_id() = p_student_id or ...)".
-- ============================================================================
select pg_temp.act_as(:'admin');
select public.erklaer_nachlesen(:'k1', 'zz_a2_n1') as admin_vorher \gset
select pg_temp.act_as(:'coach_a');
select public.erklaer_nachlesen(:'k1', 'zz_a2_n1') as coach_vorher \gset

select pg_get_functiondef('public.erklaer_nachlesen(uuid,text)'::regprocedure) as def_fix \gset
select regexp_replace(
         replace(:'def_fix', 'if not coalesce(coalesce(public.get_my_role(), '''') = ''admin''',
                             'if not (coalesce(public.get_my_role(), '''') = ''admin'''),
         ',\s*false\) then(\s*raise exception ''erklaer_nachlesen: kein Zugriff'')', ') then\1') as def_alt \gset
select isnt(:'def_alt'::text, :'def_fix'::text, 'D Ruecknahme greift (Text geaendert)');
select ok(:'def_alt' !~ 'false\) then\s*raise exception ''erklaer_nachlesen: kein Zugriff''',
          'D Ruecknahme: coalesce(..., false) um das Tor ist weg');
select is(pg_temp.fehler(:'def_alt'), 'kein Fehler', 'D Ruecknahme eingespielt');

select is(array(select muster from pg_temp.null_offene_pruefungen() where proname = 'erklaer_nachlesen'),
          array['R2 not (... = ...)'], 'D Waechter schlaegt bei der Ruecknahme an');
select is(pg_temp.probe(k.uid, format($$select public.erklaer_nachlesen(%L, 'zz_a2_n1')$$, :'k1')), 'kein Fehler',
          'D ohne Fix: ' || k.konto || ' bekommt Zeilen statt 42501') from konten k order by k.nr;
select pg_temp.act_as(:'admin');
select is(public.erklaer_nachlesen(:'k1', 'zz_a2_n1'), :'admin_vorher'::jsonb, 'D Admin: dasselbe Ergebnis mit und ohne Fix');
select pg_temp.act_as(:'coach_a');
select is(public.erklaer_nachlesen(:'k1', 'zz_a2_n1'), :'coach_vorher'::jsonb, 'D Coach der Session: dasselbe Ergebnis');

-- Fix wieder herstellen: Waechter still, Proben wieder 42501.
select is(pg_temp.fehler(:'def_fix'), 'kein Fehler', 'D Fix wieder eingespielt');
select is(array(select sig from pg_temp.null_offene_pruefungen() where proname = 'erklaer_nachlesen'),
          '{}'::text[], 'D Fix zurueck: Waechter still');
select is(pg_temp.probe(k.uid, format($$select public.erklaer_nachlesen(%L, 'zz_a2_n1')$$, :'k1')), '42501',
          'D Fix zurueck: ' || k.konto || ' -> 42501') from konten k order by k.nr;

select * from finish();
rollback;
