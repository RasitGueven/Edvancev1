-- ============================================================================
-- C3: Schublade der Coach-Live-Sicht (Pfad-Vorschlag, Heute, Grund mit Zahl, Erklaersequenz, Belege)
-- (Migrationen 20261011100100, 20261011100200; offene-punkte-c3).
--
-- Zusagen (Nummern wie im Auftrag, Buchstaben je Umfangspunkt):
--   1) P Pfad-Vorschlag aus dem Signal entscheidung_tiefer mit Zahlen, Klasse, Fehlbild (Klartext) und dem Tag der
--        frueheren Session mit demselben Fehlbild; offen nur bis zur Entscheidung.
--      H Heute je Kind: ankommen, warmup, kern, eingemischt (richtig/von/hinweise wie die Engine), erklaerung.
--      G Grund mit Zahl: Fenster (richtig, von, ziel, aenderung) und Mischanteil in session_schritte.details.
--      X Erklaersequenz: alle Kernideen in Reihenfolge mit Titel, Stand, Runde, Variante, Fehlbild der letzten Runde.
--      M Warm-up-Beleg: Heute-Zeile warmup mit dem Skill (die Abbildung macht daraus den Mastery-Beleg).
--      0 Kind ohne Ereignisse: leere Listen statt Fehler.
--   2) Signal vor A2d (ohne Felder) und Schritt ohne Zahlen: kein Fehler, Felder null bzw. {}.
--   3) Tablet unveraendert: session_naechster_schritt und tablet_stand ohne neue Felder; session_schritte ohne
--      Rechte fuer anon/authenticated; Append-only-Sperre unveraendert.
--   4) Rechte: Coach nur fuer die eigene Session, Konto ohne Profil 42501, Admin darf.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(56);

\ir session_a2_fixture.sql

-- Bekanntes Fehlbild fuer die Voraussetzungen: "0" heisst vorzeichen_ignoriert.
update task_solutions set acceptance = acceptance || '{"known_errors": {"0": "vorzeichen_ignoriert"}}'
 where task_id in (select id from tasks where skill_key in ('zz_a2_v1', 'zz_a2_v2'));
select klartext as fb_text from fehlbild_labels where slug = 'vorzeichen_ignoriert' \gset

