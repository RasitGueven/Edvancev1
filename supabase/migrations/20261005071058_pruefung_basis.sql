-- Lena-Board, Migration 1 von 4: pruefung_basis (Entscheidungen 5 bis 11)
--
-- Daten fuer "Aufgaben pruefen": Status 'rueckfrage', Versionszaehler gegen gleichzeitiges
-- Bearbeiten, Pilotmarke, die eingefrorene Ausgangsfassung, das Pruefprotokoll, die globalen
-- Einstellungen und die neuen Gruende fuer "Passt nicht".
--
-- Lesen von Ausgangsfassung und Protokoll nur mit darf_pruefen() (admin oder coach mit Pruefrecht),
-- nie anon. Geschrieben wird beides ausschliesslich ueber die pruef_*-Funktionen (Migration 2).
-- Kein begin/commit: der Runner klammert (CLAUDE.md §10, ~/bin/mig -1).

-- ── 5 · Status 'rueckfrage' ─────────────────────────────────────────────────
-- "Unsicher" bei Lena = Rueckfrage beim Admin. Entsteht nur ueber pruef_entscheiden.
alter table public.tasks drop constraint tasks_status_check;
alter table public.tasks add constraint tasks_status_check
  check (status = any (array['draft', 'review', 'ready', 'beanstandet', 'rueckfrage']));

-- ── 6 · Versionszaehler ─────────────────────────────────────────────────────
-- Jede Aenderung an der Aufgabe oder ihrer Loesung erhoeht pruef_version. Die schreibenden
-- pruef_*-Funktionen nehmen die Version, die das Frontend zuletzt gesehen hat, und lehnen bei
-- Abweichung mit ED409 ab ("Die Aufgabe wurde inzwischen geaendert. Bitte neu laden.").
alter table public.tasks add column pruef_version bigint not null default 1;

-- ── 10 · Pilotmarke ─────────────────────────────────────────────────────────
alter table public.tasks add column pruef_pilot boolean not null default false;

-- Immer old + 1, auch wenn jemand pruef_version selbst setzt: die Version laesst sich nicht
-- zurueckdrehen.
create or replace function public.tasks_pruef_version()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.pruef_version := old.pruef_version + 1;
  return new;
end $$;

create trigger tasks_pruef_version
  before update on public.tasks
  for each row execute function public.tasks_pruef_version();

-- Eine geaenderte Loesung ist eine geaenderte Aufgabe. Das leere UPDATE loest den Trigger oben aus.
-- Definer, damit tasks_pruefer_guard (greift nur bei current_user = 'authenticated') hier nie
-- anschlaegt; task_solutions schreibt ohnehin nur eine Definer-Funktion.
create or replace function public.task_solutions_pruef_version()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.tasks set pruef_version = pruef_version where id = new.task_id;
  return null;
end $$;

create trigger task_solutions_pruef_version
  after insert or update on public.task_solutions
  for each row execute function public.task_solutions_pruef_version();

revoke all on function public.tasks_pruef_version() from public, anon, authenticated;
revoke all on function public.task_solutions_pruef_version() from public, anon, authenticated;

-- ── 7 · Ausgangsfassung ─────────────────────────────────────────────────────
-- Eingefroren beim ersten Oeffnen durch Lena: skill_key, afb, correct_answers, acceptance,
-- typical_errors (dazu sondierrang fuer die stabile Reihenfolge im Board). Bedient "geaendert ↺"
-- und vorher → nachher. Eigene Tabelle, nicht tasks: read_tasks_by_role laesst jede angemeldete
-- Rolle freigegebene Aufgaben lesen, und Loesungen gehoeren nie nach tasks (P01-Datenvertrag).
create table public.task_pruefung_ausgang (
  task_id     uuid primary key references public.tasks (id) on delete cascade,
  ausgang     jsonb not null check (jsonb_typeof(ausgang) = 'object'),
  erstellt_am timestamptz not null default now()
);

alter table public.task_pruefung_ausgang enable row level security;
create policy task_pruefung_ausgang_lesen on public.task_pruefung_ausgang
  for select to authenticated using (public.darf_pruefen());
