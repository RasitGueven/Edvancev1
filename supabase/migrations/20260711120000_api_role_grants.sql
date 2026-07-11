-- ============================================================================
-- API-Rollen-Grants für das public-Schema
--
-- PROBLEM (beim Neuaufbau aus der Baseline entdeckt, P00b+):
--   Eine DB, die aus supabase/migrations/ gebaut wird, ist ohne diese Grants
--   FUNKTIONSUNFÄHIG: anon/authenticated/service_role haben auf KEINER Tabelle
--   in public ein SELECT/INSERT/UPDATE/DELETE. Jeder App-Query über PostgREST
--   scheitert mit „permission denied for table …".
--
-- URSACHE:
--   Postgres vergibt Rechte an neuen Tabellen über ALTER DEFAULT PRIVILEGES,
--   und zwar abhängig davon, WER die Tabelle anlegt. Im Supabase-Stack gilt:
--     FOR ROLE supabase_admin → anon/authenticated/service_role: arwdDxtm (volles DML)
--     FOR ROLE postgres       → anon/authenticated/service_role: Dxtm      (KEIN DML)
--   Migrationen laufen als `postgres`. Die Tabellen landen also ohne DML-Rechte.
--   In der bisherigen Prod-DB fiel das nie auf, weil sie nie aus Migrationen
--   gebaut wurde — die Rechte kamen dort implizit zustande und standen deshalb
--   auch nie in schema.sql.
--
-- SICHERHEIT:
--   Die Zeilen-Ebene regelt weiterhin ausschließlich RLS (auf allen 35 Tabellen
--   aktiv, 93 Policies). Grants sind nur das Tabellen-Tor davor.
--   anon bekommt bewusst NUR select: es existiert keine einzige anon-Policy, RLS
--   liefert ihm also ohnehin keine Zeile (einzige Ausnahme: badge_catalog, das
--   per `using (true)` absichtlich öffentlich ist). Kein anon-Schreibrecht heißt:
--   eine künftige Tabelle, bei der RLS vergessen wird, ist nicht sofort
--   welt-beschreibbar.
-- ============================================================================

begin;

grant usage on schema public to anon, authenticated, service_role;

-- Bestandstabellen
grant select, insert, update, delete on all tables in schema public
  to authenticated, service_role;
grant select on all tables in schema public to anon;
grant usage, select on all sequences in schema public
  to authenticated, service_role;

-- Alles, was KÜNFTIGE Migrationen anlegen (sie laufen ebenfalls als postgres) —
-- ohne das hier hätte jede neue Tabelle denselben Defekt wieder.
alter default privileges for role postgres in schema public
  grant select, insert, update, delete on tables to authenticated, service_role;
alter default privileges for role postgres in schema public
  grant select on tables to anon;
alter default privileges for role postgres in schema public
  grant usage, select on sequences to authenticated, service_role;

commit;
