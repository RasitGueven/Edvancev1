-- PRUEFUNG: Schuelerakte S1 — was vertrag_abschliessen jetzt zusaetzlich tut
-- (Migration 20260929100100_schuelerakte_akte.sql, Abschnitt 8).
--
-- Laeuft komplett in einer Transaktion und rollt am Ende zurueck. Testdaten
-- tragen das Praefix ZZ_. Claims MIT Rolle (siehe vertrag_abschluss.PRUEFUNG.sql).
--
-- Gegen Produktion ausfuehren, nachdem die Migration eingespielt ist:
--     psql "$DATABASE_URL" -f supabase/checks/schuelerakte_abschluss.PRUEFUNG.sql
--
-- Geprueft:
--   1  Erstvertrag mit LSA  -> eltern_reports Nr. 1 = lernstandsanalyse, LSA verknuepft,
--                              freigegeben_von / versendet_am / pdf_pfad NULL
--   2  Schule               -> students.schule_id aus dem Vertrag
--   3  Rueckweg             -> lsa_lead_kontext findet den Lead ueber converted_student_id
--   4  Idempotenz           -> zweiter Aufruf legt keinen zweiten Report an
--   5  Folgevertrag         -> neues Fach in student_subjects, kein zweiter Report 1
--   6  eltern_report_eintragen -> naechste Nummer 2, unveraenderlich

begin;

