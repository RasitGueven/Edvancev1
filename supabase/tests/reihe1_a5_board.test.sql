-- ============================================================================
-- Reihe 1 · A5 Lena-Board fuer Bauformen (Migration 20261027143548) mit den Pilot-Bauformen aus A4 (NP-2, WZ-1).
--   Abnahme 6: Lena sieht NP-2 mit sechs Beispielen, je Stufe eines; „Andere Beispiele“ zeigt andere; „passt“ setzt
--              zur Freigabe; nach der Sammelfreigabe liefert aufgabe_ziehen eine Instanz.
--   Abnahme 7: gemeldete Instanz wird nicht gezogen; nach der zweiten Meldung ist die Bauform pausiert und unter
--              „Auffaellig“.
--   Coach-Pruefgespraeche: Lena prueft einzeln.
-- Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(16);

\set lena  '2c600000-0000-4000-8000-0000000000b5'
\set admin '2c600000-0000-4000-8000-0000000000a5'
\set coach '2c600000-0000-4000-8000-0000000000c5'
insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena', 'r1a5-lena@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin', 'r1a5-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach', 'r1a5-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena', 'r1a5-lena@test.local', 'coach', 'R1A5 Lena', true),
  (:'admin', 'r1a5-admin@test.local', 'admin', 'R1A5 Admin', false),
  (:'coach', 'r1a5-coach@test.local', 'coach', 'R1A5 Coach', false);
create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
select id as np2 from bauformen where schluessel = 'NP-2' \gset

-- ── Abnahme 6 ───────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach');
select throws_ok('select * from bauform_pruef_liste()', '42501', null, '0 ein Coach ohne Pruefrecht sieht das Board nicht');
select pg_temp.act_as(:'lena');
select ok(exists (select 1 from bauform_pruef_liste() where schluessel = 'NP-2' and status = 'zur_pruefung'),
          '6 NP-2 steht zur Pruefung im Board');
select bauform_pruef_detail(:'np2', 1) as d1 \gset
select bauform_pruef_detail(:'np2', 2) as d2 \gset
select is(jsonb_array_length(:'d1'::jsonb -> 'beispiele'), 6, '6 sechs Beispiele');
select is((select count(distinct (e ->> 'stufe'))::int from jsonb_array_elements(:'d1'::jsonb -> 'beispiele') e), 4,
          '6 je Stufe mindestens eines (Stufen 1–4)');
select is((select count(*)::int from jsonb_array_elements(:'d1'::jsonb -> 'beispiele') e
            where e -> 'payload' ->> 'kind' = 'format' and e -> 'loesung' ? 'menge' and jsonb_array_length(e -> 'hinweise') = 3), 6,
          '6 jedes Beispiel wie auf dem Tablet, mit Loesung, Fehlbildern und drei Hinweisen');
select isnt((select jsonb_agg(e ->> 'task_id' order by e ->> 'task_id') from jsonb_array_elements(:'d1'::jsonb -> 'beispiele') e),
            (select jsonb_agg(e ->> 'task_id' order by e ->> 'task_id') from jsonb_array_elements(:'d2'::jsonb -> 'beispiele') e),
            '6 „Andere Beispiele“ zeigt andere');
select is(bauform_pruefen(:'np2', (:'d1'::jsonb ->> 'version')::int, 'passt') ->> 'status', 'zur_freigabe',
          '6 passt setzt zur Freigabe');
select pg_temp.act_as(:'admin');
select cmp_ok(bauform_freigeben('quadratische_funktionen_gleichungen'), '>=', 1, '6 Sammelfreigabe der Reihe');
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
insert into leads (full_name, first_name, status, class_level) values ('ZZ R1A5 Kind', 'ZZ', 'vertrag', 9);
insert into students (class_level) values (9) returning id as kind \gset
select aufgabe_ziehen(:'kind', 'gleichung_quadr_faktor', 'uebung', 3) as gezogen \gset
select ok((select bauform_id = :'np2'::uuid and stufe = 3 and status = 'ready' from tasks where id = :'gezogen'),
          '6 nach der Sammelfreigabe liefert aufgabe_ziehen eine Instanz der Stufe 3');

-- ── Abnahme 7 ───────────────────────────────────────────────────────────────
select pg_temp.act_as(:'coach');
select aufgabe_melden(:'gezogen', 'ZZ Loesung stimmt nicht');
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
select ok(aufgabe_ziehen(:'kind', 'gleichung_quadr_faktor', 'uebung', 3) is distinct from :'gezogen'::uuid,
          '7 die gemeldete Instanz wird nicht mehr gezogen');
select pg_temp.act_as(:'coach');
select aufgabe_melden(aufgabe_zwilling(:'kind', :'gezogen'), 'ZZ auch falsch')
  from (select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true)) x;
select is((select status from bauformen where id = :'np2'), 'pausiert', '7 nach der zweiten Meldung ist die Bauform pausiert');
select pg_temp.act_as(:'lena');
select is((select count(*)::int from bauform_auffaellig() where bauform_id = :'np2'), 2, '7 beide stehen unter „Auffaellig“');
select ok((select meldungen -> 0 ->> 'grund' = 'ZZ Loesung stimmt nicht' from bauform_auffaellig() where task_id = :'gezogen'),
          '7 mit dem Grund der Meldung');

-- ── Coach-Pruefgespraeche ───────────────────────────────────────────────────
reset role;
insert into skill_pruefung (skill_key, frage, erwartung, kriterium, status, quelle)
values ('gleichung_quadr_faktor', 'ZZ Warum hat x² = 3x zwei Lösungen?', 'ZZ x ausklammern', 'ZZ nennt beide', 'entwurf', 'ki')
returning id as sp \gset
select pg_temp.act_as(:'lena');
select throws_ok(format('select skill_pruefung_entscheiden(%L, %L)', :'sp', 'passt_nicht'), '22023', null,
                 'P passt nicht braucht eine Notiz');
select is(skill_pruefung_entscheiden(:'sp', 'passt'), 'geprueft', 'P passt setzt geprueft');
select is((select geprueft_von from skill_pruefung_liste() where id = :'sp'), 'R1A5 Lena', 'P mit Lenas Namen');

select * from finish();
rollback;
