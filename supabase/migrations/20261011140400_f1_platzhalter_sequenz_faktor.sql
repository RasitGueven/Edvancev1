-- F1.5 Platzhalter-Erklaersequenz fuer das Szenario Batu (Paket F1, Umfang B4; docs/szenario/batu.md).
--
-- Fuer den ersten offenen Ziel-Skill der ersten Session (gleichung_quadr_faktor, Thema Quadratische Gleichungen)
-- gibt es noch keine Erklaersequenz. Damit der Ablauf Erklaerung -> Loesungsbeispiel -> Aufgabe im Testlauf
-- durchgespielt werden kann, steht hier eine erkennbare Platzhalter-Sequenz: eine Kernidee, ein Erklaerschritt,
-- ein Loesungsbeispiel (Variante A) und ein Check (eigene Check-Aufgabe, draft, Einsatz {check}).
--
-- Alles Entwurf: Kernidee und Schritte status 'entwurf', quelle 'ki'; nichts wird freigegeben. erklaer_start
-- liefert Entwuerfe nur im Testlauf (Entscheidung 27, 20261008124414_a2_erklaer_testlauf.sql), sonst nichts.
-- Die Texte beginnen mit „Platzhalter“ und sind kein Lerninhalt. Ersetzen: durch eine echte Sequenz (Inhaltspflege),
-- danach diese Zeilen loeschen (ids unten).
--
-- Loesung ueber public.task_solution_upsert als transaktionslokaler Systemaufruf (wie E2b, 20261010132749).
-- cluster_id per Unterabfrage auf die feste Prod-id der Aufgaben dieses Skills; im CI-Neuaufbau bleibt sie null.
-- Ohne den Skill (fremde Datenbank) faellt alles weg: jede Zeile haengt an exists(skill).
-- Idempotent (on conflict do nothing). Kein begin/commit: mig klammert mit psql -1, die CI ohne.

insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key,
  class_level, curriculum_grade, cluster_id, afb, competency_content, competency_process,
  est_duration_sec, needs_image, status, source, source_ref,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz)
select
  'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid, 'exercise', 'Platzhalter-Check · Nullprodukt',
  'Platzhalter-Check (kein Lerninhalt): Löse x · (x − 3) = 0. Gib die größere Lösung an.',
  '{"kind":"short_input","prompt":"Platzhalter-Check (kein Lerninhalt): Löse x · (x − 3) = 0. Gib die größere Lösung an."}'::jsonb,
  'NUMERIC', 'gleichung_quadr_faktor', null, 9,
  (select c.id from public.skill_clusters c where c.id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'::uuid),
  'I', 'gleichungen', 'Operieren', 45, false, 'draft', 'edvance_f1_platzhalter', 'f1-platzhalter-faktor-c1',
  false, true, false, false, '[]'::jsonb, '[]'::jsonb, '{check}'::text[]
 where exists (select 1 from public.skills s where s.skill_key = 'gleichung_quadr_faktor')
on conflict do nothing;

do $loesung$
begin
  if exists (select 1 from public.tasks t where t.id = 'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid
              and t.source = 'edvance_f1_platzhalter')
     and not exists (select 1 from public.task_solutions s where s.task_id = 'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid) then
    perform set_config('request.jwt.claim.role', 'service_role', true);
    perform public.task_solution_upsert(
      p_task_id         => 'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid,
      p_correct_answers => '["3","+3"]'::jsonb,
      p_solution        => 'Platzhalter: Ein Produkt ist null, wenn ein Faktor null ist. x = 0 oder x − 3 = 0, also x = 3.',
      p_hints           => '[]'::jsonb,
      p_coach_hints     => '[]'::jsonb,
      p_typical_errors  => '[]'::jsonb,
      p_acceptance      => '{"canonical":"3","known_errors":{"-3":"vorzeichen_ignoriert","−3":"vorzeichen_ignoriert"}}'::jsonb);
  end if;
end
$loesung$;

insert into public.erklaer_kernidee (id, skill_key, nr, titel, status, quelle)
select 'e7dce277-0337-41fc-a31d-fd71172c0ac8'::uuid, 'gleichung_quadr_faktor', 1,
       'Platzhalter: Quadratische Gleichungen durch Ausklammern (Nullprodukt)', 'entwurf', 'ki'
 where exists (select 1 from public.skills s where s.skill_key = 'gleichung_quadr_faktor')
on conflict do nothing;

insert into public.erklaer_schritt (id, kernidee_id, variante, art, inhalt, bild, fehlbild_slugs, status)
select v.id, 'e7dce277-0337-41fc-a31d-fd71172c0ac8'::uuid, 'A', v.art, v.inhalt, null, '{}'::text[], 'entwurf'
  from (values
    ('151258bb-7eb4-4456-a5ca-033694452697'::uuid, 'erklaerung',
     '# Platzhalter: Erklärschritt

Dieser Text ist ein Platzhalter für den Testlauf und kein Lerninhalt.

Hier steht später die Kernidee: Ein Produkt ist null, wenn einer der Faktoren null ist.'),
    ('7d7b0e1e-8f52-4839-a986-418202bda036'::uuid, 'beispiel',
     '# Platzhalter: Lösungsbeispiel

1. Platzhalter: x² − 4x = 0 ausklammern: x · (x − 4) = 0.
2. Platzhalter: x = 0 oder x − 4 = 0.
3. Platzhalter: Lösungen 0 und 4.')
  ) v(id, art, inhalt)
 where exists (select 1 from public.erklaer_kernidee k where k.id = 'e7dce277-0337-41fc-a31d-fd71172c0ac8'::uuid)
on conflict do nothing;

insert into public.erklaer_check (kernidee_id, task_id, reihenfolge)
select 'e7dce277-0337-41fc-a31d-fd71172c0ac8'::uuid, 'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid, 1
 where exists (select 1 from public.erklaer_kernidee k where k.id = 'e7dce277-0337-41fc-a31d-fd71172c0ac8'::uuid)
   and exists (select 1 from public.tasks t where t.id = 'a368a0d0-25fd-4cc9-a873-541afbb9e864'::uuid)
on conflict do nothing;
