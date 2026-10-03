-- Keine eigene Aufgabe ist bisher fachlich freigegeben: Die ready-Staende stammen aus
-- Migrationen (reviewed_by leer) oder aus Tests am Board. Alles geht durch Lenas
-- Freigabe. Eigene Aufgaben (nicht VERA8) von ready zurueck auf draft,
-- Pruefvermerk leeren. VERA8 bleibt unberuehrt (nicht im Board).
do $$
declare n int;
begin
  update tasks
     set status = 'draft', reviewed_by = null, reviewed_at = null
   where status = 'ready'
     and source is distinct from 'VERA8_IQB';
  get diagnostics n = row_count;
  if n > 256 then raise exception 'Erwartet hoechstens 256 Aufgaben, gefunden %', n; end if;
  raise notice 'zurueckgesetzt: %', n;
end $$;
