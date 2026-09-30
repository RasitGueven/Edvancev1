-- Abnahme Schuelerakte S3: fortschritt(p_student)
-- (Migration 20260930140000_akte_fortschritt.sql).
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/fortschritt_test.sql
--
-- Eine Transaktion, ROLLBACK am Ende — gegen Prod ohne bleibende Aenderung.
-- Legt eigene Fixtures an (Praefix ZZ_T3): ein Fach mit drei Clustern, Microskills,
-- eine Prozesskompetenz, Admin, zwei Coaches, ein aktives und ein ruhendes Kind.
-- Unabhaengig von vorhandenen Lerninhalten. Abnahme: Spalte `ergebnis` nur OK.

begin;

create temp table ergebnis (nr integer, pruefung text, ist text, soll text) on commit drop;
grant all on ergebnis to authenticated;

do $$
declare
  v_admin uuid := gen_random_uuid();
  v_coach uuid := gen_random_uuid();
  v_fach  uuid := gen_random_uuid();
  v_leer  uuid := gen_random_uuid();
  c1 uuid := gen_random_uuid(); c2 uuid := gen_random_uuid(); c3 uuid := gen_random_uuid();
  m1 uuid := gen_random_uuid(); m2 uuid := gen_random_uuid(); m3 uuid := gen_random_uuid(); m4 uuid := gen_random_uuid();
  v_pk uuid := gen_random_uuid();
  k_aktiv uuid := gen_random_uuid(); k_ruhend uuid := gen_random_uuid();
  l1 uuid := gen_random_uuid(); l2 uuid := gen_random_uuid();
  v_n integer;
  v_t text;
  r record;
