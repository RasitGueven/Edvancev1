-- Reihe 1 · A4 Bauform-Motor: Versionswechsel vertraegt den Export (tools/bauform.sh).
--
-- Die Datenmigration einer Bauform aktualisiert Steckbrief, Pruefprotokoll, Blindloeser, Verdacht und Status in EINEM
-- Update. Bisher setzte der Trigger bei einem neuen Steckbrief Pruefprotokoll, Blindloeser und Verdacht zurueck und den
-- Status auf zur_pruefung — auch wenn das Update die Werte des neuen Laufs mitbrachte. Jetzt: Setzt der Export
-- transaktionslokal edvance.bauform_export = '1', gelten seine Werte fuer die neue Version (auch wenn sie gleich
-- aussehen wie vorher, Zweitpruefung A4 Befund 3); ohne den Schalter wird zurueckgesetzt wie bisher (A2, Abnahme 10).
-- Eine neue Version ist nie schon zur_freigabe, freigegeben oder pausiert.
create or replace function public.bauform_versionswechsel() returns trigger language plpgsql
set search_path = public, pg_temp as $$
begin
  new.geaendert_am := now();
  if (new.steckbrief, new.format, new.rollen, new.skill_key, new.kernidee_key)
     is distinct from (old.steckbrief, old.format, old.rollen, old.skill_key, old.kernidee_key) then
    insert into public.bauform_versionen (bauform_id, version, steckbrief, status)
    values (old.id, old.version, old.steckbrief, old.status);
    new.version := old.version + 1;
    if coalesce(current_setting('edvance.bauform_export', true), '') <> '1' then
      new.pruefprotokoll := '{}'::jsonb;
      new.blindloeser := null;
      new.verdacht := null;
      if old.status <> 'entwurf' then
        new.status := 'zur_pruefung';
      end if;
    elsif new.status in ('zur_freigabe', 'freigegeben', 'pausiert', 'beanstandet', 'rueckfrage') then
      new.status := case when new.verdacht is null then 'zur_pruefung' else 'entwurf' end;
    end if;
    new.freigegeben_am := null;
    new.freigegeben_von := null;
  end if;
  return new;
end $$;
