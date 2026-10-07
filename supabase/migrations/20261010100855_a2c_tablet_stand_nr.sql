-- A2c (Nachtrag aus R2): tablet_stand nennt dem wartenden Tablet seine Nummer.
-- Der Warte-Bildschirm zeigt die Tablet-Nummer schon vor der Zuweisung; bisher kam dann nur {zugewiesen: false}.
--   - Platz-Konto (platz_devices) ohne aktive Zuweisung: { zugewiesen: false, tablet_nr: <Nummer oder null> }.
--     Nur die Nummer des eigenen Geraets (profile_id = auth.uid()), sonst nichts.
--   - Alle anderen Konten (Schueler, Coach, Admin, ohne Profil): weiter nur { zugewiesen: false }.
--   - Mit Zuweisung unveraendert.
-- Grundlage: Prod-Definition (pg_get_functiondef, 07.10.2026) aus 20261009100412_a2b_tablet_lesen.
-- Signatur und Rechte bleiben (create or replace).

CREATE OR REPLACE FUNCTION public.tablet_stand()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t public.session_tablets;
  a public.session_ausgegeben;
  pa record;
begin
  select st.* into t from public.session_tablets st
    join public.coaching_sessions cs on cs.id = st.session_id and cs.status = 'active'
   where st.geraet_id = auth.uid() and st.geloest_am is null;
  if not found then
    -- A2c (Nachtrag R2): ein Platz-Konto ohne Zuweisung bekommt die Nummer des eigenen Geraets fuer den
    -- Warte-Bildschirm (null, wenn das Geraet keine hat). Alle anderen Konten: nur zugewiesen = false.
    return jsonb_build_object('zugewiesen', false)
           || coalesce((select jsonb_build_object('tablet_nr', pd.tablet_nr)
                          from public.platz_devices pd where pd.profile_id = auth.uid()), '{}'::jsonb);
  end if;
  a := public.session_aktuelle_ausgabe(t.session_id, t.student_id);
  select * into pa from public.session_pruefung_aktiv(t.session_id, t.student_id);
  return jsonb_build_object(
    'zugewiesen', true,
    'session_id', t.session_id,
    'tablet_nr', t.tablet_nr,
    'vorname', (select coalesce(l.first_name, split_part(l.full_name, ' ', 1)) from public.leads l
                 where l.id = public.session_lead_von_kind(t.student_id)),
    'phase', public.session_phase(t.session_id, t.student_id),
    'checkin_fertig', exists (select 1 from public.session_checkin c where c.session_id = t.session_id
                               and c.student_id = t.student_id and c.kind_am is not null),
    'aufgabe', case when a.id is null then null else public.lsa_question_payload(a.task_id) end,
    -- A2b (Entscheidung 31): nur Label und Frage, nie Erwartung oder Kriterium.
    'pruefung', case when pa.skill_key is null then null else jsonb_build_object(
        'skill_label', public.session_label(pa.skill_key),
        'frage', public.session_pruefung_frage(pa.skill_key)) end,
    -- A2b (Entscheidung 34): gemeistert erst nach der Bestaetigung des Coaches in dieser Session.
    'bestaetigt', coalesce((select jsonb_agg(jsonb_build_object('skill_key', l.skill_key,
                    'skill_label', public.session_label(l.skill_key), 'am', l.coach_am) order by l.coach_am)
                  from public.lernpfad l
                 where l.student_id = t.student_id and l.coach_session_id = t.session_id
                   and l.stand_coach = 'gemeistert'), '[]'::jsonb));
end;
$function$;
