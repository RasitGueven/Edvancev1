-- Session-Rahmen P1, Paket A1 — Lernpfad und Mastery auf skill_key: Tabellen,
-- RLS und interne Helfer.
--
-- Grundlage: docs/session/Bauauftrag-Session-P1.md, Entscheidungen 3, 4, 6, 16, 23.
--
--   lernpfad            je Kind und skill_key eine Zeile. Der Systemzustand
--                       (stand_system) und die Entscheidung des Coaches
--                       (stand_coach) stehen in getrennten Spalten; keine
--                       Funktion schreibt beide (Entscheidung 3).
--   lernpfad_belege     Rohdaten aus Sessions, nur anhaengen (CLAUDE.md §6).
--                       Aus ihnen rechnet lernpfad_beleg den Systemzustand.
--   lernpfad_protokoll  wer hat wann was entschieden (Mastery, Pfad tiefer,
--                       Uebernahme aus der LSA), nur anhaengen.
--   skill_pruefung      Pruefgespraech je Skill (Frage, Erwartung, Kriterium).
--                       Inhalte kommen in P2; ausgeliefert wird nur 'freigegeben'.
--
-- Die bisherige Microskill-Mastery (student_competency_mastery u. a.) bleibt
-- unberuehrt und wird nicht weiter beschrieben (Entscheidung 23, Altlast).
--
-- Rechte: Admin liest alles, ein Coach den Lernpfad von Kindern mit laufendem
-- Vertrag (akte_aktiv, wie die Akte). Geschrieben wird nur ueber SECURITY
-- DEFINER-Funktionen; authenticated hat kein INSERT/UPDATE/DELETE.

-- ============================================================================
-- 1. Tabellen
-- ============================================================================

create table public.lernpfad (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.students(id) on delete cascade,
  skill_key         text not null references public.skills(skill_key),
  stand_system      text not null default 'offen'
                    check (stand_system in ('offen', 'aktiv', 'sicher', 'noch_nicht_sicher', 'kandidat')),
  stand_system_seit timestamptz not null default now(),
  stand_coach       text check (stand_coach in ('gemeistert', 'vertagt')),
  coach_grund       text,
  coach_von         uuid references public.profiles(id) on delete set null,
  coach_am          timestamptz,
  coach_session_id  uuid references public.coaching_sessions(id) on delete set null,
  quelle            text not null check (quelle in ('lsa', 'session', 'coach')),
  lsa_session_id    uuid references public.lsa_sessions(id) on delete set null,
  letzte_uebung_am  timestamptz,
  letzte_session_id uuid references public.coaching_sessions(id) on delete set null,
  belege            jsonb not null default '[]'::jsonb,
  angelegt          timestamptz not null default now(),
  aktualisiert      timestamptz not null default now(),
  constraint lernpfad_student_skill_uq unique (student_id, skill_key),
  constraint lernpfad_coach_vollstaendig
    check (stand_coach is null or (coach_am is not null)),
  constraint lernpfad_vertagt_braucht_grund
    check (stand_coach is distinct from 'vertagt' or nullif(btrim(coach_grund), '') is not null)
);

comment on table public.lernpfad is
  'Lernpfad je Kind und skill_key (Session-Rahmen A1). stand_system = Beleg des Systems, stand_coach = Entscheidung des Coaches; getrennt, eine Entscheidung ueberschreibt nie den Systemzustand.';
comment on column public.lernpfad.stand_system is
  'offen | aktiv (heute dran bzw. Pfad tiefer) | sicher | noch_nicht_sicher | kandidat (Mastery-Kandidat nach Entscheidung 16). Schreibt nur das System.';
comment on column public.lernpfad.stand_coach is
  'null | gemeistert | vertagt. Schreibt nur mastery_entscheiden. "Gemeistert" gibt es nur hier (Entscheidung 6).';
comment on column public.lernpfad.belege is
  'Verdichtung je Session: [{session_id, am, gesamt, richtig_ohne_hinweis}]. Rohdaten in lernpfad_belege.';

