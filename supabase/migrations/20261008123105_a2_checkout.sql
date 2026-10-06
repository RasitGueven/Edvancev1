-- A2.3 Session-Engine: Check-out (Entscheidung A2 K).
--
-- Zu Beginn der Phase exit_aufgaben Aufgaben zum Ziel der Stunde, ohne Hinweise
-- (hinweis_abrufen lehnt sie ab, 20261008124410), auf dem aktuellen Niveau. Skill: der zuletzt
-- in der Kernarbeit geuebte (nicht eingemischt), sonst der aktuelle Skill des Ziels; reicht
-- sein Pool nicht, die anderen heute geuebten Skills. Danach das Ergebnis fuer
-- session_kind_abschluss.exit_ergebnis und art = termin (home_quests_aktiv) bzw. fertig.

create function public.session_plan_checkout(p_session_id uuid, p_student_id uuid, p_testlauf boolean,
                                             p_aktuell text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_n      int := public.session_wert_zahl(p_session_id, 'exit_aufgaben')::int;
  v_quests boolean := coalesce((public.session_wert(p_session_id, 'home_quests_aktiv') #>> '{}')::boolean, false);
  v_e      int;
  v_r      int;
  v_erg    jsonb := '{}';
  c        record;
  w        record;
  v_niv    int;
begin
  select count(*), count(*) filter (where (public.session_aufgabe_stand(p_session_id, p_student_id, s.task_id)).richtig)
    into v_e, v_r
    from public.session_schritte s
   where s.session_id = p_session_id and s.student_id = p_student_id and s.art = 'exit';

  if v_e < v_n then
    for c in
      select x.skill_key from (
        select s.skill_key, max(s.id) as zuletzt, 0 as rang from public.session_schritte s
         where s.session_id = p_session_id and s.student_id = p_student_id and s.phase = 'kern'
           and s.art = 'aufgabe' and not s.eingemischt and s.skill_key is not null
         group by s.skill_key
        union all
        select p_aktuell, 0, 1 where p_aktuell is not null
      ) x
      order by x.rang, x.zuletzt desc
    loop
      v_niv := (public.session_niveau(p_session_id, p_student_id, c.skill_key)).niveau;
      select * into w from public.session_aufgabe_waehlen(p_session_id, p_student_id, c.skill_key, v_niv, p_testlauf);
      if w.task_id is not null then
        return public.session_schritt('exit', 'checkout', c.skill_key, w.task_id, 'selbststaendig', false, v_niv,
          'Check-out: Exit-Aufgabe ' || (v_e + 1) || ' von ' || v_n || ' zu ' || public.session_label(c.skill_key)
            || ', Stufe ' || v_niv || ', ohne Hinweise', 'exit');
      end if;
    end loop;
  end if;

  if v_e > 0 then
    v_erg := jsonb_build_object('exit_ergebnis', jsonb_build_object('richtig', v_r, 'gesamt', v_e));
  end if;
  if v_quests and not exists (select 1 from public.session_kind_abschluss k where k.session_id = p_session_id
                               and k.student_id = p_student_id and k.quest_termin is not null) then
    return public.session_schritt('termin', 'checkout', null, null, null, false, null,
      'Check-out: Termin für die Home Quests wählen'
        || case when v_e > 0 then ' (Exit ' || v_r || ' von ' || v_e || ')' else '' end, 'termin', v_erg);
  end if;
  return public.session_schritt('fertig', 'checkout', null, null, null, false, null,
    'Fertig für heute' || case when v_e > 0 then ': Exit ' || v_r || ' von ' || v_e || ' richtig'
                               else ' (keine Exit-Aufgabe im Pool)' end, 'fertig', v_erg);
end;
$$;

revoke all on function public.session_plan_checkout(uuid, uuid, boolean, text) from public, anon, authenticated;
