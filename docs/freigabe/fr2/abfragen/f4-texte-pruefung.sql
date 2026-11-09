-- FR-2 F4.2 Zählabfrage nach dem Einspielen (dbread). Erwartung: 7 Aufgaben, 7 mit Lösung, alle draft, Pool lsa,
-- 7 in Lenas Board (pruef_ausschluss null), 7 mit neuem Textschlüssel (kein anderer Aufgabe desselben Skills gleich).
select count(*) aufgaben,
       count(*) filter (where exists (select 1 from task_solutions s where s.task_id = t.id)) mit_loesung,
       count(*) filter (where t.status = 'draft' and t.einsatz = '{lsa}') draft_lsa,
       count(*) filter (where public.pruef_ausschluss(t.id) is null) im_board,
       count(*) filter (where not exists (select 1 from tasks o where o.skill_key = t.skill_key and o.id <> t.id
           and coalesce(lsa_text_schluessel(o.question, o.parts), o.id::text)
             = coalesce(lsa_text_schluessel(t.question, t.parts), t.id::text))) neuer_text
  from tasks t where t.id in ('6b363dac-a30c-4a2f-8fa0-b7814353d1f2','b65bad4b-a8dd-4cee-8b9e-7716f5c786c0','3b64f242-c2ab-4f18-8af4-a72dc185cf10','fa8c52a4-161c-4bd4-9174-b98091ceb608','300b2a89-6f7f-4022-8a61-9a9d040fadd3','ab6509f0-c7c8-4c7b-b2f7-b65d12b23a8a','dc412552-d604-4f43-b7f5-3f991a7b740e');
