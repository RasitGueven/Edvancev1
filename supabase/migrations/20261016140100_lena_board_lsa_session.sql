-- Lena-Board: LSA- und Session-Aufgaben getrennt (feature/lena-board-lsa-session).
--
-- pruef_board() liefert zusätzlich
--   anlaesse      die aktiven pruef_soll-Anlässe des aktuellen Knotens (tasks.skill_key), sortiert, nie null.
--                 Die Zuordnung läuft nur über den Knoten: neue Aufgaben eines Knotens mit Soll-Eintrag landen
--                 ohne weiteren Eingriff im passenden Bereich. tasks.einsatz trennt nicht (alles '{lsa,session}').
--   hat_hinweise  task_solutions.hints (per Check immer ein Array) hat mindestens einen Eintrag.
-- pruef_board_soll(p_anlass) rechnet auf Wunsch nur mit einem Anlass; ohne Argument wie bisher (Höchstwert über
-- alle aktiven Anlässe). Beispiel vorzeichen_add_sub: batu_lsa 3 / batu_session 7 statt überall 7.
--
-- Rückgabetyp bzw. Parameter ändern sich, daher drop + create. Rechte wie vorher: execute nur für authenticated.
-- pruef_board_soll ruft pruef_board() zur Laufzeit (plpgsql, keine pg_depend-Kante); beide werden neu angelegt.

drop function public.pruef_board_soll();
drop function public.pruef_board();

create function public.pruef_board()
returns table (task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text,
               skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean,
               letzte_dauer_sek integer, anlaesse text[], hat_hinweise boolean)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with b as (
    select t.id, t.title, t.status, t.source_ref, t.skill_key sk_jetzt,
           coalesce(a.ausgang ->> 'skill_key', t.skill_key) sk,
           case when a.task_id is not null then (a.ausgang ->> 'sondierrang')::int else t.sondierrang end sr
      from public.tasks t
      left join public.task_pruefung_ausgang a on a.task_id = t.id
     where public.pruef_ausschluss(t.id) is null
       and (t.pruef_pilot or not coalesce((select e.nur_pilot from public.pruef_einstellungen e limit 1), false)))
  select b.id, th.stufe, th.thema_key, th.label, th.sort, b.sk_jetzt, sj.label,
         public.pruef_kurztitel(b.title),
         row_number() over (order by case th.stufe when 'erste' then 1 when 'zweite' then 2 else 3 end,
                                     th.sort nulls last, s.fundament_tiefe, b.sk, b.sr nulls last,
                                     b.source_ref, b.id),
         public.pruef_lena_status(b.status),
         coalesce(jsonb_array_length(lp.aenderungen) > 0, false),
         lp.dauer_sek,
         coalesce((select array_agg(ps.anlass order by ps.anlass) from public.pruef_soll ps
                    where ps.aktiv and ps.skill_key = b.sk_jetzt), '{}'::text[]),
         coalesce((select jsonb_array_length(ts.hints) > 0
                     from public.task_solutions ts where ts.task_id = b.id), false)
    from b
    join public.skills s on s.skill_key = b.sk
    join public.skill_thema st on st.skill_key = b.sk
    join public.themen th on th.thema_key = st.thema_key
    left join public.skills sj on sj.skill_key = b.sk_jetzt
    left join lateral (select p.aenderungen, p.dauer_sek from public.task_pruefungen p
                        where p.task_id = b.id order by p.geprueft_am desc limit 1) lp on true;
end $$;

revoke all on function public.pruef_board() from public, anon, authenticated;
grant execute on function public.pruef_board() to authenticated;

create function public.pruef_board_soll(p_anlass text default null)
returns table (skill_key text, skill_label text, thema_key text, thema_label text, thema_sort integer,
               stufe text, sort integer, anlaesse text[], soll integer, min_ohne_mc integer, im_board integer,
               gezaehlt integer, gezaehlt_ohne_mc integer, rest integer, reicht boolean)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
begin
  if not public.darf_pruefen() then
    raise exception 'pruef_board_soll: kein Pruefrecht' using errcode = '42501';
  end if;
  return query
  with s as (
    select p.skill_key sk, max(p.soll) so, max(p.min_ohne_mc) mo, min(p.sort) srt,
           array_agg(p.anlass order by p.sort, p.anlass) an
      from public.pruef_soll p
     where p.aktiv and (p_anlass is null or p.anlass = p_anlass)
     group by p.skill_key),
  b as (
    select z.skill_key sk, count(*)::int n,
           count(*) filter (where z.lena_status in ('passt', 'freigegeben'))::int g,
           count(*) filter (where z.lena_status in ('passt', 'freigegeben')
                              and t.input_type is distinct from 'MC')::int g_ohne
      from public.pruef_board() z
      join public.tasks t on t.id = z.task_id
     group by z.skill_key)
  select s.sk, k.label, th.thema_key, th.label, th.sort, th.stufe, s.srt, s.an, s.so, s.mo,
         coalesce(b.n, 0), coalesce(b.g, 0), coalesce(b.g_ohne, 0),
         greatest(s.so - coalesce(b.g, 0), s.mo - coalesce(b.g_ohne, 0), 0),
         coalesce(b.g, 0) >= s.so and coalesce(b.g_ohne, 0) >= s.mo
    from s
    join public.skills k on k.skill_key = s.sk
    left join public.skill_thema st on st.skill_key = s.sk
    left join public.themen th on th.thema_key = st.thema_key
    left join b on b.sk = s.sk
   order by s.srt, s.sk;
end $$;

revoke all on function public.pruef_board_soll(text) from public, anon, authenticated;
grant execute on function public.pruef_board_soll(text) to authenticated;
