-- ============================================================================
-- Themenkatalog nach Stufen, Schulen mit Schulplaenen, Themen je Lead
-- (W1-4, Migration 1 von 3 — nur Schema)
-- ============================================================================
--
-- Das Erstgespraech fragt kuenftig ein konkretes Thema ab ("Wurzeln",
-- "Zinsen") statt eines Kompetenzbereichs aus skill_clusters, und belegt
-- "schon behandelt" aus dem schulinternen Lehrplan der Schule vor. Diese Datei
-- legt das gesamte Schema dafuer an: Erstgespraech, LSA-Einstieg, Report.
-- Daten (Themenkatalog, Schulen, Schulplaene) folgen in Migration 2 und 3.
--
-- Nicht angefasst: skills, skill_kante, tasks, skill_voraussetzung,
-- leads.current_topic_cluster_id (wird spaeter abgeloest).
--
-- public.schulen gibt es schon (Vertraege P1, 20260925120000) mit Admin-RLS,
-- Unique-Index auf (lower(name), coalesce(ort, '')) und Verweisen aus students
-- und vertraege. Sie wird hier nur um Spalten erweitert, nicht neu angelegt;
-- Index und RLS bleiben, wie sie sind.

-- ============================================================================
-- 1. themen — Stufe, Schlagworte, KLP-Bezug, Reihenfolge
-- ============================================================================
--
-- Stufen nach Kernlehrplan Mathematik G9 NRW (2019): Erprobungsstufe 5/6,
-- Erste Stufe 7/8, Zweite Stufe 9/10. klp nennt die Kompetenzerwartungen als
-- '<Inhaltsfeld>-<Nr>' (Ari, Fkt, Geo, Sto) mit der Nummer aus dem KLP; die
-- Nummern beginnen je Stufe neu, eindeutig sind sie zusammen mit stufe.

alter table public.themen
  add column stufe       text,
  add column schlagworte text[] not null default '{}',
  add column klp         text[] not null default '{}',
  add column sort        int;

-- Die 8 bestehenden Zeilen tragen alle klasse 8. Kreis und Prismen/Zylinder
-- liegen laut KLP in der Zweiten Stufe (Geo-3, Geo-5), der Rest in der Ersten.
update public.themen
   set stufe = case when thema_key in ('kreis', 'prismen_zylinder') then 'zweite'
                    else 'erste' end
 where stufe is null;

alter table public.themen
  alter column stufe set not null,
  add constraint themen_stufe_check check (stufe in ('erprobung', 'erste', 'zweite'));

comment on column public.themen.klasse is 'veraltet, maßgeblich ist stufe';
comment on column public.themen.stufe is
  'KLP-Stufe: erprobung (5/6), erste (7/8), zweite (9/10)';
comment on column public.themen.schlagworte is
  'Suchbegriffe fuer das Erstgespraech, kleingeschrieben, ohne Dubletten';
comment on column public.themen.klp is
  'Kompetenzerwartungen des KLP G9 NRW, z. B. {Fkt-4,Fkt-5}';

-- ============================================================================
-- 2. thema_einstieg — Einstiegsknoten eines Themas fuer die LSA
-- ============================================================================
--
-- Bewusst eine eigene Tabelle: skill_voraussetzung beschreibt Voraussetzungen
-- mit Tragkraft und wird nicht umgewidmet.

create table public.thema_einstieg (
  thema_key text not null references public.themen (thema_key) on delete cascade,
  skill_key text not null references public.skills (skill_key) on delete cascade,
  primary key (thema_key, skill_key)
);

comment on table public.thema_einstieg is
  'Skill-Knoten, bei denen die LSA fuer ein Thema einsteigt';

create index thema_einstieg_skill_idx on public.thema_einstieg (skill_key);

alter table public.thema_einstieg enable row level security;

create policy thema_einstieg_read on public.thema_einstieg
  for select using (public.get_my_role() = any (array['admin', 'coach']));
create policy thema_einstieg_admin_write on public.thema_einstieg
  for all using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 3. schulen — Schulform, Stadtteil, Traeger, Website
