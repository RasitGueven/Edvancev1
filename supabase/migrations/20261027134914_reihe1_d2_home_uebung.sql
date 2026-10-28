-- Reihe 1 · D2 Übung zuhause, Offen-Regeln, „Zeig's mir“, Fragen an den Coach (Bauauftrag D, Konzept §9).
--
-- FernUSG (Entscheidung 3): Zuhause wird nur gespeichert, DASS geübt wurde — Kind, Skill, Anzahl Aufgaben, Dauer,
-- Zeitpunkt. Keine Antworten, keine Richtigkeit, kein Fehlbild. Kein Befund, keine Stufe, kein Lernpfad ändert sich.
-- XP (Entscheidung 7) bucht home_uebung_melden fürs Üben, nie fürs Richtig-Haben.
--
--   home_uebung              eine Zeile je erledigter Quest, append-only
--   home_uebung_melden       das Kind selbst (auch ohne Gerätezeile)
--   home_uebung_kurz         Kind selbst, Coach mit aktiver Akte, Admin; „n×“ = Quests seit der letzten
--                            abgeschlossenen Session vor Ort (home_letzte_session)
--   home_pfad                Pfad des Kindes: XP, Level, Wochen mit Übung, Serie, Quests diese Woche
--   kompetenz_offen          Offen-Regeln 1–6 der Anforderung Themenbaum §3 (stable, schreibt nicht)
--   kompetenz_offen_merken   schreibt neu Offenes nach schueler_kompetenz_offen (Regel 6: einmal offen bleibt offen);
--                            dasselbe tun Trigger vor und nach jeder Änderung an lernpfad, lead_themen, lead_klassenarbeiten
--   zeigs_mir_uebernommen    intern für C: übernommener Skill oder null (nur lesen)
--   zeigs_mir                höchstens ein Vorschlag je Kind und Session (unique)
--   zeigs_mir_offen          Coach der Session, Admin: legt den Vorschlag beim ersten Abruf an
--   zeigs_mir_entscheiden    Coach der Session, Admin: uebernehmen | nicht_heute
--   coach_fragen             „Frage für meinen Coach“ aus Eddie (D5); eddie_frage_merken, coach_fragen_offen,
--                            coach_frage_erledigt
--
-- Fremde Funktionen (aufgabe_werten von A) ruft diese Migration nicht auf; die App wertet zuhause selbst über
-- aufgabe_werten (rein) und meldet nur das Ergebnis „erledigt“. Rollback: supabase/rollback/20261027134914_reihe1_d2_home_uebung.sql.

-- ── Tabellen ────────────────────────────────────────────────────────────────
create table public.home_uebung (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  skill_key  text not null references public.skills(skill_key),
  aufgaben   integer not null check (aufgaben between 1 and 20),
  dauer_sek  integer not null check (dauer_sek between 0 and 7200),
  am         timestamptz not null default now()
);
create index home_uebung_kind_am_idx on public.home_uebung (student_id, am desc);

create function public.home_uebung_append_only()
returns trigger
language plpgsql
as $$
begin
  raise exception 'home_uebung ist append-only' using errcode = '42501';
end;
$$;
create trigger home_uebung_append_only before update or delete on public.home_uebung
  for each row execute function public.home_uebung_append_only();
comment on table public.home_uebung is
  'Reihe 1 · D2: eine Zeile je erledigter Home-Quest. Nur „dass geübt wurde“ (FernUSG): keine Antworten, keine Richtigkeit. Append-only.';

create table public.schueler_kompetenz_offen (
  student_id uuid not null references public.students(id) on delete cascade,
  skill_key  text not null references public.skills(skill_key),
  seit       timestamptz not null default now(),
  grund      text not null check (grund in ('befund', 'aktuell', 'grundlage', 'voraussetzungen', 'frueher', 'start')),
  primary key (student_id, skill_key)
);
comment on table public.schueler_kompetenz_offen is
  'Anforderung Themenbaum §3 Regel 6: einmal offen bleibt offen. Fortgeschrieben von kompetenz_offen_merken, nie gelöscht.';

