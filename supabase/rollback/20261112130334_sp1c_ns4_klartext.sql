-- Rollback zu 20261112130334_sp1c_ns4_klartext: Stand davor wiederherstellen (NS-4 Stufe 2 und 3 ohne Klartext). Nichts wird gelöscht.
update public.bauform_stufen s set beschreibung = null, beispiel = null
  from public.bauformen b where s.bauform_id = b.id and b.schluessel = 'NS-4' and s.stufe in (2, 3);
