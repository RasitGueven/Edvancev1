-- Abnahme Schuelerakte S1, Teil B: Einheiten-Stand, Betriebstage, Wortliste.
-- (Migrationen 20260929100000_schuelerakte_basis.sql, 20260929100100_schuelerakte_akte.sql)
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/einheiten_stand_test.sql
--
-- Feste Werte, heute = 2028-03-13, Vergleich auf eine Nachkommastelle.
-- Abnahme: die Spalte `ergebnis` enthaelt ausschliesslich OK.
--
-- Die Datei laeuft in EINER Transaktion und endet mit ROLLBACK. Geschrieben
-- wird nur im Teil N (notiz_anlegen mit "Standardaufgaben" legt eine Notiz an,
-- die das ROLLBACK wieder entfernt). Teil N braucht ein Admin-Profil und eine
-- aktive Akte; fehlt eins davon, steht dort FEHLER mit dem Grund.

begin;

-- ------------------------------------------------------------ Teil N: notiz_anlegen
-- Exceptions sind in reinem SQL nicht fangbar; die Ergebnisse gehen per
-- set_config in den Sitzungszustand (transaktionslokal, vor dem ROLLBACK gelesen).
do $$
declare
  v_admin uuid;
  v_akte  uuid;
begin
  select id into v_admin from public.profiles where role = 'admin' order by created_at limit 1;
  select v.student_id into v_akte from public.vertraege_aktuell v
   where v.wirksamer_status in ('aktiv', 'im_widerruf') and v.student_id is not null
   order by v.student_id limit 1;

  if v_admin is null or v_akte is null then
    perform set_config('edvance.test_allergie', 'keine Vorbedingung (Admin/aktive Akte fehlt)', true);
    perform set_config('edvance.test_standard', 'keine Vorbedingung (Admin/aktive Akte fehlt)', true);
    return;
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  begin
    perform public.notiz_anlegen(v_akte, 'lernen', 'Hat eine Allergie gegen Nuesse.');
    perform set_config('edvance.test_allergie', 'angenommen', true);
  exception when others then
    perform set_config('edvance.test_allergie', 'abgelehnt ' || sqlstate, true);
  end;

  begin
    perform public.notiz_anlegen(v_akte, 'lernen', 'Standardaufgaben sitzen, Transfer noch unsicher.');
    perform set_config('edvance.test_standard', 'angenommen', true);
  exception when others then
    perform set_config('edvance.test_standard', 'abgelehnt ' || sqlstate || ' ' || sqlerrm, true);
  end;

  execute 'reset role';
end;
$$;

