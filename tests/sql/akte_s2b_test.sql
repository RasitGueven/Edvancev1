-- Abnahme Schuelerakte S2b: akte_stammdaten_aendern und akte_sessions
-- (Migration 20260930120000_akte_stammdaten_sessions.sql).
--
-- Ausfuehren:  psql "$DATABASE_URL" -f tests/sql/akte_s2b_test.sql
--
-- Eine Transaktion, ROLLBACK am Ende — gegen Prod ohne bleibende Aenderung.
-- Legt eigene Testfaelle an (Praefix ZZ_T2B), prueft mit Claims als Admin und
-- als Coach (Rolle authenticated). Abnahme: Spalte `ergebnis` nur OK.

begin;

create temp table ergebnis (nr integer, pruefung text, ist text, soll text) on commit drop;
grant all on ergebnis to authenticated;

do $$
declare
  v_admin uuid := gen_random_uuid();
  v_coach uuid := gen_random_uuid();
  v_fremd uuid := gen_random_uuid();
  v_kindprofil uuid := gen_random_uuid();
  k_aktiv uuid := gen_random_uuid();
  k_ruhend uuid := gen_random_uuid();
  l1 uuid := gen_random_uuid(); l2 uuid := gen_random_uuid();
  s_eigen uuid := gen_random_uuid(); s_fremd uuid := gen_random_uuid(); s_ruhend uuid := gen_random_uuid();
  v_beginn date := (date_trunc('month', current_date) - interval '2 months')::date;
  v_n integer;
  v_t text;
