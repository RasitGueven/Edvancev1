-- Reihe 1 · A2 Datenmodell Bauformen (Konzept Sessionreihe 1 §3, §5, §6, §9).
--
-- Eine Bauform beschreibt einen Aufgabentyp mit Platzhaltern; ein Generator (scripts/bauformen/, A4) erzeugt daraus
-- Instanzen. Jede Instanz ist eine normale Zeile in tasks mit Pool session.
--   bauformen              Steckbrief, Version, Status (Lena prueft je Bauform), Pruefmaschine und Blindloeser je Version
--   bauform_versionen      jede fruehere Fassung des Steckbriefs (nur anhaengen)
--   bauform_pruefungen     Lenas Entscheidungen je Bauform und Version (Muster task_pruefungen, nur anhaengen)
--   tasks.*                bauform_id, bauform_version, params, stufe, rolle, kernidee_key, pruefmaschine
--   aufgabe_bewaehrung     Bewaehrung je Instanz (Zaehler, Status)
--   aufgabe_meldungen      Meldungen der Coaches (nur anhaengen)
--   aufgabe_gesehen        "gesehen" je Kind und Instanz, nur Session vor Ort (FernUSG: zuhause nichts je Aufgabe)
--   skill_pruefung         + geprueft_von, geprueft_am (Coach-Pruefgespraeche; die Tabelle gibt es seit lernpfad_schema)
--
-- RLS: Kinder lesen nichts davon direkt, nur ueber die Funktionen (A2 funktionen). Steckbriefe lesen Admins und Lena
-- (darf_pruefen). Geschrieben wird nur ueber SECURITY-DEFINER-Funktionen und Migrationen.
-- Neue Spalten an tasks (pg_proc, 27.10.2026): keine Funktion referenziert bauform_id, bauform_version, params, stufe,
-- rolle, kernidee_key oder pruefmaschine — die Namen sind neu. "select * into t from tasks" (z. B. pruef_wertung_testen,
-- session_bewerten) bekommt die Spalten mit, liest sie aber nicht.

create table public.bauformen (
  id               uuid primary key default gen_random_uuid(),
  schluessel       text not null unique check (schluessel ~ '^[A-Z]{2,3}-[0-9]{1,2}$'),
  reihe            text not null default 'quadratische_funktionen_gleichungen' check (reihe ~ '^[a-z][a-z0-9_]*$'),
  skill_key        text not null references public.skills (skill_key) on update cascade,
  kernidee_key     text check (kernidee_key ~ '^[a-z][a-z0-9_]*:K[1-9]$'),
  format           text not null check (format in ('mc', 'zahl', 'bruch', 'mehrteiler', 'tabelle', 'feldmaske',
                                                   'loesungsmenge', 'graph_auswahl', 'fehler_finden', 'bausteine',
                                                   'schritte_ordnen')),
  rollen           text[] not null check (cardinality(rollen) >= 1 and rollen <@ array['warmup', 'uebung', 'transfer',
                                          'recap', 'beispiel', 'home', 'generalprobe']::text[]),
  -- Text, Stufen, Fehlbilder (je mit gilt_fuer_stufen), Hinweise, Loesungsweg, Warum-Bausteine, Kontext, Figur, Zeit,
  -- kann_entfallen (Konzept §3.1). Form im DATENVERTRAG §13.3.
  steckbrief       jsonb not null default '{}'::jsonb check (jsonb_typeof(steckbrief) = 'object'),
  generator_pfad   text,
  version          int not null default 1 check (version >= 1),
  status           text not null default 'entwurf' check (status in ('entwurf', 'zur_pruefung', 'rueckfrage',
                                                   'beanstandet', 'zur_freigabe', 'freigegeben', 'pausiert')),
  -- Pruefmaschine der aktuellen Version: {gruen, rot, rot_anteil, gruende: {...}, lauf_am}
  pruefprotokoll   jsonb not null default '{}'::jsonb,
  -- Blindloeser der aktuellen Version: {geloest, abweichend, anteil, bestanden, notiz, am}
  blindloeser      jsonb,
  -- Grund, wenn Pruefmaschine (> 30 % rot) oder Blindloeser (> 10 % Abweichung) die Bauform verdaechtig machen.
  verdacht         text,
  freigegeben_am   timestamptz,
  freigegeben_von  uuid references public.profiles (id) on delete set null,
  angelegt_am      timestamptz not null default now(),
  geaendert_am     timestamptz not null default now()
);
create index bauformen_skill_idx on public.bauformen (skill_key);
comment on table public.bauformen is
  'Reihe 1 A2: Bauform (Aufgabentyp mit Platzhaltern). Lena prueft je Bauform und Version, Admins geben frei.';

