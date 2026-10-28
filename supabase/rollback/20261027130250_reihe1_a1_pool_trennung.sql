-- Rollback zu reihe1_a1_pool_trennung: Regeln und Guard zuruecknehmen, Default wiederherstellen,
-- danach den Eintrag in supabase_migrations.schema_migrations loeschen.
--
alter table public.tasks drop constraint if exists tasks_einsatz_ein_pool;
alter table public.tasks drop constraint if exists tasks_einsatz_nicht_leer;
-- Daten: vor A1 trugen alle Aufgaben {lsa,session} ausser diesen drei (dbread 27.10.2026: zwei {lsa}, eine {check}).
-- Neue Aufgaben, die nach A1 mit {session} angelegt wurden (Bauform-Instanzen), bleiben {session}.
alter table public.tasks disable trigger tasks_pruef_version;
update public.tasks set einsatz = '{lsa,session}'
 where einsatz = '{lsa}'
   and id not in ('a368a0d0-25fd-4cc9-a873-541afbb9e864', '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24',
                  '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13')
   and created_at < '2026-10-27 13:02:50+00';
alter table public.tasks enable trigger tasks_pruef_version;
alter table public.tasks alter column einsatz set default '{lsa,session}';
comment on column public.tasks.einsatz is
  'Einsatz (Entscheidung 28): lsa, session, check, quest. Bestand: {lsa,session}. Check-Aufgaben der Erklaersequenz nur {check}.';

create or replace function public.tasks_pruefer_guard()
returns trigger
language plpgsql
as $$
begin
  if current_user = 'authenticated'
     and public.get_my_role() is distinct from 'admin' then
    if new.status      is distinct from old.status
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'Freigabe: Status nur ueber task_status_set / lena_beanstande'
        using errcode = '42501';
    end if;
    -- Herkunft und Steuerung des Bestands pflegt der Pruefer nicht: sie
    -- entscheiden, woher eine Aufgabe kommt und ob/wie die LSA sie zieht.
    if new.id is distinct from old.id
       or new.source        is distinct from old.source
       or new.source_ref    is distinct from old.source_ref
       or new.created_at    is distinct from old.created_at
       or new.content_type  is distinct from old.content_type
       or new.is_active     is distinct from old.is_active
       or new.is_diagnostic is distinct from old.is_diagnostic
       or new.is_tutorial   is distinct from old.is_tutorial
       or new.skill_key     is distinct from old.skill_key
       or new.sondierrang   is distinct from old.sondierrang then
      raise exception 'Freigabe: Herkunfts- und Steuerfelder aendert nur admin'
        using errcode = '42501';
    end if;
    if old.status = 'ready' then
      raise exception 'Freigabe: eine freigegebene Aufgabe aendert nur admin'
        using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

-- pruef_board ohne pool (Fassung vor A1, aus Prod abgezogen 27.10.2026).
drop function if exists public.pruef_board();
create function public.pruef_board()
 RETURNS TABLE(task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text, skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean, letzte_dauer_sek integer, anlaesse text[], hat_hinweise boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt, t.einsatz,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek,
         coalesce((select array_agg(ps.anlass order by ps.anlass) from public.pruef_soll ps
                    where ps.aktiv and ps.skill_key = b.sk_jetzt and ps.einsatz = any (b.einsatz)), '{}'::text[]),
         coalesce((select jsonb_array_length(ts.hints) > 0
                     from public.task_solutions ts where ts.task_id = b.id), false)
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $function$;
revoke all on function public.pruef_board() from public, anon;
grant execute on function public.pruef_board() to authenticated;
