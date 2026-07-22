-- ============================================================================
-- Bruch-Fundament, Charge 01 — known_errors nachgetragen
--
-- ERZEUGT von scripts/content/brueche_known_errors.py. Nicht von Hand pflegen:
-- neu erzeugen und die Datei ersetzen.
--
-- LAEUFT NICHT AUTOMATISCH. Von Hand einspielen:
--     psql "$DATABASE_URL" -f supabase/seeds/20260722_brueche_known_errors.sql
--
-- SETZT A12 VORAUS (known_errors als erlaubter acceptance-Key). Ohne A12
-- weist der CHECK task_solutions_acceptance_check das UPDATE ab und die
-- Transaktion bricht ab — genau so soll es sein.
--
-- REIN DEKLARATIV: die Bewertung bleibt, wie sie ist. lsa_grade wird nicht
-- angefasst, kein Schema geaendert, kein Status bewegt (alles bleibt 'draft' —
-- die Freigabe ist Lenas Schritt). known_errors ist Rohmaterial fuer die
-- Report-Feindiagnostik: es beantwortet nicht "richtig oder falsch", sondern
-- "welcher Denkfehler steckt hinter dieser falschen Antwort".
--
-- SOLUTION-LEAK: known_errors landet ausschliesslich in task_solutions (kein
-- Grant fuer anon/authenticated). In `tasks` steht davon nichts.
--
-- ERGAENZT, ERSETZT NICHT: das UPDATE verwendet `acceptance || ...`, canonical
-- und require_reduced bleiben unangetastet.
--
-- IDEMPOTENT: zweimal einspielen schreibt zweimal dasselbe.
-- ============================================================================

begin;

-- ── 1. Die Fehlbilder je Aufgabe ───────────────────────────────────────────
--
-- Wert -> Fehlertyp. Die Werte stehen genau so, wie ein Kind sie eintippen
-- wuerde. Berechnet aus der Didaktik (siehe Generator-Skript), nicht geraten.

update task_solutions ts
   set acceptance = ts.acceptance || jsonb_build_object('known_errors', v.known_errors::jsonb),
       updated_at = now()
  from (values
  ('brueche-kuerzen-01', '{"17/23": "additiv_gekuerzt", "9/12": "teilgekuerzt"}'),
  ('brueche-kuerzen-02', '{"11/15": "additiv_gekuerzt", "6/8": "teilgekuerzt"}'),
  ('brueche-kuerzen-03', '{"7/11": "additiv_gekuerzt", "4/6": "teilgekuerzt"}'),
  ('brueche-kuerzen-04', '{"15/23": "additiv_gekuerzt", "8/12": "teilgekuerzt"}'),
  ('brueche-kuerzen-05', '{"11/17": "additiv_gekuerzt", "6/9": "teilgekuerzt"}'),
  ('brueche-kuerzen-06', '{"19/23": "additiv_gekuerzt", "10/12": "teilgekuerzt"}'),
  ('brueche-kuerzen-07', '{"3/11": "additiv_gekuerzt", "2/6": "teilgekuerzt"}'),
  ('brueche-addieren-01', '{"3/7": "nenner_addiert", "3/12": "zaehler_nicht_erweitert", "11/7": "nenner_addiert_zaehler_ok"}'),
  ('brueche-addieren-02', '{"2/9": "nenner_addiert", "2/6": "zaehler_nicht_erweitert", "3/9": "nenner_addiert_zaehler_ok", "3/6": "teilgekuerzt"}'),
  ('brueche-addieren-03', '{"2/16": "nenner_addiert", "2/12": "zaehler_nicht_erweitert", "4/16": "nenner_addiert_zaehler_ok", "4/12": "teilgekuerzt"}'),
  ('brueche-addieren-04', '{"2/8": "nenner_addiert", "2/6": "zaehler_nicht_erweitert", "4/8": "nenner_addiert_zaehler_ok", "4/6": "teilgekuerzt"}'),
  ('brueche-addieren-05', '{"4/12": "nenner_addiert", "4/8": "zaehler_nicht_erweitert", "7/12": "nenner_addiert_zaehler_ok"}'),
  ('brueche-addieren-06', '{"6/16": "nenner_addiert", "6/12": "zaehler_nicht_erweitert", "8/16": "nenner_addiert_zaehler_ok", "8/12": "teilgekuerzt"}'),
  ('brueche-addieren-07', '{"3/15": "nenner_addiert", "3/18": "zaehler_nicht_erweitert", "7/15": "nenner_addiert_zaehler_ok"}'),
  ('brueche-multiplizieren-01', '{"22/15": "hauptnenner_bei_mult"}'),
  ('brueche-multiplizieren-02', '{"17/12": "hauptnenner_bei_mult", "6/12": "teilgekuerzt"}'),
  ('brueche-multiplizieren-03', '{"23/20": "hauptnenner_bei_mult", "6/20": "teilgekuerzt"}'),
  ('brueche-multiplizieren-04', '{"11/10": "hauptnenner_bei_mult"}'),
  ('brueche-multiplizieren-05', '{"49/30": "hauptnenner_bei_mult", "20/30": "teilgekuerzt"}'),
  ('brueche-multiplizieren-06', '{"25/24": "hauptnenner_bei_mult", "6/24": "teilgekuerzt"}'),
  ('brueche-multiplizieren-07', '{"9/6": "hauptnenner_bei_mult", "10/18": "teilgekuerzt"}'),
  ('brueche-dividieren-01', '{"8/15": "nicht_gestuerzt", "12/10": "falschen_gestuerzt", "10/12": "teilgekuerzt"}'),
  ('brueche-dividieren-02', '{"3/8": "nicht_gestuerzt", "6/4": "falschen_gestuerzt", "4/6": "teilgekuerzt"}'),
  ('brueche-dividieren-03', '{"6/12": "nicht_gestuerzt", "8/9": "falschen_gestuerzt"}'),
  ('brueche-dividieren-04', '{"6/20": "nicht_gestuerzt", "15/8": "falschen_gestuerzt"}'),
  ('brueche-dividieren-05', '{"9/32": "nicht_gestuerzt", "24/12": "falschen_gestuerzt", "12/24": "teilgekuerzt"}'),
  ('brueche-dividieren-06', '{"10/18": "nicht_gestuerzt", "12/15": "falschen_gestuerzt", "15/12": "teilgekuerzt"}'),
  ('brueche-dividieren-07', '{"8/27": "nicht_gestuerzt", "18/12": "falschen_gestuerzt", "12/18": "teilgekuerzt"}')
) as v(source_ref, known_errors)
 where ts.task_id = (
         select t.id from tasks t
          where t.source = 'edvance_fundament' and t.source_ref = v.source_ref
       )
   and ts.acceptance ? 'canonical';