create table public.bauform_versionen (
  bauform_id   uuid not null references public.bauformen (id) on delete restrict,
  version      int not null,
  steckbrief   jsonb not null,
  status       text not null,
  abgeloest_am timestamptz not null default now(),
  primary key (bauform_id, version)
);

create table public.bauform_pruefungen (
  id           uuid primary key default gen_random_uuid(),
  bauform_id   uuid not null references public.bauformen (id) on delete restrict,
  version      int not null,
  entscheidung text not null check (entscheidung in ('passt', 'unsicher', 'passt_nicht', 'zurueckgenommen',
                                                    'reaktiviert')),
  gruende      text[] not null default '{}',
  notiz        text,
  dauer_sek    int check (dauer_sek is null or dauer_sek >= 0),
  geprueft_von uuid references public.profiles (id) on delete set null,
  geprueft_am  timestamptz not null default now()
);
create index bauform_pruefungen_bauform_idx on public.bauform_pruefungen (bauform_id, geprueft_am desc);

alter table public.tasks
  add column bauform_id     uuid references public.bauformen (id) on delete restrict,
  add column bauform_version int,
  add column params         jsonb,
  add column stufe          smallint check (stufe between 1 and 5),
  add column rolle          text check (rolle in ('warmup', 'uebung', 'transfer', 'recap', 'beispiel', 'home',
                                                  'generalprobe')),
  add column kernidee_key   text,
  add column pruefmaschine  jsonb;
-- Eine Instanz traegt Bauform, Version, Stufe, genau eine Rolle und gehoert zum Pool session.
alter table public.tasks add constraint tasks_bauform_instanz check (
  bauform_id is null
  or (bauform_version is not null and stufe is not null and rolle is not null and einsatz = array['session']::text[]));
create index tasks_bauform_idx on public.tasks (bauform_id, rolle, stufe) where bauform_id is not null;
create index tasks_instanz_ziehen_idx on public.tasks (skill_key, rolle, stufe) where bauform_id is not null;
comment on column public.tasks.rolle is 'Reihe 1 A2: genau eine Rolle je Bauform-Instanz (warmup, uebung, transfer, recap, beispiel, home, generalprobe).';
comment on column public.tasks.pruefmaschine is 'Reihe 1 A2: Ergebnis der Pruefmaschine je Pruefung {"1": {"ok": true, "grund": "…"}, …}.';

create table public.aufgabe_bewaehrung (
  task_id                uuid primary key references public.tasks (id) on delete restrict,
  bearbeitungen          int not null default 0,
  richtig                int not null default 0,
  fehlbild_zaehler       jsonb not null default '{}'::jsonb,   -- {slug: n}
  unbekannt              jsonb not null default '{}'::jsonb,   -- {normalisierte falsche Antwort ohne Fehlbild: n}
  haeufigste_unbekannte  text,
  status                 text not null default 'in_bewaehrung'
                           check (status in ('in_bewaehrung', 'bewaehrt', 'auffaellig', 'pausiert')),
  grund                  text,
  geaendert_am           timestamptz not null default now()
);

