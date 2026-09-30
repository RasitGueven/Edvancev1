-- Testakten fuer die Screenshots der Schuelerakte (S2/S2b).
--
-- Legt fuenf Kinder mit Vertraegen und vergangenen Anwesenheiten an, sodass am
-- Tag des Einspielens genau diese Zustaende entstehen:
--   ZZ_S2B Mia Plan       Klasse 8   im Plan
--   ZZ_S2B Efe Leicht     Klasse 9   leicht im Rueckstand   (+ ausgeblendete und entfernte Notiz)
--   ZZ_S2B Elif Deutlich  Klasse 9   deutlich im Rueckstand
--   ZZ_S2B Lina Startet   Klasse 10  Vertrag startet noch (Beginn naechster Monat)
--   ZZ_S2B Ben Ruhend     Klasse 10  ruhend (Vertrag ausgelaufen)
-- Die Zustaende haengen am Datum: die Zahl der Anwesenheiten wird beim
-- Einspielen aus einheiten_rechnung() bestimmt. Mit jeder Woche waechst der
-- Rueckstand (gut eine Einheit pro Woche) — fuer Screenshots innerhalb von
-- etwa einer Woche verwenden, danach Teardown und neu einspielen.
--
-- Kennung: leads.full_name beginnt mit 'ZZ_S2B ', coaching_sessions.room =
-- 'ZZ_S2B'. Alles andere haengt an diesen Zeilen. Entfernen mit
-- tools/seed/zz_schuelerakten_teardown.sql.
--
-- Sessions liegen nur an Betriebstagen innerhalb laufender Vertraege — der
-- P5b-Trigger (session_platz_zugang) prueft auch hier. Coach der Sessions ist
-- der Test-Coach zz_testcoach@edvance.invalid, falls es ihn gibt, sonst keiner.
--
-- Ausfuehren:  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -1 -f tools/seed/zz_schuelerakten_seed.sql

do $$
declare
  c_marke  constant text := 'ZZ_S2B';
  v_coach  uuid;
  v_heute  date := (now() at time zone 'Europe/Berlin')::date;
  v_monat  date := date_trunc('month', (now() at time zone 'Europe/Berlin'))::date;
  r        record;
  v_lead   uuid;
  v_kind   uuid;
  v_beginn date;
  v_ende   date;
  v_soll   numeric;
  v_n      integer;
  v_tag    date;
  v_i      integer;
  v_sess   uuid;
