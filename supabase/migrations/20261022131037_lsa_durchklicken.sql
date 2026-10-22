-- LSA-R2: durchgeklickte LSA erkennen (Bauauftrag docs/lsa/Bauauftrag-LSA-R2.md,
-- Auswertung docs/lsa/durchklicken-auswertung.md, festgelegt von Rasit am 22.10.2026).
--
-- 1. public.lsa_durchklick_stand(session) -> jsonb. Die Schwellen stehen nur hier, als
--    Konstanten oben in der Funktion. Zaehlweise: eine Aufgabe = eine Abgabe (Multi-Part
--    zaehlt einmal), Reihenfolge nach der Abgabezeit.
--      schnell        = duration_ms < c_schnell_ms
--      schnell falsch = schnell und mindestens ein Teil correct = false;
--                       „Weiss ich nicht“ ist nie falsch und unterbricht jede Folge
--      nicht auswertbar = Folge schnell falsch >= c_folge
--                         oder (Antworten >= c_min_antworten und Anteil >= c_anteil)
--      folge_schnell_aktuell = schnelle Abgaben am Ende, richtig oder falsch, ohne WN
--    Ausfuehrbar fuer admin und coach (lsa_may_act_for, ohne das Kind selbst) und intern
--    aus lsa_finish und platz_submit (Flag edvance.lsa_intern, transaktionslokal, wie
--    edvance.allow_provisional). Nicht fuer anon, nicht fuer Schueler.
-- 2. lsa_sessions: auswertbar (Default true, kein Backfill), nicht_auswertbar_grund,
--    hinweis_tempo_am. Die bestehenden Policies sind zeilenweise und decken die Spalten ab
--    (admin alles, coach und Eltern lesen); geschrieben wird nur ueber die Funktionen.
-- 3. lsa_finish: unveraendert bis auf auswertbar/nicht_auswertbar_grund vor dem Setzen von
--    completed und den neuen Schluessel result_summary.durchklick.
-- 4. platz_submit: unveraendert bis auf hinweis_tempo (boolean) in der Antwort. true genau
--    einmal je Sitzung: sobald folge_schnell_aktuell >= c_hinweis_folge und hinweis_tempo_am
--    noch leer war; im selben Aufruf wird hinweis_tempo_am gesetzt. ok und next wie bisher.
--
-- Nicht angefasst: lsa_select_next_core, lsa_urteil_buchen_core, lsa_submit (LSA-V2).
-- Ohne begin/commit: der Runner klammert.

alter table public.lsa_sessions
  add column auswertbar boolean not null default true,
  add column nicht_auswertbar_grund jsonb,
  add column hinweis_tempo_am timestamptz;

comment on column public.lsa_sessions.auswertbar is
  'LSA-R2: false, wenn lsa_finish die Sitzung als durchgeklickt erkannt hat (lsa_durchklick_stand). Alte Sitzungen bleiben true.';
comment on column public.lsa_sessions.nicht_auswertbar_grund is
  'LSA-R2: der Stand aus lsa_durchklick_stand beim Abschluss, nur bei auswertbar = false.';
comment on column public.lsa_sessions.hinweis_tempo_am is
  'LSA-R2: wann platz_submit dem Kind den Tempo-Hinweis gemeldet hat (hoechstens einmal je Sitzung).';

