-- Reihe 1 · C1 Reihenplanung, Teil 1: Datenmodell (docs/reihe1/Bauauftrag-C-Session-Workflow.md C1.1,
-- Konzept docs/reihe1/Konzept-Sessionreihe-1-und-Bauformen.md §2).
--
--   reihe_kernideen        Katalog der Kernideen je Skill (Konzept §2.1), nr = Reihenfolge des Katalogs (§2.3 Regel 4)
--   reihe_kann_entfallen   kleine Rückfall-Liste „kann entfallen“, bis skill_kann_entfallen von Auftrag A da ist
--   reihen                 Reihe je Kind und Fach (Themen, Klassenarbeitsdatum oder leer, Takt, Start, Status)
--   reihe_plan_versionen   Systemvorschlag, unveränderlich je Version (Sessions als jsonb, Anlass, Grund, Stellschrauben)
--   reihe_coach_aenderungen Coach-Änderungen getrennt vom Systemvorschlag (verschieben | bestaetigen, mit Grund)
--   reihe_ist              was eine abgeschlossene Session laut Plan behandelt hat („schon gesehen“, Konzept §2.3 Regel 2)
--
-- Schreiben nur über die SECURITY-DEFINER-Funktionen aus Teil 2. Lesen: Admin, Coach mit laufendem Vertrag
-- (lernpfad_darf_lesen). Stellschrauben der Planung in session_einstellungen (Startwerte Konzept §2.3).
-- Rollback: supabase/rollback/20261027130023_reihe1_c1_reihe_schema.sql.

create table public.reihe_kernideen (
  skill_key     text not null references public.skills (skill_key) on delete cascade,
  kernidee_key  text not null check (kernidee_key ~ '^K[1-9]$'),
  nr            int  not null unique check (nr >= 1),
  titel         text not null check (btrim(titel) <> ''),
  primary key (skill_key, kernidee_key)
);
comment on table public.reihe_kernideen is
  'Reihe 1 C1: Kernideen je Kern-Skill (Konzept §2.1). nr = Katalog-Reihenfolge, nach der die Reihe plant. Auftrag C.';

create table public.reihe_kann_entfallen (
  skill_key text primary key references public.skills (skill_key) on delete cascade
);
comment on table public.reihe_kann_entfallen is
  'Reihe 1 C1: Rückfall-Liste „kann entfallen“ (Konzept §2.3 Regel 5), solange skill_kann_entfallen (Auftrag A) fehlt.';

create table public.reihen (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.students (id) on delete cascade,
  fach        text not null default 'mathematik',
  thema_keys  text[] not null check (cardinality(thema_keys) >= 1 and array_position(thema_keys, null) is null),
  ka_datum    date,
  takt        smallint not null default 1 check (takt between 1 and 3),
  start       date not null,
  status      text not null default 'aktiv' check (status in ('aktiv', 'beendet')),
  angelegt_am timestamptz not null default now(),
  angelegt_von uuid references public.profiles (id) on delete set null,
  constraint reihen_ka_nach_start check (ka_datum is null or ka_datum > start)
);
comment on table public.reihen is
  'Reihe 1 C1: Reihe je Kind und Fach. ka_datum null = Modus Schulthema (rollierend, ohne Generalprobe). Auftrag C.';
create unique index reihen_eine_aktive on public.reihen (student_id, fach) where status = 'aktiv';

create table public.reihe_plan_versionen (
  id            uuid primary key default gen_random_uuid(),
  reihe_id      uuid not null references public.reihen (id) on delete cascade,
  version       int  not null check (version >= 1),
  anlass        text not null check (anlass in ('start', 'session', 'coach', 'daten')),
  grund         text not null,
  session_id    uuid references public.coaching_sessions (id) on delete set null,
  plan          jsonb not null check (jsonb_typeof(plan -> 'sessions') = 'array'),
  erstellt_am   timestamptz not null default clock_timestamp(),
  erstellt_von  uuid references public.profiles (id) on delete set null,
  unique (reihe_id, version)
);
comment on table public.reihe_plan_versionen is
  'Reihe 1 C1: Systemvorschlag je Version (nur anhängen). plan = {sessions[], warnung, modus, stellschrauben}. Auftrag C.';

