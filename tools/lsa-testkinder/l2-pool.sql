-- LSA-L2 Schritt 1: Bereiche und Pool für ein Kind mit Schulplan (docs/lsa/l2-batu-pool.md). Nur lesend.
--
--   (aus dem Repo-Wurzelverzeichnis) dbread -v schule='Friedrich-Wilhelm-Gymnasium' -v klasse=9 -v thema=reelle_zahlen \
--          -v behandelt='brueche,…' -f tools/lsa-testkinder/l2-pool.sql
--
-- Gruppen: siehe l2-gruppen.sql.
-- Pool wie für echte Kinder: lsa_im_pool(id, false). „ohne MC“: input_type <> 'MC'. Entwurf: status draft.
\set ON_ERROR_STOP on
set l2.schule = :'schule'; set l2.klasse = :'klasse'; set l2.thema = :'thema'; set l2.behandelt = :'behandelt';
\set l2_gruppen `cat tools/lsa-testkinder/l2-gruppen.sql`
\echo '## Fahrplan'
select p.klasse, p.position, p.thema_key from schul_themenplan p join schulen sc on sc.id = p.schule_id
 where sc.name = :'schule' and lower(p.fach) = 'mathematik' and p.klasse in (:klasse, :klasse + 1)
 order by p.klasse, p.position;

\echo '## Bereiche und Pool'
with l2_bereich as (
:l2_gruppen
)
select b.gruppe, b.skill_key, b.klasse, b.feld, b.alle_gruppen,
       count(t.id) filter (where public.lsa_im_pool(t.id, false))                          as frei,
       count(t.id) filter (where public.lsa_im_pool(t.id, false) and t.input_type <> 'MC') as frei_ohne_mc,
       coalesce(string_agg(t.sondierrang::text, '/' order by t.sondierrang)
                  filter (where public.lsa_im_pool(t.id, false)), '')                       as sondierrang,
       count(t.id) filter (where t.status = 'draft')                                      as entwurf,
       case when count(t.id) filter (where public.lsa_im_pool(t.id, false)) >= 2
             and count(t.id) filter (where public.lsa_im_pool(t.id, false) and t.input_type <> 'MC') >= 1
            then 'ja' else 'LÜCKE' end                                                     as reicht
  from l2_bereich b left join tasks t on t.skill_key = b.skill_key and 'lsa' = any (t.einsatz)
 group by b.gruppe, b.skill_key, b.klasse, b.feld, b.alle_gruppen
 order by array_position(array['Thema','KA2','KA3','KA4','Grundlage','Rückblick','Ausblick'], b.gruppe), b.klasse desc, b.skill_key;

-- Schritt 1.4: Fast-Duplikate im freien Pool. Text = question und die prompts der parts; normalisiert wie
-- lsa_text_schluessel (Migration *_lsa_l2_wiederholung): klein, Zahlen → #, Leerraum zusammengefasst.
\echo '## Fast-Duplikate je Skill (freier Pool)'
with t as (
  select t.id, t.skill_key, t.input_type,
         btrim(regexp_replace(regexp_replace(lower(coalesce(t.question, '') || ' ' || coalesce(
           (select string_agg(p ->> 'prompt', ' ' order by ord) from jsonb_array_elements(
              case when jsonb_typeof(t.parts) = 'array' then t.parts else '[]' end) with ordinality e(p, ord)), '')),
           '[0-9]+([.,][0-9]+)*', '#', 'g'), '[[:space:]]+', ' ', 'g')) as norm
    from tasks t where public.lsa_im_pool(t.id, false)
)
select skill_key, count(*) as aufgaben, left(md5(norm), 8) as text_hash, left(norm, 70) as text
  from t group by skill_key, norm having count(*) > 1 order by skill_key, count(*) desc;
