-- Lenas Rückfrage vom 20.10.2026 (M3; nach 20261021073637_lena_rf_prozent_schreibweisen): 54f5e1df wird
-- nicht freigegeben, sondern mit Antwort und Gegenfrage an Lena zurückgegeben (Rasit, 21.10.2026).
--
-- Bildet die Schreiblogik von pruef_rueckfrage_klaeren(p_task_id, 'an_lena', p_antwort) nach (Stand Prod,
-- pg_get_functiondef 21.10.2026). Einziger Unterschied: Statt auth.uid() steht Rasits Profil-ID
-- (profiles.role = 'admin', „Rasit Güven“), und es gibt keine Rollenprüfung, weil die Migration ohne JWT läuft.
--
--   pruef_rueckfrage_klaeren('an_lena')          hier
--   ------------------------------------------   -----------------------------------------------------------
--   get_my_role() = 'admin'                      entfällt
--   select … for update; status = 'rueckfrage'   dasselbe; andere Status werden übersprungen (Compare-and-set)
--   status 'draft', reviewed_by/_at = null       dasselbe, nur where status = 'rueckfrage'
--   delete task_pruefung_ausgang                 dasselbe
--   letzte task_pruefungen-Zeile: antwort,       dasselbe, beantwortet_von = Rasit
--     beantwortet_von = auth.uid(), _am = now()
--   pruef_protokoll(id, 'rueckfrage_an_lena',    derselbe Insert in task_admin_protokoll, von = Rasit
--     '[]', antwort, false), von = auth.uid()
--
-- Kein Freigabe-Gate: Die Aufgabe geht nicht nach 'ready'.
-- In der CI fehlt die Aufgabe, die Schleife läuft null Mal. Idempotent: ein zweiter Lauf findet die Aufgabe
-- nicht mehr in 'rueckfrage'. Kein begin/commit: mig klammert mit psql -1.

do $rf3$
declare
  c_rasit constant uuid := '35e4f9ac-d9aa-421c-8ba8-3948b1575f41';
  r       record;
  v_id    uuid;
  v_n     integer := 0;
begin
  for r in
    select v.task_id, v.antwort
      from (values
        ('54f5e1df-adc9-4fa3-b9c1-c15301c29cbe'::uuid,
         'Danke dir, du hast völlig recht: 0,48 % und 12/25 % sind nicht dasselbe wie 48 %. Wir haben das so umgestellt, dass bei Prozent nur noch 48 % zählt (12/25 und 0,48 sind natürlich weiter richtig). Auch 48 ohne Prozentzeichen zählt nicht mehr, denn das wäre 48 und nicht 0,48. Denselben Fehler haben wir bei der Münz-Aufgabe (50 %) gefunden und mitkorrigiert. Wenn Rot und Blau vertauscht werden, kommt hier immer dasselbe Ergebnis heraus: In jedem Weg werden dieselben zwei Zahlen malgenommen, nur in anderer Reihenfolge. Deshalb können wir diesen Fehler an der Antwort leider nicht erkennen. Zu deinem zweiten Beispiel: Welches Endergebnis würde ein Kind da typischerweise eintippen, wenn es die Gesamtzahl übersieht? Dann nehmen wir es als typischen Fehler auf.')
      ) v(task_id, antwort)
      join public.tasks t on t.id = v.task_id
     where t.status = 'rueckfrage'
     order by v.task_id
  loop
    perform 1 from public.tasks where id = r.task_id and status = 'rueckfrage' for update;
    if not found then continue; end if;

    update public.tasks
       set status = 'draft', reviewed_by = null, reviewed_at = null
     where id = r.task_id and status = 'rueckfrage';
    delete from public.task_pruefung_ausgang where task_id = r.task_id;

    select p.id into v_id from public.task_pruefungen p where p.task_id = r.task_id
     order by p.geprueft_am desc limit 1;
    if v_id is not null then
      update public.task_pruefungen
         set antwort = nullif(btrim(r.antwort), ''), beantwortet_von = c_rasit, beantwortet_am = now()
       where id = v_id;
    end if;

    insert into public.task_admin_protokoll (task_id, aktion, aenderungen, grund, sammel, von, am)
    values (r.task_id, 'rueckfrage_an_lena', '[]', nullif(btrim(r.antwort), ''), false, c_rasit, clock_timestamp());

    v_n := v_n + 1;
  end loop;
  raise notice 'lena_rf_an_lena: % Rückfrage(n) beantwortet und an Lena zurückgegeben', v_n;
end $rf3$;
