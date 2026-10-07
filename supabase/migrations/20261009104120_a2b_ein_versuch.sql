-- A2b: ein Versuch je Aufgabe und Hinweise nur vor dem Abgeben, auf dem Server erzwungen (Rasit 07.10.,
-- Entscheidungen 29 und 32; offene-punkte-a2b 1 und 2). Grundlage: die Fassungen aus 20261009103015_a2b_regeln.
--   antwort_abgeben  lehnt jede zweite Antwort zu derselben Ausgabe und demselben Teil mit P0001 ab
--                    (Hinweis schon_beantwortet), auch wenn die erste falsch war. Die Pruefung steht vor der
--                    Bewertung: es wird nichts gespeichert, kein Beleg, kein Ereignis.
--   hinweis_abrufen  lehnt mit P0001 ab (Hinweis hinweis_nach_antwort), sobald zu dieser Ausgabe eine Antwort
--                    vorliegt. Hinweise haengen je Aufgabe (task_solutions.hints, kein Teil), deshalb zaehlt
--                    bei MULTI_PART die erste Antwort auf irgendeinen Teil.
-- "Dieselbe Ausgabe" = die juengste Zeile in session_ausgegeben fuer Kind und Aufgabe; gezaehlt werden
-- Antworten seit ihrem Zeitpunkt.

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
  -- A2b (Entscheidung 29): ein Versuch je Ausgabe und Teil, unabhaengig vom Ergebnis.
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id and r.student_id = t.student_id
              and r.task_id = p_task_id and r.teil is not distinct from p_teil and r.zeit >= a.zeit) then
    raise exception 'antwort_abgeben: zu dieser Aufgabe liegt schon eine Antwort vor' using errcode = 'P0001',
      hint = 'schon_beantwortet';
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
  -- A2b (Entscheidung 32): nur vor dem Abgeben; Hinweise haengen an der Aufgabe, also zaehlt jede Antwort
  -- auf irgendeinen Teil seit der juengsten Ausgabe.
  if exists (select 1 from public.session_antworten r where r.session_id = p_session_id and r.student_id = t.student_id
              and r.task_id = p_task_id
              and r.zeit >= (select max(x.zeit) from public.session_ausgegeben x where x.session_id = p_session_id
                              and x.student_id = t.student_id and x.task_id = p_task_id)) then
    raise exception 'hinweis_abrufen: zu dieser Aufgabe liegt schon eine Antwort vor' using errcode = 'P0001',
      hint = 'hinweis_nach_antwort';
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
