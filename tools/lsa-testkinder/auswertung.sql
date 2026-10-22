-- LSA-V2: Kennzahlen je Kind für den Lauf, den erzeugen.sql gerade gemacht hat (lsat.sitzungen).
-- Eingebunden von simulation.sh nach erzeugen.sql; liest nur. Braucht lsa_ausblick_knoten (Migration
-- 20261022131358_lsa_v2_ausblick; für den Stand davor spielt simulation.sh nur diese Hilfsfunktionen nach dem Lauf ein).
--
--   Aufgaben     ausgegebene Aufgaben (lsa_ausgegeben)
--   Dauer        Summe der Antwortdauern (die Uhr des Skripts)
--   Ende         Zeit (über 19 Minuten), Deckel (40 ausgegeben) oder leer (die Auswahl lieferte nichts mehr)
--   Ausblick     ausgegebene Skills, die Ausblick-Knoten der Sitzung sind; sicher = davon traegt
--   tiefste Kl.  kleinste Herkunftsklasse unter den ausgegebenen Skills
--   Zweitbelege  Urteile mit zwei Proben
with kind as (
  select e.ord, e.k ->> 'kind' as kind, (e.k ->> 'klasse')::int as klasse,
         (current_setting('lsat.sitzungen')::jsonb ->> (e.k ->> 'kind'))::uuid as sid
    from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) with ordinality e(k, ord)
), z as (
  select kind.*,
         (select count(*) from lsa_ausgegeben a where a.session_id = kind.sid) as aufgaben,
         (select sum(r.d) from (select distinct r.task_id, r.duration_ms as d from lsa_responses r
                                 where r.session_id = kind.sid) r) as dauer_ms,
         public.lsa_ausblick_knoten(kind.sid) as ausblick
    from kind
)
select z.kind                                                          as "Kind",
       z.klasse                                                        as "Kl.",
       z.aufgaben                                                      as "Aufgaben",
       to_char(make_interval(secs => z.dauer_ms / 1000.0), 'MI:SS')    as "Dauer",
       case when z.dauer_ms > 19 * 60000 then 'Zeit'
            when z.aufgaben >= 40 then 'Deckel' else 'leer' end        as "Ende",
       (select count(distinct t.skill_key) from lsa_ausgegeben a join tasks t on t.id = a.task_id
         where a.session_id = z.sid and t.skill_key = any (z.ausblick)) as "Ausblick",
       (select count(*) from lsa_skill_urteil u
         where u.session_id = z.sid and u.belegt_direkt and u.zustand = 'traegt'
           and u.skill_key = any (z.ausblick))                         as "davon sicher",
       (select min(s.klasse_herkunft) from lsa_ausgegeben a join tasks t on t.id = a.task_id
          join skills s on s.skill_key = t.skill_key where a.session_id = z.sid) as "tiefste Kl.",
       (select count(*) from lsa_skill_urteil u where u.session_id = z.sid and u.proben_anzahl = 2) as "Zweitbelege"
  from z
 order by z.ord;

-- Die Ausblick-Knoten je Kind in der Reihenfolge der Ausgabe, mit Urteil.
select z.kind as "Kind",
       string_agg(x.sk || ' ' || coalesce(u.zustand, '–'), ', ' order by x.nr) as "Ausblick (Reihenfolge, Urteil)"
  from (select e.ord, e.k ->> 'kind' as kind,
               (current_setting('lsat.sitzungen')::jsonb ->> (e.k ->> 'kind'))::uuid as sid
          from jsonb_array_elements(current_setting('lsat.kinder')::jsonb) with ordinality e(k, ord)) z
  cross join lateral unnest(public.lsa_ausblick_knoten(z.sid)) with ordinality x(sk, nr)
  join lsa_skill_urteil u on u.session_id = z.sid and u.skill_key = x.sk and u.belegt_direkt
 group by z.ord, z.kind
 order by z.ord;
