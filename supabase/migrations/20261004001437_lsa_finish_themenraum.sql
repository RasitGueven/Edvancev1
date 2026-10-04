-- Themenraum beim LSA-Abschluss sichern (W5-d, Teil 1).
-- Begruendung: docs/report/themenraum-entscheidungen.md.
--
-- #189 gliedert "Wie wir gesucht haben" nach dem Themenraum der Sitzung:
-- Einstiegsknoten des Themas (thema_einstieg) und darunter ihr
-- Voraussetzungsabschluss (lsa_abschluss). Bisher rechnet der Report beides aus
-- den HEUTIGEN Tabellen. Seit K8-K10 aendern sich Kanten und Einstiege laufend;
-- ein alter Report verschoebe sich nachtraeglich.
--
-- 1. public.lsa_themenraum(thema_key) -> { thema_key, einstieg[], darunter[] }
--    darunter = Vereinigung von lsa_abschluss ueber alle Einstiegsknoten, ohne
--    die Einstiege selbst. Beide Listen sortiert, damit derselbe Stand
--    byte-gleich gespeichert wird. Nur intern (lsa_finish, Nachtrag); wie
--    lsa_abschluss nicht fuer anon/authenticated ausfuehrbar.
-- 2. lsa_finish: unveraendert bis auf das neue Feld result_summary.themenraum
--    (+ stand = Abschlusszeitpunkt), nur bei Sitzungen mit thema_key.
--    Keine Aenderung an lsa_grade, Urteilsbuchung oder den bestehenden Feldern.
--    Eine bereits abgeschlossene Sitzung gibt weiter ihr gespeichertes
--    result_summary zurueck — ihren Themenraum traegt der Nachtrag nach.
--
-- Ohne begin/commit: der Runner klammert.

create function public.lsa_themenraum(p_thema_key text)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $$
  with e as (
    select te.skill_key from thema_einstieg te where te.thema_key = p_thema_key
  ),
  d as (
    select distinct a.skill_key
      from e cross join lateral public.lsa_abschluss(e.skill_key) a
     where a.skill_key not in (select skill_key from e)
  )
  select jsonb_build_object(
           'thema_key', p_thema_key,
           'einstieg',  coalesce((select jsonb_agg(skill_key order by skill_key) from e), '[]'::jsonb),
           'darunter',  coalesce((select jsonb_agg(skill_key order by skill_key) from d), '[]'::jsonb))
$$;

revoke execute on function public.lsa_themenraum(text) from public, anon, authenticated;
grant execute on function public.lsa_themenraum(text) to service_role;

