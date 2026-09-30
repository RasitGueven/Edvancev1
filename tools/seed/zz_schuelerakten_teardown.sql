-- Entfernt restlos, was tools/seed/zz_schuelerakten_seed.sql angelegt hat — und
-- sonst nichts. Kennung: leads.full_name beginnt mit 'ZZ_S2B ',
-- coaching_sessions.room = 'ZZ_S2B'.
--
-- Reihenfolge nach den Fremdschluesseln:
--   1. Seed-Sessions (Kaskade: session_students)
--   2. Vertraege der Seed-Leads (vertraege -> leads/students ON DELETE RESTRICT)
--   3. Kinder aus diesen Vertraegen (Kaskade: schueler_notizen, eltern_reports,
--      session_students und die uebrigen student_*-Tabellen)
--   4. Seed-Leads
-- Am Ende prueft der Block, dass keine Zeile mit der Kennung uebrig ist.
--
-- Ausfuehren:  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_teardown.sql

do $$
declare
  c_marke  constant text := 'ZZ_S2B';
  v_leads  uuid[];
  v_kinder uuid[];
  v_n      integer;
begin
  select coalesce(array_agg(id), '{}') into v_leads from public.leads where full_name like c_marke || ' %';
  select coalesce(array_agg(distinct student_id), '{}') into v_kinder
    from public.vertraege where lead_id = any(v_leads) and student_id is not null;

  -- Nur Kinder, die ausschliesslich Seed-Vertraege haben (Schutz vor Fremddaten).
  if exists (select 1 from public.vertraege v
              where v.student_id = any(v_kinder) and not (v.lead_id = any(v_leads))) then
    raise exception 'Teardown %: ein Seed-Kind hat einen fremden Vertrag — Abbruch, nichts geloescht', c_marke;
  end if;
  if exists (select 1 from public.session_students ss join public.coaching_sessions cs on cs.id = ss.session_id
              where cs.room = c_marke and not (ss.student_id = any(v_kinder))) then
    raise exception 'Teardown %: eine Seed-Session hat fremde Teilnehmer — Abbruch, nichts geloescht', c_marke;
  end if;

  delete from public.coaching_sessions where room = c_marke;
  get diagnostics v_n = row_count; raise notice 'Sessions: %', v_n;

  perform set_config('edvance.vertrag_rpc', '1', true);
  delete from public.vertraege where lead_id = any(v_leads);
  get diagnostics v_n = row_count; raise notice 'Vertraege: %', v_n;

  delete from public.students where id = any(v_kinder);
  get diagnostics v_n = row_count; raise notice 'Kinder: %', v_n;

  delete from public.leads where id = any(v_leads);
  get diagnostics v_n = row_count; raise notice 'Leads: %', v_n;

  -- Kontrolle
  if exists (select 1 from public.leads where full_name like c_marke || ' %')
     or exists (select 1 from public.coaching_sessions where room = c_marke)
     or exists (select 1 from public.students where id = any(v_kinder))
     or exists (select 1 from public.schueler_notizen where text like c_marke || '%')
     or exists (select 1 from public.eltern_reports where kernaussagen::text like '%' || c_marke || '%') then
    raise exception 'Teardown %: es ist noch etwas uebrig', c_marke;
  end if;
  raise notice 'Teardown %: nichts mehr uebrig', c_marke;
end;
$$;
