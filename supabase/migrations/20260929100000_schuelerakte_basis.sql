-- Schuelerakte S1, Teil 1 von 3: Grundlagen.
--
-- Bauauftrag Schuelerakte (Fassung 2), Paket S1, Lieferumfang A.1. Massgeblich
-- ist docs/schuelerakte/entscheidungen.md; die Nummern in den Kommentaren
-- ("Entscheidung 6") verweisen dorthin.
--
-- Inhalt:
--   1. feiertage_nrw          — gesetzliche Feiertage NRW + Pfingstferientag
--   2. akte_einstellungen     — Ampelschwellen (einzeilig)
--   3. akte_wortliste         — Wortliste Gesundheit / Report-Verbot
--   4. students.schule_id     — Schule als Verweis statt Freitext
--   5. Anwesenheit            — planned | present | cancelled | unexcused | cancelled_by_us
--   6. einheit_verbraucht     — einzige Stelle, die entscheidet, was eine Einheit kostet
--   7. betriebstag/betriebstage
--
-- Klasse: students.class_level existiert schon (Check 5..13) und wird genutzt.
-- Der Check bleibt, wie er ist — die Auswahl 8|9|10 ist eine Frage der
-- Oberflaeche. Ein engerer Check wuerde die LSA fuer andere Klassen
-- (lead_lsa_freigeben, lsa_sessions.grade 5..13) und den Altbestand brechen.

begin;

-- ============================================================================
-- 1. feiertage_nrw (Entscheidung 6)
-- ============================================================================
--
-- ferien_nrw kennt nur Herbst, Weihnachten, Ostern, Sommer (art-Check). Die
-- gesetzlichen Feiertage und der eine Pfingstferientag stehen hier. Ein Tag ist
-- Betriebstag, wenn er Mo-Fr ist und in keiner der beiden Tabellen steht.
--
-- Oster-abhaengige Tage aus dem Osterdatum (Gauss): 2026-04-05, 2027-03-28,
-- 2028-04-16, 2029-04-01, 2030-04-21. Karfreitag = Ostern - 2, Ostermontag + 1,
-- Christi Himmelfahrt + 39, Pfingstmontag + 50, Fronleichnam + 60.
-- Pfingstferientag = Dienstag nach Pfingstmontag = Ostern + 51.
--
-- Abgleich mit der amtlichen Ferienordnung (Schulministerium NRW,
-- OpenData_Ferientermine.csv, FerienID 5): dort stehen nur 2026-05-26,
-- 2027-05-18 und 2029-05-22; fuer 2027/28 und 2029/30 KEIN Pfingstferientag.
-- Entscheidung Rasit (29.09.2026): 2028-06-06 und 2030-06-11 bleiben wie im
-- Bauauftrag stehen. Die Kontrollwerte in tests/sql/einheiten_stand_test.sql
-- rechnen damit.

create table public.feiertage_nrw (
  datum date primary key,
  art   text not null,
  name  text not null,
  constraint feiertage_nrw_art_check check (art in ('feiertag', 'pfingstferien')),
  constraint feiertage_nrw_name_nicht_leer check (nullif(btrim(name), '') is not null)
);

comment on table public.feiertage_nrw is
  'Gesetzliche Feiertage NRW und der Pfingstferientag. Zusammen mit ferien_nrw die Grundlage von betriebstag(). Schreiben nur per Migration.';

