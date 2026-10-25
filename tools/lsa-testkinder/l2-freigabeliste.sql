-- LSA-L2 Schritt 3D: Freigabeliste für Lena (docs/lsa/freigabeliste-batu-1025.md). Nur lesend, gegen Prod.
--   (aus dem Repo-Wurzelverzeichnis) dbread -v schule=… -v klasse=9 -v thema=reelle_zahlen -v behandelt='…' \
--          -At -f tools/lsa-testkinder/l2-freigabeliste.sql
-- Je Bereich mit Lücke (weniger als 2 freigegebene Aufgaben oder keine ohne MC) eine Markdown-Zeile, sortiert:
-- KA2 vor KA3 vor KA4 vor Grundlage, dann Rückblick und Ausblick; im Block Bericht-Voraussetzung zuerst, dann
-- Klasse absteigend. Entwürfe: status draft oder rueckfrage, mit Kurztitel (title, sonst Anfang der Frage) und Art.
\set ON_ERROR_STOP on
set l2.schule = :'schule'; set l2.klasse = :'klasse'; set l2.thema = :'thema'; set l2.behandelt = :'behandelt';
\set l2_gruppen `cat tools/lsa-testkinder/l2-gruppen.sql`
with b as (:l2_gruppen), z as (
  select b.*,
         (select count(*) from tasks t where t.skill_key = b.skill_key and public.lsa_im_pool(t.id, false)) as frei,
         (select count(*) from tasks t where t.skill_key = b.skill_key and public.lsa_im_pool(t.id, false)
                                         and t.input_type <> 'MC') as frei_ohne_mc
    from b
)
select '| ' || z.gruppe || ' | ' || z.skill_key || case when z.bericht_signal then ' ★' else '' end || ' | ' || z.klasse
       || ' | ' || z.frei || ' | ' || z.frei_ohne_mc || ' | '
       || case when z.frei = 0 then 'keine frei' when z.frei_ohne_mc = 0 then 'nur MC frei' else 'nur 1 frei' end
       || ' | ' || coalesce((select string_agg(coalesce(nullif(btrim(t.title), ''), left(regexp_replace(t.question, '\s+', ' ', 'g'), 50))
                                              || case when t.input_type = 'MC' then ' (MC)' else '' end
                                              || case when t.status = 'rueckfrage' then ' (Rückfrage)' else '' end,
                                              '; ' order by t.input_type = 'MC', t.title)
                               from tasks t where t.skill_key = z.skill_key and 'lsa' = any (t.einsatz)
                                and t.status in ('draft', 'rueckfrage')), '–') || ' |'
  from z
 where z.frei < 2 or z.frei_ohne_mc < 1
 order by array_position(array['KA2','KA3','KA4','Grundlage','Rückblick','Ausblick','Thema'], z.gruppe),
          z.bericht_signal desc, z.klasse desc, z.skill_key;
