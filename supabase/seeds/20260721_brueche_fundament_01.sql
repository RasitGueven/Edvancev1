-- ============================================================================
-- Bruch-Fundament, Charge 01 — 28 Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/brueche_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. supabase/seed.sql ist der Stammdaten-Seed (Faecher,
-- Cluster, Tarife) und wird bei `supabase db reset` gezogen. Diese Datei hier
-- ist Inhalt, kein Stammdatum, und wird bewusst von Hand eingespielt:
--     psql "$DATABASE_URL" -f supabase/seeds/20260721_brueche_fundament_01.sql
--
-- SETZT A10 + A11 VORAUS (task_solutions.acceptance, require_reduced, lsa_grade).
--
-- STATUS: alles 'draft'. NICHTS steht auf ready. Die Freigabe ist Lenas
-- Schritt — dieser Seed nimmt sie ihr nicht ab und darf es auch nicht.
--
-- SOLUTION-LEAK: Loesung und Akzeptanz-Set stehen ausschliesslich in
-- task_solutions (kein Grant fuer anon/authenticated). In `tasks` steht nur,
-- was das Kind ohnehin sieht — die Frage. Die Formanforderung
-- ("vollstaendig gekuerzt") gehoert in den FRAGETEXT, weil der Schueler-Payload
-- kein Feld fuer eine Instruktion hat.
--
-- IDEMPOTENT ueber (source, source_ref): zweimal einspielen legt nichts doppelt
-- an. Der Selbsttest am Ende laeuft trotzdem jedes Mal.
-- ============================================================================

begin;

-- ── 0. Voraussetzungen ─────────────────────────────────────────────────────
--
-- Ohne Cluster laege der Content zwar in der Tabelle, waere aber nicht
-- freigebbar (das Gate verlangt cluster_id fuer 'ready') — und niemand wuesste
-- warum. Lieber hier abbrechen als Lena spaeter raten lassen.

do $$
begin
  if not exists (
    select 1 from skill_clusters sc
      join subjects s on s.id = sc.subject_id
     where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen'
  ) then
    raise exception 'Cluster "Zahl & Rechnen" (Mathematik) fehlt — erst supabase/seed.sql einspielen.';
  end if;
  if not exists (select 1 from process_competencies where code = 'Ope') then
    raise exception 'Prozesskompetenz "Ope" fehlt — erst supabase/seed.sql einspielen.';
  end if;
end $$;