insert into public.feiertage_nrw (datum, art, name) values
  -- 2026
  (date '2026-01-01', 'feiertag',      'Neujahr'),
  (date '2026-04-03', 'feiertag',      'Karfreitag'),
  (date '2026-04-06', 'feiertag',      'Ostermontag'),
  (date '2026-05-01', 'feiertag',      'Tag der Arbeit'),
  (date '2026-05-14', 'feiertag',      'Christi Himmelfahrt'),
  (date '2026-05-25', 'feiertag',      'Pfingstmontag'),
  (date '2026-05-26', 'pfingstferien', 'Pfingstferientag'),
  (date '2026-06-04', 'feiertag',      'Fronleichnam'),
  (date '2026-10-03', 'feiertag',      'Tag der Deutschen Einheit'),
  (date '2026-11-01', 'feiertag',      'Allerheiligen'),
  (date '2026-12-25', 'feiertag',      '1. Weihnachtstag'),
  (date '2026-12-26', 'feiertag',      '2. Weihnachtstag'),
  -- 2027
  (date '2027-01-01', 'feiertag',      'Neujahr'),
  (date '2027-03-26', 'feiertag',      'Karfreitag'),
  (date '2027-03-29', 'feiertag',      'Ostermontag'),
  (date '2027-05-01', 'feiertag',      'Tag der Arbeit'),
  (date '2027-05-06', 'feiertag',      'Christi Himmelfahrt'),
  (date '2027-05-17', 'feiertag',      'Pfingstmontag'),
  (date '2027-05-18', 'pfingstferien', 'Pfingstferientag'),
  (date '2027-05-27', 'feiertag',      'Fronleichnam'),
  (date '2027-10-03', 'feiertag',      'Tag der Deutschen Einheit'),
  (date '2027-11-01', 'feiertag',      'Allerheiligen'),
  (date '2027-12-25', 'feiertag',      '1. Weihnachtstag'),
  (date '2027-12-26', 'feiertag',      '2. Weihnachtstag'),
  -- 2028
  (date '2028-01-01', 'feiertag',      'Neujahr'),
  (date '2028-04-14', 'feiertag',      'Karfreitag'),
  (date '2028-04-17', 'feiertag',      'Ostermontag'),
  (date '2028-05-01', 'feiertag',      'Tag der Arbeit'),
  (date '2028-05-25', 'feiertag',      'Christi Himmelfahrt'),
  (date '2028-06-05', 'feiertag',      'Pfingstmontag'),
  (date '2028-06-06', 'pfingstferien', 'Pfingstferientag'),
  (date '2028-06-15', 'feiertag',      'Fronleichnam'),
  (date '2028-10-03', 'feiertag',      'Tag der Deutschen Einheit'),
  (date '2028-11-01', 'feiertag',      'Allerheiligen'),
  (date '2028-12-25', 'feiertag',      '1. Weihnachtstag'),
  (date '2028-12-26', 'feiertag',      '2. Weihnachtstag'),
  -- 2029
  (date '2029-01-01', 'feiertag',      'Neujahr'),
  (date '2029-03-30', 'feiertag',      'Karfreitag'),
  (date '2029-04-02', 'feiertag',      'Ostermontag'),
  (date '2029-05-01', 'feiertag',      'Tag der Arbeit'),
  (date '2029-05-10', 'feiertag',      'Christi Himmelfahrt'),
  (date '2029-05-21', 'feiertag',      'Pfingstmontag'),
  (date '2029-05-22', 'pfingstferien', 'Pfingstferientag'),
  (date '2029-05-31', 'feiertag',      'Fronleichnam'),
  (date '2029-10-03', 'feiertag',      'Tag der Deutschen Einheit'),
  (date '2029-11-01', 'feiertag',      'Allerheiligen'),
  (date '2029-12-25', 'feiertag',      '1. Weihnachtstag'),
  (date '2029-12-26', 'feiertag',      '2. Weihnachtstag'),
  -- 2030
  (date '2030-01-01', 'feiertag',      'Neujahr'),
  (date '2030-04-19', 'feiertag',      'Karfreitag'),
  (date '2030-04-22', 'feiertag',      'Ostermontag'),
  (date '2030-05-01', 'feiertag',      'Tag der Arbeit'),
  (date '2030-05-30', 'feiertag',      'Christi Himmelfahrt'),
  (date '2030-06-10', 'feiertag',      'Pfingstmontag'),
  (date '2030-06-11', 'pfingstferien', 'Pfingstferientag'),
  (date '2030-06-20', 'feiertag',      'Fronleichnam'),
  (date '2030-10-03', 'feiertag',      'Tag der Deutschen Einheit'),
  (date '2030-11-01', 'feiertag',      'Allerheiligen'),
  (date '2030-12-25', 'feiertag',      '1. Weihnachtstag'),
  (date '2030-12-26', 'feiertag',      '2. Weihnachtstag');

alter table public.feiertage_nrw enable row level security;

