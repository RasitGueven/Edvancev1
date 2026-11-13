-- Rollback zu 20261113082727_sf1_schulformen_kurs. Den Eintrag in supabase_migrations.schema_migrations danach
-- von Hand entfernen. Scheitert bewusst, solange eine Zeile „Sekundarschule“ trägt oder Schulen mit Schulnummer
-- (Datenmigration 20261113…_sf1_schulen) da sind — dann zuerst deren Rollback.
drop function if exists public.kind_kurs_aktuell(uuid, text);
drop trigger if exists kind_kurs_von_lead on public.leads;
drop function if exists public.kind_kurs_von_lead();
drop table if exists public.kind_kurs;
drop function if exists public.kind_kurs_nur_anhaengen();

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
