-- ============================================================================
-- Runden und Überschlag — Fundament-Charge 2 als DRAFT (10 Aufgaben)
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
  ('runden-01', 'runden_ueberschlag', 'Runden · 3,47', 'Runde auf eine Nachkommastelle.

3,47 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

3,47 = ?')),
  ('runden-02', 'runden_ueberschlag', 'Runden · 2,85', 'Runde auf eine Nachkommastelle.

2,85 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

2,85 = ?')),
  ('runden-03', 'runden_ueberschlag', 'Runden · 7,152', 'Runde auf zwei Nachkommastellen.

7,152 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf zwei Nachkommastellen.

7,152 = ?')),
  ('runden-04', 'runden_ueberschlag', 'Runden · 4,45', 'Runde auf eine Nachkommastelle.

4,45 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

4,45 = ?')),
  ('runden-05', 'runden_ueberschlag', 'Runden · 12,6', 'Runde auf eine ganze Zahl.

12,6 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine ganze Zahl.

12,6 = ?')),
  ('runden-06', 'runden_ueberschlag', 'Runden · 5,32', 'Runde auf eine Nachkommastelle.

5,32 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

5,32 = ?')),
  ('runden-07', 'runden_ueberschlag', 'Runden · 8,214', 'Runde auf zwei Nachkommastellen.

8,214 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf zwei Nachkommastellen.

8,214 = ?')),
  ('runden-08', 'runden_ueberschlag', 'Runden · 3,71', 'Runde auf eine Nachkommastelle.

3,71 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

3,71 = ?')),
  ('runden-09', 'runden_ueberschlag', 'Runden · 6,048', 'Runde auf zwei Nachkommastellen.

6,048 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf zwei Nachkommastellen.

6,048 = ?')),
  ('runden-10', 'runden_ueberschlag', 'Runden · 9,25', 'Runde auf eine Nachkommastelle.

9,25 = ?', 'I', null, jsonb_build_object('kind','short_input','prompt','Runde auf eine Nachkommastelle.

9,25 = ?'))
) as v(source_ref, skill_key, titel, frage, afb, unit, payload)
on conflict (source, source_ref) do nothing;

insert into task_solutions (task_id, correct_answers, acceptance, updated_at)
select t.id, v.correct_answers::jsonb, v.acceptance::jsonb, now()
from (values
  ('runden-01', '["3,5"]', '{"canonical": "3,5", "known_errors": {"3,4": "abgeschnitten", "3,47": "falsche_stelle"}}'),
  ('runden-02', '["2,9"]', '{"canonical": "2,9", "known_errors": {"2,8": "abgeschnitten", "2,85": "falsche_stelle"}}'),
  ('runden-03', '["7,15"]', '{"canonical": "7,15", "known_errors": {"7,16": "immer_aufgerundet", "7,152": "falsche_stelle"}}'),
  ('runden-04', '["4,5"]', '{"canonical": "4,5", "known_errors": {"4,4": "abgeschnitten", "4,45": "falsche_stelle"}}'),
  ('runden-05', '["13"]', '{"canonical": "13", "known_errors": {"12": "abgeschnitten", "12,6": "falsche_stelle"}}'),
  ('runden-06', '["5,3"]', '{"canonical": "5,3", "known_errors": {"5,4": "immer_aufgerundet", "5,32": "falsche_stelle"}}'),
  ('runden-07', '["8,21"]', '{"canonical": "8,21", "known_errors": {"8,22": "immer_aufgerundet", "8,214": "falsche_stelle"}}'),
  ('runden-08', '["3,7"]', '{"canonical": "3,7", "known_errors": {"3,8": "immer_aufgerundet", "3,71": "falsche_stelle"}}'),
  ('runden-09', '["6,05"]', '{"canonical": "6,05", "known_errors": {"6,04": "abgeschnitten", "6,048": "falsche_stelle"}}'),
  ('runden-10', '["9,3"]', '{"canonical": "9,3", "known_errors": {"9,2": "abgeschnitten", "9,25": "falsche_stelle"}}')
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
      ('runden-01', '3,5', 'voll', 'canonical'),
      ('runden-01', '3,4', 'nicht', 'abgeschnitten'),
      ('runden-01', '3,47', 'nicht', 'falsche_stelle'),
      ('runden-02', '2,9', 'voll', 'canonical'),
      ('runden-02', '2,8', 'nicht', 'abgeschnitten'),
      ('runden-02', '2,85', 'nicht', 'falsche_stelle'),
      ('runden-03', '7,15', 'voll', 'canonical'),
      ('runden-03', '7,16', 'nicht', 'immer_aufgerundet'),
      ('runden-03', '7,152', 'nicht', 'falsche_stelle'),
      ('runden-04', '4,5', 'voll', 'canonical'),
      ('runden-04', '4,4', 'nicht', 'abgeschnitten'),
      ('runden-04', '4,45', 'nicht', 'falsche_stelle'),
      ('runden-05', '13', 'voll', 'canonical'),
      ('runden-05', '12', 'nicht', 'abgeschnitten'),
      ('runden-05', '12,6', 'nicht', 'falsche_stelle'),
      ('runden-06', '5,3', 'voll', 'canonical'),
      ('runden-06', '5,4', 'nicht', 'immer_aufgerundet'),
      ('runden-06', '5,32', 'nicht', 'falsche_stelle'),
      ('runden-07', '8,21', 'voll', 'canonical'),
      ('runden-07', '8,22', 'nicht', 'immer_aufgerundet'),
      ('runden-07', '8,214', 'nicht', 'falsche_stelle'),
      ('runden-08', '3,7', 'voll', 'canonical'),
      ('runden-08', '3,8', 'nicht', 'immer_aufgerundet'),
      ('runden-08', '3,71', 'nicht', 'falsche_stelle'),
      ('runden-09', '6,05', 'voll', 'canonical'),
      ('runden-09', '6,04', 'nicht', 'abgeschnitten'),
      ('runden-09', '6,048', 'nicht', 'falsche_stelle'),
      ('runden-10', '9,3', 'voll', 'canonical'),
      ('runden-10', '9,2', 'nicht', 'abgeschnitten'),
      ('runden-10', '9,25', 'nicht', 'falsche_stelle')
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
     where t.source = 'edvance_fundament' and t.source_ref like 'runden-%'
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
   where source='edvance_fundament' and source_ref like 'runden-%' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht auf draft.', v_anzahl;
  end if;

  raise notice 'Runden und Überschlag: alle Proben bestanden.';
end $$;

commit;