create table public.reihe_coach_aenderungen (
  id          uuid primary key default gen_random_uuid(),
  reihe_id    uuid not null references public.reihen (id) on delete cascade,
  aktion      text not null check (aktion in ('verschieben', 'bestaetigen')),
  skill_key   text,
  ziel_datum  date,
  version_id  uuid not null references public.reihe_plan_versionen (id) on delete cascade,
  grund       text,
  von         uuid references public.profiles (id) on delete set null,
  am          timestamptz not null default clock_timestamp(),
  constraint reihe_coach_verschieben check (aktion <> 'verschieben' or (skill_key is not null and ziel_datum is not null))
);
comment on table public.reihe_coach_aenderungen is
  'Reihe 1 C1: Coach-Entscheidungen, getrennt vom Systemvorschlag (Konzept §2.3 Regel 6). Nur anhängen. Auftrag C.';

create table public.reihe_ist (
  reihe_id   uuid not null references public.reihen (id) on delete cascade,
  session_id uuid not null references public.coaching_sessions (id) on delete cascade,
  datum      date not null,
  kernideen  jsonb not null default '[]'::jsonb check (jsonb_typeof(kernideen) = 'array'),
  am         timestamptz not null default clock_timestamp(),
  primary key (reihe_id, session_id)
);
comment on table public.reihe_ist is
  'Reihe 1 C1: Kernideen, die laut wirksamem Plan in einer abgeschlossenen Session dran waren (Grundlage für „schon gesehen“).';

-- Nur anhängen: Versionen, Coach-Änderungen und Ist-Zeilen werden nie geändert oder gelöscht (ausser per Kaskade).
create function public.reihe_nur_anhaengen()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  raise exception '%: nur anhängen', tg_table_name using errcode = '55000';
end;
$$;
create trigger reihe_plan_versionen_nur_anhaengen before update on public.reihe_plan_versionen
  for each row execute function public.reihe_nur_anhaengen();
create trigger reihe_coach_aenderungen_nur_anhaengen before update on public.reihe_coach_aenderungen
  for each row execute function public.reihe_nur_anhaengen();
create trigger reihe_ist_nur_anhaengen before update on public.reihe_ist
  for each row execute function public.reihe_nur_anhaengen();

alter table public.reihe_kernideen enable row level security;
alter table public.reihe_kann_entfallen enable row level security;
alter table public.reihen enable row level security;
alter table public.reihe_plan_versionen enable row level security;
alter table public.reihe_coach_aenderungen enable row level security;
alter table public.reihe_ist enable row level security;
revoke all on public.reihe_kernideen, public.reihe_kann_entfallen, public.reihen, public.reihe_plan_versionen,
              public.reihe_coach_aenderungen, public.reihe_ist from anon;
-- Zweitprüfung 7: Clients nur lesen (kein INSERT/UPDATE/DELETE/TRUNCATE, das ginge an RLS bzw. Trigger vorbei).
revoke insert, update, delete, truncate, references, trigger on public.reihe_kernideen, public.reihe_kann_entfallen,
              public.reihen, public.reihe_plan_versionen, public.reihe_coach_aenderungen, public.reihe_ist from authenticated;

create policy reihe_kernideen_lesen on public.reihe_kernideen for select to authenticated using (true);
create policy reihe_kann_entfallen_lesen on public.reihe_kann_entfallen for select to authenticated using (true);
create policy reihen_lesen on public.reihen for select to authenticated
  using (public.lernpfad_darf_lesen(student_id));
create policy reihe_plan_versionen_lesen on public.reihe_plan_versionen for select to authenticated
  using (exists (select 1 from public.reihen r where r.id = reihe_id and public.lernpfad_darf_lesen(r.student_id)));
create policy reihe_coach_aenderungen_lesen on public.reihe_coach_aenderungen for select to authenticated
  using (exists (select 1 from public.reihen r where r.id = reihe_id and public.lernpfad_darf_lesen(r.student_id)));
