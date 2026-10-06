-- E1.2 Hinweis-Status (Bauauftrag Session-P1, Entscheidungen 5 und 20).
--
-- Hinweis-Objekte in task_solutions.hints bekommen ein Feld status ('entwurf' |
-- 'geprueft'). Vorhandene Hinweise ohne Status gelten als entwurf; es gibt keine
-- Datenmigration (Prod: 93 Aufgaben mit Hinweisen, 0 mit status, dbread 06.10.).
--
-- Regel "der Status haengt am Text" (Trigger hinweise_status_folgt_text):
--   - Aendert sich der Text eines Hinweises (gleiches level), faellt er auf entwurf.
--   - Bleibt der Text gleich, bleibt der alte Status, egal was der Schreiber mitschickt.
--     So verliert der Admin-Editor (editorState.ts schickt nur {level, text}) beim
--     Speichern keinen geprueften Hinweis, und ein geaenderter Hinweis geht nie
--     ungeprueft an ein Kind.
--   - Neue Zeilen (INSERT) bekommen fuer jeden Hinweis entwurf.
-- Den Status setzen nur Pruefer und Admin ueber hinweis_status_setzen; nur diese Funktion
-- (bzw. eine Migration, die es ausdruecklich will) setzt transaktionslokal das Flag
-- edvance.hinweis_status = 'setzen', mit dem der Trigger den neuen Status uebernimmt.
-- lsa_hint liefert nur geprueft (gleiche Signatur, gleiche Rueckgabe, gleiche Rechte).

create function public.hinweise_status_gueltig(p_hints jsonb) returns boolean
language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_typeof(p_hints) <> 'array'
      or not exists (select 1 from jsonb_array_elements(p_hints) h
                      where h ? 'status'
                        and coalesce(h ->> 'status', '') not in ('entwurf', 'geprueft'))
$$;

alter table public.task_solutions
  add constraint task_solutions_hints_status_check
  check (public.hinweise_status_gueltig(hints));

create function public.hinweise_status_folgt_text() returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_setzen boolean := coalesce(current_setting('edvance.hinweis_status', true), '') = 'setzen';
  v_alt    jsonb   := case when tg_op = 'UPDATE' and jsonb_typeof(old.hints) = 'array' then old.hints else '[]' end;
begin
  if jsonb_typeof(new.hints) <> 'array' or (tg_op = 'UPDATE' and new.hints is not distinct from old.hints) then
    return new;
  end if;
  new.hints := coalesce((
    select jsonb_agg(
             case
               when v_setzen and n.h ? 'status' then n.h
               when a.h is null or a.h ->> 'text' is distinct from n.h ->> 'text'
                 then n.h || '{"status":"entwurf"}'
               else n.h || jsonb_build_object('status', coalesce(a.h -> 'status', '"entwurf"'))
             end order by n.ord)
      from jsonb_array_elements(new.hints) with ordinality as n(h, ord)
      left join lateral (
        select o.h from jsonb_array_elements(v_alt) as o(h)
         where o.h ->> 'level' = n.h ->> 'level'
         limit 1) a on true), '[]'::jsonb);
  return new;
end;
$$;

create trigger task_solutions_hinweise_status
  before insert or update of hints on public.task_solutions
  for each row execute function public.hinweise_status_folgt_text();

create or replace function public.lsa_hint(p_session_id uuid, p_task_id uuid, p_level integer default 1)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_session lsa_sessions;
  v_hint    jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not (p_task_id = any (v_session.item_ids)) then
    raise exception 'LSA: Item gehoert nicht zu dieser Session' using errcode = 'P0001';
  end if;

  -- Entscheidung 20: nur geprueft. Ohne Status gilt ein Hinweis als entwurf.
  select h
    into v_hint
    from task_solutions s,
         lateral jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id
     and (h ->> 'level')::int = p_level
     and h ->> 'status' = 'geprueft'
   limit 1;

  if v_hint is null then
    return jsonb_build_object('level', p_level, 'text', null, 'available', false);
  end if;

  return jsonb_build_object(
    'level',     p_level,
    'text',      v_hint ->> 'text',
    'available', true
  );
end;
$$;

create function public.hinweis_status_setzen(p_task_id uuid, p_level integer, p_status text)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_hints jsonb;
begin
  if not public.darf_pruefen() then
    raise exception 'hinweis_status_setzen: nur Pruefer oder Admin' using errcode = '42501';
  end if;
  if p_status is null or p_status not in ('entwurf', 'geprueft') then
    raise exception 'hinweis_status_setzen: Status entwurf oder geprueft' using errcode = '22023';
  end if;

  select hints into v_hints from public.task_solutions where task_id = p_task_id for update;
  if v_hints is null or not exists (select 1 from jsonb_array_elements(v_hints) h
                                     where (h ->> 'level')::int = p_level) then
    raise exception 'hinweis_status_setzen: Hinweis nicht gefunden' using errcode = 'P0002';
  end if;

  perform set_config('edvance.hinweis_status', 'setzen', true);
  update public.task_solutions
     set hints = (select jsonb_agg(case when (h ->> 'level')::int = p_level
                                        then h || jsonb_build_object('status', p_status)
                                        else h end order by ord)
                    from jsonb_array_elements(v_hints) with ordinality as e(h, ord)),
         updated_at = now()
   where task_id = p_task_id
  returning hints into v_hints;
  perform set_config('edvance.hinweis_status', '', true);
  return v_hints;
end;
$$;

comment on function public.hinweis_status_setzen(uuid, integer, text) is
  'Setzt den Pruefstatus eines Hinweises (entwurf/geprueft). Nur darf_pruefen(). Pruefoberflaeche folgt in P2.';

revoke all on function public.hinweise_status_gueltig(jsonb) from public, anon, authenticated;
revoke all on function public.hinweise_status_folgt_text() from public, anon, authenticated;
revoke all on function public.hinweis_status_setzen(uuid, integer, text) from public, anon, authenticated;
grant execute on function public.hinweis_status_setzen(uuid, integer, text) to authenticated;
