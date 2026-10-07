-- A2.1 Session-Engine: Grundlagen (Bauauftrag Session-Rahmen P1, Entscheidungen A2 B, C, D, J).
--
--   session_schritte      jeder Schritt, den die Engine einem Kind gibt (nur anhaengen). Traegt
--                         den Grund fuer den Coach (Entscheidung N) und ist das Gedaechtnis der
--                         Engine: gezeigte Beispiele, Warm-up-Zaehler, Mischzaehler, Exit.
--   session_im_pool       Pool fuer die Session (J): 'session' im Einsatz, aktiv, kein Tutorial,
--                         Uebung, mit Loesung; ready, im Testlauf auch draft/review/rueckfrage
--                         ohne pruef_ausschluss (wie lsa_im_pool aus X0).
--   session_uhr_phase     Phase nach der Uhr der Session (C): gestartet_am plus Snapshot.
--   session_zielliste     Ziel der Stunde (D): Klassenarbeit/Schulthema -> ziel_fertigkeiten,
--                         Lernpfad -> naechste_luecke; je Zeile, ob der Skill noch offen ist.
--
-- A1-Funktionen bekommen einen Kern ohne Rechtepruefung (*_core), weil die Engine unter dem
-- Geraetekonto des Tablets laeuft (Rolle student). Die bisherigen Funktionen pruefen wie
-- vorher und rufen den Kern; Signatur und Ergebnis bleiben gleich.
-- lernpfad_stellschraube liest den Snapshot der Session (B), ohne dynamisches SQL.

create table public.session_schritte (
  id            bigint generated always as identity primary key,
  session_id    uuid not null references public.coaching_sessions(id) on delete restrict,
  student_id    uuid not null references public.students(id) on delete cascade,
  art           text not null check (art in ('erklaerung', 'beispiel', 'aufgabe', 'erklaerung_angebot', 'exit',
                                             'termin', 'fertig', 'warten')),
  phase         text not null check (phase in ('checkin', 'warmup', 'kern', 'checkout')),
  skill_key     text references public.skills(skill_key),
  task_id       uuid references public.tasks(id),
  modus         text check (modus in ('gefuehrt', 'selbststaendig')),
  eingemischt   boolean not null default false,
  nach_beispiel boolean not null default false,
  schwierigkeit smallint check (schwierigkeit between 1 and 5),
  grund         text not null check (nullif(btrim(grund), '') is not null),
  grund_code    text not null,
  zeit          timestamptz not null default clock_timestamp(),
  -- nur gebuchte Kinder (no action: eine Buchung mit Verlauf bleibt)
  foreign key (session_id, student_id) references public.session_students(session_id, student_id)
);

create index session_schritte_kind_idx on public.session_schritte (session_id, student_id, id desc);
create index session_schritte_task_idx on public.session_schritte (student_id, task_id) where task_id is not null;
create index session_ausgegeben_kind_task_idx on public.session_ausgegeben (student_id, task_id, zeit);
create index session_antworten_task_idx on public.session_antworten (student_id, task_id);

comment on table public.session_schritte is
  'A2: Schritte der Session-Engine je Kind (append-only), mit Grund fuer den Coach. Schreiben nur session_naechster_schritt.';

create trigger session_schritte_nur_anhaengen
  before update or delete on public.session_schritte
  for each row execute function public.session_nur_anhaengen();

alter table public.session_schritte enable row level security;
revoke all on public.session_schritte from public, anon, authenticated;

-- ── Pool (J) ──────────────────────────────────────────────────────────────
-- Kein SECURITY DEFINER, damit der Planer die Bedingung in seine Abfrage einbettet.
create function public.session_im_pool(p_task_id uuid, p_testlauf boolean default false)
returns boolean
language sql
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.tasks t
     where t.id = p_task_id
       and coalesce(t.is_active, false)
       and not coalesce(t.is_tutorial, false)
       and t.content_type = 'exercise'
       and 'session' = any (t.einsatz)
       and exists (select 1 from public.task_solutions s
                    where s.task_id = t.id
                      and public.lsa_has_answers(t.input_type, t.parts, s.correct_answers))
       and (t.status = 'ready'
            or (coalesce(p_testlauf, false)
                and t.status in ('draft', 'review', 'rueckfrage')
                and public.pruef_ausschluss(t.id) is null))
  )
$$;

comment on function public.session_im_pool(uuid, boolean) is
  'A2 Pool der Session (J): Einsatz session, aktiv, kein Tutorial, exercise, Loesung; ready, im Testlauf auch ungepruefte ohne pruef_ausschluss.';

-- ── Uhr (C) ───────────────────────────────────────────────────────────────
-- Eine Session dauert 60 Minuten (Entscheidung 1). Phasen aus dem Snapshot.
create function public.session_uhr_phase(p_session_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when cs.gestartet_am is null then null
    when now() < cs.gestartet_am + public.session_wert_zahl(cs.id, 'phase_checkin_min') * interval '1 minute'
      then 'checkin'
    when now() < cs.gestartet_am + (public.session_wert_zahl(cs.id, 'phase_checkin_min')
                                   + public.session_wert_zahl(cs.id, 'phase_warmup_min')) * interval '1 minute'
      then 'warmup'
    when now() < cs.gestartet_am + (60 - public.session_wert_zahl(cs.id, 'phase_checkout_min')) * interval '1 minute'
      then 'kern'
    else 'checkout'
  end
    from public.coaching_sessions cs where cs.id = p_session_id
$$;

-- ── Stellschrauben aus dem Snapshot (B) ───────────────────────────────────
create or replace function public.lernpfad_stellschraube(p_schluessel text, p_session_id uuid default null)
returns numeric
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_start numeric := case p_schluessel
                       when 'mastery_abstand_sessions'     then 1
                       when 'mastery_richtig_ohne_hinweis' then 2
                     end;
begin
  -- Snapshot der Session, vor dem Start (oder ohne Session) die Tabelle, sonst der Startwert.
  return coalesce(public.session_wert_zahl(p_session_id, p_schluessel), v_start);
exception when others then
  return v_start;
end;
$$;

comment on function public.lernpfad_stellschraube(text, uuid) is
  'Stellschraube fuer A1: Snapshot der Session (session_wert), ohne Session session_einstellungen, sonst Startwert.';