create policy reihe_ist_lesen on public.reihe_ist for select to authenticated
  using (exists (select 1 from public.reihen r where r.id = reihe_id and public.lernpfad_darf_lesen(r.student_id)));

-- Katalog Reihe 1 (Konzept §2.1, 19 Kernideen in der Reihenfolge der Tabelle).
insert into public.reihe_kernideen (skill_key, kernidee_key, nr, titel) values
  ('fkt_quadr_parabel', 'K1', 1, 'Normalparabel: Wertetabelle, Symmetrie, Scheitel im Ursprung'),
  ('fkt_quadr_parabel', 'K2', 2, 'Streckfaktor a: enger, weiter, nach unten geöffnet'),
  ('fkt_quadr_parabel', 'K3', 3, 'Verschieben: d nach rechts, e nach oben'),
  ('fkt_quadr_scheitel', 'K1', 4, 'S(d | e) ablesen, das Vorzeichen in der Klammer'),
  ('fkt_quadr_scheitel', 'K2', 5, 'Gleichung aus dem Graphen'),
  ('fkt_quadr_normalform', 'K1', 6, 'Scheitelpunktform ausmultiplizieren (der Rückweg)'),
  ('fkt_quadr_normalform', 'K2', 7, 'Quadratische Ergänzung mit a = 1'),
  ('fkt_quadr_normalform', 'K3', 8, 'Mit a ≠ 1: erst ausklammern'),
  ('gleichung_quadr_wurzel', 'K1', 9, 'x² = c hat zwei, eine oder keine Lösung'),
  ('gleichung_quadr_wurzel', 'K2', 10, 'Erst umstellen, dann Wurzel'),
  ('gleichung_quadr_wurzel', 'K3', 11, '(x − d)² = c'),
  ('gleichung_quadr_faktor', 'K1', 12, 'Ein Produkt ist 0, wenn ein Faktor 0 ist'),
  ('gleichung_quadr_faktor', 'K2', 13, 'x ausklammern'),
  ('gleichung_quadr_formel', 'K1', 14, 'Normalform herstellen, p und q ablesen'),
  ('gleichung_quadr_formel', 'K2', 15, 'Formel anwenden'),
  ('gleichung_quadr_anzahl', 'K1', 16, 'Der Ausdruck unter der Wurzel entscheidet'),
  ('fkt_quadr_nullstellen', 'K1', 17, 'Nullstelle heißt f(x) = 0, Schnitt mit der x-Achse'),
  ('fkt_quadr_nullstellen', 'K2', 18, 'Den passenden Weg wählen'),
  ('fkt_quadr_extrem', 'K1', 19, 'Die Größe als quadratische Funktion, der Scheitel ist das Extremum');

insert into public.reihe_kann_entfallen (skill_key) values ('fkt_quadr_extrem');

-- Stellschrauben der Planung (Konzept §2.3 Regeln 2, 3, 5, 7).
insert into public.session_einstellungen
  (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, werte, einheit)
select k, b, 'zahl', w, w, mi, ma, g, null, e
  from (values
    ('reihe_kapazitaet_min', 'Reihe: Kapazität der Kernarbeit je Session', '36'::jsonb, 20, 45, true, 'minuten'),
    ('reihe_spielraum', 'Reihe: Spielraum über der Kapazität', '0.10', 0, 0.25, false, 'anteil'),
    ('reihe_min_neu', 'Reihe: Zeitbedarf einer neuen Kernidee', '12', 4, 20, true, 'minuten'),
    ('reihe_min_gesehen', 'Reihe: Zeitbedarf einer gesehenen, noch nicht sicheren Kernidee', '6', 2, 12, true, 'minuten'),
    ('reihe_min_gesehen_knapp', 'Reihe: dasselbe, wenn die Reihe sonst nicht passt', '4', 2, 12, true, 'minuten'),
    ('reihe_transfer_min', 'Reihe: eigener Transferblock vor der Generalprobe', '12', 0, 20, true, 'minuten'),
    ('reihe_rollierend_sessions', 'Reihe ohne Klassenarbeit: rollierend geplante Sessions', '4', 2, 8, true, 'sessions')
  ) as v(k, b, w, mi, ma, g, e);
