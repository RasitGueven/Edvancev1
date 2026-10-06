-- A2 Erklaerinhalte im Testlauf (Rasit 06.10.): Im Testlauf (nur mit Testkonten, Entscheidung 27)
-- laufen auch ungepruefte Erklaerinhalte, wie bei Aufgaben. Sonst nie.
--   erklaer_status_ok       freigegeben; im Testlauf auch entwurf und geprueft.
--   erklaer_checks          ready; im Testlauf auch draft/review/rueckfrage ohne pruef_ausschluss (wie X0).
--   erklaer_varianten, erklaer_naechste_kernidee, erklaer_schritte_json, erklaer_zeigen
--                           bekommen p_testlauf (intern, ersetzt per drop/create, Standard false).
--   erklaer_start, erklaer_check_abgeben  lesen coaching_sessions.testlauf und reichen ihn durch.
-- Grundlage: Prod-Definitionen (E1) bzw. die A2-Fassung aus 20261008124412.
-- erklaer_nachlesen (zuhause) bleibt bei freigegeben (Aufruf ohne p_testlauf).

-- erklaer_status_ok legt 20261008122230_a2_bausteine an (SQL-Funktionen dort brauchen sie beim Anlegen).

drop function public.erklaer_zeigen(uuid, uuid, public.erklaer_kernidee, text, integer, text);
drop function public.erklaer_schritte_json(uuid, text);
drop function public.erklaer_naechste_kernidee(text, integer);
drop function public.erklaer_varianten(uuid);
drop function public.erklaer_checks(uuid);

create function public.erklaer_checks(p_kernidee_id uuid, p_testlauf boolean default false) returns uuid[]
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(c.task_id order by c.reihenfolge), '{}')
    from public.erklaer_check c
    join public.tasks t on t.id = c.task_id
   where c.kernidee_id = p_kernidee_id and coalesce(t.is_active, true)
     and (t.status = 'ready'
          or (coalesce(p_testlauf, false) and t.status in ('draft', 'review', 'rueckfrage')
              and public.pruef_ausschluss(t.id) is null))
     and 'check' = any (t.einsatz)
$$;

create function public.erklaer_varianten(p_kernidee_id uuid, p_testlauf boolean default false) returns text[]
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(s.variante order by s.variante), '{}')
    from public.erklaer_schritt s
   where s.kernidee_id = p_kernidee_id and s.art = 'erklaerung' and public.erklaer_status_ok(s.status, p_testlauf)
$$;

create function public.erklaer_naechste_kernidee(p_skill_key text, p_nach_nr integer,
                                                 p_testlauf boolean default false)
returns public.erklaer_kernidee
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select k.* from public.erklaer_kernidee k
   where k.skill_key = p_skill_key and k.nr > p_nach_nr and public.erklaer_status_ok(k.status, p_testlauf)
     and cardinality(public.erklaer_varianten(k.id, p_testlauf)) > 0
     and cardinality(public.erklaer_checks(k.id, p_testlauf)) > 0
   order by k.nr limit 1
$$;

create function public.erklaer_schritte_json(p_kernidee_id uuid, p_variante text,
                                             p_testlauf boolean default false) returns jsonb
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(public.erklaer_schritt_json(s)
                            order by case s.art when 'erklaerung' then 1 else 2 end), '[]')
    from public.erklaer_schritt s
   where s.kernidee_id = p_kernidee_id and s.variante = p_variante and public.erklaer_status_ok(s.status, p_testlauf)
$$;

create function public.erklaer_zeigen(
  p_session_id uuid, p_student_id uuid, p_kernidee public.erklaer_kernidee,
  p_variante text, p_runde integer, p_aktion text, p_testlauf boolean default false
)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_checks uuid[] := public.erklaer_checks(p_kernidee.id, p_testlauf);
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
                           where k.skill_key = p_kernidee.skill_key and public.erklaer_status_ok(k.status, p_testlauf))),
    'variante', p_variante,
    'runde',    p_runde,
    'schritte', public.erklaer_schritte_json(p_kernidee.id, p_variante, p_testlauf),
    'check',    jsonb_build_object('task_id', v_check,
                                   'aufgabe', public.lsa_question_payload(v_check)));
end;
$$;

create or replace function public.erklaer_start(p_session_id uuid, p_student_id uuid, p_skill_key text)
returns jsonb
language plpgsql volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_letzt public.erklaer_fortschritt;
  v_k     public.erklaer_kernidee;
  v_tl    boolean;
begin
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

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
    if not public.erklaer_status_ok(v_k.status, v_tl)
       or not (v_letzt.variante = any (public.erklaer_varianten(v_k.id, v_tl)))
       or not (v_letzt.check_task_id = any (public.erklaer_checks(v_k.id, v_tl))) then
      raise exception 'erklaer_start: Erklaerung inzwischen nicht mehr freigegeben' using errcode = 'P0002';
    end if;
    return jsonb_build_object(
      'aktion', 'start',
      'kernidee', jsonb_build_object('nr', v_k.nr, 'titel', v_k.titel,
                    'von', (select count(*) from public.erklaer_kernidee k
                             where k.skill_key = p_skill_key and public.erklaer_status_ok(k.status, v_tl))),
      'variante', v_letzt.variante, 'runde', v_letzt.runde,
      'schritte', public.erklaer_schritte_json(v_k.id, v_letzt.variante, v_tl),
      'check', jsonb_build_object('task_id', v_letzt.check_task_id,
                                  'aufgabe', public.lsa_question_payload(v_letzt.check_task_id)));
  end if;

  v_k := public.erklaer_naechste_kernidee(p_skill_key, 0, v_tl);
  if v_k.id is null then
    raise exception 'erklaer_start: keine freigegebene Erklaerung fuer %', p_skill_key using errcode = 'P0002';
  end if;
  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               (public.erklaer_varianten(v_k.id, v_tl))[1], 1, 'start', v_tl);
