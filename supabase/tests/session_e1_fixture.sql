-- Fixture „Steigung aus dem Graphen“ (Coach-Live-Dummy, Jonas) fuer session_e1.test.sql
-- und docs/session/e1-durchlauf.sql. Keine eigene Transaktion: der Aufrufer klammert.
--
-- Skill fkt_linear_steigung, drei Kernideen, je Variante A und B freigegeben.
--   Kernidee 1 hat zusaetzlich eine Variante C im Entwurf (Sentinel ENTWURF-E1).
--   Kernidee 2, Variante B ist fuer das Fehlbild steigung_kehrwert gedacht
--   (Δx und Δy vertauscht, wie im Dummy).
-- Ein zweiter Skill (fkt_linear_steigung_nur_entwurf) hat nur Entwuerfe.
-- Die Loesungen tragen den Sentinel LOESUNG-E1 (solution) — er darf nie in einer Antwort stehen.

\o /dev/null
\set admin_uid   'e1000000-0000-0000-0000-00000000000a'
\set coach_uid   'e1000000-0000-0000-0000-00000000000c'
\set kind_uid    'e1000000-0000-0000-0000-00000000000d'
\set session_id  'e1000000-0000-0000-0000-0000000000a1'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'admin_uid', 'e1-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'e1-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'e1-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'admin_uid', 'e1-admin@test.local', 'admin',   'E1 Admin'),
  (:'coach_uid', 'e1-coach@test.local', 'coach',   'E1 Coach'),
  (:'kind_uid',  'e1-kind@test.local',  'student', 'Jonas Vogt');
insert into students (profile_id, class_level) values (:'kind_uid', 8);

select (select id from students where profile_id = :'kind_uid') as kind_id
\gset

insert into coaching_sessions (id, coach_id, room, scheduled_at, status)
values (:'session_id', :'coach_uid', 'E1', now(), 'active');
-- Buchung ohne Vertrag nur in diesem Test: der ZG001-Trigger wird transaktionslokal abgeschaltet.
alter table session_students disable trigger session_students_zugang_trg;
insert into session_students (session_id, student_id, attendance) values (:'session_id', :'kind_id', 'present');
alter table session_students enable trigger session_students_zugang_trg;

insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe)
values ('fkt_linear_steigung_nur_entwurf', 'E1 nur Entwurf', 8, 1);

-- Drei Check-Aufgaben, freigegeben (ready). Antworten mit Fehlbild in known_errors.
-- Einsatz nur 'check' (Entscheidung 28); erklaer_checks filtert seit A2 darauf.
insert into tasks (cluster_id, content_type, input_type, status, question, afb,
                   competency_content, est_duration_sec, class_level, source, source_ref, einsatz)
select c.id, 'exercise', 'NUMERIC', 'ready', q.frage, 'I', 'Funktionen', 120, 8, 'test', q.ref, '{check}'
  from (select id from skill_clusters order by sort_order limit 1) c,
       (values ('e1-check-1', 'Die Gerade geht durch (0|0) und (1|2). Um wie viel steigt sie pro Schritt nach rechts?'),
               ('e1-check-2', 'Die Gerade geht durch (0|1) und (4|3). Bestimme die Steigung mit dem Steigungsdreieck.'),
               ('e1-check-3', 'Die Gerade geht durch (0|4) und (2|0). Bestimme die Steigung.')) q(ref, frage);

select (select id from tasks where source_ref = 'e1-check-1') as check1,
       (select id from tasks where source_ref = 'e1-check-2') as check2,
       (select id from tasks where source_ref = 'e1-check-3') as check3
\gset

insert into task_solutions (task_id, correct_answers, solution, acceptance, hints) values
  (:'check1', '["2"]',   'LOESUNG-E1: 2 nach oben je Schritt',
   '{"canonical":"2","known_errors":{"0,5":"steigung_kehrwert"}}',
   '[{"level":1,"text":"HINWEIS-ENTWURF-E1"},{"level":2,"text":"Geh einen Schritt nach rechts."}]'),
  (:'check2', '["0,5"]', 'LOESUNG-E1: Δy : Δx = 2 : 4 = 0,5',
   '{"canonical":"0,5","known_errors":{"2":"steigung_kehrwert"}}', '[]'),
  (:'check3', '["-2"]',  'LOESUNG-E1: Δy : Δx = -4 : 2 = -2',
   '{"canonical":"-2","known_errors":{"2":"richtung_vertauscht"}}', '[]');

