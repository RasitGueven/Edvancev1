-- Abnahme P5b "Session-Platz nur mit Zugang"
-- (Migration 20260930100000_session_platz_zugang.sql).
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/session_zugang_test.sql
--
-- Laeuft in EINER Transaktion und endet mit ROLLBACK — gegen Prod ausfuehrbar
-- ohne bleibende Aenderung. Legt als Datenbank-Eigentuemer eigene Testfaelle an
-- (Admin, zwei Coaches, Kinder, Vertraege, Sessions; Praefix ZZ_), prueft dann
-- mit gesetzten Claims als Admin und als Coach (Rolle authenticated, wie ueber
-- die API). Setzt keine S1-Objekte voraus.
--
-- Abnahme: die Spalte `ergebnis` enthaelt ausschliesslich OK.
--
-- Datumsbezug (relativ zu heute, Europe/Berlin):
--   M1 = 1. des Folgemonats. Session "davor" = M1 - 1 Tag, "danach" = M1 + 5 Tage.

begin;

create temp table ergebnis (nr integer, pruefung text, ist text, soll text) on commit drop;
grant all on ergebnis to authenticated;

do $$
declare
  v_admin  uuid := gen_random_uuid();
  v_coach  uuid := gen_random_uuid();
  v_fremd  uuid := gen_random_uuid();
  k_aktiv  uuid := gen_random_uuid();   -- laufender Vertrag
  k_ohne   uuid := gen_random_uuid();   -- kein Vertrag
  k_spaet  uuid := gen_random_uuid();   -- Vertrag ab M1
  k_luecke uuid := gen_random_uuid();   -- Luecke vor unterschriebenem Folgevertrag
  k_widerr uuid := gen_random_uuid();   -- Luecke vor WIDERRUFENEM Folgevertrag
  l1 uuid := gen_random_uuid(); l2 uuid := gen_random_uuid();
  l3 uuid := gen_random_uuid(); l5 uuid := gen_random_uuid();
  v_alt2 uuid := gen_random_uuid();
  l_lsa uuid := gen_random_uuid();
  v_alt uuid := gen_random_uuid();
  v_aktiv_vertrag uuid := gen_random_uuid();
  m1 date := (date_trunc('month', current_date) + interval '1 month')::date;
  s_heute  uuid := gen_random_uuid();   -- Session des Coaches, heute
  s_davor  uuid := gen_random_uuid();   -- Session des Coaches, M1 - 1
  s_danach uuid := gen_random_uuid();   -- Session des Coaches, M1 + 5
  s_fremd  uuid := gen_random_uuid();   -- Session eines anderen Coaches, heute
  v_n integer;
  v_t text;
  v_code text;
  v_hint text;
