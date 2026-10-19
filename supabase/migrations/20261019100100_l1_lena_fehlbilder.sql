-- L1 (M1): Lenas Rückfragen vom 19.10.2026 umsetzen: zwei neue Fehlbilder, Antwortregeln, ein Aufgabentext.
--
-- 1. Zwei neue Fehlbilder, je mit eigener, freigegebener Familie, damit der Elterntext wörtlich im Report steht
--    (der Report zeigt je Familie nur fehlbild_familien.elterntext, lsa_fehlbild_auswertung):
--      plus_minus_vertauscht   Plus und Minus vertauscht (Zahlenstrahl, falsche Richtung)
--      merksatz_als_addition   „Minus mal Minus gibt Plus“ als Rechenanweisung, addiert
--    Dazu der Klartext von vorzeichen_ignoriert verallgemeinert (nur wo der Vorher-Text steht), weil der Slug nach
--    Schritt 2 auch für „Vorzeichen der ersten Zahl übersehen“ steht; die Daten bleiben.
--    Der Wunsch-Slug richtung_vertauscht ist schon belegt: Maßstab (teilt statt malzunehmen), Familie
--    einheiten_massstab, 49 Schlüssel in groessen_* und geo_massstab. Ein Slug mit der Bedeutung „Plus und Minus
--    vertauscht“ oder „Merksatz als Addition“ existiert nicht (dbread, 19.10.2026). Per on conflict do nothing.
-- 2. known_errors aller Aufgaben von vorzeichen_add_sub und vorzeichen_mult_div:
--      a ± b (b positiv, ohne Klammer): a ∓ b → plus_minus_vertauscht
--      (−a) · (−b): −a + b → merksatz_als_addition; Division bleibt unberührt (mit Lena abgestimmt)
--      betrag_fehler nur für „gleicher Betrag, umgekehrtes Vorzeichen“; 27f51c08 und e96cd37d hatten die Werte
--      von betrag_fehler und vorzeichen_ignoriert vertauscht.
--    Ausgelassen (Wert schon unter einem anderen Fehlbild): 3e6fb055 (2 − 9, „11“) und 738de19f (3 − 8, „11“),
--    beide vorzeichen_ignoriert. typical_errors sind in beiden Fertigkeiten leer und bleiben leer.
--    Jeder Schlüssel nur, wo der Vorher-Wert steht (neu: Schlüssel fehlt), und nie gleich canonical/equivalents.
--    Dieselben Schlüssel in der eingefrorenen Ausgangsfassung (task_pruefung_ausgang.ausgang.acceptance), damit
--    die Änderung auf Lenas Board weder als ihre eigene noch als Abweichung erscheint.
-- 3. 0b7e781c (Wurzeln 1 bis 60): Aufgabentext ohne n (question und question_payload.prompt), Lösungstext ohne n.
--    Rechnung, Titel, AFB (II) und est_duration_sec (90) bleiben. Die Ziffernfolge des Texts ändert sich
--    (1, 2, 3, …, 60); tasks_zahlen_guard greift nur für current_user = 'authenticated', diese Migration läuft
--    als postgres.
--
-- pruef_version zählt per Trigger hoch. lsa_responses enthält für beide Fertigkeiten keine Zeile; es gibt nichts
-- nachzuziehen. Idempotent; in der CI ohne die Aufgaben nur Schritt 1. Kein begin/commit: mig klammert mit psql -1.

do $l1$
declare
  v_rasit uuid := (select p.id from public.profiles p where p.id = '35e4f9ac-d9aa-421c-8ba8-3948b1575f41');
  v_n integer;
