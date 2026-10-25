-- LSA-L3 Schritt 1.3/3: Auswertung des Laufs, den erzeugen.sql gerade gemacht hat. Eingebunden von simulation.sh
-- (AUSWERTUNG="l3-auswertung.sql") nach l2-auswertung.sql, die l2_folge und l2_lauf anlegt. Liest nur.
--
-- Gruppen je Kind aus l3-gruppen.sql (Thema, KA2–KA4 = Voraussetzungen der nächsten drei Klassenarbeiten,
-- Grundlage, Rückblick, Ausblick). Eine Aufgabe zählt zur ersten Gruppe ihres Skills; Minuten = Antwortdauer.
-- KA-Voraussetzungen wie in L2: die, die im Bericht das Signal bestimmen (je KA gezählt, ein Skill kann in zwei
-- KA stehen). prüfbar = mit Aufgabe im Pool und Klasse ≤ Kind; mitbelegt zählt nicht als direkt.
\set l3_gruppen `cat tools/lsa-testkinder/l3-gruppen.sql`
select set_config('l3.q', :'l3_gruppen', false) as l3q \gset
create temp table l3_gruppe (kind text, skill_key text, klasse int, feld text, gruppe text, alle_gruppen text, ka int[],
                             bericht_ka int[], kommend text);
do $$
declare k jsonb;
begin
  for k in select * from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) loop
    perform set_config('l3.schule', coalesce(k ->> 'schule', ''), false), set_config('l3.klasse', k ->> 'klasse', false),
            set_config('l3.thema', k ->> 'thema', false),
            set_config('l3.behandelt', (select string_agg(x, ',') from jsonb_array_elements_text(k -> 'behandelt') x), false);
    execute format('insert into l3_gruppe select %L, x.* from (%s) x', k ->> 'kind', current_setting('l3.q'));
  end loop;
end $$;

create temp table l3_item as
select f.kind, f.sid, f.nr, f.minute, f.skill_key, f.klasse, f.feld, f.ergebnis, f.task_id,
       (select r.duration_ms from lsa_responses r where r.session_id = f.sid and r.task_id = f.task_id limit 1) as ms,
       coalesce(g.gruppe, '–') as gruppe, g.alle_gruppen,
       (select (e.k ->> 'klasse')::int from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) e(k)
         where e.k ->> 'kind' = f.kind) as kind_klasse,
       to_jsonb(ls) ->> 'ka_modus' as modus
  from l2_folge f join lsa_sessions ls on ls.id = f.sid
  left join l3_gruppe g on g.kind = f.kind and g.skill_key = f.skill_key;

\echo '## L3: Kennzahlen je Kind (Aufgaben/Minuten je Gruppe; KA = Bericht-Voraussetzungen KA2–KA4 direkt geprüft)'
with kind as (
  select e.ord, e.k ->> 'kind' as kind, (e.k ->> 'klasse')::int as kl,
         (current_setting('lsat.sitzungen')::jsonb ->> (e.k ->> 'kind'))::uuid as sid
    from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) with ordinality e(k, ord)
), ka as (
  select kind.kind, g.skill_key, r.rang, u.belegt_direkt as direkt, u.zustand,
         exists (select 1 from tasks t where t.skill_key = g.skill_key and public.lsa_im_pool(t.id, true)) as pool,
         g.klasse <= kind.kl as klasse_ok
    from kind join l3_gruppe g on g.kind = kind.kind cross join lateral unnest(g.bericht_ka) r(rang)
    left join lsa_skill_urteil u on u.session_id = kind.sid and u.skill_key = g.skill_key
), raum as (
  select kind.kind, g.skill_key, g.gruppe, u.belegt_direkt as direkt,
         exists (select 1 from tasks t where t.skill_key = g.skill_key and public.lsa_im_pool(t.id, true)) as pool
    from kind join l3_gruppe g on g.kind = kind.kind and g.alle_gruppen ~ '(Thema|Grundlage)'
    left join lsa_skill_urteil u on u.session_id = kind.sid and u.skill_key = g.skill_key
)
select kind.kind as "Kind", coalesce(max(i.modus), '–') as "Modus", count(i.nr) as "Aufg.",
       to_char(make_interval(secs => coalesce(sum(i.ms), 0) / 1000.0), 'MI:SS') as "Dauer",
       case when coalesce(sum(i.ms), 0) > 19 * 60000 then 'Zeit' when count(i.nr) >= 40 then 'Deckel' else 'leer' end as "Ende",
       count(i.nr) filter (where i.gruppe = 'Thema') || ' · ' ||
         to_char(make_interval(secs => coalesce(sum(i.ms) filter (where i.gruppe = 'Thema'), 0) / 1000.0), 'MI:SS') as "Thema",
       count(i.nr) filter (where i.gruppe ~ '^KA') || ' · ' ||
         to_char(make_interval(secs => coalesce(sum(i.ms) filter (where i.gruppe ~ '^KA'), 0) / 1000.0), 'MI:SS') as "KA2–4",
       count(i.nr) filter (where i.gruppe = 'Grundlage') || ' · ' ||
         to_char(make_interval(secs => coalesce(sum(i.ms) filter (where i.gruppe = 'Grundlage'), 0) / 1000.0), 'MI:SS') as "Grundl.",
       count(i.nr) filter (where i.gruppe = 'Rückblick') || ' · ' ||
         to_char(make_interval(secs => coalesce(sum(i.ms) filter (where i.gruppe = 'Rückblick'), 0) / 1000.0), 'MI:SS') as "Rückbl.",
       count(i.nr) filter (where i.gruppe not in ('Thema', 'Grundlage', 'Rückblick') and i.gruppe !~ '^KA') as "sonst",
       (select count(*) filter (where direkt) || '/' || count(*) || ' (prüfbar ' || count(*) filter (where pool and klasse_ok) || ')'
          from ka where ka.kind = kind.kind) as "KA direkt",
       (select string_agg('KA' || r || ' ' || d || '/' || n, ', ' order by r)
          from (select rang as r, count(*) filter (where direkt) as d, count(*) as n from ka where ka.kind = kind.kind
                group by rang) x) as "je KA",
       (select count(*) filter (where direkt) || '/' || count(*) filter (where pool) from raum where raum.kind = kind.kind)
         as "Themenraum",
       (select count(*) filter (where direkt) from raum where raum.kind = kind.kind and raum.gruppe = 'Thema') as "Thema dir.",
       count(i.nr) filter (where i.alle_gruppen ~ 'Ausblick') as "Ausblick",
       count(i.nr) filter (where i.klasse > kind.kl) as "Kl.>",
       (select count(*) - count(distinct f.text_hash) from l2_folge f where f.kind = kind.kind) as "(b)",
       (select count(*) from l2_lauf f where f.kind = kind.kind and f.text_hash = f.hash_davor) as "(c)",
       (select count(*) from (select 1 from l2_lauf f where f.kind = kind.kind and f.skill_key is not null
                               group by f.skill_key, f.skill_lauf having count(*) > 2) x) as "(d)",
       left(md5(coalesce(string_agg(i.task_id::text || i.ergebnis, ',' order by i.nr), '')), 8) as "Folge-md5"
  from kind left join l3_item i on i.kind = kind.kind
 group by kind.ord, kind.kind, kind.kl order by kind.ord;

