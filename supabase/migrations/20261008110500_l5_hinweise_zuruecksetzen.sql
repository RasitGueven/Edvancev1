-- L5.1 Kinder-Hinweise pruefen und freigeben, Teil 5: Beanstanden oder Zuruecksetzen einer freigegebenen Aufgabe.
--
-- Entscheidung Rasit (06.10., nach dem Consensus-Check): Beanstandung oder Zuruecksetzen einer freigegebenen
-- Aufgabe setzt ihre Kinder-Hinweise auf entwurf, ueber denselben Weg wie die Ruecknahme (pruef_hinweise_setzen).
-- Ein Trigger statt je Funktion, damit jeder Weg aus ready gilt:
--   lena_beanstande, lena_beanstande_muster (setzen beanstandet ohne Statuspruefung),
--   task_status_set aus dem Editor (ready -> draft/review),
--   direktes UPDATE ueber die Policy admin_write_tasks (Fallback in taskAuthoring.updateTaskStatus),
--   und die beiden Ruecknahmen (dort rufen pruef_freigabe_zuruecknehmen/freigabe_zuruecknehmen es schon selbst;
--   der zweite Aufruf findet nichts mehr und schreibt nicht).
-- SECURITY DEFINER: Ein Admin, der per PostgREST tasks.status aendert, hat keine Rechte auf task_solutions.
-- Der verschachtelte Versions-Update (task_solutions_pruef_version) sieht old.status <> 'ready' und laeuft nicht erneut.

create function public.tasks_hinweise_bei_ruecknahme()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform public.pruef_hinweise_setzen(new.id, 'entwurf');
  return null;
end;
$$;

comment on function public.tasks_hinweise_bei_ruecknahme() is
  'L5: verlaesst eine Aufgabe ready (Ruecknahme, Beanstandung, Editor), fallen ihre Kinder-Hinweise auf entwurf.';

create trigger tasks_hinweise_bei_ruecknahme
  after update of status on public.tasks
  for each row
  when (old.status = 'ready' and new.status is distinct from 'ready')
  execute function public.tasks_hinweise_bei_ruecknahme();

revoke all on function public.tasks_hinweise_bei_ruecknahme() from public, anon, authenticated;