begin
  -- ---------------------------------------------------------------- Testfaelle
  insert into auth.users (id, email, instance_id, aud, role) values
    (v_admin, 'zz_p5b_admin@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_coach, 'zz_p5b_coach@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_fremd, 'zz_p5b_fremd@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
  insert into public.profiles (id, email, role, full_name) values
    (v_admin, 'zz_p5b_admin@edvance.invalid', 'admin', 'ZZ P5b Admin'),
    (v_coach, 'zz_p5b_coach@edvance.invalid', 'coach', 'ZZ P5b Coach'),
    (v_fremd, 'zz_p5b_fremd@edvance.invalid', 'coach', 'ZZ P5b Fremdcoach')
  on conflict (id) do update set role = excluded.role;

  insert into public.leads (id, full_name, status) values
    (l1, 'ZZ_P5b Aktiv', 'converted'), (l2, 'ZZ_P5b Spaet', 'converted'), (l3, 'ZZ_P5b Luecke', 'converted'),
    (l5, 'ZZ_P5b Widerruf', 'converted');
  insert into public.students (id, class_level) values
    (k_aktiv, 9), (k_ohne, 9), (k_spaet, 9), (k_luecke, 9), (k_widerr, 9);

  insert into public.vertraege (id, lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, widerruf_bis) values
    (v_aktiv_vertrag, l1, 'abgeschlossen', 'aktiv', k_aktiv, 57, 12,
     (date_trunc('month', current_date) - interval '2 months')::date, current_date + 200, current_date - 70, null),
    (gen_random_uuid(), l2, 'abgeschlossen', 'im_widerruf', k_spaet, 57, 12,
     m1, (m1 + interval '1 year')::date - 1, current_date, m1 + 29);
  insert into public.vertraege (id, lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, verlaengerung_status) values
    (v_alt, l3, 'abgeschlossen', 'aktiv', k_luecke, 57, 12,
     date_trunc('month', current_date - 400)::date, current_date - 5, current_date - 400, 'verlaengert');
  insert into public.vertraege (lead_id, status, vertrag_status, student_id, vorgaenger_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, widerruf_bis) values
    (l3, 'abgeschlossen', 'im_widerruf', k_luecke, v_alt, 57, 12,
     m1, (m1 + interval '1 year')::date - 1, current_date - 1, m1 + 29);
  -- Wie k_luecke, aber der Folgevertrag ist widerrufen
  insert into public.vertraege (id, lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, verlaengerung_status) values
    (v_alt2, l5, 'abgeschlossen', 'aktiv', k_widerr, 57, 12,
     date_trunc('month', current_date - 400)::date, current_date - 5, current_date - 400, 'verlaengert');
  insert into public.vertraege (lead_id, status, vertrag_status, student_id, vorgaenger_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, widerruf_bis, widerrufen_am) values
    (l5, 'abgeschlossen', 'widerrufen', k_widerr, v_alt2, 57, 12,
     m1, (m1 + interval '1 year')::date - 1, current_date - 3, m1 + 29, current_date - 1);

  insert into public.coaching_sessions (id, coach_id, scheduled_at, status) values
    (s_heute,  v_coach, (current_date + time '16:00') at time zone 'Europe/Berlin', 'upcoming'),
    (s_davor,  v_coach, ((m1 - 1) + time '16:00') at time zone 'Europe/Berlin', 'upcoming'),
    (s_danach, v_coach, ((m1 + 5) + time '16:00') at time zone 'Europe/Berlin', 'upcoming'),
    (s_fremd,  v_fremd, (current_date + time '17:00') at time zone 'Europe/Berlin', 'upcoming');

  -- Lead ohne Vertrag mit Einwilligung, fuer die LSA
  insert into public.leads (id, full_name, first_name, status, consent_dsgvo_at, class_level, subjects)
  values (l_lsa, 'ZZ_P5b LSA', 'ZZ_LSA', 'new', now(), 8, array['Mathematik']);

  -- ---------------------------------------------------------------- als Admin
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  begin
    insert into public.session_students (session_id, student_id) values (s_heute, k_aktiv);
    insert into ergebnis values (1, 'Admin: Kind mit laufendem Vertrag eintragen', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (1, 'Admin: Kind mit laufendem Vertrag eintragen', 'Fehler ' || sqlstate, 'klappt');
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_heute, k_ohne);
    insert into ergebnis values (2, 'Admin: Kind ohne Vertrag eintragen', 'klappt', 'Fehler ZG001');
  exception when others then
    get stacked diagnostics v_code = returned_sqlstate, v_t = message_text, v_hint = pg_exception_hint;
    insert into ergebnis values (2, 'Admin: Kind ohne Vertrag eintragen', 'Fehler ' || v_code, 'Fehler ZG001');
    insert into ergebnis values (3, 'Fehlertext',
      v_t, 'Kein laufender Vertrag am ' || to_char(current_date, 'DD.MM.YYYY') || ' — Platz kann nicht vergeben werden.');
    insert into ergebnis values (4, 'Hint fuer die Oberflaeche', v_hint, 'datum:' || to_char(current_date, 'YYYY-MM-DD'));
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_davor, k_spaet);
    insert into ergebnis values (5, 'Vertrag ab M1: Session davor (M1-1)', 'klappt', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (5, 'Vertrag ab M1: Session davor (M1-1)', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_danach, k_spaet);
    insert into ergebnis values (6, 'Vertrag ab M1: Session danach (M1+5)', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (6, 'Vertrag ab M1: Session danach (M1+5)', 'Fehler ' || sqlstate, 'klappt');
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_heute, k_luecke);
    insert into ergebnis values (7, 'Luecke vor unterschriebenem Folgevertrag', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (7, 'Luecke vor unterschriebenem Folgevertrag', 'Fehler ' || sqlstate, 'klappt');
  end;

  insert into ergebnis values (12, 'hat_zugang in der Luecke vor widerrufenem Folgevertrag',
    public.hat_zugang(k_widerr)::text, 'false');
  begin
    insert into public.session_students (session_id, student_id) values (s_heute, k_widerr);
    insert into ergebnis values (13, 'Luecke vor widerrufenem Folgevertrag eintragen', 'klappt', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (13, 'Luecke vor widerrufenem Folgevertrag eintragen', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  -- Session verschieben (Trigger auf coaching_sessions.scheduled_at)
  begin
    update public.coaching_sessions set scheduled_at = scheduled_at + interval '30 minutes' where id = s_heute;
    insert into ergebnis values (14, 'Session am selben Tag spaeter legen', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (14, 'Session am selben Tag spaeter legen', 'Fehler ' || sqlstate, 'klappt');
  end;
  begin
    update public.coaching_sessions set scheduled_at = scheduled_at + interval '300 days' where id = s_heute;
    insert into ergebnis values (15, 'Admin: Session hinter das Vertragsende verschieben', 'klappt', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (15, 'Admin: Session hinter das Vertragsende verschieben', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  -- Verschieben per UPDATE ist ebenfalls geprueft
  begin
    update public.session_students set session_id = s_davor where session_id = s_danach and student_id = k_spaet;
    insert into ergebnis values (8, 'UPDATE session_id in eine Session vor Vertragsbeginn', 'klappt', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (8, 'UPDATE session_id in eine Session vor Vertragsbeginn', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  -- Auswahlliste
  select string_agg(x, ',' order by x) into v_t from (
    select case k when k_aktiv then 'aktiv' when k_ohne then 'ohne' when k_spaet then 'spaet' when k_luecke then 'luecke' end x
      from public.session_platz_kandidaten(s_davor) k where k in (k_aktiv, k_ohne, k_spaet, k_luecke)) z;
  insert into ergebnis values (9, 'Auswahlliste Session davor', coalesce(v_t, '-'), 'aktiv,luecke');
  select string_agg(x, ',' order by x) into v_t from (
    select case k when k_aktiv then 'aktiv' when k_ohne then 'ohne' when k_spaet then 'spaet' when k_luecke then 'luecke' end x
      from public.session_platz_kandidaten(s_danach) k where k in (k_aktiv, k_ohne, k_spaet, k_luecke)) z;
  insert into ergebnis values (10, 'Auswahlliste Session danach', coalesce(v_t, '-'), 'aktiv,luecke,spaet');

  -- LSA fuer einen Lead ohne Vertrag bleibt moeglich (kein session_students-Bezug).
  -- Fach/Klasse der juengsten abgeschlossenen LSA: dafuer gibt es nachweislich
  -- einen Item-Pool. Ohne jeden Pool (leere Datenbank) scheitert lsa_start mit
  -- P0002 — dann legt der Test die Sitzung so an wie lead_lsa_freigeben
  -- (provisorisches Kind + lsa_sessions) und zeigt den Weg in der Spalte ist.
  declare
    v_fach   text := 'Mathematik';
    v_klasse integer := 8;
    v_weg    text := 'lead_lsa_freigeben';
    v_prov   uuid;
  begin
    execute 'reset role';
    select l.subject, l.grade into v_fach, v_klasse from public.lsa_sessions l
     where l.status = 'completed' order by l.completed_at desc nulls last limit 1;
    v_fach := coalesce(v_fach, 'Mathematik'); v_klasse := coalesce(v_klasse, 8);
    execute 'set local role authenticated';
    begin
      perform public.lead_lsa_freigeben(l_lsa, v_klasse, v_fach);
    exception when sqlstate 'P0002' then
      execute 'reset role';
      v_weg := 'direkt, kein Item-Pool';
      perform set_config('edvance.allow_provisional', '1', true);
      insert into public.students (class_level, is_provisional, lead_id) values (v_klasse, true, l_lsa)
      returning id into v_prov;
      perform set_config('edvance.allow_provisional', '', true);
      insert into public.lsa_sessions (student_id, subject, grade, status) values (v_prov, v_fach, v_klasse, 'in_progress');
      execute 'set local role authenticated';
    end;
    execute 'reset role';
    select count(*) into v_n from public.lsa_sessions l join public.students s on s.id = l.student_id
     where s.lead_id = l_lsa;
    execute 'set local role authenticated';
    insert into ergebnis values (11, 'LSA fuer Lead ohne Vertrag (' || v_weg || ')', 'klappt, LSA-Sitzungen ' || v_n, 'klappt, LSA-Sitzungen 1');
  exception when others then
    insert into ergebnis values (11, 'LSA fuer Lead ohne Vertrag', 'Fehler ' || sqlstate || ' ' || sqlerrm, 'klappt, LSA-Sitzungen 1');
  end;

  -- ---------------------------------------------------------------- als Coach
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  begin
    insert into public.session_students (session_id, student_id) values (s_danach, k_aktiv);
    insert into ergebnis values (20, 'Coach: Kind mit Vertrag in eigene Session', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (20, 'Coach: Kind mit Vertrag in eigene Session', 'Fehler ' || sqlstate, 'klappt');
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_danach, k_ohne);
    insert into ergebnis values (21, 'Coach: Kind ohne Vertrag in eigene Session (API)', 'klappt', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (21, 'Coach: Kind ohne Vertrag in eigene Session (API)', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  begin
    insert into public.session_students (session_id, student_id) values (s_fremd, k_aktiv);
    insert into ergebnis values (22, 'Coach: in fremde Session eintragen', 'klappt', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (22, 'Coach: in fremde Session eintragen', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;

  begin
    -- s_danach traegt jetzt k_spaet (Vertrag ab M1): vor M1 verschieben geht nicht
    update public.coaching_sessions set scheduled_at = ((m1 - 1) + time '16:00') at time zone 'Europe/Berlin'
     where id = s_danach;
    get diagnostics v_n = row_count;
    insert into ergebnis values (24, 'Coach: eigene Session vor den Vertragsbeginn verschieben', 'klappt (' || v_n || ')', 'Fehler ZG001');
  exception when others then
    insert into ergebnis values (24, 'Coach: eigene Session vor den Vertragsbeginn verschieben', 'Fehler ' || sqlstate, 'Fehler ZG001');
  end;

  begin
    perform * from public.session_platz_kandidaten(s_fremd);
    insert into ergebnis values (23, 'Coach: Auswahlliste fremder Session', 'geliefert', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (23, 'Coach: Auswahlliste fremder Session', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;

  -- ---------------------------------------------------------------- Bestand bleibt bearbeitbar
  -- Kind A verliert seinen Vertrag nachtraeglich; die Anwesenheit seiner
  -- bestehenden Zeile laesst sich weiter setzen (Trigger nur fuer student_id / session_id).
  execute 'reset role';
  perform set_config('edvance.vertrag_rpc', '1', true);
  update public.vertraege set vertrag_status = 'widerrufen', widerrufen_am = current_date - 1 where id = v_aktiv_vertrag;
  perform set_config('edvance.vertrag_rpc', '', true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  begin
    update public.session_students set attendance = 'present' where session_id = s_heute and student_id = k_aktiv;
    get diagnostics v_n = row_count;
    insert into ergebnis values (30, 'Bestehende Zeile ohne Zugang: Anwesenheit setzen (Zeilen)', v_n::text, '1');
  exception when others then
    insert into ergebnis values (30, 'Bestehende Zeile ohne Zugang: Anwesenheit setzen (Zeilen)', 'Fehler ' || sqlstate, '1');
  end;

  execute 'reset role';
end;
$$;

-- Rechte: nichts davon an anon; die Trigger-Funktion an niemanden
insert into ergebnis
select 40 + row_number() over (), 'anon darf ' || f || ' nicht ausfuehren',
       has_function_privilege('anon', f, 'execute')::text, 'false'
  from unnest(array['public.session_platz_kandidaten(uuid)', 'public.session_platz_zugang(uuid,date)',
                    'public.session_platz_zugang_pruefen()']) f;
insert into ergebnis values (47, 'authenticated darf session_platz_zugang nicht ausfuehren',
  has_function_privilege('authenticated', 'public.session_platz_zugang(uuid,date)', 'execute')::text, 'false');
insert into ergebnis values (48, 'authenticated darf den Verschiebe-Trigger nicht direkt ausfuehren',
  has_function_privilege('authenticated', 'public.session_verschieben_zugang_pruefen()', 'execute')::text, 'false');
insert into ergebnis values (49, 'authenticated darf die Trigger-Funktion nicht direkt ausfuehren',
  has_function_privilege('authenticated', 'public.session_platz_zugang_pruefen()', 'execute')::text, 'false');

select nr, pruefung, ist, soll,
       case when ist is not distinct from soll then 'OK' else 'FEHLER' end as ergebnis
  from ergebnis
 order by nr;

rollback;
