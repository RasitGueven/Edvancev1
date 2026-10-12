-- T3.1 Inhalt im Testlauf sichtbar: die Regel an einer Stelle (Entscheidung Rasit 08.10.2026, Paket T3).
--
-- In einer Testlauf-Session (coaching_sessions.testlauf) und in einer LSA eines Testkontos gilt jeder Inhalt, der
-- die Pruefung des Lena-Boards besteht, als freigegeben: Hinweise jeden Status mit Text, Fehlbild-Klartext,
-- Erklaersequenzen im Entwurf. Massstab ist die Aufgabe: Sie besteht die Pruefung, wenn pruef_ausschluss leer ist
-- und sie ready oder in Arbeit ist (dieselbe Menge wie der Testlauf-Pool in session_im_pool/lsa_im_pool,
-- Entscheidung 27). Beanstandete Aufgaben zaehlen nie.
--
-- Zwei Hilfen, beide nur intern (kein Grant an Clients; die Aufrufer sind SECURITY DEFINER):
--   testlauf_inhalt_sichtbar(task) - besteht der Inhalt dieser Aufgabe die Pruefung?
--   lsa_testinhalte(lsa_session)  - gilt fuer diese LSA die Testlauf-Regel? Testlauf oder Testkonto, wie F1 E2
--                                    (20261011140200, lsa_select_next_core v_pool). lsa_select_next_core selbst
--                                    bleibt unveraendert (Auswahl, nicht Teil von T3; offene-punkte-t3).
-- Ob eine Coaching-Session ein Testlauf ist, steht nur in coaching_sessions.testlauf; die Aufrufer lesen es dort,
-- nie aus einem Parameter des Clients.

create or replace function public.testlauf_inhalt_sichtbar(p_task_id uuid)
 returns boolean
 language sql
 stable
 set search_path to 'public', 'pg_temp'
as $function$
  select coalesce((select t.status in ('ready', 'draft', 'review', 'rueckfrage')
                          and public.pruef_ausschluss(t.id) is null
                     from public.tasks t where t.id = p_task_id), false)
$function$;

create or replace function public.lsa_testinhalte(p_session_id uuid)
 returns boolean
 language sql
 stable
 set search_path to 'public', 'pg_temp'
as $function$
  select coalesce((select coalesce(l.testlauf, false) or coalesce(s.ist_test, false)
                     from public.lsa_sessions l left join public.students s on s.id = l.student_id
                    where l.id = p_session_id), false)
$function$;

revoke all on function public.testlauf_inhalt_sichtbar(uuid), public.lsa_testinhalte(uuid)
  from public, anon, authenticated;