-- Wie ferien_nrw: lesen jeder Angemeldete, schreiben niemand.
create policy feiertage_nrw_authenticated_read on public.feiertage_nrw
  for select using (auth.role() = 'authenticated');

revoke all on public.feiertage_nrw from public, anon, authenticated;
grant select on public.feiertage_nrw to authenticated;

-- ============================================================================
-- 2. akte_einstellungen (Entscheidung 7)
-- ============================================================================
--
-- Eigene Tabelle, weil vertrag_einstellungen nur fuer Admins lesbar ist und
-- fachlich zum Vertrag gehoert (S0, Abschnitt 7). Einzeilig nach demselben
-- Muster: id boolean = true.

create table public.akte_einstellungen (
  id         boolean primary key default true,
  schwelle_1 numeric not null default 1.5,
  schwelle_2 numeric not null default 3.5,
  updated_at timestamptz not null default now(),
  constraint akte_einstellungen_eine_zeile check (id),
  constraint akte_einstellungen_schwellen check (schwelle_1 >= 0 and schwelle_1 < schwelle_2)
);

comment on table public.akte_einstellungen is
  'Einstellungen der Schuelerakte (eine Zeile). schwelle_1/_2: Ampel des Einheiten-Stands — Rueckstand <= schwelle_1 im Plan, <= schwelle_2 leicht, darueber deutlich im Rueckstand.';

insert into public.akte_einstellungen (id) values (true);

alter table public.akte_einstellungen enable row level security;

create policy akte_einstellungen_authenticated_read on public.akte_einstellungen
  for select using (auth.role() = 'authenticated');
create policy akte_einstellungen_admin_update on public.akte_einstellungen
  for update using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');

revoke all on public.akte_einstellungen from public, anon, authenticated;
grant select, update on public.akte_einstellungen to authenticated;

-- ============================================================================
-- 3. akte_wortliste (Entscheidung 9)
-- ============================================================================
--
-- Geprueft wird kleingeschrieben. nur_ganzes_wort = true: Treffer nur als
-- ganzes Wort (sonst waere "ads" in "Standardaufgaben" ein Treffer).
-- nur_ganzes_wort = false: Treffer auch als Wortteil ("allergi" trifft
-- "Allergie", "allergisch").

create table public.akte_wortliste (
  id              uuid primary key default gen_random_uuid(),
  liste           text not null,
  wort            text not null,
  nur_ganzes_wort boolean not null default false,
  created_at      timestamptz not null default now(),
  created_by      uuid references public.profiles(id) on delete set null,
  constraint akte_wortliste_liste_check check (liste in ('gesundheit', 'report_verbot')),
  constraint akte_wortliste_wort_form check (wort = lower(btrim(wort)) and wort <> ''),
  constraint akte_wortliste_eindeutig unique (liste, wort)
);

comment on table public.akte_wortliste is
  'Woerter, die in Notizen (liste gesundheit) bzw. Reports (liste report_verbot) nicht vorkommen duerfen. Geprueft serverseitig in notiz_anlegen; das Frontend liest die Liste fuer die Live-Pruefung.';

insert into public.akte_wortliste (liste, wort, nur_ganzes_wort) values
  ('gesundheit', 'adhs',       true),
  ('gesundheit', 'ads',        true),
  ('gesundheit', 'allergi',    false),
  ('gesundheit', 'diagnos',    false),
  ('gesundheit', 'medikament', false),
  ('gesundheit', 'krank',      false),
  ('gesundheit', 'therapie',   false),
  ('gesundheit', 'therapeut',  false),
  ('gesundheit', 'legasthen',  false),
  ('gesundheit', 'lrs',        true),
  ('gesundheit', 'dyskalkul',  false),
  ('gesundheit', 'autis',      false),
  ('gesundheit', 'depress',    false),
  ('gesundheit', 'asthma',     false),
  ('gesundheit', 'epilep',     false),
  ('gesundheit', 'arzt',       false),
  ('gesundheit', 'ärzt',       false),
  ('gesundheit', 'attest',     false),
  ('gesundheit', 'tabletten',  false),
  ('gesundheit', 'psych',      false);

alter table public.akte_wortliste enable row level security;

