-- Reihe 1 · A3 Formate: Figuren (Generator parabel, Optionen der Graph-Auswahl) und Kindersicht.
--
--   task_figures.generator      + 'parabel' (scripts/figures/parabel.py, pruefe_parabel.py)
--   task_figur_optionen         je Option einer Graph-Auswahl eine Figur (task_figures traegt nur eine je Aufgabe):
--                               (task_id, option_id, generator, params, alt_text, svg_hash, erzeugt_am).
--                               upload_figures.py laedt sie nach generiert/<task_id>/option-<id>-<theme>.svg.
--   format_kindersicht(task, payload)   setzt bei graph_auswahl je Option bild und bild_hell (nur hochgeladene)
--   aufgabe_payload             nutzt format_kindersicht (sonst unveraendert)
--   aufgabe_ziehbar             eine Graph-Auswahl ist erst ziehbar, wenn jede Option ihr Bild hat


create table public.task_figur_optionen (
  task_id    uuid not null references public.tasks (id) on delete cascade,
  option_id  text not null check (option_id ~ '^[a-z0-9]{1,8}$'),
  generator  text not null check (generator = 'parabel'),
  params     jsonb not null,
  alt_text   text not null check (btrim(alt_text) <> '' and alt_text !~ '[0-9]'),
  svg_hash   text,
  erzeugt_am timestamptz,
  primary key (task_id, option_id)
);
alter table public.task_figur_optionen enable row level security;
create policy task_figur_optionen_pruefer_lesen on public.task_figur_optionen for select to authenticated
  using (public.darf_pruefen());
revoke all on public.task_figur_optionen from anon, authenticated;
grant select on public.task_figur_optionen to authenticated;

create function public.format_kindersicht(p_task uuid, p_payload jsonb)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when p_payload ->> 'format' = 'graph_auswahl' then
      jsonb_set(p_payload, '{optionen}', coalesce((
        select jsonb_agg(o || jsonb_strip_nulls(jsonb_build_object(
                 'bild', case when f.svg_hash is not null then public.lsa_storage_base() || 'generiert/' || p_task::text
                                                              || '/option-' || f.option_id || '-dunkel.svg' end,
                 'bild_hell', case when f.svg_hash is not null then public.lsa_storage_base() || 'generiert/'
                                                                    || p_task::text || '/option-' || f.option_id || '-hell.svg' end,
                 'alt', coalesce(f.alt_text, o ->> 'alt')))
               order by n)
          from jsonb_array_elements(p_payload -> 'optionen') with ordinality e(o, n)
          left join public.task_figur_optionen f on f.task_id = p_task and f.option_id = o ->> 'id'), '[]'::jsonb))
    else p_payload end
$$;
revoke all on function public.format_kindersicht(uuid, jsonb) from public, anon, authenticated;

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
                            'payload', public.format_kindersicht(t.id, t.question_payload));
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

-- aufgabe_ziehbar (A2) zusaetzlich mit den Bildern der Graph-Auswahl.
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
                        where w.task_id = t.id and w.status in ('pausiert', 'auffaellig'))
       -- A3: eine Graph-Auswahl erst, wenn jede Option ihr hochgeladenes Bild hat (Zweitpruefung A3, Befund 11).
       and (t.input_type <> 'GRAPH_AUSWAHL'
            or (jsonb_array_length(coalesce(t.question_payload -> 'optionen', '[]')) >= 2
                and not exists (select 1 from jsonb_array_elements(coalesce(t.question_payload -> 'optionen', '[]')) o
                                 where not exists (select 1 from public.task_figur_optionen f
                                                    where f.task_id = t.id and f.option_id = o ->> 'id'
                                                      and f.svg_hash is not null)))))
$$;
revoke all on function public.aufgabe_ziehbar(uuid) from public, anon, authenticated;

-- Zuletzt, damit test_upload_figures.py die Positivliste hier abliest (Text nach dem letzten Constraint-Namen).
alter table public.task_figures drop constraint task_figures_generator_check;
alter table public.task_figures add constraint task_figures_generator_check
  check (generator = any (array['koordinatensystem', 'winkel', 'thales', 'rechtecke', 'rechteck', 'parabel']::text[]));
