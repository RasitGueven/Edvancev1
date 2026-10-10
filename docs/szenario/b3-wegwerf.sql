-- F1 / B3: Grundlage fuer den Test von tools/szenario-lsa.mjs in der Wegwerf-DB (nie Produktion).
-- Ein Admin, ein Testkind Klasse 9 mit Lead und laufendem Vertrag (wie TESTLEAD Zweitmann) und ein echtes Kind.
-- Im Neuaufbau fehlen Prod-Inhalte: Cluster an den Wurzel-Aufgaben (sonst pruef_ausschluss 'gate') und Aufgaben
-- zu runden_ueberschlag (kommen in Prod aus supabase/seeds). Beides legt diese Datei an, mit Praefix zz_f1.
--   psql -d <wegwerf-db> -v ON_ERROR_STOP=1 -f docs/szenario/b3-wegwerf.sql
begin;

insert into auth.users (id, email, instance_id, aud, role) values
  ('f1f1f1f1-0001-4000-8000-000000000001', 'f1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  ('f1f1f1f1-0001-4000-8000-000000000001', 'f1-admin@test.local', 'admin', 'ZZ F1 Admin');

create or replace function pg_temp.kind(p_id uuid, p_name text, p_test boolean) returns void language plpgsql as $$
declare v_lead uuid;
begin
  insert into leads (full_name, first_name, status, class_level, ist_test)
  values (p_name, split_part(p_name, ' ', 1), 'converted', 9, false) returning id into v_lead;
  insert into students (id, class_level, ist_test) values (p_id, 9, p_test);
  update leads set converted_student_id = p_id where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
                         student_id, vertragsbeginn, vertrag_ende, widerruf_bis)
  values (v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 31, 'vor_ort', p_id,
          date_trunc('month', current_date - 31)::date,
          (date_trunc('month', current_date) + interval '7 month' - interval '1 day')::date, current_date - 16);
end $$;
select pg_temp.kind('f1f1f1f1-0002-4000-8000-000000000001', 'ZZ F1 Zweitmann', true);
select pg_temp.kind('f1f1f1f1-0002-4000-8000-000000000002', 'ZZ F1 Echt', false);

-- Cluster wie in Prod (dort gesetzt), damit die Entwuerfe ohne pruef_ausschluss im Testlauf-Pool stehen.
update tasks set cluster_id = (select id from skill_clusters where name = 'Zahl & Rechnen')
 where skill_key like 'zahl_wurzel%' and cluster_id is null;

-- runden_ueberschlag: vier Entwuerfe mit known_errors „abgeschnitten“ (Prod hat 13).
insert into tasks (cluster_id, content_type, input_type, status, question, question_payload, afb, competency_content,
                   est_duration_sec, class_level, curriculum_grade, source, source_ref, skill_key, einsatz, is_active)
select (select id from skill_clusters where name = 'Zahl & Rechnen'), 'exercise', 'NUMERIC', 'draft',
       'ZZ F1 Runde ' || v || ' auf eine Stelle nach dem Komma.',
       jsonb_build_object('kind', 'short_input', 'prompt', 'ZZ F1 Runde ' || v || ' auf eine Stelle nach dem Komma.'),
       'I', 'zahlen', 45, 5, 5, 'test', 'zz-f1-runden-' || n, 'runden_ueberschlag', '{lsa,session}', true
  from (values (1, '3,46'), (2, '7,28'), (3, '1,95'), (4, '4,77')) x(n, v);
select set_config('request.jwt.claim.role', 'service_role', true);
select public.task_solution_upsert(
         p_task_id => t.id,
         p_correct_answers => jsonb_build_array(x.richtig),
         p_solution => 'ZZ F1 runden',
         p_hints => '[]'::jsonb, p_coach_hints => '[]'::jsonb, p_typical_errors => '[]'::jsonb,
         p_acceptance => jsonb_build_object('canonical', x.richtig, 'known_errors', jsonb_build_object(x.falsch, 'abgeschnitten')))
  from tasks t join (values ('zz-f1-runden-1', '3,5', '3,4'), ('zz-f1-runden-2', '7,3', '7,2'),
                            ('zz-f1-runden-3', '2,0', '1,9'), ('zz-f1-runden-4', '4,8', '4,7')) x(ref, richtig, falsch)
    on t.source_ref = x.ref;
select set_config('request.jwt.claim.role', '', true);
commit;
