-- Rollback zu reihe1_a4_versionswechsel: bauform_versionswechsel in der A2-Fassung, danach den Eintrag in
-- supabase_migrations.schema_migrations loeschen.
create or replace function public.bauform_versionswechsel() returns trigger language plpgsql
set search_path = public, pg_temp as $$
begin
  new.geaendert_am := now();
  if (new.steckbrief, new.format, new.rollen, new.skill_key, new.kernidee_key)
     is distinct from (old.steckbrief, old.format, old.rollen, old.skill_key, old.kernidee_key) then
    insert into public.bauform_versionen (bauform_id, version, steckbrief, status)
    values (old.id, old.version, old.steckbrief, old.status);
    new.version := old.version + 1;
    new.pruefprotokoll := '{}'::jsonb;
    new.blindloeser := null;
    new.verdacht := null;
    new.freigegeben_am := null;
    new.freigegeben_von := null;
    if old.status <> 'entwurf' then
      new.status := 'zur_pruefung';
    end if;
  end if;
  return new;
end $$;
