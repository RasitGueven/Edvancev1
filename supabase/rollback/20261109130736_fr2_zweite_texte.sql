-- Rollback zu 20261109130736_fr2_zweite_texte: die sieben neuen Entwürfe wieder entfernen, nur solange sie unberührt
-- sind (Status draft, ohne Prüfentscheidung). Danach die Version aus supabase_migrations.schema_migrations löschen.
-- Geprüfte oder freigegebene Aufgaben bleiben stehen (append-only Prüfprotokoll); dann von Hand entscheiden.
delete from public.task_solutions
 where task_id in ('6b363dac-a30c-4a2f-8fa0-b7814353d1f2','b65bad4b-a8dd-4cee-8b9e-7716f5c786c0','3b64f242-c2ab-4f18-8af4-a72dc185cf10','fa8c52a4-161c-4bd4-9174-b98091ceb608','300b2a89-6f7f-4022-8a61-9a9d040fadd3','ab6509f0-c7c8-4c7b-b2f7-b65d12b23a8a','dc412552-d604-4f43-b7f5-3f991a7b740e')
   and task_id in (select t.id from public.tasks t where t.status = 'draft'
                     and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id));
delete from public.tasks t
 where t.id in ('6b363dac-a30c-4a2f-8fa0-b7814353d1f2','b65bad4b-a8dd-4cee-8b9e-7716f5c786c0','3b64f242-c2ab-4f18-8af4-a72dc185cf10','fa8c52a4-161c-4bd4-9174-b98091ceb608','300b2a89-6f7f-4022-8a61-9a9d040fadd3','ab6509f0-c7c8-4c7b-b2f7-b65d12b23a8a','dc412552-d604-4f43-b7f5-3f991a7b740e') and t.status = 'draft'
   and not exists (select 1 from public.task_pruefungen p where p.task_id = t.id);