-- Ab hier als Admin ueber die Pflegefunktionen (wie spaeter die Inhalte in P2).
select set_config('request.jwt.claims',
                  json_build_object('sub', :'admin_uid', 'role', 'authenticated')::text, false);

create temp table e1_k (nr int primary key, id uuid);
insert into e1_k
select n, public.erklaer_kernidee_speichern(null, 'fkt_linear_steigung', n, t, 'ki')
  from (values (1, 'Steigung: wie viel es pro Schritt nach rechts hoch- oder runtergeht'),
               (2, 'Steigungsdreieck: Δy durch Δx'),
               (3, 'Negative Steigung: Der Graph fällt')) v(n, t);

create temp table e1_s (id uuid);
insert into e1_s
select public.erklaer_schritt_speichern(k.id, v.variante, a.art,
         format('Kernidee %s, Variante %s, %s: Die Steigung ist $m = \frac{\Delta y}{\Delta x}$.',
                k.nr, v.variante, a.art),
         case when a.art = 'erklaerung' then '{"svg_hash":"ab12","alt":"Steigungsdreieck an einer Geraden"}'::jsonb end,
         case when k.nr = 2 and v.variante = 'B' then '{steigung_kehrwert}'::text[] else '{}' end)
  from e1_k k, (values ('A'), ('B')) v(variante), (values ('erklaerung'), ('beispiel')) a(art);

-- Formeln wie von tools/formeln-svg.mjs eingetragen, dann pruefen und freigeben.
select public.erklaer_formeln_setzen(s.id, s.inhalt, array[encode(sha256(convert_to(s.inhalt, 'UTF8')), 'hex')])
  from erklaer_schritt s join e1_s using (id);
select public.erklaer_check_setzen(k.id, c.task_id, 1)
  from e1_k k join (values (1, :'check1'::uuid), (2, :'check2'::uuid), (3, :'check3'::uuid)) c(nr, task_id) using (nr);
-- Jeder Statuswechsel erhoeht pruef_version: deshalb Zeile fuer Zeile mit frischer Version.
do $$
declare r record;
begin
  for r in select s.id, s.kernidee_id from erklaer_schritt s join e1_s using (id) loop
    perform public.erklaer_status_setzen('schritt', r.id, 'geprueft',
              (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
    perform public.erklaer_status_setzen('schritt', r.id, 'freigegeben',
              (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
  end loop;
  for r in select id from e1_k loop
    perform public.erklaer_status_setzen('kernidee', r.id, 'geprueft',
              (select pruef_version from erklaer_kernidee where id = r.id));
    perform public.erklaer_status_setzen('kernidee', r.id, 'freigegeben',
              (select pruef_version from erklaer_kernidee where id = r.id));
  end loop;
end $$;

-- Entwuerfe: Variante C in Kernidee 1, dazu ein Skill nur mit Entwurf.
select public.erklaer_schritt_speichern(k.id, 'C', 'erklaerung', 'ENTWURF-E1 Variante C', null, '{}')
  from e1_k k where k.nr = 1;
select public.erklaer_kernidee_speichern(null, 'fkt_linear_steigung_nur_entwurf', 1, 'ENTWURF-E1 Kernidee', 'ki');
select public.erklaer_schritt_speichern(
         (select id from erklaer_kernidee where skill_key = 'fkt_linear_steigung_nur_entwurf'),
         'A', 'erklaerung', 'ENTWURF-E1 Text', null, '{}');

-- Hinweis Stufe 2 von check1 geprueft, Stufe 1 bleibt Entwurf.
select public.hinweis_status_setzen(:'check1', 2, 'geprueft');

select set_config('request.jwt.claims', '', false);
\o
