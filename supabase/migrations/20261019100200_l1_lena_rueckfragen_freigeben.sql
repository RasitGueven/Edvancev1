-- L1 (M2): Lenas acht Rückfragen vom 19.10.2026 beantworten und freigeben (nach M1 20261019100100_l1_lena_fehlbilder).
--
-- Bildet die Schreiblogik von pruef_rueckfrage_klaeren(p_task_id, 'freigeben', p_antwort) nach (Stand Prod,
-- pg_get_functiondef 19.10.2026). Einziger Unterschied: Statt auth.uid() steht Rasits Profil-ID
-- (profiles.role = 'admin', „Rasit Güven“), und es gibt keine Rollenprüfung, weil die Migration ohne JWT läuft.
--
--   pruef_rueckfrage_klaeren                     hier
--   ------------------------------------------   -----------------------------------------------------------
--   get_my_role() = 'admin'                      entfällt
--   select … for update; status = 'rueckfrage'   dasselbe; andere Status werden übersprungen (Compare-and-set)
--   task_status_set(id, 'ready'):                ausgeschrieben:
--     Gate freigabe_gate_fehler → raise            Gate vorab, raise exception bricht die ganze Migration ab
--     status 'ready', reviewed_by = auth.uid(),    status 'ready', reviewed_by = Rasit, reviewed_at = now(),
--     reviewed_at = now()                          nur where status = 'rueckfrage'
--   pruef_hinweise_setzen(id, 'geprueft')        derselbe Aufruf
--   letzte task_pruefungen-Zeile: antwort,       dasselbe, beantwortet_von = Rasit
--     beantwortet_von = auth.uid(), _am = now()
--   pruef_protokoll(id, 'rueckfrage_freigeben',  derselbe Insert in task_admin_protokoll, von = Rasit
--     '[]', antwort, false), von = auth.uid()
--
-- task_status_set wird nicht aufgerufen: Es verlangt admin oder ist_systemaufruf() und schreibt
-- reviewed_by = auth.uid() (hier NULL). Für den Weg nach 'ready' tut es sonst nichts (task_pruefung_ausgang
-- räumt es nur beim Weg nach 'draft').
--
-- In der CI fehlen die Aufgaben, die Schleife läuft null Mal; Rasits Profil wird dann nicht gebraucht.
-- Idempotent: ein zweiter Lauf findet keine Aufgabe mehr in 'rueckfrage'. Kein begin/commit: mig klammert mit psql -1.

do $l1f$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  r       record;
  v_gate  text;
  v_id    uuid;
  v_n     integer := 0;
begin
  for r in
    select v.task_id, v.antwort
      from (values
        ('17674b19-fe14-42ca-98db-6598fa8c5a3a'::uuid, 'Danke, übernommen! Den Richtungsfehler (Plus und Minus vertauscht) haben wir als eigenes Fehlerbild angelegt und bei allen Aufgaben dieser Fertigkeit ergänzt.'),
        ('3b44eada-3589-4bdb-a33b-2fb2ca0a1726'::uuid, 'Danke, übernommen! Den Richtungsfehler (Plus und Minus vertauscht) haben wir als eigenes Fehlerbild angelegt und bei allen Aufgaben dieser Fertigkeit ergänzt.'),
        ('c92aa7e8-1e2d-4c80-a1fc-0fe4fedd86b0'::uuid, 'Danke, übernommen! Den Richtungsfehler (Plus und Minus vertauscht) haben wir als eigenes Fehlerbild angelegt und bei allen Aufgaben dieser Fertigkeit ergänzt.'),
        ('27f51c08-6a47-4ceb-b189-f5f07cbcf1cf'::uuid, 'Du hattest recht, die Zuordnung war falsch: Die 8 ist jetzt ‚Betrag richtig, Vorzeichen gekippt‘, die 4 ‚Vorzeichen der ersten Zahl übersehen‘. Die −4 haben wir als Richtungsfehler ergänzt, auch bei allen anderen Aufgaben dieser Fertigkeit.'),
        ('2e8ce53f-1357-48b2-8d76-0633ae836980'::uuid, 'Danke, übernommen! ‚Minus mal Minus gibt Plus, dann addiert‘ ist jetzt ein eigenes Fehlerbild, ergänzt bei allen Multiplikationen mit zwei negativen Zahlen.'),
        ('e58cb290-db86-40df-b60b-03aee393107b'::uuid, 'Danke, übernommen! ‚Minus mal Minus gibt Plus, dann addiert‘ ist jetzt ein eigenes Fehlerbild, ergänzt bei allen Multiplikationen mit zwei negativen Zahlen.'),
        ('7db70449-d6fa-47dd-9423-1e8c75ce8c8f'::uuid, 'Danke für die Einordnung, sehen wir genauso. Bei der Division ergänzen wir den Fehler nicht.'),
        ('0b7e781c-60ae-4a93-afb8-2ee2b400b15a'::uuid, 'Danke! Der Text ist jetzt ohne n formuliert, AFB II haben wir übernommen.')
      ) v(task_id, antwort)
      join public.tasks t on t.id = v.task_id
     where t.status = 'rueckfrage'
     order by v.task_id
  loop
    perform 1 from public.tasks where id = r.task_id and status = 'rueckfrage' for update;
    if not found then continue; end if;

    v_gate := public.freigabe_gate_fehler(r.task_id);
    if v_gate is not null then
      raise exception 'l1_rueckfragen_freigeben: Gate bei %: %', r.task_id, v_gate;
    end if;

    update public.tasks
       set status = 'ready', reviewed_by = c_rasit, reviewed_at = now()
     where id = r.task_id and status = 'rueckfrage';

    perform public.pruef_hinweise_setzen(r.task_id, 'geprueft');

    select p.id into v_id from public.task_pruefungen p where p.task_id = r.task_id
     order by p.geprueft_am desc limit 1;
    if v_id is not null then
      update public.task_pruefungen
         set antwort = nullif(btrim(r.antwort), ''), beantwortet_von = c_rasit, beantwortet_am = now()
       where id = v_id;
    end if;

    insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von, am)
    values (r.task_id, 'rueckfrage_freigeben', '[]', nullif(btrim(r.antwort), ''), false, c_rasit, clock_timestamp());

    v_n := v_n + 1;
  end loop;
  raise notice 'l1_rueckfragen_freigeben: % Rückfrage(n) beantwortet und freigegeben', v_n;
end $l1f$;
