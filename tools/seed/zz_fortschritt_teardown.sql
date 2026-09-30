-- Entfernt, was tools/seed/zz_fortschritt_seed.sql angelegt hat — und sonst nichts:
--   student_focus_areas mit note = 'ZZ_S2B' der ZZ_S2B-Kinder,
--   student_competency_mastery und student_subjects der ZZ_S2B-Kinder
--   (der Akten-Seed legt dort nichts an; echte Kinder sind nicht betroffen).
-- Die Akten selbst bleiben stehen. Reihenfolge fuer restloses Aufraeumen:
--   1. tools/seed/zz_fortschritt_teardown.sql
--   2. tools/seed/zz_schuelerakten_teardown.sql
-- (Der Akten-Teardown allein raeumt per Kaskade auch den Fortschritt mit ab.)
--
-- Ausfuehren:  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_fortschritt_teardown.sql

do $$
declare
  c_marke  constant text := 'ZZ_S2B';
  v_kinder uuid[];
  v_n      integer;
begin
  select coalesce(array_agg(converted_student_id), '{}') into v_kinder
    from public.leads where full_name like c_marke || ' %' and converted_student_id is not null;

  delete from public.student_focus_areas where note = c_marke and student_id = any(v_kinder);
  get diagnostics v_n = row_count; raise notice 'Schwerpunkte: %', v_n;
  delete from public.student_competency_mastery where student_id = any(v_kinder);
  get diagnostics v_n = row_count; raise notice 'Mastery: %', v_n;
  delete from public.student_subjects where student_id = any(v_kinder);
  get diagnostics v_n = row_count; raise notice 'Faecher: %', v_n;

  if exists (select 1 from public.student_focus_areas where note = c_marke)
     or exists (select 1 from public.student_competency_mastery where student_id = any(v_kinder))
     or exists (select 1 from public.student_subjects where student_id = any(v_kinder)) then
    raise exception 'Fortschritt-Teardown %: es ist noch etwas uebrig', c_marke;
  end if;
  raise notice 'Fortschritt-Teardown %: nichts mehr uebrig', c_marke;
end;
$$;
