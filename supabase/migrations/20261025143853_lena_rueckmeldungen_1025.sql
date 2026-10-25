-- L1 (25.10.2026): Lenas Rückfragen vom 25.10. umsetzen. Auswertung: docs/lsa/lena-rueckmeldungen-2026-10-25.md
--
-- Nur Daten, nur die Aufgaben mit Lenas Rückmeldung, je Block über die task_id:
--   1. known_errors in a394b2eb (−3 + 4 · 2) und 6ef85b4a (3/4), vorhandene Fehlbilder, kein neues.
--   2. typical_errors ohne Fehlbild-Slug in 1527a939 und 10a764bc (TERM). TERM darf kein acceptance tragen
--      (lsa_term_acceptance_guard), also auch keine known_errors; Lena sieht die Einträge unter „weitere Hinweise“.
--   3. Aufgabentexte in 3b1e6f0a, 4f0b933d, e8348c89, 7976c81f (question und question_payload.prompt bzw. parts).
--
-- Anders als 20261019100100_l1_lena_fehlbilder wird die Ausgangsfassung (task_pruefung_ausgang) NICHT nachgezogen:
-- Lena soll im Board vorher → nachher sehen (pruef_aufgabe.aenderungen). Die Texte gehören nicht zur Fassung; die
-- vier Aufgaben gehen per pruef_rueckfrage_klaeren('an_lena') an Lena zurück, die Antwort nennt vorher und nachher.
--
-- Jede Änderung nur, wo der Vorher-Stand steht (known_errors: Schlüssel fehlt; Text: alter Text). Ein neuer
-- Schlüssel ist nie gleich canonical oder einer richtigen Antwort. pruef_version zählt per Trigger hoch.
-- Idempotent; im CI-Neuaufbau fehlen die Aufgaben, jeder Block trifft 0 Zeilen. Kein begin/commit: mig klammert.
-- Rollback: supabase/rollback/20261025143853_lena_rueckmeldungen_1025.sql

do $l1b$
declare
  v_n integer;
