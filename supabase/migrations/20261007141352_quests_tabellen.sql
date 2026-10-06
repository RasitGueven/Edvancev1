-- Q1 Home Quests — Tabellen, Rechte, Stellschrauben (Bauauftrag Session-Rahmen P1, Entscheidungen 4, 21, 22).
--
-- Zuhause wird nur "erledigt" gespeichert: keine Antworten, kein richtig oder falsch,
-- keine Dauer. Die Tabellen tragen deshalb keine Spalte, in die so etwas passen wuerde.
--
--   quests          eine Quest je Kind, Session und Art (A, B, KA)
--   quest_aufgaben  welche Aufgaben in einer Quest stehen, in welcher Reihenfolge
--   push_tokens     Geraete-Tokens fuer die spaetere Erinnerung (kein Versand in P1)
--
-- Schreiben nur ueber die SECURITY DEFINER-Funktionen der folgenden Q1-Migrationen.
-- Lesen: das Kind und seine Eltern die eigenen Quests, Admin alles, ein Coach nur
-- bei laufendem Vertrag (Entscheidung 26, hat_zugang). push_tokens liest niemand direkt.

create table public.quests (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students(id) on delete cascade,
  session_id   uuid not null references public.coaching_sessions(id) on delete cascade,
  art          text not null,
  ka_thema_key text,
  faellig_ab   date not null,
  termin       timestamptz,
  status       text not null default 'offen',
  erledigt_am  timestamptz,
  xp_gebucht   integer,
  angelegt_am  timestamptz not null default now(),
  constraint quests_art_check      check (art in ('A', 'B', 'KA')),
  constraint quests_status_check   check (status in ('offen', 'erledigt', 'verfallen')),
  constraint quests_ka_thema_check check ((art = 'KA') = (ka_thema_key is not null)),
  constraint quests_erledigt_check check ((status = 'erledigt') = (erledigt_am is not null)),
  constraint quests_xp_check       check (xp_gebucht is null or (xp_gebucht >= 0 and status = 'erledigt')),
  constraint quests_einmal_je_art  unique (session_id, student_id, art)
);

create index quests_student_idx on public.quests (student_id, faellig_ab);
create index quests_termin_idx  on public.quests (termin) where status = 'offen';

comment on table public.quests is
  'Home Quests (Q1). Speichert nur offen/erledigt/verfallen und den Zeitpunkt, nie Antworten oder Ergebnisse (FernUSG, Entscheidung 4).';
comment on column public.quests.session_id is 'Session, aus deren Check-out die Quest stammt.';
comment on column public.quests.faellig_ab is 'Ab diesem Tag (Europe/Berlin) ist die Quest abrufbar.';
comment on column public.quests.termin is 'Vom Kind im Check-out gewaehlter Termin; Grundlage der spaeteren Erinnerung.';
comment on column public.quests.xp_gebucht is 'Gebuchte XP (null = noch nicht gebucht). Wird genau einmal gesetzt.';

create table public.quest_aufgaben (
  quest_id    uuid not null references public.quests(id) on delete cascade,
  task_id     uuid not null references public.tasks(id) on delete cascade,
  reihenfolge smallint not null,
  constraint quest_aufgaben_pkey primary key (quest_id, reihenfolge),
  constraint quest_aufgaben_einmal unique (quest_id, task_id),
  constraint quest_aufgaben_reihenfolge_check check (reihenfolge >= 1)
);

comment on table public.quest_aufgaben is 'Aufgaben einer Home Quest (Q1), nur freigegebene mit Loesungsweg.';

create table public.push_tokens (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.students(id) on delete cascade,
  geraet      text,
  plattform   text not null,
  token       text not null,
  angelegt_am timestamptz not null default now(),
  constraint push_tokens_plattform_check check (plattform in ('ios', 'android', 'web')),
  constraint push_tokens_token_check     check (length(btrim(token)) between 1 and 4096),
  constraint push_tokens_token_einmal    unique (token)
);

comment on table public.push_tokens is
  'Push-Tokens der Kinder fuer die Quest-Erinnerung (Q1). Kein Versand in P1; Loeschung bei Vertragsende offen (Datenschutz).';

-- Rechte: die Default-Privilegien (20260711120000) geben authenticated DML auf jede neue
-- Tabelle. Hier wird alles entzogen und nur das Lesen gewaehrt, das die Policies tragen.
alter table public.quests         enable row level security;
alter table public.quest_aufgaben enable row level security;
alter table public.push_tokens    enable row level security;

revoke all on public.quests, public.quest_aufgaben, public.push_tokens from public, anon, authenticated;
grant select on public.quests, public.quest_aufgaben to authenticated;

create policy quests_select_own on public.quests
  for select to authenticated using (student_id = public.get_my_student_id());
create policy quests_select_parent on public.quests
  for select to authenticated using (public.is_parent_of_student(student_id));
create policy quests_select_admin on public.quests
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');
create policy quests_select_coach on public.quests
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'coach' and public.hat_zugang(student_id));

-- quest_aufgaben: nur Admin direkt; das Kind bekommt seine Aufgaben ueber quest_inhalt.
create policy quest_aufgaben_select_admin on public.quest_aufgaben
  for select to authenticated using (coalesce(public.get_my_role(), '') = 'admin');

-- ---------------------------------------------------------------------------
-- Stellschrauben. Die Tabelle session_einstellungen baut R1. Solange sie fehlt (oder
-- den Schluessel nicht kennt), gelten die Startwerte aus dem Bauauftrag (Entscheidung 22).
-- Die Spaltennamen schluessel/wert sind eine Annahme bis R1 eingespielt ist (offener Punkt).
-- ---------------------------------------------------------------------------
create function public.quest_einstellung(p_schluessel text)
returns text
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_wert text;
begin
  if to_regclass('public.session_einstellungen') is not null then
    begin
      execute 'select wert::text from public.session_einstellungen where schluessel = $1'
         into v_wert using p_schluessel;
    exception when undefined_column or undefined_table then
      v_wert := null;
    end;
  end if;

  v_wert := nullif(btrim(v_wert, ' "'), '');
  return coalesce(v_wert, case p_schluessel
    when 'quests_pro_woche'     then '2'
    when 'quest_minuten'        then '10'
    when 'quest_a_abstand_tage' then '2'
    when 'quest_xp'             then '50'
    when 'mischanteil'          then '0.30'
    when 'home_quests_aktiv'    then 'aus'
  end);
end;
$$;

create function public.quest_einstellung_zahl(p_schluessel text, p_rueckfall numeric)
returns numeric
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  return coalesce(public.quest_einstellung(p_schluessel)::numeric, p_rueckfall);
exception when invalid_text_representation then
  return p_rueckfall;
end;
$$;

create function public.home_quests_aktiv()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select lower(coalesce(public.quest_einstellung('home_quests_aktiv'), 'aus')) in ('an', 'true', '1', 'ja');
$$;

comment on function public.quest_einstellung(text) is
  'Liest eine Quest-Stellschraube aus session_einstellungen (R1), sonst den Startwert. Intern.';
comment on function public.home_quests_aktiv() is
  'Stellschraube home_quests_aktiv (Startwert aus). Solange aus, legt nur ein Systemaufruf Quests an.';

revoke all on function public.quest_einstellung(text)               from public, anon, authenticated;
revoke all on function public.quest_einstellung_zahl(text, numeric) from public, anon, authenticated;
revoke all on function public.home_quests_aktiv()                   from public, anon, authenticated;
