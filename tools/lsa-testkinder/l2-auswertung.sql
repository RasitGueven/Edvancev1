-- LSA-L2 Schritt 2.3/2.4: Auswertung des Laufs, den erzeugen.sql gerade gemacht hat (lsat.sitzungen, lsat.folge).
-- Eingebunden von simulation.sh nach erzeugen.sql, im CI-Neuaufbau. Liest nur (temporäre Tabellen der Sitzung).
--
-- Text-Hash: der normalisierte Text wie lsa_text_schluessel (klein, Zahlen → #, Leerraum zusammengefasst), hier
-- ausgeschrieben, damit „vorher“ ohne die Migration dasselbe rechnet. Mit der Prod-Fixture (l2-fixture.sql) steht
-- der Prod-Hash im Aufgabentext und wird zurückgelesen; sonst die ersten 12 Stellen von md5(normalisierter Text).
--
-- 1. Je Kind: Aufgaben, Dauer, Ende, Themenraum geprüft/vorgesehen (vorgesehen = Knoten mit Aufgabe im Pool),
--    Wiederholungen (a) task_id doppelt, (b) Text-Hash doppelt in der Sitzung, (c) Text-Hash direkt hintereinander,
--    (d) Skill mehr als 2× hintereinander (Zahl der Stellen), (e) Feld mehr als 4× hintereinander.
-- 2. Batu: die Folge (Nr · Minute · Phase · Skill · Feld · Klasse · Gruppe · Text-Hash · Ergebnis) und die Abdeckung
--    je Gruppe, dazu je kommender Klassenarbeit die Voraussetzungen, die im Bericht das Signal bestimmen.
--    Phase ist abgeleitet (die Auswahl schreibt keine Phase): zweite Aufgabe eines Skills = Zweitbeleg; Einstieg =
--    T; Themenraum vor Minute 12 = Tiefe; Rand/Tiefe einer kommenden Klassenarbeit = Vorschau; übriger Themenraum =
--    vertiefen; sonst Ausblick bzw. Rückblick.
create temp table l2_folge as
select k.kind, (current_setting('lsat.sitzungen')::jsonb ->> k.kind)::uuid as sid, f.nr::int, (f.e ->> 't')::uuid as task_id,
       round((f.e ->> 'ms')::numeric / 60000, 1) as minute, t.skill_key, s.klasse_herkunft as klasse,
       public.lsa_themenfeld(t.skill_key) as feld,
       coalesce(translate(substring(t.question from '^ZZ L2 ([0-9a-p]+):'), 'ghijklmnop', '0123456789'),
                left(md5(btrim(regexp_replace(regexp_replace(lower(coalesce(t.question, '') || ' ' || coalesce(
                  (select string_agg(p ->> 'prompt', ' ' order by o) from jsonb_array_elements(
                     case when jsonb_typeof(t.parts) = 'array' then t.parts else '[]' end) with ordinality e(p, o)), '')),
                  '[0-9]+([.,][0-9]+)*', '#', 'g'), '[[:space:]]+', ' ', 'g'))), 12)) as text_hash,
       (select case when bool_or(r.abgabeart = 'weiss_nicht') then 'weiß nicht'
                    when bool_and(r.correct) then 'richtig' else 'falsch' end
          from lsa_responses r where r.session_id = (current_setting('lsat.sitzungen')::jsonb ->> k.kind)::uuid
                                 and r.task_id = (f.e ->> 't')::uuid) as ergebnis
  from (select e.k ->> 'kind' as kind from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) e(k)) k
  cross join lateral jsonb_array_elements(current_setting('lsat.folge')::jsonb -> k.kind) with ordinality f(e, nr)
  join tasks t on t.id = (f.e ->> 't')::uuid
  left join skills s on s.skill_key = t.skill_key;

create temp table l2_lauf as
select f.*,
       f.nr - row_number() over (partition by f.kind, f.skill_key order by f.nr) as skill_lauf,
       f.nr - row_number() over (partition by f.kind, f.feld order by f.nr) as feld_lauf,
       lag(f.text_hash) over (partition by f.kind order by f.nr) as hash_davor
  from l2_folge f;

\echo '## Je Kind'
with kind as (
  select e.ord, e.k ->> 'kind' as kind, (current_setting('lsat.sitzungen')::jsonb ->> (e.k ->> 'kind'))::uuid as sid
    from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) with ordinality e(k, ord)
), raum as (
  select kind.kind, x.sk
    from kind join lsa_sessions ls on ls.id = kind.sid
   cross join lateral (select te.skill_key as sk from thema_einstieg te where te.thema_key = ls.thema_key
                       union select a.skill_key from thema_einstieg te cross join lateral public.lsa_abschluss(te.skill_key) a
                        where te.thema_key = ls.thema_key) x
   where exists (select 1 from tasks t where t.skill_key = x.sk and public.lsa_im_pool(t.id, true))
)
select kind.kind as "Kind",
       (select count(*) from l2_folge f where f.kind = kind.kind) as "Aufgaben",
       to_char(make_interval(secs => (select sum(r.d) from (select distinct r.task_id, r.duration_ms as d
                                       from lsa_responses r where r.session_id = kind.sid) r) / 1000.0), 'MI:SS') as "Dauer",
       case when (select sum(r.d) from (select distinct r.task_id, r.duration_ms as d from lsa_responses r
                                         where r.session_id = kind.sid) r) > 19 * 60000 then 'Zeit'
            when (select count(*) from lsa_ausgegeben a where a.session_id = kind.sid) >= 40 then 'Deckel'
            else 'leer' end as "Ende",
       (select count(*) from raum where raum.kind = kind.kind and exists (
          select 1 from lsa_skill_urteil u where u.session_id = kind.sid and u.skill_key = raum.sk and u.belegt_direkt))
         || '/' || (select count(*) from raum where raum.kind = kind.kind) as "Themenraum",
       (select count(*) - count(distinct f.task_id) from l2_folge f where f.kind = kind.kind) as "(a)",
       (select count(*) - count(distinct f.text_hash) from l2_folge f where f.kind = kind.kind) as "(b)",
       (select count(*) from l2_lauf f where f.kind = kind.kind and f.text_hash = f.hash_davor) as "(c)",
       (select count(*) from (select 1 from l2_lauf f where f.kind = kind.kind and f.skill_key is not null
                               group by f.skill_key, f.skill_lauf having count(*) > 2) x) as "(d)",
       (select count(*) from (select 1 from l2_lauf f where f.kind = kind.kind and f.feld is not null
                               group by f.feld, f.feld_lauf having count(*) > 4) x) as "(e)"
  from kind order by kind.ord;