\echo '## L3: kommende Klassenarbeiten je Kind (KA2, KA3, KA4)'
select distinct on (kind) kind as "Kind", kommend as "KA2 · KA3 · KA4" from l3_gruppe order by kind;

\echo '## L3: Folgen der L3-Kinder'
select i.kind as "Kind", i.nr as "Nr", i.minute as "Min", case
         when exists (select 1 from l3_item j where j.kind = i.kind and j.skill_key = i.skill_key and j.nr < i.nr)
           then 'Zweitbeleg'
         when exists (select 1 from thema_einstieg te join lsa_sessions ls on ls.thema_key = te.thema_key
                       where ls.id = i.sid and te.skill_key = i.skill_key) then 'T'
         when i.alle_gruppen ~ 'KA. (Rand|tiefer)' and (i.modus is distinct from 'vorschau_zuerst' or i.minute < 13)
           then 'Vorschau'
         when i.alle_gruppen ~ '(Thema|Grundlage)' then 'Tiefe'
         when i.alle_gruppen ~ 'KA' then 'Vorschau'
         else coalesce(i.gruppe, '?') end as "Phase",
       i.skill_key as "Skill", i.feld as "Feld", i.klasse as "Kl.",
       case when i.gruppe like 'KA%' then 'Voraussetzung ' || i.gruppe else i.gruppe end as "Gruppe",
       i.ergebnis as "Ergebnis"
  from l3_item i
 where i.kind in ('BatuB', 'BatuG', 'BatuN4', 'BatuS2', 'Mia', 'MiaB')
 order by array_position(array['BatuB', 'BatuG', 'BatuN4', 'BatuS2', 'Mia', 'MiaB'], i.kind), i.nr;

\echo '## L3: Bericht-Voraussetzungen je KA (L3-Kinder und Batu)'
select g.kind as "Kind", 'KA' || r.rang as "KA",
       string_agg(g.skill_key || ' ' || case when u.belegt_direkt then 'direkt'
                                             when u.zustand is not null then 'mit (' || u.zustand || ')'
                                             when g.klasse > (select (e.k ->> 'klasse')::int from jsonb_array_elements(
                                                    current_setting('lsat.kinder')::jsonb) e(k) where e.k ->> 'kind' = g.kind)
                                               then 'über Klasse'
                                             when not exists (select 1 from tasks t where t.skill_key = g.skill_key
                                                                 and public.lsa_im_pool(t.id, true)) then 'kein Pool'
                                             else '–' end, ', ' order by g.skill_key) as "Voraussetzung: Stand"
  from l3_gruppe g cross join lateral unnest(g.bericht_ka) r(rang)
  left join lsa_skill_urteil u on u.session_id = (current_setting('lsat.sitzungen')::jsonb ->> g.kind)::uuid
                              and u.skill_key = g.skill_key
 where g.kind in ('Batu', 'BatuB', 'BatuG', 'BatuN4', 'BatuS2', 'Mia', 'MiaB')
 group by g.kind, r.rang
 order by array_position(array['Batu', 'BatuB', 'BatuG', 'BatuN4', 'BatuS2', 'Mia', 'MiaB'], g.kind), r.rang;