begin
  insert into auth.users (id, email, instance_id, aud, role) values
    (v_admin, 'zz_t3_admin@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_coach, 'zz_t3_coach@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
  insert into public.profiles (id, email, role, full_name) values
    (v_admin, 'zz_t3_admin@edvance.invalid', 'admin', 'ZZ_T3 Admin'),
    (v_coach, 'zz_t3_coach@edvance.invalid', 'coach', 'ZZ_T3 Coach')
  on conflict (id) do update set role = excluded.role, full_name = excluded.full_name;

  insert into public.subjects (id, name) values (v_fach, 'ZZ_T3 Fach'), (v_leer, 'ZZ_T3 Leer');
  insert into public.skill_clusters (id, subject_id, name, class_level_min, class_level_max, sort_order) values
    (c1, v_fach, 'ZZ_T3 Thema A', 8, 10, 1), (c2, v_fach, 'ZZ_T3 Thema B', 8, 10, 2), (c3, v_fach, 'ZZ_T3 Thema C', 8, 10, 3);
  insert into public.microskills (id, cluster_id, code, name, class_level, sort_order) values
    (m1, c1, 'ZZ_T3_M1', 'ZZ_T3 Kompetenz 1', 9, 1), (m2, c1, 'ZZ_T3_M2', 'ZZ_T3 Kompetenz 2', 9, 2),
    (m3, c2, 'ZZ_T3_M3', 'ZZ_T3 Kompetenz 3', 9, 1), (m4, c2, 'ZZ_T3_M4', 'ZZ_T3 Kompetenz 4', 9, 2);
  insert into public.process_competencies (id, code, name, sort_order) values (v_pk, 'ZZ_T3', 'ZZ_T3 Operieren', 99);

  insert into public.leads (id, full_name, status) values (l1, 'ZZ_T3 Aktiv', 'converted'), (l2, 'ZZ_T3 Ruhend', 'converted');
  insert into public.students (id, class_level) values (k_aktiv, 9), (k_ruhend, 9);
  insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am) values
    (l1, 'abgeschlossen', 'aktiv', k_aktiv, 57, 12, date_trunc('month', current_date - 60)::date, current_date + 200, current_date - 70),
    (l2, 'abgeschlossen', 'aktiv', k_ruhend, 57, 12, date_trunc('month', current_date - 400)::date, current_date - 10, current_date - 410);

  insert into public.student_subjects (student_id, subject_id) values (k_aktiv, v_fach), (k_aktiv, v_leer), (k_ruhend, v_fach);
  -- Lernpfad: aktiv Thema B und C -> aktuelles Thema = B (Station 2 von 3); A ist verworfen
  insert into public.student_focus_areas (student_id, cluster_id, status, active) values
    (k_aktiv, c2, 'vorgeschlagen', true), (k_aktiv, c3, 'bestaetigt', true), (k_aktiv, c1, 'verworfen', true),
    (k_ruhend, c1, 'vorgeschlagen', true);

  -- Mastery: zwei vom Coach bestaetigt, eine nur System-Evidenz (Score ohne Bestaetigung)
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  insert into public.student_competency_mastery (student_id, microskill_id, competency_id, score, mastered) values
    (k_aktiv, m1, v_pk, 90, true), (k_aktiv, m3, v_pk, 85, true), (k_aktiv, m2, v_pk, 97, false),
    (k_ruhend, m1, v_pk, 80, true);
  perform set_config('request.jwt.claims', '', true);
  update public.student_competency_mastery set mastered_at = now() - interval '10 days' where student_id = k_aktiv and microskill_id = m1;

  -- ---------------------------------------------------------------- als Admin
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select string_agg(f.fach || ':' || coalesce(f.thema, '-') || ':' || coalesce(f.station::text, '-') || '/' || coalesce(f.stationen::text, '-')
                    || ':' || jsonb_array_length(f.kompetenzen), ' | ' order by f.fach) into v_t
    from public.fortschritt(k_aktiv) f;
  insert into ergebnis values (1, 'Admin: je Fach Thema, Station, Anzahl bestaetigter Kompetenzen', v_t,
    'ZZ_T3 Fach:ZZ_T3 Thema B:2/3:2 | ZZ_T3 Leer:-:-/-:0');

  select string_agg(k ->> 'kompetenz' || '/' || (k ->> 'coach'), ',') into v_t
    from public.fortschritt(k_aktiv) f, jsonb_array_elements(f.kompetenzen) k where f.fach = 'ZZ_T3 Fach';
  insert into ergebnis values (2, 'Admin: bestaetigte Kompetenzen, neueste zuerst, mit Coach (System-Evidenz fehlt)', v_t,
    'ZZ_T3 Kompetenz 3/ZZ_T3 Coach,ZZ_T3 Kompetenz 1/ZZ_T3 Coach');

  select count(*) into v_n from public.fortschritt(k_ruhend);
  insert into ergebnis values (3, 'Admin: ruhende Akte behaelt ihren Stand', v_n::text, '1');

  -- ---------------------------------------------------------------- als Coach
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select jsonb_array_length(f.kompetenzen)::text into v_t from public.fortschritt(k_aktiv) f where f.fach = 'ZZ_T3 Fach';
  insert into ergebnis values (10, 'Coach: aktive Akte, genau 2 gemeistert (2 bestaetigt + 1 System)', coalesce(v_t, '-'), '2');
  begin
    perform * from public.fortschritt(k_ruhend);
    insert into ergebnis values (11, 'Coach: ruhende Akte', 'geliefert', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (11, 'Coach: ruhende Akte', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  execute 'reset role';
end;
$$;

insert into ergebnis values
  (20, 'anon darf fortschritt nicht ausfuehren', has_function_privilege('anon', 'public.fortschritt(uuid)', 'execute')::text, 'false'),
  (21, 'authenticated darf fortschritt ausfuehren', has_function_privilege('authenticated', 'public.fortschritt(uuid)', 'execute')::text, 'true');

select nr, pruefung, ist, soll,
       case when ist is not distinct from soll then 'OK' else 'FEHLER' end as ergebnis
  from ergebnis order by nr;

rollback;
