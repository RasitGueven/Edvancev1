-- p2-vorher.sql — Ausgangsstand für tools/p2-pruefung.sql (nur Wegwerf-DB, nie Produktion).
-- Läuft nach dem Laden der Prod-Fixture und VOR den P2-Migrationen.
\set ON_ERROR_STOP 1

-- Prüfkonten: ein Admin und eine Prüferin (coach mit darf_pruefen) wie Lena.
insert into auth.users (id, email) values
  ('2c000000-0000-4000-8000-00000000000a', 'zz_p2_admin@edvance.invalid'),
  ('2c000000-0000-4000-8000-00000000000b', 'zz_p2_lena@edvance.invalid')
on conflict do nothing;
insert into public.profiles (id, email, role, full_name, darf_pruefen) values
  ('2c000000-0000-4000-8000-00000000000a', 'zz_p2_admin@edvance.invalid', 'admin', 'ZZ P2 Admin', false),
  ('2c000000-0000-4000-8000-00000000000b', 'zz_p2_lena@edvance.invalid', 'coach', 'ZZ P2 Lena', true)
on conflict (id) do update set role = excluded.role, darf_pruefen = excluded.darf_pruefen;

create schema p2v;
-- Fingerabdruck aller Felder ausser pruef_pilot und den Zählern, die jeder Schreibweg mitzieht (updated_at,
-- pruef_version per Trigger tasks_pruef_version — dieselbe Nebenwirkung wie die Admin-Aktion pilot_aus).
create table p2v.tasks as
  select t.id, t.pruef_pilot, t.pruef_version,
         md5((to_jsonb(t) - 'pruef_pilot' - 'updated_at' - 'pruef_version')::text) fp
    from public.tasks t;
create table p2v.protokoll as select count(*) n from public.task_admin_protokoll;
\echo '── vorher'
select count(*) filter (where pruef_pilot) pilot, count(*) aufgaben from p2v.tasks;
