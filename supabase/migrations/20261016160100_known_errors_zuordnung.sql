-- known_errors: falsche Antworten, die nicht zum zugeordneten Fehlbild passen (Pilot-Aufgaben, Durchsicht 16.10.).
--
-- Gefunden bei der Vorbereitung der Fehlbild-Freigabe (docs/themen/fehlbilder-freigabe.md, „Zuordnung auffällig“).
-- Geändert wird nur task_solutions.acceptance -> known_errors, und nur dort, wo der Schlüssel noch den alten Slug trägt
-- (bei MC zusätzlich nur, wenn die Option noch den erwarteten Text hat). correct_answers, Hinweise, Lösung, Status und
-- tasks bleiben unberührt.
--
--   21f1c9f4 dezimal_mult              0,25 · 12 = 3: „30“ ist nicht das Komma weggelassen (das wäre 300), sondern
--                                       zehnmal zu groß → „30“ an faktor_zehn_daneben, dazu „300“ an komma_ignoriert.
--   b2bc0cfc term_binom_faktorisieren   x² + 8x + 16 → (x + 8)²: 2ab = 8x nicht halbiert → a an halbieren_vergessen.
--   f54b2f2c term_binom_quadrat         x² + 20x + 100 → (x + 20)²: wie b2bc0cfc → a an halbieren_vergessen.
--   bb125765 potenzen                   1,05³ → 1,1025 ist 1,05², nicht vertauscht; kein passender Slug → Schlüssel entfällt.
--   88ca2551 term_binom_faktorisieren   47² − 43² → 90 ist nur 47 + 43; kein passender Slug → Schlüssel entfällt.
--   20321d30 dezimal_add_sub            3,2 − 0,85 → 2,45 ist ein Entbündelungsfehler; kein passender Slug → Schlüssel entfällt.
--
-- Die drei Aufgaben ohne passenden Slug behalten mindestens ein anderes Fehlbild (mal_exponent, quadrat_gliedweise,
-- falsche_operation). Idempotent; in der CI ohne diese Aufgaben ein No-op. Kein begin/commit: mig klammert mit psql -1.

do $kez$
declare
  v_n integer := 0;
  v_m integer;
begin
  -- 21f1c9f4: „30“ umhängen, „300“ ergänzen
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{known_errors}',
                                (s.acceptance -> 'known_errors') || '{"30": "faktor_zehn_daneben", "300": "komma_ignoriert"}'::jsonb)
   where s.task_id = '21f1c9f4-2ef0-445d-937b-73c7c5d0d606'
     and s.acceptance -> 'known_errors' ->> '30' = 'komma_ignoriert'
     and not (s.acceptance -> 'known_errors' ? '300');
  get diagnostics v_m = row_count; v_n := v_n + v_m;

  -- b2bc0cfc, f54b2f2c: Option a an halbieren_vergessen
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{known_errors,a}', '"halbieren_vergessen"'::jsonb)
    from public.tasks t, (values ('b2bc0cfc-d927-4a29-aca4-4686606d9466'::uuid, '(x + 8)²'),
                                 ('f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa'::uuid, '(x + 20)²')) v(task_id, label)
   where s.task_id = v.task_id and t.id = v.task_id
     and s.acceptance -> 'known_errors' ->> 'a' = 'quadrat_gliedweise'
     and exists (select 1 from jsonb_array_elements(t.question_payload -> 'options') o
                  where o ->> 'id' = 'a' and o ->> 'label' = v.label);
  get diagnostics v_m = row_count; v_n := v_n + v_m;

  -- bb125765, 88ca2551, 20321d30: Schlüssel ohne passenden Slug streichen
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{known_errors}', (s.acceptance -> 'known_errors') - v.keys)
    from (values ('bb125765-c709-4f59-afff-4b4bd090dbbf'::uuid, array['1,1025', '1.1025'], 'basis_exponent_vertauscht'),
                 ('88ca2551-82bf-4ca3-b971-32cd4292a146'::uuid, array['90'],               'faktorisierung_unvollstaendig'),
                 ('20321d30-58db-4218-96b3-d035bca32573'::uuid, array['2,45'],             'stellenwert_ignoriert')) v(task_id, keys, slug)
   where s.task_id = v.task_id
     and exists (select 1 from jsonb_each_text(s.acceptance -> 'known_errors') e
                  where e.key = any(v.keys) and e.value = v.slug);
  get diagnostics v_m = row_count; v_n := v_n + v_m;

  raise notice 'known_errors_zuordnung: % Aufgabe(n) geändert', v_n;
end $kez$;
