-- Rollback zu 20261113082851_sf1_schulen: entfernt genau die 46 Schulen dieser Migration (über die Schulnummer),
-- solange nichts auf sie zeigt. Zeigt ein Lead, Kind oder Vertrag schon auf eine von ihnen, scheitert der Rollback
-- (Fremdschlüssel) — dann nicht erzwingen, sondern Rasit fragen. Den Eintrag in
-- supabase_migrations.schema_migrations danach von Hand entfernen.
delete from public.schulen
 where schulnummer = any (array[
    '160064','160076','160090','160106','160118','160120','160131','160155','160179','160180','160192','160209',
    '160210','160222','160260','160430','160568','160570','160581','197567','100036','100041','100068','100071',
    '100169','100208','100210','100211','100212','100219','100235','164161','183726','184287','184913','184937',
    '185176','187902','188165','193021','195959','196459','197488','198742','198912','191942'
  ]);