begin
  if exists (select 1 from public.leads where full_name like c_marke || ' %') then
    raise exception 'Seed %: es gibt schon Testakten — erst tools/seed/zz_schuelerakten_teardown.sql', c_marke;
  end if;

  select p.id into v_coach from public.profiles p
   where p.email = 'zz_testcoach@edvance.invalid' and p.role = 'coach';

  for r in
    select * from (values
      -- vorname, nachname, klasse, art, monate_zurueck, ziel_rueckstand
      -- Ziele mittig in den Ampelbaendern: der Rueckstand waechst um gut eine
      -- Einheit pro Woche, so halten die Zustaende etwa eine Woche.
      ('Mia',  'Plan',     8,  'laufend', 3, -0.5),
      ('Efe',  'Leicht',   9,  'laufend', 4, 2.2),
      ('Elif', 'Deutlich', 9,  'laufend', 6, 6.5),
      ('Lina', 'Startet',  10, 'vorher',  0, null),
      ('Ben',  'Ruhend',   10, 'ruhend',  0, null)
    ) as t(vorname, nachname, klasse, art, monate_zurueck, ziel)
  loop
    insert into public.leads (full_name, first_name, status, class_level)
    values (c_marke || ' ' || r.vorname || ' ' || r.nachname, c_marke || ' ' || r.vorname, 'converted', r.klasse)
    returning id into v_lead;
    insert into public.students (class_level) values (r.klasse) returning id into v_kind;
    update public.leads set converted_student_id = v_kind where id = v_lead;

    if r.art = 'laufend' then
      v_beginn := (v_monat - make_interval(months => r.monate_zurueck))::date;
      v_ende   := (v_beginn + interval '12 months')::date - 1;
      insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                    vertragsbeginn, vertrag_ende, abgeschlossen_am, klasse,
                                    kind_vorname, kind_nachname)
      values (v_lead, 'abgeschlossen', 'aktiv', v_kind, 57, 12, v_beginn, v_ende, v_beginn - 14, r.klasse,
              c_marke || ' ' || r.vorname, r.nachname);

      -- Anwesenheiten: so viele, dass rueckstand = soll - n dem Ziel entspricht.
      select e.soll into v_soll from public.einheiten_rechnung(57, v_beginn, v_ende, 0, v_heute) e;
      v_n := greatest(0, round(v_soll - r.ziel)::integer);

      -- Die letzten v_n Betriebstage vor heute, im Vertrag, verteilt.
      v_i := 0;
      for v_tag in
        select d::date from generate_series(v_heute - 1, v_beginn, interval '-1 day') d
         where public.betriebstag(d::date)
         limit v_n
      loop
        insert into public.coaching_sessions (coach_id, room, scheduled_at, status)
        values (v_coach, c_marke, (v_tag + time '16:00') at time zone 'Europe/Berlin', 'done')
        returning id into v_sess;
        v_i := v_i + 1;
        insert into public.session_students (session_id, student_id, attendance)
        values (v_sess, v_kind, case when r.nachname = 'Leicht' and v_i = 2 then 'unexcused' else 'present' end);
      end loop;
      if v_i < v_n then
        raise exception 'Seed %: fuer % gibt es nur % statt % Betriebstage', c_marke, r.nachname, v_i, v_n;
      end if;

      -- Zur Anschauung: eine geplante Session (naechster Betriebstag) und bei
      -- "Plan" eine vergangene "ausgefallen (durch uns)" — beide zaehlen nicht.
      select min(d::date) into v_tag from generate_series(v_heute + 1, v_heute + 30, interval '1 day') d
       where public.betriebstag(d::date);
      insert into public.coaching_sessions (coach_id, room, scheduled_at, status)
      values (v_coach, c_marke, (v_tag + time '16:00') at time zone 'Europe/Berlin', 'upcoming')
      returning id into v_sess;
      insert into public.session_students (session_id, student_id) values (v_sess, v_kind);
      if r.nachname = 'Plan' then
        insert into public.coaching_sessions (coach_id, room, scheduled_at, status)
        values (v_coach, c_marke, (v_beginn + 3 + time '16:00') at time zone 'Europe/Berlin', 'done')
        returning id into v_sess;
        insert into public.session_students (session_id, student_id, attendance)
        values (v_sess, v_kind, 'cancelled_by_us');
      end if;

    elsif r.art = 'vorher' then
      v_beginn := (v_monat + interval '1 month')::date;
      insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                    vertragsbeginn, vertrag_ende, abgeschlossen_am, widerruf_bis, klasse,
                                    kind_vorname, kind_nachname)
      values (v_lead, 'abgeschlossen', 'im_widerruf', v_kind, 76, 12, v_beginn,
              (v_beginn + interval '12 months')::date - 1, v_heute, v_beginn + 29, r.klasse,
              c_marke || ' ' || r.vorname, r.nachname);

    else -- ruhend: Jahresvertrag, vor 20 Tagen ausgelaufen, mit drei alten Sessions
      v_ende   := v_heute - 20;
      v_beginn := date_trunc('month', v_ende - 360)::date;
      insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                    vertragsbeginn, vertrag_ende, abgeschlossen_am, klasse,
                                    kind_vorname, kind_nachname)
      values (v_lead, 'abgeschlossen', 'aktiv', v_kind, 38, 12, v_beginn, v_ende, v_beginn - 14, r.klasse,
              c_marke || ' ' || r.vorname, r.nachname);
      for v_tag in
        select d::date from generate_series(v_ende - 7, v_beginn, interval '-1 day') d
         where public.betriebstag(d::date) limit 3
      loop
        insert into public.coaching_sessions (coach_id, room, scheduled_at, status)
        values (v_coach, c_marke, (v_tag + time '16:00') at time zone 'Europe/Berlin', 'done')
        returning id into v_sess;
        insert into public.session_students (session_id, student_id, attendance) values (v_sess, v_kind, 'present');
      end loop;
    end if;

    -- Notizen und ein Zwischenbericht fuer die Admin-Screenshots
    if r.nachname = 'Leicht' then
      insert into public.schueler_notizen (student_id, kategorie, text, autor_id, autor_rolle) values
        (v_kind, 'lernen', 'ZZ_S2B Bruchrechnen sitzt, Gleichungen mit Klammern noch unsicher.', v_coach,
         case when v_coach is null then 'admin' else 'coach' end);
      insert into public.schueler_notizen (student_id, kategorie, text, autor_rolle,
                                           ausgeblendet_am, ausgeblendet_grund) values
        (v_kind, 'verhalten', 'ZZ_S2B Kam zweimal zu spaet.', 'admin', now(), 'ZZ_S2B doppelt erfasst');
      insert into public.schueler_notizen (student_id, kategorie, text, autor_rolle,
                                           entfernt_am, entfernt_grund) values
        (v_kind, 'organisatorisch', null, 'admin', now(), 'gesundheitsangabe');
    elsif r.nachname = 'Plan' then
      insert into public.eltern_reports (student_id, nr, art, berichtsmonat, kernaussagen, versendet_am) values
        (v_kind, 1, 'zwischenbericht', v_monat,
         jsonb_build_object('Mathematik', 'ZZ_S2B Brueche sicher, Gleichungen noch nicht sicher.'), now());
    end if;
  end loop;

  raise notice 'Seed %: fuenf Testakten angelegt (Coach der Sessions: %)', c_marke, coalesce(v_coach::text, 'keiner');
end;
$$;
