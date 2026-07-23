-- ============================================================================
-- Proportionalität und Dreisatz — Fundament-Charge 2 als DRAFT (14 Aufgaben)
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
  ('proportionalitaet-01', 'proportionalitaet', 'Dreisatz · 2 L Saft kosten 3 €.', '2 L Saft kosten 3 €. Was kosten 4 L?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 L Saft kosten 3 €. Was kosten 4 L?')),
  ('proportionalitaet-02', 'proportionalitaet', 'Dreisatz · 2 Hefte kosten 3 €.', '2 Hefte kosten 3 €. Was kosten 6 Hefte?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 Hefte kosten 3 €. Was kosten 6 Hefte?')),
  ('proportionalitaet-03', 'proportionalitaet', 'Dreisatz · 2 kg Äpfel kosten 3 €.', '2 kg Äpfel kosten 3 €. Was kosten 8 kg?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 kg Äpfel kosten 3 €. Was kosten 8 kg?')),
  ('proportionalitaet-04', 'proportionalitaet', 'Dreisatz · 2 m Stoff kosten 3 €.', '2 m Stoff kosten 3 €. Was kosten 10 m?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 m Stoff kosten 3 €. Was kosten 10 m?')),
  ('proportionalitaet-05', 'proportionalitaet', 'Dreisatz · 2 Flaschen kosten 3 €.', '2 Flaschen kosten 3 €. Was kosten 12 Flaschen?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 Flaschen kosten 3 €. Was kosten 12 Flaschen?')),
  ('proportionalitaet-06', 'proportionalitaet', 'Dreisatz · 2 Tickets kosten 4 €.', '2 Tickets kosten 4 €. Was kosten 5 Tickets?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 Tickets kosten 4 €. Was kosten 5 Tickets?')),
  ('proportionalitaet-07', 'proportionalitaet', 'Dreisatz · 2 Stifte kosten 4 €.', '2 Stifte kosten 4 €. Was kosten 7 Stifte?', 'I', '€', jsonb_build_object('kind','short_input','prompt','2 Stifte kosten 4 €. Was kosten 7 Stifte?')),
  ('proportionalitaet-08', 'proportionalitaet', 'Dreisatz · 2 Arbeiter schaffen eine Aufgabe in 3 Stunden.', '2 Arbeiter schaffen eine Aufgabe in 3 Stunden. Wie lange brauchen 6 Arbeiter?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Arbeiter schaffen eine Aufgabe in 3 Stunden. Wie lange brauchen 6 Arbeiter?')),
  ('proportionalitaet-09', 'proportionalitaet', 'Dreisatz · 2 Pumpen leeren ein Becken in 6 Stunden.', '2 Pumpen leeren ein Becken in 6 Stunden. Wie lange brauchen 3 Pumpen?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Pumpen leeren ein Becken in 6 Stunden. Wie lange brauchen 3 Pumpen?')),
  ('proportionalitaet-10', 'proportionalitaet', 'Dreisatz · 2 Maler streichen eine Wand in 9 Stunden.', '2 Maler streichen eine Wand in 9 Stunden. Wie lange brauchen 3 Maler?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Maler streichen eine Wand in 9 Stunden. Wie lange brauchen 3 Maler?')),
  ('proportionalitaet-11', 'proportionalitaet', 'Dreisatz · 2 Helfer räumen eine Halle in 9 Stunden.', '2 Helfer räumen eine Halle in 9 Stunden. Wie lange brauchen 6 Helfer?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Helfer räumen eine Halle in 9 Stunden. Wie lange brauchen 6 Helfer?')),
  ('proportionalitaet-12', 'proportionalitaet', 'Dreisatz · 2 Bagger heben eine Grube in 10 Stunden.', '2 Bagger heben eine Grube in 10 Stunden. Wie lange brauchen 4 Bagger?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Bagger heben eine Grube in 10 Stunden. Wie lange brauchen 4 Bagger?')),
  ('proportionalitaet-13', 'proportionalitaet', 'Dreisatz · 2 Mäher mähen ein Feld in 12 Stunden.', '2 Mäher mähen ein Feld in 12 Stunden. Wie lange brauchen 3 Mäher?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Mäher mähen ein Feld in 12 Stunden. Wie lange brauchen 3 Mäher?')),
  ('proportionalitaet-14', 'proportionalitaet', 'Dreisatz · 2 Drucker erledigen einen Auftrag in 15 Stunden.', '2 Drucker erledigen einen Auftrag in 15 Stunden. Wie lange brauchen 3 Drucker?', 'II', 'Stunden', jsonb_build_object('kind','short_input','prompt','2 Drucker erledigen einen Auftrag in 15 Stunden. Wie lange brauchen 3 Drucker?'))
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('proportionalitaet-01', '["6"]', '{"canonical": "6", "known_errors": {"1,5": "antiproportional_verwechselt", "12": "einheit_verrutscht"}}'),
  ('proportionalitaet-02', '["9"]', '{"canonical": "9", "known_errors": {"1": "antiproportional_verwechselt", "4": "falscher_bezug", "18": "einheit_verrutscht"}}'),
  ('proportionalitaet-03', '["12"]', '{"canonical": "12", "known_errors": {"0,75": "antiproportional_verwechselt", "24": "einheit_verrutscht"}}'),
  ('proportionalitaet-04', '["15"]', '{"canonical": "15", "known_errors": {"0,6": "antiproportional_verwechselt", "30": "einheit_verrutscht"}}'),
  ('proportionalitaet-05', '["18"]', '{"canonical": "18", "known_errors": {"0,5": "antiproportional_verwechselt", "8": "falscher_bezug", "36": "einheit_verrutscht"}}'),
  ('proportionalitaet-06', '["10"]', '{"canonical": "10", "known_errors": {"1,6": "antiproportional_verwechselt", "2,5": "falscher_bezug", "20": "einheit_verrutscht"}}'),
  ('proportionalitaet-07', '["14"]', '{"canonical": "14", "known_errors": {"3,5": "falscher_bezug", "28": "einheit_verrutscht"}}'),
  ('proportionalitaet-08', '["1"]', '{"canonical": "1", "known_errors": {"9": "antiproportional_verwechselt", "4": "falscher_bezug", "6": "einheit_verrutscht"}}'),
  ('proportionalitaet-09', '["4"]', '{"canonical": "4", "known_errors": {"9": "antiproportional_verwechselt", "1": "falscher_bezug", "12": "einheit_verrutscht"}}'),
  ('proportionalitaet-10', '["6"]', '{"canonical": "6", "known_errors": {"13,5": "antiproportional_verwechselt", "18": "einheit_verrutscht"}}'),
  ('proportionalitaet-11', '["3"]', '{"canonical": "3", "known_errors": {"27": "antiproportional_verwechselt", "18": "einheit_verrutscht"}}'),
  ('proportionalitaet-12', '["5"]', '{"canonical": "5", "known_errors": {"20": "antiproportional_verwechselt", "0,8": "falscher_bezug"}}'),
  ('proportionalitaet-13', '["8"]', '{"canonical": "8", "known_errors": {"18": "antiproportional_verwechselt", "0,5": "falscher_bezug", "24": "einheit_verrutscht"}}'),
  ('proportionalitaet-14', '["10"]', '{"canonical": "10", "known_errors": {"22,5": "antiproportional_verwechselt", "0,4": "falscher_bezug", "30": "einheit_verrutscht"}}')
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
      ('proportionalitaet-01', '6', 'voll', 'canonical'),
      ('proportionalitaet-01', '1,5', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-01', '12', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-02', '9', 'voll', 'canonical'),
      ('proportionalitaet-02', '1', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-02', '4', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-02', '18', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-03', '12', 'voll', 'canonical'),
      ('proportionalitaet-03', '0,75', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-03', '24', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-04', '15', 'voll', 'canonical'),
      ('proportionalitaet-04', '0,6', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-04', '30', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-05', '18', 'voll', 'canonical'),
      ('proportionalitaet-05', '0,5', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-05', '8', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-05', '36', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-06', '10', 'voll', 'canonical'),
      ('proportionalitaet-06', '1,6', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-06', '2,5', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-06', '20', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-07', '14', 'voll', 'canonical'),
      ('proportionalitaet-07', '3,5', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-07', '28', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-08', '1', 'voll', 'canonical'),
      ('proportionalitaet-08', '9', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-08', '4', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-08', '6', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-09', '4', 'voll', 'canonical'),
      ('proportionalitaet-09', '9', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-09', '1', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-09', '12', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-10', '6', 'voll', 'canonical'),
      ('proportionalitaet-10', '13,5', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-10', '18', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-11', '3', 'voll', 'canonical'),
      ('proportionalitaet-11', '27', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-11', '18', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-12', '5', 'voll', 'canonical'),
      ('proportionalitaet-12', '20', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-12', '0,8', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-13', '8', 'voll', 'canonical'),
      ('proportionalitaet-13', '18', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-13', '0,5', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-13', '24', 'nicht', 'einheit_verrutscht'),
      ('proportionalitaet-14', '10', 'voll', 'canonical'),
      ('proportionalitaet-14', '22,5', 'nicht', 'antiproportional_verwechselt'),
      ('proportionalitaet-14', '0,4', 'nicht', 'falscher_bezug'),
      ('proportionalitaet-14', '30', 'nicht', 'einheit_verrutscht')
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
     where t.source = 'edvance_fundament' and t.source_ref like 'proportionalitaet-%'
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
   where source='edvance_fundament' and source_ref like 'proportionalitaet-%' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  raise notice 'Proportionalität und Dreisatz: alle Proben bestanden.';
end $$;

commit;
