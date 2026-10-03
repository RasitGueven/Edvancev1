-- Pruefquery zu 20261003104943_substrat_k8_lgs.sql (rein lesend, laeuft auch mit dbread).
-- Erwartung: jede Zeile ok = t.
--   5 Knoten (Kl. 8, Tiefen einsetzen 7, gleichsetzen 8, addition 8, grafisch 8, sachaufgabe 9),
--   13 Kanten, jede echt flacher, 4 neue Fehlbilder (unfreigegeben, mit Klartext und Erklaerung),
--   wiederverwendete Slugs vorhanden.
-- psql -v lokal=true (Wegwerf-DB): die Pruefung der wiederverwendeten Alt-Slugs entfaellt
-- (lokal fehlen die Alt-Slugs aus dem Datenimport). Ohne Variable alles pruefen.

\if :{?lokal}
\else
  \set lokal false
\endif

select 'knoten' as pruefung,
       count(*) = 5 and bool_and(klasse_herkunft = 8 and fach = 'mathematik')
       and string_agg(skill_key || ':' || fundament_tiefe, ' ' order by skill_key)
           = 'gleichung_lgs_addition:8 gleichung_lgs_einsetzen:7 gleichung_lgs_gleichsetzen:8 '
             'gleichung_lgs_grafisch:8 gleichung_lgs_sachaufgabe:9' as ok,
       string_agg(skill_key || ':' || klasse_herkunft || '/' || fundament_tiefe, ' ' order by skill_key) as ist
  from public.skills where skill_key like 'gleichung_lgs_%'
union all
select 'kanten', count(*) = 13, count(*)::text
  from public.skill_kante where skill_key like 'gleichung_lgs_%'
union all
select 'kanten_soll', count(*) = 13, string_agg(skill_key || '->' || voraussetzt_skill_key, ' ')
  from public.skill_kante
 where (skill_key, voraussetzt_skill_key) in (
   ('gleichung_lgs_einsetzen', 'term_minusklammer'), ('gleichung_lgs_einsetzen', 'gleichung_zweischrittig'),
   ('gleichung_lgs_einsetzen', 'term_einsetzen'),
   ('gleichung_lgs_gleichsetzen', 'gleichung_beidseitig'), ('gleichung_lgs_gleichsetzen', 'gleichung_neg_koeffizient'),
   ('gleichung_lgs_gleichsetzen', 'term_einsetzen'),
   ('gleichung_lgs_addition', 'gleichung_neg_koeffizient'), ('gleichung_lgs_addition', 'term_ausmultiplizieren'),
   ('gleichung_lgs_addition', 'term_einsetzen'),
   ('gleichung_lgs_grafisch', 'fkt_linear_graph'),
   ('gleichung_lgs_sachaufgabe', 'gleichung_modellieren'), ('gleichung_lgs_sachaufgabe', 'gleichung_lgs_einsetzen'),
   ('gleichung_lgs_sachaufgabe', 'gleichung_lgs_addition'))
union all
select 'kanten_echt_flacher', coalesce(bool_and(v.fundament_tiefe < s.fundament_tiefe), false),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key like 'gleichung_lgs_%'
union all
select 'tiefe = 1 + tiefste Voraussetzung', coalesce(bool_and(s.fundament_tiefe = x.max_v + 1), false),
       string_agg(s.skill_key || ':' || s.fundament_tiefe || '/' || x.max_v, ' ' order by s.skill_key)
  from public.skills s
  join (select k.skill_key, max(v.fundament_tiefe) max_v
          from public.skill_kante k join public.skills v on v.skill_key = k.voraussetzt_skill_key
         group by 1) x on x.skill_key = s.skill_key
 where s.skill_key like 'gleichung_lgs_%'
union all
select 'fehlbilder_neu', count(*) = 4 and bool_and(freigegeben_am is null) and bool_and(klartext <> '')
       and bool_and(erklaerung <> '') and bool_and(familie = 'gleichungen_umformen'),
       string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('nicht_alle_glieder_multipliziert', 'seiten_ungleich_verknuepft',
                'loesungsanzahl_verwechselt', 'parallele_uebersehen')
union all
select 'fehlbilder_klartext_woertlich',
       count(*) filter (where (slug, klartext) in (
         ('nicht_alle_glieder_multipliziert', 'Multipliziert beim Additionsverfahren nur einen Teil der Gleichung mit dem Faktor.'),
         ('seiten_ungleich_verknuepft', 'Verknüpft die beiden Gleichungen links und rechts unterschiedlich – links subtrahiert, rechts addiert oder umgekehrt.'),
         ('loesungsanzahl_verwechselt', 'Verwechselt „keine Lösung“ und „unendlich viele Lösungen“.'),
         ('parallele_uebersehen', 'Nimmt genau eine Lösung an, obwohl die Geraden parallel sind oder aufeinander liegen.'))) = 4,
       ''
  from public.fehlbild_labels
union all
select 'wiederverwendet_vorhanden (Prod)', :lokal or count(*) = 12, string_agg(slug, ' ' order by slug)
  from public.fehlbild_labels
 where slug in ('klammer_vergessen', 'vorzeichen_beim_umstellen', 'falsches_vorzeichen_beim_zusammenfuehren',
                'variablen_nicht_zusammengefuehrt', 'koordinaten_vertauscht', 'groessen_vertauscht',
                'bedingung_unvollstaendig', 'division_vergessen', 'falsche_groesse_beantwortet',
                'koordinate_vorzeichen_verloren', 'klammer_falsch_gesetzt', 'umfang_falsch_modelliert');
