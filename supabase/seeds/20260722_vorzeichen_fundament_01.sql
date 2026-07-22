-- ============================================================================
-- Vorzeichen-Fundament, Charge 01 — 21 Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/vorzeichen_fundament.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH:
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_vorzeichen_fundament_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
--
-- STATUS: alles 'draft'. NICHTS steht auf ready — die Freigabe ist Lenas
-- Schritt, und dieser Seed nimmt sie ihr nicht ab.
--
-- BINAER, NICHT DREISTUFIG: "-3 - 5 = -8" ist richtig oder falsch. Es gibt
-- nichts zu kuerzen und keine Form zu verfehlen, also kein require_reduced und
-- kein 'teilweise'. Genau deshalb tragen diese Aufgaben known_errors von
-- Anfang an: bei binaerer Bewertung sind die Fehlbilder die EINZIGE
-- Feindiagnostik, die der Typ hergibt.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder stehen ausschliesslich
-- in task_solutions (kein Grant fuer anon/authenticated). In `tasks` steht nur
-- die Frage.
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

-- ── 0. Voraussetzungen ─────────────────────────────────────────────────────

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
  if to_regprocedure('public.lsa_grade(text,jsonb,jsonb,jsonb)') is null then
    raise exception 'lsa_grade fehlt — A11 ist nicht eingespielt.';
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
  v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_build_object('kind', 'short_input', 'prompt', v.frage)
