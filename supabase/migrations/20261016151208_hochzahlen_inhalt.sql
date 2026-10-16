-- Hochzahlen im Aufgabentext als Hochzeichen statt "^" (15 Pilot-Aufgaben, Knoten potenzen)
--
-- Das Tablet (edvance-app, Buehne.tsx) zeigt den Aufgabentext als reinen Text. "-2^2" stand dort genau so; Kinder in
-- Klasse 5-8 kennen "^" oft nicht, die Aufgabe misst dann die Schreibweise statt der Fertigkeit.
--
-- Geaendert wird nur der Aufgabentext: tasks.question (daraus baut lsa_question_payload prompt/stem) und die Kopie in
-- question_payload.prompt, wenn sie denselben Text traegt. Teilaufgaben, MC-Optionen, Musterloesungen und Hinweise
-- enthalten im Pilot kein "^" (geprueft per dbread, 16.10.2026). correct_answers und acceptance bleiben unberuehrt.
--
-- Je Aufgabe gezielt per id und mit dem Vorher-Text in der WHERE-Bedingung: Hat sich der Text inzwischen geaendert
-- (oder laeuft die Migration ein zweites Mal), aendert sie nichts. Status, reviewed_*, Pruefstatus (task_pruefungen)
-- und Ausgangsfassung (task_pruefung_ausgang) bleiben; pruef_version zaehlt per Trigger hoch.
--
-- Minus bleibt "-": potenzen und die uebrigen Knoten bis Klasse 8 schreiben im Pilot durchgehend "-" (48 Aufgaben mit
-- "-", 17 mit "−", diese nur in quadratischen Gleichungen und einer Wurzelaufgabe).
--
-- Ausgelassen: 5c73a51d (2^5). Die Schrift des Aufgabentexts auf dem Tablet (Fraunces 500) hat kein Zeichen fuer ⁵,
-- das iPad setzte es in einer Ersatzschrift.
--
-- Hinweis: lsa_ziffernfolge zaehlt "²" nicht als Ziffer ("-2^2" → {2,2}, "-2²" → {2}). Das betrifft nur
-- tasks_zahlen_guard, der fuer current_user = 'authenticated' greift; diese Migration laeuft als postgres.

begin;

with v(id, alt, neu) as (values
  ('855d22d3-4995-4497-a69a-6b89bcb097e5'::uuid, E'Berechne.\n\n(-2)^3 = ?', E'Berechne.\n\n(-2)³ = ?'),
  ('89ad1d12-b903-4411-a066-76e8b68ddcac'::uuid, E'Berechne.\n\n(-3)^2 = ?', E'Berechne.\n\n(-3)² = ?'),
  ('e5da9c79-e34a-42f9-bc85-0e135ff90987'::uuid, E'Berechne.\n\n(-3)^3 = ?', E'Berechne.\n\n(-3)³ = ?'),
  ('e7c7b1c6-85c0-4592-8996-d9310332ce17'::uuid, E'Berechne.\n\n(-4)^2 = ?', E'Berechne.\n\n(-4)² = ?'),
  ('796659c3-7b6f-4ccb-a7b1-144eab486c5c'::uuid, E'Berechne.\n\n(-5)^2 = ?', E'Berechne.\n\n(-5)² = ?'),
  ('a3343b39-bedb-491f-a214-6b6817ce2768'::uuid, E'Berechne.\n\n-2^2 = ?', E'Berechne.\n\n-2² = ?'),
  ('83839a0b-e05e-4ef5-a18b-4afde56e3752'::uuid, E'Berechne.\n\n10^2 = ?', E'Berechne.\n\n10² = ?'),
  ('db07cb07-f719-4c8b-9e23-614902c6a7a4'::uuid, E'Berechne.\n\n2^3 = ?', E'Berechne.\n\n2³ = ?'),
  ('01f22500-c86d-47d0-bb1d-a5f420e2de9d'::uuid, E'Berechne.\n\n3^2 = ?', E'Berechne.\n\n3² = ?'),
  ('59c982b3-47db-4d90-b0ba-5de9ff4a8cbd'::uuid, E'Berechne.\n\n3^4 = ?', E'Berechne.\n\n3⁴ = ?'),
  ('e1aeb6a9-507a-471c-92c8-98ae592162a3'::uuid, E'Berechne.\n\n4^3 = ?', E'Berechne.\n\n4³ = ?'),
  ('25539057-46a0-473c-ab73-40d1b81edd55'::uuid, E'Berechne.\n\n5^2 = ?', E'Berechne.\n\n5² = ?'),
  ('744b2ea7-ab5e-4e8f-95d2-3e029684eb9e'::uuid, E'Berechne.\n\n5^3 = ?', E'Berechne.\n\n5³ = ?'),
  ('72d61822-e5ed-49c3-8f9d-643cf94196bc'::uuid, E'Berechne.\n\n6^2 = ?', E'Berechne.\n\n6² = ?'),
  ('9ee7cbb7-5f40-4aeb-8983-ace78557d557'::uuid, E'Berechne.\n\n7^2 = ?', E'Berechne.\n\n7² = ?')

), u as (
  update public.tasks t
     set question = v.neu,
         question_payload = case when t.question_payload ->> 'prompt' = v.alt
                                 then jsonb_set(t.question_payload, '{prompt}', to_jsonb(v.neu))
                                 else t.question_payload end
    from v
   where t.id = v.id
     and t.question = v.alt
  returning t.id
)
select format('hochzahlen: %s Aufgabentexte umgestellt', count(*)) as hochzahlen from u;

commit;
