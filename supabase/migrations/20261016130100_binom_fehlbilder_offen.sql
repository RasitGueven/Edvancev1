-- Binomische Formeln (Stufe 3): Fehlbild je MC-Ablenker, je eine offene Aufgabe für term_binom_gemischt und
-- term_binom_quadrat. Erzeugt von tools/binom-rechencheck.py (dort Rechen-Check mit sympy) — nicht von Hand editieren.
--
-- Mechanismus: pruef_auffaelligkeiten meldet mc_ablenker_ohne_fehlbild für jede Option, deren id weder in
-- correct_answers noch als Schlüssel in acceptance.known_errors steht. Hier werden die fehlenden Options-ids als
-- Schlüssel ergänzt ({Options-id: Slug}), vorhandene Schlüssel bleiben unverändert (neu || alt, alt gewinnt).
-- Ergänzt wird nur, wenn die Option noch den Text trägt, gegen den gerechnet wurde.
--
-- Neue Slugs (binom_formel_verwechselt, mischglieder_nicht_aufgehoben, faktor_nicht_quadriert) mit Klartext, nicht freigegeben.
-- Neue Aufgaben: status draft, pruef_pilot, einsatz lsa, ohne Hinweise. Lösung über task_solution_upsert als
-- Systemaufruf (transaktionslokal). Fehlen Knoten oder Aufgaben (CI-Neuaufbau), passiert nichts.
-- Kein begin/commit: mig klammert mit psql -1.

insert into public.fehlbild_labels (slug, familie, klartext, erklaerung)
values
  ('binom_formel_verwechselt', 'gleichungen_umformen', 'Verwechselt die binomischen Formeln, etwa (a − b)² statt (a + b)² oder (a + b)(a − b) statt (a + b)².',
   'Die drei binomischen Formeln unterscheiden sich nur in den Vorzeichen. Wer sie verwechselt, bekommt beim Mischglied 2ab das falsche Vorzeichen oder lässt es ganz weg. Geübt wird, vor dem Rechnen zu bestimmen, welche der drei Formen vorliegt.'),
  ('mischglieder_nicht_aufgehoben', 'gleichungen_umformen', 'Multipliziert (a + b)(a − b) aus, lässt die Mischglieder aber stehen, statt dass sie sich aufheben: (x + 4)(x − 4) = x² − 8x − 16.',
   'Beim Ausmultiplizieren von (a + b)(a − b) entstehen +ab und −ab; zusammen ergeben sie null. Wer beide Mischglieder mit Minus schreibt oder nur eines streicht, behält ein x-Glied, das nicht dorthin gehört. Geübt wird, alle vier Teilprodukte hinzuschreiben und erst dann zusammenzufassen.'),
  ('faktor_nicht_quadriert', 'potenzen_wurzeln', 'Quadriert bei (2x)² nur das x, nicht den Faktor davor: 2x² statt 4x².',
   'Das Quadrat einer Klammer wie (2x) betrifft jeden Faktor darin: (2x)² = 2² · x² = 4x². Wer nur x quadriert, behält den Faktor 2 statt 4. Geübt wird, den Faktor vor dem x beim Quadrieren mitzunehmen.')
on conflict (slug) do nothing;

do $binom_a$
declare
  v_n integer;
