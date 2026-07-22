-- ============================================================================
-- Dezimalzahlen, Charge 01 — 26 Aufgaben als DRAFT
--
-- ERZEUGT von scripts/content/dezimalzahlen.py. Nicht von Hand pflegen.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/seeds/20260722_dezimalzahlen_01.sql
--
-- SETZT A11 (lsa_grade) UND A12 (known_errors) VORAUS.
-- STATUS: alles 'draft'. Die Freigabe ist Lenas Schritt.
--
-- SCHREIBWEISE: lsa_values_equal vergleicht WERTGLEICH — "0,30" und "0,3" sind
-- dieselbe Zahl (live geprueft). Deshalb steht jedes Fehlbild in genau EINER
-- Form, der kuerzesten. Und deshalb prueft das Sieb die Trennschaerfe auf
-- WERTEN: ein Fehlbild, das wertgleich zur Loesung waere, ginge sonst als
-- 'voll' durch — es waere kein Fehlbild, sondern eine zweite richtige Antwort.
--
-- BINAER: kein require_reduced, kein 'teilweise'. Deshalb known_errors ueberall.
--
-- SOLUTION-LEAK: Loesung, Akzeptanz-Set und Fehlbilder ausschliesslich in
-- task_solutions. In `tasks` steht nur die Frage.
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
  v.titel, v.frage, v.afb, 6, false,
  (select sc.id from skill_clusters sc
     join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  jsonb_build_object('kind', 'short_input', 'prompt', v.frage)
from (values
  ('dezimal-addieren-01', 'Dezimalzahlen · Addieren · 0,5 + 0,25', 'Berechne.

0,5 + 0,25 = ?', 'I'),
  ('dezimal-addieren-02', 'Dezimalzahlen · Addieren · 0,7 + 0,5', 'Berechne.

0,7 + 0,5 = ?', 'I'),
  ('dezimal-addieren-03', 'Dezimalzahlen · Addieren · 0,8 + 0,45', 'Berechne.

0,8 + 0,45 = ?', 'I'),
  ('dezimal-addieren-04', 'Dezimalzahlen · Addieren · 0,6 + 0,4', 'Berechne.

0,6 + 0,4 = ?', 'I'),
  ('dezimal-addieren-05', 'Dezimalzahlen · Addieren · 0,25 + 0,4', 'Berechne.

0,25 + 0,4 = ?', 'I'),
  ('dezimal-addieren-06', 'Dezimalzahlen · Addieren · 0,9 + 0,35', 'Berechne.

0,9 + 0,35 = ?', 'I'),
  ('dezimal-addieren-07', 'Dezimalzahlen · Addieren · 0,8 + 0,7', 'Berechne.

0,8 + 0,7 = ?', 'I'),
  ('dezimal-addieren-08', 'Dezimalzahlen · Addieren · 0,3 + 0,45', 'Berechne.

0,3 + 0,45 = ?', 'I'),
  ('dezimal-multiplizieren-01', 'Dezimalzahlen · Multiplizieren · 0,3 · 0,4', 'Berechne.

0,3 · 0,4 = ?', 'I'),
  ('dezimal-multiplizieren-02', 'Dezimalzahlen · Multiplizieren · 0,2 · 0,7', 'Berechne.

0,2 · 0,7 = ?', 'I'),
  ('dezimal-multiplizieren-03', 'Dezimalzahlen · Multiplizieren · 0,6 · 0,4', 'Berechne.

0,6 · 0,4 = ?', 'I'),
  ('dezimal-multiplizieren-04', 'Dezimalzahlen · Multiplizieren · 0,9 · 0,3', 'Berechne.

0,9 · 0,3 = ?', 'I'),
  ('dezimal-multiplizieren-05', 'Dezimalzahlen · Multiplizieren · 0,5 · 0,6', 'Berechne.

0,5 · 0,6 = ?', 'I'),
  ('dezimal-multiplizieren-06', 'Dezimalzahlen · Multiplizieren · 0,8 · 0,5', 'Berechne.

0,8 · 0,5 = ?', 'I'),
  ('dezimal-dividieren-01', 'Dezimalzahlen · Dividieren · 4,8 : 0,6', 'Berechne.

4,8 : 0,6 = ?', 'I'),
  ('dezimal-dividieren-02', 'Dezimalzahlen · Dividieren · 3,5 : 0,5', 'Berechne.

3,5 : 0,5 = ?', 'I'),
  ('dezimal-dividieren-03', 'Dezimalzahlen · Dividieren · 7,2 : 0,8', 'Berechne.

7,2 : 0,8 = ?', 'I'),
  ('dezimal-dividieren-04', 'Dezimalzahlen · Dividieren · 2,4 : 0,4', 'Berechne.

2,4 : 0,4 = ?', 'I'),
  ('dezimal-dividieren-05', 'Dezimalzahlen · Dividieren · 5,4 : 0,9', 'Berechne.

5,4 : 0,9 = ?', 'I'),
  ('dezimal-dividieren-06', 'Dezimalzahlen · Dividieren · 1,2 : 0,3', 'Berechne.

1,2 : 0,3 = ?', 'I'),
  ('dezimal-umwandeln-01', 'Dezimalzahlen · Bruch umwandeln · 3/4', 'Schreibe den Bruch als Dezimalzahl.

3/4 = ?', 'I'),
  ('dezimal-umwandeln-02', 'Dezimalzahlen · Bruch umwandeln · 1/4', 'Schreibe den Bruch als Dezimalzahl.

1/4 = ?', 'I'),
  ('dezimal-umwandeln-03', 'Dezimalzahlen · Bruch umwandeln · 1/2', 'Schreibe den Bruch als Dezimalzahl.

1/2 = ?', 'I'),
  ('dezimal-umwandeln-04', 'Dezimalzahlen · Bruch umwandeln · 1/5', 'Schreibe den Bruch als Dezimalzahl.

1/5 = ?', 'I'),
  ('dezimal-umwandeln-05', 'Dezimalzahlen · Bruch umwandeln · 3/8', 'Schreibe den Bruch als Dezimalzahl.

3/8 = ?', 'I'),
  ('dezimal-umwandeln-06', 'Dezimalzahlen · Bruch umwandeln · 1/8', 'Schreibe den Bruch als Dezimalzahl.

1/8 = ?', 'I')
) as v(source_ref, titel, frage, afb)
on conflict (source, source_ref) do nothing;

-- ── 2. Loesung, Akzeptanz-Set und Fehlbilder (Server-Only-Zone) ────────────

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('dezimal-addieren-01', '["0,75"]', '{"canonical": "0,75", "known_errors": {"0,3": "stellenwert_ignoriert"}}'),
  ('dezimal-addieren-02', '["1,2"]', '{"canonical": "1,2", "known_errors": {"0,12": "uebertrag_vergessen"}}'),
  ('dezimal-addieren-03', '["1,25"]', '{"canonical": "1,25", "known_errors": {"0,53": "stellenwert_ignoriert"}}'),
  ('dezimal-addieren-04', '["1"]', '{"canonical": "1", "known_errors": {"0,1": "uebertrag_vergessen"}}'),
  ('dezimal-addieren-05', '["0,65"]', '{"canonical": "0,65", "known_errors": {"0,29": "stellenwert_ignoriert"}}'),
  ('dezimal-addieren-06', '["1,25"]', '{"canonical": "1,25", "known_errors": {"0,44": "stellenwert_ignoriert"}}'),
  ('dezimal-addieren-07', '["1,5"]', '{"canonical": "1,5", "known_errors": {"0,15": "uebertrag_vergessen"}}'),
  ('dezimal-addieren-08', '["0,75"]', '{"canonical": "0,75", "known_errors": {"0,48": "stellenwert_ignoriert"}}'),
  ('dezimal-multiplizieren-01', '["0,12"]', '{"canonical": "0,12", "known_errors": {"1,2": "kommastellen_zu_wenig", "0,012": "kommastellen_zu_viel", "12": "komma_ignoriert"}}'),
  ('dezimal-multiplizieren-02', '["0,14"]', '{"canonical": "0,14", "known_errors": {"1,4": "kommastellen_zu_wenig", "0,014": "kommastellen_zu_viel", "14": "komma_ignoriert"}}'),
  ('dezimal-multiplizieren-03', '["0,24"]', '{"canonical": "0,24", "known_errors": {"2,4": "kommastellen_zu_wenig", "0,024": "kommastellen_zu_viel", "24": "komma_ignoriert"}}'),
  ('dezimal-multiplizieren-04', '["0,27"]', '{"canonical": "0,27", "known_errors": {"2,7": "kommastellen_zu_wenig", "0,027": "kommastellen_zu_viel", "27": "komma_ignoriert"}}'),
  ('dezimal-multiplizieren-05', '["0,3"]', '{"canonical": "0,3", "known_errors": {"3": "kommastellen_zu_wenig", "0,03": "kommastellen_zu_viel", "30": "komma_ignoriert"}}'),
  ('dezimal-multiplizieren-06', '["0,4"]', '{"canonical": "0,4", "known_errors": {"4": "kommastellen_zu_wenig", "0,04": "kommastellen_zu_viel", "40": "komma_ignoriert"}}'),
  ('dezimal-dividieren-01', '["8"]', '{"canonical": "8", "known_errors": {"0,8": "komma_nicht_verschoben", "0,08": "falsche_richtung"}}'),
  ('dezimal-dividieren-02', '["7"]', '{"canonical": "7", "known_errors": {"0,7": "komma_nicht_verschoben", "0,07": "falsche_richtung"}}'),
  ('dezimal-dividieren-03', '["9"]', '{"canonical": "9", "known_errors": {"0,9": "komma_nicht_verschoben", "0,09": "falsche_richtung"}}'),
  ('dezimal-dividieren-04', '["6"]', '{"canonical": "6", "known_errors": {"0,6": "komma_nicht_verschoben", "0,06": "falsche_richtung"}}'),
  ('dezimal-dividieren-05', '["6"]', '{"canonical": "6", "known_errors": {"0,6": "komma_nicht_verschoben", "0,06": "falsche_richtung"}}'),
  ('dezimal-dividieren-06', '["4"]', '{"canonical": "4", "known_errors": {"0,4": "komma_nicht_verschoben", "0,04": "falsche_richtung"}}'),
  ('dezimal-umwandeln-01', '["0,75"]', '{"canonical": "0,75", "known_errors": {"0,34": "ziffern_gelesen"}}'),
  ('dezimal-umwandeln-02', '["0,25"]', '{"canonical": "0,25", "known_errors": {"0,14": "ziffern_gelesen", "4": "umgekehrt_geteilt"}}'),
  ('dezimal-umwandeln-03', '["0,5"]', '{"canonical": "0,5", "known_errors": {"0,12": "ziffern_gelesen", "2": "umgekehrt_geteilt"}}'),
  ('dezimal-umwandeln-04', '["0,2"]', '{"canonical": "0,2", "known_errors": {"0,15": "ziffern_gelesen", "5": "umgekehrt_geteilt"}}'),
  ('dezimal-umwandeln-05', '["0,375"]', '{"canonical": "0,375", "known_errors": {"0,38": "ziffern_gelesen"}}'),
  ('dezimal-umwandeln-06', '["0,125"]', '{"canonical": "0,125", "known_errors": {"0,18": "ziffern_gelesen", "8": "umgekehrt_geteilt"}}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── 3. Proben gegen lsa_grade, mit Negativkontrolle ────────────────────────

do $$
declare
  r           record;
  v_urteil    text;
  v_echte     int := 0;
  v_kontrolle int := 0;
begin
  for r in
    select * from (values
      ('dezimal-addieren-01', '0,75', 'voll', '—', false),
      ('dezimal-addieren-01', '0,3', 'nicht', 'stellenwert_ignoriert', false),
      ('dezimal-addieren-02', '1,2', 'voll', '—', false),
      ('dezimal-addieren-02', '0,12', 'nicht', 'uebertrag_vergessen', false),
      ('dezimal-addieren-03', '1,25', 'voll', '—', false),
      ('dezimal-addieren-03', '0,53', 'nicht', 'stellenwert_ignoriert', false),
      ('dezimal-addieren-04', '1', 'voll', '—', false),
      ('dezimal-addieren-04', '0,1', 'nicht', 'uebertrag_vergessen', false),
      ('dezimal-addieren-05', '0,65', 'voll', '—', false),
      ('dezimal-addieren-05', '0,29', 'nicht', 'stellenwert_ignoriert', false),
      ('dezimal-addieren-06', '1,25', 'voll', '—', false),
      ('dezimal-addieren-06', '0,44', 'nicht', 'stellenwert_ignoriert', false),
      ('dezimal-addieren-07', '1,5', 'voll', '—', false),
      ('dezimal-addieren-07', '0,15', 'nicht', 'uebertrag_vergessen', false),
      ('dezimal-addieren-08', '0,75', 'voll', '—', false),
      ('dezimal-addieren-08', '0,48', 'nicht', 'stellenwert_ignoriert', false),
      ('dezimal-multiplizieren-01', '0,12', 'voll', '—', false),
      ('dezimal-multiplizieren-01', '1,2', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-01', '0,012', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-01', '12', 'nicht', 'komma_ignoriert', false),
      ('dezimal-multiplizieren-02', '0,14', 'voll', '—', false),
      ('dezimal-multiplizieren-02', '1,4', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-02', '0,014', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-02', '14', 'nicht', 'komma_ignoriert', false),
      ('dezimal-multiplizieren-03', '0,24', 'voll', '—', false),
      ('dezimal-multiplizieren-03', '2,4', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-03', '0,024', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-03', '24', 'nicht', 'komma_ignoriert', false),
      ('dezimal-multiplizieren-04', '0,27', 'voll', '—', false),
      ('dezimal-multiplizieren-04', '2,7', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-04', '0,027', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-04', '27', 'nicht', 'komma_ignoriert', false),
      ('dezimal-multiplizieren-05', '0,3', 'voll', '—', false),
      ('dezimal-multiplizieren-05', '3', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-05', '0,03', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-05', '30', 'nicht', 'komma_ignoriert', false),
      ('dezimal-multiplizieren-06', '0,4', 'voll', '—', false),
      ('dezimal-multiplizieren-06', '4', 'nicht', 'kommastellen_zu_wenig', false),
      ('dezimal-multiplizieren-06', '0,04', 'nicht', 'kommastellen_zu_viel', false),
      ('dezimal-multiplizieren-06', '40', 'nicht', 'komma_ignoriert', false),
      ('dezimal-dividieren-01', '8', 'voll', '—', false),
      ('dezimal-dividieren-01', '0,8', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-01', '0,08', 'nicht', 'falsche_richtung', false),
      ('dezimal-dividieren-02', '7', 'voll', '—', false),
      ('dezimal-dividieren-02', '0,7', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-02', '0,07', 'nicht', 'falsche_richtung', false),
      ('dezimal-dividieren-03', '9', 'voll', '—', false),
      ('dezimal-dividieren-03', '0,9', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-03', '0,09', 'nicht', 'falsche_richtung', false),
      ('dezimal-dividieren-04', '6', 'voll', '—', false),
      ('dezimal-dividieren-04', '0,6', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-04', '0,06', 'nicht', 'falsche_richtung', false),
      ('dezimal-dividieren-05', '6', 'voll', '—', false),
      ('dezimal-dividieren-05', '0,6', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-05', '0,06', 'nicht', 'falsche_richtung', false),
      ('dezimal-dividieren-06', '4', 'voll', '—', false),
      ('dezimal-dividieren-06', '0,4', 'nicht', 'komma_nicht_verschoben', false),
      ('dezimal-dividieren-06', '0,04', 'nicht', 'falsche_richtung', false),
      ('dezimal-umwandeln-01', '0,75', 'voll', '—', false),
      ('dezimal-umwandeln-01', '0,34', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-02', '0,25', 'voll', '—', false),
      ('dezimal-umwandeln-02', '0,14', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-02', '4', 'nicht', 'umgekehrt_geteilt', false),
      ('dezimal-umwandeln-03', '0,5', 'voll', '—', false),
      ('dezimal-umwandeln-03', '0,12', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-03', '2', 'nicht', 'umgekehrt_geteilt', false),
      ('dezimal-umwandeln-04', '0,2', 'voll', '—', false),
      ('dezimal-umwandeln-04', '0,15', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-04', '5', 'nicht', 'umgekehrt_geteilt', false),
      ('dezimal-umwandeln-05', '0,375', 'voll', '—', false),
      ('dezimal-umwandeln-05', '0,38', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-06', '0,125', 'voll', '—', false),
      ('dezimal-umwandeln-06', '0,18', 'nicht', 'ziffern_gelesen', false),
      ('dezimal-umwandeln-06', '8', 'nicht', 'umgekehrt_geteilt', false),
      ('dezimal-addieren-01', '0,75', 'nicht', 'NEGATIVKONTROLLE', true)
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
        raise notice 'Negativkontrolle hat angeschlagen (so soll es sein): %/% ist %',
          r.source_ref, r.antwort, coalesce(v_urteil, '<null>');
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
  if v_kontrolle <> 1 then
    raise exception 'Negativkontrolle hat NICHT angeschlagen — die Probenschleife prueft nichts.';
  end if;

  raise notice 'Dezimalzahlen: alle echten Proben bestanden, Negativkontrolle greift.';
end $$;

commit;
