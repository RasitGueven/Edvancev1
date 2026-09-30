-- Datenmigration rest-01: Vorbefuellung fuer Lenas Pruefung (Item-Pflege).
-- Erzeugt von tools/prefill-build.mjs aus docs/prefill/rest-01.json — nicht von Hand editieren.
-- Erste Charge Restbestand (ohne VERA8): die restlichen 6 offenen Binom-Aufgaben (Algebra & Funktionen) und alle 22 offenen edvance_fundament_afb1-Aufgaben (ohne Themengebiet). Im Restbestand gibt es keine nachweisbar falschen Altwerte oder Import-Platzhalter — 0 Ueberschreibungen.
-- Regeln: nur status = 'draft', nie VERA8 (source is distinct from 'VERA8_IQB' in jedem WHERE),
-- jede Aenderung als Compare-and-set (/*cas*/: leer ODER exakter alter Wert),
-- Kennzeichen tasks.vorbefuellt in derselben Anweisung, keine DDL, keine Status-Felder.
-- Idempotent: ein zweiter Lauf aendert nichts. Werte + Gruende: docs/prefill/rest-01.csv
-- Kein Ziel-DB-Guard in der Datei: CI spielt alle Migrationen in eine leere DB 'neuaufbau' ein
-- (dort treffen die UPDATEs 0 Zeilen). Der Ziel-DB-Check steht in der Apply-Kette (docs/prefill/README.md).

