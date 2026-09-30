-- Fortschritt fuer die ZZ_S2B-Testakten (Kachel Fortschritt, S3).
--
-- Setzt tools/seed/zz_schuelerakten_seed.sql voraus (fuenf ZZ_S2B-Akten) und den
-- Test-Coach zz_testcoach@edvance.invalid. Nutzt die vorhandenen Lerninhalte
-- (Fach Mathematik mit seinen skill_clusters/microskills, process_competencies)
-- und legt KEINE eigenen Inhalte an — ZZ-Cluster koennten sonst in der App
-- echter Kinder auftauchen.
--
--   ZZ_S2B Mia Plan       Mathematik: Station 2; 2 vom Coach bestaetigte Kompetenzen
--                         + 1 nur vom System erkannte (Score ohne Bestaetigung)
--   ZZ_S2B Efe Leicht     zwei Faecher: Mathematik (Station 4, 5 bestaetigte ->
--                         "und 1 weitere") und Deutsch (in Prod ohne Lernpfad)
--   ZZ_S2B Elif Deutlich  Fach Mathematik, kein Lernpfad -> "Noch kein Lernpfad."
--   ZZ_S2B Ben Ruhend     Mathematik: Station 1, 1 bestaetigt (ruhend, Admin-Sicht)
--   ZZ_S2B Lina Startet   nichts
--
-- Bestaetigt wird wie im echten Weg: mit den Claims des Test-Coaches setzt der
-- Trigger enforce_mastery_gate mastered_by / mastered_at. Danach werden die
-- Daten gestaffelt (Update ohne Statuswechsel beruehrt mastered_by nicht).
--
-- Kennung: student_focus_areas.note = 'ZZ_S2B'; Mastery und student_subjects
-- gehoeren zu den ZZ_S2B-Kindern (der Akten-Seed legt dort nichts an).
-- Entfernen: tools/seed/zz_fortschritt_teardown.sql (oder der Akten-Teardown,
-- der die Kinder samt allem loescht).
--
-- Ausfuehren:  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_fortschritt_seed.sql

do $$
declare
  c_marke constant text := 'ZZ_S2B';
  v_coach uuid;
  v_mathe uuid;
  v_deutsch uuid;
  v_kind  jsonb := '{}'::jsonb;
  r       record;
  v_cluster uuid[];
  v_ms    uuid[];
  v_pk    uuid[];
  i       integer;
begin
  select p.id into v_coach from public.profiles p where p.email = 'zz_testcoach@edvance.invalid' and p.role = 'coach';
  if v_coach is null then
    raise exception 'Fortschritt-Seed: Test-Coach zz_testcoach@edvance.invalid fehlt';
  end if;

  for r in
    select l.first_name, l.converted_student_id as kind
      from public.leads l where l.full_name like c_marke || ' %' and l.converted_student_id is not null
  loop
    v_kind := v_kind || jsonb_build_object(split_part(r.first_name, ' ', 2), r.kind);
  end loop;
  if (select count(*) from jsonb_object_keys(v_kind)) <> 5 then
    raise exception 'Fortschritt-Seed: erst tools/seed/zz_schuelerakten_seed.sql (gefunden: %)', v_kind;
  end if;
  if exists (select 1 from public.student_focus_areas where note = c_marke) then
    raise exception 'Fortschritt-Seed: es gibt schon Fortschritt-Testdaten — erst zz_fortschritt_teardown.sql';
  end if;

  select id into v_mathe from public.subjects where name = 'Mathematik';
  select id into v_deutsch from public.subjects where name = 'Deutsch';
  select array_agg(c.id order by c.sort_order, c.name) into v_cluster
    from public.skill_clusters c where c.subject_id = v_mathe and not c.is_deprecated and 9 between c.class_level_min and c.class_level_max;
  select array_agg(m.id order by c.sort_order, m.sort_order, m.code) into v_ms
    from public.microskills m join public.skill_clusters c on c.id = m.cluster_id
   where c.subject_id = v_mathe and not c.is_deprecated;
  select array_agg(id order by sort_order) into v_pk from public.process_competencies;
  if v_mathe is null or v_deutsch is null or coalesce(array_length(v_cluster, 1), 0) < 4
     or coalesce(array_length(v_ms, 1), 0) < 8 or coalesce(array_length(v_pk, 1), 0) < 1 then
    raise exception 'Fortschritt-Seed: Lerninhalte fehlen (Mathematik >= 4 Cluster, >= 8 Microskills, Deutsch, Prozesskompetenzen)';
  end if;

  -- Faecher der Akten
  insert into public.student_subjects (student_id, subject_id) values
    ((v_kind ->> 'Mia')::uuid, v_mathe), ((v_kind ->> 'Efe')::uuid, v_mathe), ((v_kind ->> 'Efe')::uuid, v_deutsch),
    ((v_kind ->> 'Elif')::uuid, v_mathe), ((v_kind ->> 'Ben')::uuid, v_mathe)
  on conflict do nothing;

  -- Lernpfad-Stand (aktiver Schwerpunkt im Lernpfad Mathematik)
  insert into public.student_focus_areas (student_id, cluster_id, coach_id, source, note, active, status) values
    ((v_kind ->> 'Mia')::uuid, v_cluster[2], v_coach, 'lsa', c_marke, true, 'vorgeschlagen'),
    ((v_kind ->> 'Efe')::uuid, v_cluster[4], v_coach, 'lsa', c_marke, true, 'vorgeschlagen'),
    ((v_kind ->> 'Ben')::uuid, v_cluster[1], v_coach, 'lsa', c_marke, true, 'vorgeschlagen');

  -- Mastery: bestaetigt ueber die Coach-Claims (Trigger setzt mastered_by/_at)
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  insert into public.student_competency_mastery (student_id, microskill_id, competency_id, score, mastered) values
    ((v_kind ->> 'Mia')::uuid, v_ms[1], v_pk[1], 92, true),
    ((v_kind ->> 'Mia')::uuid, v_ms[2], v_pk[1], 88, true),
    ((v_kind ->> 'Mia')::uuid, v_ms[5], v_pk[1], 96, false),   -- nur System-Evidenz
    ((v_kind ->> 'Ben')::uuid, v_ms[1], v_pk[1], 85, true);
  for i in 1 .. 5 loop
    insert into public.student_competency_mastery (student_id, microskill_id, competency_id, score, mastered)
    values ((v_kind ->> 'Efe')::uuid, v_ms[i + 2], v_pk[1 + (i % coalesce(array_length(v_pk, 1), 1))], 80 + i, true);
  end loop;
  perform set_config('request.jwt.claims', '', true);

  -- Daten staffeln (neueste zuerst in der Kachel)
  update public.student_competency_mastery m
     set mastered_at = now() - make_interval(days => (x.rang * 9)::integer)
    from (select student_id, microskill_id, competency_id,
                 row_number() over (partition by student_id order by microskill_id) as rang
            from public.student_competency_mastery
           where mastered_by is not null
             and student_id in (select (value #>> '{}')::uuid from jsonb_each(v_kind))) x
   where m.student_id = x.student_id and m.microskill_id = x.microskill_id and m.competency_id = x.competency_id;

  raise notice 'Fortschritt-Seed %: Lernpfad fuer 3 Kinder, 8 bestaetigte + 1 System-Kompetenz', c_marke;
end;
$$;
