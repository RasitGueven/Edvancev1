-- P2 · M3: pruef_board_soll() — Sollzahlen und Lenas Fortschritt je Knoten.
--
-- Eigene Funktion statt neuer Spalten an pruef_board(): pruef_board liefert eine Zeile je Aufgabe, die Sollwerte
-- gehören zum Knoten; bestehende Aufrufer bleiben unberührt. Gerechnet wird auf pruef_board(), also genau auf den
-- Aufgaben, die Lena sieht (Pilot, nicht ausgeschlossen), gruppiert nach dem aktuellen Knoten der Aufgabe.
--
-- Je Knoten mit mindestens einem aktiven pruef_soll-Eintrag:
--   soll / min_ohne_mc  Höchstwert über die aktiven Anlässe (z. B. vorzeichen_add_sub: batu_session 7 > batu_lsa 3),
--   sort                kleinster sort-Wert der aktiven Anlässe,
--   gezaehlt            Aufgaben mit lena_status passt (review) oder freigegeben (ready),
--   gezaehlt_ohne_mc    davon mit input_type <> 'MC',
--   rest                was noch fehlt: greatest(soll - gezaehlt, min_ohne_mc - gezaehlt_ohne_mc, 0),
--   reicht              gezaehlt >= soll und gezaehlt_ohne_mc >= min_ohne_mc.
-- unsicher (rueckfrage) und passt_nicht (beanstandet) zählen nicht.
-- Thema und Stufe kommen aus skill_thema/themen des Knotens (wie pruef_board für den Ausgangsknoten).

create function public.pruef_board_soll()
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
     where p.aktiv
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

revoke all on function public.pruef_board_soll() from public, anon, authenticated;
grant execute on function public.pruef_board_soll() to authenticated;