-- ── 1. Die Aufgaben ────────────────────────────────────────────────────────

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.titel, v.frage, 'I', 6, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_build_object('kind', 'short_input', 'prompt', v.frage)
from (values
  ('brueche-kuerzen-01', 'Brüche · Kürzen · 18/24', 'Kürze den Bruch vollständig.

18/24 = ?'),
  ('brueche-kuerzen-02', 'Brüche · Kürzen · 12/16', 'Kürze den Bruch vollständig.

12/16 = ?'),
  ('brueche-kuerzen-03', 'Brüche · Kürzen · 8/12', 'Kürze den Bruch vollständig.

8/12 = ?'),
  ('brueche-kuerzen-04', 'Brüche · Kürzen · 16/24', 'Kürze den Bruch vollständig.

16/24 = ?'),
  ('brueche-kuerzen-05', 'Brüche · Kürzen · 12/18', 'Kürze den Bruch vollständig.

12/18 = ?'),
  ('brueche-kuerzen-06', 'Brüche · Kürzen · 20/24', 'Kürze den Bruch vollständig.

20/24 = ?'),
  ('brueche-kuerzen-07', 'Brüche · Kürzen · 4/12', 'Kürze den Bruch vollständig.

4/12 = ?'),
  ('brueche-addieren-01', 'Brüche · Addieren · 1/4 + 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/4 + 2/3 = ?'),
  ('brueche-addieren-02', 'Brüche · Addieren · 1/6 + 1/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/6 + 1/3 = ?'),
  ('brueche-addieren-03', 'Brüche · Addieren · 1/4 + 1/12', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/4 + 1/12 = ?'),
  ('brueche-addieren-04', 'Brüche · Addieren · 1/2 + 1/6', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/2 + 1/6 = ?'),
  ('brueche-addieren-05', 'Brüche · Addieren · 3/4 + 1/8', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

3/4 + 1/8 = ?'),
  ('brueche-addieren-06', 'Brüche · Addieren · 5/12 + 1/4', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

5/12 + 1/4 = ?'),
  ('brueche-addieren-07', 'Brüche · Addieren · 2/9 + 1/6', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

2/9 + 1/6 = ?'),
  ('brueche-multiplizieren-01', 'Brüche · Multiplizieren · 2/3 · 4/5', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

2/3 · 4/5 = ?'),
  ('brueche-multiplizieren-02', 'Brüche · Multiplizieren · 2/3 · 3/4', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

2/3 · 3/4 = ?'),
  ('brueche-multiplizieren-03', 'Brüche · Multiplizieren · 3/4 · 2/5', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

3/4 · 2/5 = ?'),
  ('brueche-multiplizieren-04', 'Brüche · Multiplizieren · 1/2 · 3/5', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/2 · 3/5 = ?'),
  ('brueche-multiplizieren-05', 'Brüche · Multiplizieren · 4/5 · 5/6', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

4/5 · 5/6 = ?'),
  ('brueche-multiplizieren-06', 'Brüche · Multiplizieren · 3/8 · 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

3/8 · 2/3 = ?'),
  ('brueche-multiplizieren-07', 'Brüche · Multiplizieren · 5/6 · 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

5/6 · 2/3 = ?'),
  ('brueche-dividieren-01', 'Brüche · Dividieren · 2/3 : 4/5', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

2/3 : 4/5 = ?'),
  ('brueche-dividieren-02', 'Brüche · Dividieren · 1/2 : 3/4', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

1/2 : 3/4 = ?'),
  ('brueche-dividieren-03', 'Brüche · Dividieren · 3/4 : 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

3/4 : 2/3 = ?'),
  ('brueche-dividieren-04', 'Brüche · Dividieren · 2/5 : 3/4', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

2/5 : 3/4 = ?'),
  ('brueche-dividieren-05', 'Brüche · Dividieren · 3/8 : 3/4', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

3/8 : 3/4 = ?'),
  ('brueche-dividieren-06', 'Brüche · Dividieren · 5/6 : 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

5/6 : 2/3 = ?'),
  ('brueche-dividieren-07', 'Brüche · Dividieren · 4/9 : 2/3', 'Berechne. Gib das Ergebnis als vollständig gekürzten Bruch an.

4/9 : 2/3 = ?')
) as v(source_ref, titel, frage)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung + Akzeptanz-Set (Server-Only-Zone) ──────────────────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('brueche-kuerzen-01', '["3/4"]', '{"canonical": "3/4", "require_reduced": true}'),
  ('brueche-kuerzen-02', '["3/4"]', '{"canonical": "3/4", "require_reduced": true}'),
  ('brueche-kuerzen-03', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-kuerzen-04', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-kuerzen-05', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-kuerzen-06', '["5/6"]', '{"canonical": "5/6", "require_reduced": true}'),
  ('brueche-kuerzen-07', '["1/3"]', '{"canonical": "1/3", "require_reduced": true}'),
  ('brueche-addieren-01', '["11/12"]', '{"canonical": "11/12", "require_reduced": true}'),
  ('brueche-addieren-02', '["1/2"]', '{"canonical": "1/2", "require_reduced": true}'),
  ('brueche-addieren-03', '["1/3"]', '{"canonical": "1/3", "require_reduced": true}'),
  ('brueche-addieren-04', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-addieren-05', '["7/8"]', '{"canonical": "7/8", "require_reduced": true}'),
  ('brueche-addieren-06', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-addieren-07', '["7/18"]', '{"canonical": "7/18", "require_reduced": true}'),
  ('brueche-multiplizieren-01', '["8/15"]', '{"canonical": "8/15", "require_reduced": true}'),
  ('brueche-multiplizieren-02', '["1/2"]', '{"canonical": "1/2", "require_reduced": true}'),
  ('brueche-multiplizieren-03', '["3/10"]', '{"canonical": "3/10", "require_reduced": true}'),
  ('brueche-multiplizieren-04', '["3/10"]', '{"canonical": "3/10", "require_reduced": true}'),
  ('brueche-multiplizieren-05', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-multiplizieren-06', '["1/4"]', '{"canonical": "1/4", "require_reduced": true}'),
  ('brueche-multiplizieren-07', '["5/9"]', '{"canonical": "5/9", "require_reduced": true}'),
  ('brueche-dividieren-01', '["5/6"]', '{"canonical": "5/6", "require_reduced": true}'),
  ('brueche-dividieren-02', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}'),
  ('brueche-dividieren-03', '["9/8"]', '{"canonical": "9/8", "require_reduced": true}'),
  ('brueche-dividieren-04', '["8/15"]', '{"canonical": "8/15", "require_reduced": true}'),
  ('brueche-dividieren-05', '["1/2"]', '{"canonical": "1/2", "require_reduced": true}'),
  ('brueche-dividieren-06', '["5/4"]', '{"canonical": "5/4", "require_reduced": true}'),
  ('brueche-dividieren-07', '["2/3"]', '{"canonical": "2/3", "require_reduced": true}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Selbsttest: urteilt lsa_grade so, wie die Didaktik es will? ─────────
--
-- Das Skript, das diese Datei erzeugt hat, kennt die Bewertungsfunktion NICHT
-- und baut sie auch nicht nach — zwei Wahrheiten ueber "was zaehlt als richtig"
-- waeren genau der Fehler, den die Server-Only-Zone verhindern soll. Statt zu
-- behaupten, fragt die Datei hier die Datenbank:
--
--   die gekuerzte Loesung        -> 'voll'
--   dieselbe Zahl, ungekuerzt    -> 'teilweise'   (die diagnostische Zwischenstufe)
--   jedes Fehlbild               -> 'nicht'
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- eingespielt. Lieber kein Content als Content, der falsch bewertet wird.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
begin
  for r in
    select * from (values
      ('brueche-kuerzen-01', '3/4', 'voll', '—'),
      ('brueche-kuerzen-01', '9/12', 'teilweise', '—'),
      ('brueche-kuerzen-01', '17/23', 'nicht', 'additiv'),
      ('brueche-kuerzen-02', '3/4', 'voll', '—'),
      ('brueche-kuerzen-02', '6/8', 'teilweise', '—'),
      ('brueche-kuerzen-02', '11/15', 'nicht', 'additiv'),
      ('brueche-kuerzen-03', '2/3', 'voll', '—'),
      ('brueche-kuerzen-03', '4/6', 'teilweise', '—'),
      ('brueche-kuerzen-03', '7/11', 'nicht', 'additiv'),
      ('brueche-kuerzen-04', '2/3', 'voll', '—'),
      ('brueche-kuerzen-04', '8/12', 'teilweise', '—'),
      ('brueche-kuerzen-04', '15/23', 'nicht', 'additiv'),
      ('brueche-kuerzen-05', '2/3', 'voll', '—'),
      ('brueche-kuerzen-05', '6/9', 'teilweise', '—'),
      ('brueche-kuerzen-05', '11/17', 'nicht', 'additiv'),
      ('brueche-kuerzen-06', '5/6', 'voll', '—'),
      ('brueche-kuerzen-06', '10/12', 'teilweise', '—'),
      ('brueche-kuerzen-06', '19/23', 'nicht', 'additiv'),
      ('brueche-kuerzen-07', '1/3', 'voll', '—'),
      ('brueche-kuerzen-07', '2/6', 'teilweise', '—'),
      ('brueche-kuerzen-07', '3/11', 'nicht', 'additiv'),
      ('brueche-addieren-01', '11/12', 'voll', '—'),
      ('brueche-addieren-01', '3/7', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-02', '1/2', 'voll', '—'),
      ('brueche-addieren-02', '3/6', 'teilweise', '—'),
      ('brueche-addieren-02', '2/9', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-03', '1/3', 'voll', '—'),
      ('brueche-addieren-03', '4/12', 'teilweise', '—'),
      ('brueche-addieren-03', '2/16', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-04', '2/3', 'voll', '—'),
      ('brueche-addieren-04', '4/6', 'teilweise', '—'),
      ('brueche-addieren-04', '2/8', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-05', '7/8', 'voll', '—'),
      ('brueche-addieren-05', '4/12', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-06', '2/3', 'voll', '—'),
      ('brueche-addieren-06', '8/12', 'teilweise', '—'),
      ('brueche-addieren-06', '6/16', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-addieren-07', '7/18', 'voll', '—'),
      ('brueche-addieren-07', '3/15', 'nicht', 'zaehler_plus_nenner'),
      ('brueche-multiplizieren-01', '8/15', 'voll', '—'),
      ('brueche-multiplizieren-01', '10/12', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-01', '22/15', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-02', '1/2', 'voll', '—'),
      ('brueche-multiplizieren-02', '6/12', 'teilweise', '—'),
      ('brueche-multiplizieren-02', '8/9', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-02', '17/12', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-03', '3/10', 'voll', '—'),
      ('brueche-multiplizieren-03', '6/20', 'teilweise', '—'),
      ('brueche-multiplizieren-03', '15/8', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-03', '23/20', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-04', '3/10', 'voll', '—'),
      ('brueche-multiplizieren-04', '5/6', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-04', '11/10', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-05', '2/3', 'voll', '—'),
      ('brueche-multiplizieren-05', '20/30', 'teilweise', '—'),
      ('brueche-multiplizieren-05', '24/25', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-05', '49/30', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-06', '1/4', 'voll', '—'),
      ('brueche-multiplizieren-06', '6/24', 'teilweise', '—'),
      ('brueche-multiplizieren-06', '9/16', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-06', '25/24', 'nicht', 'additionsregel'),
      ('brueche-multiplizieren-07', '5/9', 'voll', '—'),
      ('brueche-multiplizieren-07', '10/18', 'teilweise', '—'),
      ('brueche-multiplizieren-07', '15/12', 'nicht', 'ueber_kreuz'),
      ('brueche-multiplizieren-07', '9/6', 'nicht', 'additionsregel'),
      ('brueche-dividieren-01', '5/6', 'voll', '—'),
      ('brueche-dividieren-01', '10/12', 'teilweise', '—'),
      ('brueche-dividieren-01', '8/15', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-01', '12/10', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-02', '2/3', 'voll', '—'),
      ('brueche-dividieren-02', '4/6', 'teilweise', '—'),
      ('brueche-dividieren-02', '3/8', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-02', '6/4', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-03', '9/8', 'voll', '—'),
      ('brueche-dividieren-03', '6/12', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-03', '8/9', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-04', '8/15', 'voll', '—'),
      ('brueche-dividieren-04', '6/20', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-04', '15/8', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-05', '1/2', 'voll', '—'),
      ('brueche-dividieren-05', '12/24', 'teilweise', '—'),
      ('brueche-dividieren-05', '9/32', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-05', '24/12', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-06', '5/4', 'voll', '—'),
      ('brueche-dividieren-06', '15/12', 'teilweise', '—'),
      ('brueche-dividieren-06', '10/18', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-06', '12/15', 'nicht', 'falsch_gestuerzt'),
      ('brueche-dividieren-07', '2/3', 'voll', '—'),
      ('brueche-dividieren-07', '12/18', 'teilweise', '—'),
      ('brueche-dividieren-07', '8/27', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-07', '18/12', 'nicht', 'falsch_gestuerzt')
    ) as p(source_ref, antwort, erwartet, fehlbild)
  loop
    select public.lsa_grade(
             'NUMERIC',
             s.acceptance,
             s.correct_answers,
             jsonb_build_object('value', r.antwort)
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (Fehlbild %)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.fehlbild;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  raise notice 'Bruch-Fundament: alle Proben bestanden.';
end $$;

commit;
