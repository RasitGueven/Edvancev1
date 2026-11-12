-- Rollback zu 20261112115143_sp1b_klartext_nachzug: Stand nach 20261112083401_sp1_klartext wiederherstellen (die sechs Bauformen waren dort
-- strittig und ohne Stufen-Klartext; SCH-3 hatte den Titel aus klartext-entwurf.json). Nichts wird gelöscht.
update public.bauform_stufen s set beschreibung = null, beispiel = null
  from public.bauformen b where s.bauform_id = b.id and b.schluessel in ('EIN-1', 'KO-1', 'EX-2', 'NP-4', 'NS-5');
update public.bauformen set titel = 'Hoch- oder Tiefpunkt bestimmen und verorten' where schluessel = 'SCH-3';
