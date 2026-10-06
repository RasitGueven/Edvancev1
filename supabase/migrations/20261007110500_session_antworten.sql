-- R1.3 Antworten und Hinweise in der Session.
--
-- session_ausgegeben: welche Aufgabe wann welchem Kind gegeben wurde (Muster
--   lsa_ausgegeben). Bis A1/P2 die Auswahl liefert, gibt aufgabe_ausgeben sie
--   aus (Coach, Admin oder Systemaufruf); nur Aufgaben mit Status ready
--   (Entscheidung 5). Sie ist zugleich das Tor fuer antwort_abgeben.
-- session_antworten: jeder Versuch, nur anhaengen. Bewertung auf dem Server mit
--   derselben Engine wie die LSA (lsa_grade/lsa_is_correct, lsa_part_answer,
--   lsa_fehlbild_match ueber acceptance.known_errors) im Muster von
--   pruef_wertung_testen (20261005071648_pruefung_funktionen_d.sql:298-322).
--   Das Kind steht ueber das Tablet fest (student_id); das angemeldete Konto
--   (angemeldet_als) und das Geraet stehen getrennt daneben (R0 Frage 3).

create table public.session_ausgegeben (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null,
  student_id  uuid not null,
  task_id     uuid not null references public.tasks(id),
  phase       text check (phase in ('checkin', 'warmup', 'kern', 'checkout')),
  eingemischt boolean not null default false,
  zeit        timestamptz not null default clock_timestamp(),
  von         uuid references public.profiles(id) on delete set null,
  foreign key (session_id, student_id)
    references public.session_students(session_id, student_id) on delete cascade
);
create index session_ausgegeben_kind_idx on public.session_ausgegeben (session_id, student_id, zeit desc);

create table public.session_antworten (
  id               uuid primary key default gen_random_uuid(),
  session_id       uuid not null,
  student_id       uuid not null,
  task_id          uuid not null references public.tasks(id),
  teil             int,
  versuch_nr       int not null check (versuch_nr >= 1),
  eingabe          jsonb not null,
  ergebnis         text not null check (ergebnis in ('richtig', 'teilweise', 'falsch')),
  fehlbild_slug    text,
  hinweisstufe_max int not null default 0 check (hinweisstufe_max between 0 and 3),
  dauer_ms         int check (dauer_ms >= 0),
  phase            text check (phase in ('checkin', 'warmup', 'kern', 'checkout')),
  eingemischt      boolean not null default false,
  zeit             timestamptz not null default clock_timestamp(),
  geraet_id        uuid references public.platz_devices(profile_id) on delete set null,
  angemeldet_als   uuid references public.profiles(id) on delete set null,
  foreign key (session_id, student_id)
    references public.session_students(session_id, student_id) on delete cascade,
  unique nulls not distinct (session_id, student_id, task_id, teil, versuch_nr)
);
create index session_antworten_kind_idx on public.session_antworten (session_id, student_id, zeit);

comment on table public.session_antworten is
  'R1: Antworten in der Session (append-only). student_id = wer sass (ueber das Tablet), angemeldet_als = Konto, geraet_id = Geraet.';

create trigger session_antworten_nur_anhaengen
  before update or delete on public.session_antworten
  for each row execute function public.session_nur_anhaengen();
create trigger session_ausgegeben_nur_anhaengen
  before update or delete on public.session_ausgegeben
  for each row execute function public.session_nur_anhaengen();

alter table public.session_ausgegeben enable row level security;
alter table public.session_antworten enable row level security;
revoke all on public.session_ausgegeben, public.session_antworten from public, anon, authenticated;

-- Aktuelle Aufgabe eines Kindes: die zuletzt ausgegebene.
create function public.session_aktuelle_ausgabe(p_session_id uuid, p_student_id uuid)
returns public.session_ausgegeben
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select * from public.session_ausgegeben
   where session_id = p_session_id and student_id = p_student_id
   order by zeit desc limit 1
$$;