-- Batu: Gruppen wie in Schritt 1 (l2-gruppen.sql mit seinen Angaben aus kinder.sql).
select (current_setting('lsat.sitzungen')::jsonb ? 'Batu')::int as l2_batu \gset
\if :l2_batu
select set_config('l2.schule', k ->> 'schule', false) as a, set_config('l2.klasse', k ->> 'klasse', false) as b,
       set_config('l2.thema', k ->> 'thema', false) as c,
       set_config('l2.behandelt', (select string_agg(x, ',') from jsonb_array_elements_text(k -> 'behandelt') x), false) as d
  from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) k where k ->> 'kind' = 'Batu' \gset l2x_
\set l2_gruppen `cat tools/lsa-testkinder/l2-gruppen.sql`
create temp table l2_gruppe as :l2_gruppen;

\echo '## Batu: Folge'
select f.nr as "Nr", f.minute as "Min", case
         when exists (select 1 from l2_folge g where g.kind = f.kind and g.skill_key = f.skill_key and g.nr < f.nr)
           then 'Zweitbeleg'
         when exists (select 1 from thema_einstieg te join lsa_sessions ls on ls.thema_key = te.thema_key
                       where ls.id = f.sid and te.skill_key = f.skill_key) then 'T'
         when g.gruppe in ('Thema', 'Grundlage') and f.minute < 12 then 'Tiefe'
         when g.ka is not null and g.gruppe <> 'Ausblick' then 'Vorschau'
         when g.alle_gruppen ~ '(Thema|Grundlage)' then 'vertiefen'
         else coalesce(g.gruppe, '?') end as "Phase",
       f.skill_key as "Skill", f.feld as "Feld", f.klasse as "Kl.",
       case when g.gruppe like 'KA%' then 'Voraussetzung ' || g.gruppe else coalesce(g.gruppe, '–') end as "Gruppe",
       f.text_hash as "Text-Hash", f.ergebnis as "Ergebnis"
  from l2_folge f left join l2_gruppe g on g.skill_key = f.skill_key
 where f.kind = 'Batu' order by f.nr;

\echo '## Batu: Abdeckung je Gruppe (geprüft = direkt belegtes Urteil; vorgesehen = Bereich mit Aufgabe im Pool)'
select g.gruppe as "Gruppe",
       count(*) filter (where u.belegt_direkt) || '/' || count(*) filter (where p.frei) || ' (' || count(*) || ' Bereiche)'
         as "geprüft/vorgesehen",
       coalesce(string_agg(g.skill_key, ', ' order by g.skill_key) filter (where p.frei and not coalesce(u.belegt_direkt, false)), '–')
         as "vorgesehen, nicht geprüft"
  from l2_gruppe g
  left join lsa_skill_urteil u on u.session_id = (current_setting('lsat.sitzungen')::jsonb ->> 'Batu')::uuid
                              and u.skill_key = g.skill_key
  cross join lateral (select exists (select 1 from tasks t where t.skill_key = g.skill_key
                                        and public.lsa_im_pool(t.id, true)) as frei) p
 group by g.gruppe
 order by array_position(array['Thema','KA2','KA3','KA4','Grundlage','Rückblick','Ausblick'], g.gruppe);

\echo '## Batu: Voraussetzungen je kommender Klassenarbeit, die im Bericht das Signal bestimmen'
select 'KA' || ka.r as "KA",
       string_agg(g.skill_key || ' ' || case when u.belegt_direkt then 'direkt'
                                             when u.zustand is not null then 'mit (' || u.zustand || ')'
                                             when not p.frei then 'kein Pool' else '–' end, ', ' order by g.skill_key)
         as "Voraussetzung: geprüft",
       count(*) filter (where u.belegt_direkt) || '/' || count(*) as "direkt"
  from l2_gruppe g cross join lateral unnest(g.ka) ka(r)
  left join lsa_skill_urteil u on u.session_id = (current_setting('lsat.sitzungen')::jsonb ->> 'Batu')::uuid
                              and u.skill_key = g.skill_key
  cross join lateral (select exists (select 1 from tasks t where t.skill_key = g.skill_key
                                        and public.lsa_im_pool(t.id, true)) as frei) p
 where g.alle_gruppen ~ ('KA' || ka.r || ' Bericht')
 group by ka.r order by ka.r;
\endif