-- ── 1P) Pfad-Vorschlag ─────────────────────────────────────────────────────
select pg_temp.kind_mit('ZZ Emir C3', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_e \gset
-- Dasselbe Fehlbild in der frueheren Session (vor 7 Tagen) auf beiden Voraussetzungen.
insert into session_students (session_id, student_id) values (:'s_alt', :'k_e');
insert into session_antworten (session_id, student_id, task_id, versuch_nr, eingabe, ergebnis, fehlbild_slug, phase, zeit)
select :'s_alt', :'k_e', (select id from tasks where skill_key = sk order by source_ref desc limit 1), 1, '"0"', 'falsch',
       'vorzeichen_ignoriert', 'kern', now() - interval '7 days'
  from unnest(array['zz_a2_v1', 'zz_a2_v2']) sk;
select pg_temp.neue_session(array[:'k_e']::uuid[], 6) as s \gset
select pg_temp.checkin(:'s', 1);
-- Warm-up wie A2d S: drei Aufgaben, nur die zweite richtig -> Signal "eine Stufe tiefer?".
create temp table w as select n, pg_temp.loese(:'s', 1, n = 2) as x from generate_series(1, 4) n;
select pg_temp.act_as(:'coach_a');
select details as sig from raum_signale(:'s') where art = 'entscheidung' \gset
select coach_kind_detail(:'s', :'k_e') -> 'pfad_vorschlag' as pv \gset
select is(:'pv'::jsonb ->> 'offen', 'true', '1P Signal offen');
select is(:'pv'::jsonb ->> 'skill_key', :'sig'::jsonb ->> 'voraussetzung_skill_key', '1P Voraussetzung aus dem Signal');
select is(:'pv'::jsonb ->> 'label', :'sig'::jsonb ->> 'voraussetzung_label', '1P Label der Voraussetzung');
select is((:'pv'::jsonb ->> 'klasse')::int, 7, '1P Klassenstufe der Voraussetzung (skills.klasse_herkunft)');
select is(:'pv'::jsonb ->> 'ziel_label', 'ZZ Klammern ausmultiplizieren', '1P Skill des Plans');
select is((:'pv'::jsonb ->> 'warmup_aufgaben')::int || '/' || (:'pv'::jsonb ->> 'warmup_richtig'),
          (:'sig'::jsonb ->> 'warmup_aufgaben') || '/' || (:'sig'::jsonb ->> 'warmup_richtig'), '1P Warm-up-Zahlen wie im Signal');
select ok((:'pv'::jsonb ->> 'warmup_aufgaben')::int >= 2, '1P mindestens zwei Warm-up-Aufgaben auf der Voraussetzung');
select is(:'pv'::jsonb ->> 'fehlbild', :'fb_text', '1P letztes Fehlbild auf der Voraussetzung als Klartext');
select is((:'pv'::jsonb ->> 'fehlbild_am')::timestamptz::date, (now() - interval '7 days')::date,
          '1P dasselbe Fehlbild in der frueheren Session');
select is(:'pv'::jsonb ->> 'thema_label', 'ZZ Terme', '1P Thema des Ziels');
select pfad_entscheiden(:'s', :'k_e', 'plan');
select is(coach_kind_detail(:'s', :'k_e') -> 'pfad_vorschlag' ->> 'offen', 'false', '1P nach der Entscheidung nicht mehr offen');

-- ── 1H/1G) Heute und Grund ─────────────────────────────────────────────────
-- Kernarbeit (s1, nicht neu): richtig, richtig nach Hinweis, falsch; die vierte wird eingemischt (Anteil 0,3).
select pg_temp.uhr(:'s', 20);
select pg_temp.loese(:'s', 1, true) ->> 'grund_code' as k1, pg_temp.loese(:'s', 1, true, true) ->> 'grund_code' as k2,
       pg_temp.loese(:'s', 1, false) ->> 'grund_code' as k3 \gset
select pg_temp.loese(:'s', 1, true) as k4 \gset
select is(:'k1' || ',' || :'k2' || ',' || :'k3' || ',' || (:'k4'::jsonb ->> 'grund_code'), 'kern,kern,kern,gemischt',
          '1H Ablauf: drei Kernaufgaben, die vierte eingemischt');
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s', :'k_e') as d \gset
select is(:'d'::jsonb -> 'schritt_details', '{"mischanteil": 0.30}'::jsonb, '1G eingemischt: Mischanteil im letzten Schritt');
select is(:'d'::jsonb -> 'heute' -> 0 ->> 'abschnitt', 'ankommen', '1H erste Zeile: ankommen');
select is((:'d'::jsonb -> 'heute' -> 0 ->> 'zeit')::timestamptz,
          (select min(zugewiesen_am) from session_tablets where session_id = :'s' and student_id = :'k_e'), '1H ankommen: Zeit der Tablet-Zuweisung');
