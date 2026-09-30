-- Abnahme Schuelerakte S1, Teil C: Coach-Rechte.
-- (Migrationen 20260929100100_schuelerakte_akte.sql, 20260929100200_coach_rls.sql)
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/coach_rls_test.sql
--
-- Laeuft in EINER Transaktion und endet mit ROLLBACK. Zuerst legt sie als
-- Datenbank-Eigentuemer Testfaelle an (Kinder ohne Konto, Leads, Vertraege,
-- Reports, Notizen, eine Session), dann prueft sie mit gesetzten Claims als
-- Coach und als Admin (Rolle authenticated, wie ueber die API). Nichts davon
-- bleibt stehen.
--
-- Vorbedingung: je ein Profil mit role = 'coach' und role = 'admin'.
-- Abnahme: die Spalte `ergebnis` enthaelt ausschliesslich OK.
--
-- Testfaelle (Datum relativ zu heute):
--   A  aktive Akte: laufender Vertrag, Report, sichtbare + ausgeblendete Notiz,
--      eine Session des Coaches
--   B  ruhende Akte: Vertrag seit 10 Tagen ausgelaufen, Report, Notiz
--   C  Luecke vor unterschriebenem Folgevertrag (im Widerruf, Beginn naechster Monat)
--   D  Luecke vor widerrufenem Folgevertrag

begin;

create temp table ergebnis (nr integer, pruefung text, ist text, soll text) on commit drop;
grant all on ergebnis to authenticated;

do $$
declare
  v_coach  uuid;
  v_admin  uuid;
  a uuid := gen_random_uuid();  b uuid := gen_random_uuid();
  c uuid := gen_random_uuid();  d uuid := gen_random_uuid();
  la uuid := gen_random_uuid(); lb uuid := gen_random_uuid();
  lc uuid := gen_random_uuid(); ld uuid := gen_random_uuid();
  c_alt uuid := gen_random_uuid(); d_alt uuid := gen_random_uuid();
  v_session uuid := gen_random_uuid();
  v_monat date := date_trunc('month', current_date)::date;
  v_alt_beginn date := date_trunc('month', current_date - 400)::date;
  v_folge date := (date_trunc('month', current_date) + interval '1 month')::date;
  v_n integer;
  v_t text;