create function public.lsa_durchklick_stand(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  -- Die Schwellen (Rasit, 22.10.2026). Nur hier.
  c_schnell_ms    constant integer := 5000;
  c_folge         constant integer := 5;
  c_anteil        constant numeric := 0.40;
  c_min_antworten constant integer := 10;
  c_hinweis_folge constant integer := 3;

  v_student        uuid;
  a                record;
  v_antworten      integer := 0;
  v_sf             integer := 0;
  v_folge_sf       integer := 0;
  v_folge_sf_max   integer := 0;
  v_folge_schnell  integer := 0;
  v_folge          boolean;
  v_anteil         boolean;
begin
  select student_id into v_student from lsa_sessions where id = p_session_id;
  if v_student is null then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  if not (coalesce(current_setting('edvance.lsa_intern', true), '') = '1'
          or (coalesce(public.get_my_role(), '') in ('admin', 'coach')
              and public.lsa_may_act_for(v_student))) then
    raise exception 'LSA: kein Zugriff auf diese Session' using errcode = '42501';
  end if;

  -- Je Aufgabe eine Abgabe. duration_ms steht in allen Teilzeilen gleich. Innerhalb einer
  -- Transaktion tragen alle Zeilen dieselbe Zeit; dann entscheidet task_id (nur in Tests
  -- und Generatoren, jede echte Abgabe ist eine eigene Transaktion).
  for a in
    select bool_and(r.abgabeart = 'weiss_nicht')          as wn,
           coalesce(bool_or(r.correct = false), false)    as falsch,
           coalesce(max(r.duration_ms) < c_schnell_ms, false) as schnell
      from lsa_responses r
     where r.session_id = p_session_id
     group by r.task_id
     order by min(r.created_at), r.task_id
  loop
    v_antworten := v_antworten + 1;

    if a.schnell and a.falsch then
      v_sf := v_sf + 1;
      v_folge_sf := v_folge_sf + 1;
      v_folge_sf_max := greatest(v_folge_sf_max, v_folge_sf);
    else
      v_folge_sf := 0;
    end if;

    -- Fuer den Hinweis zaehlt nur das Tempo, nicht richtig/falsch (CLAUDE.md §6).
    if a.schnell and not a.wn then
      v_folge_schnell := v_folge_schnell + 1;
    else
      v_folge_schnell := 0;
    end if;
  end loop;

  v_folge  := v_folge_sf_max >= c_folge;
  v_anteil := v_antworten >= c_min_antworten and v_sf >= c_anteil * v_antworten;

  return jsonb_build_object(
    'antworten',                v_antworten,
    'schnell_falsch',           v_sf,
    'anteil_schnell_falsch',    case when v_antworten = 0 then 0
                                     else round(v_sf::numeric / v_antworten, 2) end,
    'folge_schnell_falsch_max', v_folge_sf_max,
    'folge_schnell_aktuell',    v_folge_schnell,
    'nicht_auswertbar',         v_folge or v_anteil,
    'grund',                    case when v_folge then 'folge' when v_anteil then 'anteil' end,
    'schwellen', jsonb_build_object(
      'schnell_ms',    c_schnell_ms,
      'folge',         c_folge,
      'anteil',        c_anteil,
      'min_antworten', c_min_antworten,
      'hinweis_folge', c_hinweis_folge)
  );
end;
$$;

revoke execute on function public.lsa_durchklick_stand(uuid) from public, anon;
grant execute on function public.lsa_durchklick_stand(uuid) to authenticated, service_role;

create or replace function public.lsa_finish(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_session lsa_sessions;
  v_summary jsonb;
  v_stand   jsonb;
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

  -- LSA-R2: durchgeklickt? Dieselben Kennzahlen kommen in result_summary.durchklick und,
  -- wenn nicht auswertbar, als Grund an die Sitzung. Gesetzt in DERSELBEN Anweisung wie
  -- completed, also bevor der Abschluss sichtbar wird.
  perform set_config('edvance.lsa_intern', '1', true);
  v_stand := public.lsa_durchklick_stand(p_session_id);
  perform set_config('edvance.lsa_intern', '', true);
  v_summary := v_summary || jsonb_build_object('durchklick', v_stand);

  update lsa_sessions
     set auswertbar             = not (v_stand ->> 'nicht_auswertbar')::boolean,
         nicht_auswertbar_grund = case when (v_stand ->> 'nicht_auswertbar')::boolean
                                       then v_stand end,
         status                 = 'completed',
         completed_at           = now(),
         result_summary         = v_summary
   where id = p_session_id;

  return v_summary;
end;
$$;

create or replace function public.platz_submit(p_task_id uuid, p_response jsonb, p_duration_ms integer default null,
                                             p_jetzt timestamptz default now())
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_a       platz_assignments;
  v_session lsa_sessions;
  v_open    uuid;
  v_claims  text;
  v_result  jsonb;
  v_stand   jsonb;
  v_hinweis boolean := false;
begin
  if not exists (select 1 from platz_devices where profile_id = auth.uid()) then
    raise exception 'platz_submit: kein Platz-Konto' using errcode = '42501';
  end if;

  v_a := public.platz_current_assignment();
  if v_a.id is null then
    raise exception 'platz_submit: keine aktive Zuweisung' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = v_a.session_id;
  if not found or v_session.status <> 'in_progress' then
    raise exception 'platz_submit: keine aktive Session' using errcode = '42501';
  end if;

  -- Aktuell offenes Item — Quelle je nach Modus.
  if v_session.modus = 'adaptiv' then
    select a.task_id into v_open
      from lsa_ausgegeben a
     where a.session_id = v_session.id
       and not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = a.task_id)
     order by a.ausgegeben_am
     limit 1;
  else
    select i.id into v_open
      from unnest(v_session.item_ids) with ordinality as i(id, ord)
     where not exists (select 1 from lsa_responses r
                        where r.session_id = v_session.id and r.task_id = i.id)
     order by i.ord
     limit 1;
  end if;

  if v_open is null or v_open <> p_task_id then
    raise exception 'platz_submit: nicht das aktuell offene Item' using errcode = 'P0001';
  end if;

  -- Durchreichen an die UNVERAENDERTE lsa_submit mit der Auftrags-Identitaet.
  -- lsa_submit verzweigt intern nach modus (A16): adaptiv gated ueber
  -- lsa_ausgegeben, schreibt die Antwort, bucht das Urteil und traegt die
  -- naechste Aufgabe selbst ein. p_jetzt steuert das Zeit-Ende in
  -- lsa_select_next.
  v_claims := current_setting('request.jwt.claims', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_a.created_by, 'role', 'authenticated')::text, true);

  v_result := public.lsa_submit(v_session.id, p_task_id, p_response, p_duration_ms, p_jetzt);

  perform set_config('request.jwt.claims', coalesce(v_claims, ''), true);

  -- LSA-R2: ruhiger Tempo-Hinweis, hoechstens einmal je Sitzung. Nur Tempo, kein
  -- richtig/falsch; das Kind erfaehrt nichts ueber seine Antworten. Das Update mit
  -- „is null“ setzt den Zeitpunkt genau einmal, auch bei zwei Aufrufen zugleich.
  perform set_config('edvance.lsa_intern', '1', true);
  v_stand := public.lsa_durchklick_stand(v_session.id);
  perform set_config('edvance.lsa_intern', '', true);
  if (v_stand ->> 'folge_schnell_aktuell')::int >= (v_stand -> 'schwellen' ->> 'hinweis_folge')::int then
    update lsa_sessions set hinweis_tempo_am = now()
     where id = v_session.id and hinweis_tempo_am is null;
    v_hinweis := found;
  end if;

  -- {ok, next, hinweis_tempo} — kein correct, kein Score, kein Zaehler.
  return v_result || jsonb_build_object('hinweis_tempo', v_hinweis);
end;
$$;
