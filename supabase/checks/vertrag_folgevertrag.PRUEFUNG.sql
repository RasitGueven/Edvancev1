-- PRUEFUNG: Folgevertrag (Migration 20260928120000).
--
-- Laeuft in begin … rollback, legt die Testdaten selbst an (Praefix ZZ_).
-- Claims MIT Rolle — ohne 'role' gilt der Aufruf als Systemaufruf.
--
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/checks/vertrag_folgevertrag.PRUEFUNG.sql
--
-- Signatur gegen den Schema-Abzug abgeglichen: vertrag_folgevertrag_starten(uuid) -> uuid.

begin;

do $$
declare
  v_admin   uuid;
  v_tier    uuid;
  v_lead    uuid;
  v_student uuid;
  v_alt     uuid;
  v_neu     uuid;
  v_neu2    uuid;
  v_text    text;
  v_n       integer;
  v_ok      boolean;
begin
  select id into v_admin from profiles where role = 'admin' limit 1;
  assert v_admin is not null, 'Kein Admin-Profil vorhanden';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  select id into v_tier from tiers where name = 'Premium';

  insert into students (profile_id, class_level, is_provisional, lead_id)
  values (null, 8, false, null) returning id into v_student;
  insert into leads (full_name, status) values ('ZZ_Folge Kind', 'vertrag') returning id into v_lead;

  insert into vertraege (
    lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
    unterschrieben_am, student_id, tier_id, laufzeit_monate, preis_cents, einheiten,
    vertragsbeginn, vertrag_ende, widerruf_bis, zugangscode, zugangscode_erzeugt_am,
    eltern_vorname, eltern_nachname, strasse, hausnummer, plz, ort,
    eltern_telefon, eltern_email, kind_vorname, kind_nachname, kind_geburtsdatum,
    klasse, fach, schule, kontoinhaber
  ) values (
    v_lead, 'abgeschlossen', 'aktiv', now(), date '2026-01-01', 'vor_ort',
    date '2026-01-01', v_student, v_tier, 6, 38990, 38,
    date '2026-01-01', current_date + 20, date '2026-01-30', 'EDV-ZZAA-ZZ22', date '2026-01-01',
    'ZZ_Anna', 'Folge', 'Teststr', '9', '50667', 'Koeln',
    '0221 999', 'zz_folge@edvance.invalid', 'ZZ_Mia', 'Folge', date '2012-02-02',
    8, 'Mathematik', 'ZZ_Schule', 'ZZ_Anna Folge'
  ) returning id into v_alt;

  insert into vertrag_bankdaten (vertrag_id, iban) values (v_alt, 'DE89370400440532013000');

  -- ========================================================================
  -- 1. Nur aus einem abgeschlossenen Vertrag, und nur als Admin
  -- ========================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', gen_random_uuid(), 'role', 'authenticated')::text, true);
  v_ok := false;
  begin
    perform public.vertrag_folgevertrag_starten(v_alt);
  exception when insufficient_privilege then v_ok := true; end;
  assert v_ok, 'Folgevertrag ohne Admin moeglich';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  raise notice '1  ok  nur Admin';

  -- ========================================================================
  -- 2. Der alte Index haette hier gesperrt
  -- ========================================================================
  -- vertraege_lead_offen_idx deckte frueher alles ab, was nicht abgelehnt ist.
  -- Der abgeschlossene Vertrag belegte damit den Lead dauerhaft.
  v_neu := public.vertrag_folgevertrag_starten(v_alt);
  assert v_neu is not null, 'kein Folgevertrag entstanden';
  select count(*) into v_n from vertraege where lead_id = v_lead;
  assert v_n = 2, 'zwei Vertraege am selben Lead nicht moeglich: ' || v_n;
  raise notice '2  ok  abgeschlossener Vertrag blockiert den Lead nicht mehr';

  -- ========================================================================
  -- 3. Vorbelegung
  -- ========================================================================
  select concat_ws('|', eltern_vorname, eltern_nachname, strasse, plz, ort,
                        kind_vorname, kind_nachname, klasse::text, fach, kontoinhaber)
    into v_text from vertraege where id = v_neu;
  assert v_text = 'ZZ_Anna|Folge|Teststr|50667|Koeln|ZZ_Mia|Folge|8|Mathematik|ZZ_Anna Folge',
    'Stammdaten nicht uebernommen: ' || coalesce(v_text, 'null');

  select concat_ws('|', (tier_id = v_tier)::text, laufzeit_monate::text,
                        preis_cents::text, einheiten::text,
                        (student_id = v_student)::text, (vorgaenger_id = v_alt)::text,
                        coalesce(vertragsbeginn::text, 'offen'), status)
    into v_text from vertraege where id = v_neu;
  assert v_text = 'true|6|38990|38|true|true|offen|in_vorbereitung',
    'Konditionen oder Bezuege falsch: ' || coalesce(v_text, 'null');
  raise notice '3  ok  Stammdaten, Paket, Kind und Vorgaenger uebernommen, Beginn bleibt offen';

  -- Preis kommt frisch aus tier_laufzeiten, nicht aus dem alten Vertrag.
  select preis_cents into v_n from tier_laufzeiten
   where tier_id = v_tier and laufzeit_monate = 6;
  assert (select preis_cents from vertraege where id = v_neu) = v_n,
    'Preis nicht aus tier_laufzeiten';

  -- Eigenes Mandat, gleiche Bankverbindung.
  select iban into v_text from vertrag_bankdaten where vertrag_id = v_neu;
  assert v_text = 'DE89370400440532013000', 'IBAN nicht uebernommen: ' || coalesce(v_text, 'null');
  select count(distinct mandatsreferenz) into v_n from vertraege where id in (v_alt, v_neu);
  assert v_n = 2, 'beide Vertraege teilen sich eine Mandatsreferenz';
  raise notice '4  ok  IBAN uebernommen, eigene Mandatsreferenz';

  -- ========================================================================
  -- 5. Idempotent
  -- ========================================================================
  v_neu2 := public.vertrag_folgevertrag_starten(v_alt);
  assert v_neu2 = v_neu, 'zweiter Aufruf legt einen weiteren Antrag an';
  select count(*) into v_n from vertraege where vorgaenger_id = v_alt;
  assert v_n = 1, 'mehr als ein Folgevertrag: ' || v_n;
  raise notice '5  ok  idempotent';

  -- ========================================================================
  -- 6. Aus einem offenen Antrag entsteht kein Folgevertrag
  -- ========================================================================
  v_ok := false;
  begin
    perform public.vertrag_folgevertrag_starten(v_neu);
  exception when sqlstate 'P0001' then v_ok := true; end;
  assert v_ok, 'Folgevertrag aus einem offenen Antrag war moeglich';
  raise notice '6  ok  nur aus einem abgeschlossenen Vertrag';

  raise notice '';
  raise notice '== Folgevertrag: alle Pruefungen bestanden ==';
end $$;

-- Rechte
select 'public.vertrag_folgevertrag_starten(uuid)' as funktion,
       has_function_privilege('anon', 'public.vertrag_folgevertrag_starten(uuid)'::regprocedure::oid, 'execute') as anon,
       has_function_privilege('authenticated', 'public.vertrag_folgevertrag_starten(uuid)'::regprocedure::oid, 'execute') as authenticated,
       case when not has_function_privilege('anon', 'public.vertrag_folgevertrag_starten(uuid)'::regprocedure::oid, 'execute')
             and has_function_privilege('authenticated', 'public.vertrag_folgevertrag_starten(uuid)'::regprocedure::oid, 'execute')
            then 'OK' else 'FEHLER' end as ergebnis;

rollback;
