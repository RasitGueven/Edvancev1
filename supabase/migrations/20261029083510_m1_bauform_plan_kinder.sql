-- M1 Phase 2 · Kinder für den Plan-Umschalter der Muster-Prüfung (/coach/pruefen/bauformen)
--
-- bauform_plan_kinder(): Kinder mit aktiver Reihe (reihen.status = 'aktiv'), mit Namen und Reihe, nur mit Prüfrecht
-- (darf_pruefen, wie bauform_pruef_plan). reihen selbst lesen nur Admin und Coaches mit Vertrag (lernpfad_darf_lesen);
-- Lena braucht nur Name und ID, um bauform_pruef_plan(p_student_id) aufzurufen. Testkinder (students.ist_test)
-- bleiben drin, damit der Umschalter vor dem ersten echten Kind prüfbar ist; das Flag geht mit.
--
-- Rollback: supabase/rollback/20261029083510_m1_bauform_plan_kinder.sql.

create function public.bauform_plan_kinder()
returns table(student_id uuid, name text, ist_test boolean, reihe_id uuid)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'bauform_plan_kinder: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  select s.id, coalesce(nullif(btrim(p.full_name), ''), nullif(btrim(l.full_name), ''), s.id::text),
         coalesce(s.ist_test, false), r.id
    from public.reihen r
    join public.students s on s.id = r.student_id
    left join public.profiles p on p.id = s.profile_id
    left join public.leads l on l.id = s.lead_id
   where r.status = 'aktiv'
   order by 2, s.id;
end;
$$;

comment on function public.bauform_plan_kinder() is 'reihe1 fertig';
revoke all on function public.bauform_plan_kinder() from public, anon;
grant execute on function public.bauform_plan_kinder() to authenticated;
