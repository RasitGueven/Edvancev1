-- Rollback zu ka_folge_vorrang: ka_folge_lead wieder in der Fassung aus 20261027081403_ka_folge (eigene Arbeiten ohne
-- Nummer stehen neben dem Schulwert), danach den Eintrag in supabase_migrations.schema_migrations löschen.
create or replace function public.ka_folge_lead(p_lead_id uuid, p_schuljahr text, p_fach text default 'mathematik')
returns table (nr int, thema_keys text[], datum date, status text, note smallint, herkunft text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_schule uuid;
  v_klasse int;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'ka_folge_lead: nur Admin' using errcode = '42501';
  end if;
  select l.schule_id, l.class_level into v_schule, v_klasse from public.leads l where l.id = p_lead_id;
  return query
  with eigene as (
    select k.nr, k.thema_keys, k.datum, k.status, k.note
      from public.lead_klassenarbeiten k
     where k.lead_id = p_lead_id and k.schuljahr = p_schuljahr and k.fach = p_fach
  ), schule as (
    select s.nr, s.thema_keys, s.datum
      from public.ka_folge_schule_roh(v_schule, v_klasse, p_schuljahr, p_fach) s
     where v_schule is not null and v_klasse is not null and s.gueltig and s.nr is not null
       and not exists (select 1 from eigene e
                        where e.nr is not null and (e.nr = s.nr or e.thema_keys && s.thema_keys))
  )
  select e.nr, e.thema_keys, e.datum, e.status, e.note, 'eigen'::text from eigene e
  union all
  select s.nr, s.thema_keys, s.datum, null::text, null::smallint, 'schule'::text from schule s
   order by 1 nulls last, 3 nulls last;
end;
$$;