end;
$$;

create or replace function public.erklaer_check_abgeben(
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
  v_tl       boolean;
begin
  perform public.erklaer_zugang(p_session_id, p_student_id);
  perform public.erklaer_sperren(p_session_id, p_student_id);
  v_tl := coalesce((select cs.testlauf from public.coaching_sessions cs where cs.id = p_session_id), false);

  select * into v_letzt from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
   order by id desc limit 1;
  if v_letzt.id is null or v_letzt.ergebnis <> 'gezeigt'
     or v_letzt.check_task_id is distinct from p_check_task_id then
    raise exception 'erklaer_check_abgeben: nicht der offene Check' using errcode = 'P0001';
  end if;
  select * into v_k from public.erklaer_kernidee where id = v_letzt.kernidee_id;
  if not public.erklaer_status_ok(v_k.status, v_tl) or not (p_check_task_id = any (public.erklaer_checks(v_k.id, v_tl))) then
    raise exception 'erklaer_check_abgeben: Check inzwischen nicht mehr freigegeben' using errcode = 'P0002';
  end if;

  v_urteil := public.erklaer_bewerten(p_check_task_id, p_eingabe);
  v_fb := v_urteil ->> 'fehlbild';
  insert into public.erklaer_fortschritt
    (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
  values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
          case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end, v_fb);
  -- A2: Ereignis fuer raum_signale (Signal nach erklaerrunden_bis_signal falschen Checks je Kernidee).
  perform public.session_ereignis(p_session_id, p_student_id, 'check',
    jsonb_build_object('kernidee', v_k.id, 'ergebnis',
                       case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end,
                       'runde', v_letzt.runde, 'skill_key', v_k.skill_key));

  -- Richtig: naechste Kernidee, sonst Uebergang ins Ueben. Kein Mastery-Signal.
  if (v_urteil ->> 'richtig')::boolean then
    v_naechste := public.erklaer_naechste_kernidee(v_k.skill_key, v_k.nr, v_tl);
    if v_naechste.id is null then
      return jsonb_build_object('aktion', 'weiter', 'uebergang', 'ueben');
    end if;
    return public.erklaer_zeigen(p_session_id, p_student_id, v_naechste,
                                 (public.erklaer_varianten(v_naechste.id, v_tl))[1], 1, 'weiter', v_tl);
  end if;

  -- Falsch: nach erklaerrunden_bis_signal Runden ein Signal an den Coach.
  if (select count(*) from public.erklaer_fortschritt
       where session_id = p_session_id and student_id = p_student_id
         and kernidee_id = v_k.id and ergebnis = 'falsch') >= public.erklaer_runden_bis_signal(p_session_id) then
    insert into public.erklaer_fortschritt
      (session_id, student_id, kernidee_id, runde, variante, check_task_id, ergebnis, fehlbild_slug)
    values (p_session_id, p_student_id, v_k.id, v_letzt.runde, v_letzt.variante, p_check_task_id,
            'signal', v_fb);
    return jsonb_build_object('aktion', 'signal');
  end if;

  -- Sonst eine andere Variante: passend zum Fehlbild, sonst die naechste ungezeigte.
  v_var := public.erklaer_varianten(v_k.id, v_tl);
  select coalesce(array_agg(distinct variante), '{}') into v_gezeigt
    from public.erklaer_fortschritt
   where session_id = p_session_id and student_id = p_student_id
     and kernidee_id = v_k.id and ergebnis = 'gezeigt';

  select s.variante into v_wahl from public.erklaer_schritt s
   where s.kernidee_id = v_k.id and s.art = 'erklaerung' and public.erklaer_status_ok(s.status, v_tl)
     and s.variante <> v_letzt.variante and v_fb is not null and v_fb = any (s.fehlbild_slugs)
   order by (s.variante = any (v_gezeigt)), s.variante limit 1;
  if v_wahl is null then
    select v into v_wahl from unnest(v_var) v
     where v <> v_letzt.variante
     order by (v = any (v_gezeigt)), (v < v_letzt.variante), v limit 1;
  end if;

  return public.erklaer_zeigen(p_session_id, p_student_id, v_k,
                               coalesce(v_wahl, v_letzt.variante), v_letzt.runde + 1, 'variante', v_tl);
end;
$$;

revoke all on function
  public.erklaer_checks(uuid, boolean), public.erklaer_varianten(uuid, boolean),
  public.erklaer_naechste_kernidee(text, integer, boolean), public.erklaer_schritte_json(uuid, text, boolean),
  public.erklaer_zeigen(uuid, uuid, public.erklaer_kernidee, text, integer, text, boolean)
  from public, anon, authenticated;