begin
  with neu(task_id, ke, texte) as (values
  ('18dbb731-98be-4b90-a8c2-5773114de6c6'::uuid, '{"b":"halbieren_vergessen","d":"klammer_falsch_gesetzt"}'::jsonb, '{"b":"3(x + 4)²","d":"(3x + 6)²"}'::jsonb),
  ('9be9bb9c-a5b5-482e-bd76-51599553d61b'::uuid, '{"d":"wurzel_vergessen"}'::jsonb, '{"d":"(x + 25)(x - 1)"}'::jsonb),
  ('9d904128-a0ae-449c-b7de-e1c57c8238c5'::uuid, '{"c":"quadratdifferenz_vorzeichen","d":"wurzel_gliedweise"}'::jsonb, '{"c":"(x² - 4)(x² - 4)","d":"(x + 2)⁴"}'::jsonb),
  ('b2bc0cfc-d927-4a29-aca4-4686606d9466'::uuid, '{"c":"wurzel_vergessen","d":"binom_formel_verwechselt"}'::jsonb, '{"c":"(x + 16)²","d":"(x + 4)(x - 4)"}'::jsonb),
  ('e4a18d51-9545-4f17-b1aa-10dc72c35cd3'::uuid, '{"d":"klammer_falsch_gesetzt"}'::jsonb, '{"d":"(2x + 3)(2x - 3)"}'::jsonb),
  ('1c519bed-37b4-4322-9668-849b4756efcf'::uuid, '{"c":"falsches_vorzeichen_beim_zusammenfuehren","d":"falsches_vorzeichen_beim_zusammenfuehren"}'::jsonb, '{"c":"8x + 32","d":"8x - 32"}'::jsonb),
  ('79c7a940-7a41-4b6b-b4ff-ce464425c758'::uuid, '{"c":"quadrat_gliedweise","d":"falsches_vorzeichen_beim_zusammenfuehren"}'::jsonb, '{"c":"2x² - 32","d":"2x² + 4x - 40"}'::jsonb),
  ('b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261'::uuid, '{"d":"vorzeichen_ignoriert"}'::jsonb, '{"d":"2x² + 10x + 21"}'::jsonb),
  ('c31fdbb1-9a48-4cd8-9b0c-35393af84330'::uuid, '{"d":"vorzeichen_ignoriert"}'::jsonb, '{"d":"2x² + 18"}'::jsonb),
  ('dd4db5a2-2e96-4a93-b1c0-fca052b144ca'::uuid, '{"c":"klammer_vergessen","d":"falsches_vorzeichen_beim_zusammenfuehren"}'::jsonb, '{"c":"10x² - 12x + 20","d":"8x² - 12x - 20"}'::jsonb),
  ('f8364853-03fa-4d7e-807c-b0a20dbe09e3'::uuid, '{"c":"binom_formel_verwechselt","d":"klammer_vergessen"}'::jsonb, '{"c":"4x + 8","d":"2x² + 8x + 8"}'::jsonb),
  ('513d03bd-0d8d-4f0a-9e99-ea63b38b8587'::uuid, '{"c":"umfang_statt_flaeche","d":"mal_zwei_vergessen"}'::jsonb, '{"c":"4x + 16","d":"x² + 4x + 16"}'::jsonb),
  ('9a598424-963b-4981-91ad-9a81cead51f4'::uuid, '{"d":"vorzeichen_potenz"}'::jsonb, '{"d":"x² - 10x - 25"}'::jsonb),
  ('ae6fa0b8-283c-4570-b9d2-6271c17e3384'::uuid, '{"b":"mal_zwei_vergessen","d":"mal_exponent"}'::jsonb, '{"b":"x² + 3x + 9","d":"x² + 6x + 6"}'::jsonb),
  ('de60d4ff-c473-4358-b050-85a54dd903a1'::uuid, '{"c":"faktor_nicht_quadriert","d":"mal_zwei_vergessen"}'::jsonb, '{"c":"2x² + 12x + 9","d":"4x² + 6x + 9"}'::jsonb),
  ('ebd05f6f-2ab0-41ad-bac3-16c075fc2592'::uuid, '{"c":"vorzeichen_potenz"}'::jsonb, '{"c":"9x² - 24x - 16"}'::jsonb),
  ('f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa'::uuid, '{"c":"wurzel_vergessen","d":"binom_formel_verwechselt"}'::jsonb, '{"c":"(x + 100)²","d":"(x + 10)(x - 10)"}'::jsonb),
  ('113aea0a-276a-4042-b634-805ef1e11db2'::uuid, '{"d":"mischglieder_nicht_aufgehoben"}'::jsonb, '{"d":"x² - 10x - 25"}'::jsonb),
  ('293413f8-8e31-4f0b-b64e-7ac2a183606e'::uuid, '{"c":"mischglieder_nicht_aufgehoben","d":"mischglieder_nicht_aufgehoben"}'::jsonb, '{"c":"x² - 8x - 16","d":"x² - 4x - 16"}'::jsonb),
  ('94492e5a-3627-4f45-b628-41d06114a7a4'::uuid, '{"c":"faktor_nicht_quadriert","d":"mischglieder_nicht_aufgehoben"}'::jsonb, '{"c":"3x² - 25","d":"9x² - 30x - 25"}'::jsonb),
  ('d47b8793-7e82-4036-9173-d446c554b907'::uuid, '{"a":"mischglieder_nicht_aufgehoben","c":"faktor_nicht_quadriert"}'::jsonb, '{"a":"4x² - 36x - 81","c":"2x² - 81"}'::jsonb),
  ('eb3f28da-155b-49fc-aa17-1abfd882a373'::uuid, '{"b":"binom_formel_verwechselt","d":"mischglieder_nicht_aufgehoben"}'::jsonb, '{"b":"x² - 14x + 49","d":"x² - 14x - 49"}'::jsonb)
  ), passt as (
    select n.task_id, n.ke
      from neu n join public.tasks t on t.id = n.task_id
     where not exists (select 1 from jsonb_each_text(n.texte) e
                        where not exists (select 1 from jsonb_array_elements(t.question_payload -> 'options') o
                                           where o ->> 'id' = e.key and o ->> 'label' = e.value)))
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{known_errors}',
                                p.ke || coalesce(s.acceptance -> 'known_errors', '{}'::jsonb))
    from passt p
   where s.task_id = p.task_id
     and jsonb_typeof(s.acceptance) = 'object'
     and exists (select 1 from jsonb_object_keys(p.ke) k where not coalesce(s.acceptance -> 'known_errors' ? k, false));
  get diagnostics v_n = row_count;
  raise notice 'binom_a: known_errors in % Aufgabe(n) ergaenzt', v_n;
