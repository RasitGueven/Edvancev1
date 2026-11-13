-- U1 Prüfabfrage nach dem Einspielen (dbread, als Admin über request.jwt.claims; nichts wird geschrieben).
select set_config('request.jwt.claims', '{"sub":"' || (select id from profiles where role = 'admin' order by created_at limit 1) || '","role":"authenticated"}', false) \g /dev/null
select version, name from supabase_migrations.schema_migrations where name like 'iu1%' order by 1;
select (select count(*) from pg_proc where pronamespace = 'public'::regnamespace
          and (proname like 'inhalte%' or proname in ('pruef_ziel_stand', 'pruefziel_ohne'))) funktionen,
       (select count(*) from pg_trigger where tgname like 'inhalte_cache_%') trigger,
       (select count(*) from pruefziele) ziele, (select count(*) from pruefziel_skills) skills,
       (select count(*) filter (where grund = 'zu_schwer') || '/' || count(*) filter (where grund = 'zu_leicht')
          from pruefziel_ausschluss) ausschluss;
select pg_get_functiondef('public.lsa_paket_cache_auffrischen()'::regprocedure) ~ 'lsa_paket_cache where schuljahr is not null' delete_mit_where,
       pg_get_functiondef('public.lsa_paket_cache_trigger()'::regprocedure) ~ 'gen \+ 1 where id' update_mit_where;
select bereich, komp_bereit, komp_teil, komp_offen, fehlende_texte, aufgaben_frei, aufgaben_zu_pruefen, aufgaben_fehlen, zu_leicht, ampel
  from inhalte_lsa_pruefziel('msa_zp10');
select ampel, count(*) from inhalte_lsa_themen() group by 1 order by 1;
select max(alle_zu_pruefen) alle_zu_pruefen_themen from inhalte_lsa_themen();
select abschnitt, count(*) skills, sum(rest) rest, sum(cardinality(task_ids)) ids from pruef_ziel_liste(p_pruefziel => 'msa_zp10') group by 1;
select reihe, sessions, bf_offen, bf_zu_pruefen, vid_gesamt, vid_fehlt, ampel, schulen from inhalte_session_reihen();
select count(*) themen_ohne_reihe from inhalte_themen_ohne_reihe();
