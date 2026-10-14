-- ============================================================================
-- K1b — Eltern bekommen kein Konto (Entscheidung Rasit 14.10.2026).
--
-- vertrag_abschluss ruft vertrag_abschliessen jetzt immer mit p_parent_uid = null und
-- p_parent_email = null auf. Die Funktion hat dafuer schon den Zweig
-- "if p_parent_uid is not null" — keine Migration. Hier belegt fuer alle vier Wege:
-- regulaer und Pilot, je vor Ort und Papier.
--
-- Je Abschluss: laeuft durch, eltern_email bleibt im Vertrag, keine parent_student-Zeile
-- fuer das Kind, kein Profil mit Rolle parent fuer die Elternadresse, Zahl der
-- Eltern-Profile unveraendert.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

\ir slots_fixture.sql
select pg_temp.als(:'admin');

\set k_rv 'eeeeeeee-1b00-4000-8000-000000000001'
\set k_rp 'eeeeeeee-1b00-4000-8000-000000000002'
\set k_pv 'eeeeeeee-1b00-4000-8000-000000000003'
\set k_pp 'eeeeeeee-1b00-4000-8000-000000000004'
insert into auth.users (id, email, instance_id, aud, role)
select u, 'k1b-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'k_rv'::uuid, 'rv'), (:'k_rp', 'rp'), (:'k_pv', 'pv'), (:'k_pp', 'pp')) v(u, n);

create or replace function pg_temp.lead(p_name text) returns uuid language sql as $$
  insert into public.leads (full_name, first_name, status, class_level, subjects, contact_email, consent_dsgvo_at)
  values (p_name, split_part(p_name, ' ', 1), 'lsa_fertig', 8, array['Mathematik'], 'k1b-eltern@test.local', now())
  returning id
$$;
create or replace function pg_temp.zust(variadic p text[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object('schluessel', d.schluessel, 'version', d.version))
    from public.vertrag_dokumente d where d.aktiv and d.schluessel = any(p)
$$;

select count(*)::int as eltern_vorher from profiles where role = 'parent' \gset

-- Die drei Pruefungen je Abschluss (nach dem Abschluss aufgerufen).
create or replace function pg_temp.ohne_eltern(p_vertrag uuid, p_was text) returns setof text language plpgsql as $$
declare v record;
begin
  select * into v from public.vertraege where id = p_vertrag;
  return next is(v.eltern_email, 'k1b-eltern@test.local', p_was || ': eltern_email bleibt im Vertrag');
  return next is((select count(*)::int from public.parent_student ps where ps.student_id = v.student_id), 0,
                 p_was || ': keine parent_student-Zeile');
  return next is((select count(*)::int from public.profiles p where lower(p.email) = 'k1b-eltern@test.local'), 0,
                 p_was || ': kein Profil fuer die Elternadresse');
end $$;

-- ── 1) Regulär vor Ort ─────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Rosa Vorort')) as rv \gset
update vertraege set tier_id = (select id from tiers where name = 'Basic'), laufzeit_monate = 12,
                     vertragsbeginn = '2027-11-01', kind_vorname = 'Rosa', kind_nachname = 'Vorort', klasse = 8,
                     eltern_email = 'k1b-eltern@test.local'
 where id = :'rv';
insert into vertrag_bankdaten (vertrag_id, iban) values (:'rv', 'DE89370400440532013000');
select lives_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig', 'sepa', p_student_uid => %L,
                         p_student_email => 'k1b-rv@test.local', p_parent_uid => null, p_parent_email => null)$f$,
                       :'rv', pg_temp.zust('vertrag', 'sepa_mandat', 'agb', 'widerruf', 'datenschutz_vertrag'), :'k_rv'),
                '1 regulär vor Ort: Abschluss ohne Elternkonto');
select is((select role from profiles where id = :'k_rv'), 'student', '1 regulär vor Ort: Schülerkonto angelegt');
select * from pg_temp.ohne_eltern(:'rv', '1 regulär vor Ort');

