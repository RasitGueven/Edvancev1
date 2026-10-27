-- Reihe 1 · D4 Themenliste des Themenbaums (Bauauftrag D, Anforderung Themenbaum §4 „Links: alle Themen“).
--
-- Das Kind darf skill_thema und schul_themenplan nicht lesen. themenbaum_themen liefert ihm deshalb die Themen in der
-- Reihenfolge, die das System festlegt — ohne Quelle (Schulplan oder Lehrplan NRW sieht das Kind nicht):
--   Mit Schulplan: der Doppeljahrgang des Kindes in der Reihenfolge der Schule (Thema des anderen Jahrgangs mit
--   „Kl. 10“, in beiden Jahrgängen einmal mit „9–10“), danach die früheren Doppeljahrgänge nach Lehrplan, der
--   nächstliegende zuerst. Ohne Schulplan: eigener Doppeljahrgang, dann was noch kommt, dann die früheren.
-- Je Thema: Skills (skill_thema), „aktuell“ (lead_themen aktuell oder Thema einer bevorstehenden Klassenarbeit),
-- „behandelt“ (lead_themen behandelt). plan_von/plan_bis: Klassen im Schulplan (die App zeigt daraus „Kl. 10“ oder
-- „9–10“, wenn es nicht die eigene Klasse ist). Ein Plan-Thema aus einem früheren Doppeljahrgang erscheint nur einmal,
-- an seiner Stelle im Plan. Zustände und Level rechnet die App aus kompetenz_offen.
-- Rollback: supabase/rollback/20261027141641_reihe1_d4_themenbaum.sql.

create function public.themenbaum_themen(p_kind uuid)
returns table (thema_key text, label text, gruppe integer, reihenfolge integer, plan_von integer, plan_bis integer,
               aktuell boolean, behandelt boolean, skill_keys text[])
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_klasse integer;
  v_schule uuid;
  v_dj     integer;
  v_plan   boolean;
begin
  if not public.home_darf_lesen(p_kind) then
    raise exception 'themenbaum_themen: kein Zugriff' using errcode = '42501';
  end if;
  select s.class_level, s.schule_id into v_klasse, v_schule from public.students s where s.id = p_kind;
  -- Doppeljahrgang nach Kernlehrplan G9: 5/6, 7/8, 9/10 (Startklasse 5, 7, 9).
  v_dj := case when v_klasse is null then 9 else greatest(5, least(9, v_klasse - ((v_klasse - 5) % 2))) end;
  v_plan := v_schule is not null and exists (
    select 1 from public.schul_themenplan p where p.schule_id = v_schule and p.fach = 'mathematik' and p.klasse in (v_dj, v_dj + 1));

  return query
  with leads_kind as (
    select l.id from public.leads l where l.converted_student_id = p_kind
    union select s.lead_id from public.students s where s.id = p_kind and s.lead_id is not null
  ),
  stand as (
    select t.thema_key, bool_or(t.status = 'aktuell') as aktuell, bool_or(t.status = 'behandelt') as behandelt
      from public.lead_themen t where t.lead_id in (select id from leads_kind) group by t.thema_key
  ),
  ka as (
    select distinct unnest(k.thema_keys) as thema_key from public.lead_klassenarbeiten k
     where k.lead_id in (select id from leads_kind) and k.status = 'bevorstehend'
       and (k.datum is null or k.datum >= (now() at time zone 'Europe/Berlin')::date)
  ),
  plan as (
    select p.thema_key, min(p.klasse * 1000 + p.position) as pos, min(p.klasse) as von, max(p.klasse) as bis
      from public.schul_themenplan p
     where v_plan and p.schule_id = v_schule and p.fach = 'mathematik' and p.klasse in (v_dj, v_dj + 1)
     group by p.thema_key
  ),
  themen_kind as (
    select t.thema_key, t.label, t.klasse as gruppe, t.sort,
           pl.pos, pl.von, pl.bis
      from public.themen t
      left join plan pl on pl.thema_key = t.thema_key
     where t.fach = 'mathematik'
  )
  select tk.thema_key, tk.label, coalesce(case when tk.pos is not null then v_dj end, tk.gruppe),
         (row_number() over (order by
            -- Blöcke: 0 eigener Doppeljahrgang, 1 was noch kommt (nur ohne Schulplan), 2 früher (nächstliegend zuerst)
            case when tk.pos is not null or tk.gruppe = v_dj then 0
                 when tk.gruppe > v_dj then case when v_plan then 3 else 1 end
                 else 2 end,
            case when tk.pos is not null or tk.gruppe = v_dj then 0
                 when tk.gruppe < v_dj then -tk.gruppe else tk.gruppe end,
            -- Im Plan nicht zugeordnete Themen des eigenen Doppeljahrgangs am Ende des Blocks (Plan unvollständig).
            coalesce(tk.pos, 999999), tk.sort, tk.thema_key))::integer,
         tk.von, tk.bis,
         coalesce(st.aktuell, false) or exists (select 1 from ka where ka.thema_key = tk.thema_key),
         coalesce(st.behandelt, false),
         coalesce((select array_agg(x.skill_key order by x.skill_key) from public.skill_thema x where x.thema_key = tk.thema_key), '{}')
    from themen_kind tk
    left join stand st on st.thema_key = tk.thema_key
   order by 4;
end;
$$;

comment on function public.themenbaum_themen(uuid) is
  'Themenliste des Themenbaums in Systemreihenfolge (Schulplan des Doppeljahrgangs, sonst Kernlehrplan G9), ohne Quelle. '
  'Kind selbst, Coach mit aktiver Akte, Admin. reihe1 fertig';

revoke all on function public.themenbaum_themen(uuid) from public, anon;
grant execute on function public.themenbaum_themen(uuid) to authenticated;
