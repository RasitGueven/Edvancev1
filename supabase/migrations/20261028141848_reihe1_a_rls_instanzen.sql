-- Reihe 1 · A: Kinder und Eltern lesen Bauform-Instanzen nicht direkt aus tasks (Zweitpruefung A2, offener Punkt;
-- Anweisung Rasit vom 28.10.2026). Die Policy read_tasks_by_role liess jede angemeldete Rolle ready-Zeilen lesen,
-- also auch params (Generator-Parameter, aus denen die Loesung folgt) und pruefmaschine einer freigegebenen Instanz.
--
-- Neu: Coaches und Admins wie bisher alles; alle anderen Rollen nur ready-Zeilen OHNE bauform_id. Instanzen erreichen
-- Kind und Tablet nur ueber die Funktionen aus §9 (aufgabe_ziehen, aufgabe_payload, session_*), alle security definer;
-- die liefern die Kindersicht ohne params/pruefmaschine.
--
-- Unberuehrt: die LSA (deren Aufgaben haben keine bauform_id), alle Schreibrechte (admin_write_tasks), anon.
-- Scan (pg_proc, Prod 28.10.2026): security-invoker-Funktionen, die tasks lesen, sind lsa_term_acceptance_guard,
-- freigabe_gate_fehler, pruef_*, session_im_pool, testlauf_inhalt_sichtbar. Sie laufen entweder als Trigger/Admin-Pfad
-- oder werden aus security-definer-Funktionen gerufen (aufgabe_ziehen, session_aufgabe_waehlen, lsa_im_pool,
-- aufgabe_ausgeben, antwort_abgeben, hinweis_abrufen …) und sehen dort weiter alle Zeilen. Die edvance-app liest
-- tasks nicht direkt; die Web-Lese-Pfade in src/lib/supabase (tasks.ts, heute.ts, taskAuthoring.ts) laufen fuer
-- Coach/Admin oder fuer Aufgaben ohne Bauform.
--
-- Pruefabfrage: select qual ~ 'bauform_id IS NULL' from pg_policies where tablename = 'tasks' and policyname = 'read_tasks_by_role';
--               vorher f   nachher t
alter policy read_tasks_by_role on public.tasks
  using ((public.get_my_role() = any (array['coach'::text, 'admin'::text]))
         or (public.get_my_role() is not null and status = 'ready'::text and bauform_id is null));

comment on table public.tasks is
  'Aufgaben. Lesen (read_tasks_by_role): coach/admin alles, jede andere Rolle nur status=''ready'' ohne bauform_id. Draft-Content bleibt in der Redaktion; Bauform-Instanzen (params, pruefmaschine) liest das Kind nur ueber die A-Funktionen (aufgabe_payload). Die LSA-RPCs sind SECURITY DEFINER und von der Policy nicht betroffen.';
