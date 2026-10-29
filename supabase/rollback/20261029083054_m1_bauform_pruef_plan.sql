-- Rollback zu 20261029083054_m1_bauform_pruef_plan: Plan-Funktionen weg, bauform_freigeben zurück auf zwei Parameter
-- (Wortlaut wie in Prod vor M1, aus pg_get_functiondef), Stellschraube weg. Danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen. Freigaben, die über p_schluessel liefen, bleiben bestehen.
drop function if exists public.bauform_pruef_plan(uuid);
drop function if exists public.bauform_plan_standard();
delete from public.session_einstellungen where schluessel = 'reihe_standard_sessions';
drop function if exists public.bauform_freigeben(text, text, text[]);

CREATE OR REPLACE FUNCTION public.bauform_freigeben(p_reihe text DEFAULT NULL::text, p_thema_key text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  b record;
  t record;
  n int := 0;
begin
  perform public.pruef_nur_admin('bauform_freigeben');
  if (p_reihe is null) = (p_thema_key is null) then
    raise exception 'bauform_freigeben: genau eins von Reihe oder Thema' using errcode = '22023';
  end if;
  for b in
    select x.* from public.bauformen x
     where x.status = 'zur_freigabe'
       and (x.reihe = p_reihe
            or exists (select 1 from public.skill_thema st where st.skill_key = x.skill_key and st.thema_key = p_thema_key))
     for update
  loop
    update public.bauformen set status = 'freigegeben', freigegeben_am = now(), freigegeben_von = auth.uid()
     where id = b.id;
    for t in
      select k.id from public.tasks k
       where k.bauform_id = b.id and k.bauform_version = b.version and k.status in ('draft', 'review')
         and public.instanz_gruen(k.pruefmaschine)
    loop
      update public.tasks set status = 'ready', is_active = true, reviewed_by = auth.uid(), reviewed_at = now()
       where id = t.id;
      perform public.pruef_hinweise_setzen(t.id, 'geprueft');
      insert into public.aufgabe_bewaehrung (task_id) values (t.id) on conflict do nothing;
      insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von)
      values (t.id, 'freigeben', '[]'::jsonb, format('Bauform %s v%s', b.schluessel, b.version), true, auth.uid());
    end loop;
    n := n + 1;
  end loop;
  return n;
end $function$
;

comment on function public.bauform_freigeben(text, text) is 'reihe1 fertig';
revoke all on function public.bauform_freigeben(text, text) from public, anon;
grant execute on function public.bauform_freigeben(text, text) to authenticated;