begin
  -- ── 1. Familien und Fehlbilder ─────────────────────────────────────────────
  insert into public.fehlbild_familien (schluessel, elterntext, freigegeben_am, freigegeben_von)
  values
    ('plus_minus_vertauscht',
     'Beim Rechnen mit negativen Zahlen geht Ihr Kind auf dem Zahlenstrahl manchmal in die falsche Richtung: Aus einem Plus wird ein Minus oder umgekehrt.',
     now(), v_rasit),
    ('merksatz_als_addition',
     'Ihr Kind kennt die Regel ‚Minus mal Minus ergibt Plus‘, versteht sie aber als Rechenanweisung und rechnet Plus statt Mal.',
     now(), v_rasit)
  on conflict (schluessel) do nothing;
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: % neue Familie(n)', v_n;

  insert into public.fehlbild_labels (slug, klartext, erklaerung, familie, freigegeben_am, freigegeben_von)
  values
    ('plus_minus_vertauscht',
     'Plus und Minus vertauscht, auf dem Zahlenstrahl in die falsche Richtung gegangen.',
     'Bei −4 + 9 startet man auf dem Zahlenstrahl bei −4 und geht 9 Schritte nach rechts; man landet bei 5. Wer Plus und Minus vertauscht, geht nach links und landet bei −13. Die Zahl der Schritte stimmt, nur die Richtung nicht. Geübt wird, vor dem Losgehen zu sagen: Plus heißt nach rechts, Minus heißt nach links.',
     'plus_minus_vertauscht', now(), v_rasit),
    ('merksatz_als_addition',
     '„Minus mal Minus gibt Plus“ als Rechenanweisung missverstanden und addiert.',
     'Der Satz „Minus mal Minus ergibt Plus“ sagt nur, welches Vorzeichen das Ergebnis einer Malaufgabe bekommt. Wer ihn als Rechenanweisung liest, macht aus −4 · (−6) die Rechnung −4 + 6 = 2. Richtig wird erst der Betrag ausgerechnet, 4 · 6 = 24, dann legt die Regel das Vorzeichen fest: +24. Geübt wird, Betrag und Vorzeichen in zwei getrennten Schritten zu bestimmen.',
     'merksatz_als_addition', now(), v_rasit)
  on conflict (slug) do nothing;
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: % neue(s) Fehlbild(er)', v_n;

  -- vorzeichen_ignoriert trägt nach Schritt 2 auch „Vorzeichen der ersten Zahl übersehen“ (−6 − 2 → 4):
  -- Klartext verallgemeinern. Der Elterntext der Familie vorzeichen ist schon allgemein und bleibt.
  update public.fehlbild_labels
     set klartext = 'Rechnet nur mit den Beträgen und lässt Minuszeichen weg (z. B. −4 + 9 als 4 + 9, −6 − 2 als 6 − 2).'
   where slug = 'vorzeichen_ignoriert'
     and klartext = 'Lässt die Minuszeichen weg und addiert die Beträge.';
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: vorzeichen_ignoriert Klartext, % Zeile(n)', v_n;

  -- ── 2. known_errors (alt null = Schlüssel fehlt bisher) ─────────────────────
  create temp table l1_ke (task_id uuid not null, skill_key text not null, schluessel text not null,
                           alt text, neu text not null, primary key (task_id, schluessel)) on commit drop;
  insert into l1_ke (task_id, skill_key, schluessel, alt, neu) values
    -- −3 − 5 = −8
    ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf', 'vorzeichen_add_sub', '2',   null,                   'plus_minus_vertauscht'),
    ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf', 'vorzeichen_add_sub', '8',   'vorzeichen_ignoriert', 'betrag_fehler'),
    ('e96cd37d-0254-4051-bf2d-71a6f7fa2aaf', 'vorzeichen_add_sub', '-2',  'betrag_fehler',        'vorzeichen_ignoriert'),
    -- −4 + 9 = 5
    ('17674b19-fe14-42ca-98db-6598fa8c5a3a', 'vorzeichen_add_sub', '-13', null,                   'plus_minus_vertauscht'),
    -- −6 − 2 = −8
    ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf', 'vorzeichen_add_sub', '-4',  null,                   'plus_minus_vertauscht'),
    ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf', 'vorzeichen_add_sub', '8',   'vorzeichen_ignoriert', 'betrag_fehler'),
    ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf', 'vorzeichen_add_sub', '4',   'betrag_fehler',        'vorzeichen_ignoriert'),
    -- −7 + 4 = −3
    ('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0', 'vorzeichen_add_sub', '-11', null,                   'plus_minus_vertauscht'),
    -- −9 + 5 = −4
    ('3b44eada-3589-4bdb-a33b-2fb2ca0a1726', 'vorzeichen_add_sub', '-14', null,                   'plus_minus_vertauscht'),
    -- −4 · (−6) = 24
    ('2e8ce53f-1357-48b2-8d76-0633ae836980', 'vorzeichen_mult_div', '2',  null,                   'merksatz_als_addition'),
    -- −8 · (−3) = 24
    ('e58cb290-db86-40df-b60b-03aee393107b', 'vorzeichen_mult_div', '-5', null,                   'merksatz_als_addition');

  with d as (
    select s.task_id, jsonb_object_agg(z.schluessel, z.neu) as patch
      from l1_ke z
      join public.tasks t on t.id = z.task_id and t.skill_key = z.skill_key
      join public.task_solutions s on s.task_id = z.task_id
     where jsonb_typeof(s.acceptance -> 'known_errors') = 'object'
       and (s.acceptance -> 'known_errors' ->> z.schluessel) is not distinct from z.alt
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
  raise notice 'l1_lena_fehlbilder: known_errors in % Aufgabe(n) geändert', v_n;

  with d as (
    select a.task_id, jsonb_object_agg(z.schluessel, z.neu) as patch
      from l1_ke z
      join public.task_pruefung_ausgang a on a.task_id = z.task_id
     where a.ausgang ->> 'skill_key' = z.skill_key
       and jsonb_typeof(a.ausgang -> 'acceptance' -> 'known_errors') = 'object'
       and (a.ausgang -> 'acceptance' -> 'known_errors' ->> z.schluessel) is not distinct from z.alt
     group by a.task_id)
  update public.task_pruefung_ausgang a
     set ausgang = jsonb_set(a.ausgang, '{acceptance,known_errors}', (a.ausgang -> 'acceptance' -> 'known_errors') || d.patch)
    from d
   where a.task_id = d.task_id;
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: Ausgangsfassung in % Aufgabe(n) nachgezogen', v_n;

  -- ── 3. Aufgabentext 0b7e781c ────────────────────────────────────────────────
  update public.tasks
     set question = E'Wie viele der Zahlen 1, 2, 3, …, 60 haben eine Quadratwurzel, die eine rationale Zahl ist?\n\nGib die Anzahl als ganze Zahl an.'
   where id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
     and question = E'Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl?\n\nGib die Anzahl als ganze Zahl an.';
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: question, % Zeile(n)', v_n;

  update public.tasks
     set question_payload = jsonb_set(question_payload, '{prompt}',
           to_jsonb(E'Wie viele der Zahlen 1, 2, 3, …, 60 haben eine Quadratwurzel, die eine rationale Zahl ist?\n\nGib die Anzahl als ganze Zahl an.'::text))
   where id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
     and question_payload ->> 'prompt' = E'Für wie viele natürliche Zahlen n von 1 bis 60 (jeweils einschließlich) ist √n eine rationale Zahl?\n\nGib die Anzahl als ganze Zahl an.';
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: question_payload.prompt, % Zeile(n)', v_n;

  update public.task_solutions
     set solution = E'Die Quadratwurzel einer natürlichen Zahl ist genau dann rational, wenn die Zahl eine Quadratzahl ist.\nQuadratzahlen von 1 bis 60: 1, 4, 9, 16, 25, 36, 49 (64 ist schon zu groß).\nAnzahl: 7.',
         updated_at = now()
   where task_id = '0b7e781c-60ae-4a93-afb8-2ee2b400b15a'
     and solution = E'√n ist für eine natürliche Zahl n genau dann rational, wenn n eine Quadratzahl ist.\nQuadratzahlen von 1 bis 60: 1, 4, 9, 16, 25, 36, 49 (64 ist schon zu groß).\nAnzahl: 7.';
  get diagnostics v_n = row_count;
  raise notice 'l1_lena_fehlbilder: Lösungstext, % Zeile(n)', v_n;
end $l1$;