select is((select sum((h ->> 'von')::int) || '/' || sum((h ->> 'richtig')::int) || '/' || sum((h ->> 'hinweise')::int)
             from jsonb_array_elements(:'d'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'warmup'),
          '3/1/0', '1H warmup: 3 Aufgaben, 1 richtig, keine Hinweise');
select is((select h - 'label' from jsonb_array_elements(:'d'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'kern'),
          '{"abschnitt": "kern", "skill_key": "zz_a2_s1", "richtig": 1, "von": 3, "hinweise": 1}'::jsonb,
          '1H kern: 1 von 3 (richtig nach Hinweis zaehlt nicht), 1 Hinweis');
select is((select (h ->> 'von') || '/' || (h ->> 'richtig') || '/' || (h ->> 'hinweise')
             from jsonb_array_elements(:'d'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'eingemischt'),
          '1/1/0', '1H eingemischt: eigene Zeile');
select is((select h ->> 'skill_key' from jsonb_array_elements(:'d'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'eingemischt'),
          :'k4'::jsonb ->> 'skill_key', '1H eingemischt: Skill der eingemischten Aufgabe');
-- 1M: der Warm-up-Skill steht mit Zahlen in "heute" (Beleg fuer den Mastery-Kandidaten, wenn er heute dran war).
select ok(exists (select 1 from jsonb_array_elements(:'d'::jsonb -> 'heute') h
                   where h ->> 'abschnitt' = 'warmup' and h ->> 'skill_key' = :'sig'::jsonb ->> 'skill_key'
                     and (h ->> 'von')::int = (:'sig'::jsonb ->> 'warmup_aufgaben')::int),
          '1M Warm-up-Zeile je Skill mit Zahl');

-- Fenster: Lea, ohne Mischen, fuenf Kernaufgaben falsch -> der sechste Schritt traegt 0 von 5, Ziel 0,8, leichter.
-- (Fuenf richtige machen s1 sicher; dann wechselt die Engine in die Vertiefung eines anderen Skills ohne Fenster.)
select pg_temp.stell('mischanteil', '0');
select pg_temp.kind_mit('ZZ Lea C3', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_l \gset
select pg_temp.neue_session(array[:'k_l']::uuid[], 1) as s_l \gset
select pg_temp.checkin(:'s_l', 1);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s_l', :'k_l', 'schulthema');
select pg_temp.uhr(:'s_l', 20);
select count(*) from pg_temp.lauf(:'s_l', 1, 5, false);
select pg_temp.act_as(:'coach_a');
select is(coach_kind_detail(:'s_l', :'k_l') -> 'schritt_details', '{}'::jsonb, '2 Schritt vor der Auswertung: details leer');
select pg_temp.schritt(:'s_l', 1) as l6 \gset
select pg_temp.act_as(:'coach_a');
select is(coach_kind_detail(:'s_l', :'k_l') -> 'schritt_details',
          '{"richtig": 0, "von": 5, "ziel": 0.80, "aenderung": -1}'::jsonb, '1G Fenster ausgewertet: 0 von 5, Ziel 0,8, leichter');
select is(:'l6'::jsonb ->> 'grund_code', 'kern', '1G grund_code unveraendert');
select ok(:'l6'::jsonb ->> 'grund' like '%eine Stufe leichter (0 von 5 ohne Hinweis richtig)%', '1G grund-Text unveraendert');
select is((select details from session_schritte where session_id = :'s_l' order by id desc limit 1),
          '{"richtig": 0, "von": 5, "ziel": 0.80, "aenderung": -1}'::jsonb, '1G in session_schritte.details gespeichert');
select pg_temp.stell('mischanteil', '0.3');

-- ── 3) Tablet unveraendert ─────────────────────────────────────────────────
select pg_temp.act_as(pg_temp.tablet(1));
select session_naechster_schritt(:'s_l', null)::text as tab_s, tablet_stand()::text as tab_t \gset
select ok(:'tab_s' !~ '"details"|mischanteil|aenderung|"ziel"|"richtig"|"von"',
          '3 session_naechster_schritt ohne details (Whitelist session_schritt_oeffentlich)');
select ok(:'tab_t' !~ '"details"|mischanteil|aenderung|pfad_vorschlag|schritt_details|erklaer_kernideen|"heute"',
          '3 tablet_stand ohne neue Felder');
reset role;
select ok(not has_table_privilege('authenticated', 'public.session_schritte', 'select')
          and not has_table_privilege('anon', 'public.session_schritte', 'select')
          and not has_column_privilege('authenticated', 'public.session_schritte', 'details', 'select'),
          '3 session_schritte: kein Lesen fuer Schueler-, Platz- und Coach-Konten (nur ueber SECURITY DEFINER)');
select throws_ok(format('update session_schritte set details = %L where session_id = %L', '{"x":1}', :'s_l'),
                 null, null, '3 Append-only-Sperre gilt auch fuer details');
select is((select tgname::text from pg_trigger where tgrelid = 'public.session_schritte'::regclass and not tgisinternal),
          'session_schritte_nur_anhaengen', '3 Trigger unveraendert');

-- ── 1G im Zielbereich (Rasit 08.10.) ─────────────────────────────────────
-- Stufe bleibt: Ziel 0,6 (Band 0,5 bis 0,7), richtig/falsch im Wechsel -> 3 von 5, aenderung 0. Damit s1 dabei
-- offen bleibt, braucht "sicher" hier sechs richtige ohne Hinweis (sonst wechselt die Engine nach zwei den Skill).
select pg_temp.stell('mischanteil', '0'), pg_temp.stell('ziel_erfolgsquote', '0.6'),
       pg_temp.stell('mastery_richtig_ohne_hinweis', '6');
select pg_temp.kind_mit('ZZ Ben C3', 'zz_a2_terme', '{zz_a2_v1,zz_a2_v2}', '{zz_a2_s1}') as k_b \gset
select pg_temp.neue_session(array[:'k_b']::uuid[], 1) as s_b \gset
select pg_temp.checkin(:'s_b', 1);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s_b', :'k_b', 'schulthema');
select pg_temp.uhr(:'s_b', 20);
select count(*) from (select pg_temp.loese(:'s_b', 1, n % 2 = 1) from generate_series(1, 5) n) x;
select pg_temp.schritt(:'s_b', 1) as b6 \gset
select pg_temp.act_as(:'coach_a');
select is(coach_kind_detail(:'s_b', :'k_b') -> 'schritt_details',
          '{"richtig": 3, "von": 5, "ziel": 0.6, "aenderung": 0}'::jsonb, '1G Fenster im Zielbereich: 3 von 5, Stufe bleibt');
select is((:'b6'::jsonb ->> 'skill_key') || ':' || (:'b6'::jsonb ->> 'grund_code'), 'zz_a2_s1:kern',
          '1G im Zielbereich: selber Skill, grund_code unveraendert');
select pg_temp.stell('mischanteil', '0.3'), pg_temp.stell('ziel_erfolgsquote', '0.8'),
       pg_temp.stell('mastery_richtig_ohne_hinweis', '2');

-- ── 1X) Erklaersequenz mit zwei Kernideen ──────────────────────────────────
-- n1 bekommt Variante B fuer Kernidee 1 und eine zweite Kernidee; der Check kennt das Fehlbild.
select pg_temp.aufgaben('zz_a2_n1', 1, 'ready', '{check}', 'c3-check');
update task_solutions set acceptance = acceptance || '{"known_errors": {"0": "vorzeichen_ignoriert"}}'
 where task_id in (select id from tasks where source_ref like 'a2-check-%');
select pg_temp.act_as(:'admin');
select public.erklaer_schritt_speichern(:'kern_n1', 'B', a.art, 'ZZ C3 Variante B ' || a.art, null, '{}')
  from (values ('erklaerung'), ('beispiel')) a(art);
select public.erklaer_kernidee_speichern(null, 'zz_a2_n1', 2, 'ZZ Achsenabschnitt ablesen', 'mensch') as kern_2 \gset
select public.erklaer_schritt_speichern(:'kern_2', 'A', a.art, 'ZZ C3 Kernidee 2 ' || a.art, null, '{}')
  from (values ('erklaerung'), ('beispiel')) a(art);
select public.erklaer_check_setzen(:'kern_2', (select id from tasks where source_ref = 'c3-check-1'), 1);
do $$
declare r record;
begin
  for r in select s.id, s.kernidee_id from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
            where k.skill_key = 'zz_a2_n1' and s.status <> 'freigegeben' loop
    if (select status from erklaer_schritt where id = r.id) = 'entwurf' then
      perform public.erklaer_status_setzen('schritt', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
    end if;
    perform public.erklaer_status_setzen('schritt', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.kernidee_id));
  end loop;
  for r in select id, status from erklaer_kernidee where skill_key = 'zz_a2_n1' and status <> 'freigegeben' loop
    if r.status = 'entwurf' then
      perform public.erklaer_status_setzen('kernidee', r.id, 'geprueft', (select pruef_version from erklaer_kernidee where id = r.id));
    end if;
    perform public.erklaer_status_setzen('kernidee', r.id, 'freigegeben', (select pruef_version from erklaer_kernidee where id = r.id));
  end loop;
end $$;
select set_config('request.jwt.claims', '', true);
select pg_temp.kind_mit('ZZ Jonas C3', 'zz_a2_linear', '{zz_a2_v2}') as k_j \gset
select pg_temp.neue_session(array[:'k_j']::uuid[], 1) as s_j \gset
select pg_temp.checkin(:'s_j', 1);
select pg_temp.act_as(:'coach_a');
select checkin_coach_setzen(:'s_j', :'k_j', 'schulthema');
select pg_temp.uhr(:'s_j', 20);
select is(pg_temp.schritt_tablet(:'s_j', 1) ->> 'art', 'erklaerung', '1X Erklaersequenz vorgeschaltet');
select (erklaer_start(:'s_j', null, 'zz_a2_n1')) -> 'check' ->> 'task_id' as chk1 \gset
select erklaer_check_abgeben(:'s_j', null, :'chk1', '{"text":"0"}') ->> 'aktion' as nach_falsch \gset
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s_j', :'k_j') as dj \gset
select is(jsonb_array_length(:'dj'::jsonb -> 'erklaer_kernideen'), 2, '1X beide Kernideen');
select is((select string_agg(k ->> 'titel', ' | ' order by (k ->> 'nr')::int) from jsonb_array_elements(:'dj'::jsonb -> 'erklaer_kernideen') k),
          'ZZ Steigung pro Schritt | ZZ Achsenabschnitt ablesen', '1X Titel aller Kernideen in Reihenfolge');
select is((:'dj'::jsonb -> 'erklaer_kernideen' -> 0) - 'titel',
          jsonb_build_object('nr', 1, 'stand', 'laeuft', 'runde', 2, 'variante', 'B', 'fehlbild', :'fb_text'),
          '1X Kernidee 1: laeuft in Runde 2, Variante B, Fehlbild der letzten Runde als Klartext');
select is((:'dj'::jsonb -> 'erklaer_kernideen' -> 1) - 'titel',
          '{"nr": 2, "stand": "offen", "runde": null, "variante": null, "fehlbild": null}'::jsonb, '1X Kernidee 2: offen');
select is((select h - 'label' from jsonb_array_elements(:'dj'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'erklaerung'),
          '{"abschnitt": "erklaerung", "skill_key": "zz_a2_n1", "sicher": 0, "aktuell": 1, "runde": 2}'::jsonb,
          '1H erklaerung: Kernideen sicher, aktuelle Kernidee, Runde');
-- Runde 2 richtig -> Kernidee 1 sicher, Kernidee 2 laeuft.
select pg_temp.act_as(pg_temp.tablet(1));
select (select f.check_task_id from erklaer_fortschritt f where f.session_id = :'s_j' order by f.id desc limit 1) as chk2 \gset
select erklaer_check_abgeben(:'s_j', null, :'chk2', '{"text":"7"}') ->> 'aktion' as nach_richtig \gset
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s_j', :'k_j') as dj2 \gset
select is((select string_agg(k ->> 'stand', ',' order by (k ->> 'nr')::int) from jsonb_array_elements(:'dj2'::jsonb -> 'erklaer_kernideen') k),
          'sicher,laeuft', '1X nach richtigem Check: Kernidee 1 sicher, Kernidee 2 laeuft');
select is((select (h ->> 'sicher') || '/' || (h ->> 'aktuell') || '/' || (h ->> 'runde')
             from jsonb_array_elements(:'dj2'::jsonb -> 'heute') h where h ->> 'abschnitt' = 'erklaerung'),
          '1/2/1', '1H erklaerung: eine sicher, Kernidee 2 in Runde 1');

-- ── 1-0) Kind ohne Ereignisse ──────────────────────────────────────────────
select pg_temp.kind('ZZ Ida C3') as k_i \gset
insert into session_students (session_id, student_id) values (:'s_j', :'k_i');
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s_j', :'k_i') as di \gset
select is(:'di'::jsonb -> 'heute', '[]'::jsonb, '1-0 ohne Ereignisse: heute leer');
select is(:'di'::jsonb -> 'erklaer_kernideen', '[]'::jsonb, '1-0 ohne Ereignisse: keine Kernideen');
select is(:'di'::jsonb -> 'pfad_vorschlag', 'null'::jsonb, '1-0 ohne Ereignisse: kein Pfad-Vorschlag');
select is(:'di'::jsonb -> 'schritt_details', '{}'::jsonb, '1-0 ohne Ereignisse: schritt_details leer');

-- ── 2) Signal vor A2d ─────────────────────────────────────────────────────
reset role;
insert into session_ereignisse (session_id, student_id, typ, payload)
values (:'s_j', :'k_i', 'signal', '{"art": "entscheidung", "skill_key": "zz_a2_v2", "ziel_skill_key": "zz_a2_n1",
        "grund": "Entscheidung: eine Stufe tiefer?", "grund_code": "entscheidung_tiefer"}');
select pg_temp.act_as(:'coach_a');
select coach_kind_detail(:'s_j', :'k_i') -> 'pfad_vorschlag' as alt \gset
select is(:'alt'::jsonb -> 'warmup_aufgaben', 'null'::jsonb, '2 Signal vor A2d: warmup_aufgaben null');
select is(:'alt'::jsonb -> 'warmup_richtig', 'null'::jsonb, '2 Signal vor A2d: warmup_richtig null');
select is(:'alt'::jsonb ->> 'label', 'ZZ Proportionale Zuordnung', '2 Signal vor A2d: Label aus skill_key');
select is(:'alt'::jsonb -> 'fehlbild', 'null'::jsonb, '2 ohne Fehlbild: null');
select is(:'alt'::jsonb ->> 'offen', 'true', '2 Signal vor A2d: offen');

-- ── 4) Rechte ─────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k_e'), '42501', null, '4 fremder Coach -> 42501');
select pg_temp.act_as(:'ohne');
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k_e'), '42501', null, '4 Konto ohne Profil -> 42501');
select pg_temp.act_as(:'schueler');
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k_e'), '42501', null, '4 Schuelerkonto -> 42501');
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format('select coach_kind_detail(%L, %L)', :'s', :'k_e'), '42501', null, '4 Tablet -> 42501');
select pg_temp.act_as(:'admin');
select is(coach_kind_detail(:'s', :'k_e') -> 'pfad_vorschlag' ->> 'skill_key', :'sig'::jsonb ->> 'skill_key', '4 Admin darf');
select ok(not has_function_privilege('anon', 'public.coach_kind_detail(uuid, uuid)', 'execute'), '4 anon darf nicht');
select ok((select p.prosecdef and array_to_string(p.proconfig, ',') like 'search_path=%' from pg_proc p
            where p.oid = 'public.coach_kind_detail(uuid, uuid)'::regprocedure), '4 SECURITY DEFINER mit festem search_path');

select * from finish();
rollback;
