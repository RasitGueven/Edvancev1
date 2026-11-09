-- FR-2 F4.1 Zählabfrage nach dem Einspielen (dbread). Erwartung: 3 neue Einstiege; Themen der Pläne/KLP Kl. 8–10
-- ohne Einstieg: 0; Pakete Kl. 8–10 ohne Einstieg (Speicher nach lsa_abdeckung_auffrischen bzw. live): 0.
select (select count(*) from thema_einstieg where (thema_key, skill_key) in (('rationale_zahlen', 'vorzeichen_vorrang'),
          ('zuordnungen', 'proportionalitaet'), ('statistik_beurteilen', 'stoch_bedingt_irrefuehrend'))) neue_einstiege,
       (select count(*) from (select distinct p.thema_key from schul_themenplan p where lower(p.fach) = 'mathematik'
           and p.klasse between 8 and 10 and p.thema_key is not null
         union select unnest(lsa_klp_themen('mathematik', k)) from generate_series(8, 10) k) t
         where not exists (select 1 from thema_einstieg te where te.thema_key = t.thema_key)) themen_ohne_einstieg,
       (select count(*) from lsa_pakete_basis(lsa_schuljahr_heute()) where klasse between 8 and 10 and not hat_einstieg)
         pakete_ohne_einstieg;
