-- T5.1 Pruefragen fuer den Coach in der Session (Entscheidung Rasit 12.10.2026, Paket T5; offene-punkte-t4 Punkt 1).
--
-- skill_pruefung_lesen(skill) kennt keine Session und liefert nur 'freigegeben'. Im Testlauf legt
-- pruefung_aufs_tablet seit T4 aber auch eine Pruefrage im Entwurf aufs Tablet (session_pruefung_frage_sitzung);
-- der Coach sah dazu keine Erwartung und kein Kriterium.
--
-- Neu: skill_pruefung_session(session, skill), die Spalten von skill_pruefung_lesen plus freigegeben boolean
-- (status = 'freigegeben', serverseitig; den Status selbst bekommt der Coach nicht; Rasit 14.10.).
-- Zugriff: Coach dieser Session oder Admin (session_coach_pruefen, wie die uebrigen Coach-Funktionen der Session,
-- Entscheidung 26), sonst 42501; unbekannte Session P0002 wie dort.
-- Echte Session: genau 'freigegeben' (gleiche Zeilen wie skill_pruefung_lesen, freigegeben immer true).
-- Testlauf: jede Pruefrage des Skills, also dieselbe Menge und Reihenfolge wie session_pruefung_frage_sitzung, die
-- pruefung_aufs_tablet als Vorbedingung nimmt und deren erste Zeile das Tablet zeigt (T4: Pruefragen haben keinen
-- Ausschluss, testlauf_inhalt_sichtbar uebertragen heisst „jede“). Die erste Zeile ist die Frage auf dem Tablet.
-- skill_pruefung_lesen bleibt unveraendert.

create or replace function public.skill_pruefung_session(p_session_id uuid, p_skill_key text)
 returns table(id uuid, skill_key text, frage text, erwartung text, kriterium text, quelle text, freigegeben boolean)
 language plpgsql
 stable security definer
 set search_path to 'public', 'pg_temp'
as $function$
#variable_conflict use_column
declare
  v_test boolean := (public.session_coach_pruefen(p_session_id, 'skill_pruefung_session')).testlauf;
begin
  return query
    select p.id, p.skill_key, p.frage, p.erwartung, p.kriterium, p.quelle, p.status = 'freigegeben'
      from public.skill_pruefung p
     where p.skill_key = p_skill_key
       and (p.status = 'freigegeben' or coalesce(v_test, false))
     order by (p.status = 'freigegeben') desc, (p.status = 'geprueft') desc, p.angelegt, p.id;
end;
$function$;

revoke all on function public.skill_pruefung_session(uuid, text) from public, anon, authenticated;
grant execute on function public.skill_pruefung_session(uuid, text) to authenticated;