end $binom_a$;

-- binom-quadrat-07 · Zweite binomische Formel · geschicktes Rechnen · 49²
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, estimated_minutes, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot, vorbefuellt, vorbefuellt_am)
select '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'::uuid, 'exercise', 'Zweite binomische Formel · geschicktes Rechnen · 49²', 'Berechne geschickt mit einer binomischen Formel.

49² = ?', '{"kind":"short_input","prompt":"Berechne geschickt mit einer binomischen Formel.\n\n49² = ?"}'::jsonb, 'NUMERIC', 'term_binom_quadrat',
  8, 8, (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Problemlösen, Operieren',
  60, 3, null, false, null, 'draft', 'edvance_k8_binom', 'binom-quadrat-07',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb, array['lsa'], true, '{"afb":{"art":"neu","grund":"Anwenden: Quadratzahl als (50 - 1)² zerlegen und mit der zweiten binomischen Formel rechnen.","charge":"binom-session","sicher":"mittel"},"solution":{"art":"neu","grund":"Nachgerechnet (tools/binom-rechencheck.py, sympy).","charge":"binom-session","sicher":"hoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; ganze Zahl ohne Vorzeichenvarianten.","charge":"binom-session","sicher":"hoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors, je Wert ein Fehlerweg.","charge":"binom-session","sicher":"hoch"},"hints":{"art":"leer","grund":"Auftrag Binom/Session 16.10.2026: offene Aufgabe für die LSA, ohne Hinweise.","charge":"binom-session"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"binom-session","sicher":"mittel"}}'::jsonb, now()
 where exists (select 1 from public.tasks t where t.skill_key = 'term_binom_quadrat' and t.source = 'edvance_k8_binom')
on conflict do nothing;

do $neu$
begin
  if exists (select 1 from public.tasks t where t.id = '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'::uuid and t.status = 'draft')
     and not exists (select 1 from public.task_solutions s where s.task_id = '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
      p_task_id         => '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'::uuid,
      p_correct_answers => '["2401"]'::jsonb,
      p_solution        => '49² = (50 - 1)² = 50² - 2 · 50 · 1 + 1² = 2500 - 100 + 1 = 2401.',
      p_hints           => '[]'::jsonb,
      p_coach_hints     => '[]'::jsonb,
      p_typical_errors  => '[{"error":"Gliedweise quadriert, das Mischglied fehlt: 50² - 1² = 2499.","fehlbild":"quadrat_gliedweise","socratic_question":"Ist (50 - 1)² dasselbe wie 50² - 1²? Probiere es mit (3 - 1)² aus."},{"error":"Gliedweise quadriert, das Mischglied fehlt: 50² + 1² = 2501.","fehlbild":"quadrat_gliedweise","socratic_question":"Ist (50 - 1)² dasselbe wie 50² + 1²? Probiere es mit (3 - 1)² aus."},{"error":"Mischglied ohne Faktor 2: 2500 - 50 + 1 = 2451.","fehlbild":"mal_zwei_vergessen","socratic_question":"Wie heißt das mittlere Glied in (a - b)² = a² - … + b²?"},{"error":"Das letzte Glied mit Minus: 2500 - 100 - 1 = 2399.","fehlbild":"vorzeichen_potenz","socratic_question":"Kann ein Quadrat wie (-1)² negativ sein?"},{"error":"Erste statt zweiter Formel: 2500 + 100 + 1 = 2601.","fehlbild":"binom_formel_verwechselt","socratic_question":"Ist 49² größer oder kleiner als 50²?"}]'::jsonb,
      p_beleg           => null,
      p_acceptance      => '{"canonical":"2401","known_errors":{"2499":"quadrat_gliedweise","2501":"quadrat_gliedweise","2451":"mal_zwei_vergessen","2399":"vorzeichen_potenz","2601":"binom_formel_verwechselt"}}'::jsonb,
      p_option_scores   => null);
    raise notice 'binom_a: neue Aufgabe binom-quadrat-07 angelegt';
  end if;
end $neu$;

-- binom-gemischt-07 · Binomische Formeln gemischt · vereinfachen und einsetzen · x = 100
insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, estimated_minutes, unit, needs_image, sondierrang, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot, vorbefuellt, vorbefuellt_am)
select '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid, 'exercise', 'Binomische Formeln gemischt · vereinfachen und einsetzen · x = 100', 'Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.

