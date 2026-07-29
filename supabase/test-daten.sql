-- test-daten.sql
--
-- Minimale Identitaeten fuer die Pruefskripte in supabase/checks/, die gegen
-- vorhandene Stammdaten laufen (A16, A17, A20, A21). test-grundlage.sql bildet
-- das Supabase-Umfeld nach, die Migrationen bringen das Schema, supabase/seed.sql
-- + supabase/seeds/*.sql bringen Katalog und Aufgaben — aber niemand legt einen
-- Admin, ein Platz-Geraet oder Schueler an. Ohne die scheitert A17 an
-- "kein freigegebener Item-Pool", bevor es irgendetwas pruefen kann.
--
-- Idempotent. Nur fuer Testdatenbanken. Nie gegen Produktion ausfuehren.
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 -f supabase/test-daten.sql

insert into auth.users (id, email) values
  ('00000000-0000-4000-8000-000000000001', 'admin@test.invalid'),
  ('00000000-0000-4000-8000-000000000002', 'platz@test.invalid'),
  ('00000000-0000-4000-8000-000000000003', 'schueler-a@test.invalid'),
  ('00000000-0000-4000-8000-000000000004', 'schueler-b@test.invalid')
on conflict (id) do nothing;

insert into profiles (id, email, role, full_name) values
  ('00000000-0000-4000-8000-000000000001', 'admin@test.invalid',     'admin',   'Test Admin'),
  ('00000000-0000-4000-8000-000000000002', 'platz@test.invalid',     'student', 'Platz 1'),
  ('00000000-0000-4000-8000-000000000003', 'schueler-a@test.invalid','student', 'Schueler A'),
  ('00000000-0000-4000-8000-000000000004', 'schueler-b@test.invalid','student', 'Schueler B')
on conflict (id) do nothing;

insert into platz_devices (profile_id, label)
  values ('00000000-0000-4000-8000-000000000002', 'Platz 1')
on conflict (profile_id) do nothing;

insert into students (id, profile_id, class_level, is_provisional) values
  ('00000000-0000-4000-9000-000000000003', '00000000-0000-4000-8000-000000000003', 13, false),
  ('00000000-0000-4000-9000-000000000004', '00000000-0000-4000-8000-000000000004', 13, false)
on conflict (id) do nothing;
