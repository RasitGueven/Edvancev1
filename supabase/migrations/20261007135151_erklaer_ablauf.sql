-- E1.3 Erklaersequenz: Ablauf auf dem Server (Bauauftrag Session-P1, Entscheidung 18).
--
--   erklaer_start(session, student, skill_key)                 erster Schritt (nur freigegeben)
--   erklaer_check_abgeben(session, student, check_task_id, eingabe)
--        -> genau eine aktion: 'weiter' | 'variante' | 'signal'
--   erklaer_nachlesen(student, skill_key)                      Variante A ohne Checks (zuhause)
--
-- Die Antworten enthalten nie die Loesung, kein richtig/falsch und kein Fehlbild
-- (Fehlbild sieht nur der Coach, Entscheidung 17). Der Verlauf steht append-only in
-- erklaer_fortschritt: 'gezeigt' (Variante + offener Check), dann 'richtig'/'falsch',
-- dann das naechste 'gezeigt' oder 'signal'.
-- Bewertung wie lsa_submit: lsa_is_correct je Teil; Fehlbild wie lsa_fehlbild_capture.

-- Stellschraube erklaerrunden_bis_signal (Entscheidung 15/22). session_einstellungen
-- kommt mit R1; bis zur Verdrahtung in P2 der Startwert 2 (offener Punkt).
create function public.erklaer_runden_bis_signal() returns integer
language sql immutable
set search_path = public, pg_temp
as $$ select 2 $$;

-- Admin, der Coach der Session oder das Kind selbst; das Kind muss in der Session gebucht sein.
create function public.erklaer_zugang(p_session_id uuid, p_student_id uuid) returns void
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (coalesce(public.get_my_role(), '') = 'admin'
          or exists (select 1 from public.coaching_sessions cs
                      where cs.id = p_session_id and cs.coach_id = auth.uid())
          or public.get_my_student_id() = p_student_id) then
    raise exception 'erklaer: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance in ('planned', 'present')) then
    raise exception 'erklaer: Kind ist in dieser Session nicht gebucht' using errcode = '42501';
  end if;
end;
$$;

-- Freigegebene Check-Aufgaben einer Kernidee (Entscheidung 5: nur ready und aktiv).
create function public.erklaer_checks(p_kernidee_id uuid) returns uuid[]
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(c.task_id order by c.reihenfolge), '{}')
    from public.erklaer_check c
    join public.tasks t on t.id = c.task_id
   where c.kernidee_id = p_kernidee_id and t.status = 'ready' and coalesce(t.is_active, true)
$$;

-- Varianten mit freigegebenem Erklaerschritt, in Reihenfolge A, B, C.
create function public.erklaer_varianten(p_kernidee_id uuid) returns text[]
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(s.variante order by s.variante), '{}')
    from public.erklaer_schritt s
   where s.kernidee_id = p_kernidee_id and s.art = 'erklaerung' and s.status = 'freigegeben'
$$;

-- Naechste nutzbare Kernidee eines Skills nach Nummer p_nach_nr (0 = die erste).
create function public.erklaer_naechste_kernidee(p_skill_key text, p_nach_nr integer)
returns public.erklaer_kernidee
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select k.* from public.erklaer_kernidee k
   where k.skill_key = p_skill_key and k.nr > p_nach_nr and k.status = 'freigegeben'
     and cardinality(public.erklaer_varianten(k.id)) > 0
     and cardinality(public.erklaer_checks(k.id)) > 0
   order by k.nr limit 1
$$;

-- Ein Schritt fuer die App: Text, Formeln nur als SVG-URLs, Bild.
create function public.erklaer_schritt_json(s public.erklaer_schritt) returns jsonb
language sql stable
set search_path = public, pg_temp
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'art',     s.art,
    'inhalt',  s.inhalt,
    'formeln', (select coalesce(jsonb_agg(public.lsa_storage_base() || 'erklaer/formeln/' || h || '.svg'
                                          order by o), '[]')
                  from unnest(s.formeln) with ordinality as f(h, o)),
    'bild',    case when s.bild ? 'svg_hash' then jsonb_build_object(
                      'url', public.lsa_storage_base() || 'erklaer/bilder/' || (s.bild ->> 'svg_hash') || '.svg',
                      'alt', s.bild ->> 'alt', 'content_type', 'image/svg+xml')
                    else s.bild end))
