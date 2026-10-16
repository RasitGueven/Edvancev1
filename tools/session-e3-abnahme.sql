-- session-e3-abnahme.sql — Abnahme 20261016130200_session_e3_musterloesungen (nur Wegwerf-DB). Bricht bei Abweichung ab.
-- Erwartet vorher.sol und vorher.tasks (Kopien vor der Migration, legt tools/session-e3-wegwerf-db.sh an).
\set ON_ERROR_STOP 1

do $$
declare n int;
begin
  -- 1 · Alle 18 Aufgaben der drei Knoten mit Musterlösung, ohne Befund, mit Fehlbild; term_ausklammern ohne
  --     Ablenker ohne Fehlbild.
  select count(*) into n
    from public.tasks t join public.task_solutions s on s.task_id = t.id
   where t.pruef_pilot and t.skill_key in ('gleichung_einschrittig', 'gleichung_zweischrittig', 'term_ausklammern')
     and nullif(btrim(coalesce(s.solution, '')), '') is not null
     and exists (select 1 from public.pruef_fehler_gruppen(s.acceptance))
     and jsonb_array_length(public.pruef_auffaelligkeiten(t, coalesce(s.correct_answers, '[]'), s.acceptance, s.solution)) = 0
     and public.lsa_acceptance_valid(s.acceptance);
  assert n = 18, format('%s von 18 Aufgaben mit Musterlösung, Fehlbild und ohne Befund', n);

  -- 2 · Nur leere Felder gefüllt: vorhandene Lösungen und acceptance unverändert, Hinweise und alles andere unberührt.
  select count(*) into n from vorher.sol v join public.task_solutions s using (task_id)
   where (nullif(btrim(coalesce(v.solution, '')), '') is not null and s.solution is distinct from v.solution)
      or (v.acceptance is not null and s.acceptance is distinct from v.acceptance)
      or (to_jsonb(v) - 'solution' - 'acceptance' - 'updated_at') is distinct from (to_jsonb(s) - 'solution' - 'acceptance' - 'updated_at');
  assert n = 0, format('%s Lösungszeilen über leere Felder hinaus verändert', n);
  select count(*) into n from vorher.sol v join public.task_solutions s using (task_id)
   where v.solution is distinct from s.solution;
  assert n = 18, format('%s Musterlösungen geschrieben statt 18', n);
  select count(*) into n from vorher.sol v join public.task_solutions s using (task_id)
   where v.acceptance is distinct from s.acceptance;
  assert n = 6, format('%s acceptance geschrieben statt 6', n);

  -- 3 · tasks: nur vorbefuellt.solution ergänzt, Status bleibt.
  select count(*) into n from vorher.tasks v join public.tasks t using (id)
   where (to_jsonb(v) - 'vorbefuellt' - 'pruef_version') is distinct from (to_jsonb(t) - 'vorbefuellt' - 'pruef_version')
      or (v.vorbefuellt - 'solution') is distinct from (t.vorbefuellt - 'solution')
      or (v.vorbefuellt ? 'solution' and v.vorbefuellt -> 'solution' is distinct from t.vorbefuellt -> 'solution');
  assert n = 0, format('%s Aufgaben über vorbefuellt.solution hinaus verändert', n);

  -- 4 · Neue Slugs mit Klartext, nicht freigegeben.
  select count(*) into n from public.fehlbild_labels
   where slug in ('ausklammern_nicht_ggt', 'ausklammern_glied_nicht_geteilt', 'ausklammern_falsch_geteilt')
     and nullif(btrim(klartext), '') is not null and freigegeben_am is null;
  assert n = 3, format('%s von 3 neuen Slugs mit Klartext', n);
  raise notice 'session-e3-abnahme: alle Prüfungen grün';
end $$;
