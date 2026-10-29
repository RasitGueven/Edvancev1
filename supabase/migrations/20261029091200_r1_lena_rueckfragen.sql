-- R1 (29.10.2026): Lenas Rückfragen, Klasse A. Einordnung: docs/rueckfragen/R1/einordnung.md
--
-- Nur Daten, nur die drei Aufgaben der Klasse A, je Block über die task_id:
--   1. 8c4a2d71 Aufgabentext (question und question_payload.prompt), Zahlen unverändert; Schreibweise „+1029“.
--   2. ffc76634 known_errors und typical_errors (x/y vertauscht).
--   3. 6274f6a5 known_errors und typical_errors (Dreiecksformel).
-- B (158c874c) und C (a61e8be9, 1bbce78e) ändern sich nicht. Freigabe danach über pruef_rueckfrage_klaeren
-- (tools/r1-freigeben.sql), nicht hier.
--
-- Wie 20261025143853_lena_rueckmeldungen_1025: Ausgangsfassung (task_pruefung_ausgang) bleibt, damit vorher → nachher
-- sichtbar ist. Jede Änderung nur, wo der Vorher-Stand steht (Text: alter Text; known_errors: Schlüssel fehlt;
-- typical_errors: alte Liste). Ein neuer Schlüssel ist nie canonical, equivalent oder richtige Antwort.
-- pruef_version zählt per Trigger hoch. Idempotent; im CI-Neuaufbau fehlen die Aufgaben, jeder Block trifft 0 Zeilen.
-- Kein begin/commit: mig klammert. Rollback: supabase/rollback/20261029091200_r1_lena_rueckfragen.sql

do $r1$
declare
  v_n integer;