create index lernpfad_student_idx on public.lernpfad (student_id);

create table public.lernpfad_belege (
  id              uuid primary key default gen_random_uuid(),
  student_id      uuid not null references public.students(id) on delete cascade,
  skill_key       text not null references public.skills(skill_key),
  session_id      uuid not null references public.coaching_sessions(id) on delete restrict,
  ergebnis        text not null check (ergebnis in ('richtig', 'teilweise', 'falsch')),
  hinweis_genutzt boolean not null,
  -- clock_timestamp: Reihenfolge zu einer Coach-Entscheidung auch innerhalb
  -- einer Transaktion eindeutig (Vorschlag nach „vertagt“).
  zeit            timestamptz not null default clock_timestamp()
);

comment on table public.lernpfad_belege is
  'Rohbelege aus Sessions vor Ort (Entscheidung 4), nur anhaengen. Grundlage fuer stand_system und den Mastery-Kandidaten.';

create index lernpfad_belege_student_skill_idx on public.lernpfad_belege (student_id, skill_key);

create table public.lernpfad_protokoll (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  skill_key  text not null references public.skills(skill_key),
  aktion     text not null check (aktion in ('mastery', 'pfad_tiefer', 'uebernahme')),
  anlass     text not null check (anlass in ('lsa', 'pruefung', 'warmup', 'eingriff')),
  alt        jsonb,
  neu        jsonb,
  grund      text,
  von        uuid references public.profiles(id) on delete set null,
  session_id uuid references public.coaching_sessions(id) on delete set null,
  am         timestamptz not null default clock_timestamp()
);

comment on table public.lernpfad_protokoll is
  'Wer (von), wann (am), in welcher Session und aus welchem Anlass am Lernpfad entschieden wurde (Mastery, Pfad tiefer, Uebernahme). Nur anhaengen.';

create index lernpfad_protokoll_student_idx on public.lernpfad_protokoll (student_id, am);

create table public.skill_pruefung (
  id           uuid primary key default gen_random_uuid(),
  skill_key    text not null references public.skills(skill_key),
  frage        text not null,
  erwartung    text not null,
  kriterium    text not null,
  status       text not null default 'entwurf' check (status in ('entwurf', 'geprueft', 'freigegeben')),
  quelle       text not null check (quelle in ('ki', 'mensch')),
  angelegt     timestamptz not null default now(),
  aktualisiert timestamptz not null default now()
);

comment on table public.skill_pruefung is
  'Pruefgespraech fuer die Mastery-Pruefung am Platz (Entscheidung 16): Frage in anderem Kontext, Erwartung, Kriterium. Ausgeliefert wird nur status = freigegeben.';

create index skill_pruefung_skill_idx on public.skill_pruefung (skill_key);

-- ============================================================================
-- 2. Interne Helfer (nicht fuer authenticated)
-- ============================================================================

