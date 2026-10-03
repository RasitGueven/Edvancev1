-- Pruefquery zu 20261003104946_substrat_k8_winkel.sql — rein lesend (laeuft auch mit dbread).
-- Erwartung: jede Zeile ok = t.
--   4 Knoten (Kl. 8, Tiefen neben_scheitel 2, parallelen 3, dreieck 4, thales 5),
--   5 Kanten, jede echt flacher, keine Kante von einem Bestandsknoten auf die neuen,
--   4 neue Fehlbilder (unfreigegeben, Klartext, Familie NULL),
--   wiederverwendete Alt-Slugs vorhanden (nur Prod).
--
--   psql … -v ON_ERROR_STOP=1 [-v lokal=true] -f supabase/checks/k8_winkel_substrat.PRUEFUNG.sql
-- lokal=true (Wegwerf-DB): die Alt-Slugs kommen in Prod aus einem Datenimport, nicht aus
-- Migrationen; lokal fehlen sie, die Pruefung entfaellt dann.

\if :{?lokal}
\else
  \set lokal false
\endif

select 'knoten: vier, Klasse 8, Tiefen 2/3/4/5' as pruefung,
       count(*) = 4 and bool_and(klasse_herkunft = 8 and fach = 'mathematik')
       and string_agg(skill_key || ':' || fundament_tiefe, ' ' order by skill_key)
           = 'geo_winkel_dreieck:4 geo_winkel_neben_scheitel:2 geo_winkel_parallelen:3 geo_winkel_thales:5' as ok,
       string_agg(skill_key || ':' || klasse_herkunft || '/' || fundament_tiefe, ' ' order by skill_key) as ist
  from public.skills
 where skill_key in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')
union all
select 'geo_winkel_summe unveraendert (Kl. 7, Tiefe 3, eine Kante)',
       (select klasse_herkunft = 7 and fundament_tiefe = 3 from public.skills where skill_key = 'geo_winkel_summe')
       and (select count(*) = 1 from public.skill_kante where skill_key = 'geo_winkel_summe'),
       ''
union all
select 'kanten: genau die fuenf',
       count(*) = 5 and string_agg(skill_key || '->' || voraussetzt_skill_key, ' ' order by skill_key, voraussetzt_skill_key)
         = 'geo_winkel_dreieck->geo_winkel_parallelen geo_winkel_dreieck->geo_winkel_summe '
           'geo_winkel_neben_scheitel->dezimal_add_sub geo_winkel_parallelen->geo_winkel_neben_scheitel '
           'geo_winkel_thales->geo_winkel_dreieck',
       count(*)::text
  from public.skill_kante
 where skill_key in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')
union all
select 'kanten echt flacher, Tiefe = 1 + tiefste Voraussetzung',
       bool_and(v.fundament_tiefe < s.fundament_tiefe)
       and (select bool_and(s2.fundament_tiefe = 1 + (select max(v2.fundament_tiefe) from public.skill_kante k2
                                                        join public.skills v2 on v2.skill_key = k2.voraussetzt_skill_key
                                                       where k2.skill_key = s2.skill_key))
              from public.skills s2
             where s2.skill_key in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')
union all
select 'keine Kante von einem anderen Knoten auf die neuen', count(*) = 0, coalesce(string_agg(skill_key, ' '), '')
  from public.skill_kante
 where voraussetzt_skill_key in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')
   and skill_key not in ('geo_winkel_neben_scheitel', 'geo_winkel_parallelen', 'geo_winkel_dreieck', 'geo_winkel_thales')
union all
select 'fehlbilder neu: vier, unfreigegeben, Klartext + Erklaerung, Familie NULL',
       count(*) = 4 and bool_and(freigegeben_am is null and familie is null
                                 and coalesce(klartext, '') <> '' and coalesce(erklaerung, '') <> ''),
       string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('winkelbeziehung_verwechselt', 'basiswinkel_falsch_zugeordnet',
                'rechter_winkel_falsche_ecke', 'aussenwinkel_verwechselt')
union all
select 'fehlbilder neu: Klartext woertlich (Stichprobe Anfang/Ende)',
       count(*) = 4, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where (slug = 'winkelbeziehung_verwechselt' and klartext = 'Hält zwei Winkel für gleich groß, die sich zu 180° ergänzen, oder umgekehrt.')
    or (slug = 'basiswinkel_falsch_zugeordnet' and klartext = 'Verwechselt im gleichschenkligen Dreieck den Winkel an der Spitze mit einem Basiswinkel.')
    or (slug = 'rechter_winkel_falsche_ecke' and klartext = 'Setzt beim Satz des Thales den rechten Winkel an die falsche Ecke.')
    or (slug = 'aussenwinkel_verwechselt' and klartext = 'Rechnet mit dem Innenwinkel, wo der Außenwinkel gefragt ist, oder umgekehrt.')
union all
select 'wiederverwendete Alt-Slugs vorhanden (nur Prod)',
       :lokal or count(*) = 3, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('summe_360_statt_180', 'differenz_vergessen', 'halbieren_vergessen');
