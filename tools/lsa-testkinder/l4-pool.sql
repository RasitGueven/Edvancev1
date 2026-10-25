-- LSA-L4 Teil C: der freigegebene LSA-Pool aus Prod als Fixture (l4-pool-fixture.sql), dazu die Entwürfe aus Lenas
-- Freigabeliste (docs/lsa/freigabeliste-batu-1025.md). NUR LESEND, gegen Prod:
--   (aus dem Repo-Wurzelverzeichnis) ~/bin/dbread -At -f tools/lsa-testkinder/l4-pool.sql > tools/lsa-testkinder/l4-pool-fixture.sql
-- Ausgabe ist SQL: eine Temp-Tabelle zz_l4_pool und je Aufgabe eine Zeile. Keine Inhalte, keine echten ids: die id ist
-- md5 aus Skill, Art (frei/lena) und laufender Nummer. text_hash = die ersten 12 Stellen von md5 des normalisierten
-- Texts (wie lsa_text_schluessel), damit Fast-Duplikate auch in der Fixture gleich sind.
--   lena = false: freigegeben, lsa_im_pool(id, false)
--   lena = true:  Lenas Liste, je Bereich zwei Entwürfe (status draft/rueckfrage, einsatz lsa), zuerst ohne MC
\set ON_ERROR_STOP on
\pset footer off
\pset tuples_only on
with t as (
  select t.id, t.skill_key, t.input_type, t.sondierrang,
         left(md5(btrim(regexp_replace(regexp_replace(lower(coalesce(t.question, '') || ' ' || coalesce(
           (select string_agg(p ->> 'prompt', ' ' order by ord) from jsonb_array_elements(
              case when jsonb_typeof(t.parts) = 'array' then t.parts else '[]' end) with ordinality e(p, ord)), '')),
           '[0-9]+([.,][0-9]+)*', '#', 'g'), '[[:space:]]+', ' ', 'g'))), 12) as text_hash,
         public.lsa_im_pool(t.id, false) as frei
    from tasks t
), frei as (
  select *, false as lena from t where frei
), lena as (
  select x.id, x.skill_key, x.input_type, x.sondierrang, x.text_hash, x.frei, true as lena
    from (select t.*, row_number() over (partition by t.skill_key order by t.input_type = 'MC', t.id) as nr
            from t join tasks tt on tt.id = t.id
           where not t.frei and tt.status in ('draft', 'rueckfrage') and 'lsa' = any (tt.einsatz)
             and t.skill_key in ('term_binom_faktorisieren', 'term_binom_quadratdifferenz', 'term_ausklammern',
                                 'fkt_linear_gleichung', 'fkt_linear_steigung', 'fkt_linear_yabschnitt',
                                 'geo_flaeche_drachen_raute', 'geo_flaeche_term', 'geo_flaeche_trapez',
                                 'geo_winkel_dreieck', 'geo_winkel_thales', 'gleichung_lgs_addition',
                                 'gleichung_lgs_einsetzen', 'gleichung_lgs_grafisch', 'prozent_zins_jahreszins',
                                 'prozent_zins_zinseszins', 'stoch_pfad_summe', 'term_binom_gemischt')) x
   where x.nr <= 2
), alle as (
  select *, row_number() over (partition by skill_key, lena order by sondierrang nulls last, text_hash, id) as lfd
    from (select * from frei union all select * from lena) y
)
select '-- LSA-L4: freigegebener Prod-Pool (' || count(*) filter (where not lena) || ' Aufgaben) und Lenas Liste ('
       || count(*) filter (where lena) || ' Entwürfe in ' || count(distinct skill_key) filter (where lena)
       || ' Bereichen). Erzeugt mit l4-pool.sql (dbread, nur lesend). NUR für eine Wegwerf-DB.' from alle
union all select 'create temp table zz_l4_pool (id uuid primary key, skill_key text, input_type text, sondierrang int, '
                 || 'text_hash text, lena boolean);'
union all select 'insert into zz_l4_pool (id, skill_key, input_type, sondierrang, text_hash, lena) values'
union all select string_agg(format('(%L, %L, %L, %s, %L, %s)', md5('l4:' || coalesce(skill_key, 'ohne_skill') || ':' || lena || ':' || lfd)::uuid,
                                   skill_key, input_type, coalesce(sondierrang::text, 'null'), text_hash, lena::text),
                            E',\n' order by lena, skill_key, lfd) || ';'
  from alle;