$$;

create function public.erklaer_schritte_json(p_kernidee_id uuid, p_variante text) returns jsonb
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(public.erklaer_schritt_json(s)
                            order by case s.art when 'erklaerung' then 1 else 2 end), '[]')
    from public.erklaer_schritt s
   where s.kernidee_id = p_kernidee_id and s.variante = p_variante and s.status = 'freigegeben'
$$;

-- Eine Abgabe bzw. ein Start je Session und Kind zur Zeit (Doppelklick, zwei Geraete).
create function public.erklaer_sperren(p_session_id uuid, p_student_id uuid) returns void
language sql volatile
set search_path = public, pg_temp
as $$
  select pg_advisory_xact_lock(hashtext('erklaer:' || p_session_id::text || ':' || p_student_id::text))
$$;

-- Zeigt Kernidee + Variante in Runde p_runde: schreibt 'gezeigt' und liefert das Paket.
create function public.erklaer_zeigen(
  p_session_id uuid, p_student_id uuid, p_kernidee public.erklaer_kernidee,
  p_variante text, p_runde integer, p_aktion text
)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_checks uuid[] := public.erklaer_checks(p_kernidee.id);
  v_check  uuid;
begin
  if cardinality(v_checks) = 0 or p_variante is null then
    raise exception 'erklaer: Kernidee % hat keine freigegebene Variante oder Check-Aufgabe', p_kernidee.nr
      using errcode = 'P0002';
  end if;
  v_check := v_checks[((p_runde - 1) % cardinality(v_checks)) + 1];
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis)
  values (p_session_id, p_student_id, p_kernidee.id, p_runde, p_variante, v_check, 'gezeigt');

  return jsonb_build_object(
    'aktion',   p_aktion,
    'kernidee', jsonb_build_object(
                  'nr', p_kernidee.nr, 'titel', p_kernidee.titel,
                  'von', (select count(*) from public.erklaer_kernidee k
                           where k.skill_key = p_kernidee.skill_key and k.status = 'freigegeben')),
    'variante', p_variante,
    'runde',    p_runde,
    'schritte', public.erklaer_schritte_json(p_kernidee.id, p_variante),
    'check',    jsonb_build_object('task_id', v_check,
                                   'aufgabe', public.lsa_question_payload(v_check)));
end;
$$;

-- Bewertet eine Check-Antwort mit der LSA-Engine: {richtig, fehlbild}.
create function public.erklaer_bewerten(p_task_id uuid, p_eingabe jsonb) returns jsonb
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_task    public.tasks;
  v_sol     public.task_solutions;
  v_richtig boolean;
  v_fb      text;
begin
  select * into v_task from public.tasks where id = p_task_id;
  select * into v_sol from public.task_solutions where task_id = p_task_id;

  if v_task.input_type = 'MULTI_PART' then
    select coalesce(bool_and(t.ok), false),
           (array_agg(t.fb order by t.nr) filter (where not t.ok and t.fb is not null))[1]
      into v_richtig, v_fb
      from (select (p ->> 'nr')::int as nr,
                   coalesce(public.lsa_is_correct(
                     case when p ->> 'kind' = 'mc' then 'MC' else 'SHORT_TEXT' end,
                     case when jsonb_typeof(v_sol.correct_answers -> (p ->> 'nr')) = 'array'
                          then v_sol.correct_answers -> (p ->> 'nr') else '[]'::jsonb end,
                     public.lsa_part_answer(p ->> 'kind', p_eingabe -> (p ->> 'nr'))), false) as ok,
                   public.lsa_fehlbild_match(p ->> 'kind',
                     v_sol.acceptance -> (p ->> 'nr') -> 'known_errors',
                     public.lsa_part_answer(p ->> 'kind', p_eingabe -> (p ->> 'nr'))) as fb
              from jsonb_array_elements(v_task.parts) as e(p)) t;
  else
    v_richtig := coalesce(public.lsa_is_correct(v_task.input_type, v_sol.correct_answers, p_eingabe), false);
    if not v_richtig then
      v_fb := public.lsa_fehlbild_match(lower(v_task.input_type), v_sol.acceptance -> 'known_errors',
                public.lsa_part_answer(lower(v_task.input_type), p_eingabe));
    end if;
  end if;

  return jsonb_build_object('richtig', v_richtig,
                            'fehlbild', case when v_fb = '__known__' then null else v_fb end);
