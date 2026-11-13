-- sf1-pruefung.sql — Abnahme S2 in der Wegwerf-DB (tools/sf1-wegwerf-db.sh). Bricht bei einer Abweichung ab.
\set ON_ERROR_STOP 1
create temp table nach_pakete as
  select sj, p.* from unnest(array['2026/27', '2027/28']) sj cross join lateral public.lsa_pakete_roh(sj) p;
create temp table nach_skills as
  select sj, s.* from unnest(array['2026/27', '2027/28']) sj cross join lateral public.lsa_paket_skills_roh(sj) s;
create temp table mit_plan as
  select distinct schule_id from public.schul_themenplan where lower(fach) = 'mathematik';

-- 1 · Regression: Schulen mit eigenem Plan (alle Gymnasien mit Plan) vorher = nachher, Pakete und Skills
\echo '== Regression Schulen mit Plan (Zeilen nur vorher / nur nachher)'
select 'pakete' was,
       (select count(*) from (select * from sf1_vergleich.vorher_pakete where schule_id in (select * from mit_plan)
                              except all select * from nach_pakete where schule_id in (select * from mit_plan)) x) nur_vorher,
       (select count(*) from (select * from nach_pakete where schule_id in (select * from mit_plan)
                              except all select * from sf1_vergleich.vorher_pakete where schule_id in (select * from mit_plan)) x) nur_nachher,
       (select count(*) from sf1_vergleich.vorher_pakete where schule_id in (select * from mit_plan)) zeilen
union all
select 'skills',
       (select count(*) from (select * from sf1_vergleich.vorher_skills where schule_id in (select * from mit_plan)
                              except all select * from nach_skills where schule_id in (select * from mit_plan)) x),
       (select count(*) from (select * from nach_skills where schule_id in (select * from mit_plan)
                              except all select * from sf1_vergleich.vorher_skills where schule_id in (select * from mit_plan)) x),
       (select count(*) from sf1_vergleich.vorher_skills where schule_id in (select * from mit_plan));
do $$
begin
  if exists (select * from sf1_vergleich.vorher_pakete where schule_id in (select * from mit_plan)
             except all select * from nach_pakete where schule_id in (select * from mit_plan))
     or exists (select * from nach_pakete where schule_id in (select * from mit_plan)
                except all select * from sf1_vergleich.vorher_pakete where schule_id in (select * from mit_plan))
     or exists (select * from sf1_vergleich.vorher_skills where schule_id in (select * from mit_plan)
                except all select * from nach_skills where schule_id in (select * from mit_plan))
     or exists (select * from nach_skills where schule_id in (select * from mit_plan)
                except all select * from sf1_vergleich.vorher_skills where schule_id in (select * from mit_plan)) then
    raise exception 'Regression: Pakete oder Skills einer Schule mit Plan haben sich geändert';
  end if;
  -- Vorher hatte keine Schule ohne Plan Pakete; also ist auch insgesamt nur Neues dazugekommen.
  if exists (select 1 from sf1_vergleich.vorher_pakete where schule_id not in (select * from mit_plan)) then
    raise exception 'Vorher gab es schon Pakete an Schulen ohne Plan — Annahme prüfen';
  end if;
end $$;

-- 2 · Prüfabfrage (S2.5): Schulen mit Paketen je Schulform und Quelle, 2026/27
\echo '== Schulen mit Paketen je Schulform und Quelle (2026/27)'
select coalesce(s.schulform, '(leer)') schulform, p.quelle, count(distinct p.schule_id) schulen, count(*) pakete
  from nach_pakete p join public.schulen s on s.id = p.schule_id
 where p.sj = '2026/27' group by 1, 2 order by 1, 2;

\echo '== IGS Holweide und Kerpen: Pakete Klasse 10 (2026/27)'
select s.name, s.ort, count(*) filter (where p.klasse = 10) kl10, string_agg(distinct p.quelle, ',') quelle
  from public.schulen s left join nach_pakete p on p.schule_id = s.id and p.sj = '2026/27'
 where s.name ilike '%Holweide%' or s.ort = 'Kerpen' group by 1, 2 order by 1;
do $$
begin
  if exists (select 1 from public.schulen s where (s.name ilike '%Holweide%' or s.ort = 'Kerpen')
               and not exists (select 1 from nach_pakete p where p.schule_id = s.id and p.sj = '2026/27' and p.klasse = 10)) then
    raise exception 'IGS Holweide oder eine Kerpener Gesamtschule ohne Pakete in Klasse 10';
  end if;
end $$;

-- 3 · Kein gesperrter Skill im Paket einer Schule mit Sperren (Kurs E)
\echo '== Gesperrte Skills in Paketen (muss 0 sein)'
select count(*) gesperrt_im_paket
  from nach_skills k join public.schulen sc on sc.id = k.schule_id
  join public.skill_schulform ss on ss.schulform = sc.schulform and ss.skill_key = k.skill_key
 where not ss.zulaessig and ss.kurs = any (array['alle', 'E'])
   and ss.klp_fassung = any (array['alle', public.klp_fassung(k.sj, k.klasse, sc.schulform)]);

\echo '== hat_einstieg trotz nur gesperrter Einstiege (muss 0 sein) / Positivkontrolle (> 0)'
select (select count(*) from nach_pakete p join public.schulen sc on sc.id = p.schule_id
          where p.hat_einstieg and exists (
                  select 1 from unnest(p.thema_keys) x
                   where not exists (select 1 from public.thema_einstieg te where te.thema_key = x
                                       and public.skill_zulaessig(te.skill_key, sc.schulform, 'E',
                                                                  public.klp_fassung(p.sj, p.klasse, sc.schulform))))) falsch_mit_einstieg,
       (select count(*) from nach_pakete p join public.schulen sc on sc.id = p.schule_id
         cross join unnest(p.thema_keys) x join public.thema_einstieg te on te.thema_key = x
         join public.skill_schulform ss on ss.skill_key = te.skill_key and ss.schulform = sc.schulform
         where not ss.zulaessig and ss.kurs in ('alle', 'E')
           and ss.klp_fassung in ('alle', public.klp_fassung(p.sj, p.klasse, sc.schulform))) gesperrte_einstiege_in_themen;
