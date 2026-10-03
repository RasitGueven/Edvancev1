-- Pruefquery zu 20261003121328_substrat_k10_exp.sql (nur lesend).
-- Erzeugt von tools/k10-rest-pruefung.mjs aus docs/k10-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('fkt_exp_wachstum', 'Lineares und exponentielles Wachstum, Wachstumsfaktor', 10),
  ('fkt_exp_term', 'Exponentialfunktion f(x) = a·bˣ aufstellen und auswerten', 11),
  ('fkt_exp_halbwert', 'Verdopplungszeit und Halbwertszeit', 11),
  ('fkt_exp_gleichung', 'Exponentialgleichungen bˣ = c lösen (Probieren, Logarithmus)', 7),
  ('fkt_exp_anwendung', 'Exponentielle Modelle: Zeitpunkte berechnen', 12)
),
soll_kante(skill_key, voraussetzt) as (values
  ('fkt_exp_wachstum', 'prozent_zins_zinseszins'),
  ('fkt_exp_wachstum', 'fkt_linear_gleichung'),
  ('fkt_exp_term', 'fkt_exp_wachstum'),
  ('fkt_exp_term', 'zahl_potenz_negativ'),
  ('fkt_exp_halbwert', 'fkt_exp_wachstum'),
  ('fkt_exp_gleichung', 'zahl_potenz_negativ'),
  ('fkt_exp_gleichung', 'runden_ueberschlag'),
  ('fkt_exp_anwendung', 'fkt_exp_term'),
  ('fkt_exp_anwendung', 'fkt_exp_gleichung')
)
select 'knoten: 5, Klasse 10, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 10 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
           and s.fach = 'mathematik') = 5 as ok,
       (select string_agg(s.skill_key || ':' || s.klasse_herkunft || '/' || s.fundament_tiefe, ' ' order by s.skill_key)
          from public.skills s join soll using (skill_key)) as ist
union all
select 'kanten: genau die 9 geplanten',
       (select count(*) from soll_kante k join public.skill_kante x
           on x.skill_key = k.skill_key and x.voraussetzt_skill_key = k.voraussetzt) = 9
       and (select count(*) from public.skill_kante x where x.skill_key in (select skill_key from soll)) = 9,
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
select 'neue Fehlbilder: 6, Klartext + Erklaerung, nicht freigegeben',
       count(*) = 6 and coalesce(bool_and(freigegeben_am is null and klartext <> '' and erklaerung <> ''), false),
       coalesce(string_agg(slug, ' ' order by slug), '')
  from public.fehlbild_labels
 where slug in ('linear_statt_exponentiell', 'abnahmefaktor_falsch', 'rate_aus_faktor_falsch', 'zeit_statt_perioden', 'anfangswert_faktor_vertauscht', 'log_falsch_geteilt')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 6, ''
  from public.fehlbild_labels l
  join (values ('linear_statt_exponentiell', 'sachaufgaben'), ('abnahmefaktor_falsch', 'einheiten_massstab'), ('rate_aus_faktor_falsch', 'einheiten_massstab'), ('zeit_statt_perioden', 'sachaufgaben'), ('anfangswert_faktor_vertauscht', null::text), ('log_falsch_geteilt', null::text)) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
