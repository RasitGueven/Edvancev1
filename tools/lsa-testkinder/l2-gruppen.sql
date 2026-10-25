-- LSA-L2: die Bereiche, die die LSA für ein Kind mit Schulplan prüfen soll, je Gruppe. Eine Abfrage ohne
-- Semikolon; l2-pool.sql (Prod, nur lesend) und l2-auswertung.sql (Wegwerf-DB) lesen sie mit
-- \set l2_gruppen `cat …` und setzen sie als Unterabfrage ein (:l2_gruppen).
-- Einstellungen (set): l2.schule (Name), l2.klasse, l2.thema, l2.behandelt (Komma-Liste der behandelten Themen).
-- Klasse ≥ / ≤ unten heißt: gegen l2.klasse.
-- Spalten: skill_key, klasse, feld, gruppe (erste Gruppe), alle_gruppen, bericht_signal, ka (Ränge 2..4 der
-- kommenden Klassenarbeiten, für die der Skill Rand, tiefer oder Bericht-Voraussetzung ist).
--
-- Gruppen (ein Skill kann in mehreren stehen; „gruppe“ ist die erste in dieser Reihenfolge):
--   Thema       Themenraum wie lsa_start (Einstieg ∪ lsa_abschluss), Klasse ≥ current_setting('l2.klasse')::int
--   KA2..KA4    je kommendem Plan-Thema (1., 2., 3. nach dem Thema; KA1 ist die geschriebene Arbeit zum Thema):
--               Rand und Tiefe wie die Vorschau in lsa_select_next_core, dazu die Voraussetzungen, die der Bericht
--               für sein Signal nutzt (skill_kante s → g, Heimat-Thema von s = das Thema, g nicht im Thema)
--   Grundlage   Themenraum, Klasse ≤ current_setting('l2.klasse')::int − 1 (Tiefe und Thema vertiefen)
--   Rückblick   Einstiege der behandelten Themen, Klasse ≤ current_setting('l2.klasse')::int
--   Ausblick    wie lsa_ausblick_knoten (Einstiege der nächsten 3 Themen, Klasse ≤ current_setting('l2.klasse')::int + 1)
with recursive
plan as (
  select p.klasse, p.position, p.thema_key
    from schul_themenplan p join schulen sc on sc.id = p.schule_id
   where sc.name = current_setting('l2.schule') and lower(p.fach) = 'mathematik' and p.thema_key is not null
), akt as (
  select min(position) as pos from plan where klasse = current_setting('l2.klasse')::int and thema_key = current_setting('l2.thema')
), kommend as (
  select thema_key, row_number() over (order by position)::int as rang
    from plan, akt where klasse = current_setting('l2.klasse')::int and position > akt.pos and thema_key <> current_setting('l2.thema')
), spaeter as (
  select distinct thema_key from plan, akt
   where thema_key <> current_setting('l2.thema') and ((klasse = current_setting('l2.klasse')::int and position > akt.pos) or klasse = current_setting('l2.klasse')::int + 1)
), r(rang, sk, pfad) as (
  select u.rang, k.voraussetzt_skill_key, array[k.voraussetzt_skill_key]
    from kommend u join skill_thema st on st.thema_key = u.thema_key
    join skill_kante k on k.skill_key = st.skill_key
   where u.rang <= 3
     and not exists (select 1 from skill_thema x where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
  union
  select r.rang, k.voraussetzt_skill_key, r.pfad || k.voraussetzt_skill_key
    from r join skill_thema x on x.skill_key = r.sk and x.thema_key in (select thema_key from spaeter)
    join skill_kante k on k.skill_key = r.sk
   where not k.voraussetzt_skill_key = any (r.pfad)
), rand as (
  select distinct rang, sk from r
   where not exists (select 1 from skill_thema x where x.skill_key = r.sk and x.thema_key in (select thema_key from spaeter))
), tief as (
  select distinct x.rang, a.skill_key as sk
    from rand x cross join lateral public.lsa_abschluss(x.sk) a
   where not exists (select 1 from rand y where y.sk = a.skill_key)
     and not exists (select 1 from skill_thema st where st.skill_key = a.skill_key
                                                    and st.thema_key in (select thema_key from spaeter))
), bericht as (
  select distinct u.rang, k.voraussetzt_skill_key as sk
    from kommend u join skill_thema st on st.thema_key = u.thema_key
    join skill_kante k on k.skill_key = st.skill_key
   where u.rang <= 3
     and not exists (select 1 from skill_thema x where x.skill_key = k.voraussetzt_skill_key and x.thema_key = u.thema_key)
), raum as (
  select te.skill_key as sk from thema_einstieg te where te.thema_key = current_setting('l2.thema')
  union
  select a.skill_key from thema_einstieg te cross join lateral public.lsa_abschluss(te.skill_key) a
   where te.thema_key = current_setting('l2.thema')
), rueck as (
  select distinct te.skill_key as sk from thema_einstieg te join skills s using (skill_key)
   where te.thema_key = any (string_to_array(current_setting('l2.behandelt'), ',')) and s.klasse_herkunft <= current_setting('l2.klasse')::int
), ausblick as (  -- wie lsa_ausblick_knoten: Einstiege der nächsten 3 Themen, Klasse ≤ current_setting('l2.klasse')::int + 1
  select distinct te.skill_key as sk from kommend u join thema_einstieg te on te.thema_key = u.thema_key
    join skills s on s.skill_key = te.skill_key
   where u.rang <= 3 and s.klasse_herkunft <= current_setting('l2.klasse')::int + 1
     and te.skill_key not in (select sk from raum)
     and not exists (select 1 from thema_einstieg b where b.skill_key = te.skill_key
                                                    and b.thema_key = any (string_to_array(current_setting('l2.behandelt'), ',')))
), mitglied as (
  select sk, 1 as ord, 'Thema' as gruppe, null::text as art from raum join skills s on s.skill_key = raum.sk
   where s.klasse_herkunft >= current_setting('l2.klasse')::int
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'Rand' from rand
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'tiefer' from tief
  union all select sk, 1 + rang, 'KA' || (rang + 1), 'Bericht' from bericht
  union all select sk, 5, 'Grundlage', null from raum join skills s on s.skill_key = raum.sk
   where s.klasse_herkunft < current_setting('l2.klasse')::int
  union all select sk, 6, 'Rückblick', null from rueck
  union all select sk, 7, 'Ausblick', null from ausblick
), l2_bereich as (
select m.sk as skill_key, s.klasse_herkunft as klasse, public.lsa_themenfeld(m.sk) as feld,
       (array_agg(m.gruppe order by m.ord))[1] as gruppe,
       string_agg(distinct m.gruppe || coalesce(' ' || m.art, ''), ', ') as alle_gruppen,
       bool_or(m.art = 'Bericht') as bericht_signal,
       array_agg(distinct m.ord) filter (where m.ord between 2 and 4) as ka
  from mitglied m join skills s on s.skill_key = m.sk
 group by m.sk, s.klasse_herkunft
)
select * from l2_bereich