-- ── 2) Regulär Papier ──────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Rolf Papier')) as rp \gset
update vertraege set tier_id = (select id from tiers where name = 'Basic'), laufzeit_monate = 12,
                     vertragsbeginn = '2027-11-01', kind_vorname = 'Rolf', kind_nachname = 'Papier', klasse = 8,
                     eltern_email = 'k1b-eltern@test.local'
 where id = :'rp';
insert into vertrag_bankdaten (vertrag_id, iban) values (:'rp', 'DE89370400440532013000');
select lives_ok(format($f$select vertrag_versenden(%L, 'druck')$f$, :'rp'), '2 regulär Papier: Versand');
select lives_ok(format($f$select vertrag_abschliessen(%L, 'papier', p_unterschrieben_am => '2027-10-20',
                         p_eingang_datum => '2027-10-22', p_scan_pfad => 'k1b/scan-rp.pdf', p_student_uid => %L,
                         p_student_email => 'k1b-rp@test.local', p_parent_uid => null, p_parent_email => null)$f$,
                       :'rp', :'k_rp'),
                '2 regulär Papier: Abschluss ohne Elternkonto');
select is((select role from profiles where id = :'k_rp'), 'student', '2 regulär Papier: Schülerkonto angelegt');
select * from pg_temp.ohne_eltern(:'rp', '2 regulär Papier');

-- ── 3) Pilot vor Ort ───────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Paul Vorort'), 'pilot') as pv \gset
update vertraege set vertragsbeginn = '2027-11-01', vertrag_ende = '2028-07-07', einheiten = 30,
                     kind_vorname = 'Paul', kind_nachname = 'Vorort', klasse = 8, eltern_email = 'k1b-eltern@test.local'
 where id = :'pv';
select lives_ok(format($f$select vertrag_abschliessen(%L, 'vor_ort', %L, 'sig-vertrag', p_student_uid => %L,
                         p_student_email => 'k1b-pv@test.local', p_parent_uid => null, p_parent_email => null)$f$,
                       :'pv', pg_temp.zust('pilotvereinbarung', 'datenschutz_vertrag'), :'k_pv'),
                '3 Pilot vor Ort: Abschluss ohne Elternkonto');
select is((select role from profiles where id = :'k_pv'), 'student', '3 Pilot vor Ort: Schülerkonto angelegt');
select * from pg_temp.ohne_eltern(:'pv', '3 Pilot vor Ort');

-- ── 4) Pilot Papier ────────────────────────────────────────────────────────────────────────────
select vertrag_starten(pg_temp.lead('Pia Papier'), 'pilot') as pp \gset
update vertraege set vertragsbeginn = '2027-11-01', vertrag_ende = '2028-03-17', einheiten = 16,
                     kind_vorname = 'Pia', kind_nachname = 'Papier', klasse = 8, eltern_email = 'k1b-eltern@test.local'
 where id = :'pp';
select lives_ok(format($f$select vertrag_versenden(%L, 'druck')$f$, :'pp'), '4 Pilot Papier: Versand');
select lives_ok(format($f$select vertrag_abschliessen(%L, 'papier', p_unterschrieben_am => '2027-10-20',
                         p_eingang_datum => '2027-10-22', p_scan_pfad => 'k1b/scan-pp.pdf', p_student_uid => %L,
                         p_student_email => 'k1b-pp@test.local', p_parent_uid => null, p_parent_email => null)$f$,
                       :'pp', :'k_pp'),
                '4 Pilot Papier: Abschluss ohne Elternkonto');
select is((select role from profiles where id = :'k_pp'), 'student', '4 Pilot Papier: Schülerkonto angelegt');
select * from pg_temp.ohne_eltern(:'pp', '4 Pilot Papier');

-- ── Gesamt ─────────────────────────────────────────────────────────────────────────────────────
select is((select count(*)::int from profiles where role = 'parent'), :eltern_vorher,
          'Gesamt: kein neues Eltern-Profil durch die vier Abschlüsse');

select * from finish();
rollback;
