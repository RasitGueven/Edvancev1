-- E1.1 Erklaersequenz: Datenmodell (Bauauftrag Session-P1, Entscheidungen 5, 18, 19).
--
-- Vier Tabellen:
--   erklaer_kernidee     2 bis 3 Kernideen je Skill, Pruefeinheit mit pruef_version
--   erklaer_schritt      je Kernidee und Variante (A, B, C) ein Erklaerschritt und
--                        ein Loesungsbeispiel; Formeln als SVG-Hashes, Bild wie task_figures
--   erklaer_check        Check-Aufgaben je Kernidee (normale tasks, Reihenfolge)
--   erklaer_fortschritt  append-only Protokoll je Session, Kind und Kernidee
--
-- Rechte (Entscheidung 5, Bauauftrag E1 Punkt 9):
--   - Kinder lesen NIE direkt. Sie bekommen Inhalte nur ueber erklaer_start,
--     erklaer_check_abgeben und erklaer_nachlesen, und nur freigegebene.
--   - Pruefer (darf_pruefen(): Admin oder Coach mit Pruefrecht) lesen alle Inhalte.
--   - Schreiben nur ueber SECURITY-DEFINER-Funktionen (keine INSERT/UPDATE/DELETE-
--     Policy, kein Schreib-Grant). erklaer_fortschritt lesen Admin und der Coach
--     der jeweiligen Session (Entscheidung 17: Live-Daten nur fuer die eigene Session).

create table public.erklaer_kernidee (
  id            uuid primary key default gen_random_uuid(),
  skill_key     text not null references public.skills (skill_key) on update cascade,
  nr            integer not null check (nr between 1 and 9),
  titel         text not null check (btrim(titel) <> ''),
  status        text not null default 'entwurf'
                check (status in ('entwurf', 'geprueft', 'freigegeben')),
  quelle        text not null default 'ki' check (quelle in ('ki', 'mensch')),
  pruef_version bigint not null default 1,
  angelegt_am   timestamptz not null default now(),
  geaendert_am  timestamptz not null default now(),
  unique (skill_key, nr)
);

comment on table public.erklaer_kernidee is
  'Kernideen der Erklaersequenz je Skill (Entscheidung 18). Status entwurf -> geprueft (Pruefer) -> freigegeben (Admin).';

-- Bild: entweder ein Bestandsasset {url, alt} oder eine generierte SVG {svg_hash, alt},
-- ausgeliefert unter task-assets/erklaer/<svg_hash>.svg (wie task_figures).
create function public.erklaer_bild_gueltig(p_bild jsonb) returns boolean
language sql immutable
set search_path = public, pg_temp
as $$
  select p_bild is null
      or (jsonb_typeof(p_bild) = 'object'
          and coalesce(btrim(p_bild ->> 'alt'), '') <> ''
          and ((p_bild ? 'url') <> (p_bild ? 'svg_hash'))
          and coalesce(p_bild ->> 'svg_hash', 'a') ~ '^[0-9a-f]+$'
          and coalesce(p_bild ->> 'url', 'https://') ~ '^https://'
          and not exists (select 1 from jsonb_object_keys(p_bild) k
                           where k not in ('url', 'svg_hash', 'alt')))
$$;

-- Formeln stehen im Markdown als $...$; formeln[i] ist der SVG-Hash der i-ten Formel.
create function public.erklaer_formel_anzahl(p_inhalt text) returns integer
language sql immutable
set search_path = public, pg_temp
as $$
  select count(*)::int from regexp_matches(coalesce(p_inhalt, ''), '\$[^$]+\$', 'g')
$$;

create table public.erklaer_schritt (
  id             uuid primary key default gen_random_uuid(),
  kernidee_id    uuid not null references public.erklaer_kernidee (id) on delete cascade,
  variante       text not null check (variante in ('A', 'B', 'C')),
  art            text not null check (art in ('erklaerung', 'beispiel')),
  inhalt         text not null check (btrim(inhalt) <> ''),
  formeln        text[] not null default '{}'
                 check (array_position(formeln, null) is null),
  bild           jsonb check (public.erklaer_bild_gueltig(bild)),
  fehlbild_slugs text[] not null default '{}',
  status         text not null default 'entwurf'
                 check (status in ('entwurf', 'geprueft', 'freigegeben')),
  angelegt_am    timestamptz not null default now(),
  geaendert_am   timestamptz not null default now(),
  unique (kernidee_id, variante, art)
);

comment on column public.erklaer_schritt.fehlbild_slugs is
  'Fehlbilder (fehlbild_labels.slug), fuer die diese Variante gedacht ist. erklaer_check_abgeben waehlt danach.';
