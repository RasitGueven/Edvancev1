-- A2b.4 Regeln am Tablet (Entscheidungen 29 und 32). Grundlage: Prod-Definitionen (07.10., identisch mit A2).
--   antwort_abgeben        Exit-Aufgaben bekommen nur eine neutrale Rueckmeldung (gespeichert, versuch_nr),
--                          kein Ergebnis und kein Fehlbild. Gespeichert und ausgewertet wird wie bisher.
--   hinweis_abrufen        Hinweise nur in der Kernarbeit: keine zu Aufgaben, die die Engine im Warm-up oder
--                          als Exit gab (Entscheidung 32).
--   session_schritt_oeffentlich  hinweise_erlaubt nur bei art = aufgabe in der Kernarbeit.

create or replace function public.antwort_abgeben(p_session_id uuid, p_task_id uuid, p_teil int, p_eingabe jsonb,
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
  v_skill text;
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

  -- A2 (L): jede Antwort aus Warm-up, Kernarbeit und Check-out bucht einen Lernpfad-Beleg mit
  -- Ergebnis und Hinweis-Nutzung. Testlaeufe buchen nie Belege (Entscheidung 27).
  select tk.skill_key into v_skill from public.tasks tk where tk.id = p_task_id;
  if v_skill is not null
     and not coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false)
     and public.session_phase(p_session_id, t.student_id) in ('warmup', 'kern', 'checkout') then
    perform public.lernpfad_beleg_core(t.student_id, v_skill, p_session_id, b.ergebnis, v_hin > 0);
  end if;

  -- A2b (Entscheidung 29): Exit-Aufgaben nur neutral.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'exit') then
    return jsonb_build_object('gespeichert', true, 'versuch_nr', v_nr);
  end if;

  return jsonb_build_object(
    'gespeichert', true,
    'ergebnis', b.ergebnis,
    'versuch_nr', v_nr,
    'fehlbild_klartext', (select fl.klartext from public.fehlbild_labels fl
                           where fl.slug = b.fehlbild_slug and fl.freigegeben_am is not null));
end;
$$;

create or replace function public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe int)
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
  -- A2 (K): Exit-Aufgaben im Check-out ohne Hinweise.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.art = 'exit') then
    raise exception 'hinweis_abrufen: Exit-Aufgaben ohne Hinweise' using errcode = '22023', hint = 'exit_ohne_hinweis';
  end if;
  -- A2b (Entscheidung 32): keine Hinweise im Warm-up.
  if exists (select 1 from public.session_schritte x where x.session_id = p_session_id
              and x.student_id = t.student_id and x.task_id = p_task_id and x.phase = 'warmup') then
    raise exception 'hinweis_abrufen: im Warm-up keine Hinweise' using errcode = '22023', hint = 'warmup_ohne_hinweis';
  end if;
  if p_stufe is null or p_stufe < 1 or p_stufe > public.session_wert_zahl(p_session_id, 'hinweisstufen') then
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023';
  end if;
  -- Prinzip der minimalen Hilfe (Entscheidung 11): Stufe n erst nach Stufe n-1.
  if p_stufe > 1 and not exists (select 1 from public.session_ereignisse e
       where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
         and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'stufe')::int = p_stufe - 1) then
    raise exception 'hinweis_abrufen: erst Stufe %', p_stufe - 1 using errcode = '22023', hint = 'hinweis_reihenfolge';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and h ->> 'level' = p_stufe::text and h ->> 'status' = 'geprueft'
   order by h ->> 'text'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null);
end;
$$;

create or replace function public.session_schritt_oeffentlich(p_schritt jsonb, p_coach boolean default false)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
           'art', p_schritt ->> 'art', 'phase', p_schritt ->> 'phase', 'skill_key', p_schritt ->> 'skill_key',
           'skill_label', case when p_schritt ->> 'skill_key' is not null
                               then public.session_label(p_schritt ->> 'skill_key') end,
           'task_id', p_schritt ->> 'task_id', 'modus', p_schritt ->> 'modus',
           'eingemischt', coalesce((p_schritt ->> 'eingemischt')::boolean, false),
           'grund_code', p_schritt ->> 'grund_code',
           'hinweise_erlaubt', p_schritt ->> 'art' = 'aufgabe' and p_schritt ->> 'phase' = 'kern',
           'aufgabe', case when p_schritt ->> 'art' in ('aufgabe', 'exit', 'beispiel')
                           then public.lsa_question_payload((p_schritt ->> 'task_id')::uuid) end)
         || case when p_schritt ->> 'art' = 'beispiel' then jsonb_build_object('loesungsweg',
              (select ts.solution from public.task_solutions ts where ts.task_id = (p_schritt ->> 'task_id')::uuid))
            else '{}'::jsonb end
         -- Grund und Stufe sind Coach-Wissen (Quoten, Fehlversuche, Exit-Ergebnis): nie ans Tablet
         -- (CLAUDE.md §6, Consensus-Check Befund 1).
         || case when p_coach then jsonb_build_object('grund', p_schritt ->> 'grund',
                                                      'schwierigkeit', (p_schritt ->> 'schwierigkeit')::int)
            else '{}'::jsonb end
         || case when p_schritt ? 'erklaerung_weg' then jsonb_build_object('erklaerung_weg', p_schritt ->> 'erklaerung_weg')
            else '{}'::jsonb end
$$;
