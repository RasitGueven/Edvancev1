-- Rollback zu 20261029091200_r1_lena_rueckfragen: alte Werte vom 29.10.2026 (dbread vor dem Einspielen).
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261029091200 aus
-- supabase_migrations.schema_migrations löschen. Kein Schema, kein Snapshot nötig.
-- Setzt nur zurück, wo noch der Stand nach der Migration steht. Status (Freigabe über pruef_rueckfrage_klaeren) und
-- Antworten an Lena fasst der Rollback nicht an.

do $r$
declare
  v_n integer;
begin
  -- 1. Text 8c4a2d71
  update public.tasks
     set question = E'Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?'::text))
   where id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'
     and question = E'Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?';
  get diagnostics v_n = row_count; raise notice 'rollback 8c4a2d71: %', v_n;

  update public.task_solutions
     set correct_answers = '["1029"]'::jsonb, acceptance = acceptance - 'equivalents', updated_at = now()
   where task_id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'
     and correct_answers = '["1029", "+1029"]'::jsonb and acceptance -> 'equivalents' = '["+1029"]'::jsonb;
  get diagnostics v_n = row_count; raise notice 'rollback 8c4a2d71 +1029: %', v_n;

  -- 2. ffc76634
  update public.task_solutions
     set acceptance = jsonb_set(acceptance, '{known_errors}',
           '{"4": "addiert_statt_subtrahiert", "+4": "addiert_statt_subtrahiert", "2/3": "steigung_kehrwert", "+2/3": "steigung_kehrwert"}'::jsonb),
         typical_errors = '[{"error": "Beim Auflösen nach b addiert statt subtrahiert: 1 + 3 = 4.",
                             "fehlbild": "addiert_statt_subtrahiert",
                             "socratic_question": "Was musst du auf beiden Seiten tun, damit die 3 neben dem b verschwindet?"},
                            {"error": "Mit dem Kehrwert der Steigung gerechnet: m = 1/3, b = 2/3.",
                             "fehlbild": "steigung_kehrwert",
                             "socratic_question": "Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?"}]'::jsonb,
         updated_at = now()
   where task_id = 'ffc76634-86ca-4c53-b816-d18d7f868443'
     and acceptance -> 'known_errors' ? '-18';
  get diagnostics v_n = row_count; raise notice 'rollback ffc76634: %', v_n;

  -- 3. 6274f6a5: die 24 neuen Schlüssel und die beiden angehängten typical_errors entfernen
  update public.task_solutions
     set acceptance = jsonb_set(acceptance, '{known_errors}', (acceptance -> 'known_errors') - array(
           select vz || v || einheit from unnest(array['30', '60', '65', '156']) v,
                  unnest(array['', '+']) vz, unnest(array['', ' cm²', 'cm²']) einheit)),
         typical_errors = typical_errors - 4 - 3,
         updated_at = now()
   where task_id = '6274f6a5-65e5-40f4-be09-36fa8931c424'
     and acceptance -> 'known_errors' ? '60'
     and jsonb_array_length(typical_errors) = 5;
  get diagnostics v_n = row_count; raise notice 'rollback 6274f6a5: %', v_n;
end $r$;
