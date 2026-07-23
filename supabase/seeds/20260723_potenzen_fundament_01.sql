-- ============================================================================
-- Potenzen und Quadratzahlen — Fundament-Charge 2 als DRAFT (16 Aufgaben)
--
-- ERZEUGT von scripts/content/fundament_charge2.py. Nicht von Hand pflegen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/<diese-datei>.sql
--
-- SETZT A13 (TERM-Grader-Fix) + A14 (skills, tasks.skill_key) VORAUS.
--
-- ANTWORTFORM: input_type NUMERIC, canonical ist eine REINE ZAHL. Die Einheit
-- steht im Fragetext und in tasks.unit (-> payload.unit). Das Kind tippt nur die
-- Zahl. Weil der Rest hinter der Zahl leer ist, greift der Wert-Pfad von
-- lsa_grade, NICHT der TERM-Zweig (Selbsttest 3b unten zeigt es).
--
-- STATUS: alles 'draft'. Freigabe ist Lenas Schritt.
-- SOLUTION-LEAK: canonical + known_errors nur in task_solutions (kein
-- anon/authenticated-Grant). tasks.question_payload traegt nur prompt + unit.
--
-- IDEMPOTENT ueber (source, source_ref).
-- ============================================================================

begin;

do $$
begin
  if not exists (select 1 from information_schema.columns
                  where table_name='tasks' and column_name='skill_key') then
    raise exception 'tasks.skill_key fehlt — A14 erst einspielen.';
  end if;
end $$;

insert into tasks (
  source, source_ref, content_type, input_type, status, is_active, is_diagnostic,
  skill_key, title, question, afb, curriculum_grade, needs_image,
  cluster_id, competency_content, competency_process, competency_id, unit, question_payload
)
select
  'edvance_fundament', v.source_ref, 'exercise', 'NUMERIC', 'draft', true, false,
  v.skill_key, v.titel, v.frage, v.afb, 7, false,
  (select sc.id from skill_clusters sc join subjects s on s.id = sc.subject_id
    where s.name = 'Mathematik' and sc.name = 'Zahl & Rechnen' limit 1),
  'arithmetik_algebra', 'Operieren',
  (select pc.id from process_competencies pc where pc.code = 'Ope' limit 1),
  v.unit, v.payload