-- ── 2. Selbsttest: urteilt lsa_grade ueber jedes Fehlbild wie erwartet? ────
--
-- Das Generator-Skript kennt die Bewertungsfunktion nicht und baut sie nicht
-- nach. Es fragt hier die Datenbank:
--
--   jedes Fehlbild ausser teilgekuerzt  -> 'nicht'
--   der teilgekuerzt-Wert               -> 'teilweise'
--
-- Zusaetzlich wird geprueft, dass canonical und require_reduced das UPDATE
-- ueberlebt haben und dass jeder gepruefte Wert auch wirklich in der
-- geschriebenen known_errors-Abbildung steht.
--
-- Weicht auch nur eine Probe ab, bricht die Transaktion ab und NICHTS wird
-- geschrieben. Lieber keine Feindiagnostik als eine falsche.

do $$
declare
  r        record;
  v_urteil text;
  v_label  text;
  v_fehler int := 0;
  v_anzahl int;
begin
  -- 2a. Die Akzeptanz-Grundlage darf das UPDATE nicht verloren haben.
  select count(*) into v_anzahl
    from task_solutions s
    join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament'
     and (s.acceptance -> 'canonical' is null
          or s.acceptance -> 'require_reduced' is null);
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) haben canonical/require_reduced verloren.', v_anzahl;
  end if;

  -- 2b. Jedes einzelne Fehlbild gegen lsa_grade.
  for r in
    select * from (values
      ('brueche-kuerzen-01', '17/23', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-01', '9/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-02', '11/15', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-02', '6/8', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-03', '7/11', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-03', '4/6', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-04', '15/23', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-04', '8/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-05', '11/17', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-05', '6/9', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-06', '19/23', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-06', '10/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-kuerzen-07', '3/11', 'nicht', 'additiv_gekuerzt'),
      ('brueche-kuerzen-07', '2/6', 'teilweise', 'teilgekuerzt'),
      ('brueche-addieren-01', '3/7', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-01', '3/12', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-01', '11/7', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-02', '2/9', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-02', '2/6', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-02', '3/9', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-02', '3/6', 'teilweise', 'teilgekuerzt'),
      ('brueche-addieren-03', '2/16', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-03', '2/12', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-03', '4/16', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-03', '4/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-addieren-04', '2/8', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-04', '2/6', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-04', '4/8', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-04', '4/6', 'teilweise', 'teilgekuerzt'),
      ('brueche-addieren-05', '4/12', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-05', '4/8', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-05', '7/12', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-06', '6/16', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-06', '6/12', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-06', '8/16', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-addieren-06', '8/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-addieren-07', '3/15', 'nicht', 'nenner_addiert'),
      ('brueche-addieren-07', '3/18', 'nicht', 'zaehler_nicht_erweitert'),
      ('brueche-addieren-07', '7/15', 'nicht', 'nenner_addiert_zaehler_ok'),
      ('brueche-multiplizieren-01', '22/15', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-02', '17/12', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-02', '6/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-multiplizieren-03', '23/20', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-03', '6/20', 'teilweise', 'teilgekuerzt'),
      ('brueche-multiplizieren-04', '11/10', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-05', '49/30', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-05', '20/30', 'teilweise', 'teilgekuerzt'),
      ('brueche-multiplizieren-06', '25/24', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-06', '6/24', 'teilweise', 'teilgekuerzt'),
      ('brueche-multiplizieren-07', '9/6', 'nicht', 'hauptnenner_bei_mult'),
      ('brueche-multiplizieren-07', '10/18', 'teilweise', 'teilgekuerzt'),
      ('brueche-dividieren-01', '8/15', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-01', '12/10', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-01', '10/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-dividieren-02', '3/8', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-02', '6/4', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-02', '4/6', 'teilweise', 'teilgekuerzt'),
      ('brueche-dividieren-03', '6/12', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-03', '8/9', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-04', '6/20', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-04', '15/8', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-05', '9/32', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-05', '24/12', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-05', '12/24', 'teilweise', 'teilgekuerzt'),
      ('brueche-dividieren-06', '10/18', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-06', '12/15', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-06', '15/12', 'teilweise', 'teilgekuerzt'),
      ('brueche-dividieren-07', '8/27', 'nicht', 'nicht_gestuerzt'),
      ('brueche-dividieren-07', '18/12', 'nicht', 'falschen_gestuerzt'),
      ('brueche-dividieren-07', '12/18', 'teilweise', 'teilgekuerzt')
    ) as p(source_ref, antwort, erwartet, label)
  loop
    select public.lsa_grade(
             'NUMERIC',
             s.acceptance,
             s.correct_answers,
             jsonb_build_object('value', r.antwort)
           ),
           s.acceptance #>> array['known_errors', r.antwort]
      into v_urteil, v_label
      from task_solutions s
      join tasks t on t.id = s.task_id
     where t.source = 'edvance_fundament' and t.source_ref = r.source_ref;

    if v_urteil is distinct from r.erwartet then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : lsa_grade sagt %, erwartet % (Fehlbild %)',
        r.source_ref, r.antwort, coalesce(v_urteil, '<null>'), r.erwartet, r.label;
    end if;

    if v_label is distinct from r.label then
      v_fehler := v_fehler + 1;
      raise warning 'Probe %/% : known_errors sagt %, erwartet %',
        r.source_ref, r.antwort, coalesce(v_label, '<fehlt>'), r.label;
    end if;
  end loop;

  if v_fehler > 0 then
    raise exception '% Probe(n) fehlgeschlagen — nichts geschrieben.', v_fehler;
  end if;

  -- 2c. Alle 28 haben jetzt known_errors, und der Status ist unberuehrt.
  select count(*) into v_anzahl
    from task_solutions s
    join tasks t on t.id = s.task_id
   where t.source = 'edvance_fundament' and s.acceptance ? 'known_errors';
  if v_anzahl <> 28 then
    raise exception 'nur % von 28 Aufgaben haben known_errors.', v_anzahl;
  end if;

  select count(*) into v_anzahl
    from tasks where source = 'edvance_fundament' and status <> 'draft';
  if v_anzahl > 0 then
    raise exception '% Aufgabe(n) stehen nicht mehr auf draft.', v_anzahl;
  end if;

  raise notice 'known_errors: alle Proben bestanden, 28 Aufgaben aktualisiert.';
end $$;

commit;
