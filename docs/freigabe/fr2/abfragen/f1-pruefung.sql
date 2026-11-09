-- FR-2 F1 Prüfabfrage nach dem Einspielen (dbread, nur lesend). Erwartung je Spalte im Kommentar.
select (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'
          and p.proname in ('lsa_regel', 'lsa_pakete_roh', 'lsa_paket_skills_roh', 'lsa_paket_cache_auffrischen',
                            'lsa_paket_cache_trigger', 'lsa_pakete_basis', 'lsa_paket_skills_basis',
                            'lsa_skill_bereit_roh', 'lsa_status_roh', 'pruef_ziel_roh', 'lsa_schuljahr_heute',
                            'lsa_pakete', 'lsa_skill_bereit', 'lsa_paket_skills', 'lsa_paket_status', 'lsa_abdeckung',
                            'lsa_wirkung', 'pruef_ziel_liste', 'lsa_abdeckung_auffrischen')) funktionen,      -- 19
       (select count(*) from pg_trigger where tgname like 'lsa_paket_cache_%') trigger_anzahl,                -- 7
       (select count(*) from session_einstellungen
         where schluessel in ('lsa_regel_texte', 'lsa_regel_ohne_mc', 'lsa_fokus_quartal')) stellschrauben,   -- 3
       (select schuljahr || ' / ' || case when veraltet then 'veraltet' else 'frisch' end || ' / ' || coalesce(fehler, 'ok')
          from lsa_paket_cache_stand) speicher,                                                  -- 2026/27 / frisch / ok
       (select count(*) from lsa_paket_cache where klasse between 8 and 10) pakete_8_10,                       -- 501
       (select count(*) from schule_fokus) fokus;                                                             -- 0
