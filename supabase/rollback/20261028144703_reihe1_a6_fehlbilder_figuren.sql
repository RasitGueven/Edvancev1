-- Rollback zu 20261028144703_reihe1_a6_fehlbilder_figuren: aufgabe_ziehbar wie in 20261027134927 (ohne Figur-Bedingung).
-- Die Fehlbild-Schluessel bleiben stehen (nicht loeschen; ungenutzte Schluessel schaden nicht).
-- Danach den Eintrag in supabase_migrations.schema_migrations loeschen.
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
       and (t.input_type <> 'GRAPH_AUSWAHL'
            or (jsonb_array_length(coalesce(t.question_payload -> 'optionen', '[]')) >= 2
                and not exists (select 1 from jsonb_array_elements(coalesce(t.question_payload -> 'optionen', '[]')) o
                                 where not exists (select 1 from public.task_figur_optionen f
                                                    where f.task_id = t.id and f.option_id = o ->> 'id'
                                                      and f.svg_hash is not null)))))
$$;
revoke all on function public.aufgabe_ziehbar(uuid) from public, anon, authenticated;
