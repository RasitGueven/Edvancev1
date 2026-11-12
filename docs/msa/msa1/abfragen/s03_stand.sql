-- S03 · M0.3/M5.1: Stand für Vorher/Nachher. Ampeln je Klasse (lsa_status_roh, wie lsa_abdeckung ohne Rechteprüfung),
--       gezielte Prüfliste (pruef_ziel_roh: Skills, Vorschläge, Freigaben), ziehbare Aufgaben (lsa_im_pool),
--       Skills, die die Regel erfüllen (lsa_skill_bereit_roh), aktive/inaktive LSA-Aufgaben
\set QUIET on
select 'ampel Kl. ' || klasse || ' ' || ampel schluessel, count(*)::text wert
  from public.lsa_status_roh('2026/27') where klasse between 8 and 10 group by klasse, ampel
union all select 'pruef_ziel_roh Skills', count(*)::text from public.pruef_ziel_roh()
union all select 'pruef_ziel_roh Vorschläge (task_ids)', coalesce(sum(cardinality(task_ids)), 0)::text from public.pruef_ziel_roh()
union all select 'pruef_ziel_roh Freigabe-ids', coalesce(sum(cardinality(freigabe_ids)), 0)::text from public.pruef_ziel_roh()
union all select 'pruef_ziel_liste gezielt Aufgaben (nachgebaut: pruef_ziel_roh ⋈ Paket-Skills)',
       coalesce(sum(cardinality(z.task_ids)), 0)::text from public.pruef_ziel_roh() z
 where z.skill_key in (select skill_key from public.lsa_paket_skills_basis('2026/27'))
union all select 'pruef_ziel_liste nachpruefen Aufgaben (nachgebaut)', count(*)::text from tasks t
 where 'lsa' = any (t.einsatz) and t.status = 'ready'
   and coalesce((select p2.entscheidung from task_pruefungen p2 where p2.task_id = t.id order by p2.geprueft_am desc limit 1), '') <> 'passt'
union all select 'lsa_im_pool', count(*)::text from tasks t where 'lsa' = any (t.einsatz) and public.lsa_im_pool(t.id, false)
union all select 'Skills Regel erfüllt', count(*) filter (where erfuellt)::text from public.lsa_skill_bereit_roh(null)
union all select 'LSA-Aufgaben aktiv', count(*) filter (where coalesce(is_active, false))::text from tasks where 'lsa' = any (einsatz)
union all select 'LSA-Aufgaben inaktiv', count(*) filter (where not coalesce(is_active, false))::text from tasks where 'lsa' = any (einsatz)
order by 1;
