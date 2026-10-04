-- PRUEFUNG zu W5-b (verwaiste LSA-Sitzungen). Nur lesend, laeuft mit dbread:
--
--   ~/bin/dbread -f supabase/checks/verwaiste_sitzungen.PRUEFUNG.sql
--
-- Nach 20261004001348_verwaiste_sitzungen_schliessen und
-- 20261004002740_probe_sitzung_schliessen gibt es keine 'in_progress'-Sitzung
-- mehr, die aelter als einen Tag ist. Die echte Probe-Sitzung 4ebe9d9c steht auf
-- 'aborted' (nicht 'completed', kein result_summary). Bricht sonst mit Fehler ab.
do $$
declare
  v_echt constant uuid := '4ebe9d9c-e186-40eb-b6a5-9d7e9fcef1f5';
  v_rest int;
  v_abgebrochen int;
  v_echt_status text;
  v_echt_summary boolean;
begin
  select count(*) into v_rest
    from lsa_sessions
   where status = 'in_progress'
     and started_at < now() - interval '1 day';
  if v_rest > 0 then
    raise exception 'Noch % verwaiste in_progress-Sitzung(en) aelter als 1 Tag', v_rest;
  end if;

  select status, result_summary is not null into v_echt_status, v_echt_summary
    from lsa_sessions where id = v_echt;
  if v_echt_status = 'completed' or v_echt_summary then
    raise exception 'Probe-Sitzung % wurde abgeschlossen (status %), sollte aborted sein',
      v_echt, v_echt_status;
  end if;

  select count(*) into v_abgebrochen
    from lsa_sessions
   where status = 'aborted'
     and id in ('24db324a-d631-4cb2-ab4d-27a1756f62fa', '77445f0e-2838-43e5-b161-922cc6e50b6b',
                'c419c3f6-c143-463f-9860-db122491d4a3', '08ac1882-47fa-4e1c-9e36-f66930a8e7eb',
                '473324a0-1242-476e-88de-19ee712e9e8d', '1da638ff-3e1b-47d1-acdf-7c318e6d814f',
                '13c0d52b-6585-4c45-bff5-7337036697bc', 'aa1d3587-3088-4a14-b4dc-85644479a537',
                v_echt);

  raise notice 'OK: 0 verwaiste Sitzungen; % von 9 auf aborted; Probe-Sitzung: %',
    v_abgebrochen, coalesce(v_echt_status, 'nicht vorhanden');
end $$;