revoke all on public.task_pruefung_ausgang from anon, authenticated;
grant select on public.task_pruefung_ausgang to authenticated;

-- ── 8 · Pruefprotokoll ──────────────────────────────────────────────────────
-- Eine Zeile je Entscheidung, nur anhaengen. Einzig antwort/beantwortet_* traegt der Admin
-- spaeter in die letzte Zeile nach (pruef_rueckfrage_klaeren).
create table public.task_pruefungen (
  id               uuid primary key default gen_random_uuid(),
  task_id          uuid not null references public.tasks (id) on delete cascade,
  entscheidung     text not null
                   check (entscheidung in ('passt', 'unsicher', 'passt_nicht', 'zurueckgenommen')),
  gruende          text[] not null default '{}',
  notiz            text,
  -- Liste von {feld, teil, vorher, nachher}, serverseitig berechnet (Ausgangsfassung ↔ jetzt)
  aenderungen      jsonb not null default '[]' check (jsonb_typeof(aenderungen) = 'array'),
  aenderung_grund  text,
  dauer_sek        integer check (dauer_sek between 0 and 86400),
  geprueft_von     uuid references public.profiles (id),
  geprueft_am      timestamptz not null default now(),
  antwort          text,
  beantwortet_von  uuid references public.profiles (id),
  beantwortet_am   timestamptz
);

create index task_pruefungen_task_idx on public.task_pruefungen (task_id, geprueft_am desc);

alter table public.task_pruefungen enable row level security;
create policy task_pruefungen_lesen on public.task_pruefungen
  for select to authenticated using (public.darf_pruefen());
revoke all on public.task_pruefungen from anon, authenticated;
grant select on public.task_pruefungen to authenticated;

create or replace function public.task_pruefungen_nur_anhaengen()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if (new.id, new.task_id, new.entscheidung, new.gruende, new.notiz, new.aenderungen,
      new.aenderung_grund, new.dauer_sek, new.geprueft_von, new.geprueft_am)
     is distinct from
     (old.id, old.task_id, old.entscheidung, old.gruende, old.notiz, old.aenderungen,
      old.aenderung_grund, old.dauer_sek, old.geprueft_von, old.geprueft_am) then
    raise exception 'task_pruefungen: das Protokoll wird nur angehaengt, nicht geaendert'
      using errcode = '42501';
  end if;
  return new;
end $$;

create trigger task_pruefungen_nur_anhaengen
  before update on public.task_pruefungen
  for each row execute function public.task_pruefungen_nur_anhaengen();

revoke all on function public.task_pruefungen_nur_anhaengen() from public, anon, authenticated;

-- ── 9 · Einstellungen (genau eine Zeile) ────────────────────────────────────
create table public.pruef_einstellungen (
  id            boolean primary key default true check (id),
  hilfsmittel   text not null default 'Taschenrechner, Stift und Zettel',
  nur_pilot     boolean not null default false,
  grund_pflicht boolean not null default false
);

insert into public.pruef_einstellungen (id) values (true) on conflict (id) do nothing;

alter table public.pruef_einstellungen enable row level security;
create policy pruef_einstellungen_lesen on public.pruef_einstellungen
  for select to authenticated using (true);
create policy pruef_einstellungen_admin on public.pruef_einstellungen
  for update to authenticated
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
revoke all on public.pruef_einstellungen from anon, authenticated;
grant select, update on public.pruef_einstellungen to authenticated;

-- ── 11 · Gruende fuer "Passt nicht" ─────────────────────────────────────────
-- Die bisherigen sieben Kategorien bleiben; Lenas sieben Gruende kommen dazu.
alter table public.task_reviews drop constraint task_reviews_kategorie_check;
alter table public.task_reviews add constraint task_reviews_kategorie_check
  check (kategorie = any (array[
    'fehlbild_falsch', 'fehlbild_unrealistisch', 'zahlen_unguenstig', 'formulierung',
    'didaktisch', 'kontext', 'loesung_passt_nicht',
    'aufgabe_fehlerhaft', 'aufgabe_unklar', 'bild_falsch', 'sprache_zu_schwer',
    'tablet_umbauen', 'passt_nicht_in_lsa', 'sonstiges']));
