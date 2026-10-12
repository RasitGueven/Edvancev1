-- Gemeinsame Ausgangslage der slots_*.test.sql (Paket SL1). Wird per \ir eingebunden, läuft in der
-- Transaktion des Tests (begin … rollback). Alle Namen erfunden.
--
--   Konten: Admin, Coaches A–D, Elternteil, Schülerkonto, Konto ohne Profil, Tablet 1
--   Räume:  Raum 1, Raum 2, Raum 3 (aktiv ab 01.01.2026)
--   Stammschichten: Coach A in Raum 1 und Coach B in Raum 2, Mo–Fr, 14–20 Uhr (Raum 3 ohne Schicht)
--   Hilfen: pg_temp.als(uid), pg_temp.als_system(), pg_temp.zeit(stunde), pg_temp.raum(name),
--           pg_temp.kind(name, paket, laufzeit, beginn, stichtag, fach) -> student_id, pg_temp.vertrag(student)

\set admin   'eeeeeeee-5100-4000-8000-000000000001'
\set coach_a 'eeeeeeee-5100-4000-8000-000000000002'
\set coach_b 'eeeeeeee-5100-4000-8000-000000000003'
\set coach_c 'eeeeeeee-5100-4000-8000-000000000004'
\set coach_d 'eeeeeeee-5100-4000-8000-000000000005'
\set eltern  'eeeeeeee-5100-4000-8000-000000000006'
\set schueler 'eeeeeeee-5100-4000-8000-000000000007'
\set ohne_profil 'eeeeeeee-5100-4000-8000-000000000008'
\set tablet  'eeeeeeee-5100-4000-8000-000000000009'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'sl1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'coach_a', 'coach-a'), (:'coach_b', 'coach-b'), (:'coach_c', 'coach-c'),
               (:'coach_d', 'coach-d'), (:'eltern', 'eltern'), (:'schueler', 'schueler'), (:'ohne_profil', 'ohne'),
               (:'tablet', 'tablet')) v(u, n);

insert into profiles (id, email, role, full_name) values
  (:'admin', 'sl1-admin@test.local', 'admin', 'ZZ Admin'),
  (:'coach_a', 'sl1-coach-a@test.local', 'coach', 'Coach Anna'),
  (:'coach_b', 'sl1-coach-b@test.local', 'coach', 'Coach Ben'),
  (:'coach_c', 'sl1-coach-c@test.local', 'coach', 'Coach Cem'),
  (:'coach_d', 'sl1-coach-d@test.local', 'coach', 'Coach Dana'),
  (:'eltern', 'sl1-eltern@test.local', 'parent', 'ZZ Eltern'),
  (:'schueler', 'sl1-schueler@test.local', 'student', 'ZZ Schüler'),
  (:'tablet', 'sl1-tablet@test.local', 'student', 'ZZ Tablet 1');
insert into platz_devices (profile_id, label, tablet_nr) values (:'tablet', 'ZZ SL1 Tablet 1', 1);

create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;
create or replace function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claim.role', 'service_role', true);
end $$;
create or replace function pg_temp.zeit(p_stunde int) returns uuid language sql as $$
  select id from public.slot_zeiten where beginn = make_time(p_stunde, 0, 0) and inaktiv_ab is null
$$;
create or replace function pg_temp.raum(p_name text) returns uuid language sql as $$
  select id from public.raeume where name = p_name
$$;

insert into public.raeume (name, aktiv_ab) values ('Raum 1', '2026-01-01'), ('Raum 2', '2026-01-01'), ('Raum 3', '2026-01-01');
insert into public.stammschichten (coach_id, wochentag, slot_zeit_id, raum_id, gueltig_ab)
select c.coach, w, z.id, pg_temp.raum(c.raum), date '2026-01-01'
  from (values (:'coach_a'::uuid, 'Raum 1'), (:'coach_b'::uuid, 'Raum 2')) c(coach, raum),
       generate_series(1, 5) w, public.slot_zeiten z;

-- Kind mit Lead und abgeschlossenem Vertrag (Paket, Laufzeit, Einheiten aus tier_laufzeiten).
create or replace function pg_temp.kind(p_name text, p_paket text, p_laufzeit int, p_beginn date, p_stichtag date,
                                        p_fach text default 'Mathematik') returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values (p_name, split_part(p_name, ' ', 1), 'vertrag', 8)
  returning id into v_lead;
  insert into students (class_level) values (8) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, student_id,
                         vertragsbeginn, vertrag_ende, widerruf_bis, tier_id, laufzeit_monate, einheiten, fach, klasse,
                         kind_vorname, kind_nachname)
  select v_lead, 'abgeschlossen', 'aktiv', now(), p_beginn - 30, 'vor_ort', v_st, p_beginn, p_stichtag, p_beginn + 13,
         t.id, p_laufzeit, tl.einheiten, p_fach, 8, split_part(p_name, ' ', 1), split_part(p_name, ' ', 2)
    from tiers t join tier_laufzeiten tl on tl.tier_id = t.id and tl.laufzeit_monate = p_laufzeit
   where t.name = p_paket;
  return v_st;
end $$;
create or replace function pg_temp.vertrag(p_student uuid) returns uuid language sql as $$
  select id from public.vertraege where student_id = p_student order by vertragsbeginn desc limit 1
$$;
-- Ein Stammplatz-Zeilen-Array: pg_temp.zeilen('2:16:woechentlich', '4:16:a_woche')
create or replace function pg_temp.zeilen(variadic p text[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('wochentag', split_part(x, ':', 1)::int,
                                      'slot_zeit_id', pg_temp.zeit(split_part(x, ':', 2)::int),
                                      'takt', split_part(x, ':', 3)))
    from unnest(p) x
$$;
create or replace function pg_temp.termin(p_student uuid, p_datum date) returns uuid language sql as $$
  select id from public.kind_termine where student_id = p_student and datum = p_datum
   order by (zustand in ('planned', 'present', 'unexcused')) desc, angelegt_am desc limit 1
$$;
