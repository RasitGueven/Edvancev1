-- PRUEFUNG: Entwurfs-Familien erreichen den Elternbericht nicht
-- (Migration 20261004003939).
--
-- Schreibt Testdaten und rollt zurück — NICHT mit dbread, sondern in einer
-- Wegwerf-DB aus allen Migrationen:
--
--     psql postgresql:///<wegwerf> -v ON_ERROR_STOP=1 -f supabase/checks/fehlbild_familien_entwurf.PRUEFUNG.sql
--
-- Benutzt die echten Slugs mal_exponent (potenzen_wurzeln) und
-- komma_ignoriert (kommazahlen). Beide Labels werden im Test selbst
-- freigegeben, damit nur die FAMILIEN-Abnahme den Unterschied macht.

begin;

do $$
declare
  v_coach   uuid := gen_random_uuid();
  v_student uuid := gen_random_uuid();
  v_sess    uuid := gen_random_uuid();
  v_t       uuid[];
  v_fam     text;
  v_txt     text;
  v_n       bigint;
begin
  insert into auth.users (id, email) values (v_coach, 'w5a-coach@edvance.test');
  insert into public.profiles (id, email, role) values (v_coach, 'w5a-coach@edvance.test', 'coach');
  perform set_config('request.jwt.claim.sub', v_coach::text, true);

  insert into public.skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe)
  values ('W5A_PROBE', 'W5-a Probe', 'mathematik', 9, 1);
  insert into public.students (id, class_level) values (v_student, 9);
  insert into public.lsa_sessions (id, student_id, subject, grade)
  values (v_sess, v_student, 'mathematik', 9);

  select array_agg(id order by nr) into v_t
    from (select gen_random_uuid() as id, nr from generate_series(1, 4) as nr) x;
  insert into public.tasks (id, content_type, skill_key, question)
  select v_t[i], 'exercise', 'W5A_PROBE', 'W5-a Probe ' || i from generate_series(1, 4) as i;

  update public.fehlbild_labels set freigegeben_am = now(), freigegeben_von = v_coach
   where slug in ('mal_exponent', 'komma_ignoriert');

  -- Je zwei Vorkommen in zwei Aufgaben -> beide Slugs sind 'befund'.
  insert into public.lsa_responses
    (session_id, task_id, part_nr, abgabeart, correct, response, fehlbild_slug)
  values
    (v_sess, v_t[1], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'mal_exponent'),
    (v_sess, v_t[2], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'mal_exponent'),
    (v_sess, v_t[3], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'komma_ignoriert'),
    (v_sess, v_t[4], 1, 'antwort', false, '{"text":"x"}'::jsonb, 'komma_ignoriert');

  -- E1: Familie kommt, Elterntext nicht.
  select a.familie, a.familie_elterntext, a.anzahl into v_fam, v_txt, v_n
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'mal_exponent';
  if v_n is distinct from 2 then
    raise exception 'E1: Zeile fehlt oder zählt falsch (anzahl=%)', coalesce(v_n::text, '<keine>');
  end if;
  if v_fam is distinct from 'potenzen_wurzeln' then
    raise exception 'E1: familie=%, erwartet potenzen_wurzeln', coalesce(v_fam, '<null>');
  end if;
  if v_txt is not null then
    raise exception 'E1: Entwurfs-Elterntext ausgeliefert: %', v_txt;
  end if;
  select a.familie_elterntext into v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'komma_ignoriert';
  if v_txt is not null then
    raise exception 'E1: Entwurfs-Elterntext ausgeliefert: %', v_txt;
  end if;
  if exists (select 1 from public.lsa_fehlbild_auswertung(v_sess) a
              where a.familie_elterntext is not null) then
    raise exception 'E1: irgendein Elterntext ausgeliefert';
  end if;
  raise notice 'E1 ok: Entwurfs-Familien liefern keinen Elterntext';

  -- E2: Gegenprobe — Freigabe der Familie lässt den Text durch. Belegt, dass
  -- E1 an der Abnahme hängt und nicht an fehlenden Daten.
  update public.fehlbild_familien set freigegeben_am = now(), freigegeben_von = v_coach
   where schluessel = 'potenzen_wurzeln';
  select a.familie_elterntext into v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'mal_exponent';
  if v_txt is null then
    raise exception 'E2: freigegebene Familie liefert keinen Elterntext — Test ohne Aussagekraft';
  end if;
  select a.familie_elterntext into v_txt
    from public.lsa_fehlbild_auswertung(v_sess) a where a.fehlbild_slug = 'komma_ignoriert';
  if v_txt is not null then
    raise exception 'E2: unfreigegebene Familie kommazahlen liefert Text';
  end if;
  raise notice 'E2 ok: erst die Familien-Abnahme gibt den Elterntext frei';
end
$$;

rollback;
