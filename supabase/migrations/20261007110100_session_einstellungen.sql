-- R1.1 Stellschrauben der Session (Bauauftrag Session-Rahmen P1, Entscheidung 22).
--
-- Alle paedagogischen Werte sind Einstellungen mit Startwert und Spanne. Admins
-- aendern sie ohne Deployment ueber einstellung_setzen; jede Aenderung landet in
-- session_einstellungen_protokoll (Muster task_admin_protokoll: wer, wann, alt,
-- neu, grund). Jede Session friert beim Start die Werte als Snapshot ein
-- (coaching_sessions.einstellungen, Migration 20261007110200).
--
-- Lesen: authenticated (Tablet und Coach brauchen die Werte). Schreiben: nur
-- ueber einstellung_setzen, nur Admin, Spanne geprueft. Der Spannen-Check sitzt
-- zusaetzlich als CHECK an der Tabelle, damit auch kein Definer-Weg vorbeikommt.

create function public.session_einstellung_gueltig(
  p_typ      text,
  p_min      numeric,
  p_max      numeric,
  p_ganzzahl boolean,
  p_werte    text[],
  p_wert     jsonb
)
returns boolean
language sql
immutable
set search_path = public, pg_temp
as $$
  select case p_typ
    when 'zahl' then
      jsonb_typeof(p_wert) = 'number'
      and (p_wert #>> '{}')::numeric between p_min and p_max
      and (not p_ganzzahl or (p_wert #>> '{}')::numeric = trunc((p_wert #>> '{}')::numeric))
    when 'auswahl' then
      jsonb_typeof(p_wert) = 'string' and (p_wert #>> '{}') = any (p_werte)
    when 'schalter' then
      jsonb_typeof(p_wert) = 'boolean'
    else false
  end
$$;

create table public.session_einstellungen (
  schluessel    text primary key check (schluessel ~ '^[a-z][a-z_]*$'),
  beschreibung  text not null,
  typ           text not null check (typ in ('zahl', 'auswahl', 'schalter')),
  wert          jsonb not null,
  startwert     jsonb not null,
  min           numeric,
  max           numeric,
  ganzzahl      boolean not null default true,
  werte         text[],
  einheit       text check (einheit in ('minuten', 'anzahl', 'stufen', 'anteil', 'tage', 'sessions', 'xp')),
  geaendert_am  timestamptz,
  geaendert_von uuid references public.profiles(id) on delete set null,
  constraint session_einstellungen_spanne check (
    (typ = 'zahl' and min is not null and max is not null and min <= max and werte is null)
    or (typ = 'auswahl' and min is null and max is null and cardinality(werte) >= 2)
    or (typ = 'schalter' and min is null and max is null and werte is null)
  ),
  constraint session_einstellungen_wert_gueltig check (
    public.session_einstellung_gueltig(typ, min, max, ganzzahl, werte, wert)
    and public.session_einstellung_gueltig(typ, min, max, ganzzahl, werte, startwert)
  )
);

comment on table public.session_einstellungen is
  'R1 Stellschrauben (Entscheidung 22). Lesen authenticated, schreiben nur ueber einstellung_setzen (Admin).';

insert into public.session_einstellungen
  (schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, werte, einheit)
select k, b, t, w, w, mi, ma, g, ws, e
  from (values
    ('phase_checkin_min', 'Dauer Check-in', 'zahl', '5'::jsonb, 3, 8, true, null::text[], 'minuten'),
    ('phase_warmup_min', 'Dauer Warm-up', 'zahl', '10', 5, 15, true, null, 'minuten'),
    ('phase_checkout_min', 'Dauer Check-out', 'zahl', '5', 3, 10, true, null, 'minuten'),
    ('warmup_aufgaben', 'Aufgaben im Warm-up', 'zahl', '3', 1, 5, true, null, 'anzahl'),
    ('warmup_leichter_stufen', 'Warm-up leichter als Kernarbeit um', 'zahl', '1', 0, 2, true, null, 'stufen'),
    ('ziel_erfolgsquote', 'Ziel-Erfolgsquote', 'zahl', '0.80', 0.60, 0.90, false, null, 'anteil'),
    ('mischanteil', 'Anteil älterer Aufgaben in der Kernarbeit', 'zahl', '0.30', 0, 0.50, false, null, 'anteil'),
    ('ka_tage', 'Klassenarbeit zählt und Mischen pausiert, wenn sie näher liegt als (Tage)', 'zahl', '7', 0, 14, true, null, 'tage'),
    ('hinweisstufen', 'Hinweisstufen je Aufgabe', 'zahl', '3', 0, 3, true, null, 'stufen'),
    ('signal_fehlversuche', 'Signal nach Fehlversuchen in Folge', 'zahl', '2', 1, 4, true, null, 'anzahl'),
    ('signal_minuten_ohne_fortschritt', 'Signal nach Minuten ohne Eingabe', 'zahl', '3', 1, 10, true, null, 'minuten'),
    ('mikro_erklaerung_min', 'Mikro-Erklärung höchstens (Minuten)', 'zahl', '2', 1, 5, true, null, 'minuten'),
    ('kernideen_max', 'Kernideen pro Skill höchstens', 'zahl', '3', 1, 5, true, null, 'anzahl'),
    ('check_aufgaben_je_kernidee', 'Check-Aufgaben je Kernidee', 'zahl', '1', 1, 3, true, null, 'anzahl'),
    ('erklaerrunden_bis_signal', 'Erklärrunden bis Coach-Signal', 'zahl', '2', 1, 3, true, null, 'anzahl'),
    ('erklaerung_bei_neuem_skill', 'Erklärung bei neuem Skill', 'auswahl', '"vorgeschaltet"', null, null, true,
       array['vorgeschaltet', 'angeboten'], null),
    ('loesungsbeispiele_vor_aufgabe', 'Lösungsbeispiele vor der ersten eigenen Aufgabe', 'zahl', '1', 0, 3, true, null, 'anzahl'),
    ('erklaerung_anbieten_nach_fehlversuchen', '„Nochmal erklären“ anbieten nach Fehlversuchen', 'zahl', '2', 1, 4, true, null, 'anzahl'),
    ('mastery_abstand_sessions', 'Mastery-Kandidat frühestens nach Sessions', 'zahl', '1', 1, 3, true, null, 'sessions'),
    ('mastery_richtig_ohne_hinweis', 'dafür richtig ohne Hinweis', 'zahl', '2', 2, 6, true, null, 'anzahl'),
    ('mastery_kandidaten_je_raum', 'Mastery-Prüfungen je Raum und Session', 'zahl', '3', 1, 5, true, null, 'anzahl'),
    ('exit_aufgaben', 'Exit-Aufgaben', 'zahl', '2', 1, 3, true, null, 'anzahl'),
    ('thema_alt_tage', 'Schulthema im Briefing zum Nachfragen markieren nach (Tage)', 'zahl', '21', 7, 42, true, null, 'tage'),
    ('quests_pro_woche', 'Home Quests pro Woche', 'zahl', '2', 0, 3, true, null, 'anzahl'),
    ('quest_minuten', 'Dauer einer Quest (Minuten)', 'zahl', '10', 5, 20, true, null, 'minuten'),
    ('quest_a_abstand_tage', 'Quest A nach der Session (Tage)', 'zahl', '2', 1, 3, true, null, 'tage'),
    ('quest_xp', 'XP je erledigter Quest', 'zahl', '50', 10, 100, true, null, 'xp'),
    ('home_quests_aktiv', 'Home Quests eingeschaltet', 'schalter', 'false', null, null, true, null, null)
  ) as v(k, b, t, w, mi, ma, g, ws, e);

create table public.session_einstellungen_protokoll (
  id         uuid primary key default gen_random_uuid(),
  schluessel text not null references public.session_einstellungen(schluessel),
  alt        jsonb not null,
  neu        jsonb not null,
  grund      text not null check (nullif(btrim(grund), '') is not null),
  von        uuid references public.profiles(id) on delete set null,
  am         timestamptz not null default now()
);

create index session_einstellungen_protokoll_idx
  on public.session_einstellungen_protokoll (schluessel, am desc);

comment on table public.session_einstellungen_protokoll is
  'R1 Aenderungsprotokoll der Stellschrauben (Muster task_admin_protokoll). Nur anhaengen; lesen nur Admin.';

alter table public.session_einstellungen enable row level security;
alter table public.session_einstellungen_protokoll enable row level security;

create policy session_einstellungen_lesen on public.session_einstellungen
  for select to authenticated using (true);
create policy session_einstellungen_protokoll_admin on public.session_einstellungen_protokoll
  for select to authenticated using (public.get_my_role() = 'admin');

revoke all on public.session_einstellungen, public.session_einstellungen_protokoll
  from public, anon, authenticated;
grant select on public.session_einstellungen, public.session_einstellungen_protokoll to authenticated;

-- einstellung_setzen: ein Wert, Spanne geprueft, Grund Pflicht, Protokollzeile.
-- Ein unveraenderter Wert schreibt nichts (kein Protokoll ohne Aenderung).
create function public.einstellung_setzen(p_schluessel text, p_wert jsonb, p_grund text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v public.session_einstellungen;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'einstellung_setzen: nur Admin' using errcode = '42501';
  end if;
  if nullif(btrim(coalesce(p_grund, '')), '') is null then
    raise exception 'einstellung_setzen: Grund ist Pflicht' using errcode = '22023';
  end if;

  select * into v from public.session_einstellungen where schluessel = p_schluessel for update;
  if not found then
    raise exception 'einstellung_setzen: unbekannte Stellschraube %', p_schluessel using errcode = 'P0002';
  end if;
  if p_wert is null
     or not public.session_einstellung_gueltig(v.typ, v.min, v.max, v.ganzzahl, v.werte, p_wert) then
    raise exception 'einstellung_setzen: Wert % liegt ausserhalb der Spanne von %', p_wert, p_schluessel
      using errcode = '22023', hint = 'spanne:' || p_schluessel;
  end if;
  if v.wert = p_wert then
    return;
  end if;

  update public.session_einstellungen
     set wert = p_wert, geaendert_am = now(), geaendert_von = auth.uid()
   where schluessel = p_schluessel;

  insert into public.session_einstellungen_protokoll (schluessel, alt, neu, grund, von)
  values (p_schluessel, v.wert, p_wert, btrim(p_grund), auth.uid());
end;
$$;

comment on function public.einstellung_setzen(text, jsonb, text) is
  'R1: setzt eine Stellschraube (nur Admin, Spanne geprueft, Grund Pflicht) und protokolliert alt/neu.';

revoke all on function public.session_einstellung_gueltig(text, numeric, numeric, boolean, text[], jsonb)
  from public, anon, authenticated;
revoke all on function public.einstellung_setzen(text, jsonb, text) from public, anon, authenticated;
grant execute on function public.einstellung_setzen(text, jsonb, text) to authenticated;
