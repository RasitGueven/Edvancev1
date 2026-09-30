-- freigabe_cluster ohne VERA8 (Nachtrag zu PR #176).
--
-- VERA8-Aufgaben erscheinen nicht mehr im Lena-Board (src/lib/authoring/vera8.ts).
-- "Alle geprueften freigeben" im Board ruft freigabe_cluster fuer ein ganzes
-- Themengebiet — ohne diese Bedingung wuerde es eine im Board unsichtbare
-- VERA8-Aufgabe im Status 'review' mit auf 'ready' setzen. Die Freigabe wirkt
-- damit genau auf das, was das Board zeigt. Sonst unveraendert (Signatur, Rechte,
-- Rueckgabe). Die Kennung 'VERA8_IQB' muss der in src/lib/authoring/vera8.json
-- entsprechen — vera8.test.ts prueft den Gleichlauf.

create or replace function public.freigabe_cluster(p_cluster_id uuid) returns integer
    language plpgsql security definer
    set search_path to 'public'
    as $$
declare
  v_id uuid;
  v_n  integer := 0;
begin
  if public.get_my_role() is distinct from 'admin' then
    raise exception 'freigabe_cluster: nur admin darf freigeben' using errcode = '42501';
  end if;

  for v_id in
    select id from public.tasks
     where cluster_id = p_cluster_id and status = 'review'
       and source is distinct from 'VERA8_IQB'
  loop
    begin
      perform public.task_status_set(v_id, 'ready');
      v_n := v_n + 1;
    exception
      when sqlstate 'P0001' then null;
    end;
  end loop;

  return v_n;
end $$;