-- #1 AFB I · Fläche · Dreieck g = 10 cm, h = 6 cm
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key geo_flaeche_dreieck: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'A = g · h : 2 = 10 cm · 6 cm : 2 = 60 cm² : 2 = 30 cm².'
   where s.task_id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and exists (select 1 from public.tasks d where d.id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?"},{"level":2,"text":"Rechne Grundseite mal Höhe und teile das Ergebnis durch 2."}]'::jsonb
   where s.task_id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and exists (select 1 from public.tasks d where d.id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Grundseite und Höhe werden addiert: 10 + 6 = 16.","socratic_question":"Wird bei einer Fläche addiert oder multipliziert?"},{"error":"Das Halbieren wird vergessen: 10 · 6 = 60.","socratic_question":"Welchen Teil eines Rechtecks bedeckt das Dreieck?"}]'::jsonb
   where s.task_id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and exists (select 1 from public.tasks d where d.id = 'dbe2ed81-b0e9-470a-8f9a-80966a4eaf63' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #2 AFB I · Fläche · Dreieck g = 6 cm, h = 4 cm
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key geo_flaeche_dreieck: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'A = g · h : 2 = 6 cm · 4 cm : 2 = 24 cm² : 2 = 12 cm².'
   where s.task_id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and exists (select 1 from public.tasks d where d.id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Formel gilt für die Fläche eines Dreiecks?"},{"level":2,"text":"Rechne Grundseite mal Höhe und teile das Ergebnis durch 2."}]'::jsonb
   where s.task_id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and exists (select 1 from public.tasks d where d.id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Grundseite und Höhe werden addiert: 6 + 4 = 10.","socratic_question":"Wird bei einer Fläche addiert oder multipliziert?"},{"error":"Das Halbieren wird vergessen: 6 · 4 = 24.","socratic_question":"Welchen Teil eines Rechtecks bedeckt das Dreieck?"}]'::jsonb
   where s.task_id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and exists (select 1 from public.tasks d where d.id = '0f3fe7d3-cdcf-4514-84a9-b08e5826234a' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #3 AFB I · Flächeneinheiten · 5 cm² in mm²
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key groessen_flaechen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '3372f3a7-7014-4052-809c-3bb17d627361' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '3372f3a7-7014-4052-809c-3bb17d627361' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 cm² = 100 mm² (1 cm = 10 mm, also 10 · 10).
5 cm² = 5 · 100 mm² = 500 mm².'
   where s.task_id = '3372f3a7-7014-4052-809c-3bb17d627361' and exists (select 1 from public.tasks d where d.id = '3372f3a7-7014-4052-809c-3bb17d627361' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie viele mm² passen dann in 1 cm²?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100. Multipliziere mit 100."}]'::jsonb
   where s.task_id = '3372f3a7-7014-4052-809c-3bb17d627361' and exists (select 1 from public.tasks d where d.id = '3372f3a7-7014-4052-809c-3bb17d627361' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Die Einheit wird nicht umgerechnet: 5.","socratic_question":"Ist ein mm² größer oder kleiner als ein cm²?"},{"error":"Es wird wie bei Längen mit 10 statt mit 100 multipliziert: 50.","socratic_question":"Wie viele kleine Quadrate von 1 mm Seitenlänge passen in ein Quadrat von 1 cm Seitenlänge?"}]'::jsonb
   where s.task_id = '3372f3a7-7014-4052-809c-3bb17d627361' and exists (select 1 from public.tasks d where d.id = '3372f3a7-7014-4052-809c-3bb17d627361' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #4 AFB I · Flächeneinheiten · 8 cm² in mm²
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key groessen_flaechen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '341fd991-7230-4548-8413-7f5f422231bf' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '341fd991-7230-4548-8413-7f5f422231bf' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 cm² = 100 mm² (1 cm = 10 mm, also 10 · 10).
8 cm² = 8 · 100 mm² = 800 mm².'
   where s.task_id = '341fd991-7230-4548-8413-7f5f422231bf' and exists (select 1 from public.tasks d where d.id = '341fd991-7230-4548-8413-7f5f422231bf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Millimeter hat ein Zentimeter – und wie viele mm² passen dann in 1 cm²?"},{"level":2,"text":"Bei Flächeneinheiten ist die Umrechnungszahl 100. Multipliziere mit 100."}]'::jsonb
   where s.task_id = '341fd991-7230-4548-8413-7f5f422231bf' and exists (select 1 from public.tasks d where d.id = '341fd991-7230-4548-8413-7f5f422231bf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Die Einheit wird nicht umgerechnet: 8.","socratic_question":"Ist ein mm² größer oder kleiner als ein cm²?"},{"error":"Es wird wie bei Längen mit 10 statt mit 100 multipliziert: 80.","socratic_question":"Wie viele kleine Quadrate von 1 mm Seitenlänge passen in ein Quadrat von 1 cm Seitenlänge?"}]'::jsonb
   where s.task_id = '341fd991-7230-4548-8413-7f5f422231bf' and exists (select 1 from public.tasks d where d.id = '341fd991-7230-4548-8413-7f5f422231bf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #5 AFB I · Gemischte Schreibweise · 1,4 m in cm
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key groessen_gemischt: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dd8db039-818d-42c2-8866-2df507675c36' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dd8db039-818d-42c2-8866-2df507675c36' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 m = 100 cm.
1,4 m = 1,4 · 100 cm = 140 cm.'
   where s.task_id = 'dd8db039-818d-42c2-8866-2df507675c36' and exists (select 1 from public.tasks d where d.id = 'dd8db039-818d-42c2-8866-2df507675c36' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2,"text":"Multipliziere 1,4 mit 100 – das Komma rückt zwei Stellen nach rechts."}]'::jsonb
   where s.task_id = 'dd8db039-818d-42c2-8866-2df507675c36' and exists (select 1 from public.tasks d where d.id = 'dd8db039-818d-42c2-8866-2df507675c36' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Mit 10 statt mit 100 multipliziert: 14.","socratic_question":"Wie viele Zentimeter hat ein Meter genau?"},{"error":"Das Komma wird als Trenner gelesen: 1 m und 4 cm = 104 cm.","socratic_question":"Was bedeutet die 4 nach dem Komma – 4 Zentimeter oder 4 Zehntel Meter?"}]'::jsonb
   where s.task_id = 'dd8db039-818d-42c2-8866-2df507675c36' and exists (select 1 from public.tasks d where d.id = 'dd8db039-818d-42c2-8866-2df507675c36' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #6 AFB I · Gemischte Schreibweise · 2,5 m in cm
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key groessen_gemischt: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 m = 100 cm.
2,5 m = 2,5 · 100 cm = 250 cm.'
   where s.task_id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and exists (select 1 from public.tasks d where d.id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Zentimeter hat ein Meter?"},{"level":2,"text":"Multipliziere 2,5 mit 100 – das Komma rückt zwei Stellen nach rechts."}]'::jsonb
   where s.task_id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and exists (select 1 from public.tasks d where d.id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Mit 10 statt mit 100 multipliziert: 25.","socratic_question":"Wie viele Zentimeter hat ein Meter genau?"},{"error":"Das Komma wird als Trenner gelesen: 2 m und 5 cm = 205 cm.","socratic_question":"Was bedeutet die 5 nach dem Komma – 5 Zentimeter oder 5 Zehntel Meter?"}]'::jsonb
   where s.task_id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and exists (select 1 from public.tasks d where d.id = 'c9e3f728-2591-4704-9558-d5f8dc467f93' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #7 AFB I · Gleichung · 4x + 3 = 3x + 11
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key gleichung_beidseitig: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '00096607-230e-4fd3-b236-42673e5ea268' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '00096607-230e-4fd3-b236-42673e5ea268' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '4x + 3 = 3x + 11 | − 3x
x + 3 = 11 | − 3
x = 8
Probe: 4 · 8 + 3 = 35 und 3 · 8 + 11 = 35.'
   where s.task_id = '00096607-230e-4fd3-b236-42673e5ea268' and exists (select 1 from public.tasks d where d.id = '00096607-230e-4fd3-b236-42673e5ea268' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichung."},{"level":2,"text":"Ziehe auf beiden Seiten 3x ab, danach auf beiden Seiten 3."}]'::jsonb
   where s.task_id = '00096607-230e-4fd3-b236-42673e5ea268' and exists (select 1 from public.tasks d where d.id = '00096607-230e-4fd3-b236-42673e5ea268' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Zahlen verrechnet.","socratic_question":"Was passiert mit 4x und 3x, wenn du auf beiden Seiten 3x abziehst?"},{"error":"Beim Zusammenführen wird ein Vorzeichen falsch übernommen.","socratic_question":"Setze dein Ergebnis zur Probe in beide Seiten ein – kommt links und rechts dasselbe heraus?"}]'::jsonb
   where s.task_id = '00096607-230e-4fd3-b236-42673e5ea268' and exists (select 1 from public.tasks d where d.id = '00096607-230e-4fd3-b236-42673e5ea268' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #8 AFB I · Gleichung · 6x + 2 = 5x + 8
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key gleichung_beidseitig: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '6x + 2 = 5x + 8 | − 5x
x + 2 = 8 | − 2
x = 6
Probe: 6 · 6 + 2 = 38 und 5 · 6 + 8 = 38.'
   where s.task_id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and exists (select 1 from public.tasks d where d.id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Bringe alle Terme mit x auf eine Seite der Gleichung."},{"level":2,"text":"Ziehe auf beiden Seiten 5x ab, danach auf beiden Seiten 2."}]'::jsonb
   where s.task_id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and exists (select 1 from public.tasks d where d.id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Die x-Terme werden nicht zusammengeführt, sondern nur die Zahlen verrechnet.","socratic_question":"Was passiert mit 6x und 5x, wenn du auf beiden Seiten 5x abziehst?"},{"error":"Beim Zusammenführen wird ein Vorzeichen falsch übernommen.","socratic_question":"Setze dein Ergebnis zur Probe in beide Seiten ein – kommt links und rechts dasselbe heraus?"}]'::jsonb
   where s.task_id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and exists (select 1 from public.tasks d where d.id = 'f76034e5-792c-47bb-81b2-1d5ecd205499' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #9 AFB I · Grundwert · 20 sind 10 %
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key prozent_grundwert: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '10 % sind der zehnte Teil. Wenn 20 der zehnte Teil sind, ist die ganze Zahl 20 · 10 = 200.'
   where s.task_id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and exists (select 1 from public.tasks d where d.id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":"Wenn 20 ein Zehntel der Zahl sind: Wie oft passt dieses Zehntel in das Ganze?"}]'::jsonb
   where s.task_id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and exists (select 1 from public.tasks d where d.id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Es wird 20 · 0,1 gerechnet statt geteilt: 2.","socratic_question":"Muss die gesuchte Zahl größer oder kleiner als 20 sein?"},{"error":"Das Komma wird eine Stelle zu weit verschoben: 2000.","socratic_question":"Sind 10 % von 2000 wirklich 20?"}]'::jsonb
   where s.task_id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and exists (select 1 from public.tasks d where d.id = '5bcf9b2a-6cce-4674-b070-3bd14cd3bad1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #10 AFB I · Grundwert · 45 sind 10 %
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key prozent_grundwert: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f0dc76f2-9666-4122-867c-9d089b106205' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f0dc76f2-9666-4122-867c-9d089b106205' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '10 % sind der zehnte Teil. Wenn 45 der zehnte Teil sind, ist die ganze Zahl 45 · 10 = 450.'
   where s.task_id = 'f0dc76f2-9666-4122-867c-9d089b106205' and exists (select 1 from public.tasks d where d.id = 'f0dc76f2-9666-4122-867c-9d089b106205' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welcher Bruchteil sind 10 %?"},{"level":2,"text":"Wenn 45 ein Zehntel der Zahl sind: Wie oft passt dieses Zehntel in das Ganze?"}]'::jsonb
   where s.task_id = 'f0dc76f2-9666-4122-867c-9d089b106205' and exists (select 1 from public.tasks d where d.id = 'f0dc76f2-9666-4122-867c-9d089b106205' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Es wird 45 · 0,1 gerechnet statt geteilt: 4,5.","socratic_question":"Muss die gesuchte Zahl größer oder kleiner als 45 sein?"},{"error":"Das Komma wird eine Stelle zu weit verschoben: 4500.","socratic_question":"Sind 10 % von 4500 wirklich 45?"}]'::jsonb
   where s.task_id = 'f0dc76f2-9666-4122-867c-9d089b106205' and exists (select 1 from public.tasks d where d.id = 'f0dc76f2-9666-4122-867c-9d089b106205' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #11 AFB I · Maßstab · 1:100, 5 cm auf dem Plan
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key geo_massstab: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'Maßstab 1:100 heißt: 1 cm auf dem Plan sind 100 cm in Wirklichkeit.
5 cm · 100 = 500 cm.'
   where s.task_id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and exists (select 1 from public.tasks d where d.id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Was bedeutet der Maßstab 1:100 für 1 cm auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit 100."}]'::jsonb
   where s.task_id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and exists (select 1 from public.tasks d where d.id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Mit 10 statt mit 100 multipliziert: 50 cm.","socratic_question":"Was sagt die zweite Zahl im Maßstab 1:100 aus?"},{"error":"Die Richtung wird vertauscht und durch 100 geteilt: 0,05 cm.","socratic_question":"Ist die Strecke in Wirklichkeit länger oder kürzer als auf dem Plan?"}]'::jsonb
   where s.task_id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and exists (select 1 from public.tasks d where d.id = '76f0bf82-458f-4903-a1ac-71f74c44e1e5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #12 AFB I · Maßstab · 1:200, 3 cm auf dem Plan
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 6 bereits zugeordneten Aufgaben mit skill_key geo_massstab: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'Maßstab 1:200 heißt: 1 cm auf dem Plan sind 200 cm in Wirklichkeit.
3 cm · 200 = 600 cm.'
   where s.task_id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and exists (select 1 from public.tasks d where d.id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Was bedeutet der Maßstab 1:200 für 1 cm auf dem Plan?"},{"level":2,"text":"Multipliziere die Länge auf dem Plan mit 200."}]'::jsonb
   where s.task_id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and exists (select 1 from public.tasks d where d.id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Mit 20 statt mit 200 multipliziert: 60 cm.","socratic_question":"Was sagt die zweite Zahl im Maßstab 1:200 aus?"},{"error":"Die Richtung wird vertauscht und durch 200 geteilt: 0,015 cm.","socratic_question":"Ist die Strecke in Wirklichkeit länger oder kürzer als auf dem Plan?"}]'::jsonb
   where s.task_id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and exists (select 1 from public.tasks d where d.id = '1a3cac96-e9a5-4a9a-9c6f-873940ec1fe7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #13 AFB I · Potenzen · 3^2
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 16 bereits zugeordneten Aufgaben mit skill_key potenzen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '3² = 3 · 3 = 9.'
   where s.task_id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and exists (select 1 from public.tasks d where d.id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Was bedeutet die kleine 2 oben an der 3?"},{"level":2,"text":"Multipliziere die Zahl mit sich selbst."}]'::jsonb
   where s.task_id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and exists (select 1 from public.tasks d where d.id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Basis mal Exponent gerechnet: 3 · 2 = 6.","socratic_question":"Wie oft steht die 3 als Faktor in 3²?"},{"error":"Basis und Exponent werden vertauscht: 2³ = 8.","socratic_question":"Welche Zahl wird mit sich selbst multipliziert – die große oder die kleine?"}]'::jsonb
   where s.task_id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and exists (select 1 from public.tasks d where d.id = '01f22500-c86d-47d0-bb1d-a5f420e2de9d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #14 AFB I · Potenzen · 5^2
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 16 bereits zugeordneten Aufgaben mit skill_key potenzen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '25539057-46a0-473c-ab73-40d1b81edd55' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '25539057-46a0-473c-ab73-40d1b81edd55' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '5² = 5 · 5 = 25.'
   where s.task_id = '25539057-46a0-473c-ab73-40d1b81edd55' and exists (select 1 from public.tasks d where d.id = '25539057-46a0-473c-ab73-40d1b81edd55' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Was bedeutet die kleine 2 oben an der 5?"},{"level":2,"text":"Multipliziere die Zahl mit sich selbst."}]'::jsonb
   where s.task_id = '25539057-46a0-473c-ab73-40d1b81edd55' and exists (select 1 from public.tasks d where d.id = '25539057-46a0-473c-ab73-40d1b81edd55' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Basis mal Exponent gerechnet: 5 · 2 = 10.","socratic_question":"Wie oft steht die 5 als Faktor in 5²?"},{"error":"Basis und Exponent werden vertauscht: 2⁵ = 32.","socratic_question":"Welche Zahl wird mit sich selbst multipliziert – die große oder die kleine?"}]'::jsonb
   where s.task_id = '25539057-46a0-473c-ab73-40d1b81edd55' and exists (select 1 from public.tasks d where d.id = '25539057-46a0-473c-ab73-40d1b81edd55' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #15 AFB I · Prozentuale Veränderung · 200 um 10 % größer
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key prozent_veraenderung: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '25da44e4-8960-4836-929f-cdfbaab61c14' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '25da44e4-8960-4836-929f-cdfbaab61c14' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '10 % von 200 sind 20.
Vergrößert: 200 + 20 = 220 (oder 200 · 1,1 = 220).'
   where s.task_id = '25da44e4-8960-4836-929f-cdfbaab61c14' and exists (select 1 from public.tasks d where d.id = '25da44e4-8960-4836-929f-cdfbaab61c14' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viel sind 10 % von 200?"},{"level":2,"text":"Rechne diesen Betrag zur ursprünglichen Zahl dazu."}]'::jsonb
   where s.task_id = '25da44e4-8960-4836-929f-cdfbaab61c14' and exists (select 1 from public.tasks d where d.id = '25da44e4-8960-4836-929f-cdfbaab61c14' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur der Prozentwert wird angegeben: 20.","socratic_question":"Wie groß ist die Zahl insgesamt, nachdem sie gewachsen ist?"},{"error":"Es wird verkleinert statt vergrößert: 180.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb
   where s.task_id = '25da44e4-8960-4836-929f-cdfbaab61c14' and exists (select 1 from public.tasks d where d.id = '25da44e4-8960-4836-929f-cdfbaab61c14' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #16 AFB I · Prozentuale Veränderung · 400 um 10 % größer
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key prozent_veraenderung: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '10 % von 400 sind 40.
Vergrößert: 400 + 40 = 440 (oder 400 · 1,1 = 440).'
   where s.task_id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and exists (select 1 from public.tasks d where d.id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viel sind 10 % von 400?"},{"level":2,"text":"Rechne diesen Betrag zur ursprünglichen Zahl dazu."}]'::jsonb
   where s.task_id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and exists (select 1 from public.tasks d where d.id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur der Prozentwert wird angegeben: 40.","socratic_question":"Wie groß ist die Zahl insgesamt, nachdem sie gewachsen ist?"},{"error":"Es wird verkleinert statt vergrößert: 360.","socratic_question":"Wird die Zahl größer oder kleiner?"}]'::jsonb
   where s.task_id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and exists (select 1 from public.tasks d where d.id = 'dcf715b5-4a34-48c8-ba54-bbbb22617058' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #17 AFB I · Volumen · Quader 2 cm, 3 cm, 5 cm
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key geo_volumen_quader: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'V = a · b · c = 2 cm · 3 cm · 5 cm = 30 cm³.'
   where s.task_id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and exists (select 1 from public.tasks d where d.id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"level":2,"text":"Multipliziere alle drei Kantenlängen miteinander."}]'::jsonb
   where s.task_id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and exists (select 1 from public.tasks d where d.id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur zwei Kanten werden multipliziert: 2 · 3 = 6.","socratic_question":"Wie viele Kantenlängen braucht ein Körper mit Länge, Breite und Höhe?"},{"error":"Die Kanten werden addiert: 2 + 3 + 5 = 10.","socratic_question":"Wird bei einem Volumen addiert oder multipliziert?"}]'::jsonb
   where s.task_id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and exists (select 1 from public.tasks d where d.id = 'c4ffe2bc-72fd-4faf-b2e8-bd1c59a6e2a7' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #18 AFB I · Volumen · Quader 4 cm, 2 cm, 6 cm
update public.tasks set cluster_id = '3156b22e-ad3b-46c8-8c76-4155176cc52a'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key geo_volumen_quader: Themengebiet „Geometrie & Messen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'V = a · b · c = 4 cm · 2 cm · 6 cm = 48 cm³.'
   where s.task_id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and exists (select 1 from public.tasks d where d.id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie berechnest du das Volumen eines Quaders?"},{"level":2,"text":"Multipliziere alle drei Kantenlängen miteinander."}]'::jsonb
   where s.task_id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and exists (select 1 from public.tasks d where d.id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur zwei Kanten werden multipliziert: 4 · 2 = 8.","socratic_question":"Wie viele Kantenlängen braucht ein Körper mit Länge, Breite und Höhe?"},{"error":"Die Kanten werden addiert: 4 + 2 + 6 = 12.","socratic_question":"Wird bei einem Volumen addiert oder multipliziert?"}]'::jsonb
   where s.task_id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and exists (select 1 from public.tasks d where d.id = '7f41ce84-72e3-42fe-9bd4-40d7bfc12cb4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #19 AFB I · Volumeneinheiten · 2 dm³ in cm³
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key groessen_volumen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 dm³ = 1000 cm³ (1 dm = 10 cm, also 10 · 10 · 10).
2 dm³ = 2 · 1000 cm³ = 2000 cm³.'
   where s.task_id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and exists (select 1 from public.tasks d where d.id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie viele cm³ passen dann in 1 dm³?"},{"level":2,"text":"Bei Volumeneinheiten ist die Umrechnungszahl 1000."}]'::jsonb
   where s.task_id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and exists (select 1 from public.tasks d where d.id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Es wird wie bei Längen mit 10 multipliziert: 20.","socratic_question":"Wie viele Würfel mit 1 cm Kantenlänge passen in einen Würfel mit 1 dm Kantenlänge?"},{"error":"Die Richtung wird vertauscht und geteilt: 0,002.","socratic_question":"Ist ein cm³ größer oder kleiner als ein dm³?"}]'::jsonb
   where s.task_id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and exists (select 1 from public.tasks d where d.id = 'a9ff9918-5d33-4381-b0bc-f611b3cb3a30' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #20 AFB I · Volumeneinheiten · 5 dm³ in cm³
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 5 bereits zugeordneten Aufgaben mit skill_key groessen_volumen: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = '1 dm³ = 1000 cm³ (1 dm = 10 cm, also 10 · 10 · 10).
5 dm³ = 5 · 1000 cm³ = 5000 cm³.'
   where s.task_id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and exists (select 1 from public.tasks d where d.id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie viele Zentimeter hat ein Dezimeter – und wie viele cm³ passen dann in 1 dm³?"},{"level":2,"text":"Bei Volumeneinheiten ist die Umrechnungszahl 1000."}]'::jsonb
   where s.task_id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and exists (select 1 from public.tasks d where d.id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Es wird wie bei Längen mit 10 multipliziert: 50.","socratic_question":"Wie viele Würfel mit 1 cm Kantenlänge passen in einen Würfel mit 1 dm Kantenlänge?"},{"error":"Die Richtung wird vertauscht und geteilt: 0,005.","socratic_question":"Ist ein cm³ größer oder kleiner als ein dm³?"}]'::jsonb
   where s.task_id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and exists (select 1 from public.tasks d where d.id = 'd040f47f-0d2e-4cb1-abfc-36eb694f518d' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #21 AFB I · Vorrang · -6 + 4 · 2
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key vorzeichen_vorrang: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'Punktrechnung vor Strichrechnung: 4 · 2 = 8.
-6 + 8 = 2.'
   where s.task_id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and exists (select 1 from public.tasks d where d.id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{"level":2,"text":"Rechne zuerst 4 · 2 und addiere das Ergebnis zu -6."}]'::jsonb
   where s.task_id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and exists (select 1 from public.tasks d where d.id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Minuszeichen vor der 6 wird übersehen: 6 + 8 = 14.","socratic_question":"Welches Vorzeichen hat die erste Zahl?"},{"error":"Von links nach rechts gerechnet: (-6 + 4) · 2 = -4.","socratic_question":"Gilt hier „von links nach rechts“ oder „Punkt vor Strich“?"}]'::jsonb
   where s.task_id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and exists (select 1 from public.tasks d where d.id = '864f0b02-71a8-4203-988d-9b6fbf6dd074' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #22 AFB I · Vorrang · -8 + 5 · 3
update public.tasks set cluster_id = 'e7108c9a-d19e-4021-8499-55b4f3d5d70c'::uuid, vorbefuellt = vorbefuellt || '{"cluster_id":{"art":"neu","grund":"Wie alle 7 bereits zugeordneten Aufgaben mit skill_key vorzeichen_vorrang: Themengebiet „Zahl & Rechnen“.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (cluster_id is null);
update public.tasks set needs_image = false, vorbefuellt = vorbefuellt || '{"needs_image":{"art":"neu","grund":"Aufgabentext enthält alle Angaben und verweist auf keine Abbildung.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (needs_image is null);
with u as (update public.task_solutions s set solution = 'Punktrechnung vor Strichrechnung: 5 · 3 = 15.
-8 + 15 = 7.'
   where s.task_id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and exists (select 1 from public.tasks d where d.id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Rechenart kommt zuerst: Plus oder Mal?"},{"level":2,"text":"Rechne zuerst 5 · 3 und addiere das Ergebnis zu -8."}]'::jsonb
   where s.task_id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and exists (select 1 from public.tasks d where d.id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Minuszeichen vor der 8 wird übersehen: 8 + 15 = 23.","socratic_question":"Welches Vorzeichen hat die erste Zahl?"},{"error":"Von links nach rechts gerechnet: (-8 + 5) · 3 = -9.","socratic_question":"Gilt hier „von links nach rechts“ oder „Punkt vor Strich“?"}]'::jsonb
   where s.task_id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and exists (select 1 from public.tasks d where d.id = 'd79fa8b6-c6b4-425c-ae78-724e5b38af81' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #23 Gemischt · Koeffizienten und Differenz · (3x - 2)² - (x + 4)(x - 4)
update public.tasks set est_duration_sec = 90, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '(3x - 2)² = 9x² - 12x + 4 (zweite binomische Formel)
(x + 4)(x - 4) = x² - 16 (dritte binomische Formel)
9x² - 12x + 4 - (x² - 16) = 8x² - 12x + 20.'
   where s.task_id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and exists (select 1 from public.tasks d where d.id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Setze den zweiten Teil in Klammern, bevor du subtrahierst – das Minus wirkt auf beide Glieder."}]'::jsonb
   where s.task_id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and exists (select 1 from public.tasks d where d.id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Minus vor der Klammer wird nicht auf -16 angewendet: 8x² - 12x - 12.","socratic_question":"Was ergibt − (x² − 16), wenn du die Klammer auflöst?"}]'::jsonb
   where s.task_id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and exists (select 1 from public.tasks d where d.id = 'dd4db5a2-2e96-4a93-b1c0-fca052b144ca' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #24 Gemischt · Quadrat und Quadratdifferenz · (x + 5)² - (x + 2)(x - 2)
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '(x + 5)² = x² + 10x + 25
(x + 2)(x - 2) = x² - 4
x² + 10x + 25 - (x² - 4) = 10x + 29.'
   where s.task_id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and exists (select 1 from public.tasks d where d.id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Achte beim Abziehen der Klammer (x² − 4) auf das Vorzeichen der 4."}]'::jsonb
   where s.task_id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and exists (select 1 from public.tasks d where d.id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Minus vor der Klammer wird nicht auf -4 angewendet: 10x + 21.","socratic_question":"Was ergibt − (x² − 4), wenn du die Klammer auflöst?"},{"error":"Das Quadrat wird gliedweise gebildet, der Mischterm 10x fehlt: 29.","socratic_question":"Rechne (x + 5)(x + 5) Schritt für Schritt aus – wie viele Produkte entstehen?"}]'::jsonb
   where s.task_id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and exists (select 1 from public.tasks d where d.id = 'b7ac3c73-91eb-4a9c-9d9e-4d9f3790b261' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #25 Gemischt · Sachkontext · Restfläche
update public.tasks set est_duration_sec = 120, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Restfläche = Grundstück − Beet = (x + 3)² - (x - 1)²
= x² + 6x + 9 - (x² - 2x + 1) = 8x + 8 (in m²).'
   where s.task_id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and exists (select 1 from public.tasks d where d.id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie berechnest du die Restfläche aus der Fläche des Grundstücks und der Fläche des Beets?"},{"level":2,"text":"Multipliziere beide Quadrate mit den binomischen Formeln aus und ziehe sie voneinander ab."}]'::jsonb
   where s.task_id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and exists (select 1 from public.tasks d where d.id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Beide Quadrate werden gliedweise gebildet: 9 − 1 = 8.","socratic_question":"Probiere es mit x = 2 aus: Wie groß sind Grundstück und Beet dann?"}]'::jsonb
   where s.task_id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and exists (select 1 from public.tasks d where d.id = 'f8364853-03fa-4d7e-807c-b0a20dbe09e3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #26 Gemischt · Summe zweier Formeln · (x + 6)(x - 6) + (x + 2)²
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '(x + 6)(x - 6) = x² - 36
(x + 2)² = x² + 4x + 4
x² - 36 + x² + 4x + 4 = 2x² + 4x - 32.'
   where s.task_id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and exists (select 1 from public.tasks d where d.id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Multipliziere beide Teile aus und fasse gleichartige Terme zusammen."}]'::jsonb
   where s.task_id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and exists (select 1 from public.tasks d where d.id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von 36 wird falsch übernommen: 2x² + 4x + 40.","socratic_question":"Was ergibt 6 · (−6) beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and exists (select 1 from public.tasks d where d.id = '79c7a940-7a41-4b6b-b4ff-ce464425c758' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #27 Gemischt · vereinfachen · (x + 4)² - x² - 16
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = '1c519bed-37b4-4322-9668-849b4756efcf' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '(x + 4)² = x² + 8x + 16
x² + 8x + 16 - x² - 16 = 8x.'
   where s.task_id = '1c519bed-37b4-4322-9668-849b4756efcf' and exists (select 1 from public.tasks d where d.id = '1c519bed-37b4-4322-9668-849b4756efcf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Multipliziere (x + 4)² zuerst mit der ersten binomischen Formel aus."},{"level":2,"text":"Fasse danach zusammen: Was bleibt übrig, wenn du x² und 16 wieder abziehst?"}]'::jsonb
   where s.task_id = '1c519bed-37b4-4322-9668-849b4756efcf' and exists (select 1 from public.tasks d where d.id = '1c519bed-37b4-4322-9668-849b4756efcf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet, der Mischterm fehlt: 0.","socratic_question":"Rechne (x + 4)(x + 4) Schritt für Schritt aus – bleibt wirklich nichts übrig?"}]'::jsonb
   where s.task_id = '1c519bed-37b4-4322-9668-849b4756efcf' and exists (select 1 from public.tasks d where d.id = '1c519bed-37b4-4322-9668-849b4756efcf' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #28 Gemischt · zwei Quadrate · (x + 3)² - (x - 3)²
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now()
 where id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '(x + 3)² = x² + 6x + 9
(x - 3)² = x² - 6x + 9
x² + 6x + 9 - (x² - 6x + 9) = 12x.'
   where s.task_id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and exists (select 1 from public.tasks d where d.id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomischen Formeln stecken in den beiden Teilen?"},{"level":2,"text":"Setze den zweiten Teil in Klammern, bevor du subtrahierst – das Minus wirkt auf alle drei Glieder."}]'::jsonb
   where s.task_id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and exists (select 1 from public.tasks d where d.id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Die Quadrate werden gliedweise gebildet: 9 − 9 = 0.","socratic_question":"Rechne (x + 3)(x + 3) Schritt für Schritt aus – wie viele Produkte entstehen?"},{"error":"Die Klammer wird beim Abziehen vergessen: 18.","socratic_question":"Was ergibt − (x² − 6x + 9), wenn du die Klammer auflöst?"}]'::jsonb
   where s.task_id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and exists (select 1 from public.tasks d where d.id = 'c31fdbb1-9a48-4cd8-9b0c-35393af84330' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Aus acceptance.known_errors der Aufgabe abgeleitet.","charge":"rest-01"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