-- Bewertung eines Teils (oder der ganzen Aufgabe) wie die LSA. Liefert nie die Loesung.
create function public.session_bewerten(p_task_id uuid, p_teil int, p_eingabe jsonb,
                                        out ergebnis text, out fehlbild_slug text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t      public.tasks;
  v_ca   jsonb;
  v_acc  jsonb;
  v_p    jsonb;
  v_kind text;
  v_resp jsonb;
  v_ok   boolean;
  v_st   text;
begin
  select * into t from public.tasks where id = p_task_id;
  select s.correct_answers, s.acceptance into v_ca, v_acc from public.task_solutions s where s.task_id = p_task_id;
  if t.input_type = 'MULTI_PART' then
    select x into v_p from jsonb_array_elements(t.parts) x where (x ->> 'nr')::int = p_teil;
    if v_p is null then
      raise exception 'antwort_abgeben: Teil % gibt es nicht', p_teil using errcode = '22023';
    end if;
    v_kind := v_p ->> 'kind';
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(case when v_kind = 'mc' then 'MC' else 'SHORT_TEXT' end,
              case when jsonb_typeof(v_ca -> (v_p ->> 'nr')) = 'array' then v_ca -> (v_p ->> 'nr') else '[]' end,
              v_resp), false);
    v_st := case when v_ok then 'voll' else 'nicht' end;
    v_acc := coalesce(v_acc -> (v_p ->> 'nr') -> 'known_errors', v_acc -> 'known_errors');
  else
    v_kind := lower(t.input_type);
    v_resp := public.lsa_part_answer(v_kind, p_eingabe);
    v_ok := coalesce(public.lsa_is_correct(t.input_type, v_ca, v_resp), false);
    v_st := case when t.input_type in ('MC', 'TERM') then case when v_ok then 'voll' else 'nicht' end
                 else public.lsa_grade(t.input_type, v_acc, v_ca, v_resp) end;
    v_acc := v_acc -> 'known_errors';
  end if;
  ergebnis := case v_st when 'voll' then 'richtig' when 'teilweise' then 'teilweise' else 'falsch' end;
  if ergebnis <> 'richtig' then
    fehlbild_slug := public.lsa_fehlbild_match(v_kind, v_acc, v_resp);
  end if;
end;
$$;

create function public.aufgabe_ausgeben(p_session_id uuid, p_student_id uuid, p_task_id uuid,
                                        p_eingemischt boolean default false)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_id uuid;
begin
  if not public.ist_systemaufruf() then
    perform public.session_coach_pruefen(p_session_id, 'aufgabe_ausgeben');
  end if;
  if not exists (select 1 from public.session_tablets where session_id = p_session_id
                  and student_id = p_student_id and geloest_am is null) then
    raise exception 'aufgabe_ausgeben: Kind hat kein Tablet' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.tasks where id = p_task_id and status = 'ready') then
    raise exception 'aufgabe_ausgeben: nur freigegebene Aufgaben (ready)' using errcode = 'P0001',
      hint = 'nicht_ready';
  end if;
  insert into public.session_ausgegeben (session_id, student_id, task_id, phase, eingemischt, von)
  values (p_session_id, p_student_id, p_task_id, public.session_phase(p_session_id, p_student_id),
          coalesce(p_eingemischt, false), auth.uid())
  returning id into v_id;
  return v_id;
end;
$$;

