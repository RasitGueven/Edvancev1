-- Pruefquery zu 20261001123347_substrat_k8_zins.sql — rein lesend.
-- Erwartung: jede Zeile ok = t.

with
knoten as (
  select count(*) n from skills
   where skill_key like 'prozent_zins_%' and klasse_herkunft = 7 and fach = 'mathematik'
     and (skill_key, fundament_tiefe) in (('prozent_zins_jahreszins', 7), ('prozent_zins_teilzins', 8),
                                          ('prozent_zins_rueckrechnung', 8), ('prozent_zins_zinseszins', 9))),
kanten as (
  select count(*) n,
         count(*) filter (where sv.fundament_tiefe >= s.fundament_tiefe) guard_verletzt
    from skill_kante k join skills s using (skill_key)
    join skills sv on sv.skill_key = k.voraussetzt_skill_key
   where k.skill_key like 'prozent_zins_%'),
fehlbilder as (
  select count(*) n,
         count(*) filter (where freigegeben_am is null and nullif(btrim(klartext), '') is not null
                            and familie in (select schluessel from fehlbild_familien)) sauber
    from fehlbild_labels
   where slug in ('zeitfaktor_vergessen', 'zinszeit_falsch_umgerechnet', 'prozente_addiert',
                  'wachstumsfaktor_falsch', 'zu_frueh_gerundet')),
wiederverwendet as (
  select count(*) n from fehlbild_labels
   where slug in ('dezimalverschiebung', 'nur_prozentwert', 'falsche_groesse_beantwortet',
                  'multipliziert_statt_dividiert', 'faktor_100_vergessen', 'bezug_vertauscht'))
select 'vier Knoten, Tiefen 7/8/8/9, klasse_herkunft 7' pruefung, (select n from knoten) = 4 ok
union all select 'elf Kanten', (select n from kanten) = 11
union all select 'keine Kante verletzt den Tiefen-Guard', (select guard_verletzt from kanten) = 0
union all select 'fuenf neue Fehlbilder, Klartext + Familie, nicht freigegeben', (select sauber from fehlbilder) = 5
union all select 'sechs wiederverwendete Slugs vorhanden', (select n from wiederverwendet) = 6
union all select 'keine Aufgaben an den neuen Knoten', not exists (select 1 from tasks where skill_key like 'prozent_zins_%')
union all select 'Tiefen-Check erlaubt 9', exists (select 1 from pg_constraint
  where conname = 'skills_fundament_tiefe_check' and pg_get_constraintdef(oid) ~ '<= 12');

-- Kantenliste zur Sichtkontrolle
select k.skill_key, s.fundament_tiefe, k.voraussetzt_skill_key, sv.fundament_tiefe tiefe_voraussetzung
  from skill_kante k join skills s using (skill_key) join skills sv on sv.skill_key = k.voraussetzt_skill_key
 where k.skill_key like 'prozent_zins_%' order by s.fundament_tiefe, k.skill_key, k.voraussetzt_skill_key;
