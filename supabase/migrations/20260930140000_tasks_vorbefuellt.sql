-- Vorbefuellt-Kennzeichen (Nachtrag 2 zu PR #176).
--
-- Lena soll pro Aufgabe und pro Feld sehen, was ein Agent vorbefuellt oder
-- ueberschrieben hat und noch kein Mensch bestaetigt hat — auch Felder, die
-- bewusst leer blieben, mit Grund.
--
--   tasks.vorbefuellt     { "<feld>": { "art": "neu|ueberschrieben|ergaenzt|leer",
--                                        "grund": "...", "charge": "..." } }
--                         <feld> = Spalte ('afb', 'solution', 'hints' ...),
--                         'parts.<nr>.<schluessel>' oder 'correct_answers.<nr>'.
--   tasks.vorbefuellt_am  wann zuletzt vorbefuellt wurde.
--
-- Warum in tasks und nicht in einer eigenen Tabelle: Editor und Strecke lesen und
-- schreiben tasks ohnehin; die bestehenden Policies (read_tasks_by_role,
-- pruefer_update_tasks, admin_write_tasks) und der Tabellen-Grant decken die
-- neuen Spalten ab — Lena (Coach mit darf_pruefen) liest sie und setzt sie beim
-- Speichern zurueck, ohne neue RLS. tasks_pruefer_guard sperrt sie nicht.
--
-- Loesungsschutz: tasks ist fuer ready-Aufgaben auch fuer Schueler lesbar. Deshalb
-- traegt das Kennzeichen KEINE Werte (kein alter, kein neuer Wert) — nur Art und
-- Grund. Alte Werte stehen in der Charge-CSV (docs/prefill/). Der CHECK erzwingt das.

create function public.vorbefuellt_valid(p jsonb) returns boolean
    language sql immutable
    as $$
  select jsonb_typeof(p) = 'object'
     and not exists (
       select 1 from jsonb_each(p) as e(k, v)
        where btrim(k) = ''
           or jsonb_typeof(v) <> 'object'
           or coalesce(v ->> 'art', '') not in ('neu', 'ueberschrieben', 'ergaenzt', 'leer')
           or coalesce(btrim(v ->> 'grund'), '') = ''
           or v ?| array['alt', 'wert', 'neu']
     )
$$;

alter table public.tasks
  add column vorbefuellt jsonb not null default '{}'::jsonb,
  add column vorbefuellt_am timestamp with time zone,
  add constraint tasks_vorbefuellt_check check (public.vorbefuellt_valid(vorbefuellt));

comment on column public.tasks.vorbefuellt is
  'Vom Agenten vorbefuellte/ueberschriebene/bewusst leere Felder, noch nicht von einem Menschen bestaetigt. Keine Werte (Loesungsschutz).';
comment on column public.tasks.vorbefuellt_am is
  'Zeitpunkt der letzten Vorbefuellung.';