from (values
  ('vorzeichen-addieren-01', 'Vorzeichen · Addieren · -3 - 5', 'Berechne.

-3 - 5 = ?', 'I'),
  ('vorzeichen-addieren-02', 'Vorzeichen · Addieren · -7 + 4', 'Berechne.

-7 + 4 = ?', 'I'),
  ('vorzeichen-addieren-03', 'Vorzeichen · Addieren · 2 - 9', 'Berechne.

2 - 9 = ?', 'I'),
  ('vorzeichen-addieren-04', 'Vorzeichen · Addieren · -6 - 2', 'Berechne.

-6 - 2 = ?', 'I'),
  ('vorzeichen-addieren-05', 'Vorzeichen · Addieren · -4 + 9', 'Berechne.

-4 + 9 = ?', 'I'),
  ('vorzeichen-addieren-06', 'Vorzeichen · Addieren · 3 - 8', 'Berechne.

3 - 8 = ?', 'I'),
  ('vorzeichen-addieren-07', 'Vorzeichen · Addieren · -9 + 5', 'Berechne.

-9 + 5 = ?', 'I'),
  ('vorzeichen-punktrechnung-01', 'Vorzeichen · Multiplizieren · -3 · 5', 'Berechne.

-3 · 5 = ?', 'I'),
  ('vorzeichen-punktrechnung-02', 'Vorzeichen · Multiplizieren · -4 · (-6)', 'Berechne.

-4 · (-6) = ?', 'I'),
  ('vorzeichen-punktrechnung-03', 'Vorzeichen · Dividieren · -20 : 4', 'Berechne.

-20 : 4 = ?', 'I'),
  ('vorzeichen-punktrechnung-04', 'Vorzeichen · Multiplizieren · 7 · (-3)', 'Berechne.

7 · (-3) = ?', 'I'),
  ('vorzeichen-punktrechnung-05', 'Vorzeichen · Multiplizieren · -8 · (-3)', 'Berechne.

-8 · (-3) = ?', 'I'),
  ('vorzeichen-punktrechnung-06', 'Vorzeichen · Dividieren · -36 : (-6)', 'Berechne.

-36 : (-6) = ?', 'I'),
  ('vorzeichen-punktrechnung-07', 'Vorzeichen · Dividieren · 24 : (-4)', 'Berechne.

24 : (-4) = ?', 'I'),
  ('vorzeichen-vorrang-01', 'Vorzeichen · Vorrang · 4 + (-2) · 3', 'Berechne.

4 + (-2) · 3 = ?', 'II'),
  ('vorzeichen-vorrang-02', 'Vorzeichen · Vorrang · 5 - 2 · (-3)', 'Berechne.

5 - 2 · (-3) = ?', 'II'),
  ('vorzeichen-vorrang-03', 'Vorzeichen · Vorrang · -3 + 4 · 2', 'Berechne.

-3 + 4 · 2 = ?', 'II'),
  ('vorzeichen-vorrang-04', 'Vorzeichen · Vorrang · 6 + (-3) · 4', 'Berechne.

6 + (-3) · 4 = ?', 'II'),
  ('vorzeichen-vorrang-05', 'Vorzeichen · Vorrang · -2 - 3 · (-4)', 'Berechne.

-2 - 3 · (-4) = ?', 'II'),
  ('vorzeichen-vorrang-06', 'Vorzeichen · Vorrang · 8 + (-5) · 2', 'Berechne.

8 + (-5) · 2 = ?', 'II'),
  ('vorzeichen-vorrang-07', 'Vorzeichen · Vorrang · 3 - 4 · (-2)', 'Berechne.

3 - 4 · (-2) = ?', 'II')
) as v(source_ref, titel, frage, afb)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung, Akzeptanz-Set und Fehlbilder (Server-Only-Zone) ────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('vorzeichen-addieren-01', '["-8"]', '{"canonical": "-8", "known_errors": {"15": "mult_add_verwechslung", "-2": "betrag_fehler", "8": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-02', '["-3"]', '{"canonical": "-3", "known_errors": {"-28": "mult_add_verwechslung", "3": "betrag_fehler", "11": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-03', '["-7"]', '{"canonical": "-7", "known_errors": {"-18": "mult_add_verwechslung", "7": "betrag_fehler", "11": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-04', '["-8"]', '{"canonical": "-8", "known_errors": {"12": "mult_add_verwechslung", "4": "betrag_fehler", "8": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-05', '["5"]', '{"canonical": "5", "known_errors": {"-36": "mult_add_verwechslung", "-5": "betrag_fehler", "13": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-06', '["-5"]', '{"canonical": "-5", "known_errors": {"-24": "mult_add_verwechslung", "5": "betrag_fehler", "11": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-addieren-07', '["-4"]', '{"canonical": "-4", "known_errors": {"-45": "mult_add_verwechslung", "4": "betrag_fehler", "14": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-punktrechnung-01', '["-15"]', '{"canonical": "-15", "known_errors": {"15": "vorzeichen_ignoriert", "2": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-02', '["24"]', '{"canonical": "24", "known_errors": {"-24": "vorzeichen_ignoriert", "-10": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-03', '["-5"]', '{"canonical": "-5", "known_errors": {"5": "vorzeichen_ignoriert", "-16": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-04', '["-21"]', '{"canonical": "-21", "known_errors": {"21": "vorzeichen_ignoriert", "4": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-05', '["24"]', '{"canonical": "24", "known_errors": {"-24": "vorzeichen_ignoriert", "-11": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-06', '["6"]', '{"canonical": "6", "known_errors": {"-6": "vorzeichen_ignoriert", "-42": "mult_add_verwechslung"}}'),
  ('vorzeichen-punktrechnung-07', '["-6"]', '{"canonical": "-6", "known_errors": {"6": "vorzeichen_ignoriert", "20": "mult_add_verwechslung"}}'),
  ('vorzeichen-vorrang-01', '["-2"]', '{"canonical": "-2", "known_errors": {"6": "vorrang_ignoriert", "10": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-vorrang-02', '["11"]', '{"canonical": "11", "known_errors": {"-9": "vorrang_ignoriert", "-1": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-vorrang-03', '["5"]', '{"canonical": "5", "known_errors": {"2": "vorrang_ignoriert"}}'),
  ('vorzeichen-vorrang-04', '["-6"]', '{"canonical": "-6", "known_errors": {"12": "vorrang_ignoriert", "18": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-vorrang-05', '["10"]', '{"canonical": "10", "known_errors": {"20": "vorrang_ignoriert", "-14": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-vorrang-06', '["-2"]', '{"canonical": "-2", "known_errors": {"6": "vorrang_ignoriert", "18": "vorzeichen_ignoriert"}}'),
  ('vorzeichen-vorrang-07', '["11"]', '{"canonical": "11", "known_errors": {"2": "vorrang_ignoriert", "-5": "vorzeichen_ignoriert"}}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Proben: urteilt lsa_grade so, wie die Didaktik es will? ─────────────
--
-- Der Generator kennt die Bewertungsfunktion NICHT und baut sie nicht nach —
-- zwei Wahrheiten ueber "was zaehlt als richtig" waeren genau der Fehler, den
-- die Server-Only-Zone verhindern soll. Statt zu behaupten, fragt die Datei
-- hier die Datenbank:
--
--   die korrekte Zahl -> 'voll'
--   jeder Fehlbildwert -> 'nicht'
--
-- MIT NEGATIVKONTROLLE: die letzte Zeile der Probenliste ist ABSICHTLICH
-- falsch erwartet. Laeuft der Block gruen durch, ohne sie zu melden, prueft er
-- nichts — dann ist der Selbsttest selbst kaputt. Erwartet wird also GENAU EIN
-- gemeldeter Fehler, und der Block sagt das ausdruecklich.

do $$
declare
  r             record;
  v_urteil      text;
  v_echte       int := 0;
  v_kontrolle   int := 0;
begin
  for r in
    select * from (values
      ('vorzeichen-addieren-01', '-8', 'voll', '—', false),
      ('vorzeichen-addieren-01', '15', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-01', '-2', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-01', '8', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-02', '-3', 'voll', '—', false),
      ('vorzeichen-addieren-02', '-28', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-02', '3', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-02', '11', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-03', '-7', 'voll', '—', false),
      ('vorzeichen-addieren-03', '-18', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-03', '7', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-03', '11', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-04', '-8', 'voll', '—', false),
      ('vorzeichen-addieren-04', '12', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-04', '4', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-04', '8', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-05', '5', 'voll', '—', false),
      ('vorzeichen-addieren-05', '-36', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-05', '-5', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-05', '13', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-06', '-5', 'voll', '—', false),
      ('vorzeichen-addieren-06', '-24', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-06', '5', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-06', '11', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-07', '-4', 'voll', '—', false),
      ('vorzeichen-addieren-07', '-45', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-addieren-07', '4', 'nicht', 'betrag_fehler', false),
      ('vorzeichen-addieren-07', '14', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-01', '-15', 'voll', '—', false),
      ('vorzeichen-punktrechnung-01', '15', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-01', '2', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-02', '24', 'voll', '—', false),
      ('vorzeichen-punktrechnung-02', '-24', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-02', '-10', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-03', '-5', 'voll', '—', false),
      ('vorzeichen-punktrechnung-03', '5', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-03', '-16', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-04', '-21', 'voll', '—', false),
      ('vorzeichen-punktrechnung-04', '21', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-04', '4', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-05', '24', 'voll', '—', false),
      ('vorzeichen-punktrechnung-05', '-24', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-05', '-11', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-06', '6', 'voll', '—', false),
      ('vorzeichen-punktrechnung-06', '-6', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-06', '-42', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-punktrechnung-07', '-6', 'voll', '—', false),
      ('vorzeichen-punktrechnung-07', '6', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-punktrechnung-07', '20', 'nicht', 'mult_add_verwechslung', false),
      ('vorzeichen-vorrang-01', '-2', 'voll', '—', false),
      ('vorzeichen-vorrang-01', '6', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-01', '10', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-vorrang-02', '11', 'voll', '—', false),
      ('vorzeichen-vorrang-02', '-9', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-02', '-1', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-vorrang-03', '5', 'voll', '—', false),
      ('vorzeichen-vorrang-03', '2', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-04', '-6', 'voll', '—', false),
      ('vorzeichen-vorrang-04', '12', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-04', '18', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-vorrang-05', '10', 'voll', '—', false),
      ('vorzeichen-vorrang-05', '20', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-05', '-14', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-vorrang-06', '-2', 'voll', '—', false),
      ('vorzeichen-vorrang-06', '6', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-06', '18', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-vorrang-07', '11', 'voll', '—', false),
      ('vorzeichen-vorrang-07', '2', 'nicht', 'vorrang_ignoriert', false),
      ('vorzeichen-vorrang-07', '-5', 'nicht', 'vorzeichen_ignoriert', false),
      ('vorzeichen-addieren-01', '-8', 'nicht', 'NEGATIVKONTROLLE', true)
    ) as p(source_ref, antwort, erwartet, label, ist_kontrolle)
  loop
    select public.lsa_grade(
             'NUMERIC', s.acceptance, s.correct_answers,
             jsonb_build_object('value', r.antwort)
           )
      into v_urteil
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      if r.ist_kontrolle then
        v_kontrolle := v_kontrolle + 1;
        raise notice 'Negativkontrolle hat angeschlagen (so soll es sein): %/% ist %, erwartet war absichtlich %',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet;
      else
        v_echte := v_echte + 1;
        raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.label;
      end if;
    end if;
  end loop;

  if v_echte > 0 then
    raise exception '% echte Probe(n) fehlgeschlagen — nichts eingespielt.', v_echte;
  end if;

  -- Ein Selbsttest, der nie anschlaegt, beweist nichts. Schlaegt die
  -- Negativkontrolle NICHT an, prueft die Schleife in Wahrheit gar nichts.
  if v_kontrolle <> 1 then
    raise exception 'Negativkontrolle hat NICHT angeschlagen — die Probenschleife prueft nichts.';
  end if;

  raise notice 'Vorzeichen-Fundament: alle echten Proben bestanden, Negativkontrolle greift.';
end $$;

commit;