create table public.aufgabe_meldungen (
  id        uuid primary key default gen_random_uuid(),
  task_id   uuid not null references public.tasks (id) on delete restrict,
  grund     text not null check (btrim(grund) <> ''),
  von       uuid references public.profiles (id) on delete set null,
  am        timestamptz not null default now()
);
create index aufgabe_meldungen_task_idx on public.aufgabe_meldungen (task_id);

create table public.aufgabe_gesehen (
  student_id uuid not null references public.students (id) on delete cascade,
  task_id    uuid not null references public.tasks (id) on delete restrict,
  session_id uuid not null references public.coaching_sessions (id) on delete cascade,
  am         timestamptz not null default now(),
  primary key (student_id, task_id, session_id)
);
create index aufgabe_gesehen_task_idx on public.aufgabe_gesehen (task_id);

alter table public.skill_pruefung
  add column geprueft_von uuid references public.profiles (id) on delete set null,
  add column geprueft_am  timestamptz;

-- Nur anhaengen: Versionen, Pruefungen, Meldungen (wie task_pruefungen).
create function public.reihe1_nur_anhaengen() returns trigger language plpgsql as $$
begin
  raise exception '%: nur anhaengen', tg_table_name using errcode = '42501';
end $$;
create trigger bauform_versionen_nur_anhaengen before update or delete on public.bauform_versionen
  for each row execute function public.reihe1_nur_anhaengen();
create trigger bauform_pruefungen_nur_anhaengen before update or delete on public.bauform_pruefungen
  for each row execute function public.reihe1_nur_anhaengen();
create trigger aufgabe_meldungen_nur_anhaengen before update or delete on public.aufgabe_meldungen
  for each row execute function public.reihe1_nur_anhaengen();

-- Versionswechsel (Konzept §3.2, Abnahme 10): Aendert sich, was Lena prueft (Steckbrief, Format, Rollen, Skill,
-- Kernidee), steigt die Version. Die alte Fassung kommt nach bauform_versionen; die Bauform ist fuer Lena wieder offen
-- (zur_pruefung), Pruefmaschine und Blindloeser gelten nicht mehr. Alte Instanzen bleiben, werden aber nicht mehr
-- gezogen (aufgabe_ziehen verlangt tasks.bauform_version = bauformen.version). Aus entwurf bleibt entwurf.
create function public.bauform_versionswechsel() returns trigger language plpgsql
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
create trigger bauformen_versionswechsel before update on public.bauformen
  for each row execute function public.bauform_versionswechsel();

alter table public.bauformen          enable row level security;
alter table public.bauform_versionen  enable row level security;
alter table public.bauform_pruefungen enable row level security;
alter table public.aufgabe_bewaehrung enable row level security;
alter table public.aufgabe_meldungen  enable row level security;
alter table public.aufgabe_gesehen    enable row level security;

create policy bauformen_pruefer_lesen on public.bauformen for select to authenticated using (public.darf_pruefen());
create policy bauform_versionen_pruefer_lesen on public.bauform_versionen for select to authenticated
  using (public.darf_pruefen());
create policy bauform_pruefungen_pruefer_lesen on public.bauform_pruefungen for select to authenticated
  using (public.darf_pruefen());
create policy aufgabe_bewaehrung_pruefer_lesen on public.aufgabe_bewaehrung for select to authenticated
  using (public.darf_pruefen());
create policy aufgabe_meldungen_lesen on public.aufgabe_meldungen for select to authenticated
  using (public.darf_pruefen() or coalesce(public.get_my_role(), '') = 'coach');
create policy aufgabe_gesehen_admin_lesen on public.aufgabe_gesehen for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin');

revoke all on public.bauformen, public.bauform_versionen, public.bauform_pruefungen, public.aufgabe_bewaehrung,
              public.aufgabe_meldungen, public.aufgabe_gesehen from anon, authenticated;
grant select on public.bauformen, public.bauform_versionen, public.bauform_pruefungen, public.aufgabe_bewaehrung,
                public.aufgabe_meldungen, public.aufgabe_gesehen to authenticated;