create table public.zeigs_mir (
  student_id      uuid not null references public.students(id) on delete cascade,
  session_id      uuid not null references public.coaching_sessions(id) on delete cascade,
  skill_key       text not null references public.skills(skill_key),
  quests          integer not null,
  vorschlag_am    timestamptz not null default now(),
  entscheidung    text check (entscheidung in ('uebernehmen', 'nicht_heute')),
  entschieden_von uuid references public.profiles(id) on delete set null,
  entschieden_am  timestamptz,
  primary key (student_id, session_id),
  constraint zeigs_mir_entscheidung_vollstaendig check ((entscheidung is null) = (entschieden_am is null))
);
comment on table public.zeigs_mir is
  'Reihe 1 · D2: höchstens ein Vorschlag „Zeig''s mir“ je Kind und Session (Entscheidung 5). C liest ihn über zeigs_mir_offen.';

create table public.coach_fragen (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students(id) on delete cascade,
  text         text not null check (char_length(btrim(text)) between 1 and 280),
  am           timestamptz not null default now(),
  erledigt_am  timestamptz,
  erledigt_von uuid references public.profiles(id) on delete set null
);
create index coach_fragen_offen_idx on public.coach_fragen (student_id) where erledigt_am is null;
comment on table public.coach_fragen is 'Reihe 1 · D2/D5: Fragen, die das Kind zuhause bei Eddie für den Coach merkt.';

alter table public.home_uebung enable row level security;
alter table public.schueler_kompetenz_offen enable row level security;
alter table public.zeigs_mir enable row level security;
alter table public.coach_fragen enable row level security;
-- Gelesen wird nur über die Funktionen; der Admin darf die Rohdaten sehen.
create policy home_uebung_admin_lesen on public.home_uebung for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin');
create policy schueler_kompetenz_offen_admin_lesen on public.schueler_kompetenz_offen for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin');
create policy zeigs_mir_admin_lesen on public.zeigs_mir for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin');
create policy coach_fragen_admin_lesen on public.coach_fragen for select to authenticated
  using (coalesce(public.get_my_role(), '') = 'admin');

revoke all on table public.home_uebung, public.schueler_kompetenz_offen, public.zeigs_mir, public.coach_fragen from anon;
revoke insert, update, delete, truncate on table public.home_uebung, public.schueler_kompetenz_offen, public.zeigs_mir,
  public.coach_fragen from authenticated;
grant select on table public.home_uebung, public.schueler_kompetenz_offen, public.zeigs_mir, public.coach_fragen to authenticated;

-- ── Hilfen ──────────────────────────────────────────────────────────────────
-- Wer darf die Übung eines Kindes lesen? Das Kind selbst, der Coach mit aktiver Akte, der Admin.
create function public.home_darf_lesen(p_kind uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role(), '') = 'admin'
      or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_kind))
      or coalesce(public.get_my_student_id() = p_kind, false);
$$;
comment on function public.home_darf_lesen(uuid) is 'Intern: Kind selbst, Coach mit aktiver Akte, Admin.';

-- Ende der letzten abgeschlossenen Session vor Ort, in der das Kind da war (vor p_vor, ohne Testläufe).
create function public.home_letzte_session(p_kind uuid, p_vor timestamptz default null)
returns timestamptz
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select max(cs.beendet_am)
    from public.coaching_sessions cs
    join public.session_students ss on ss.session_id = cs.id
   where ss.student_id = p_kind and ss.attendance = 'present'
     and cs.beendet_am is not null and not coalesce(cs.testlauf, false)
     and (p_vor is null or cs.beendet_am < p_vor);
$$;
comment on function public.home_letzte_session(uuid, timestamptz) is
  'Intern: Ende der letzten abgeschlossenen Session vor Ort mit Anwesenheit (Zählweise „n× geübt“, Konzept §9).';

-- ── Übung melden und lesen ──────────────────────────────────────────────────
create function public.home_uebung_melden(p_skill text, p_anzahl integer, p_dauer_sek integer)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind  uuid := public.get_my_student_id();
  v_id    uuid;
  v_xp    integer;
  v_heute integer;