(x + 5)² - (x + 2)(x - 2) = ?', '{"kind":"short_input","prompt":"Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?"}'::jsonb, 'NUMERIC', 'term_binom_gemischt',
  8, 8, (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'II', 'arithmetik_algebra', 'Problemlösen, Operieren',
  60, 3, null, false, null, 'draft', 'edvance_k8_binom', 'binom-gemischt-07',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb, array['lsa'], true, '{"afb":{"art":"neu","grund":"Anwenden: erste und dritte binomische Formel kombinieren, Minus vor der Klammer, dann einsetzen.","charge":"binom-session","sicher":"mittel"},"solution":{"art":"neu","grund":"Nachgerechnet (tools/binom-rechencheck.py, sympy).","charge":"binom-session","sicher":"hoch"},"correct_answers":{"art":"neu","grund":"Nachgerechnet; ganze Zahl ohne Vorzeichenvarianten.","charge":"binom-session","sicher":"hoch"},"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors, je Wert ein Fehlerweg.","charge":"binom-session","sicher":"hoch"},"hints":{"art":"leer","grund":"Auftrag Binom/Session 16.10.2026: offene Aufgabe für die LSA, ohne Hinweise.","charge":"binom-session"},"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"binom-session","sicher":"mittel"}}'::jsonb, now()
 where exists (select 1 from public.tasks t where t.skill_key = 'term_binom_gemischt' and t.source = 'edvance_k8_binom')
on conflict do nothing;

do $neu$
begin
  if exists (select 1 from public.tasks t where t.id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid and t.status = 'draft')
     and not exists (select 1 from public.task_solutions s where s.task_id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
      p_task_id         => '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'::uuid,
      p_correct_answers => '["1029"]'::jsonb,
      p_solution        => '(x + 5)² = x² + 10x + 25
(x + 2)(x - 2) = x² - 4
x² + 10x + 25 - (x² - 4) = 10x + 29
Für x = 100: 10 · 100 + 29 = 1029.',
      p_hints           => '[]'::jsonb,
      p_coach_hints     => '[]'::jsonb,
      p_typical_errors  => '[{"error":"Die Klammer x² - 4 mit falschem Vorzeichen abgezogen: 10x + 21, also 1021.","fehlbild":"quadratdifferenz_vorzeichen","socratic_question":"Was ergibt -(x² - 4), wenn du die Klammer auflöst?"},{"error":"Gliedweise quadriert: (x + 5)² = x² + 25, übrig bleibt 29.","fehlbild":"quadrat_gliedweise","socratic_question":"Ist (x + 5)² dasselbe wie x² + 25? Setze x = 1 ein und vergleiche."},{"error":"Das Minus vor dem zweiten Produkt weggelassen: 2x² + 10x + 21, also 21021.","fehlbild":"vorzeichen_ignoriert","socratic_question":"Welches Rechenzeichen steht zwischen den beiden Produkten?"}]'::jsonb,
      p_beleg           => null,
      p_acceptance      => '{"canonical":"1029","known_errors":{"1021":"quadratdifferenz_vorzeichen","29":"quadrat_gliedweise","21021":"vorzeichen_ignoriert"}}'::jsonb,
      p_option_scores   => null);
    raise notice 'binom_a: neue Aufgabe binom-gemischt-07 angelegt';
  end if;
end $neu$;