end;
$$;

create function public.erklaer_start(p_session_id uuid, p_student_id uuid, p_skill_key text)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_letzt public.erklaer_fortschritt;
  v_k     public.erklaer_kernidee;
begin
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);

  select f.* into v_letzt from public.erklaer_fortschritt f
    join public.erklaer_kernidee k on k.id = f.kernidee_id
   where f.session_id = p_session_id and f.student_id = p_student_id and k.skill_key = p_skill_key
   order by f.id desc limit 1;

  if v_letzt.id is not null then
    -- Wiederaufnahme: dasselbe Paket, derselbe offene Check, ohne neue Zeile.
    select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
    if v_letzt.ergebnis = 'signal' then
      return jsonb_build_object('aktion', 'signal');
    elsif v_letzt.ergebnis = 'richtig' then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    -- Inzwischen nicht mehr freigegeben (Kernidee, Variante oder Check): nicht ausliefern.
    if v_k.status <> 'freigegeben'
       or not (v_letzt.variante = any (public.erklaer_varianten(v_k.id)))
       or not (v_letzt.check_task_id = any (public.erklaer_checks(v_k.id))) then
      raise exception 'erklaer_start: Erklaerung inzwischen nicht mehr freigegeben' using errcode = 'P0002';
    end if;
    return jsonb_build_object(
      'aktion', 'start',
      'kernidee', jsonb_build_object('nr', v_k.nr, 'titel', v_k.titel,
                    'von', (select count(*) from public.erklaer_kernidee k
                             where k.skill_key = p_skill_key and k.status = 'freigegeben')),
      'variante', v_letzt.variante, 'runde', v_letzt.runde,
      'schritte', public.erklaer_schritte_json(v_k.id, v_letzt.variante),
      'check', jsonb_build_object('task_id', v_letzt.check_task_id,
                                  'aufgabe', public.lsa_question_payload(v_letzt.check_task_id)));
  end if;

  v_k := public.erklaer_naechste_kernidee(p_skill_key, 0);
  if v_k.id is null then
    raise exception 'erklaer_start: keine freigegebene Erklaerung fuer %', p_skill_key using errcode = 'P0002';
  end if;
  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               (public.erklaer_varianten(v_k.id))[1], 1, 'start');
end;
$$;

create function public.erklaer_check_abgeben(
  p_session_id uuid, p_student_id uuid, p_check_task_id uuid, p_eingabe jsonb
)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_letzt    public.erklaer_fortschritt;
  v_k        public.erklaer_kernidee;
  v_naechste public.erklaer_kernidee;
  v_urteil   jsonb;
  v_fb       text;
  v_var      text[];
  v_gezeigt  text[];
  v_wahl     text;
