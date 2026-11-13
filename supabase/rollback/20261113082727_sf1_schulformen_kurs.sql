-- Rollback zu 20261113082727_sf1_schulformen_kurs. Den Eintrag in supabase_migrations.schema_migrations danach
-- von Hand entfernen. Bricht ab, solange Schulen mit Schulnummer da sind (zuerst Rollback
-- 20261113082851_sf1_schulen) oder eine Zeile „Sekundarschule“ trägt (dann scheitert der CHECK).
do $$
begin
  if exists (select 1 from public.schulen where schulnummer is not null) then
    raise exception 'Rollback abgebrochen: zuerst 20261113082851_sf1_schulen zurücknehmen';
  end if;
end $$;
drop function if exists public.kind_kurs_aktuell(uuid, text);
drop trigger if exists kind_kurs_von_lead on public.leads;
drop function if exists public.kind_kurs_von_lead();
drop table if exists public.kind_kurs;
drop function if exists public.kind_kurs_nur_anhaengen();
drop function if exists public.kind_kurs_stempel();

alter table public.leads drop constraint if exists leads_abschlussziel_check;
alter table public.leads drop constraint if exists leads_kurs_mathe_check;
alter table public.leads drop column if exists abschlussziel;
alter table public.leads drop column if exists kurs_mathe;

drop index if exists public.schulen_schulnummer_uniq;
alter table public.schulen drop constraint if exists schulen_schulnummer_check;
alter table public.schulen drop column if exists schulnummer;

alter table public.students drop constraint students_school_type_check;
alter table public.students add constraint students_school_type_check check (
  school_type = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule']));
alter table public.leads drop constraint leads_school_type_check;
alter table public.leads add constraint leads_school_type_check check (
  school_type = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule']));
alter table public.schulen drop constraint schulen_schulform_check;
alter table public.schulen add constraint schulen_schulform_check check (
  schulform is null or schulform = any (array['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule']));