-- ============================================================================
--
-- Alle Spalten nullable: der Bestand (aus dem Vertragsformular angelegt) kennt
-- sie nicht. schulform nimmt dieselben Werte wie leads.school_type.

alter table public.schulen
  add column schulform text,
  add column stadtteil text,
  add column traeger   text,
  add column website   text,
  alter column ort set default 'Köln',
  add constraint schulen_schulform_check
    check (schulform is null
           or schulform in ('Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule')),
  add constraint schulen_traeger_check
    check (traeger is null or traeger in ('öffentlich', 'privat'));

-- ============================================================================
-- 4. schul_themenplan — Unterrichtsvorhaben je Schule, Fach, Klasse
-- ============================================================================
--
-- Eine Zeile je Unterrichtsvorhaben in der Reihenfolge des Plans. thema_key
-- ist NULL, wenn das Vorhaben keinem Thema zuzuordnen ist. Uebernommen werden
-- nur der Titel des Vorhabens und seine Stellung im Plan, kein Plantext.

create table public.schul_themenplan (
  schule_id  uuid not null references public.schulen (id) on delete cascade,
  fach       text not null,
  klasse     int  not null check (klasse between 5 and 10),
  position   int  not null check (position >= 1),
  thema_key  text references public.themen (thema_key),
  uv_titel   text not null check (nullif(btrim(uv_titel), '') is not null),
  stunden    int  check (stunden is null or stunden > 0),
  halbjahr   int  check (halbjahr is null or halbjahr in (1, 2)),
  quelle_url text not null check (nullif(btrim(quelle_url), '') is not null),
  stand      text,
  constraint schul_themenplan_uniq unique (schule_id, fach, klasse, position)
);

comment on table public.schul_themenplan is
  'Unterrichtsvorhaben aus schulinternen Lehrplaenen; thema_key NULL = nicht zuordenbar';

create index schul_themenplan_thema_idx on public.schul_themenplan (thema_key);

alter table public.schul_themenplan enable row level security;

create policy schul_themenplan_read on public.schul_themenplan
  for select using (public.get_my_role() = any (array['admin', 'coach']));
create policy schul_themenplan_admin_write on public.schul_themenplan
  for all using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 5. leads.schule_id — Schule aus der Liste, school_name bleibt Freitext
-- ============================================================================

alter table public.leads
  add column schule_id uuid references public.schulen (id) on delete set null;

create index leads_schule_idx on public.leads (schule_id);

-- ============================================================================
-- 6. lead_themen — aktuelles und schon behandelte Themen eines Leads
-- ============================================================================
--
-- Hoechstens ein 'aktuell' je Lead und Fach. quelle 'schulplan' heisst: aus
-- schul_themenplan vorbelegt, 'gespraech': im Erstgespraech genannt.
-- RLS wie leads (nur Admin).

create table public.lead_themen (
  lead_id   uuid not null references public.leads (id) on delete cascade,
  fach      text not null,
  thema_key text not null references public.themen (thema_key),
  status    text not null check (status in ('aktuell', 'behandelt')),
  quelle    text not null check (quelle in ('gespraech', 'schulplan')),
  angelegt  timestamptz not null default now(),
  primary key (lead_id, thema_key)
);

comment on table public.lead_themen is
  'Themen eines Leads aus dem Erstgespraech: aktuell (hoechstens eins je Fach) oder behandelt';

create unique index lead_themen_ein_aktuelles
  on public.lead_themen (lead_id, fach) where status = 'aktuell';
create index lead_themen_thema_idx on public.lead_themen (thema_key);

alter table public.lead_themen enable row level security;

create policy lead_themen_admin_all on public.lead_themen
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 7. lsa_sessions.thema_key — Thema, mit dem eine LSA startet
-- ============================================================================
--
-- Gesetzt von der neuen Themenauswahl, gelesen vom Report. Bestehende
-- Sitzungen bleiben NULL.

alter table public.lsa_sessions
  add column thema_key text references public.themen (thema_key);

comment on column public.lsa_sessions.thema_key is
  'Thema, bei dem die LSA eingestiegen ist; NULL bei Sitzungen vor der Themenauswahl';
