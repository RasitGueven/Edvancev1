-- Rollback zu reihe1_a2_fehlbild_schluessel: die 39 qf_-Schluessel wieder entfernen, solange keine Aufgabe, keine
-- Antwort und kein Video sie nutzt (sonst Abbruch), danach den Eintrag in supabase_migrations.schema_migrations loeschen.
do $$
begin
  if exists (select 1 from public.session_antworten where fehlbild_slug like 'qf\_%')
     or exists (select 1 from public.lsa_responses where fehlbild_slug like 'qf\_%')
     or exists (select 1 from public.task_solutions where acceptance::text like '%"qf\_%') then
    raise exception 'Rollback abgebrochen: qf_-Schluessel sind schon in Gebrauch';
  end if;
end $$;
delete from public.fehlbild_labels where slug like 'qf\_%' and freigegeben_am is null;
