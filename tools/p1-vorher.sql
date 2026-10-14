-- p1-vorher.sql — Ausgangsstand für tools/p1-pruefung.sql (nur Wegwerf-DB, nie Produktion).
-- Läuft nach dem Laden der Prod-Fixture und VOR den P1-Migrationen.
\set ON_ERROR_STOP 1

-- Prüfer-Konto wie in Prod (Admin der Probe) + Gegenproben, die P1 nicht anfassen darf:
--   g1: andere Fertigkeit, echte Beanstandung von Lena-Seite (Notiz 'echt')
--   g2: andere Fertigkeit, Review mit exakt der Probe-Signatur (Kategorie, Notiz, Prüfer, Zeitstempel)
insert into auth.users (id, email) values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'zz_p1_admin@edvance.invalid')
on conflict do nothing;
insert into public.profiles (id, email, role, full_name)
values ('35e4f9ac-d9aa-421c-8ba8-3948b1575f41', 'zz_p1_admin@edvance.invalid', 'admin', 'ZZ P1 Admin')
on conflict (id) do update set role = 'admin';

create schema p1v;
create table p1v.gegenprobe as
  select 'g' || row_number() over (order by t.id) as rolle, t.id
    from public.tasks t
   where t.status = 'draft' and t.skill_key = 'zahl_potenz_gesetze'
   order by t.id limit 2;
do $$ begin
  if (select count(*) from p1v.gegenprobe) <> 2 then raise exception 'vorher: Gegenproben fehlen'; end if;
end $$;
update public.tasks set status = 'beanstandet' where id in (select id from p1v.gegenprobe);
insert into public.task_reviews (task_id, kategorie, notiz, geprueft_von, geprueft_am)
select g.id, 'fehlbild_falsch',
       case g.rolle when 'g1' then 'echt' else 'Probe' end,
       '35e4f9ac-d9aa-421c-8ba8-3948b1575f41',
       case g.rolle when 'g1' then now() else '2026-07-24 06:48:02.349088+00'::timestamptz end
  from p1v.gegenprobe g;

create table p1v.tasks         as select * from public.tasks;
create table p1v.task_solutions as select * from public.task_solutions;
create table p1v.task_reviews  as select * from public.task_reviews;
create table p1v.skill_thema   as select * from public.skill_thema;
create table p1v.protokoll_n   as select count(*) n from public.task_admin_protokoll where aktion = 'pilot_an';
create table p1v.pool          as select t.id from public.tasks t where public.lsa_im_pool(t.id, false);
create table p1v.abschluss     as
  select s.skill_key, array(select a.skill_key from public.lsa_abschluss(s.skill_key) a order by 1) ab
    from public.skills s;
create table p1v.themenraum    as
  select te.thema_key, array_agg(x.sk order by x.sk) raum
    from public.thema_einstieg te
    cross join lateral (select te.skill_key sk union select a.skill_key from public.lsa_abschluss(te.skill_key) a) x
   where te.thema_key = 'reelle_zahlen'
   group by 1;
