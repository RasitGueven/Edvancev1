-- LSA ohne Ausblick (Rasit 25.10.2026): „Kinder sollen nichts in der LSA haben, was sie noch nicht hatten.“
--
-- 1. Ausblick aus. Der Ausblick (LSA-V2) gab starken Kindern die Einstiege der naechsten drei Plan-Themen, also
--    Stoff, der noch nicht behandelt ist. lsa_ausblick_knoten liefert jetzt immer '{}'; damit ueberspringt
--    lsa_select_next_core die Ausblick-Phase (cardinality = 0), und lsa_ist_ausblick ist immer false (kein
--    Sonderfall Zweitbeleg/Abstieg mehr). lsa_select_next_core selbst bleibt unveraendert.
--    Die uebrigen Phasen ziehen keinen neuen Stoff: Thema und Tiefe liegen im Themenraum und seinen
--    Voraussetzungen, die Vorschau nimmt nur Voraussetzungen der kommenden Themen und nie Skills kommender oder
--    spaeterer Themen, der Rueckblick nur Einstiege behandelter Themen (lead_themen.status = 'behandelt').
--    Schalter fuer Tests und Simulation: set local lsa.ausblick = 'an' (pgTAP lsa_v2_ausblick, lsa_v_vorschau).
-- 2. Lenas Liste (pruef_soll batu_lsa, P4): die fuenf Ausblick-Bereiche und gleichung_quadr_formel (Plan Klasse
--    10, von der LSA nie abgefragt) ruhen (aktiv = false). Nichts geloescht, keine Flags entfernt.
--
-- Rollback: supabase/rollback/20261025220449_lsa_ohne_ausblick.sql. Kein begin/commit: mig klammert.

create or replace function public.lsa_ausblick_knoten(p_session_id uuid, p_mit_thema boolean default null)
returns text[]
language plpgsql
stable
security definer
set search_path to 'public'
as $$
declare
  -- So viele kommende Plan-Themen nimmt der Ausblick (die Vorschau nimmt c_vorschau_themen = 2).
  c_ausblick_themen constant int := 3;

  v_sess     lsa_sessions;
  v_fach     text;
  v_schule   uuid;
  v_aktuell  int;
  v_themen   text[];
  v_einstieg text[];
  v_raum     text[];
  v_lead     uuid;
begin
  -- Rasit 25.10.2026: Kinder bekommen in der LSA nichts, was sie noch nicht hatten. Der Ausblick ist aus; nur die
  -- Tests schalten ihn mit set local lsa.ausblick = 'an' ein, damit der Mechanismus geprueft bleibt.
  if current_setting('lsa.ausblick', true) is distinct from 'an' then
    return '{}';
  end if;

  select * into v_sess from lsa_sessions where id = p_session_id;
  if not found or v_sess.thema_key is null then
    return '{}';
  end if;
  if not coalesce(p_mit_thema, exists (
       select 1 from thema_einstieg te join tasks t on t.skill_key = te.skill_key
        where te.thema_key = v_sess.thema_key
          and public.lsa_im_pool(t.id, public.lsa_testinhalte(p_session_id)))) then
    return '{}';
  end if;

  v_fach   := lower(v_sess.subject);
  v_schule := public.lsa_schule_von_sitzung(p_session_id);
  v_lead   := public.lsa_lead_von_schueler(v_sess.student_id);

  if exists (select 1 from schul_themenplan p
              where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade) then
    -- Aktuelle Position wie in lsa_select_next_core (LSA-V) und lernweg.ts.
    v_aktuell := coalesce(
      (select min(p.position) from schul_themenplan p
        where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade
          and p.thema_key = v_sess.thema_key),
      (select min(p.position) from schul_themenplan p
        where p.schule_id = v_schule and lower(p.fach) = v_fach and p.klasse = v_sess.grade
          and p.halbjahr = case when extract(month from coalesce(v_sess.completed_at, v_sess.started_at,
                                                                 v_sess.created_at) at time zone 'Europe/Berlin')
                                     between 2 and 7 then 2 else 1 end),
      0);
    v_themen := array(
      select x.thema_key
        from (select p.thema_key,
                     min(case when p.klasse = v_sess.grade then 0 else 1 end) as kl,
                     min(p.position) filter (where p.klasse = v_sess.grade) as pos,
                     min(p.position) as pos_naechste
                from schul_themenplan p
               where p.schule_id = v_schule and lower(p.fach) = v_fach and p.thema_key is not null
                 and p.thema_key is distinct from v_sess.thema_key
                 and ((p.klasse = v_sess.grade and p.position > v_aktuell) or p.klasse = v_sess.grade + 1)
               group by p.thema_key) x
       order by x.kl, coalesce(x.pos, x.pos_naechste)
       limit c_ausblick_themen);
  else
    -- Kernlehrplan wie die Vorschau (klpPlan in plan.ts).
    with klp as (
      select th.thema_key, th.sort from themen th
       where lower(th.fach) = v_fach
         and th.stufe = case when v_sess.grade <= 6 then 'erprobung'
                             when v_sess.grade <= 8 then 'erste' else 'zweite' end
    ), k as (
      select * from klp
       where not exists (select 1 from themen th join klp using (thema_key) where th.klasse >= v_sess.grade)
          or thema_key in (select th.thema_key from themen th join klp using (thema_key)
                            where th.klasse >= v_sess.grade)
    )
    select array(select k.thema_key from k
                  where k.sort > coalesce((select k2.sort from k k2 where k2.thema_key = v_sess.thema_key), -1)
                  order by k.sort nulls last, k.thema_key
                  limit c_ausblick_themen)
      into v_themen;
  end if;

  v_einstieg := array(select te.skill_key from thema_einstieg te where te.thema_key = v_sess.thema_key);
  v_raum := v_einstieg || array(
    select distinct a.skill_key
      from unnest(v_einstieg) e(sk)
      cross join lateral public.lsa_abschluss(e.sk) a);

  return array(
    select x.skill_key
      from (select te.skill_key, min(u.rang) as rang
              from unnest(v_themen) with ordinality u(thema_key, rang)
              join thema_einstieg te on te.thema_key = u.thema_key
             group by te.skill_key) x
      join skills s on s.skill_key = x.skill_key
     where s.klasse_herkunft <= v_sess.grade + 1
       and not x.skill_key = any (v_raum)
       and not exists (select 1 from lead_themen lt join thema_einstieg te on te.thema_key = lt.thema_key
                        where lt.lead_id = v_lead and lt.status = 'behandelt' and lower(lt.fach) = v_fach
                          and te.skill_key = x.skill_key)
     order by x.rang, s.fundament_tiefe nulls last, x.skill_key);
end;
$$;

update public.pruef_soll
   set aktiv = false
 where anlass = 'batu_lsa' and aktiv
   and skill_key in ('gleichung_quadr_formel', 'fkt_quadr_normalform', 'fkt_quadr_nullstellen', 'geo_kreis_flaeche',
                     'geo_kreis_umfang', 'zahl_potenz_rechnen');