begin
  if v_kind is null then
    raise exception 'home_uebung_melden: nur das Kind selbst' using errcode = '42501';
  end if;
  if not public.hat_zugang(v_kind) then
    raise exception 'home_uebung_melden: kein laufender Vertrag' using errcode = '42501';
  end if;
  if p_skill is null or not exists (select 1 from public.skills s where s.skill_key = p_skill) then
    raise exception 'home_uebung_melden: Skill unbekannt' using errcode = '22023';
  end if;
  if p_anzahl is null or p_anzahl not between 1 and 20 or p_dauer_sek is null or p_dauer_sek not between 0 and 7200 then
    raise exception 'home_uebung_melden: Anzahl 1–20, Dauer 0–7200 s' using errcode = '22023';
  end if;
  if p_dauer_sek < p_anzahl * 5 then
    raise exception 'home_uebung_melden: zu kurz für % Aufgaben', p_anzahl using errcode = '22023';
  end if;
  if exists (select 1 from public.kompetenz_offen_roh(v_kind) o where o.skill_key = p_skill and o.zustand = 'gesperrt') then
    raise exception 'home_uebung_melden: Skill ist noch gesperrt' using errcode = '22023';
  end if;

  -- Meldungen eines Kindes nacheinander; ein Wiederholungsversuch derselben Quest (gleicher Skill, < 60 s) bucht nichts.
  perform pg_advisory_xact_lock(hashtext('home_uebung:' || v_kind::text));
  if exists (select 1 from public.home_uebung h
              where h.student_id = v_kind and h.skill_key = p_skill and h.am > now() - interval '60 seconds') then
    return;
  end if;
  select count(*) into v_heute from public.home_uebung h
   where h.student_id = v_kind
     and (h.am at time zone 'Europe/Berlin')::date = (now() at time zone 'Europe/Berlin')::date;
  if v_heute >= 40 then
    raise exception 'home_uebung_melden: Tagesgrenze erreicht' using errcode = '54000';
  end if;

  insert into public.home_uebung (student_id, skill_key, aufgaben, dauer_sek)
  values (v_kind, p_skill, p_anzahl, p_dauer_sek)
  returning id into v_id;

  -- XP fürs Üben (Stellschraube home_uebung_xp, Start 10), getrennt von jeder Kompetenz; XP nur für die ersten
  -- zehn Quests eines Tages (höchstens 100 XP), geübt werden darf weiter.
  v_xp := least(greatest(public.quest_einstellung_zahl('home_uebung_xp', 10)::integer, 0), 1000);
  if v_xp > 0 and v_heute < 10 then
    perform public.xp_buchen_intern(v_kind, v_xp, 'home_uebung', 'home_uebung:' || v_id::text, null);
  end if;
end;
$$;
comment on function public.home_uebung_melden(text, integer, integer) is
  'Das Kind selbst: eine erledigte Home-Quest (Skill, Anzahl, Dauer). Speichert nie Antworten oder Richtigkeit. reihe1 fertig';

