-- T3.2 Testlauf-Session: Hinweise, Fehlbild-Satz und Nachlesen wie freigegeben (Paket T3, Entscheidung Rasit 08.10.).
--
-- Bestand (docs/session/offene-punkte-t3.md, Tabelle): Drei Lesestellen des Tablets filtern im Testlauf noch nach
-- Freigabe, obwohl die Auswahl (session_im_pool, erklaer_status_ok) ungepruefte Inhalte schon ausgibt.
--   hinweis_abrufen   nur Hinweise mit status 'geprueft'      -> im Testlauf jeder Hinweis mit Text
--   antwort_abgeben   Fehlbild-Satz nur mit freigegeben_am   -> im Testlauf jeder Klartext
--   erklaer_nachlesen nur Kernideen mit status 'freigegeben' -> im Testlauf auch Entwurf/geprueft (wie erklaer_start)
-- Jeweils nur, wenn die Aufgabe die Pruefung des Lena-Boards besteht (testlauf_inhalt_sichtbar, T3.1). Ob die
-- Session ein Testlauf ist, kommt aus coaching_sessions.testlauf, nie vom Client. Ausserhalb eines Testlaufs liefert
-- jede Funktion dasselbe wie vorher.
--
-- Rumpf je Funktion zeilengleich mit der Prod-Definition nach SL1 (pg_get_functiondef per dbread, 12.10.2026);
-- Signatur, SECURITY, search_path und Grants unveraendert (create or replace behaelt die Grants).

CREATE OR REPLACE FUNCTION public.hinweis_abrufen(p_session_id uuid, p_task_id uuid, p_stufe integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'hinweis_abrufen');
  v_text text;
  -- T3: Testlauf nur aus der Session, nach der Platz-Pruefung oben.
  v_tl   boolean := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);
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
    raise exception 'hinweis_abrufen: Stufe % ist nicht freigeschaltet', p_stufe using errcode = '22023',
      hint = 'stufe_gesperrt';
  end if;
  -- Prinzip der minimalen Hilfe (Entscheidung 11): Stufe n erst nach Stufe n-1.
  if p_stufe > 1 and not exists (select 1 from public.session_ereignisse e
       where e.session_id = p_session_id and e.student_id = t.student_id and e.typ = 'hinweis'
         and e.payload ->> 'task_id' = p_task_id::text and (e.payload ->> 'stufe')::int = p_stufe - 1) then
    raise exception 'hinweis_abrufen: erst Stufe %', p_stufe - 1 using errcode = '22023', hint = 'hinweis_reihenfolge';
  end if;

  select h ->> 'text' into v_text
    from public.task_solutions s, jsonb_array_elements(s.hints) as e(h)
   where s.task_id = p_task_id and h ->> 'level' = p_stufe::text
     and (h ->> 'status' = 'geprueft'
          -- T3: im Testlauf jeder Hinweis mit Text, wenn die Aufgabe die Pruefung des Lena-Boards besteht.
          or (v_tl and nullif(btrim(h ->> 'text'), '') is not null and public.testlauf_inhalt_sichtbar(p_task_id)))
   order by coalesce(h ->> 'status' = 'geprueft', false) desc, h ->> 'text'
   limit 1;

  perform public.session_ereignis(p_session_id, t.student_id, 'hinweis',
    jsonb_build_object('task_id', p_task_id, 'stufe', p_stufe, 'geliefert', v_text is not null));
  -- A2c: weitere = es gibt eine naechste Stufe (hinweisstufen sieht das Tablet sonst nicht).
  return jsonb_build_object('stufe', p_stufe, 'text', v_text, 'verfuegbar', v_text is not null,
                            'weitere', p_stufe < public.session_wert_zahl(p_session_id, 'hinweisstufen'));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.antwort_abgeben(p_session_id uuid, p_task_id uuid, p_teil integer, p_eingabe jsonb, p_dauer_ms integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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
                           where fl.slug = b.fehlbild_slug
                             and (fl.freigegeben_am is not null
                                  -- T3: im Testlauf jeder Klartext, wenn die Aufgabe die Pruefung besteht.
                                  or (coalesce((select cs.testlauf from public.coaching_sessions cs
                                                 where cs.id = p_session_id), false)
                                      and nullif(btrim(fl.klartext), '') is not null
                                      and public.testlauf_inhalt_sichtbar(p_task_id)))));
end;
$function$
;

CREATE OR REPLACE FUNCTION public.erklaer_nachlesen(p_student_id uuid, p_skill_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_tl boolean;
begin
  -- A2c: ohne Kind das Kind des aufrufenden Tablets in seiner laufenden Session (wie tablet_stand).
  if p_student_id is null then
    select st.student_id into p_student_id
      from public.session_tablets st
      join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
     where st.geraet_id = auth.uid() and st.geloest_am is null;
    if p_student_id is null then
      raise exception 'erklaer_nachlesen: kein zugewiesener Platz an diesem Tablet' using errcode = '42501';
    end if;
  end if;
  -- A2: NULL-sicher (Befund X0b); zusaetzlich das Tablet des Kindes in einer laufenden Session.
  if not coalesce(coalesce(public.get_my_role(), '') = 'admin'
          or public.get_my_student_id() = p_student_id
          or exists (select 1 from public.session_students ss
                       join public.coaching_sessions cs on cs.id = ss.session_id
                      where ss.student_id = p_student_id and cs.coach_id = auth.uid())
          or exists (select 1 from public.session_tablets st
                       join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                      where st.student_id = p_student_id and st.geraet_id = auth.uid() and st.geloest_am is null),
          false) then
    raise exception 'erklaer_nachlesen: kein Zugriff' using errcode = '42501';
  end if;
  -- T3: Am Tablet des Kindes in seiner laufenden Testlauf-Session auch Kernideen im Entwurf (wie erklaer_start).
  -- Schuelerkonto, Coach und Admin sehen weiter nur Freigegebenes.
  v_tl := exists (select 1 from public.session_tablets st
                    join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                   where st.student_id = p_student_id and st.geraet_id = auth.uid() and st.geloest_am is null
                     and cs.testlauf);

  return jsonb_build_object(
    'skill_key', p_skill_key,
    'kernideen', (select coalesce(jsonb_agg(jsonb_build_object(
                           'nr', k.nr, 'titel', k.titel,
                           'schritte', public.erklaer_schritte_json(k.id, 'A', v_tl)) order by k.nr), '[]')
                    from public.erklaer_kernidee k
                   where k.skill_key = p_skill_key and public.erklaer_status_ok(k.status, v_tl)
                     and 'A' = any (public.erklaer_varianten(k.id, v_tl))));
end;
$function$
;

