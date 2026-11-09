-- FR-2 F2 Prüfabfrage nach dem Einspielen von fr2_nur_pilot_aus (dbread). Erwartung: nur_pilot f, im Board
-- (pruef_ausschluss null) jetzt alle 716 LSA-Entwürfe sichtbar statt der Pilot-Teilmenge; pilot_fehlt überall leer.
select (select nur_pilot from pruef_einstellungen) nur_pilot,
       (select count(*) from tasks t where 'lsa' = any (t.einsatz) and t.status = 'draft'
           and public.pruef_ausschluss(t.id) is null and public.pruef_im_pilot(t)) lsa_entwuerfe_fuer_lena;
