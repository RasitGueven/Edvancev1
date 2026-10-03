-- Pruefquery zu 20261003105859_substrat_k9_bedingt.sql (nur lesend).
-- Erzeugt von tools/k9-rest-pruefung.mjs aus docs/k9-rest/graph.json — unabhaengig von der Migration.
-- Erwartung: jede Zeile ok = t.
\if :{?lokal}
\else
  \set lokal false
\endif

with soll(skill_key, label, tiefe) as (values
  ('stoch_bedingt_vierfeld', 'Vierfeldertafel ergänzen', 5),
  ('stoch_bedingt_wkeit', 'Bedingte Wahrscheinlichkeit aus der Vierfeldertafel', 6),
  ('stoch_bedingt_unabhaengig', 'Stochastische Unabhängigkeit prüfen', 7),
  ('stoch_bedingt_umkehr', 'Bedingte Wahrscheinlichkeiten umkehren (Testsituationen)', 7),
  ('stoch_bedingt_irrefuehrend', 'Irreführende Aussagen und Darstellungen erkennen', 8)
),
soll_kante(skill_key, voraussetzt) as (values
  ('stoch_bedingt_vierfeld', 'bruch_dezimal'),
  ('stoch_bedingt_wkeit', 'stoch_bedingt_vierfeld'),
  ('stoch_bedingt_unabhaengig', 'stoch_bedingt_wkeit'),
  ('stoch_bedingt_umkehr', 'stoch_bedingt_wkeit'),
  ('stoch_bedingt_umkehr', 'prozent_prozentwert'),
  ('stoch_bedingt_irrefuehrend', 'stoch_bedingt_wkeit'),
  ('stoch_bedingt_irrefuehrend', 'prozent_prozentsatz')
)
select 'knoten: 5, Klasse 9, Tiefe und Label wie geplant' as pruefung,
       (select count(*) from soll join public.skills s using (skill_key)
         where s.klasse_herkunft = 9 and s.fundament_tiefe = soll.tiefe and s.label = soll.label
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
 where slug in ('bedingung_vertauscht', 'gesamtheit_statt_bedingung', 'randsumme_verwechselt', 'achse_abgeschnitten_uebersehen', 'absolut_statt_relativ')
union all
select 'neue Fehlbilder: Familie wie geplant',
       count(*) = 5, ''
  from public.fehlbild_labels l
  join (values ('bedingung_vertauscht', 'sachaufgaben'), ('gesamtheit_statt_bedingung', 'sachaufgaben'), ('randsumme_verwechselt', 'sachaufgaben'), ('achse_abgeschnitten_uebersehen', 'sachaufgaben'), ('absolut_statt_relativ', 'sachaufgaben')) f(slug, familie)
    on f.slug = l.slug and l.familie is not distinct from f.familie
;