comment on column public.erklaer_schritt.formeln is
  'SVG-Hashes der Formeln in Reihenfolge ihres Auftretens ($...$), erzeugt von tools/formeln-svg.mjs.';

create table public.erklaer_check (
  kernidee_id uuid not null references public.erklaer_kernidee (id) on delete cascade,
  task_id     uuid not null references public.tasks (id),
  reihenfolge integer not null check (reihenfolge >= 1),
  primary key (kernidee_id, task_id),
  unique (kernidee_id, reihenfolge)
);

comment on table public.erklaer_check is
  'Check-Aufgaben je Kernidee. Normale tasks; Einsatz check (X0) wird beim Anlegen der Inhalte in P2 gesetzt.';

create table public.erklaer_fortschritt (
  id            bigint generated always as identity primary key,
  -- Eine Session mit Lernverlauf darf nicht geloescht werden (Entscheidung Rasit 06.10.).
  session_id    uuid not null references public.coaching_sessions (id) on delete restrict,
  student_id    uuid not null references public.students (id) on delete cascade,
  kernidee_id   uuid not null references public.erklaer_kernidee (id),
  runde         integer not null check (runde >= 1),
  variante      text check (variante in ('A', 'B', 'C')),
  check_task_id uuid references public.tasks (id),
  ergebnis      text not null check (ergebnis in ('gezeigt', 'richtig', 'falsch', 'signal')),
  fehlbild_slug text,
  zeit          timestamptz not null default now()
);

comment on table public.erklaer_fortschritt is
  'Append-only: gezeigt (Variante + offener Check), richtig/falsch (Check-Ergebnis mit Fehlbild), signal (Coach).';

create index erklaer_fortschritt_kind_idx
  on public.erklaer_fortschritt (session_id, student_id, id);
-- Zweite Sicherung neben der Sperre in erklaer_check_abgeben: je Runde hoechstens ein Ergebnis.
create unique index erklaer_fortschritt_ergebnis_einmal
  on public.erklaer_fortschritt (session_id, student_id, kernidee_id, runde, ergebnis)
  where ergebnis <> 'gezeigt';
create index erklaer_schritt_kernidee_idx on public.erklaer_schritt (kernidee_id);
create index erklaer_check_task_idx on public.erklaer_check (task_id);

-- Append-only wie behavior_snapshots (CLAUDE.md §6): kein Update, kein Delete.
-- Ausnahme: das Loeschen per Kaskade, wenn das Kind geloescht wird (z. B. DSGVO).
-- Das laeuft ueber die Fremdschluessel-Trigger, also mit pg_trigger_depth() > 1.
create function public.erklaer_fortschritt_nur_anhaengen() returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if tg_op = 'DELETE' and pg_trigger_depth() > 1 then
    return old;
  end if;
  raise exception 'erklaer_fortschritt ist append-only' using errcode = '42501';
end;
$$;

create trigger erklaer_fortschritt_nur_anhaengen
  before update or delete on public.erklaer_fortschritt
  for each row execute function public.erklaer_fortschritt_nur_anhaengen();

-- RLS -------------------------------------------------------------------------
alter table public.erklaer_kernidee    enable row level security;
alter table public.erklaer_schritt     enable row level security;
alter table public.erklaer_check       enable row level security;
alter table public.erklaer_fortschritt enable row level security;

revoke all on table public.erklaer_kernidee, public.erklaer_schritt,
                    public.erklaer_check, public.erklaer_fortschritt
  from public, anon, authenticated;
grant select on table public.erklaer_kernidee, public.erklaer_schritt,
                      public.erklaer_check, public.erklaer_fortschritt
  to authenticated;

create policy erklaer_kernidee_pruefer_lesen on public.erklaer_kernidee
  for select to authenticated using (public.darf_pruefen());
create policy erklaer_schritt_pruefer_lesen on public.erklaer_schritt
  for select to authenticated using (public.darf_pruefen());
create policy erklaer_check_pruefer_lesen on public.erklaer_check
  for select to authenticated using (public.darf_pruefen());

create policy erklaer_fortschritt_admin_coach_lesen on public.erklaer_fortschritt
  for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin'
         or exists (select 1 from public.coaching_sessions cs
                     where cs.id = erklaer_fortschritt.session_id
                       and cs.coach_id = auth.uid()));

revoke all on function public.erklaer_bild_gueltig(jsonb) from public, anon, authenticated;
revoke all on function public.erklaer_formel_anzahl(text) from public, anon, authenticated;
revoke all on function public.erklaer_fortschritt_nur_anhaengen() from public, anon, authenticated;
