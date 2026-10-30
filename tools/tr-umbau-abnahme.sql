-- Abnahme TR-Umbau (nur lesen): ~/bin/dbread -f tools/tr-umbau-abnahme.sql
-- Erwartet je eingespielter Aufgabe: MULTI_PART, review, format/gate in Ordnung, nicht im Pool, sammel f. Keine ready.
\pset pager off
select v.id, t.input_type, t.status, jsonb_array_length(t.parts) teile,
       public.lsa_eingabeformat_eindeutig(t.input_type, t.bruch, t.unit, t.parts, s.correct_answers) format,
       public.freigabe_gate_fehler(t.id) gate, public.lsa_im_pool(t.id) pool, public.pruef_freigabe_erlaubt(t.id) sammel
  from unnest(array['88ca2551-82bf-4ca3-b971-32cd4292a146', '7e027634-1c45-4c70-8357-198dad0f1797',
                    '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13', '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24',
                    '21427340-fc85-41c4-abea-99ad0121b83c', 'ad08897e-a44b-43fb-a779-96b889c069db',
                    '0bcc83c8-42f0-4956-b1d0-00446cb6e5e2', 'df6b2bcd-8643-46b2-9553-db75854b597d',
                    '1dece473-758d-4108-9969-02b495dbf4ed']::uuid[]) v(id)
  join public.tasks t on t.id = v.id join public.task_solutions s on s.task_id = t.id
 order by t.status, t.skill_key;
select t.skill_key, count(*) filter (where public.lsa_im_pool(t.id)) im_pool
  from public.tasks t where t.skill_key like 'zahl_wurzel%' or t.skill_key like 'term_binom%'
 group by 1 order by 2, 1;