from (values
  ('potenzen-01', 'potenzen', 'Potenzen · 3^4 = ?', 'Berechne.

3^4 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

3^4 = ?')),
  ('potenzen-02', 'potenzen', 'Potenzen · 2^5 = ?', 'Berechne.

2^5 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

2^5 = ?')),
  ('potenzen-03', 'potenzen', 'Potenzen · 5^3 = ?', 'Berechne.

5^3 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

5^3 = ?')),
  ('potenzen-04', 'potenzen', 'Potenzen · 4^3 = ?', 'Berechne.

4^3 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

4^3 = ?')),
  ('potenzen-05', 'potenzen', 'Potenzen · 6^2 = ?', 'Berechne.

6^2 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

6^2 = ?')),
  ('potenzen-06', 'potenzen', 'Potenzen · 7^2 = ?', 'Berechne.

7^2 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

7^2 = ?')),
  ('potenzen-07', 'potenzen', 'Potenzen · 10^2 = ?', 'Berechne.

10^2 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

10^2 = ?')),
  ('potenzen-08', 'potenzen', 'Potenzen · 2^3 = ?', 'Berechne.

2^3 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Berechne.

2^3 = ?')),
  ('potenzen-09', 'potenzen', 'Potenzen · (-3)^2 = ?', 'Berechne.

(-3)^2 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

(-3)^2 = ?')),
  ('potenzen-10', 'potenzen', 'Potenzen · (-4)^2 = ?', 'Berechne.

(-4)^2 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

(-4)^2 = ?')),
  ('potenzen-11', 'potenzen', 'Potenzen · (-2)^3 = ?', 'Berechne.

(-2)^3 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

(-2)^3 = ?')),
  ('potenzen-12', 'potenzen', 'Potenzen · (-3)^3 = ?', 'Berechne.

(-3)^3 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

(-3)^3 = ?')),
  ('potenzen-13', 'potenzen', 'Potenzen · (-5)^2 = ?', 'Berechne.

(-5)^2 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

(-5)^2 = ?')),
  ('potenzen-14', 'potenzen', 'Potenzen · -2^2 = ?', 'Berechne.

-2^2 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

-2^2 = ?')),
  ('potenzen-15', 'potenzen', 'Potenzen · √36 = ?', 'Berechne.

√36 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

√36 = ?')),
  ('potenzen-16', 'potenzen', 'Potenzen · √144 = ?', 'Berechne.

√144 = ?', 'II', null, jsonb_build_object('kind','short_input','prompt','Berechne.

√144 = ?'))
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('potenzen-01', '["81"]', '{"canonical": "81", "known_errors": {"12": "mal_exponent", "64": "basis_exponent_vertauscht"}}'),
  ('potenzen-02', '["32"]', '{"canonical": "32", "known_errors": {"10": "mal_exponent", "25": "basis_exponent_vertauscht"}}'),
  ('potenzen-03', '["125"]', '{"canonical": "125", "known_errors": {"15": "mal_exponent", "243": "basis_exponent_vertauscht"}}'),
  ('potenzen-04', '["64"]', '{"canonical": "64", "known_errors": {"12": "mal_exponent", "81": "basis_exponent_vertauscht"}}'),
  ('potenzen-05', '["36"]', '{"canonical": "36", "known_errors": {"12": "mal_exponent", "64": "basis_exponent_vertauscht"}}'),
  ('potenzen-06', '["49"]', '{"canonical": "49", "known_errors": {"14": "mal_exponent", "128": "basis_exponent_vertauscht"}}'),
  ('potenzen-07', '["100"]', '{"canonical": "100", "known_errors": {"20": "mal_exponent", "1024": "basis_exponent_vertauscht"}}'),
  ('potenzen-08', '["8"]', '{"canonical": "8", "known_errors": {"6": "mal_exponent", "9": "basis_exponent_vertauscht"}}'),
  ('potenzen-09', '["9"]', '{"canonical": "9", "known_errors": {"-9": "vorzeichen_potenz", "-6": "mal_exponent"}}'),
  ('potenzen-10', '["16"]', '{"canonical": "16", "known_errors": {"-16": "vorzeichen_potenz", "-8": "mal_exponent"}}'),
  ('potenzen-11', '["-8"]', '{"canonical": "-8", "known_errors": {"8": "vorzeichen_potenz", "-6": "mal_exponent"}}'),
  ('potenzen-12', '["-27"]', '{"canonical": "-27", "known_errors": {"27": "vorzeichen_potenz", "-9": "mal_exponent"}}'),
  ('potenzen-13', '["25"]', '{"canonical": "25", "known_errors": {"-25": "vorzeichen_potenz", "-10": "mal_exponent"}}'),
  ('potenzen-14', '["-4"]', '{"canonical": "-4", "known_errors": {"4": "vorzeichen_potenz"}}'),
  ('potenzen-15', '["6"]', '{"canonical": "6", "known_errors": {"18": "wurzel_halbiert"}}'),
  ('potenzen-16', '["12"]', '{"canonical": "12", "known_errors": {"72": "wurzel_halbiert"}}')
) as v(source_ref, correct_answers, acceptance)
join tasks t on t.source = 'edvance_fundament' and t.source_ref = v.source_ref
on conflict (task_id) do update
   set correct_answers = excluded.correct_answers,
       acceptance      = excluded.acceptance,
       updated_at      = now();

-- ── Selbsttest ─────────────────────────────────────────────────────────────
--   canonical -> 'voll', jedes Fehlbild -> 'nicht'. Weicht eine Probe ab,
--   bricht die Transaktion ab und NICHTS wird eingespielt.

do $$
declare
  r        record;
  v_urteil text;
  v_fehler int := 0;
  v_anzahl int;
begin
  for r in
    select * from (values
      ('potenzen-01', '81', 'voll', 'canonical'),
      ('potenzen-01', '12', 'nicht', 'mal_exponent'),
      ('potenzen-01', '64', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-02', '32', 'voll', 'canonical'),
      ('potenzen-02', '10', 'nicht', 'mal_exponent'),
      ('potenzen-02', '25', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-03', '125', 'voll', 'canonical'),
      ('potenzen-03', '15', 'nicht', 'mal_exponent'),
      ('potenzen-03', '243', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-04', '64', 'voll', 'canonical'),
      ('potenzen-04', '12', 'nicht', 'mal_exponent'),
      ('potenzen-04', '81', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-05', '36', 'voll', 'canonical'),
      ('potenzen-05', '12', 'nicht', 'mal_exponent'),
      ('potenzen-05', '64', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-06', '49', 'voll', 'canonical'),
      ('potenzen-06', '14', 'nicht', 'mal_exponent'),
      ('potenzen-06', '128', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-07', '100', 'voll', 'canonical'),
      ('potenzen-07', '20', 'nicht', 'mal_exponent'),
      ('potenzen-07', '1024', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-08', '8', 'voll', 'canonical'),
      ('potenzen-08', '6', 'nicht', 'mal_exponent'),
      ('potenzen-08', '9', 'nicht', 'basis_exponent_vertauscht'),
      ('potenzen-09', '9', 'voll', 'canonical'),
      ('potenzen-09', '-9', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-09', '-6', 'nicht', 'mal_exponent'),
      ('potenzen-10', '16', 'voll', 'canonical'),
      ('potenzen-10', '-16', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-10', '-8', 'nicht', 'mal_exponent'),
      ('potenzen-11', '-8', 'voll', 'canonical'),
      ('potenzen-11', '8', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-11', '-6', 'nicht', 'mal_exponent'),
      ('potenzen-12', '-27', 'voll', 'canonical'),
      ('potenzen-12', '27', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-12', '-9', 'nicht', 'mal_exponent'),
      ('potenzen-13', '25', 'voll', 'canonical'),
      ('potenzen-13', '-25', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-13', '-10', 'nicht', 'mal_exponent'),
      ('potenzen-14', '-4', 'voll', 'canonical'),
      ('potenzen-14', '4', 'nicht', 'vorzeichen_potenz'),
      ('potenzen-15', '6', 'voll', 'canonical'),
      ('potenzen-15', '18', 'nicht', 'wurzel_halbiert'),
      ('potenzen-16', '12', 'voll', 'canonical'),
      ('potenzen-16', '72', 'nicht', 'wurzel_halbiert')
    ) as p(source_ref, antwort, erwartet, label)
  loop
    select public.lsa_grade('NUMERIC', s.acceptance, s.correct_answers,
                            jsonb_build_object('text', r.antwort))
      into v_urteil
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;
    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (%)',
        r.source_ref, r.antwort, coalesce(v_urteil,'<null>'), r.erwartet, r.label;
    end if;
  end loop;

  -- 3b: diese Aufgaben betreten den TERM-Zweig NICHT (Rest hinter der Zahl leer).
  for r in
    select distinct s.acceptance ->> 'canonical' as canon
      from task_solutions s join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref like 'potenzen-%'
  loop
    if not public.lsa_is_unit((public.lsa_split_value_unit(r.canon))[2]) then
      v_fehler := v_fehler + 1;
      raise warning 'canonical % betritt den TERM/Einheit-Zweig — Rest ist keine leere Einheit', r.canon;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts eingespielt.', v_fehler;
  end if;

  select count(*) into v_anzahl from tasks
   where source='edvance_fundament' and source_ref like 'potenzen-%' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  raise notice 'Potenzen und Quadratzahlen: alle Proben bestanden.';
end $$;

commit;
