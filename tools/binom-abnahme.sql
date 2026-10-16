-- binom-abnahme.sql — Abnahme 20261016130100_binom_fehlbilder_offen (nur Wegwerf-DB). Bricht bei Abweichung ab.
-- Erwartet die Tabelle vorher.sol (Kopie von task_solutions vor der Migration).
\set ON_ERROR_STOP 1

-- Board als Prüf-Admin (legt tools/binom-wegwerf-db.sh an), wie in der App: authenticated mit sub.
select set_config('request.jwt.claims',
  json_build_object('sub', '2b000000-0000-4000-8000-0000000000ad', 'role', 'authenticated')::text, false);
create temp table brd as select * from public.pruef_board();
select set_config('request.jwt.claims', '', false);

do $$
declare n int;
begin
  -- 1 · Keine MC-Aufgabe der vier Knoten meldet noch einen Ablenker ohne Fehlbild, keine einen anderen Befund.
  select count(*) into n
    from public.tasks t join public.task_solutions s on s.task_id = t.id,
         jsonb_array_elements(public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers, '[]'), s.acceptance, s.solution)) b
   where t.pruef_pilot and t.skill_key like 'term_binom_%';
  assert n = 0, format('%s Befund(e) in term_binom_*', n);

  -- 2 · Vorhandene known_errors unverändert (jeder alte Schlüssel mit altem Slug), sonst nur Schlüssel ergänzt.
  select count(*) into n
    from vorher.sol v join public.task_solutions s using (task_id), jsonb_each(coalesce(v.acceptance -> 'known_errors', '{}')) e
   where s.acceptance -> 'known_errors' -> e.key is distinct from e.value;
  assert n = 0, format('%s vorhandene known_errors verändert', n);
  select count(*) into n
    from vorher.sol v join public.task_solutions s using (task_id)
   where (to_jsonb(v) - 'acceptance' - 'updated_at') is distinct from (to_jsonb(s) - 'acceptance' - 'updated_at')
      or (v.acceptance - 'known_errors') is distinct from (s.acceptance - 'known_errors');
  assert n = 0, format('%s Lösungszeilen ausserhalb von known_errors verändert', n);
  select count(*) into n from vorher.sol v join public.task_solutions s using (task_id)
   where v.acceptance is distinct from s.acceptance;
  assert n = 22, format('%s Lösungszeilen ergänzt statt 22', n);

  -- 3 · Neue Aufgaben: draft, Pilot, im Board, im Testlauf-Pool, je Knoten mind. 2 taugliche, davon 1 ohne MC.
  select count(*) into n from public.tasks
   where source_ref in ('binom-quadrat-07', 'binom-gemischt-07') and status = 'draft' and pruef_pilot
     and einsatz = array['lsa'] and public.lsa_im_pool(id, true) and id in (select task_id from brd);
  assert n = 2, format('%s von 2 neuen Aufgaben draft/Pilot/Board/lsa_im_pool', n);

  -- 4 · Neue Slugs mit Klartext, nicht freigegeben; jeder benutzte Slug hat Klartext.
  select count(*) into n from public.fehlbild_labels
   where slug in ('binom_formel_verwechselt', 'mischglieder_nicht_aufgehoben', 'faktor_nicht_quadriert')
     and nullif(btrim(klartext), '') is not null and freigegeben_am is null;
  assert n = 3, format('%s von 3 neuen Slugs mit Klartext', n);
  select count(*) into n
    from public.tasks t join public.task_solutions s on s.task_id = t.id, public.pruef_fehler_gruppen(s.acceptance) g
   where t.pruef_pilot and t.skill_key like 'term_binom_%'
     and not exists (select 1 from public.fehlbild_labels l where l.slug = g.slug and nullif(btrim(l.klartext), '') is not null);
  assert n = 0, format('%s Slug(s) ohne Klartext in term_binom_*', n);
  raise notice 'binom-abnahme: alle Prüfungen grün';
end $$;
