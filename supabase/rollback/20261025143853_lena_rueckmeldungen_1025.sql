-- Rollback zu 20261025143853_lena_rueckmeldungen_1025: alte Werte vom 25.10.2026 (dbread vor dem Einspielen).
--
-- Einspielen wie eine Migration (-v ON_ERROR_STOP=1 -1), danach die Zeile 20261025143853 aus
-- supabase_migrations.schema_migrations löschen. Kein Schema, kein Snapshot nötig.
-- Setzt nur zurück, wo noch der Stand nach der Migration steht. Die Status der Aufgaben (freigeben/an_lena über
-- pruef_rueckfrage_klaeren) und Lenas Antworten im Prüfprotokoll fasst der Rollback nicht an.

do $r$
declare
  v_n integer;
begin
  -- 1. known_errors entfernen
  update public.task_solutions
     set acceptance = jsonb_set(acceptance, '{known_errors}', (acceptance -> 'known_errors') - array['-14', '-11', '11']),
         updated_at = now()
   where task_id = 'a394b2eb-df58-4b57-9c79-ae8ff0c62b24'
     and acceptance -> 'known_errors' = '{"2": "vorrang_ignoriert", "-14": "plus_minus_vertauscht", "-11": "plus_minus_vertauscht", "11": "vorzeichen_ignoriert"}'::jsonb;
  get diagnostics v_n = row_count; raise notice 'rollback a394b2eb: %', v_n;

  update public.task_solutions
     set acceptance = jsonb_set(acceptance, '{known_errors}', (acceptance -> 'known_errors') - array['1,3', '1,33', '1,333', '4/3']),
         updated_at = now()
   where task_id = '6ef85b4a-1f14-49b4-acf6-05aa01567e4f'
     and acceptance -> 'known_errors' = '{"0,34": "ziffern_gelesen", "1,3": "umgekehrt_geteilt", "1,33": "umgekehrt_geteilt", "1,333": "umgekehrt_geteilt", "4/3": "umgekehrt_geteilt"}'::jsonb;
  get diagnostics v_n = row_count; raise notice 'rollback 6ef85b4a: %', v_n;

  -- 2. typical_errors wieder leer
  update public.task_solutions set typical_errors = '[]'::jsonb, updated_at = now()
   where task_id in ('1527a939-6199-4d8c-9163-6f34b0cd0e13', '10a764bc-9657-4a5a-b11d-64b2a0014b05')
     and typical_errors::text like '%Nur das erste Glied mit %';
  get diagnostics v_n = row_count; raise notice 'rollback typical_errors: %', v_n;

  -- 3. Aufgabentexte
  update public.tasks
     set question = E'Berechne geschickt mit einer binomischen Formel.\n\n49² = ?',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Berechne geschickt mit einer binomischen Formel.\n\n49² = ?'::text))
   where id = '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'
     and question = E'Berechne geschickt mit Hilfe einer binomischen Formel.\n\n49² = ?';
  get diagnostics v_n = row_count; raise notice 'rollback 3b1e6f0a: %', v_n;

  update public.tasks
     set parts = jsonb_set(parts, '{1,prompt}', to_jsonb('Wie viele Gigabyte wurden genutzt?'::text))
   where id = '4f0b933d-3ead-4042-adb9-a1369ba28f39'
     and parts -> 1 ->> 'prompt' = 'Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?';
  get diagnostics v_n = row_count; raise notice 'rollback 4f0b933d: %', v_n;

  update public.tasks
     set question = E'Löse die Gleichung. Gib den Wert für x an.\n\n2x + 4 = 20',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Löse die Gleichung. Gib den Wert für x an.\n\n2x + 4 = 20'::text))
   where id = 'e8348c89-67cb-4650-be91-235e69321776' and question = E'Löse die Gleichung.\n\n2x + 4 = 20';
  get diagnostics v_n = row_count; raise notice 'rollback e8348c89: %', v_n;

  update public.tasks
     set question = E'Löse die Gleichung. Gib den Wert für x an.\n\n3x + 6 = 24',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Löse die Gleichung. Gib den Wert für x an.\n\n3x + 6 = 24'::text))
   where id = '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992' and question = E'Löse die Gleichung.\n\n3x + 6 = 24';
  get diagnostics v_n = row_count; raise notice 'rollback 7976c81f: %', v_n;
end $r$;
