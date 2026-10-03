-- Pruefquery zu 20261003121331_substrat_k10_sinus.sql (nur lesend).
-- Erzeugt von tools/k10-rest-pruefung.mjs aus docs/k10-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('fkt_sinus_einheitskreis', 'Sinus und Kosinus am Einheitskreis', 8),
  ('fkt_sinus_bogenmass', 'Bogenmaß und Gradmaß', 8),
  ('fkt_sinus_graph', 'Graph der Sinusfunktion', 9),
  ('fkt_sinus_parameter', 'Amplitude und Periode bei a·sin(b·x)', 10),
  ('fkt_sinus_periodisch', 'Periodische Vorgänge mit Sinusfunktionen beschreiben', 11)
),
soll_kante(skill_key, voraussetzt) as (values
  ('fkt_sinus_einheitskreis', 'geo_trigo_verhaeltnis'),
  ('fkt_sinus_einheitskreis', 'geo_koordinaten'),
  ('fkt_sinus_bogenmass', 'geo_kreis_sektor'),
  ('fkt_sinus_graph', 'fkt_sinus_einheitskreis'),
  ('fkt_sinus_graph', 'fkt_sinus_bogenmass'),
  ('fkt_sinus_parameter', 'fkt_sinus_graph'),
  ('fkt_sinus_periodisch', 'fkt_sinus_parameter')
)
select 'knoten: 5, Klasse 10, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 10 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 5 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 7 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 7
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 7,
       (select count(*)::text from public.skill_kante x where x.skill_key in (select skill_key from soll))
union all
select 'kanten echt flacher (Tiefen-Guard)',
       coalesce(bool_and(v.fundament_tiefe < s.fundament_tiefe), false),
       coalesce(string_agg(k.skill_key || '->' || k.voraussetzt_skill_key, ' ')
                filter (where v.fundament_tiefe >= s.fundament_tiefe), '')
  from public.skill_kante k
  join public.skills s on s.skill_key = k.skill_key
  join public.skills v on v.skill_key = k.voraussetzt_skill_key
 where k.skill_key in (select skill_key from soll)
union all
select 'Tiefe = 1 + tiefste Voraussetzung',
       coalesce(bool_and(s.fundament_tiefe = 1 + m.t), false), coalesce(string_agg(s.skill_key, ' ') filter (where s.fundament_tiefe <> 1 + m.t), '')
  from public.skills s
  join (select k.skill_key, max(v.fundament_tiefe) t from public.skill_kante k
          join public.skills v on v.skill_key = k.voraussetzt_skill_key group by 1) m using (skill_key)
 where s.skill_key in (select skill_key from soll)
union all
select 'neue Fehlbilder: 5, Klartext + Erklaerung, nicht freigegeben',
       count(*) = 5 and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), false),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in ('bogenmass_modus', 'periode_falsch', 'amplitude_verwechselt', 'quadrant_vorzeichen', 'grad_bogen_faktor_falsch')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 5, ''
  from public.fehlbild_labels l
  join (values ('bogenmass_modus', null::text), ('periode_falsch', null::text), ('amplitude_verwechselt', null::text), ('quadrant_vorzeichen', 'vorzeichen'), ('grad_bogen_faktor_falsch', 'einheiten_massstab')) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
