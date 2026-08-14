-- PRUEFUNG zu AF7 (Skill-Urteil fuer MULTI_PART).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/urteil_multipart.PRUEFUNG.sql
--
-- Geprueft wird ueber den ECHTEN Pfad: lsa_submit im adaptiven Modus, das
-- lsa_urteil_buchen_core selbst aufruft — nicht die Funktion isoliert. Der
-- Defekt sass darin, dass die Funktion die Antwortzeilen NICHT FAND; ein
-- direkter Aufruf mit handgelegten Zeilen haette daran vorbeilaufen koennen.
--
-- Jede Probe braucht eine eigene Sitzung UND einen eigenen Schueler:
--   * lsa_skill_urteil ist je (session_id, skill_key) eindeutig, und ein
--     FINALES Urteil wird nie ueberschrieben — zwei Proben in derselben Sitzung
--     wuerden sich gegenseitig verdecken.
--   * lsa_sessions_active_unique laesst je (student_id, subject) nur eine
--     aktive Sitzung zu.
--
-- Alles in begin/rollback: lsa_responses ist append-only, hier bleibt nichts.

begin;

do $$
declare
  v_coach uuid := gen_random_uuid();
  v_multi uuid := gen_random_uuid();
  v_flach uuid := gen_random_uuid();
  v_st    uuid;
  v_se    uuid;
  v_zust  text;
  v_n     integer;
  v_ctrl  boolean;
