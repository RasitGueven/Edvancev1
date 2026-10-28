-- ============================================================================
-- Reihe 1 · D4 Themenliste (Anforderung Themenbaum §4, Abnahme 1, 4, 7).
--   1) ohne Schulplan, Klasse 6: zuerst 5/6, dann 7/8 und 9/10, dann nichts Früheres; keine Quellenangabe
--   2) mit Schulplan, Klasse 9: Plan-Reihenfolge der Schule im Doppeljahrgang, „Kl. 10“ und „9–10“, dann 7/8, 5/6
--   3) aktuell (Schulthema, bevorstehende KA) und behandelt; Skills je Thema
--   4) Rechte: Kind selbst, kein fremdes Kind
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set k6 'dddddddd-d400-4000-8000-000000000001'
\set k9 'dddddddd-d400-4000-8000-000000000002'
insert into auth.users (id, email, instance_id, aud, role)
select u, 'd4-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'k6'::uuid, 'k6'), (:'k9', 'k9')) v(u, n);
insert into profiles (id, email, role, full_name) values (:'k6', 'd4-k6@test.local', 'student', 'ZZ Sechs'), (:'k9', 'd4-k9@test.local', 'student', 'ZZ Neun');
create or replace function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

-- Eigener Katalog: je Doppeljahrgang zwei Themen; die Bestandsthemen stören die Reihenfolge nicht (nur z_*-Themen geprüft).
insert into themen (thema_key, fach, klasse, label, stufe, sort)
select k, 'mathematik', kl, 'ZZ ' || k, 'erste', s from (values
  ('z5a', 5, 9001), ('z5b', 5, 9002), ('z7a', 7, 9003), ('z7b', 7, 9004), ('z9a', 9, 9005), ('z9b', 9, 9006),
  ('z9c', 9, 9007)) v(k, kl, s);
insert into skills (skill_key, label, fach, klasse_herkunft, fundament_tiefe) values ('zs9', 'ZZ S9', 'Mathematik', 9, 1);
insert into skill_thema (skill_key, thema_key) values ('zs9', 'z9b');

insert into students (class_level, profile_id) values (6, :'k6') returning id as s6 \gset
insert into schulen (name) values ('ZZ Schule') returning id as schule \gset
insert into leads (full_name, first_name, status, class_level) values ('ZZ Neun', 'ZZ', 'vertrag', 9) returning id as lead9 \gset
insert into students (class_level, profile_id, schule_id) values (9, :'k9', :'schule') returning id as s9 \gset
update leads set converted_student_id = :'s9' where id = :'lead9';
insert into schul_themenplan (schule_id, fach, klasse, position, thema_key, uv_titel, quelle_url, stand)
values (:'schule', 'mathematik', 9, 1, 'z9b', 'UV B', 'https://zz.invalid', current_date), (:'schule', 'mathematik', 9, 2, 'z9a', 'UV A', 'https://zz.invalid', current_date),
       (:'schule', 'mathematik', 10, 1, 'z9a', 'UV A2', 'https://zz.invalid', current_date), (:'schule', 'mathematik', 10, 2, 'z7a', 'UV Wiederholung', 'https://zz.invalid', current_date);
insert into lead_themen (lead_id, fach, thema_key, status, quelle) values (:'lead9', 'mathematik', 'z9a', 'aktuell', 'gespraech'),
  (:'lead9', 'mathematik', 'z9b', 'behandelt', 'gespraech');

-- ── 1) ohne Schulplan, Klasse 6 ─────────────────────────────────────────────
select pg_temp.als(:'k6');
select results_eq($$select thema_key, gruppe from themenbaum_themen(get_my_student_id()) where thema_key ~ '^z[579][ab]$' order by reihenfolge$$,
  $$values ('z5a'::text, 5), ('z5b', 5), ('z7a', 7), ('z7b', 7), ('z9a', 9), ('z9b', 9)$$,
  '1 Klasse 6 ohne Schulplan: eigener Doppeljahrgang, dann was noch kommt');
select is((select count(*)::int from themenbaum_themen(get_my_student_id()) where plan_von is not null), 0,
          '1 ohne Schulplan keine Planklassen, keine Quellenangabe');
reset role;

-- ── 2) mit Schulplan, Klasse 9 ──────────────────────────────────────────────
select pg_temp.als(:'k9');
select results_eq($$select thema_key, plan_von, plan_bis from themenbaum_themen(get_my_student_id()) where thema_key ~ '^z[579][abc]$' order by reihenfolge$$,
  $$values ('z9b'::text, 9, 9), ('z9a', 9, 10), ('z7a', 10, 10), ('z9c', null, null), ('z7b', null, null), ('z5a', null, null), ('z5b', null, null)$$,
  '2 Plan-Reihenfolge im Doppeljahrgang (Planklassen für „Kl. 10“ und „9–10“), nicht eingeplantes z9c am Ende, dann 7/8, 5/6');
-- ── 3) aktuell, behandelt, Skills ───────────────────────────────────────────
select results_eq($$select thema_key, aktuell, behandelt, skill_keys from themenbaum_themen(get_my_student_id()) where thema_key in ('z9a', 'z9b') order by 1$$,
  $$values ('z9a'::text, true, false, '{}'::text[]), ('z9b', false, true, '{zs9}'::text[])$$, '3 aktuell, behandelt, Skills');
reset role;
insert into lead_klassenarbeiten (lead_id, fach, schuljahr, nr, datum, thema_keys, status, quelle) values
  (:'lead9', 'mathematik', '2026/27', 1, current_date + 5, array['z7b'], 'bevorstehend', 'admin'),
  (:'lead9', 'mathematik', '2026/27', 2, current_date - 5, array['z5a'], 'bevorstehend', 'admin'),
  (:'lead9', 'mathematik', '2026/27', 3, current_date + 6, array['z5b'], 'geschrieben', 'admin');
select pg_temp.als(:'k9');
select results_eq($$select thema_key, aktuell from themenbaum_themen(get_my_student_id()) where thema_key in ('z7b', 'z5a', 'z5b') order by 1$$,
  $$values ('z5a'::text, false), ('z5b', false), ('z7b', true)$$, '3 Klassenarbeit: nur bevorstehend und ab heute ist aktuell');
-- ── 4) Rechte ───────────────────────────────────────────────────────────────
select throws_ok(format('select * from themenbaum_themen(%L)', :'s6'), '42501', null, '4 fremdes Kind: kein Zugriff');
reset role;
insert into auth.users (id, email, instance_id, aud, role) values ('dddddddd-d400-4000-8000-000000000009', 'd4-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values ('dddddddd-d400-4000-8000-000000000009', 'd4-admin@test.local', 'admin', 'ZZ Admin');
select pg_temp.als('dddddddd-d400-4000-8000-000000000009');
select ok((select count(*) from themenbaum_themen(:'s9')) > 0, '4 Admin liest');
reset role;

select * from finish();
rollback;