-- Vom Tablet. Gibt nur Ergebnis, Fehlbild-Klartext (nur abgenommene, AF3) und
-- Versuchsnummer zurueck, nie Loesung, correct_answers oder acceptance.
create function public.antwort_abgeben(p_session_id uuid, p_task_id uuid, p_teil int, p_eingabe jsonb,
                                       p_dauer_ms int default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t     public.session_tablets := public.session_tablet_platz(p_session_id, 'antwort_abgeben');
  a     public.session_ausgegeben;
  b     record;
  v_nr  int;
  v_hin int;
begin
  select * into a from public.session_ausgegeben
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
   order by zeit desc limit 1;
  if not found then
    raise exception 'antwort_abgeben: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  if p_eingabe is null or jsonb_typeof(p_eingabe) = 'null' or btrim(p_eingabe #>> '{}') = '' then
    raise exception 'antwort_abgeben: leere Eingabe' using errcode = '22023';
  end if;
  if exists (select 1 from public.session_antworten where session_id = p_session_id and student_id = t.student_id
              and task_id = p_task_id and teil is not distinct from p_teil and ergebnis = 'richtig') then
    raise exception 'antwort_abgeben: schon richtig geloest' using errcode = 'P0001';
  end if;

  select * into b from public.session_bewerten(p_task_id, p_teil, p_eingabe);

  select count(*) + 1 into v_nr from public.session_antworten
   where session_id = p_session_id and student_id = t.student_id and task_id = p_task_id
     and teil is not distinct from p_teil;
  select coalesce(max((e.payload ->> 'stufe')::int), 0) into v_hin from public.session_ereignisse e
   where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
     and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'geliefert')::boolean;

  insert into public.session_antworten (session_id, student_id, task_id, teil, versuch_nr, eingabe, ergebnis,
         fehlbild_slug, hinweisstufe_max, dauer_ms, phase, eingemischt, geraet_id, angemeldet_als)
  values (p_session_id, t.student_id, p_task_id, p_teil, v_nr, p_eingabe, b.ergebnis, b.fehlbild_slug, v_hin,
          p_dauer_ms, public.session_phase(p_session_id, t.student_id), a.eingemischt, t.geraet_id, auth.uid());

  return jsonb_build_object(
    'ergebnis', b.ergebnis,
    'versuch_nr', v_nr,
    'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl
                           where fl.slug = b.fehlbild_slug and fl.freigegeben_am is not null));
end;
$$;

-- Vom Tablet. Nur gepruefte Hinweise (Entscheidung 20): ein Hinweis-Objekt in
-- task_solutions.hints zaehlt nur mit status = 'geprueft'; ohne Status gilt er
-- bis E1 als nicht geprueft. Jede Anfrage wird protokolliert.
create function public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe int)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'hinweis_abrufen');
  v_text text;
begin
  if not exists (select 1 from public.session_ausgegeben where session_id = p_session_id
                  and student_id = t.student_id and task_id = p_task_id) then
    raise exception 'hinweis_abrufen: Aufgabe wurde diesem Kind nicht gegeben' using errcode = 'P0001';
  end if;
  if p_stufe is null or p_stufe < 1 or p_stufe > public.session_wert_zahl(p_session_id, 'hinweisstufen') then
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and (h ->> 'level')::int = p_stufe and h ->> 'status' = 'geprueft'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null);
end;
$$;

-- Kiosk-Abfrage fuer das Tablet: welcher Platz, welche Phase, welche Aufgabe
-- (lsa_question_payload, ohne Loesung). Ohne Zuweisung: zugewiesen = false.
create function public.tablet_stand()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  t public.session_tablets;
  a public.session_ausgegeben;
begin
  select st.* into t from public.session_tablets st
    join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
   where st.geraet_id = auth.uid() and st.geloest_am is null;
  if not found then
    return jsonb_build_object('zugewiesen', false);
  end if;
  a := public.session_aktuelle_ausgabe(t.session_id, t.student_id);
  return jsonb_build_object(
    'zugewiesen', true,
    'session_id', t.session_id,
    'tablet_nr', t.tablet_nr,
    'vorname', (select coalesce(l.first_name, split_part(l.full_name, ' ', 1)) from public.leads l
                 where l.id = public.session_lead_von_kind(t.student_id)),
    'phase', public.session_phase(t.session_id, t.student_id),
    'checkin_fertig', exists (select 1 from public.session_checkin c where c.session_id = t.session_id
                               and c.student_id = t.student_id and c.kind_am is not null),
    'aufgabe', case when a.id is null then null else public.lsa_question_payload(a.task_id) end);
end;
$$;

revoke all on function
  public.session_aktuelle_ausgabe(uuid, uuid), public.session_bewerten(uuid, int, jsonb),
  public.aufgabe_ausgeben(uuid, uuid, uuid, boolean), public.antwort_abgeben(uuid, uuid, int, jsonb, int),
  public.hinweis_abrufen(uuid, uuid, int), public.tablet_stand()
  from public, anon, authenticated;
grant execute on function
  public.aufgabe_ausgeben(uuid, uuid, uuid, boolean), public.antwort_abgeben(uuid, uuid, int, jsonb, int),
  public.hinweis_abrufen(uuid, uuid, int), public.tablet_stand()
  to authenticated;