begin
  -- ── 1. known_errors ─────────────────────────────────────────────────────────
  create temp table l1b_ke (task_id uuid not null, skill_key text not null, schluessel text not null,
                            slug text not null, primary key (task_id, schluessel)) on commit drop;
  insert into l1b_ke (task_id, skill_key, schluessel, slug) values
    -- a394b2eb −3 + 4 · 2 = 5. Lena: „… das Minuszeichen falsch einordnet und -3 + 4 = -7 erhält und dann x2
    -- rechnet = -14“. −14 und −11 (−3 − 8, Vorrang richtig) → plus_minus_vertauscht; 11 (3 + 8) →
    -- vorzeichen_ignoriert wie in 864f0b02 und 573dd0b7.
    ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', 'vorzeichen_vorrang', '-14', 'plus_minus_vertauscht'),
    ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', 'vorzeichen_vorrang', '-11', 'plus_minus_vertauscht'),
    ('a394b2eb-df58-4b57-9c79-ae8ff0c62b24', 'vorzeichen_vorrang', '11',  'vorzeichen_ignoriert'),
    -- 6ef85b4a 3/4 = 0,75. Lena: „… dass falsch gerechnet wurde = 4/3 = 1,3“. 4 : 3 → umgekehrt_geteilt wie
    -- bei 1/2, 1/4, 1/5.
    ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'bruch_dezimal', '1,3',   'umgekehrt_geteilt'),
    ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'bruch_dezimal', '1,33',  'umgekehrt_geteilt'),
    ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'bruch_dezimal', '1,333', 'umgekehrt_geteilt'),
    ('6ef85b4a-1f14-49b4-acf6-05aa01567e4f', 'bruch_dezimal', '4/3',   'umgekehrt_geteilt');

  with d as (
    select s.task_id, jsonb_object_agg(z.schluessel, z.slug) as patch
      from l1b_ke z
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
  raise notice 'l1b: known_errors in % Aufgabe(n) ergänzt', v_n;

  -- ── 2. typical_errors (TERM, ohne Slug) ─────────────────────────────────────
  -- 1527a939 3(x + 2). Lena: „… nur einen Summand mit 3 multiplizieren = 3x + 2“ (wäre klammer_vergessen).
  update public.task_solutions
     set typical_errors = '[{"error": "Nur das erste Glied mit 3 multipliziert: 3x + 2 statt 3x + 6.",
                             "socratic_question": "Womit wird die 2 in der Klammer multipliziert?"}]'::jsonb,
         updated_at = now()
   where task_id = '1527a939-6199-4d8c-9163-6f34b0cd0e13' and typical_errors = '[]'::jsonb;
  get diagnostics v_n = row_count;
  raise notice 'l1b: typical_errors 1527a939, % Zeile(n)', v_n;

  -- 10a764bc −3(x + 2). Lena: „Distributivgesetz nicht vollständig angewendet = -3x + 2 / … Minuszeichen nur
  -- teilweise berücksichtigt = -3x + 6“. Der Satz „in der Form ax + b“ bleibt (TERM-Vergleich zeichengenau).
  update public.task_solutions
     set typical_errors = '[{"error": "Nur das erste Glied mit −3 multipliziert: −3x + 2 statt −3x − 6.",
                             "socratic_question": "Womit wird die 2 in der Klammer multipliziert?"},
                            {"error": "Das Minus nur beim ersten Glied mitgenommen: −3x + 6 statt −3x − 6.",
                             "socratic_question": "Was ergibt (−3) · 2?"}]'::jsonb,
         updated_at = now()
   where task_id = '10a764bc-9657-4a5a-b11d-64b2a0014b05' and typical_errors = '[]'::jsonb;
  get diagnostics v_n = row_count;
  raise notice 'l1b: typical_errors 10a764bc, % Zeile(n)', v_n;

  -- ── 3. Aufgabentexte ────────────────────────────────────────────────────────
  -- 3b1e6f0a 49². Lena: „… formulieren "mit Hilfe einer binom. Formel"“.
  update public.tasks
     set question = E'Berechne geschickt mit Hilfe einer binomischen Formel.\n\n49² = ?',
         question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Berechne geschickt mit Hilfe einer binomischen Formel.\n\n49² = ?'::text))
   where id = '3b1e6f0a-5c2d-4e8b-9f71-2a6d0c4b8e13'
     and question = E'Berechne geschickt mit einer binomischen Formel.\n\n49² = ?'
     and question_payload ->> 'prompt' = E'Berechne geschickt mit einer binomischen Formel.\n\n49² = ?';
  get diagnostics v_n = row_count;
  raise notice 'l1b: Text 3b1e6f0a, % Zeile(n)', v_n;

  -- 4f0b933d Handytarif. Lena: „… in der Teilaufgabe b.) ergänzen: "Wenn die Rechnung 45 Euro beträgt, wie viel
  -- Gigabyte wurden in diesem Monat verbraucht?"“. Nur der Prompt von Teil 2, der Stamm bleibt (Teil 1 braucht 45 €).
  update public.tasks
     set parts = jsonb_set(parts, '{1,prompt}',
           to_jsonb('Wenn die Rechnung 45 € beträgt, wie viele Gigabyte wurden in diesem Monat verbraucht?'::text))
   where id = '4f0b933d-3ead-4042-adb9-a1369ba28f39'
     and parts -> 1 ->> 'nr' = '2'
     and parts -> 1 ->> 'prompt' = 'Wie viele Gigabyte wurden genutzt?';
  get diagnostics v_n = row_count;
  raise notice 'l1b: Text 4f0b933d Teil 2, % Zeile(n)', v_n;

  -- e8348c89 2x + 4 = 20. Lena: „Ich würd hier "Gib den Wert für x an" in der Aufgabenstellung weglassen.“
  update public.tasks
     set question = E'Löse die Gleichung.\n\n2x + 4 = 20',
         question_payload = jsonb_set(question_payload, '{prompt}', to_jsonb(E'Löse die Gleichung.\n\n2x + 4 = 20'::text))
   where id = 'e8348c89-67cb-4650-be91-235e69321776'
     and question = E'Löse die Gleichung. Gib den Wert für x an.\n\n2x + 4 = 20'
     and question_payload ->> 'prompt' = E'Löse die Gleichung. Gib den Wert für x an.\n\n2x + 4 = 20';
  get diagnostics v_n = row_count;
  raise notice 'l1b: Text e8348c89, % Zeile(n)', v_n;

  -- 7976c81f 3x + 6 = 24. Lena: „ebd. "Löse die Gleichung" reicht als Aufgabenstellung.“
  update public.tasks
     set question = E'Löse die Gleichung.\n\n3x + 6 = 24',
         question_payload = jsonb_set(question_payload, '{prompt}', to_jsonb(E'Löse die Gleichung.\n\n3x + 6 = 24'::text))
   where id = '7976c81f-9b0b-46d8-a0d1-b5b6cc3bc992'
     and question = E'Löse die Gleichung. Gib den Wert für x an.\n\n3x + 6 = 24'
     and question_payload ->> 'prompt' = E'Löse die Gleichung. Gib den Wert für x an.\n\n3x + 6 = 24';
  get diagnostics v_n = row_count;
  raise notice 'l1b: Text 7976c81f, % Zeile(n)', v_n;
end $l1b$;
