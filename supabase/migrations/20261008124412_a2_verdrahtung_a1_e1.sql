-- A2.4 Verdrahtung A1 und E1 (Entscheidungen A2 B, F, M; offene-punkte-a1 10, offene-punkte-e1 1, 2, 4, 6;
-- Befunde X0b in docs/session/offene-punkte-x0b.md).
--
-- Grundlage: Definitionen in Prod (pg_get_functiondef 06.10., identisch mit den Migrationen).
--   lernpfad_coach_der_session, lernpfad_darf_lesen   NULL-sicher (Konto ohne Profil -> false).
--   mein_lernpfad          auch vom Tablet des Kindes (Zuordnung ueber session_tablets).
--   erklaer_zugang         NULL-sicher; Tablet des Kindes zugelassen; nur in einer laufenden Session.
--   erklaer_nachlesen      NULL-sicher; Tablet des Kindes zugelassen ("nochmal erklaeren", G).
--   erklaer_checks         nur Aufgaben mit Einsatz 'check' (Entscheidung 28).
--   erklaer_runden_bis_signal(session)  aus dem Snapshot statt Startwert 2 (B); die alte Fassung
--                          ohne Argument entfaellt (einziger Aufrufer erklaer_check_abgeben).
--   erklaer_check_abgeben  schreibt je Check ein Ereignis 'check' (kernidee, ergebnis, runde), aus dem
--                          raum_signale das Signal "Erklaerrunden" rechnet (offene-punkte-r1 16).

create or replace function public.lernpfad_coach_der_session(p_session_id uuid, p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.get_my_role(), '') = 'coach'
     and exists (
       select 1
         from public.coaching_sessions cs
         join public.session_students ss on ss.session_id = cs.id
        where cs.id = p_session_id
          and cs.coach_id = auth.uid()
          and ss.student_id = p_student_id
     );
$$;

create or replace function public.lernpfad_darf_lesen(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case coalesce(public.get_my_role(), '')
           when 'admin' then true
           when 'coach' then public.akte_aktiv(p_student_id)
           else false
         end;
$$;

create or replace function public.mein_lernpfad()
returns table (skill_key text, label text, stand text, seit timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
#variable_conflict use_column
declare
  v_student uuid := coalesce(public.get_my_student_id(),
    -- A2: am Tablet das Kind des aktiven Platzes in einer laufenden Session (offene-punkte-a1 10).
    (select st.student_id from public.session_tablets st
       join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
      where st.geraet_id = auth.uid() and st.geloest_am is null));
begin
  if v_student is null then
    raise exception 'mein_lernpfad: nur fuer Schuelerkonten' using errcode = '42501';
  end if;
  return query
    select l.skill_key, s.label,
           case when l.stand_coach = 'gemeistert' then 'gemeistert'
                when l.stand_system = 'kandidat'  then 'sicher'
                else l.stand_system end,
           case when l.stand_coach = 'gemeistert' then l.coach_am else l.stand_system_seit end
      from public.lernpfad l
      join public.skills s on s.skill_key = l.skill_key
     where l.student_id = v_student
     order by s.klasse_herkunft, s.fundament_tiefe, l.skill_key;
end;
$$;

create or replace function public.erklaer_zugang(p_session_id uuid, p_student_id uuid) returns void
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  -- A2: NULL-sicher (Befund X0b); zusaetzlich das Tablet des Kindes (offene-punkte-e1 6).
  if not coalesce(coalesce(public.get_my_role(), '') = 'admin'
          or exists (select 1 from public.coaching_sessions cs
                      where cs.id = p_session_id and cs.coach_id = auth.uid())
          or public.get_my_student_id() = p_student_id
          or exists (select 1 from public.session_tablets st
                      where st.session_id = p_session_id and st.student_id = p_student_id
                        and st.geraet_id = auth.uid() and st.geloest_am is null), false) then
    raise exception 'erklaer: kein Zugriff auf diese Session' using errcode = '42501';
  end if;
  if not exists (select 1 from public.coaching_sessions cs where cs.id = p_session_id and cs.status = 'active') then
    raise exception 'erklaer: Session laeuft nicht' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance in ('planned', 'present')) then
    raise exception 'erklaer: Kind ist in dieser Session nicht gebucht' using errcode = '42501';
  end if;
end;
$$;

create or replace function public.erklaer_checks(p_kernidee_id uuid) returns uuid[]
language sql stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(array_agg(c.task_id order by c.reihenfolge), '{}')
    from public.erklaer_check c
    join public.tasks t on t.id = c.task_id
   where c.kernidee_id = p_kernidee_id and t.status = 'ready' and coalesce(t.is_active, true)
     and 'check' = any (t.einsatz)
$$;

drop function public.erklaer_runden_bis_signal();

create function public.erklaer_runden_bis_signal(p_session_id uuid) returns integer
language sql stable
security definer
set search_path = public, pg_temp
as $$ select coalesce(public.session_wert_zahl(p_session_id, 'erklaerrunden_bis_signal')::int, 2) $$;

revoke all on function public.erklaer_runden_bis_signal(uuid) from public, anon, authenticated;

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
  -- A2: Ereignis fuer raum_signale (Signal nach erklaerrunden_bis_signal falschen Checks je Kernidee).
  perform public.session_ereignis(p_session_id, p_student_id, 'check',
    jsonb_build_object('kernidee', v_k.id, 'ergebnis',
                       case when (v_urteil ->> 'richtig')::boolean then 'richtig' else 'falsch' end,
                       'runde', v_letzt.runde, 'skill_key', v_k.skill_key));

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
         and kernidee_id = v_k.id and ergebnis = 'falsch') >= public.erklaer_runden_bis_signal(p_session_id) then
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

create or replace function public.erklaer_nachlesen(p_student_id uuid, p_skill_key text)
returns jsonb
language plpgsql stable
security definer
set search_path = public, pg_temp
as $$
begin
  -- A2: NULL-sicher (Befund X0b); zusaetzlich das Tablet des Kindes in einer laufenden Session.
  if not coalesce(coalesce(public.get_my_role(), '') = 'admin'
          or public.get_my_student_id() = p_student_id
          or exists (select 1 from public.session_students ss
                       join public.coaching_sessions cs on cs.id = ss.session_id
                      where ss.student_id = p_student_id and cs.coach_id = auth.uid())
          or exists (select 1 from public.session_tablets st
                       join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
                      where st.student_id = p_student_id and st.geraet_id = auth.uid() and st.geloest_am is null),
          false) then
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
