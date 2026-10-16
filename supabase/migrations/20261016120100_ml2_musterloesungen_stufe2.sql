-- ML2: Musterlösungen für fünf Knoten aus Stufe 2 von Batus LSA und Klartext für das Fehlbild teilgekuerzt.
--
-- Laut docs/themen/pruefung-batu-inhalte.md (Stand 16.10.) fehlen in bruch_dezimal (6), vorzeichen_mult_div (7),
-- bruch_kuerzen (7), vorzeichen_add_sub (7) und dezimal_mult (7 von 9) die Musterlösungen; Lena kann diese
-- Aufgaben so nicht freigeben. Die 34 Texte folgen den vorhandenen Lösungen derselben Stufe (dezimal_div,
-- dezimal_add_sub, runden_ueberschlag): kurze Schritte, Dezimalkomma, "-" als Minus, Ende beim Ergebnis.
-- Jedes Endergebnis ist maschinell gegen correct_answers nachgerechnet und von pruef_auffaelligkeiten ohne Befund.
--
-- 1. task_solutions.solution nur dort, wo sie heute leer ist (NULL oder nur Leerraum), und nur an Pilot-Aufgaben
--    im Status draft mit dem erwarteten skill_key. Antworten, Akzeptanz, Hinweise und Status bleiben unberührt.
-- 2. fehlbild_labels.teilgekuerzt bekommt Klartext und freigegeben_am, beides nur, wenn es noch leer ist.
--    freigegeben_von bleibt leer (Migration, keine Person).
-- Idempotent; in der CI ohne diese Aufgaben ein No-op. Kein begin/commit: mig klammert mit psql -1.

do $ml2$
declare
  v_n integer;
