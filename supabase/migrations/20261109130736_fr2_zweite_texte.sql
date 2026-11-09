-- FR-2 F4.2 (09.11.2026): je eine neue LSA-Aufgabe mit anderem Aufgabentext für die sieben Skills, denen auch mit allen
-- Entwürfen ein zweiter Textschlüssel fehlt (Bericht Q27): bruch_add, bruch_dezimal, bruch_kuerzen, bruch_mult,
-- gleichung_beidseitig, gleichung_neg_koeffizient, term_minusklammer. Beschreibung und Prüfung:
-- docs/freigabe/fr2/neue-aufgaben.md.
--
-- Schreibweisen: alles, was lsa_grade voll wertet, steht auch in correct_answers (lsa_is_correct), z. B. „+4“, „6+3x“,
-- „7 / 12“ (geprüft: docs/freigabe/fr2/neue-aufgaben.md).
-- Andere Formulierung bzw. Darstellung (Sachaufgabe, Zahlenrätsel, Gleichung mit x rechts), nicht nur andere Zahlen,
-- damit lsa_text_schluessel (Zahlen → #) einen neuen Schlüssel liefert. Ohne MC, AFB I–II, Lösung in allen
-- Schreibweisen, Fehlbilder aus fehlbild_labels wie bei den Geschwistern, sondierrang 3 (1 und 2 sind vergeben).
-- Status draft, Pool lsa: Lena prüft sie in „Gezielt prüfen“, freigeben nur Admins (nie ready hier).
-- Cluster und Kompetenz wie die Geschwister (source_ref in der Liste). Muster: 20261025213530_term_ausklammern_ohne_mc.
-- Idempotent (feste ids); ohne Skill oder Geschwister (CI-Neuaufbau) übersprungen.
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261109130736_fr2_zweite_texte.sql

create temp table fr2_neu (
  id uuid primary key, skill_key text, geschwister text, source_ref text, title text, question text, input_type text,
  bruch boolean, afb text, curriculum_grade int, est_duration_sec int, correct_answers jsonb, acceptance jsonb,
  solution text
);  -- ohne „on commit drop“: CI spielt ohne -1 ein (jede Anweisung eigene Transaktion); am Ende entfernt

insert into fr2_neu values
  ('6b363dac-a30c-4a2f-8fa0-b7814353d1f2', 'bruch_add', 'brueche-addieren-04', 'brueche-addieren-08',
   'Brüche · Addieren · Sachaufgabe Pizza',
   E'Lea isst 1/4 einer Pizza, Tom isst 1/3 derselben Pizza.\nWelcher Anteil der Pizza ist zusammen gegessen? Gib den Anteil als vollständig gekürzten Bruch an.',
   'NUMERIC', true, 'II', 6, 90, '["7/12", "7 / 12"]',
   '{"canonical": "7/12", "require_reduced": true, "known_errors": {"2/7": "nenner_addiert", "2/12": "zaehler_nicht_erweitert"}}',
   E'1/4 + 1/3 = 3/12 + 4/12 = 7/12. 7/12 lässt sich nicht weiter kürzen.'),
  ('b65bad4b-a8dd-4cee-8b9e-7716f5c786c0', 'bruch_dezimal', 'dezimal-umwandeln-03', 'dezimal-umwandeln-07',
   'Dezimalzahlen · Bruch umwandeln · Sachaufgabe Glas',
   E'Ein Glas ist zu 2/5 mit Saft gefüllt.\nGib diesen Anteil als Dezimalzahl an.',
   'NUMERIC', null, 'I', 6, 60, '["0,4", "0.4", "0,40"]',
   '{"canonical": "0,4", "known_errors": {"2,5": "umgekehrt_geteilt", "0,25": "ziffern_gelesen"}}',
   E'2/5 = 4/10 = 0,4.'),
  ('3b64f242-c2ab-4f18-8af4-a72dc185cf10', 'bruch_kuerzen', 'brueche-kuerzen-07', 'brueche-kuerzen-08',
   'Brüche · Kürzen · Sachaufgabe Fahrrad',
   E'In einer Klasse mit 24 Kindern fahren 18 mit dem Fahrrad zur Schule.\nWelcher Anteil der Klasse ist das? Gib den Anteil als vollständig gekürzten Bruch an.',
   'NUMERIC', true, 'II', 6, 90, '["3/4", "3 / 4"]',
   '{"canonical": "3/4", "require_reduced": true, "known_errors": {"9/12": "teilgekuerzt", "6/8": "teilgekuerzt"}}',
   E'18 von 24 sind 18/24. Gekürzt mit 6: 18/24 = 3/4.'),
  ('fa8c52a4-161c-4bd4-9174-b98091ceb608', 'bruch_mult', 'brueche-multiplizieren-02', 'brueche-multiplizieren-08',
   'Brüche · Multiplizieren · Sachaufgabe Holzleiste',
   E'Von einer 5/6 m langen Holzleiste werden 3/5 abgesägt.\nWie viele Meter sind das? Gib das Ergebnis als vollständig gekürzten Bruch an.',
   'NUMERIC', true, 'II', 6, 90, '["1/2", "1 / 2"]',
   '{"canonical": "1/2", "require_reduced": true, "known_errors": {"15/30": "teilgekuerzt", "3/6": "teilgekuerzt", "43/30": "hauptnenner_bei_mult"}}',
   E'3/5 von 5/6 m: 3/5 · 5/6 = 15/30 = 1/2. Es sind 1/2 m.'),
  ('300b2a89-6f7f-4022-8a61-9a9d040fadd3', 'gleichung_beidseitig', 'gleichung-beidseitig-02', 'gleichung-beidseitig-06',
   'Gleichungen · Variable beidseitig · Zahlenrätsel',
   E'Denk dir eine Zahl. Nimmst du sie 5-mal und addierst 3, kommt dasselbe heraus, wie wenn du sie 2-mal nimmst und 15 addierst.\nWie heißt die Zahl?',
   'NUMERIC', null, 'II', 7, 90, '["4", "+4"]',
   '{"canonical": "4", "equivalents": ["+4"], "known_errors": {"6": "falsches_vorzeichen_beim_zusammenfuehren"}}',
   E'5x + 3 = 2x + 15 | − 2x − 3 ergibt 3x = 12, also x = 4. Probe: 5 · 4 + 3 = 23 = 2 · 4 + 15.'),
  ('ab6509f0-c7c8-4c7b-b2f7-b65d12b23a8a', 'gleichung_neg_koeffizient', 'gleichung-negativ-02', 'gleichung-negativ-06',
   'Gleichungen · Negativer Koeffizient · x rechts',
   E'Für welche Zahl x stimmt die Gleichung?\n\n20 = 32 − 4x',
   'NUMERIC', null, 'I', 7, 60, '["3", "+3"]',
   '{"canonical": "3", "equivalents": ["+3"], "known_errors": {"-3": "vorzeichen_beim_umstellen", "12": "division_vergessen"}}',
   E'20 = 32 − 4x | − 32 ergibt −12 = −4x, also x = 3. Probe: 32 − 4 · 3 = 20.'),
  ('dc412552-d604-4f43-b7f5-3f991a7b740e', 'term_minusklammer', 'term-minusklammer-01', 'term-minusklammer-07',
   'Terme · Minusklammer · vereinfachen',
   E'Vereinfache so weit wie möglich und schreibe das Ergebnis in der Form ax + b.\n\n4x - (x - 6)',
   'TERM', null, 'I', 7, 60, '["3x+6", "6+3x"]', null,
   E'Das Minus vor der Klammer dreht beide Vorzeichen: 4x − x + 6 = 3x + 6.');

insert into public.tasks (
  id, content_type, title, question, question_payload, input_type, skill_key, bruch,
  class_level, curriculum_grade, cluster_id, competency_id, afb, competency_content, competency_process,
  estimated_minutes, est_duration_sec, needs_image, status, source, source_ref, sondierrang,
  is_diagnostic, is_active, dialog_enabled, is_tutorial, parts, assets, einsatz, pruef_pilot)
select n.id, 'exercise', n.title, n.question, null, n.input_type, n.skill_key, n.bruch,
       null, n.curriculum_grade, g.cluster_id, g.competency_id, n.afb, g.competency_content, g.competency_process,
       3, n.est_duration_sec, false, 'draft', 'edvance_fundament', n.source_ref, 3,
       false, true, false, false, '[]'::jsonb, '[]'::jsonb, '{lsa}'::text[], true
  from fr2_neu n
  join public.tasks g on g.source_ref = n.geschwister and g.skill_key = n.skill_key
 where exists (select 1 from public.skills s where s.skill_key = n.skill_key)
on conflict do nothing;

do $loesung$
declare
  n record;
begin
  perform set_config('request.jwt.claim.role', 'service_role', true);
  for n in select f.* from fr2_neu f
            where exists (select 1 from public.tasks t where t.id = f.id)
              and not exists (select 1 from public.task_solutions s where s.task_id = f.id) loop
    perform public.task_solution_upsert(
      p_task_id => n.id, p_correct_answers => n.correct_answers, p_solution => n.solution, p_hints => '[]'::jsonb,
      p_coach_hints => '[]'::jsonb, p_typical_errors => '[]'::jsonb, p_beleg => null, p_acceptance => n.acceptance,
      p_option_scores => null);
  end loop;
end
$loesung$;

drop table fr2_neu;