create or replace function public.lsa_finish(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
  v_summary jsonb;
begin
  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not public.lsa_may_act_for(v_session.student_id) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if v_session.status = 'completed' then
    return v_session.result_summary;
  end if;

  with answered as (
    -- Die Einheit der Auswertung ist die ZEILE in lsa_responses — also die
    -- Teilaufgabe, wo es eine gibt, sonst das flache Item. Kompetenz und AFB
    -- kommen bei Multi-Part aus der Teilaufgabe (tasks.parts), nicht aus dem Item.
    select r.correct,
           r.abgabeart,
           r.duration_ms,
           r.task_id,
           r.part_nr,
           coalesce(part.competency, t.competency_content, '?') as competency,
           coalesce(part.afb,        t.afb,                'II') as afb,
           t.cluster_id
      from lsa_responses r
      join tasks t on t.id = r.task_id
      left join lateral (
        select p ->> 'competency_content' as competency,
               p ->> 'afb'                as afb
          from jsonb_array_elements(t.parts) as e(p)
         where r.part_nr is not null
           and (p ->> 'nr')::int = r.part_nr
         limit 1
      ) part on true
     where r.session_id = p_session_id
  ),
  by_competency as (
    select competency,
           count(*) filter (where abgabeart = 'antwort')      as total,
           count(*) filter (where correct)                    as correct_count,
           count(*) filter (where abgabeart <> 'antwort')     as unbeantwortet,
           round(avg(duration_ms) filter (where abgabeart = 'antwort')::numeric, 0)
                                                              as avg_duration_ms,
           round(
             count(*) filter (where correct)::numeric
             / nullif(count(*) filter (where abgabeart = 'antwort'), 0), 2
           )                                                  as hit_rate
      from answered
     group by competency
  ),
  by_afb as (
    select afb,
           count(*) filter (where abgabeart = 'antwort')  as total,
           count(*) filter (where correct)                as correct_count,
           count(*) filter (where abgabeart <> 'antwort') as unbeantwortet
      from answered
     group by afb
  ),
  weak_clusters as (
    select cluster_id,
           round(
             count(*) filter (where correct)::numeric
             / nullif(count(*) filter (where abgabeart = 'antwort'), 0), 2
           ) as hit_rate
      from answered
     where cluster_id is not null
     group by cluster_id
    -- Ein Cluster, in dem nichts geprueft wurde, hat keine Quote und wird
    -- nicht als schwach vorgeschlagen. Der Coach sieht ihn ueber
    -- 'unbeantwortet' — geraten wird hier nicht.
    having count(*) filter (where abgabeart = 'antwort') > 0
       and count(*) filter (where correct)::numeric
           / count(*) filter (where abgabeart = 'antwort') < 0.6
  )
  select jsonb_build_object(
           -- 'answered' zaehlt ITEMS (Fortschritt gegen 'planned'),
           -- 'answered_parts' die Datenpunkte. Kein Score, keine Quote.
           'answered',       (select count(distinct task_id) from answered),
           'answered_parts', (select count(*) from answered),
           'planned',        array_length(v_session.item_ids, 1),
           -- Getrennt ausgewiesen, nicht verrechnet: das Kind hat abgegeben,
           -- nur nichts, was sich pruefen laesst.
           'unbeantwortet', jsonb_build_object(
             'weiss_nicht', (select count(*) from answered where abgabeart = 'weiss_nicht'),
             'leer',        (select count(*) from answered where abgabeart = 'leer')
           ),
           'competencies', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'competency',      competency,
                      'total',           total,
                      'correct',         correct_count,
                      'unbeantwortet',   unbeantwortet,
                      'hit_rate',        hit_rate,
                      'avg_duration_ms', avg_duration_ms
                    ) order by hit_rate nulls first)
               from by_competency), '[]'::jsonb),
           'afb', coalesce((
             select jsonb_agg(jsonb_build_object(
                      'afb', afb, 'total', total, 'correct', correct_count,
                      'unbeantwortet', unbeantwortet
                    ) order by afb)
               from by_afb), '[]'::jsonb),
           'proposal', jsonb_build_object(
             'is_proposal', true,
             'applied',     false,
             'focus_cluster_ids', coalesce((
               select jsonb_agg(cluster_id order by hit_rate) from weak_clusters
             ), '[]'::jsonb),
             'clusters', coalesce((
               select jsonb_agg(jsonb_build_object(
                        'cluster_id', w.cluster_id,
                        'name',       c.name,
                        'hit_rate',   w.hit_rate
                      ) order by w.hit_rate)
                 from weak_clusters w
                 join skill_clusters c on c.id = w.cluster_id
             ), '[]'::jsonb),
             'note', 'Vorschlag. Der Lernpfad wird erst durch die Coach-Bestaetigung aktiv (lsa_confirm_focus).'
           )
         )
    into v_summary;

  -- W5-d: den Themenraum der Sitzung festhalten, wie er JETZT gilt. Der
  -- Report liest ihn spaeter von hier statt aus den heutigen Kanten — die
  -- aendern sich mit jedem Inhalts-Lauf, ein alter Report saehe sonst anders
  -- aus als am Tag des Gespraechs. Ohne thema_key kein Feld. Nur ergaenzt:
  -- alle bisherigen Felder entstehen oben unveraendert.
  if v_session.thema_key is not null then
    v_summary := v_summary || jsonb_build_object(
      'themenraum',
      public.lsa_themenraum(v_session.thema_key)
        || jsonb_build_object('stand', to_jsonb(now())));
  end if;

  update lsa_sessions
     set status         = 'completed',
         completed_at   = now(),
         result_summary = v_summary
   where id = p_session_id;

  return v_summary;
end;
$function$;