-- Darf der Aufrufer den Lernpfad dieses Kindes lesen? Admin immer, Coach nur
-- bei laufendem Vertrag (akte_aktiv, wie die Akte; Entscheidung 26).
create function public.lernpfad_darf_lesen(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case public.get_my_role()
           when 'admin' then true
           when 'coach' then public.akte_aktiv(p_student_id)
           else false
         end;
$$;

comment on function public.lernpfad_darf_lesen(uuid) is
  'Lesen des Lernpfads: Admin immer, Coach nur bei laufendem Vertrag (akte_aktiv). Grundlage der RLS-Regeln.';

-- Ist der Aufrufer Coach dieser Session, und ist das Kind dort gebucht?
create function public.lernpfad_coach_der_session(p_session_id uuid, p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.get_my_role() = 'coach'
     and exists (
       select 1
         from public.coaching_sessions cs
         join public.session_students ss on ss.session_id = cs.id
        where cs.id = p_session_id
          and cs.coach_id = auth.uid()
          and ss.student_id = p_student_id
     );
$$;

comment on function public.lernpfad_coach_der_session(uuid, uuid) is
  'true, wenn der Aufrufer Coach der Session ist und das Kind in ihr gebucht ist (session_students).';

-- Stellschraube lesen: zuerst der Snapshot der Session (R1:
-- coaching_sessions.einstellungen), dann session_einstellungen (R1), sonst der
-- Startwert aus dem Bauauftrag. Beide Quellen gibt es erst mit R1; der Zugriff
-- laeuft deshalb ueber to_jsonb bzw. dynamisches SQL und faellt bei jedem
-- Fehler auf den Startwert zurueck (offener Punkt A1-1).
create function public.lernpfad_stellschraube(p_schluessel text, p_session_id uuid default null)
returns numeric
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_wert  text;
  v_start numeric := case p_schluessel
                       when 'mastery_abstand_sessions'     then 1
                       when 'mastery_richtig_ohne_hinweis' then 2
                     end;
begin
  if p_session_id is not null then
    begin
      select to_jsonb(cs) -> 'einstellungen' ->> p_schluessel
        into v_wert
        from public.coaching_sessions cs
       where cs.id = p_session_id;
    exception when others then
      v_wert := null;
    end;
  end if;

  if v_wert is null and to_regclass('public.session_einstellungen') is not null then
    begin
      execute 'select to_jsonb(e) ->> ''wert'' from public.session_einstellungen e
                where to_jsonb(e) ->> ''schluessel'' = $1'
         into v_wert
        using p_schluessel;
    exception when others then
      v_wert := null;
    end;
  end if;

  begin
    return coalesce(v_wert::numeric, v_start);
  exception when others then
    return v_start;
  end;
end;
$$;

comment on function public.lernpfad_stellschraube(text, uuid) is
  'Stellschraube fuer A1: Session-Snapshot, dann session_einstellungen, sonst Startwert (mastery_abstand_sessions 1, mastery_richtig_ohne_hinweis 2).';

revoke all on function public.lernpfad_darf_lesen(uuid) from public, anon, authenticated;
revoke all on function public.lernpfad_coach_der_session(uuid, uuid) from public, anon, authenticated;
revoke all on function public.lernpfad_stellschraube(text, uuid) from public, anon, authenticated;
-- Die RLS-Regel ruft lernpfad_darf_lesen im Kontext des Aufrufers auf.
grant execute on function public.lernpfad_darf_lesen(uuid) to authenticated;

-- ============================================================================
-- 3. RLS und Tabellenrechte
-- ============================================================================

alter table public.lernpfad           enable row level security;
alter table public.lernpfad_belege    enable row level security;
alter table public.lernpfad_protokoll enable row level security;
alter table public.skill_pruefung     enable row level security;

-- Default Privileges (20260711120000_api_role_grants.sql) geben authenticated
-- DML auf jede neue Tabelle. Hier gilt: nur lesen, nur ueber die Regeln unten.
revoke all on public.lernpfad, public.lernpfad_belege, public.lernpfad_protokoll, public.skill_pruefung
  from anon, authenticated;
grant select on public.lernpfad, public.lernpfad_belege, public.lernpfad_protokoll, public.skill_pruefung
  to authenticated;

create policy lernpfad_lesen on public.lernpfad
  for select to authenticated
  using (public.lernpfad_darf_lesen(student_id));

create policy lernpfad_belege_lesen on public.lernpfad_belege
  for select to authenticated
  using (public.lernpfad_darf_lesen(student_id));

create policy lernpfad_protokoll_lesen on public.lernpfad_protokoll
  for select to authenticated
  using (public.lernpfad_darf_lesen(student_id));

-- Direkt liest nur der Admin (auch Entwuerfe). Coaches lesen ueber die
-- Funktion skill_pruefung_lesen (nur freigegeben); Kinder gar nicht, denn die
-- Erwartung ist Coach-Wissen.
create policy skill_pruefung_admin_lesen on public.skill_pruefung
  for select to authenticated
  using (public.get_my_role() = 'admin');
