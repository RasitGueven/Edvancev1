-- Datenmigration mathe8-pilot: Vorbefuellung fuer Lenas Pruefung (Item-Pflege).
-- Erzeugt von tools/prefill-build.mjs aus docs/prefill/mathe8-pilot.json — nicht von Hand editieren.
-- Die ersten 18 offenen Aufgaben (status=draft) im Themengebiet 'Algebra & Funktionen' in Lenas Warteschlange (themenVon: Titel, dann id) — ohne VERA8 (Entscheidung zu PR #176). Urspruenglich 25 inkl. 7 VERA8; nicht aufgefuellt.
-- Ersetzt 20260930120000_prefill_mathe8_pilot (Versionskollision mit S2b, nie eingespielt).
-- Regeln: nur status = 'draft', nie VERA8 (source is distinct from 'VERA8_IQB' in jedem WHERE),
-- jede Aenderung als Compare-and-set (/*cas*/: leer ODER exakter alter Wert),
-- Kennzeichen tasks.vorbefuellt in derselben Anweisung, keine DDL, keine Status-Felder.
-- Idempotent: ein zweiter Lauf aendert nichts. Werte + Gruende: docs/prefill/mathe8-pilot.csv
-- Kein Ziel-DB-Guard in der Datei: CI spielt alle Migrationen in eine leere DB 'neuaufbau' ein
-- (dort treffen die UPDATEs 0 Zeilen). Der Ziel-DB-Check steht in der Apply-Kette (docs/prefill/README.md).

-- #1 Binomische Formel · Quadrat · (2x + 3)²
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Erste binomische Formel mit a = 2x und b = 3:
(2x + 3)² = (2x)² + 2 · 2x · 3 + 3² = 4x² + 12x + 9.
Richtig ist also 4x² + 12x + 9.'
   where s.task_id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and exists (select 1 from public.tasks d where d.id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomische Formel passt zu (a + b)²?"},{"level":2,"text":"Setze a = 2x und b = 3 in a² + 2ab + b² ein. Denk an den Mischterm 2ab."}]'::jsonb
   where s.task_id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and exists (select 1 from public.tasks d where d.id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet: (2x + 3)² = 4x² + 9 – der Mischterm 12x fehlt.","socratic_question":"Schreibe (2x + 3)² als (2x + 3)(2x + 3) und multipliziere jedes Glied mit jedem – wie viele Produkte entstehen?"}]'::jsonb
   where s.task_id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and exists (select 1 from public.tasks d where d.id = 'de60d4ff-c473-4358-b050-85a54dd903a1' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #2 Binomische Formel · Quadrat · (3x - 4)²
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Zweite binomische Formel mit a = 3x und b = 4:
(3x - 4)² = (3x)² - 2 · 3x · 4 + 4² = 9x² - 24x + 16.
Richtig ist also 9x² - 24x + 16.'
   where s.task_id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and exists (select 1 from public.tasks d where d.id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomische Formel passt zu (a - b)²?"},{"level":2,"text":"Setze a = 3x und b = 4 in a² - 2ab + b² ein. Achte auf das Vorzeichen des Mischterms."}]'::jsonb
   where s.task_id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and exists (select 1 from public.tasks d where d.id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet: 9x² + 16 – der Mischterm fehlt.","socratic_question":"Wenn du (3x - 4)(3x - 4) ausmultiplizierst: Was ergibt 3x · (-4)?"},{"error":"Der Mischterm bekommt das falsche Vorzeichen: 9x² + 24x + 16.","socratic_question":"Welches Vorzeichen hat 2ab, wenn b abgezogen wird?"}]'::jsonb
   where s.task_id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and exists (select 1 from public.tasks d where d.id = 'ebd05f6f-2ab0-41ad-bac3-16c075fc2592' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #3 Binomische Formel · Quadrat · (x - 5)²
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '9a598424-963b-4981-91ad-9a81cead51f4' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Zweite binomische Formel mit a = x und b = 5:
(x - 5)² = x² - 2 · x · 5 + 5² = x² - 10x + 25.
Richtig ist also x² - 10x + 25.'
   where s.task_id = '9a598424-963b-4981-91ad-9a81cead51f4' and exists (select 1 from public.tasks d where d.id = '9a598424-963b-4981-91ad-9a81cead51f4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomische Formel passt zu (a - b)²?"},{"level":2,"text":"Rechne a² - 2ab + b² mit a = x und b = 5."}]'::jsonb
   where s.task_id = '9a598424-963b-4981-91ad-9a81cead51f4' and exists (select 1 from public.tasks d where d.id = '9a598424-963b-4981-91ad-9a81cead51f4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet: x² + 25 – der Mischterm -10x fehlt.","socratic_question":"Rechne (x - 5)(x - 5) Schritt für Schritt aus – wie viele Produkte entstehen?"},{"error":"Der Mischterm bekommt das falsche Vorzeichen: x² + 10x + 25.","socratic_question":"Was ergibt x · (-5) + (-5) · x?"}]'::jsonb
   where s.task_id = '9a598424-963b-4981-91ad-9a81cead51f4' and exists (select 1 from public.tasks d where d.id = '9a598424-963b-4981-91ad-9a81cead51f4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #4 Binomische Formel · Quadrat · (x + 3)²
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Erste binomische Formel mit a = x und b = 3:
(x + 3)² = x² + 2 · x · 3 + 3² = x² + 6x + 9.
Richtig ist also x² + 6x + 9.'
   where s.task_id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and exists (select 1 from public.tasks d where d.id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomische Formel passt zu (a + b)²?"},{"level":2,"text":"Rechne a² + 2ab + b² mit a = x und b = 3."}]'::jsonb
   where s.task_id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and exists (select 1 from public.tasks d where d.id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet: x² + 9 – der Mischterm 6x fehlt.","socratic_question":"Setze zur Probe x = 1 ein: Ist (1 + 3)² dasselbe wie 1² + 9?"}]'::jsonb
   where s.task_id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and exists (select 1 from public.tasks d where d.id = 'ae6fa0b8-283c-4570-b9d2-6271c17e3384' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #5 Binomische Formel · Rückrichtung · x² + 20x + 100
update public.tasks set est_duration_sec = 90, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Gesucht sind a und b mit a² = x² und b² = 100, also a = x und b = 10.
Probe des Mischterms: 2 · x · 10 = 20x – passt.
x² + 20x + 100 = (x + 10)².'
   where s.task_id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and exists (select 1 from public.tasks d where d.id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Von welcher Zahl ist 100 das Quadrat?"},{"level":2,"text":"Prüfe mit dem Mischterm: 2 · a · b muss 20x ergeben."}]'::jsonb
   where s.task_id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and exists (select 1 from public.tasks d where d.id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Der Mischterm wird direkt als b übernommen: (x + 20)². Ausmultipliziert ergibt das x² + 40x + 400.","socratic_question":"Multipliziere deine Klammer zur Probe aus – kommt wieder x² + 20x + 100 heraus?"}]'::jsonb
   where s.task_id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and exists (select 1 from public.tasks d where d.id = 'f54b2f2c-5c0e-46ae-bd6c-00acc3efa4fa' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #6 Binomische Formel · Sachkontext · quadratisches Beet
update public.tasks set est_duration_sec = 90, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II + Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Fläche eines Quadrats = Seitenlänge · Seitenlänge.
A = (x + 4)² = x² + 2 · x · 4 + 4² = x² + 8x + 16 (in m²).'
   where s.task_id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and exists (select 1 from public.tasks d where d.id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Wie berechnest du die Fläche eines Quadrats?"},{"level":2,"text":"Die Fläche ist (x + 4)². Nutze die erste binomische Formel."}]'::jsonb
   where s.task_id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and exists (select 1 from public.tasks d where d.id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Quadrat wird gliedweise gebildet: x² + 16 – der Mischterm 8x fehlt.","socratic_question":"Zeichne das Beet als Quadrat mit den Teilen x und 4: Aus welchen vier Rechtecken besteht es?"}]'::jsonb
   where s.task_id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and exists (select 1 from public.tasks d where d.id = '513d03bd-0d8d-4f0a-9e99-ea63b38b8587' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #7 Dritte binomische Formel · (2x - 9)(2x + 9)
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'd47b8793-7e82-4036-9173-d446c554b907' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Dritte binomische Formel mit a = 2x und b = 9:
(2x - 9)(2x + 9) = (2x)² - 9² = 4x² - 81.'
   where s.task_id = 'd47b8793-7e82-4036-9173-d446c554b907' and exists (select 1 from public.tasks d where d.id = 'd47b8793-7e82-4036-9173-d446c554b907' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a - b)(a + b) = a² - b². Hier ist a = 2x und b = 9."}]'::jsonb
   where s.task_id = 'd47b8793-7e82-4036-9173-d446c554b907' and exists (select 1 from public.tasks d where d.id = 'd47b8793-7e82-4036-9173-d446c554b907' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 4x² + 81.","socratic_question":"Was ergibt (-9) · 9 beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = 'd47b8793-7e82-4036-9173-d446c554b907' and exists (select 1 from public.tasks d where d.id = 'd47b8793-7e82-4036-9173-d446c554b907' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #8 Dritte binomische Formel · (3x + 5)(3x - 5)
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '94492e5a-3627-4f45-b628-41d06114a7a4' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Dritte binomische Formel mit a = 3x und b = 5:
(3x + 5)(3x - 5) = (3x)² - 5² = 9x² - 25.'
   where s.task_id = '94492e5a-3627-4f45-b628-41d06114a7a4' and exists (select 1 from public.tasks d where d.id = '94492e5a-3627-4f45-b628-41d06114a7a4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a + b)(a - b) = a² - b². Hier ist a = 3x und b = 5."}]'::jsonb
   where s.task_id = '94492e5a-3627-4f45-b628-41d06114a7a4' and exists (select 1 from public.tasks d where d.id = '94492e5a-3627-4f45-b628-41d06114a7a4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 9x² + 25.","socratic_question":"Was ergibt 5 · (-5) beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = '94492e5a-3627-4f45-b628-41d06114a7a4' and exists (select 1 from public.tasks d where d.id = '94492e5a-3627-4f45-b628-41d06114a7a4' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #9 Dritte binomische Formel · (x - 7)(x + 7)
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Dritte binomische Formel mit a = x und b = 7:
(x - 7)(x + 7) = x² - 7² = x² - 49.'
   where s.task_id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and exists (select 1 from public.tasks d where d.id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a - b)(a + b) = a² - b². Hier ist a = x und b = 7."}]'::jsonb
   where s.task_id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and exists (select 1 from public.tasks d where d.id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 49.","socratic_question":"Was ergibt (-7) · 7 beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and exists (select 1 from public.tasks d where d.id = 'eb3f28da-155b-49fc-aa17-1abfd882a373' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #10 Dritte binomische Formel · (x + 4)(x - 4)
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Dritte binomische Formel mit a = x und b = 4:
(x + 4)(x - 4) = x² - 4² = x² - 16.'
   where s.task_id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and exists (select 1 from public.tasks d where d.id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Die Klammern unterscheiden sich nur im Vorzeichen. Welche binomische Formel passt?"},{"level":2,"text":"(a + b)(a - b) = a² - b². Hier ist a = x und b = 4."}]'::jsonb
   where s.task_id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and exists (select 1 from public.tasks d where d.id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 16.","socratic_question":"Was ergibt 4 · (-4) beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and exists (select 1 from public.tasks d where d.id = '293413f8-8e31-4f0b-b64e-7ac2a183606e' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #11 Dritte binomische Formel · geschicktes Rechnen · 102 · 98
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '7e027634-1c45-4c70-8357-198dad0f1797' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '102 · 98 = (100 + 2)(100 - 2) = 100² - 2² = 10000 - 4 = 9996.'
   where s.task_id = '7e027634-1c45-4c70-8357-198dad0f1797' and exists (select 1 from public.tasks d where d.id = '7e027634-1c45-4c70-8357-198dad0f1797' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Schreibe 102 und 98 als 100 plus bzw. minus eine kleine Zahl."},{"level":2,"text":"Nutze (a + b)(a - b) = a² - b² mit a = 100 und b = 2."}]'::jsonb
   where s.task_id = '7e027634-1c45-4c70-8357-198dad0f1797' and exists (select 1 from public.tasks d where d.id = '7e027634-1c45-4c70-8357-198dad0f1797' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Das Vorzeichen von b² wird falsch gesetzt: 100² + 2² = 10004.","socratic_question":"Ist 102 · 98 größer oder kleiner als 100 · 100?"}]'::jsonb
   where s.task_id = '7e027634-1c45-4c70-8357-198dad0f1797' and exists (select 1 from public.tasks d where d.id = '7e027634-1c45-4c70-8357-198dad0f1797' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #12 Dritte binomische Formel · Sachkontext · Grundstück
update public.tasks set est_duration_sec = 120, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III + Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '113aea0a-276a-4042-b634-805ef1e11db2' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Die neuen Seitenlängen sind (x + 5) m und (x - 5) m.
A = (x + 5)(x - 5) = x² - 25 (in m²).
Das Rechteck ist also um 25 m² kleiner als das ursprüngliche Quadrat.'
   where s.task_id = '113aea0a-276a-4042-b634-805ef1e11db2' and exists (select 1 from public.tasks d where d.id = '113aea0a-276a-4042-b634-805ef1e11db2' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Schreibe die beiden neuen Seitenlängen als Terme auf."},{"level":2,"text":"Multipliziere (x + 5) mit (x - 5). Welche binomische Formel passt?"}]'::jsonb
   where s.task_id = '113aea0a-276a-4042-b634-805ef1e11db2' and exists (select 1 from public.tasks d where d.id = '113aea0a-276a-4042-b634-805ef1e11db2' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Es wird angenommen, dass sich Verlängern und Verkürzen ausgleichen: Fläche bleibt x².","socratic_question":"Probiere es mit x = 10 aus: Wie groß ist ein Rechteck mit 15 m und 5 m im Vergleich zum Quadrat mit 10 m?"},{"error":"Das Vorzeichen von b² wird falsch gesetzt: x² + 25.","socratic_question":"Was ergibt 5 · (-5) beim Ausmultiplizieren?"}]'::jsonb
   where s.task_id = '113aea0a-276a-4042-b634-805ef1e11db2' and exists (select 1 from public.tasks d where d.id = '113aea0a-276a-4042-b634-805ef1e11db2' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #13 Faktorisieren · Differenz von Quadraten · x² - 25
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'x² - 25 = x² - 5² ist eine Differenz von Quadraten.
Mit a² - b² = (a + b)(a - b): x² - 25 = (x + 5)(x - 5).'
   where s.task_id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and exists (select 1 from public.tasks d where d.id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Von welcher Zahl ist 25 das Quadrat?"},{"level":2,"text":"Nutze a² - b² = (a + b)(a - b) rückwärts."}]'::jsonb
   where s.task_id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and exists (select 1 from public.tasks d where d.id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Beide Klammern bekommen dasselbe Vorzeichen: (x - 5)(x - 5) oder (x + 5)(x + 5). Das ergibt einen Mischterm ±10x.","socratic_question":"Multipliziere deine Klammern zur Probe aus – verschwindet der Term mit x?"}]'::jsonb
   where s.task_id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and exists (select 1 from public.tasks d where d.id = '9be9bb9c-a5b5-482e-bd76-51599553d61b' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #14 Faktorisieren · gemeinsamer Faktor und Quadrat · 3x² + 12x + 12
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Zuerst 3 ausklammern: 3x² + 12x + 12 = 3(x² + 4x + 4).
Die Klammer ist ein vollständiges Quadrat: x² + 4x + 4 = (x + 2)².
Also: 3x² + 12x + 12 = 3(x + 2)².'
   where s.task_id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and exists (select 1 from public.tasks d where d.id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Zahl steckt in allen drei Summanden als Faktor?"},{"level":2,"text":"Klammere 3 aus und prüfe dann, ob die Klammer eine binomische Formel ist."}]'::jsonb
   where s.task_id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and exists (select 1 from public.tasks d where d.id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur der gemeinsame Faktor wird ausgeklammert: 3(x² + 4x + 4) – die Klammer lässt sich noch als (x + 2)² schreiben.","socratic_question":"Kannst du den Term in der Klammer noch weiter zerlegen?"}]'::jsonb
   where s.task_id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and exists (select 1 from public.tasks d where d.id = '18dbb731-98be-4b90-a8c2-5773114de6c6' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #15 Faktorisieren · gemeinsamer Faktor zuerst · 2x² - 18
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Zuerst 2 ausklammern: 2x² - 18 = 2(x² - 9).
Die Klammer ist eine Differenz von Quadraten: x² - 9 = (x + 3)(x - 3).
Also: 2x² - 18 = 2(x + 3)(x - 3).'
   where s.task_id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and exists (select 1 from public.tasks d where d.id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche Zahl steckt in beiden Summanden als Faktor?"},{"level":2,"text":"Klammere 2 aus und zerlege x² - 9 mit a² - b² = (a + b)(a - b)."}]'::jsonb
   where s.task_id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and exists (select 1 from public.tasks d where d.id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nur der gemeinsame Faktor wird ausgeklammert: 2(x² - 9) – die Klammer lässt sich noch zerlegen.","socratic_question":"Ist x² - 9 schon ein Produkt, oder kannst du es noch zerlegen?"},{"error":"Beide Klammern bekommen dasselbe Vorzeichen: 2(x - 3)(x - 3).","socratic_question":"Multipliziere (x - 3)(x - 3) aus – bleibt ein Term mit x übrig?"}]'::jsonb
   where s.task_id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and exists (select 1 from public.tasks d where d.id = 'e4a18d51-9545-4f17-b1aa-10dc72c35cd3' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #16 Faktorisieren · geschicktes Rechnen · 47² - 43²
update public.tasks set est_duration_sec = 60, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB II, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = '47² - 43² = (47 + 43)(47 - 43) = 90 · 4 = 360.'
   where s.task_id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and exists (select 1 from public.tasks d where d.id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Welche binomische Formel hat die Form a² - b²?"},{"level":2,"text":"a² - b² = (a + b)(a - b). Setze a = 47 und b = 43 ein."}]'::jsonb
   where s.task_id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and exists (select 1 from public.tasks d where d.id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"47² - 43² wird als (47 - 43)² gerechnet: 16.","socratic_question":"Ist 47² - 43² dasselbe wie (47 - 43)²? Probiere es mit kleinen Zahlen wie 3² - 2² aus."},{"error":"Nur (47 + 43) = 90 wird berechnet, der Faktor (47 - 43) = 4 fehlt.","socratic_question":"Aus wie vielen Faktoren besteht (a + b)(a - b)?"}]'::jsonb
   where s.task_id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and exists (select 1 from public.tasks d where d.id = '88ca2551-82bf-4ca3-b971-32cd4292a146' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #17 Faktorisieren · vollständiges Quadrat · x² + 8x + 16
update public.tasks set est_duration_sec = 45, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB I, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'Gesucht sind a und b mit a² = x² und b² = 16, also a = x und b = 4.
Probe des Mischterms: 2 · x · 4 = 8x – passt.
x² + 8x + 16 = (x + 4)².'
   where s.task_id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and exists (select 1 from public.tasks d where d.id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Von welcher Zahl ist 16 das Quadrat?"},{"level":2,"text":"Prüfe mit dem Mischterm: 2 · a · b muss 8x ergeben."}]'::jsonb
   where s.task_id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and exists (select 1 from public.tasks d where d.id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Der Mischterm wird direkt als b übernommen: (x + 8)². Ausmultipliziert ergibt das x² + 16x + 64.","socratic_question":"Multipliziere deine Klammer zur Probe aus – kommt wieder x² + 8x + 16 heraus?"}]'::jsonb
   where s.task_id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and exists (select 1 from public.tasks d where d.id = 'b2bc0cfc-d927-4a29-aca4-4686606d9466' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);

-- #18 Faktorisieren · zweistufig · x⁴ - 16
update public.tasks set est_duration_sec = 90, vorbefuellt = vorbefuellt || '{"est_duration_sec":{"art":"neu","grund":"Zeitregel: AFB III, kein Sachkontext.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now()
 where id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and status = 'draft' and source is distinct from 'VERA8_IQB' and /*cas*/ (est_duration_sec is null);
with u as (update public.task_solutions s set solution = 'x⁴ - 16 = (x²)² - 4² = (x² + 4)(x² - 4).
Die zweite Klammer ist wieder eine Differenz von Quadraten: x² - 4 = (x + 2)(x - 2).
Also: x⁴ - 16 = (x² + 4)(x + 2)(x - 2).'
   where s.task_id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and exists (select 1 from public.tasks d where d.id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(btrim(s.solution), '') = '') returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"solution":{"art":"neu","grund":"Nachgerechnet.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set hints = '[{"level":1,"text":"Schreibe x⁴ als (x²)² und 16 als 4²."},{"level":2,"text":"Nach dem ersten Zerlegen: Lässt sich eine der Klammern noch einmal mit a² - b² zerlegen?"}]'::jsonb
   where s.task_id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and exists (select 1 from public.tasks d where d.id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.hints, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"hints":{"art":"neu","grund":"Generiert.","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
with u as (update public.task_solutions s set typical_errors = '[{"error":"Nach dem ersten Schritt wird aufgehört: (x² + 4)(x² - 4) – die Klammer x² - 4 lässt sich noch zerlegen.","socratic_question":"Ist x² - 4 selbst wieder eine Differenz von Quadraten?"}]'::jsonb
   where s.task_id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and exists (select 1 from public.tasks d where d.id = '9d904128-a0ae-449c-b7de-e1c57c8238c5' and d.status = 'draft' and d.source is distinct from 'VERA8_IQB') and /*cas*/ (coalesce(s.typical_errors, '[]'::jsonb) in ('[]'::jsonb, '{}'::jsonb)) returning s.task_id)
update public.tasks set vorbefuellt = vorbefuellt || '{"typical_errors":{"art":"neu","grund":"Begruendung in der Charge-CSV (docs/prefill)","charge":"mathe8-pilot"}}'::jsonb, vorbefuellt_am = now() where id in (select task_id from u);