-- Lesen: Admin und Coach (das Notizfeld prueft live, S2). Pflegen: Admin.
create policy akte_wortliste_read on public.akte_wortliste
  for select using (public.get_my_role() in ('admin', 'coach'));
create policy akte_wortliste_admin_all on public.akte_wortliste
  for all using (public.get_my_role() = 'admin') with check (public.get_my_role() = 'admin');

revoke all on public.akte_wortliste from public, anon, authenticated;
grant select, insert, update, delete on public.akte_wortliste to authenticated;

-- Trefferpruefung, die notiz_anlegen und spaeter die Eltern-Reports nutzen.
-- Liefert das erste getroffene Wort oder NULL.
create or replace function public.akte_wortliste_treffer(p_liste text, p_text text)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select w.wort
    from public.akte_wortliste w
   where w.liste = p_liste
     and case
           when w.nur_ganzes_wort then
             lower(coalesce(p_text, '')) ~ ('\m' || regexp_replace(w.wort, '([.*+?^${}()|\[\]\\])', '\\\1', 'g') || '\M')
           else
             strpos(lower(coalesce(p_text, '')), w.wort) > 0
         end
   order by w.wort
   limit 1;
$$;

comment on function public.akte_wortliste_treffer(text, text) is
  'Erstes Wort aus akte_wortliste (Liste p_liste), das in p_text vorkommt, sonst NULL. Kleinschreibung; nur_ganzes_wort ueber Wortgrenzen.';

revoke all on function public.akte_wortliste_treffer(text, text) from public, anon, authenticated;
grant execute on function public.akte_wortliste_treffer(text, text) to authenticated;

-- ============================================================================
-- 4. students.schule_id
-- ============================================================================
--
-- school_name (Freitext) bleibt als Altbestand stehen. Neu zeigt die Akte auf
-- schulen.id — dieselbe Liste wie unter Vertraege. Vorbelegt aus dem letzten
-- abgeschlossenen Vertrag des Kindes, der eine Schule traegt.

alter table public.students
  add column schule_id uuid references public.schulen(id) on delete restrict;

create index students_schule_idx on public.students (schule_id);

comment on column public.students.schule_id is
  'Schule des Kindes (schulen). Gesetzt beim Vertragsabschluss, gepflegt in der Akte. school_name ist Altbestand.';

update public.students s
   set schule_id = x.schule_id
  from (
    select distinct on (v.student_id) v.student_id, v.schule_id
      from public.vertraege v
     where v.status = 'abgeschlossen'
       and v.student_id is not null
       and v.schule_id is not null
     order by v.student_id, v.vertragsbeginn desc nulls last, v.abgeschlossen_am desc nulls last
  ) x
 where x.student_id = s.id
   and s.schule_id is null;

-- ============================================================================
-- 5. Anwesenheit (Entscheidung 4)
-- ============================================================================
--
-- Alt: present | absent | unknown. Neu:
--   planned          geplant (vor dem Termin; Standard)
--   present          anwesend
--   cancelled        abgesagt              (setzt spaeter das Slots-Feature)
--   unexcused        unentschuldigt ("nicht erschienen")
--   cancelled_by_us  ausgefallen durch uns (setzt spaeter das Slots-Feature)
-- Umstellung: present -> present, absent -> unexcused, unknown -> planned.
-- Prod traegt laut S0 zwei Zeilen, beide 'unknown'.

alter table public.session_students drop constraint session_students_attendance_check;

update public.session_students
   set attendance = case attendance
                      when 'absent'  then 'unexcused'
                      when 'unknown' then 'planned'
                      else attendance
                    end
 where attendance in ('absent', 'unknown');

alter table public.session_students alter column attendance set default 'planned';

alter table public.session_students
  add constraint session_students_attendance_check
  check (attendance in ('planned', 'present', 'cancelled', 'unexcused', 'cancelled_by_us'));

comment on column public.session_students.attendance is
  'planned | present | cancelled | unexcused | cancelled_by_us. In der Session setzt der Coach present oder unexcused. Was eine Einheit verbraucht, entscheidet einheit_verbraucht().';

-- ============================================================================
-- 6. einheit_verbraucht (Entscheidung 5)
-- ============================================================================