begin
  -- ── 1. Text ─────────────────────────────────────────────────────────────────
  -- 8c4a2d71 (x + 5)² − (x + 2)(x − 2), x = 100 → 1029. Lena: „Ich würde hier in der Aufgabenstellung formulieren
  -- "Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für  x = 100 ein."“ Übernommen, nur
  -- „für x = 100“ → „für x den Wert 100“ (liest sich glatter). Ziffernfolge gleich.
  update public.tasks
     set question = E'Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Vereinfache den Term zuerst anhand der binomischen Formeln und setze dann für x den Wert 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?'::text))
   where id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'
     and question = E'Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?'
     and question_payload ->> 'prompt' = E'Vereinfache den Term zuerst mit den binomischen Formeln und setze dann x = 100 ein.\n\n(x + 5)² - (x + 2)(x - 2) = ?';
  get diagnostics v_n = row_count;
  raise notice 'r1: Text 8c4a2d71, % Zeile(n)', v_n;

  -- 8c4a2d71 Gegenprobe der Schreibweisen: „+1029“ ist im Urteil voll, aber nicht in correct_answers (correct = false,
  -- Fehlbild-Erfassung). Wie im Bestand üblich „+v“ ergänzen, auch als equivalent.
  update public.task_solutions
     set correct_answers = correct_answers || '["+1029"]'::jsonb,
         acceptance = acceptance || '{"equivalents": ["+1029"]}'::jsonb,
         updated_at = now()
   where task_id = '8c4a2d71-0e9b-4f36-b5a8-6d1f3e7c9a24'
     and correct_answers = '["1029"]'::jsonb
     and acceptance ->> 'canonical' = '1029' and not acceptance ? 'equivalents';
  get diagnostics v_n = row_count;
  raise notice 'r1: Schreibweise +1029 in 8c4a2d71, % Zeile(n)', v_n;

  -- ── 2./3. known_errors ──────────────────────────────────────────────────────
  create temp table r1_ke (task_id uuid not null, skill_key text not null, schluessel text not null,
                           slug text not null, primary key (task_id, schluessel)) on commit drop;
  insert into r1_ke (task_id, skill_key, schluessel, slug) values
    -- ffc76634 A(1 | 1), B(3 | 7), b = −2. Lena: „… sowohl beim Berechnen der Steigung und beim Einsetzten in die
    -- Gleichung hinterher den X-Wert und den Y-Wert vertauschen …“. Beides vertauscht ergibt m = 1/3, b = 2/3 (schon
    -- steigung_kehrwert, A ist symmetrisch); fehlte dezimal. Nur Steigung vertauscht, B eingesetzt: b = 6. Nur B
    -- vertauscht eingesetzt (3 = 3 · 7 + b): b = −18 → koordinaten_vertauscht.
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,6',   'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,7',   'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,66',  'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,67',  'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,666', 'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '0,667', 'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '6',     'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '+6',    'steigung_kehrwert'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '-18',   'koordinaten_vertauscht'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '−18',   'koordinaten_vertauscht'),
    ('ffc76634-86ca-4c53-b816-d18d7f868443', 'fkt_linear_gleichung', '- 18',  'koordinaten_vertauscht');
  -- 6274f6a5 Raute e = 24, f = 10, a = 13 → 120 cm². Lena: „… die falsche Formel zur Berechnung nehmen, wie etwa die
  -- eines Dreiecks“. g = e, h = f ergibt richtig 120. Nur ein Dreieck (24 · 5 : 2 = 60) oder ein Viertel
  -- (12 · 5 : 2 = 30) → teilflaeche_vergessen; Seite als Grundseite (13 · 10 : 2 = 65, 13 · 24 : 2 = 156) →
  -- falsche_hoehe wie schon 13 · 13. Die sechs Schreibweisen des Bestands: v, +v, v cm², vcm², +v cm², +vcm².
  insert into r1_ke (task_id, skill_key, schluessel, slug)
  select '6274f6a5-65e5-40f4-be09-36fa8931c424', 'geo_flaeche_drachen_raute', vz || w.v || einheit, w.slug
    from (values ('30', 'teilflaeche_vergessen'), ('60', 'teilflaeche_vergessen'),
                 ('65', 'falsche_hoehe'), ('156', 'falsche_hoehe')) w(v, slug),
         (values (''), ('+')) p(vz),
         (values (''), (' cm²'), ('cm²')) e(einheit);

  with d as (
    select s.task_id, jsonb_object_agg(z.schluessel, z.slug) as patch
      from r1_ke z
      join public.tasks t on t.id = z.task_id and t.skill_key = z.skill_key
      join public.task_solutions s on s.task_id = z.task_id
     where jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
       and not (s.acceptance -> 'known_errors' ? z.schluessel)
       and (s.acceptance ->> 'canonical') is distinct from z.schluessel
       and not coalesce(s.acceptance -> 'equivalents' ? z.schluessel, false)
       and not coalesce(s.correct_answers ? z.schluessel, false)
     group by s.task_id)
  update public.task_solutions s
     set acceptance = jsonb_set(s.acceptance, '{known_errors}', (s.acceptance -> 'known_errors') || d.patch),
         updated_at = now()
    from d
   where s.task_id = d.task_id;
  get diagnostics v_n = row_count;
  raise notice 'r1: known_errors in % Aufgabe(n) ergänzt', v_n;

  -- ── 2./3. typical_errors ────────────────────────────────────────────────────
  -- ffc76634: Kehrwert-Eintrag nennt zusätzlich b = 6; neuer Eintrag für koordinaten_vertauscht.
  update public.task_solutions
     set typical_errors = '[{"error": "Beim Auflösen nach b addiert statt subtrahiert: 1 + 3 = 4.",
                             "fehlbild": "addiert_statt_subtrahiert",
                             "socratic_question": "Was musst du auf beiden Seiten tun, damit die 3 neben dem b verschwindet?"},
                            {"error": "Mit dem Kehrwert der Steigung gerechnet (x- und y-Werte im Steigungsdreieck vertauscht): m = 1/3, b = 2/3, mit B eingesetzt b = 6.",
                             "fehlbild": "steigung_kehrwert",
                             "socratic_question": "Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?"},
                            {"error": "Beim Einsetzen von B x und y vertauscht: 3 = 3 · 7 + b, also b = -18.",
                             "fehlbild": "koordinaten_vertauscht",
                             "socratic_question": "Welche Zahl in B(3 | 7) ist der x-Wert, welche der y-Wert?"}]'::jsonb,
         updated_at = now()
   where task_id = 'ffc76634-86ca-4c53-b816-d18d7f868443'
     and typical_errors = '[{"error": "Beim Auflösen nach b addiert statt subtrahiert: 1 + 3 = 4.",
                             "fehlbild": "addiert_statt_subtrahiert",
                             "socratic_question": "Was musst du auf beiden Seiten tun, damit die 3 neben dem b verschwindet?"},
                            {"error": "Mit dem Kehrwert der Steigung gerechnet: m = 1/3, b = 2/3.",
                             "fehlbild": "steigung_kehrwert",
                             "socratic_question": "Um wie viel geht es nach oben, wenn du einen Schritt nach rechts gehst?"}]'::jsonb;
  get diagnostics v_n = row_count;
  raise notice 'r1: typical_errors ffc76634, % Zeile(n)', v_n;

  -- 6274f6a5: zwei Einträge angehängt.
  update public.task_solutions
     set typical_errors = typical_errors || '[{"error": "Nur ein Dreieck der Raute berechnet: 24 · 5 : 2 = 60 (oder ein Viertel: 12 · 5 : 2 = 30).",
                                               "fehlbild": "teilflaeche_vergessen",
                                               "socratic_question": "Aus wie vielen solchen Dreiecken besteht die Raute?"},
                                              {"error": "Die Dreiecksformel mit der Seite als Grundseite: 13 · 10 : 2 = 65 oder 13 · 24 : 2 = 156.",
                                               "fehlbild": "falsche_hoehe",
                                               "socratic_question": "Steht die Diagonale senkrecht auf der Seite, die du als Grundseite nimmst?"}]'::jsonb,
         updated_at = now()
   where task_id = '6274f6a5-65e5-40f4-be09-36fa8931c424'
     and jsonb_array_length(typical_errors) = 3
     and not typical_errors @> '[{"fehlbild": "teilflaeche_vergessen"}]';
  get diagnostics v_n = row_count;
  raise notice 'r1: typical_errors 6274f6a5, % Zeile(n)', v_n;
end $r1$;