create function public.home_uebung_kurz(p_kind uuid, p_seit timestamptz default null)
returns table (skill_key text, quests integer, aufgaben integer, dauer_sek integer, zuletzt timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_seit timestamptz;
begin
  if not public.home_darf_lesen(p_kind) then
    raise exception 'home_uebung_kurz: kein Zugriff' using errcode = '42501';
  end if;
  v_seit := coalesce(p_seit, public.home_letzte_session(p_kind), '-infinity'::timestamptz);
  return query
    select h.skill_key, count(*)::integer, sum(h.aufgaben)::integer, sum(h.dauer_sek)::integer, max(h.am)
      from public.home_uebung h
     where h.student_id = p_kind and h.am > v_seit
     group by h.skill_key
     order by count(*) desc, max(h.am) desc;
end;
$$;
comment on function public.home_uebung_kurz(uuid, timestamptz) is
  'Übung zuhause je Skill seit p_seit (null: seit der letzten abgeschlossenen Session vor Ort). Kind, Coach, Admin. reihe1 fertig';

create function public.home_pfad(p_kind uuid)
returns table (xp_total integer, level integer, wochen_mit_uebung integer, serie_wochen integer,
               quests_diese_woche integer, praesenz_wochen integer)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_woche  date := date_trunc('week', now() at time zone 'Europe/Berlin')::date;
  v_wochen date[];
  v_pruef  date;
  v_serie  integer := 0;
begin
  if not public.home_darf_lesen(p_kind) then
    raise exception 'home_pfad: kein Zugriff' using errcode = '42501';
  end if;
  select coalesce(array_agg(distinct date_trunc('week', h.am at time zone 'Europe/Berlin')::date), '{}')
    into v_wochen from public.home_uebung h where h.student_id = p_kind;
  -- Serie: Wochen in Folge mit Übung bis zur laufenden Woche; eine laufende Woche ohne Übung bricht sie noch nicht.
  v_pruef := case when v_woche = any (v_wochen) then v_woche else v_woche - 7 end;
  while v_pruef = any (v_wochen) loop
    v_serie := v_serie + 1;
    v_pruef := v_pruef - 7;
  end loop;

  return query
  select coalesce(sp.xp_total, 0), coalesce(sp.level, 1), cardinality(v_wochen), v_serie,
         (select count(*)::integer from public.home_uebung h
           where h.student_id = p_kind and date_trunc('week', h.am at time zone 'Europe/Berlin')::date = v_woche),
         coalesce(sp.presence_streak_weeks, 0)
    from (select 1) eins
    left join public.student_progress sp on sp.student_id = p_kind;
end;
$$;
comment on function public.home_pfad(uuid) is
  'Pfad des Kindes (nur Verhalten): XP, Level, Wochen mit Übung, Serie in Wochen, Quests diese Woche, Präsenz-Wochen. reihe1 fertig';

-- ── Offen-Regeln ────────────────────────────────────────────────────────────
create function public.kompetenz_offen_roh(p_kind uuid)
returns table (skill_key text, zustand text, grund text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_klasse integer;
begin
  select s.class_level into v_klasse from public.students s where s.id = p_kind;

  return query
  with recursive
  leads_kind as (
    select l.id from public.leads l where l.converted_student_id = p_kind
    union select s.lead_id from public.students s where s.id = p_kind and s.lead_id is not null
  ),
  -- Regel 2: Schulthema „aktuell“ oder Thema einer angekündigten Klassenarbeit.
  aktuelle_themen as (
    select t.thema_key from public.lead_themen t where t.lead_id in (select id from leads_kind) and t.status = 'aktuell'
    union
    select unnest(k.thema_keys) from public.lead_klassenarbeiten k
     where k.lead_id in (select id from leads_kind) and k.status = 'bevorstehend'
       and (k.datum is null or k.datum >= (now() at time zone 'Europe/Berlin')::date)
  ),
  aktuell as (select distinct st.skill_key from public.skill_thema st where st.thema_key in (select thema_key from aktuelle_themen)),
  -- Regel 3: Voraussetzungen des aktuellen Stoffs, über mehrere Stufen.
  grundlage as (
    select k.voraussetzt_skill_key as skill_key from public.skill_kante k where k.skill_key in (select skill_key from aktuell)
    union
    select k.voraussetzt_skill_key from public.skill_kante k join grundlage g on g.skill_key = k.skill_key
  ),
  -- Befund vor Ort; vom Coach gemeistert gilt als sicher.
  befund as (
    select lp.skill_key, case when lp.stand_coach = 'gemeistert' then 'sicher' else lp.stand_system end as stand_system
      from public.lernpfad lp
     where lp.student_id = p_kind and (lp.stand_system in ('sicher', 'noch_nicht_sicher') or lp.stand_coach = 'gemeistert')
  ),
  voraus as (
    select s.skill_key,
           count(k.voraussetzt_skill_key) as n,
           count(k.voraussetzt_skill_key) filter (where b.stand_system = 'sicher') as sicher
      from public.skills s
      left join public.skill_kante k on k.skill_key = s.skill_key
      left join befund b on b.skill_key = k.voraussetzt_skill_key
     group by s.skill_key
  )
  select s.skill_key,
         case
           when b.stand_system = 'sicher' then 'sicher'
           when b.stand_system = 'noch_nicht_sicher' then 'noch_nicht_sicher'
           when g.grund is not null then 'nicht_angeschaut'
           else 'gesperrt'
         end,
         g.grund
    from public.skills s
    join voraus v on v.skill_key = s.skill_key
    left join befund b on b.skill_key = s.skill_key
    cross join lateral (select case
           when b.skill_key is not null then 'befund'                                         -- Regel 4
           when s.skill_key in (select skill_key from aktuell) then 'aktuell'                  -- Regel 2
           when s.skill_key in (select skill_key from grundlage) then 'grundlage'              -- Regel 3
           when v.n > 0 and v.sicher = v.n then 'voraussetzungen'                              -- Regel 1
           when v_klasse is not null and s.klasse_herkunft < v_klasse then 'frueher'           -- Regel 5
           when v.n = 0 then 'start'                                                           -- ohne Voraussetzung
           else (select o.grund from public.schueler_kompetenz_offen o                         -- Regel 6
                  where o.student_id = p_kind and o.skill_key = s.skill_key)
         end as grund) g
   order by s.skill_key;
end;
$$;
comment on function public.kompetenz_offen_roh(uuid) is 'Intern: Offen-Regeln ohne Rechteprüfung (Trigger, kompetenz_offen).';

create function public.kompetenz_offen(p_kind uuid)
returns table (skill_key text, zustand text, grund text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.home_darf_lesen(p_kind) then
    raise exception 'kompetenz_offen: kein Zugriff' using errcode = '42501';
  end if;
  return query select * from public.kompetenz_offen_roh(p_kind);
end;
$$;
comment on function public.kompetenz_offen(uuid) is
  'Offen-Regeln des Themenbaums (Anforderung Themenbaum §3): zustand sicher | noch_nicht_sicher | nicht_angeschaut | gesperrt; '
  'grund befund | aktuell | grundlage | voraussetzungen | frueher | start | null. Befunde nur aus lernpfad (LSA, Session); '
  'Übung zuhause ändert nichts. Kind, Coach, Admin. reihe1 fertig';

-- Regel 6 serverseitig: schreibt neu Offenes fest. Läuft aus Triggern auf lernpfad, lead_themen und
-- lead_klassenarbeiten — VOR einer Änderung (damit nichts, was offen war, verloren geht) und danach.
create function public.kompetenz_offen_merken_intern(p_kind uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_n integer;
begin
  if p_kind is null then
    return 0;
  end if;
  insert into public.schueler_kompetenz_offen (student_id, skill_key, grund)
  select p_kind, o.skill_key, o.grund from public.kompetenz_offen_roh(p_kind) o where o.grund is not null
  on conflict (student_id, skill_key) do nothing;
  get diagnostics v_n = row_count;
  return v_n;
end;
$$;
comment on function public.kompetenz_offen_merken_intern(uuid) is 'Intern: Regel 6 fortschreiben (Trigger).';

create function public.kompetenz_offen_merken(p_kind uuid)
returns integer
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.home_darf_lesen(p_kind) then
    raise exception 'kompetenz_offen_merken: kein Zugriff' using errcode = '42501';
  end if;
  return public.kompetenz_offen_merken_intern(p_kind);
end;
$$;
comment on function public.kompetenz_offen_merken(uuid) is
  'Schreibt neu Offenes fest (Regel 6), Rückgabe: Anzahl neuer Zeilen. Kind, Coach, Admin. Die Trigger tun das ohnehin. reihe1 fertig';

create function public.kompetenz_offen_trigger()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_zeile record := case when tg_op = 'DELETE' then old else new end;
  v_kind  uuid;
begin
  if tg_table_name = 'lernpfad' then
    v_kind := v_zeile.student_id;
  else
    select l.converted_student_id into v_kind from public.leads l where l.id = v_zeile.lead_id;
  end if;
  perform public.kompetenz_offen_merken_intern(v_kind);
  return v_zeile;
end;
$$;
comment on function public.kompetenz_offen_trigger() is 'Intern: Regel 6 vor und nach jeder Änderung an Befunden und aktuellem Stoff.';

create trigger lernpfad_kompetenz_offen_vorher before update or delete on public.lernpfad
  for each row execute function public.kompetenz_offen_trigger();
create trigger lernpfad_kompetenz_offen_nachher after insert or update on public.lernpfad
  for each row execute function public.kompetenz_offen_trigger();
create trigger lead_themen_kompetenz_offen_vorher before update or delete on public.lead_themen
  for each row execute function public.kompetenz_offen_trigger();
create trigger lead_themen_kompetenz_offen_nachher after insert or update on public.lead_themen
  for each row execute function public.kompetenz_offen_trigger();
create trigger lead_klassenarbeiten_kompetenz_offen_vorher before update or delete on public.lead_klassenarbeiten
  for each row execute function public.kompetenz_offen_trigger();
create trigger lead_klassenarbeiten_kompetenz_offen_nachher after insert or update on public.lead_klassenarbeiten
  for each row execute function public.kompetenz_offen_trigger();

-- ── Zeig's mir ──────────────────────────────────────────────────────────────
create function public.zeigs_mir_darf(p_kind uuid, p_session uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.session_students ss where ss.session_id = p_session and ss.student_id = p_kind)
     and (coalesce(public.get_my_role(), '') = 'admin'
          or exists (select 1 from public.coaching_sessions cs
                      where cs.id = p_session and cs.coach_id = auth.uid()
                        and coalesce(public.get_my_role(), '') = 'coach'));
$$;
comment on function public.zeigs_mir_darf(uuid, uuid) is 'Intern: Coach der Session oder Admin, Kind in der Session gebucht.';

create function public.zeigs_mir_offen(p_kind uuid, p_session uuid)
returns table (skill_key text, vorschlag_am timestamptz, entscheidung text, entschieden_von uuid)
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_beginn timestamptz;
begin
  if not public.zeigs_mir_darf(p_kind, p_session) then
    raise exception 'zeigs_mir_offen: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if not exists (select 1 from public.zeigs_mir z where z.student_id = p_kind and z.session_id = p_session)
     and exists (select 1 from public.coaching_sessions cs
                  where cs.id = p_session and cs.beendet_am is null and not coalesce(cs.testlauf, false)) then
    select coalesce(cs.gestartet_am, cs.scheduled_at, now()) into v_beginn
      from public.coaching_sessions cs where cs.id = p_session;
    -- Entscheidung 5: Skill mit mindestens zwei Quests seit der letzten Session, noch nicht sicher; der meistgeübte.
    insert into public.zeigs_mir (student_id, session_id, skill_key, quests)
    select p_kind, p_session, h.skill_key, count(*)::integer
      from public.home_uebung h
     where h.student_id = p_kind
       and h.am > coalesce(public.home_letzte_session(p_kind, v_beginn), '-infinity'::timestamptz)
       and h.am <= v_beginn
       and not exists (select 1 from public.lernpfad lp
                        where lp.student_id = p_kind and lp.skill_key = h.skill_key and lp.stand_system = 'sicher')
     group by h.skill_key
    having count(*) >= 2
     order by count(*) desc, max(h.am) desc
     limit 1
    on conflict (student_id, session_id) do nothing;
  end if;
  return query
    select z.skill_key, z.vorschlag_am, z.entscheidung, z.entschieden_von
      from public.zeigs_mir z where z.student_id = p_kind and z.session_id = p_session;
end;
$$;
comment on function public.zeigs_mir_offen(uuid, uuid) is
  'Coach der Session, Admin: der eine Vorschlag „Zeig''s mir“ (legt ihn beim ersten Abruf an). Leer, wenn keiner passt. reihe1 fertig';

create function public.zeigs_mir_entscheiden(p_kind uuid, p_session uuid, p_skill text, p_entscheidung text)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  if not public.zeigs_mir_darf(p_kind, p_session) then
    raise exception 'zeigs_mir_entscheiden: nur Coach der Session oder Admin' using errcode = '42501';
  end if;
  if exists (select 1 from public.coaching_sessions cs where cs.id = p_session and cs.beendet_am is not null) then
    raise exception 'zeigs_mir_entscheiden: Session ist beendet' using errcode = '55000';
  end if;
  if p_entscheidung is null or p_entscheidung not in ('uebernehmen', 'nicht_heute') then
    raise exception 'zeigs_mir_entscheiden: uebernehmen oder nicht_heute' using errcode = '22023';
  end if;
  update public.zeigs_mir z
     set entscheidung = p_entscheidung, entschieden_von = auth.uid(), entschieden_am = now()
   where z.student_id = p_kind and z.session_id = p_session and z.skill_key = p_skill;
  if not found then
    raise exception 'zeigs_mir_entscheiden: kein Vorschlag für diesen Skill' using errcode = '55000';
  end if;
end;
$$;
comment on function public.zeigs_mir_entscheiden(uuid, uuid, text, text) is
  'Coach der Session, Admin: übernimmt den Vorschlag oder „nicht heute“ (änderbar bis Session-Ende). reihe1 fertig';

-- Für C (session_naechster_schritt, Tablet-Kontext): nur lesen, legt nichts an, keine Rechteprüfung, kein Grant.
create function public.zeigs_mir_uebernommen(p_kind uuid, p_session uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select z.skill_key from public.zeigs_mir z
   where z.student_id = p_kind and z.session_id = p_session and z.entscheidung = 'uebernehmen';
$$;
comment on function public.zeigs_mir_uebernommen(uuid, uuid) is
  'Intern für C (aus plpgsql): Skill, den der Coach für „Zeig''s mir“ übernommen hat, sonst null. Ohne Grant. reihe1 fertig';

-- ── Fragen an den Coach ─────────────────────────────────────────────────────
create function public.eddie_frage_merken(p_text text)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind uuid := public.get_my_student_id();
  v_id   uuid;
begin
  if v_kind is null then
    raise exception 'eddie_frage_merken: nur das Kind selbst' using errcode = '42501';
  end if;
  if p_text is null or char_length(btrim(p_text)) not between 1 and 280 then
    raise exception 'eddie_frage_merken: 1–280 Zeichen' using errcode = '22023';
  end if;
  if (select count(*) from public.coach_fragen f where f.student_id = v_kind and f.erledigt_am is null) >= 10 then
    raise exception 'eddie_frage_merken: schon zehn offene Fragen' using errcode = '54000';
  end if;
  insert into public.coach_fragen (student_id, text) values (v_kind, btrim(p_text)) returning id into v_id;
  return v_id;
end;
$$;
comment on function public.eddie_frage_merken(text) is 'Das Kind: merkt eine Frage für den Coach (höchstens zehn offene). reihe1 fertig';

create function public.coach_fragen_offen(p_kind uuid)
returns table (id uuid, text text, am timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not (coalesce(public.get_my_role(), '') = 'admin'
          or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(p_kind))) then
    raise exception 'coach_fragen_offen: nur Coach oder Admin' using errcode = '42501';
  end if;
  return query select f.id, f.text, f.am from public.coach_fragen f
                where f.student_id = p_kind and f.erledigt_am is null order by f.am;
end;
$$;
comment on function public.coach_fragen_offen(uuid) is 'Coach mit aktiver Akte, Admin: offene Fragen des Kindes. reihe1 fertig';

create function public.coach_frage_erledigt(p_frage uuid)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_kind uuid;
begin
  select f.student_id into v_kind from public.coach_fragen f where f.id = p_frage and f.erledigt_am is null;
  if v_kind is null or not (coalesce(public.get_my_role(), '') = 'admin'
                            or (coalesce(public.get_my_role(), '') = 'coach' and public.akte_aktiv(v_kind))) then
    raise exception 'coach_frage_erledigt: kein Zugriff' using errcode = '42501';
  end if;
  update public.coach_fragen set erledigt_am = now(), erledigt_von = auth.uid() where id = p_frage;
end;
$$;
comment on function public.coach_frage_erledigt(uuid) is 'Coach mit aktiver Akte, Admin: Frage besprochen. reihe1 fertig';

-- ── Rechte ──────────────────────────────────────────────────────────────────
revoke all on function public.home_darf_lesen(uuid), public.home_letzte_session(uuid, timestamptz),
  public.home_uebung_melden(text, integer, integer), public.home_uebung_kurz(uuid, timestamptz), public.home_pfad(uuid),
  public.kompetenz_offen(uuid), public.kompetenz_offen_merken(uuid), public.zeigs_mir_darf(uuid, uuid),
  public.zeigs_mir_offen(uuid, uuid), public.zeigs_mir_entscheiden(uuid, uuid, text, text), public.eddie_frage_merken(text),
  public.coach_fragen_offen(uuid), public.coach_frage_erledigt(uuid) from public, anon;
revoke all on function public.home_darf_lesen(uuid), public.zeigs_mir_darf(uuid, uuid),
  public.home_letzte_session(uuid, timestamptz) from authenticated;
revoke all on function public.kompetenz_offen_roh(uuid), public.kompetenz_offen_merken_intern(uuid),
  public.kompetenz_offen_trigger(), public.zeigs_mir_uebernommen(uuid, uuid), public.home_uebung_append_only()
  from public, anon, authenticated;
grant execute on function public.home_uebung_melden(text, integer, integer),
  public.home_uebung_kurz(uuid, timestamptz), public.home_pfad(uuid), public.kompetenz_offen(uuid),
  public.kompetenz_offen_merken(uuid), public.zeigs_mir_offen(uuid, uuid), public.zeigs_mir_entscheiden(uuid, uuid, text, text),
  public.eddie_frage_merken(text), public.coach_fragen_offen(uuid), public.coach_frage_erledigt(uuid) to authenticated;
