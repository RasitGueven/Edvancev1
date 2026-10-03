-- VERA8-Aufgabe mit needs_image = true, aber ohne Abbildung (VERA-Bilder aus
-- Lizenzgruenden nicht hochgeladen). Sie stand auf ready und waere damit in der
-- LSA-Auswahl gelandet ("siehe Abbildung" ohne Bild). Zurueck auf draft.
do $$
declare n int;
begin
  update tasks t set status = 'draft'
   where t.status = 'ready'
     and t.class_level = 8 and t.needs_image
     and not exists (select 1 from task_figures f where f.task_id = t.id)
     and jsonb_array_length(case when jsonb_typeof(t.assets) = 'array' then t.assets else '[]'::jsonb end) = 0;
  get diagnostics n = row_count;
  if n > 1 then raise exception 'Erwartet hoechstens 1 Aufgabe, gefunden %', n; end if;
  raise notice 'zurueckgesetzt: %', n;
end $$;