create or replace function public.einheit_verbraucht(p_attendance text)
returns boolean
language sql
immutable
parallel safe
as $$
  select coalesce(p_attendance in ('present', 'unexcused'), false);
$$;

comment on function public.einheit_verbraucht(text) is
  'Einzige Stelle, die entscheidet, ob eine Anwesenheit eine Einheit verbraucht: present und unexcused ja, alles andere nein.';

revoke all on function public.einheit_verbraucht(text) from public, anon, authenticated;
grant execute on function public.einheit_verbraucht(text) to authenticated;

-- ============================================================================
-- 7. betriebstag / betriebstage (Entscheidung 6)
-- ============================================================================
--
-- SECURITY DEFINER wie vertrag_ende_berechnen: ferien_nrw und feiertage_nrw
-- tragen RLS, die Rechnung soll fuer jeden Aufrufer dieselbe sein.
-- Datumsarithmetik nur ueber date.

create or replace function public.betriebstag(p_datum date)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select extract(isodow from p_datum) between 1 and 5
     and not exists (select 1 from public.feiertage_nrw f where f.datum = p_datum)
     and not exists (select 1 from public.ferien_nrw f where p_datum between f.von and f.bis);
$$;

comment on function public.betriebstag(date) is
  'Mo-Fr, nicht in ferien_nrw, nicht in feiertage_nrw.';

-- Werktage Mo-Fr im geschlossenen Intervall, rein rechnerisch. Bezugspunkt
-- 1970-01-05 ist ein Montag; bis(d) = Werktage vom Bezugspunkt bis d.
create or replace function public.werktage(p_von date, p_bis date)
returns integer
language sql
immutable
parallel safe
as $$
  select case when p_bis < p_von then 0 else
    ((p_bis - date '1970-01-05' + 1) / 7) * 5 + least((p_bis - date '1970-01-05' + 1) % 7, 5)
    - (((p_von - date '1970-01-05') / 7) * 5 + least((p_von - date '1970-01-05') % 7, 5))
  end;
$$;

comment on function public.werktage(date, date) is
  'Anzahl Mo-Fr von p_von bis p_bis (beide eingeschlossen), ohne Feiertage und Ferien. Gueltig ab 1970-01-05.';

-- Anzahl Betriebstage im geschlossenen Intervall [p_von, p_bis]. Leeres
-- Intervall (p_bis < p_von) = 0.
--   Werktage
--   - Werktage in Ferien (count distinct: auch ueberlappende Ferien zaehlen je Tag einmal)
--   - Feiertage an Werktagen ausserhalb der Ferien
-- Gleichwertig zu "count(*) where betriebstag(d)", aber ohne Tag-fuer-Tag-
-- Unterabfragen: das Board ruft die Funktion dreimal je Kind (Ziel 300 Kinder
-- unter 300 ms). tests/sql/einheiten_stand_test.sql prueft die Gleichheit.
create or replace function public.betriebstage(p_von date, p_bis date)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.werktage(p_von, p_bis)
       - (select count(distinct g.t)::integer
            from public.ferien_nrw f
            cross join lateral generate_series(greatest(f.von, p_von), least(f.bis, p_bis), interval '1 day') g(t)
           where f.von <= p_bis and f.bis >= p_von
             and extract(isodow from g.t) between 1 and 5)
       - (select count(*)::integer
            from public.feiertage_nrw h
           where h.datum between p_von and p_bis
             and extract(isodow from h.datum) between 1 and 5
             and not exists (select 1 from public.ferien_nrw f where h.datum between f.von and f.bis));
$$;

comment on function public.betriebstage(date, date) is
  'Anzahl Betriebstage (siehe betriebstag) von p_von bis p_bis, beide eingeschlossen. 0, wenn p_bis vor p_von liegt.';

revoke all on function public.werktage(date, date) from public, anon, authenticated;
grant execute on function public.werktage(date, date) to authenticated;
revoke all on function public.betriebstag(date) from public, anon, authenticated;
revoke all on function public.betriebstage(date, date) from public, anon, authenticated;
grant execute on function public.betriebstag(date) to authenticated;
grant execute on function public.betriebstage(date, date) to authenticated;

commit;