begin
  insert into auth.users (id, email, instance_id, aud, role) values
    (v_admin, 'zz_t2b_admin@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_coach, 'zz_t2b_coach@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_fremd, 'zz_t2b_fremd@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_kindprofil, 'zz_t2b_kind@edvance.invalid', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
  insert into public.profiles (id, email, role, full_name) values
    (v_admin, 'zz_t2b_admin@edvance.invalid', 'admin', 'ZZ_T2B Admin'),
    (v_coach, 'zz_t2b_coach@edvance.invalid', 'coach', 'ZZ_T2B Coach'),
    (v_fremd, 'zz_t2b_fremd@edvance.invalid', 'coach', 'ZZ_T2B Fremdcoach'),
    (v_kindprofil, 'zz_t2b_kind@edvance.invalid', 'student', 'ZZ_T2B Kind Alt')
  on conflict (id) do update set role = excluded.role, full_name = excluded.full_name;

  insert into public.leads (id, full_name, status) values (l1, 'ZZ_T2B Aktiv', 'converted'), (l2, 'ZZ_T2B Ruhend', 'converted');
  insert into public.students (id, profile_id, class_level) values (k_aktiv, v_kindprofil, 9), (k_ruhend, null, 9);
  insert into public.vertraege (lead_id, status, vertrag_status, student_id, einheiten, laufzeit_monate,
                                vertragsbeginn, vertrag_ende, abgeschlossen_am) values
    (l1, 'abgeschlossen', 'aktiv', k_aktiv, 57, 12, v_beginn, current_date + 200, v_beginn - 10),
    (l2, 'abgeschlossen', 'aktiv', k_ruhend, 57, 12, date_trunc('month', current_date - 400)::date,
     current_date - 10, date_trunc('month', current_date - 400)::date - 10);

  -- Sessions innerhalb der Vertraege (P5b-Trigger): eine vom Coach, eine von einem anderen Coach
  insert into public.coaching_sessions (id, coach_id, scheduled_at, status) values
    (s_eigen, v_coach, (v_beginn + 7 + time '16:00') at time zone 'Europe/Berlin', 'done'),
    (s_fremd, v_fremd, (v_beginn + 14 + time '16:00') at time zone 'Europe/Berlin', 'done'),
    (s_ruhend, v_fremd, (current_date - 40 + time '16:00') at time zone 'Europe/Berlin', 'done');
  insert into public.session_students (session_id, student_id, attendance) values
    (s_eigen, k_aktiv, 'present'), (s_fremd, k_aktiv, 'unexcused'), (s_ruhend, k_ruhend, 'present');

  -- ---------------------------------------------------------------- als Admin
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  begin
    perform public.akte_stammdaten_aendern(k_aktiv, '  ZZ_T2B Kind Neu ', 10, null);
    insert into ergebnis values (1, 'Admin: Stammdaten aendern', 'klappt', 'klappt');
  exception when others then
    insert into ergebnis values (1, 'Admin: Stammdaten aendern', 'Fehler ' || sqlstate || ' ' || sqlerrm, 'klappt');
  end;
  begin
    perform public.akte_stammdaten_aendern(k_aktiv, '   ', 10, null);
    insert into ergebnis values (2, 'Admin: leerer Name', 'klappt', 'Fehler 22023');
  exception when others then
    insert into ergebnis values (2, 'Admin: leerer Name', 'Fehler ' || sqlstate, 'Fehler 22023');
  end;
  begin
    perform public.akte_stammdaten_aendern(k_ruhend, 'ZZ_T2B Anderer Name', 8, null);
    insert into ergebnis values (3, 'Admin: Name aendern bei Kind ohne Profil', 'klappt', 'Fehler P0001');
  exception when others then
    insert into ergebnis values (3, 'Admin: Name aendern bei Kind ohne Profil', 'Fehler ' || sqlstate, 'Fehler P0001');
  end;

  select count(*) into v_n from public.akte_sessions(k_ruhend);
  insert into ergebnis values (4, 'Admin: akte_sessions ruhende Akte', v_n::text, '1');
  select string_agg(attendance || '/' || coalesce(coach_name, '-'), ',' order by scheduled_at) into v_t
    from public.akte_sessions(k_aktiv);
  insert into ergebnis values (5, 'Admin: akte_sessions aktive Akte (aelteste zuerst gelesen)', v_t,
    'present/ZZ_T2B Coach,unexcused/ZZ_T2B Fremdcoach');

  -- ---------------------------------------------------------------- als Coach
  execute 'reset role';
  perform set_config('request.jwt.claims', json_build_object('sub', v_coach, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';

  begin
    perform public.akte_stammdaten_aendern(k_aktiv, 'ZZ_T2B Coach-Name', 9, null);
    insert into ergebnis values (10, 'Coach: Stammdaten aendern', 'klappt', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (10, 'Coach: Stammdaten aendern', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  begin
    perform * from public.akte_sessions(k_ruhend);
    insert into ergebnis values (11, 'Coach: akte_sessions ruhende Akte', 'geliefert', 'Fehler 42501');
  exception when others then
    insert into ergebnis values (11, 'Coach: akte_sessions ruhende Akte', 'Fehler ' || sqlstate, 'Fehler 42501');
  end;
  select count(*) into v_n from public.akte_sessions(k_aktiv);
  insert into ergebnis values (12, 'Coach: akte_sessions aktive Akte, auch Sessions anderer Coaches', v_n::text, '2');
  select count(*) into v_n from public.session_students where student_id = k_aktiv;
  insert into ergebnis values (13, 'Coach: direkt ueber RLS nur eigene Sessions (unveraendert)', v_n::text, '1');

  -- ---------------------------------------------------------------- Nachweise als Eigentuemer
  execute 'reset role';
  select p.full_name || ' / ' || s.class_level into v_t
    from public.students s join public.profiles p on p.id = s.profile_id where s.id = k_aktiv;
  insert into ergebnis values (20, 'Name (getrimmt) und Klasse gespeichert', v_t, 'ZZ_T2B Kind Neu / 10');
  select count(*) into v_n from public.audit_log
   where aktion = 'akte_stammdaten_aendern' and objekt_id = k_aktiv and actor = v_admin;
  insert into ergebnis values (21, 'audit_log-Eintrag', v_n::text, '1');
end;
$$;

insert into ergebnis
select 30 + row_number() over (), 'anon darf ' || f || ' nicht ausfuehren', has_function_privilege('anon', f, 'execute')::text, 'false'
  from unnest(array['public.akte_stammdaten_aendern(uuid,text,integer,uuid)', 'public.akte_sessions(uuid)']) f;

select nr, pruefung, ist, soll,
       case when ist is not distinct from soll then 'OK' else 'FEHLER' end as ergebnis
  from ergebnis order by nr;

rollback;
