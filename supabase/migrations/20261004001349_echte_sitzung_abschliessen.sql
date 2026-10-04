-- NUR NACH RUECKSPRACHE MIT RASIT einspielen (W5-b, Teil 2).
--
-- Schliesst die Sitzung 4ebe9d9c (Klasse 8, 25 Antworten vom 16.08.) ueber den
-- regulaeren Abschlussweg ab: public.lsa_finish, dieselbe Funktion, die die
-- Schueler-App am Ende einer LSA aufruft (edvance-app, lsaFinish). Sie setzt
-- status = 'completed', completed_at und result_summary. Analyse und Empfehlung:
-- docs/themen/verwaiste-sitzungen.md.
--
-- lsa_finish prueft lsa_may_act_for (Coach/Admin oder der Schueler selbst ueber
-- auth.uid()). Ohne JWT schlaegt sie mit 42501 fehl, deshalb leiht sich der Block
-- transaktionslokal die Identitaet eines Admin-Profils, wie die PRUEFUNG-Skripte.
--
-- Seiteneffekte (geprueft 04.10.): keine Mail, kein Report — Elternreports
-- entstehen nur ueber die Edge Function generate_parent_report bzw. von Hand.
-- lsa_session_lead_fertig_trg aendert nur Leads auf 'lsa_freigegeben', dieser
-- Lead steht auf 'rejected'. lsa_session_platz_release_trg findet keinen
-- offenen Platz.
--
-- Im CI-Neuaufbau (leere DB) gibt es die Sitzung nicht: der Block tut nichts.
-- Ein zweiter Lauf auch nicht (nur bei status = 'in_progress').
do $$
declare
  v_sid   constant uuid := '4ebe9d9c-e186-40eb-b6a5-9d7e9fcef1f5';
  v_admin uuid;
  v_sum   jsonb;
begin
  if not exists (select 1 from lsa_sessions where id = v_sid and status = 'in_progress') then
    raise notice 'Sitzung % nicht offen, nichts zu tun', v_sid;
    return;
  end if;

  select id into v_admin from profiles where role = 'admin' order by id limit 1;
  if v_admin is null then raise exception 'kein Admin-Profil fuer lsa_finish'; end if;
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  v_sum := public.lsa_finish(v_sid);

  perform set_config('request.jwt.claims', '', true);
  raise notice 'Sitzung % abgeschlossen: % Aufgaben, % Datenpunkte',
    v_sid, v_sum ->> 'answered', v_sum ->> 'answered_parts';
end $$;
