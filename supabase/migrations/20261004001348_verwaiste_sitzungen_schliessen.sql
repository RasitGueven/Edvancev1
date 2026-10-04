-- Verwaiste LSA-Sitzungen schliessen (W5-b).
--
-- Acht Sitzungen stehen seit 15.07.–20.09. auf 'in_progress', ohne eine einzige
-- Antwort. Sie gehoeren zu einem Testprofil (*.invalid) oder zu Leads, die vor dem
-- Vertragsprozess gesammelt auf 'rejected' gesetzt wurden. Einordnung je Sitzung:
-- docs/themen/verwaiste-sitzungen.md.
--
-- Nur Status -> 'aborted'. lsa_sessions hat keine Spalte fuer Ende oder Grund
-- (completed_at heisst "abgeschlossen" und bleibt leer); der Grund ("verwaist,
-- Testsitzung" bzw. "verwaist, unklar") steht in der Doku. Nichts wird geloescht,
-- Antworten, Urteile und Reports bleiben unberuehrt.
--
-- Die Sitzung 4ebe9d9c (25 Antworten) ist bewusst NICHT dabei, siehe
-- 20261004001349_echte_sitzung_abschliessen.sql.
--
-- Trigger: lsa_session_platz_release_trg laeuft mit, keine der Sitzungen hat einen
-- offenen Platz (Stand 04.10.). lsa_session_lead_fertig_trg greift nur bei
-- 'completed'.
--
-- Per expliziter ID-Liste. Im CI-Neuaufbau (leere DB) trifft sie 0 Zeilen.
-- Ein zweiter Lauf aendert nichts (where status = 'in_progress').
do $$
declare n int;
begin
  update lsa_sessions
     set status = 'aborted'
   where status = 'in_progress'
     and id in (
       '24db324a-d631-4cb2-ab4d-27a1756f62fa',  -- TEST: Testprofil *.invalid, 0 Antworten
       '77445f0e-2838-43e5-b161-922cc6e50b6b',  -- TEST: Lead mit Team-Mailadresse, 0 Antworten
       'c419c3f6-c143-463f-9860-db122491d4a3',  -- TEST: Lead "Test", 0 Antworten
       '08ac1882-47fa-4e1c-9e36-f66930a8e7eb',  -- TEST: Lead mit test@-Adresse, 0 Antworten
       '473324a0-1242-476e-88de-19ee712e9e8d',  -- TEST: Lead "Test", 0 Antworten
       '1da638ff-3e1b-47d1-acdf-7c318e6d814f',  -- UNKLAR: Lead abgelehnt, 0 Antworten
       '13c0d52b-6585-4c45-bff5-7337036697bc',  -- TEST: Lead mit Fantasie-Mail, 0 Antworten
       'aa1d3587-3088-4a14-b4dc-85644479a537'   -- UNKLAR: Lead abgelehnt, 0 Antworten
     );
  get diagnostics n = row_count;
  if n > 8 then raise exception 'Erwartet hoechstens 8 Sitzungen, geaendert %', n; end if;
  raise notice 'verwaiste Sitzungen auf aborted: %', n;
end $$;
