-- 20260811090000_rls_skill_substrat
--
-- RLS + Schreibschutz fuer die vier Substrat-Tabellen der LSA-Auswahl:
--   skills, skill_kante, skill_voraussetzung, themen
--
-- BEFUND (STATUS.md §9):
--   Alle vier stehen ohne RLS und ohne eine einzige Policy da. Gleichzeitig
--   vergibt 20260711120000_api_role_grants.sql ueber
--     alter default privileges for role postgres in schema public
--       grant select, insert, update, delete on tables to authenticated
--   volles DML an JEDEN eingeloggten Nutzer — und zwar automatisch, weil die
--   vier Tabellen NACH jener Migration angelegt wurden (20260722130000).
--   Ergebnis: jeder Schueler-Token kann den Fundament-Graphen umschreiben oder
--   loeschen. Das ist genau der Defekt, den INV-4 verhindern soll.
--
-- ZIEL DIESER MIGRATION IST SCHREIBSCHUTZ, NICHT LESEEINSCHRAENKUNG.
--   Der bisherige SELECT-Zugriff bleibt fuer anon und authenticated exakt
--   erhalten. Eine zu enge Policy wuerde die LSA-Auswahl lahmlegen; das waere
--   ein Betriebsausfall zum Preis eines Schutzes, den niemand braucht: die
--   Tabellen enthalten Stammdaten (Skill-Labels, Kanten, Themen), keine
--   personenbezogenen Daten und keine Loesungen.
--
-- WER LIEST DIESE TABELLEN (gegen supabase/schema-erwartet.sql geprueft):
--   public.lsa_select_next_core   SECURITY DEFINER  -> skills, skill_kante
--   public.skill_kante_tiefe_guard  INVOKER (Trigger auf skill_kante) -> skills
--   public.lsa_abschluss            INVOKER         -> skill_kante
--       execute ist von public revoked, nur service_role hat es (a15, §8).
--   SECURITY-DEFINER-Funktionen laufen als Eigentuemer und umgehen RLS; sie
--   brauchen keine Policy. themen und skill_voraussetzung werden von KEINER
--   Funktion gelesen.
--   Kein Frontend liest die vier Tabellen direkt (weder die Admin-Oberflaeche
--   dieses Repos noch der Schueler-Client edvance-app).
--
-- FK-CHECKS: tasks.skill_key, student_focus_areas.skill_key, skill_kante.*
--   und skill_voraussetzung.* zeigen auf skills/themen. Referentielle
--   Integritaetspruefungen laufen mit den Rechten des Tabelleneigentuemers und
--   unterliegen keiner RLS — sie bleiben unberuehrt.
--
-- KEINE DATENAENDERUNG. Nur Rechte und RLS.

begin;

-- ── 1. Tuer zu: RLS aktivieren ──────────────────────────────────────────────
alter table public.skills              enable row level security;
alter table public.skill_kante         enable row level security;
alter table public.skill_voraussetzung enable row level security;
alter table public.themen              enable row level security;

-- ── 2. Schreibrechte entziehen ──────────────────────────────────────────────
-- Das ist der eigentliche Schutz. RLS ohne Policy verweigert zwar bereits
-- jeden Schreibzugriff, aber das Tabellen-Tor gehoert trotzdem geschlossen:
-- eine spaetere, versehentliche Policy soll nicht sofort ein Schreibrecht
-- freischalten, das nie gemeint war (dieselbe Logik wie bei task_solutions,
-- INV-4 Teil B).
--
-- anon hatte insert/update/delete nie (die default privileges geben anon nur
-- select) — der revoke ist dort vorsorglich und ein No-op.
revoke insert, update, delete on public.skills              from authenticated, anon;
revoke insert, update, delete on public.skill_kante         from authenticated, anon;
revoke insert, update, delete on public.skill_voraussetzung from authenticated, anon;
revoke insert, update, delete on public.themen              from authenticated, anon;

-- Geschrieben wird kuenftig ausschliesslich als Eigentuemer (Migrationen laufen
-- als postgres) oder mit einem service_role-Key (BYPASSRLS). Beides ist
-- serverseitig und bleibt unangetastet.

-- ── 3. Lesen: bisheriger Zugriff unveraendert ───────────────────────────────
-- Bewusst `using (true)` statt des Musters `auth.role() = 'authenticated'`
-- (skill_clusters, microskills, subjects): jenes Muster schliesst anon aus und
-- wuerde den heutigen Zugriff damit VERENGEN. Vorbild ist stattdessen
-- badge_catalog_read_all — Stammdaten, absichtlich offen.
-- service_role steht mit in der TO-Liste, damit die Policy auch dort greift, wo
-- die Rolle kein BYPASSRLS traegt (Testdatenbanken aus supabase/test-grundlage.sql).
drop policy if exists skills_read_all              on public.skills;
drop policy if exists skill_kante_read_all         on public.skill_kante;
drop policy if exists skill_voraussetzung_read_all on public.skill_voraussetzung;
drop policy if exists themen_read_all              on public.themen;

create policy skills_read_all on public.skills
  for select to anon, authenticated, service_role using (true);

create policy skill_kante_read_all on public.skill_kante
  for select to anon, authenticated, service_role using (true);

create policy skill_voraussetzung_read_all on public.skill_voraussetzung
  for select to anon, authenticated, service_role using (true);

create policy themen_read_all on public.themen
  for select to anon, authenticated, service_role using (true);

commit;
