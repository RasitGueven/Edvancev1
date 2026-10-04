-- Probe-Sitzung 4ebe9d9c schliessen (W5-b, Nachtrag).
--
-- Echte Probe-LSA (Klasse 8, 25 Antworten vom 16.08.), Lead abgelehnt, bewusst
-- nicht abgeschlossen: Ein Abschluss ueber lsa_finish haette keinen Zweck und
-- wuerde neue abgeleitete Daten ueber das Kind erzeugen (result_summary). Deshalb
-- nur Status -> 'aborted', wie 20261004001348_verwaiste_sitzungen_schliessen.
-- Antworten und Urteile bleiben unberuehrt; ob sie geloescht werden, ist eine
-- eigene Datenschutz-Entscheidung (docs/themen/verwaiste-sitzungen.md).
--
-- Trigger: lsa_session_platz_release_trg findet keinen offenen Platz (Stand
-- 04.10.), lsa_session_lead_fertig_trg greift nur bei 'completed'.
--
-- Im CI-Neuaufbau (leere DB) trifft sie 0 Zeilen, ein zweiter Lauf ebenso.
do $$
declare n int;
begin
  update lsa_sessions
     set status = 'aborted'
   where status = 'in_progress'
     and id in (
       '4ebe9d9c-e186-40eb-b6a5-9d7e9fcef1f5'   -- ECHT: Probe-LSA, Lead abgelehnt, bewusst nicht abgeschlossen
     );
  get diagnostics n = row_count;
  if n > 1 then raise exception 'Erwartet hoechstens 1 Sitzung, geaendert %', n; end if;
  raise notice 'Probe-Sitzung auf aborted: %', n;
end $$;