begin
  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  insert into auth.users (id, email) values (v_coach, 'af7-coach@edvance.test');
  insert into public.profiles (id, email, role)
    values (v_coach, 'af7-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  -- Eigener Skill je Item, damit sich die Urteile nicht ueberlagern.
  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('AF7_MULTI', 'AF7 Multi', 'mathematik', 8, 1),
         ('AF7_FLACH', 'AF7 Flach', 'mathematik', 8, 1);

  -- MULTI_PART wie die P5-Items: Teil 1 mc, Teil 2 short_input.
  insert into public.tasks (id, content_type, skill_key, question, input_type,
                            status, est_duration_sec, parts)
  values (v_multi, 'exercise', 'AF7_MULTI', 'AF7 Multi-Part', 'MULTI_PART', 'ready', 180,
    '[{"nr":1,"kind":"mc","prompt":"Welche?","afb":"II",
       "options":[{"id":"a","label":"A"},{"id":"b","label":"B"}]},
      {"nr":2,"kind":"short_input","prompt":"Wie viele?","afb":"II"}]'::jsonb);
  insert into public.task_solutions (task_id, correct_answers)
  values (v_multi, '{"1":["a"],"2":["7"]}'::jsonb);

  -- Flaches NUMERIC-Item als Kontrollgruppe.
  insert into public.tasks (id, content_type, skill_key, question, input_type, status)
  values (v_flach, 'exercise', 'AF7_FLACH', 'AF7 flach', 'NUMERIC', 'ready');
  insert into public.task_solutions (task_id, correct_answers)
  values (v_flach, '["7"]'::jsonb);

  -- ══ Fall 1: beide Teile richtig -> traegt ═════════════════════════════════
  --
  -- Kein 'teilweise' und keine zweite Probe: ein Teil ist freie Eingabe, das
  -- Gesamtergebnis ist also nicht ratbar (siehe v_is_mc-Begruendung in AF7).

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_multi);
  perform public.lsa_submit(v_se, v_multi, '{"1":"a","2":"7"}'::jsonb, 30000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_zust is distinct from 'traegt' then
    raise exception 'F1: beide richtig ergab %, erwartet traegt', coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F1 ok: beide Teile richtig -> traegt';

  -- ══ Fall 2: Teil a falsch, Teil b richtig -> traegt_nicht ═════════════════
  --
  -- Der diagnostisch wichtigste Fall: das Kind rechnet richtig, modelliert aber
  -- falsch. Die Verdichtungsregel sagt, dass die Kompetenz damit nicht traegt.

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_multi);
  perform public.lsa_submit(v_se, v_multi, '{"1":"b","2":"7"}'::jsonb, 30000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_zust is distinct from 'traegt_nicht' then
    raise exception 'F2: Teil a falsch ergab %, erwartet traegt_nicht',
      coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F2 ok: Teil a falsch, Teil b richtig -> traegt_nicht';

  -- ══ Fall 3: Teil a richtig, Teil b falsch -> traegt_nicht ═════════════════

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_multi);
  perform public.lsa_submit(v_se, v_multi, '{"1":"a","2":"9"}'::jsonb, 30000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_zust is distinct from 'traegt_nicht' then
    raise exception 'F3: Teil b falsch ergab %, erwartet traegt_nicht',
      coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F3 ok: Teil a richtig, Teil b falsch -> traegt_nicht';

  -- ══ Fall 4: beide falsch -> traegt_nicht ══════════════════════════════════

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_multi);
  perform public.lsa_submit(v_se, v_multi, '{"1":"b","2":"9"}'::jsonb, 30000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_zust is distinct from 'traegt_nicht' then
    raise exception 'F4: beide falsch ergab %, erwartet traegt_nicht',
      coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F4 ok: beide Teile falsch -> traegt_nicht';

  -- ══ Fall 5: "weiss nicht" auf das ganze Item -> kein Negativbeleg ═════════
  --
  -- lsa_submit setzt dann JEDE Teilzeile auf abgabeart weiss_nicht. Das darf
  -- kein traegt_nicht ergeben — ein "weiss nicht" ist kein belegter Fehler.
  -- Wie im flachen Pfad landet es provisorisch auf nicht_angesetzt.

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_multi);
  perform public.lsa_submit(v_se, v_multi, '{"dont_know":true}'::jsonb, 5000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_zust is distinct from 'nicht_angesetzt' then
    raise exception 'F5: weiss_nicht ergab %, erwartet nicht_angesetzt',
      coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F5 ok: "weiss nicht" -> nicht_angesetzt, kein Negativbeleg';

  -- ══ Fall 6: flaches NUMERIC-Item, richtig und falsch ══════════════════════
  --
  -- Die Kontrollgruppe. Am flachen Pfad darf sich NICHTS aendern.

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_flach);
  perform public.lsa_submit(v_se, v_flach, '{"text":"7"}'::jsonb, 20000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_FLACH';
  if v_zust is distinct from 'traegt' then
    raise exception 'F6: flach richtig ergab %, erwartet traegt', coalesce(v_zust, '<KEIN URTEIL>');
  end if;

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_ausgegeben (session_id, task_id) values (v_se, v_flach);
  perform public.lsa_submit(v_se, v_flach, '{"text":"999"}'::jsonb, 20000);

  select zustand into v_zust from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_FLACH';
  if v_zust is distinct from 'traegt_nicht' then
    raise exception 'F6: flach falsch ergab %, erwartet traegt_nicht',
      coalesce(v_zust, '<KEIN URTEIL>');
  end if;
  raise notice 'F6 ok: flaches NUMERIC-Item urteilt unveraendert (traegt / traegt_nicht)';

  -- ══ Fall 7: unvollstaendig erfasst -> KEIN Urteil ═════════════════════════
  --
  -- Fehlt eine Teilzeile, ist "sind ALLE Teile richtig" bei unbekanntem Nenner
  -- nicht beantwortbar. Dann lieber kein Beleg als einer auf halber Grundlage.
  -- Der Fall entsteht nur durch Reparatur von Hand — lsa_submit legt je Teil
  -- eine Zeile an — und wird deshalb direkt ueber die Funktion geprueft.

  v_st := gen_random_uuid(); v_se := gen_random_uuid();
  insert into public.students (id, class_level) values (v_st, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade, status, modus)
    values (v_se, v_st, 'mathematik', 8, 'in_progress', 'adaptiv');
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response)
  values (v_se, v_multi, 1, 'antwort', true, '{"selected":["a"]}'::jsonb);

  if public.lsa_urteil_buchen_core(v_se, v_multi) is not null then
    raise exception 'F7: mit nur einer von zwei Teilzeilen wurde ein Urteil gebucht';
  end if;
  select count(*) into v_n from public.lsa_skill_urteil
   where session_id = v_se and skill_key = 'AF7_MULTI';
  if v_n <> 0 then
    raise exception 'F7: es steht ein Urteil in lsa_skill_urteil, erwartet keines';
  end if;
  raise notice 'F7 ok: unvollstaendig erfasstes Item bucht kein Urteil';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.lsa_skill_urteil) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'AF7: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