begin
  select id into v_coach from public.profiles where role = 'coach' order by created_at limit 1;
  select id into v_admin from public.profiles where role = 'admin' order by created_at limit 1;
  if v_coach is null or v_admin is null then
    insert into ergebnis values (0, 'Vorbedingung: Coach- und Admin-Profil vorhanden', 'fehlt', 'vorhanden');
    return;
  end if;
  insert into ergebnis values (0, 'Vorbedingung: Coach- und Admin-Profil vorhanden', 'vorhanden', 'vorhanden');

  -- ---------------------------------------------------------------- Testfaelle
  insert into public.leads (id, full_name, first_name, contact_email, status) values
    (la, 'ZZ Test A', 'Anna', 'a@example.invalid', 'converted'),
    (lb, 'ZZ Test B', 'Ben',  'b@example.invalid', 'converted'),
    (lc, 'ZZ Test C', 'Cem',  'c@example.invalid', 'converted'),
    (ld, 'ZZ Test D', 'Dana', 'd@example.invalid', 'converted');
  insert into public.students (id, class_level) values (a, 9), (b, 9), (c, 10), (d, 8);
  update public.leads set converted_student_id = a where id = la;
  update public.leads set converted_student_id = b where id = lb;

  insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, verlaengerung_status,
                                widerruf_bis, widerrufen_am) values
    -- A: laeuft seit zwei Monaten
    (la, 'abgeschlossen', 'aktiv', a, 57, 12, (v_monat - interval '2 months')::date, current_date + 200,
     current_date - 70, null, null, null),
    -- B: seit 10 Tagen ausgelaufen
    (lb, 'abgeschlossen', 'aktiv', b, 57, 12, v_alt_beginn, current_date - 10, v_alt_beginn - 5, null, null, null);

  insert into public.vertraege (id, lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, verlaengerung_status) values
    (c_alt, lc, 'abgeschlossen', 'aktiv', c, 57, 12, v_alt_beginn, current_date - 5, v_alt_beginn - 5, 'verlaengert'),
    (d_alt, ld, 'abgeschlossen', 'aktiv', d, 57, 12, v_alt_beginn, current_date - 5, v_alt_beginn - 5, 'verlaengert');
  insert into public.vertraege (lead_id, status, vertrag_status, student_id, vorgaenger_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am, widerruf_bis, widerrufen_am) values
    (lc, 'abgeschlossen', 'im_widerruf', c, c_alt, 57, 12, v_folge, (v_folge + interval '1 year')::date - 1,
     current_date - 1, v_folge + 14, null),
    (ld, 'abgeschlossen', 'widerrufen',  d, d_alt, 57, 12, v_folge, (v_folge + interval '1 year')::date - 1,
     current_date - 1, v_folge + 14, current_date - 1);

  insert into public.eltern_reports (student_id, nr, art) values (a, 1, 'lernstandsanalyse'), (b, 1, 'lernstandsanalyse');
  insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle) values
    (a, 'lernen', 'A sichtbar', v_admin, 'admin'),
    (b, 'lernen', 'B ruhend', v_admin, 'admin');
  insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle,
                                       ausgeblendet_am, ausgeblendet_von, ausgeblendet_grund) values
    (a, 'verhalten', 'A ausgeblendet', v_admin, 'admin', now(), v_admin, 'Test');

  insert into public.coaching_sessions (id, coach_id, scheduled_at, status) values (v_session, v_coach, now(), 'active');
  insert into public.session_students (session_id, student_id) values (v_session, a);

  -- ---------------------------------------------------------------- Zustand vs. hat_zugang
  insert into ergebnis values
    (1, 'C Luecke vor unterschriebenem Folgevertrag: akte_aktiv / hat_zugang',
        public.akte_aktiv(c)::text || ' / ' || public.hat_zugang(c)::text, 'true / true'),
    -- Seit P5b (20260930100100) traegt die Bruecke von hat_zugang keinen widerrufenen Folgevertrag mehr.
    (2, 'D Luecke vor widerrufenem Folgevertrag: akte_aktiv / hat_zugang',
        public.akte_aktiv(d)::text || ' / ' || public.hat_zugang(d)::text, 'false / false');

  -- ---------------------------------------------------------------- als Coach
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select count(*) into v_n from public.leads;
  insert into ergebnis values (10, 'Coach: Zeilen aus leads', v_n::text, '0');
  select count(*) into v_n from public.parent_student;
  insert into ergebnis values (11, 'Coach: Zeilen aus parent_student', v_n::text, '0');
  select count(*) into v_n from public.vertraege;
  insert into ergebnis values (12, 'Coach: Zeilen aus vertraege', v_n::text, '0');
  select count(*) into v_n from public.vertraege_aktuell;
  insert into ergebnis values (13, 'Coach: Zeilen aus vertraege_aktuell', v_n::text, '0');
  select (select count(*) from public.vertrag_bankdaten) + (select count(*) from public.vertrag_dateien)
       + (select count(*) from public.vertrag_dokumente) + (select count(*) from public.vertrag_einstellungen)
       + (select count(*) from public.vertrag_unterschriften) + (select count(*) from public.vertrag_versand)
       + (select count(*) from public.vertrag_zustimmungen)
    into v_n;
  insert into ergebnis values (14, 'Coach: Zeilen aus vertrag_* (alle sieben)', v_n::text, '0');
  select count(*) into v_n from public.profiles where role = 'parent';
  insert into ergebnis values (15, 'Coach: Eltern-Profile sichtbar', v_n::text, '0');
  select count(*) into v_n from public.profiles where id = v_coach;
  insert into ergebnis values (16, 'Coach: eigenes Profil sichtbar', v_n::text, '1');

  select string_agg(x, ',' order by x) into v_t from (
    select case id when a then 'A' when b then 'B' when c then 'C' when d then 'D' end x
      from public.students where id in (a, b, c, d)) s;
  insert into ergebnis values (20, 'Coach: students sichtbar (nur aktive Akten)', coalesce(v_t, '-'), 'A,C');
  select string_agg(x, ',' order by x) into v_t from (
    select case student_id when a then 'A' when b then 'B' when c then 'C' when d then 'D' end x
      from public.schuelerakten where student_id in (a, b, c, d)) s;
  insert into ergebnis values (21, 'Coach: schuelerakten', coalesce(v_t, '-'), 'A,C');
  select string_agg(x, ',' order by x) into v_t from (
    select case student_id when a then 'A' when b then 'B' when c then 'C' when d then 'D' end x
      from public.board_schueler() where student_id in (a, b, c, d)) s;
  insert into ergebnis values (22, 'Coach: board_schueler', coalesce(v_t, '-'), 'A,C');

  begin
    select e.art into v_t from public.einheiten_stand(a) e;
    insert into ergebnis values (30, 'Coach: einheiten_stand aktive Akte', v_t, 'laufend');
  exception when others then
    insert into ergebnis values (30, 'Coach: einheiten_stand aktive Akte', 'Fehler ' || sqlstate, 'laufend');
  end;
  begin
    perform * from public.einheiten_stand(b);
    insert into ergebnis values (31, 'Coach: einheiten_stand ruhende Akte', 'kein Fehler', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (31, 'Coach: einheiten_stand ruhende Akte', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  begin
    select e.art into v_t from public.einheiten_stand(c) e;
    insert into ergebnis values (32, 'Coach: einheiten_stand Luecke vor Folgevertrag', v_t, 'vorher');
  exception when others then
    insert into ergebnis values (32, 'Coach: einheiten_stand Luecke vor Folgevertrag', 'Fehler ' || sqlstate, 'vorher');
  end;

  select count(*) into v_n from public.eltern_reports where student_id = a;
  insert into ergebnis values (40, 'Coach: eltern_reports aktive Akte lesbar', v_n::text, '1');
  select count(*) into v_n from public.eltern_reports where student_id = b;
  insert into ergebnis values (41, 'Coach: eltern_reports ruhende Akte nicht lesbar', v_n::text, '0');
  begin
    update public.eltern_reports set pdf_pfad = 'x.pdf' where student_id = a;
    get diagnostics v_n = row_count;
    insert into ergebnis values (42, 'Coach: eltern_reports aendern (Zeilen)', v_n::text, '0');
  exception when others then
    insert into ergebnis values (42, 'Coach: eltern_reports aendern (Zeilen)', 'Fehler ' || sqlstate, '0');
  end;

  select string_agg(text, ',' order by text) into v_t from public.schueler_notizen where student_id in (a, b);
  insert into ergebnis values (50, 'Coach: Notizen sichtbar (ohne ausgeblendete, ohne ruhende)', coalesce(v_t, '-'), 'A sichtbar');
  begin
    perform public.notiz_anlegen(b, 'lernen', 'Coach in ruhender Akte');
    insert into ergebnis values (51, 'Coach: notiz_anlegen in ruhender Akte', 'angenommen', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (51, 'Coach: notiz_anlegen in ruhender Akte', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  begin
    perform public.notiz_anlegen(a, 'organisatorisch', 'Kommt ab naechster Woche dienstags.');
    insert into ergebnis values (52, 'Coach: notiz_anlegen in aktiver Akte', 'angenommen', 'angenommen');
  exception when others then
    insert into ergebnis values (52, 'Coach: notiz_anlegen in aktiver Akte', 'Fehler ' || sqlstate, 'angenommen');
  end;
  begin
    perform public.notiz_ausblenden((select id from public.schueler_notizen where student_id = a limit 1), 'Test');
    insert into ergebnis values (53, 'Coach: notiz_ausblenden', 'angenommen', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (53, 'Coach: notiz_ausblenden', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;

  -- Sessionplan und Anwesenheit (eigene Session)
  select count(*) into v_n from public.session_students where session_id = v_session;
  insert into ergebnis values (60, 'Coach: Teilnehmer der eigenen Session lesbar', v_n::text, '1');
  select count(*) into v_n from public.session_students ss
    join public.students s on s.id = ss.student_id where ss.session_id = v_session;
  insert into ergebnis values (61, 'Coach: Kind der eigenen Session in students lesbar', v_n::text, '1');
  select attendance into v_t from public.session_students where session_id = v_session;
  insert into ergebnis values (62, 'Neue Teilnahme startet als', v_t, 'planned');
  update public.session_students set attendance = 'unexcused' where session_id = v_session and student_id = a;
  get diagnostics v_n = row_count;
  insert into ergebnis values (63, 'Coach: Anwesenheit "nicht erschienen" setzen (Zeilen)', v_n::text, '1');
  select e.verbraucht::text into v_t from public.einheiten_stand(a) e;
  insert into ergebnis values (64, 'unexcused verbraucht eine Einheit (verbraucht)', v_t, '1');
  begin
    update public.session_students set attendance = 'absent' where session_id = v_session and student_id = a;
    insert into ergebnis values (65, 'Alter Wert absent wird abgewiesen', 'angenommen', 'Fehler 23514');
  exception when others then
    insert into ergebnis values (65, 'Alter Wert absent wird abgewiesen', 'Fehler ' || sqlstate, 'Fehler 23514');
  end;

  -- LSA-Report: Rufname ueber converted_student_id, ohne direkten leads-Zugriff
  select k.rufname into v_t from public.lsa_lead_kontext(array[a]) k;
  insert into ergebnis values (70, 'Coach: lsa_lead_kontext Rufname (Rueckweg converted_student_id)', coalesce(v_t, '-'), 'Anna');
  select count(*) into v_n from public.lsa_lead_kontext(array[b]) k;
  insert into ergebnis values (71, 'Coach: lsa_lead_kontext ruhende Akte', v_n::text, '0');

  -- ---------------------------------------------------------------- als Admin
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  select string_agg(x, ',' order by x) into v_t from (
    select case student_id when a then 'A' when b then 'B' when c then 'C' when d then 'D' end || ':' || zustand x
      from public.schuelerakten where student_id in (a, b, c, d)) s;
  insert into ergebnis values (80, 'Admin: schuelerakten mit Zustand', coalesce(v_t, '-'), 'A:aktiv,B:ruhend,C:aktiv,D:ruhend');
  select (ruhend_seit = current_date - 10)::text into v_t from public.schuelerakten where student_id = b;
  insert into ergebnis values (81, 'Admin: ruhend_seit = Vertragsende', coalesce(v_t, '-'), 'true');
  select (ruhend_seit = current_date - 5)::text into v_t from public.schuelerakten where student_id = d;
  insert into ergebnis values (81, 'Admin: D ruhend_seit = Ende des Vorgaengers (Folgevertrag widerrufen)', coalesce(v_t, '-'), 'true');
  select count(*) into v_n from public.leads where id in (la, lb, lc, ld);
  insert into ergebnis values (82, 'Admin: leads unveraendert lesbar', v_n::text, '4');
  select count(*) into v_n from public.schueler_notizen where student_id in (a, b);
  insert into ergebnis values (83, 'Admin: alle Notizen inkl. ausgeblendeter', v_n::text, '4');
  select e.art into v_t from public.einheiten_stand(b) e;
  insert into ergebnis values (84, 'Admin: einheiten_stand ruhende Akte', v_t, 'keiner');
  begin
    update public.eltern_reports set art = 'zwischenbericht' where student_id = a;
    insert into ergebnis values (85, 'Admin: versendeter Report unveraenderlich', 'geaendert', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (85, 'Admin: versendeter Report unveraenderlich', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  update public.eltern_reports set pdf_pfad = 'reports/a1.pdf' where student_id = a;
  get diagnostics v_n = row_count;
  insert into ergebnis values (86, 'Admin: pdf_pfad einmalig setzen (Zeilen)', v_n::text, '1');
  begin
    update public.eltern_reports set pdf_pfad = 'reports/a1-neu.pdf' where student_id = a;
    insert into ergebnis values (87, 'Admin: pdf_pfad ein zweites Mal', 'geaendert', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (87, 'Admin: pdf_pfad ein zweites Mal', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  select (r ->> 'nr') into v_t from public.eltern_report_eintragen(a, 'zwischenbericht',
    p_kernaussagen => '{"Mathematik": "Brueche sicher, Gleichungen noch nicht sicher."}'::jsonb) r;
  insert into ergebnis values (88, 'Admin: eltern_report_eintragen vergibt naechste Nummer', coalesce(v_t, '-'), '2');
  select public.notiz_gesundheit_entfernen((select id from public.schueler_notizen where student_id = b limit 1)) into v_t;
  select coalesce(text, 'NULL') || ' / ' || entfernt_grund into v_t from public.schueler_notizen where student_id = b;
  insert into ergebnis values (89, 'Admin: Gesundheitsangabe entfernt (text / Grund)', v_t, 'NULL / gesundheitsangabe');

  execute 'reset role';
end;
$$;

select nr, pruefung, ist, soll,
       case when ist is not distinct from soll then 'OK' else 'FEHLER' end as ergebnis
  from ergebnis
 order by nr;

rollback;
