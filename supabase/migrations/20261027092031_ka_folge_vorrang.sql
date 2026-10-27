-- L5 Teil A, Nachtrag aus der Zweitprüfung (docs/report/Bauauftrag-L5.md, Entscheidungen 4 und 8): eigene Angaben
-- ohne Nummer gehen vor.
--
-- Erstgespräch und Check-in erfassen keine Nummer der Arbeit. In 20261027081403 unterdrückten deshalb nur eigene
-- Arbeiten MIT Nummer den Schulwert; eine eigene Arbeit ohne Nummer stand neben der Arbeit der Schule, und der
-- Bericht zeigte Datum und Stand der Klasse statt der eigenen. Neu in ka_folge_lead: Teilt eine eigene Arbeit ohne
-- Nummer ein Thema mit einer gültigen Arbeit der Schule, ist sie diese Arbeit. Die Nummer kommt aus der Klasse
-- (herkunft 'schule'), Themen, Datum, Stand und Note bleiben die eigenen; die Arbeit der Schule entfällt. Je eigene
-- Arbeit höchstens eine Nummer, je Nummer höchstens eine eigene Arbeit (die kleinere Nummer bzw. die frühere Arbeit).
--
-- Nur ka_folge_lead ändert sich (gleiche Signatur, gleiche Rechte). Rollback:
-- supabase/rollback/20261027092031_ka_folge_vorrang.sql.

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
    select k.id, k.nr, k.thema_keys, k.datum, k.status, k.note
      from public.lead_klassenarbeiten k
     where k.lead_id = p_lead_id and k.schuljahr = p_schuljahr and k.fach = p_fach
  ), gueltig as (
    -- Gültige Arbeiten der Schule mit Nummer, soweit keine eigene Arbeit mit Nummer sie abdeckt.
    select s.nr, s.thema_keys, s.datum
      from public.ka_folge_schule_roh(v_schule, v_klasse, p_schuljahr, p_fach) s
     where v_schule is not null and v_klasse is not null and s.gueltig and s.nr is not null
       and not exists (select 1 from eigene e
                        where e.nr is not null and (e.nr = s.nr or e.thema_keys && s.thema_keys))
  ), kandidat as (
    select distinct on (e.id) e.id, e.datum, g.nr
      from eigene e join gueltig g on e.nr is null and e.thema_keys && g.thema_keys
     order by e.id, g.nr
  ), treffer as (
    select distinct on (c.nr) c.id, c.nr from kandidat c order by c.nr, c.datum nulls last, c.id
  )
  select coalesce(e.nr, t.nr), e.thema_keys, coalesce(e.datum, g.datum), e.status, e.note,
         case when t.nr is null then 'eigen' else 'schule' end
    from eigene e
    left join treffer t on t.id = e.id
    left join gueltig g on g.nr = t.nr
  union all
  select g.nr, g.thema_keys, g.datum, null::text, null::smallint, 'schule'::text
    from gueltig g
   where not exists (select 1 from treffer t where t.nr = g.nr)
   order by 1 nulls last, 3 nulls last;
end;
$$;

comment on function public.ka_folge_lead(uuid, text, text) is
  'L5: Mathearbeiten fuer den Bericht eines Kindes: eigene Zeilen (ohne Nummer mit der Nummer einer gueltigen Arbeit der Klasse, die ein Thema teilt), dazu die uebrige gueltige Schulfolge.';