begin
  update public.task_solutions s
     set solution = v.sol, updated_at = now()
    from (values
    ('3768ecdc-2c2e-4076-b6ff-556906e5cbfe'::uuid, 'bruch_dezimal', E'1/5 auf den Nenner 10 erweitern (Zähler und Nenner mal 2):\n1/5 = 2/10 = 0,2.'),
    ('6bdc7d4e-d6a2-494e-8649-02839c5a3bda'::uuid, 'bruch_dezimal', E'1/8 auf den Nenner 1000 erweitern (Zähler und Nenner mal 125):\n1/8 = 125/1000 = 0,125.'),
    ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f'::uuid, 'bruch_dezimal', E'3/4 auf den Nenner 100 erweitern (Zähler und Nenner mal 25):\n3/4 = 75/100 = 0,75.'),
    ('80105584-06dd-4fc9-b481-ec047c7cb343'::uuid, 'bruch_dezimal', E'1/4 auf den Nenner 100 erweitern (Zähler und Nenner mal 25):\n1/4 = 25/100 = 0,25.'),
    ('8ea44368-dbbd-45b4-86c5-729c90b93498'::uuid, 'bruch_dezimal', E'3/8 auf den Nenner 1000 erweitern (Zähler und Nenner mal 125):\n3/8 = 375/1000 = 0,375.'),
    ('de2aabbf-8988-47d4-9f51-c4e80232b374'::uuid, 'bruch_dezimal', E'1/2 auf den Nenner 10 erweitern (Zähler und Nenner mal 5):\n1/2 = 5/10 = 0,5.'),
    ('1244b84c-781d-47cb-8c73-eaa5543b1ce0'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 18 und 24 beide teilbar sind, ist 6.\nZähler und Nenner durch 6 teilen: 18/24 = 3/4.'),
    ('2e40939a-e791-4615-8813-79812e1faa2c'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 12 und 18 beide teilbar sind, ist 6.\nZähler und Nenner durch 6 teilen: 12/18 = 2/3.'),
    ('41004d1a-6ab3-4556-a1a2-778ea2450471'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 12 und 16 beide teilbar sind, ist 4.\nZähler und Nenner durch 4 teilen: 12/16 = 3/4.'),
    ('9a6bf378-2cd4-4ca5-afeb-bb856d5853f8'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 8 und 12 beide teilbar sind, ist 4.\nZähler und Nenner durch 4 teilen: 8/12 = 2/3.'),
    ('9a70682a-428d-4b75-8567-e5d9f7cb607e'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 4 und 12 beide teilbar sind, ist 4.\nZähler und Nenner durch 4 teilen: 4/12 = 1/3.'),
    ('b7fbaaca-e478-4aeb-b9d1-c637494234d8'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 20 und 24 beide teilbar sind, ist 4.\nZähler und Nenner durch 4 teilen: 20/24 = 5/6.'),
    ('bba44bae-beda-4a25-8fdc-e7a303e991c8'::uuid, 'bruch_kuerzen', E'Die größte Zahl, durch die 16 und 24 beide teilbar sind, ist 8.\nZähler und Nenner durch 8 teilen: 16/24 = 2/3.'),
    ('0cbaacfd-cf96-40a7-a896-c198e67531fa'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 6 · 4 = 24.\n0,6 und 0,4 haben zusammen zwei Nachkommastellen, also 0,6 · 0,4 = 0,24.'),
    ('1983282b-8a5d-437f-a7dc-d8695f8a3496'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 5 · 6 = 30.\n0,5 und 0,6 haben zusammen zwei Nachkommastellen, also 0,5 · 0,6 = 0,30 = 0,3.'),
    ('24310ee2-1688-4504-a72b-5e1fa7cab2dc'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 8 · 5 = 40.\n0,8 und 0,5 haben zusammen zwei Nachkommastellen, also 0,8 · 0,5 = 0,40 = 0,4.'),
    ('3038721a-abdd-4030-b683-33b3e8d3efb9'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 3 · 4 = 12.\n0,3 und 0,4 haben zusammen zwei Nachkommastellen, also 0,3 · 0,4 = 0,12.'),
    ('3d066cef-b5e1-45db-b560-dd86d1c5b38c'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 2 · 7 = 14.\n0,2 und 0,7 haben zusammen zwei Nachkommastellen, also 0,2 · 0,7 = 0,14.'),
    ('d183eca3-c7af-4e26-9c7a-e8dd69937346'::uuid, 'dezimal_mult', E'Ohne Komma rechnen: 9 · 3 = 27.\n0,9 und 0,3 haben zusammen zwei Nachkommastellen, also 0,9 · 0,3 = 0,27.'),
    ('e8e6eeb7-115f-40a1-ade1-4d4aa67a97a3'::uuid, 'dezimal_mult', E'2,40 € sind 2,4 €. Ohne Komma rechnen: 24 · 15 = 360.\n2,4 und 1,5 haben zusammen zwei Nachkommastellen, also 2,4 · 1,5 = 3,60.\nYusuf zahlt 3,60 €.'),
    ('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von -4 aus 9 Schritte nach rechts: 4 Schritte bis 0, dann noch 5 weiter.\n-4 + 9 = 5.'),
    ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von -6 aus 2 Schritte nach links, also weiter weg von 0.\n-6 - 2 = -8.'),
    ('3b44eada-3589-4bdb-a33b-2fb2ca0a1726'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von -9 aus 5 Schritte nach rechts: bis 0 wären es 9 Schritte, es fehlen also noch 4.\n-9 + 5 = -4.'),
    ('3e6fb055-111e-4888-9177-d2b17dd0fc54'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von 2 aus 9 Schritte nach links: 2 Schritte bis 0, dann noch 7 weiter.\n2 - 9 = -7.'),
    ('738de19f-d3c9-43a0-b5ce-af6e30752c75'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von 3 aus 8 Schritte nach links: 3 Schritte bis 0, dann noch 5 weiter.\n3 - 8 = -5.'),
    ('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von -7 aus 4 Schritte nach rechts: bis 0 wären es 7 Schritte, es fehlen also noch 3.\n-7 + 4 = -3.'),
    ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf'::uuid, 'vorzeichen_add_sub', E'Auf dem Zahlenstrahl von -3 aus 5 Schritte nach links, also weiter weg von 0.\n-3 - 5 = -8.'),
    ('0438a9f9-bdb4-4f29-ab59-adc7946ade36'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 3 · 5 = 15.\nVorzeichen: minus mal plus ergibt minus.\n-3 · 5 = -15.'),
    ('2e8ce53f-1357-48b2-8d76-0633ae836980'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 4 · 6 = 24.\nVorzeichen: minus mal minus ergibt plus.\n-4 · (-6) = 24.'),
    ('38aa9504-bb48-4b1c-98e7-85d38de70108'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 20 : 4 = 5.\nVorzeichen: minus geteilt durch plus ergibt minus.\n-20 : 4 = -5.'),
    ('751f9c63-c295-4b9e-8202-6244c6fd8f05'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 24 : 4 = 6.\nVorzeichen: plus geteilt durch minus ergibt minus.\n24 : (-4) = -6.'),
    ('7db70449-d6fa-47dd-9423-1e8c75ce8c8f'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 36 : 6 = 6.\nVorzeichen: minus geteilt durch minus ergibt plus.\n-36 : (-6) = 6.'),
    ('ba0701ff-bac1-4ae6-a6f4-b5f610a35ee7'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 7 · 3 = 21.\nVorzeichen: plus mal minus ergibt minus.\n7 · (-3) = -21.'),
    ('e58cb290-db86-40df-b60b-03aee393107b'::uuid, 'vorzeichen_mult_div', E'Ohne Vorzeichen: 8 · 3 = 24.\nVorzeichen: minus mal minus ergibt plus.\n-8 · (-3) = 24.')
         ) v(id, skill_key, sol), public.tasks t
   where s.task_id = v.id and t.id = v.id
     and t.skill_key = v.skill_key and t.pruef_pilot and t.status = 'draft'
     and nullif(btrim(coalesce(s.solution, '')), '') is null;
  get diagnostics v_n = row_count;
  raise notice 'ml2_m1: % Musterlösung(en) gesetzt', v_n;

  update public.fehlbild_labels
     set klartext = 'Kürzt nicht vollständig, Zähler und Nenner haben noch einen gemeinsamen Teiler.',
         freigegeben_am = coalesce(freigegeben_am, now())
   where slug = 'teilgekuerzt'
     and nullif(btrim(coalesce(klartext, '')), '') is null;
  get diagnostics v_n = row_count;
  raise notice 'ml2_m1: teilgekuerzt Klartext gesetzt, % Zeile(n)', v_n;
end $ml2$;
