-- ============================================================================
-- INV-4: Keine Tabelle in `public` ohne aktives RLS.
--
-- WARUM ALS EIGENE INVARIANTE: 20260711120000_api_role_grants.sql setzt DEFAULT
--   PRIVILEGES — JEDE neu angelegte Tabelle in `public` bekommt automatisch DML
--   fuer `authenticated`. Das ist bequem und genau deshalb gefaehrlich: wer eine
--   Tabelle anlegt und `enable row level security` vergisst, hat sie im selben
--   Moment fuer jeden eingeloggten Nutzer geoeffnet — ohne dass irgendwo etwas
--   rot wird. Genau so ist der Altbestands-Leak (tasks.solution) entstanden.
--
--   Dieser Test ist die Bremse: er kennt keine Tabellen-Liste, die jemand
--   pflegen muesste, sondern fragt den Katalog. Eine neue Tabelle ohne RLS
--   laesst die Suite rot werden, bevor sie deployt wird.
--
-- ABGRENZUNG: RLS aktiv heisst nicht "korrekt policyiert" — es heisst nur, dass
--   die Tuer nicht offensteht. Die inhaltliche Zusage pro Tabelle pruefen INV-1
--   (Mastery-Gate) und INV-2 (Datenvertrag / task_solutions).
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(2);

-- --- A) Der Katalog-Check ---------------------------------------------------
-- relkind 'r' = gewoehnliche Tabelle, 'p' = partitioniert. Views/Sequenzen/
-- Fremdtabellen tragen kein RLS und sind hier nicht gemeint.
select is_empty(
  $$
    select c.relname::text
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind in ('r', 'p')
       and not c.relrowsecurity
     order by c.relname
  $$,
  'keine Tabelle in public ohne aktives RLS'
);

-- --- B) Die Server-Only-Zone bleibt ohne Tabellen-Tor ------------------------
-- RLS allein reicht bei task_solutions nicht: der eigentliche Schutz ist, dass
-- anon/authenticated ueberhaupt kein Grant haben (P01). Ein spaeteres,
-- versehentliches `grant select on all tables in schema public` wuerde RLS
-- aktiv lassen, aber die Tuer aufmachen — das faengt nur dieser Check.
select is_empty(
  $$
    select table_name::text || ':' || grantee::text || ':' || privilege_type::text
      from information_schema.role_table_grants
     where table_schema = 'public'
       and table_name = 'task_solutions'
       and grantee in ('anon', 'authenticated')
  $$,
  'task_solutions hat KEIN Grant fuer anon/authenticated'
);

select * from finish();
rollback;
