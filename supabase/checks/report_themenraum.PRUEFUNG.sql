-- PRUEFUNG zu W5-d (Themenraum beim LSA-Abschluss sichern).
--
--   ~/bin/dbread -f supabase/checks/report_themenraum.PRUEFUNG.sql
--
-- AUSSCHLIESSLICH lesend — laeuft nach dem Einspielen von
--   20261004001437_lsa_finish_themenraum
--   20261004001517_lsa_themenraum_nachtrag
-- gegen Prod. Jede verletzte Bedingung bricht mit raise exception ab; laeuft
-- das Skript bis zur Uebersicht durch, ist alles gehalten. Der schreibende Test
-- (lsa_finish schreibt das Feld, bestehende Felder unveraendert) steht in
-- supabase/tests/lsa_finish_themenraum.test.sql.

\pset pager off

do $$
declare
  v_n   int;
  v_def text;
begin
  -- 1. Beide Migrationen sind eingetragen.
  select count(*) into v_n
    from supabase_migrations.schema_migrations
   where version in ('20261004001437', '20261004001517');
  if v_n <> 2 then
    raise exception 'Migrationen eingetragen: % von 2', v_n;
  end if;

  -- 2. lsa_themenraum existiert und ist nur intern ausfuehrbar.
  if to_regprocedure('public.lsa_themenraum(text)') is null then
    raise exception 'public.lsa_themenraum(text) fehlt';
  end if;
  if has_function_privilege('authenticated', 'public.lsa_themenraum(text)', 'execute')
     or has_function_privilege('anon', 'public.lsa_themenraum(text)', 'execute') then
    raise exception 'lsa_themenraum ist fuer anon/authenticated ausfuehrbar';
  end if;

  -- 3. lsa_finish schreibt das Feld.
  v_def := pg_get_functiondef('public.lsa_finish(uuid)'::regprocedure);
  if position('lsa_themenraum(v_session.thema_key)' in v_def) = 0 then
    raise exception 'lsa_finish schreibt keinen Themenraum';
  end if;

  -- 4. Jede abgeschlossene Sitzung mit Thema hat einen Themenraum.
  select count(*) into v_n from lsa_sessions
   where status = 'completed' and thema_key is not null
     and result_summary is not null
     and not (result_summary ? 'themenraum');
  if v_n > 0 then
    raise exception '% abgeschlossene Sitzungen mit Thema ohne Themenraum', v_n;
  end if;

  -- 5. Keine Sitzung ohne Thema hat einen.
  select count(*) into v_n from lsa_sessions
   where thema_key is null and result_summary ? 'themenraum';
  if v_n > 0 then
    raise exception '% Sitzungen ohne Thema mit Themenraum', v_n;
  end if;

  -- 6. Form: thema_key passt, zwei Arrays, stand gesetzt, Einstiege nicht darunter.
  select count(*) into v_n from lsa_sessions s
   where s.result_summary ? 'themenraum'
     and (   s.result_summary -> 'themenraum' ->> 'thema_key' is distinct from s.thema_key
          or jsonb_typeof(s.result_summary -> 'themenraum' -> 'einstieg') <> 'array'
          or jsonb_typeof(s.result_summary -> 'themenraum' -> 'darunter') <> 'array'
          or coalesce(s.result_summary -> 'themenraum' ->> 'stand', '') = ''
          or (s.result_summary -> 'themenraum' -> 'darunter')
               ?| array(select jsonb_array_elements_text(s.result_summary -> 'themenraum' -> 'einstieg')));
  if v_n > 0 then
    raise exception '% Themenraeume mit falscher Form', v_n;
  end if;

  -- 7. Der Nachtrag entspricht dem heutigen Stand (er ist gerade erst gelaufen).
  select count(*) into v_n from lsa_sessions s
   where s.result_summary -> 'themenraum' ->> 'stand' = 'nachgetragen'
     and (s.result_summary -> 'themenraum') - 'stand' <> public.lsa_themenraum(s.thema_key);
  if v_n > 0 then
    raise exception '% nachgetragene Themenraeume weichen vom heutigen Stand ab', v_n;
  end if;

  -- 8. Die bisherigen Felder sind noch da.
  select count(*) into v_n from lsa_sessions
   where status = 'completed' and result_summary ? 'themenraum'
     and not (result_summary ?& array['answered', 'planned', 'competencies', 'afb', 'proposal']);
  if v_n > 0 then
    raise exception '% Sitzungen mit Themenraum, aber ohne die bisherigen Felder', v_n;
  end if;

  raise notice 'report_themenraum: alle Bedingungen gehalten';
end $$;

-- Uebersicht
select count(*) filter (where status = 'completed')                                   as abgeschlossen,
       count(*) filter (where status = 'completed' and thema_key is not null)         as mit_thema,
       count(*) filter (where result_summary -> 'themenraum' ->> 'stand' = 'nachgetragen') as nachgetragen,
       count(*) filter (where result_summary ? 'themenraum'
                          and result_summary -> 'themenraum' ->> 'stand' <> 'nachgetragen') as beim_abschluss
  from lsa_sessions;