begin
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);

  select * into v_letzt from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
   order by id desc limit 1;
  if v_letzt.id is null or v_letzt.ergebnis <> 'gezeigt'
     or v_letzt.check_task_id is distinct from p_check_task_id then
    raise exception 'erklaer_check_abgeben: nicht der offene Check' using errcode = 'P0001';
  end if;
  select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
  if v_k.status <> 'freigegeben' or not (p_check_task_id = any (public.erklaer_checks(v_k.id))) then
    raise exception 'erklaer_check_abgeben: Check inzwischen nicht mehr freigegeben' using errcode = 'P0002';
  end if;

  v_urteil := public.erklaer_bewerten(p_check_task_id, p_eingabe);
  v_fb := v_urteil ->> 'fehlbild';
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
  values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
          case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end, v_fb);

  -- Richtig: naechste Kernidee, sonst Uebergang ins Ueben. Kein Mastery-Signal.
  if (v_urteil ->> 'richtig')::boolean then
    v_naechste := public.erklaer_naechste_kernidee(v_k.skill_key, v_k.nr);
    if v_naechste.id is null then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    return public.erklaer_zeigen(p_session_id, p_student_id, v_naechste,
                                 (public.erklaer_varianten(v_naechste.id))[1], 1, 'weiter');
  end if;

  -- Falsch: nach erklaerrunden_bis_signal Runden ein Signal an den Coach.
  if (select count(*) from public.erklaer_fortschritt
       where session_id = p_session_id and student_id = p_student_id
         and kernidee_id = v_k.id and ergebnis = 'falsch') >= public.erklaer_runden_bis_signal() then
    insert into public.erklaer_fortschritt
      (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
    values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
            'signal', v_fb);
    return jsonb_build_object('aktion', 'signal');
  end if;

  -- Sonst eine andere Variante: passend zum Fehlbild, sonst die naechste ungezeigte.
  v_var := public.erklaer_varianten(v_k.id);
  select coalesce(array_agg(distinct variante), '{}') into v_gezeigt
    from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
     and kernidee_id = v_k.id and ergebnis = 'gezeigt';

  select s.variante into v_wahl from public.erklaer_schritt s
   where s.kernidee_id = v_k.id and s.art = 'erklaerung' and s.status = 'freigegeben'
     and s.variante <> v_letzt.variante and v_fb is not null and v_fb = any (s.fehlbild_slugs)
   order by (s.variante = any (v_gezeigt)), s.variante limit 1;
  if v_wahl is null then
    select v into v_wahl from unnest(v_var) v
     where v <> v_letzt.variante
     order by (v = any (v_gezeigt)), (v < v_letzt.variante), v limit 1;
  end if;

  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               coalesce(v_wahl, v_letzt.variante), v_letzt.runde + 1, 'variante');
end;
$$;

-- Zuhause: nur freigegebene Erklaerschritte und Beispiele der Variante A, keine Checks.
create function public.erklaer_nachlesen(p_student_id uuid, p_skill_key text)
returns jsonb
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not (coalesce(public.get_my_role(), '') = 'admin'
          or public.get_my_student_id() = p_student_id
          or exists (select 1 from public.session_students ss
                       join public.coaching_sessions cs on cs.id = ss.session_id
                      where ss.student_id = p_student_id and cs.coach_id = auth.uid())) then
    raise exception 'erklaer_nachlesen: kein Zugriff' using errcode = '42501';
  end if;

  return jsonb_build_object(
    'skill_key', p_skill_key,
    'kernideen', (select coalesce(jsonb_agg(jsonb_build_object(
                           'nr', k.nr, 'titel', k.titel,
                           'schritte', public.erklaer_schritte_json(k.id, 'A')) order by k.nr), '[]')
                    from public.erklaer_kernidee k
                   where k.skill_key = p_skill_key and k.status = 'freigegeben'
                     and 'A' = any (public.erklaer_varianten(k.id))));
end;
$$;

revoke all on function public.erklaer_runden_bis_signal() from public, anon, authenticated;
revoke all on function public.erklaer_sperren(uuid, uuid) from public, anon, authenticated;
revoke all on function public.erklaer_zugang(uuid, uuid) from public, anon, authenticated;
revoke all on function public.erklaer_checks(uuid) from public, anon, authenticated;
revoke all on function public.erklaer_varianten(uuid) from public, anon, authenticated;
revoke all on function public.erklaer_naechste_kernidee(text, integer) from public, anon, authenticated;
revoke all on function public.erklaer_schritt_json(public.erklaer_schritt) from public, anon, authenticated;
revoke all on function public.erklaer_schritte_json(uuid, text) from public, anon, authenticated;
revoke all on function public.erklaer_zeigen(uuid, uuid, public.erklaer_kernidee, text, integer, text)
  from public, anon, authenticated;
revoke all on function public.erklaer_bewerten(uuid, jsonb) from public, anon, authenticated;

revoke all on function public.erklaer_start(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.erklaer_check_abgeben(uuid, uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.erklaer_nachlesen(uuid, text) from public, anon, authenticated;
grant execute on function public.erklaer_start(uuid, uuid, text) to authenticated;
grant execute on function public.erklaer_check_abgeben(uuid, uuid, uuid, jsonb) to authenticated;
grant execute on function public.erklaer_nachlesen(uuid, text) to authenticated;
