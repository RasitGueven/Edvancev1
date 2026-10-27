-- Rollback zu reihe1_a3_formate_figuren: aufgabe_payload in der A2-Fassung, format_kindersicht entfernen, Generator
-- parabel aus dem CHECK (bricht ab, solange eine Figur ihn nutzt). task_figur_optionen bleibt stehen (keine Tabellen
-- entfernen), ohne Policy und Rechte. Danach den Eintrag in supabase_migrations.schema_migrations NICHT loeschen.
create or replace function public.aufgabe_payload(p_task uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.tasks;
  b public.bauformen;
  v jsonb;
  v_loesung text;
begin
  if not public.aufgabe_lesbar(p_task) then
    raise exception 'aufgabe_payload: Aufgabe nicht freigegeben' using errcode = '42501';
  end if;
  select * into t from public.tasks where id = p_task;
  if not found then
    raise exception 'aufgabe_payload: Aufgabe nicht gefunden' using errcode = 'P0002';
  end if;
  select * into b from public.bauformen where id = t.bauform_id;

  if jsonb_typeof(t.question_payload) = 'object' and t.question_payload ? 'format' then
    -- Neue Formate (A3): question_payload IST die Kindersicht (CHECK tasks_question_payload_no_solution).
    v := jsonb_build_object('task_id', t.id, 'kind', 'format', 'prompt', coalesce(t.question, ''),
                            'assets', public.lsa_task_assets(t.id), 'format', t.question_payload ->> 'format',
                            'payload', t.question_payload);
  else
    v := public.lsa_question_payload(p_task) - 'themenfeld';
  end if;

  v := v || jsonb_strip_nulls(jsonb_build_object('rolle', t.rolle, 'stufe', t.stufe, 'bauform_key', b.schluessel));
  if t.rolle = 'beispiel' then
    select s.solution into v_loesung from public.task_solutions s where s.task_id = t.id;
    v := v || jsonb_build_object('loesungsbeispiel', jsonb_build_object(
      'aufgabe', coalesce(t.question, ''),
      'schritte', coalesce((select jsonb_agg(jsonb_build_object('text', btrim(z)) order by n)
                              from unnest(string_to_array(coalesce(v_loesung, ''), E'\n')) with ordinality u(z, n)
                             where btrim(z) <> ''), '[]'::jsonb),
      'warum', b.steckbrief -> 'warum'));
  end if;
  return v;
end $$;
comment on function public.aufgabe_payload(uuid) is 'reihe1 fertig';
create or replace function public.aufgabe_ziehbar(p_task uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.tasks t
      join public.bauformen b on b.id = t.bauform_id
     where t.id = p_task
       and b.status = 'freigegeben' and t.bauform_version = b.version
       and t.status = 'ready' and coalesce(t.is_active, false) and 'session' = any (t.einsatz)
       and public.instanz_gruen(t.pruefmaschine)
       and not exists (select 1 from public.aufgabe_bewaehrung w
                        where w.task_id = t.id and w.status in ('pausiert', 'auffaellig')))
$$;
revoke all on function public.aufgabe_ziehbar(uuid) from public, anon, authenticated;
drop function if exists public.format_kindersicht(uuid, jsonb);
drop policy if exists task_figur_optionen_pruefer_lesen on public.task_figur_optionen;
revoke all on public.task_figur_optionen from authenticated;
alter table public.task_figures drop constraint task_figures_generator_check;
alter table public.task_figures add constraint task_figures_generator_check
  check (generator = any (array['koordinatensystem', 'winkel', 'thales', 'rechtecke', 'rechteck']::text[]));
