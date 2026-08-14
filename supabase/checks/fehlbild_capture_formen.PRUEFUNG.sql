-- PRUEFUNG zu AF6 (Fehlbild-Erfassung unabhaengig von der Antwortform).
--
--   psql "postgresql:///edvance_neuaufbau" -v ON_ERROR_STOP=1 \
--        -f supabase/checks/fehlbild_capture_formen.PRUEFUNG.sql
--
-- Geprueft wird der Weg ueber den ECHTEN Trigger, nicht lsa_fehlbild_match
-- direkt: der Defekt sass nicht in der Match-Funktion — die war immer richtig —
-- sondern darin, WAS ihr der Trigger uebergibt. Eine Probe auf die Funktion
-- allein waere an genau diesem Fehler vorbeigelaufen.
--
-- Deshalb legt diese Datei echte lsa_responses-Zeilen an und liest zurueck, was
-- der Trigger daraus gemacht hat. Alles in begin/rollback — lsa_responses ist
-- append-only, hier darf nichts stehenbleiben.

begin;

do $$
declare
  v_coach   uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_sess    uuid := gen_random_uuid();
  v_multi   uuid := gen_random_uuid();
  v_flach   uuid := gen_random_uuid();
  v_slug    text;
  v_ctrl    boolean;
begin
  -- ══ Testdaten ═════════════════════════════════════════════════════════════

  insert into auth.users (id, email) values (v_coach, 'af6-coach@edvance.test');
  insert into public.profiles (id, email, role)
    values (v_coach, 'af6-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('AF6_PROBE', 'AF6 Probe', 'mathematik', 8, 1);

  insert into public.students (id, class_level) values (v_student, 8);
  insert into public.lsa_sessions (id, student_id, subject, grade)
  values (v_sess, v_student, 'mathematik', 8);

  insert into public.fehlbild_labels (slug, klartext, familie, freigegeben_am, freigegeben_von)
  values ('af6_mc',    'MC-Probe',    'sachaufgaben', now(), v_coach),
         ('af6_kurz',  'Kurz-Probe',  'sachaufgaben', now(), v_coach),
         ('af6_flach', 'Flach-Probe', 'sachaufgaben', now(), v_coach);

  -- Ein MULTI_PART-Item wie die P5-Aufgaben: Teil 1 mc, Teil 2 short_input.
  insert into public.tasks (id, content_type, skill_key, question, input_type,
                            est_duration_sec, parts)
  values (v_multi, 'exercise', 'AF6_PROBE', 'AF6 Multi-Part-Probe', 'MULTI_PART', 180,
    '[{"nr":1,"kind":"mc","prompt":"Welche?","afb":"II",
       "options":[{"id":"a","label":"A"},{"id":"b","label":"B"}]},
      {"nr":2,"kind":"short_input","prompt":"Wie viele?","afb":"II"}]'::jsonb);
  insert into public.task_solutions (task_id, correct_answers, acceptance)
  values (v_multi, '{"1":["a"],"2":["7"]}'::jsonb,
    '{"1":{"canonical":"a","known_errors":{"b":"af6_mc"}},
      "2":{"canonical":"7","known_errors":{"9":"af6_kurz"}}}'::jsonb);

  -- Ein flaches NUMERIC-Item als Kontrollgruppe: es darf sich NICHT aendern.
  insert into public.tasks (id, content_type, skill_key, question, input_type)
  values (v_flach, 'exercise', 'AF6_PROBE', 'AF6 flache Probe', 'NUMERIC');
  insert into public.task_solutions (task_id, correct_answers, acceptance)
  values (v_flach, '["7"]'::jsonb,
          '{"canonical":"7","known_errors":{"9":"af6_flach"}}'::jsonb);

  -- ══ Fall 1: mc, OBJEKTFORM ════════════════════════════════════════════════
  --
  -- Der Weg, der schon vor AF6 funktioniert hat. Er muss unveraendert tragen —
  -- sonst hat die Normalisierung kaputtgemacht, was lief.

  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 1, 'antwort', false, '{"selected":["b"]}'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 1;
  if v_slug is distinct from 'af6_mc' then
    raise exception 'F1: mc/Objektform ergab %, erwartet af6_mc', coalesce(v_slug, '<null>');
  end if;
  raise notice 'F1 ok: mc mit Objektform wird gelabelt';

  -- ══ Fall 2: mc, SKALARFORM ════════════════════════════════════════════════
  --
  -- DER KERN VON AF6. Genau diese Form schickt edvance-app bei MULTI_PART
  -- (DATENVERTRAG §6), und genau sie blieb bis AF6 ohne Label.

  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 1, 'antwort', false, '"b"'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 1;
  if v_slug is distinct from 'af6_mc' then
    raise exception 'F2: mc/Skalarform ergab %, erwartet af6_mc — die '
                    'Normalisierung im Trigger greift nicht', coalesce(v_slug, '<null>');
  end if;
  raise notice 'F2 ok: mc mit Skalarform wird gelabelt (derselbe Slug)';

  -- ══ Fall 3: short_input, OBJEKTFORM ═══════════════════════════════════════

  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 2, 'antwort', false, '{"text":"9"}'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 2;
  if v_slug is distinct from 'af6_kurz' then
    raise exception 'F3: short_input/Objektform ergab %, erwartet af6_kurz',
      coalesce(v_slug, '<null>');
  end if;
  raise notice 'F3 ok: short_input mit Objektform wird gelabelt';

  -- ══ Fall 4: short_input, SKALARFORM ═══════════════════════════════════════

  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 2, 'antwort', false, '"9"'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 2;
  if v_slug is distinct from 'af6_kurz' then
    raise exception 'F4: short_input/Skalarform ergab %, erwartet af6_kurz',
      coalesce(v_slug, '<null>');
  end if;
  raise notice 'F4 ok: short_input mit Skalarform wird gelabelt (derselbe Slug)';

  -- ══ Fall 5: flaches NUMERIC-Item bleibt unveraendert ══════════════════════
  --
  -- Die Kontrollgruppe. 129 Antworten liegen in Produktion, alle in Objektform,
  -- ueber flache Items. Wenn AF6 dort etwas aendert, ist der Preis hoeher als
  -- der Gewinn.

  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_flach, null, 'antwort', false, '{"text":"9"}'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_flach;
  if v_slug is distinct from 'af6_flach' then
    raise exception 'F5: flaches Item ergab %, erwartet af6_flach', coalesce(v_slug, '<null>');
  end if;
  raise notice 'F5 ok: flaches NUMERIC-Item labelt wie bisher';

  -- ══ Fall 6: Negativkontrolle — unbekannter Wert bleibt ohne Slug ══════════
  --
  -- Ohne diesen Fall wuerde ein Trigger, der stumpf IRGENDEINEN Slug setzt,
  -- alle fuenf Faelle oben bestehen.

  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 2, 'antwort', false, '"12345"'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 2;
  if v_slug is not null then
    raise exception 'F6: unbekannter Wert wurde als % gelabelt', v_slug;
  end if;

  -- Und eine richtige Antwort ebenfalls nicht: der Trigger laeuft nur auf
  -- correct = false.
  delete from public.lsa_responses where session_id = v_sess;
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values (v_sess, v_multi, 1, 'antwort', true, '"b"'::jsonb, null);
  select fehlbild_slug into v_slug from public.lsa_responses
   where session_id = v_sess and task_id = v_multi and part_nr = 1;
  if v_slug is not null then
    raise exception 'F6: eine RICHTIGE Antwort wurde als % gelabelt', v_slug;
  end if;
  raise notice 'F6 ok: unbekannter Wert und richtige Antwort bleiben ohne Slug';

  -- ══ Fall 7: die Normalisierung laesst Objekte unangetastet ════════════════
  --
  -- Die Zusicherung, auf der die Unschaedlichkeit fuer den Altbestand ruht.

  if public.lsa_part_answer('mc', '{"selected":["b"]}'::jsonb)
     is distinct from '{"selected":["b"]}'::jsonb
   or public.lsa_part_answer('short_input', '{"text":"9"}'::jsonb)
     is distinct from '{"text":"9"}'::jsonb then
    raise exception 'F7: lsa_part_answer veraendert die Objektform';
  end if;
  raise notice 'F7 ok: Objektformen gehen unveraendert durch die Normalisierung';

  -- ══ Negativkontrolle des Harnischs selbst ═════════════════════════════════

  v_ctrl := false;
  begin
    if (select count(*) from public.lsa_responses where session_id = v_sess) <> -1 then
      raise exception 'kontrolle: absichtlich falsche Erwartung';
    end if;
  exception when others then v_ctrl := true;
  end;
  if not v_ctrl then raise exception 'FKontrolle: der Harnisch loest nicht aus'; end if;
  raise notice 'FKontrolle ok: falsche Erwartung bricht den Lauf ab';

  raise notice 'AF6: ALLE PRUEFUNGEN BESTANDEN';
end $$;

rollback;