-- ------------------------------------------------------------ Auswertung
with faelle (nr, einheiten, beginn, stichtag, verbraucht,
             s_soll, s_rueckstand, s_ampel, s_wochen, s_noetig, s_gleich,
             s_bt_gesamt, s_bt_bis_gestern, s_bt_ab_heute) as (
  values
    (1, 29, date '2027-11-01', date '2028-06-15', 14, 17.2,  3.2, 'leicht_im_rueckstand',   10.8, 1.4, 1.1, 133,  79,  54),
    (2, 76, date '2027-09-01', date '2028-08-31', 46, 45.8, -0.2, 'im_plan',                15.4, 1.9, 2.0, 194, 117,  77),
    (3, 57, date '2028-02-01', date '2029-01-31',  4,  8.6,  4.6, 'deutlich_im_rueckstand', 32.6, 1.6, 1.5, 192,  29, 163)
),
rechnung as (
  select f.*, r.*
    from faelle f
    cross join lateral public.einheiten_rechnung(f.einheiten, f.beginn, f.stichtag, f.verbraucht, date '2028-03-13') r
),
zeilen (nr, pruefung, ist, soll) as (
  select nr * 10 + 0, 'Fall ' || nr || ' art',         art,                              'laufend'        from rechnung
  union all
  select nr * 10 + 1, 'Fall ' || nr || ' Betriebstage gesamt / bis gestern / ab heute',
         betriebstage_gesamt || ' / ' || betriebstage_bis_gestern || ' / ' || betriebstage_ab_heute,
         s_bt_gesamt || ' / ' || s_bt_bis_gestern || ' / ' || s_bt_ab_heute                         from rechnung
  union all
  select nr * 10 + 2, 'Fall ' || nr || ' soll',         round(soll, 1)::text,             s_soll::text     from rechnung
  union all
  select nr * 10 + 3, 'Fall ' || nr || ' Rueckstand',   round(rueckstand, 1)::text,       s_rueckstand::text from rechnung
  union all
  select nr * 10 + 4, 'Fall ' || nr || ' Ampel',        ampel,                            s_ampel          from rechnung
  union all
  select nr * 10 + 5, 'Fall ' || nr || ' Wochen rest',  round(wochen_rest, 1)::text,      s_wochen::text   from rechnung
  union all
  select nr * 10 + 6, 'Fall ' || nr || ' noetig/Woche', round(noetig_pro_woche, 1)::text, s_noetig::text   from rechnung
  union all
  select nr * 10 + 7, 'Fall ' || nr || ' gleichmaessig/Woche', round(gleichmaessig_pro_woche, 1)::text, s_gleich::text from rechnung
  union all
  select nr * 10 + 8, 'Fall ' || nr || ' offen',        offen::text,                      (einheiten - verbraucht)::text from rechnung
  union all
  -- Fall 4: Vertrag beginnt noch
  select 40, 'Fall 4 art (76, 2028-04-01 bis 2029-03-31)', r.art, 'vorher'
    from public.einheiten_rechnung(76, date '2028-04-01', date '2029-03-31', null, date '2028-03-13') r
  union all
  select 41, 'Fall 4 ohne Soll/Rueckstand/Ampel',
         coalesce(r.soll::text, '-') || ' / ' || coalesce(r.rueckstand::text, '-') || ' / ' || coalesce(r.ampel, '-'),
         '- / - / -'
    from public.einheiten_rechnung(76, date '2028-04-01', date '2029-03-31', null, date '2028-03-13') r
  union all
  -- einheit_verbraucht
  select 50, 'einheit_verbraucht(present)',         public.einheit_verbraucht('present')::text,         'true'
  union all
  select 51, 'einheit_verbraucht(unexcused)',       public.einheit_verbraucht('unexcused')::text,       'true'
  union all
  select 52, 'einheit_verbraucht(cancelled)',       public.einheit_verbraucht('cancelled')::text,       'false'
  union all
  select 53, 'einheit_verbraucht(cancelled_by_us)', public.einheit_verbraucht('cancelled_by_us')::text, 'false'
  union all
  select 54, 'einheit_verbraucht(planned)',         public.einheit_verbraucht('planned')::text,         'false'
  union all
  -- betriebstag
  select 60, 'betriebstag(2028-06-06) Pfingstferientag', public.betriebstag(date '2028-06-06')::text, 'false'
  union all
  select 61, 'betriebstag(2028-06-15) Fronleichnam',     public.betriebstag(date '2028-06-15')::text, 'false'
  union all
  select 62, 'betriebstag(2028-03-13) Montag',           public.betriebstag(date '2028-03-13')::text, 'true'
  union all
  select 63, 'betriebstag(2028-03-11) Samstag',          public.betriebstag(date '2028-03-11')::text, 'false'
  union all
  select 64, 'betriebstag(2028-04-12) Osterferien',      public.betriebstag(date '2028-04-12')::text, 'false'
  union all
  select 66, 'betriebstage = Anzahl betriebstag() fuer jeden Monatsersten 2026-09 bis 2029-12 bis +1..400 Tage (Abweichungen)',
         (select count(*)::text from (
            select m::date von, (m + (k || ' days')::interval)::date bis
              from generate_series(date '2026-09-01', date '2029-12-01', interval '1 month') m,
                   generate_series(0, 400, 37) k) r
           where public.betriebstage(r.von, r.bis)
                 is distinct from (select count(*) from generate_series(r.von, r.bis, interval '1 day') d
                                    where public.betriebstag(d::date))),
         '0'
  union all
  select 67, 'betriebstage leeres Intervall', public.betriebstage(date '2028-03-13', date '2028-03-12')::text, '0'
  union all
  select 68, 'einheiten_rechnung ohne Vertrag liefert keine Zeile',
         (select count(*)::text from public.einheiten_rechnung(null, null, null, null, date '2028-03-13')), '0'
  union all
  select 65, 'feiertage_nrw: 12 Tage je Jahr 2026-2030',
         (select string_agg(n::text, ',' order by j) from (
            select extract(year from datum) j, count(*) n from public.feiertage_nrw group by 1) x),
         '12,12,12,12,12'
  union all
  -- Wortliste und notiz_anlegen
  select 70, 'Wortliste: "Allergie" trifft',          coalesce(public.akte_wortliste_treffer('gesundheit', 'Allergie'), '-'),         'allergi'
  union all
  select 71, 'Wortliste: "Standardaufgaben" trifft nicht', coalesce(public.akte_wortliste_treffer('gesundheit', 'Standardaufgaben'), '-'), '-'
  union all
  select 72, 'Wortliste: "ADS" nur als ganzes Wort',  coalesce(public.akte_wortliste_treffer('gesundheit', 'Verdacht auf ADS.'), '-'), 'ads'
  union all
  select 73, 'notiz_anlegen lehnt "Allergie" ab',      current_setting('edvance.test_allergie', true), 'abgelehnt 22023'
  union all
  select 74, 'notiz_anlegen akzeptiert "Standardaufgaben"', current_setting('edvance.test_standard', true), 'angenommen'
  union all
  -- Abgleich Zustand der Akte gegen hat_zugang, alle Kinder mit Vertrag (heute)
  select 80, 'akte_aktiv = hat_zugang fuer alle Kinder mit Vertrag (Abweichungen)',
         coalesce((select string_agg(x.student_id::text, ', ')
                     from (select distinct v.student_id from public.vertraege v
                            where v.status = 'abgeschlossen' and v.student_id is not null) x
                    where public.akte_aktiv(x.student_id) is distinct from public.hat_zugang(x.student_id)), 'keine'),
         'keine'
  union all
  -- Rechte: nichts davon an anon
  select 90 + row_number() over (), 'anon darf ' || f || ' nicht ausfuehren',
         has_function_privilege('anon', f, 'execute')::text, 'false'
    from unnest(array[
      'public.einheiten_stand(uuid,date)', 'public.einheiten_rechnung(integer,date,date,integer,date)',
      'public.board_schueler()', 'public.akte_basis()', 'public.notiz_anlegen(uuid,text,text)',
      'public.eltern_report_eintragen(uuid,text,date,jsonb,uuid,timestamptz,timestamptz,text,text,uuid,uuid)',
      'public.lsa_lead_kontext(uuid[])', 'public.einheiten_stand_intern(uuid,date)']) f
  union all
  select 99, 'authenticated darf einheiten_stand_intern nicht ausfuehren',
         has_function_privilege('authenticated', 'public.einheiten_stand_intern(uuid,date)', 'execute')::text, 'false'
)
select nr, pruefung, ist, soll,
       case when ist is not distinct from soll then 'OK' else 'FEHLER' end as ergebnis
  from zeilen
 order by nr;

rollback;