do $$
declare
  v_admin   uuid;
  v_kind    uuid := gen_random_uuid();
  v_lead    uuid;
  v_prov    uuid;
  v_lsa     uuid;
  v_schule  uuid;
  v_premium uuid;
  v_mathe   uuid;
  v_deutsch uuid;
  v1        uuid;
  v2        uuid;
  v_alle    jsonb;
  v_n       integer;
  v_text    text;
  v_ok      boolean;
  r         record;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden — Pruefung braucht eines';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);

  select id into v_premium from tiers where name = 'Premium';
  insert into subjects (name) select 'ZZ_Mathe'   where not exists (select 1 from subjects where name = 'ZZ_Mathe');
  insert into subjects (name) select 'ZZ_Deutsch' where not exists (select 1 from subjects where name = 'ZZ_Deutsch');
  select id into v_mathe   from subjects where name = 'ZZ_Mathe';
  select id into v_deutsch from subjects where name = 'ZZ_Deutsch';
  insert into schulen (name, ort) values ('ZZ_Gymnasium', 'Koeln') returning id into v_schule;
  select jsonb_agg(jsonb_build_object('schluessel', schluessel, 'version', version, 'akzeptiert_at', now()))
    into v_alle from vertrag_dokumente where aktiv and pflicht;

  insert into auth.users (id, email, instance_id, aud, role) values
    (v_kind, 'zz_akte_kind@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  -- Lead mit provisorischem Schueler und abgeschlossener LSA
  insert into leads (full_name, first_name, status, contact_email, class_level, subjects, consent_dsgvo_at,
                     next_exam_topic)
  values ('ZZ_Akte Kind', 'ZZ_Akte', 'lsa_fertig', 'zz_akte_eltern@edvance.invalid', 9, array['ZZ_Mathe'], now(),
          'ZZ_Lineare Funktionen')
  returning id into v_lead;
  perform set_config('edvance.allow_provisional', '1', true);
  insert into students (profile_id, class_level, is_provisional, lead_id)
  values (null, 9, true, v_lead) returning id into v_prov;
  perform set_config('edvance.allow_provisional', '', true);
  insert into lsa_sessions (student_id, subject, grade, status, completed_at)
  values (v_prov, 'Mathematik', 9, 'completed', now()) returning id into v_lsa;

  -- ========================================================================== 1
  v1 := public.vertrag_starten(v_lead);
  update vertraege
     set tier_id = v_premium, laufzeit_monate = 12, vertragsbeginn = date '2027-09-01',
         eltern_vorname = 'ZZ_Eltern', eltern_nachname = 'Akte', strasse = 'Teststr', hausnummer = '1',
         plz = '50667', ort = 'Koeln', eltern_telefon = '0221 1', eltern_email = 'zz_akte_eltern@edvance.invalid',
         kind_vorname = 'ZZ_Akte', kind_nachname = 'Kind', kind_geburtsdatum = date '2012-05-04',
         klasse = 9, fach = 'ZZ_Mathe', schule_id = v_schule
   where id = v1;
  insert into vertrag_bankdaten (vertrag_id, iban) values (v1, 'DE89370400440532013000');
  perform public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                      p_student_uid => v_kind, p_student_email => 'zz_akte_kind@edvance.invalid');

  select count(*) into v_n from eltern_reports where student_id = v_prov;
  assert v_n = 1, '1: erwartet genau einen Report, sind ' || v_n;
  select * into r from eltern_reports where student_id = v_prov;
  assert r.nr = 1 and r.art = 'lernstandsanalyse' and r.lsa_session_id = v_lsa,
    '1: Report 1 ist nicht die LSA: ' || r.nr || ' ' || r.art;
  assert r.freigegeben_von is null and r.versendet_am is null and r.pdf_pfad is null,
    '1: Felder, die es heute nicht gibt, sind nicht NULL';
  raise notice '1  ok  Erstvertrag: LSA ist Report 1';

  -- ========================================================================== 2
  select schule_id into v_text from students where id = v_prov;
  assert v_text = v_schule::text, '2: students.schule_id nicht aus dem Vertrag gesetzt';
  select count(*) into v_n from student_subjects where student_id = v_prov and subject_id = v_mathe;
  assert v_n = 1, '2: Fach des Erstvertrags fehlt';
  raise notice '2  ok  Schule und Fach aus dem Erstvertrag';

  -- ========================================================================== 3
  select lead_id is null into v_ok from students where id = v_prov;
  assert v_ok, '3: Vorbedingung: students.lead_id ist nach dem Abschluss NULL';
  select k.rufname || ' / ' || k.next_exam_topic into v_text from public.lsa_lead_kontext(array[v_prov]) k;
  assert v_text = 'ZZ_Akte / ZZ_Lineare Funktionen', '3: Rueckweg ueber converted_student_id: ' || coalesce(v_text, 'nichts');
  raise notice '3  ok  lsa_lead_kontext findet den Lead nach der Umwandlung';

  -- ========================================================================== 4
  perform public.vertrag_abschliessen(v1, 'vor_ort', v_alle, 'data:a', 'data:b',
                                      p_student_uid => v_kind, p_student_email => 'zz_akte_kind@edvance.invalid');
  select count(*) into v_n from eltern_reports where student_id = v_prov;
  assert v_n = 1, '4: zweiter Aufruf hat einen Report angelegt';
  raise notice '4  ok  idempotent';

  -- ========================================================================== 5
  v2 := public.vertrag_folgevertrag_starten(v1);
  update vertraege set vertragsbeginn = date '2028-09-01', fach = 'ZZ_Deutsch' where id = v2;
  perform public.vertrag_abschliessen(v2, 'vor_ort', v_alle, 'data:a', 'data:b');
  select count(*) into v_n from student_subjects where student_id = v_prov and subject_id in (v_mathe, v_deutsch);
  assert v_n = 2, '5: Fach des Folgevertrags nicht nachgezogen (' || v_n || ' von 2)';
  select count(*) into v_n from eltern_reports where student_id = v_prov;
  assert v_n = 1, '5: Folgevertrag hat einen weiteren Report 1 angelegt';
  raise notice '5  ok  Folgevertrag: Fach nachgezogen, kein zweiter Report 1';

  -- ========================================================================== 6
  select (x ->> 'nr')::integer into v_n
    from public.eltern_report_eintragen(v_prov, 'zwischenbericht', date '2027-12-01',
           '{"ZZ_Mathe": "Brueche sicher, Gleichungen noch nicht sicher."}'::jsonb) x;
  assert v_n = 2, '6: naechste Nummer ist nicht 2, sondern ' || v_n;
  v_ok := false;
  begin
    update eltern_reports set kernaussagen = '{}'::jsonb where student_id = v_prov and nr = 2;
  exception when sqlstate '42501' then v_ok := true;
  end;
  assert v_ok, '6: versendeter Report liess sich aendern';
  select count(*) into v_n from audit_log where aktion = 'eltern_report_eintragen' and actor = v_admin;
  assert v_n >= 2, '6: eltern_report_eintragen protokolliert nicht';
  raise notice '6  ok  Nummer 2, unveraenderlich, protokolliert';
end;
$$;

rollback;
