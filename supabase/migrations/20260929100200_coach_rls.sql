-- Schuelerakte S1, Teil 3 von 3: Coach-Rechte (RLS).
--
-- Bauauftrag Schuelerakte (Fassung 2), Paket S1, Entscheidung 12. Setzt
-- 20260929100100_schuelerakte_akte.sql voraus (akte_aktiv, lsa_lead_kontext).
-- Rollback: docs/schuelerakte/rollback_coach_rls.sql.
--
-- S0 (Abschnitt 6) hat gezeigt: Coaches lesen heute alle students, alle leads
-- samt Elternkontakt und parent_student — ueber *_coach_admin_all-Policies.
-- Danach gilt:
--   leads           Coach: kein direkter Zugriff mehr. Der LSA-Report liest ueber
--                   lsa_lead_kontext (ohne Kontaktdaten); Kiosk-, Slot- und
--                   Assessment-RPCs sind SECURITY DEFINER und lesen weiter.
--   parent_student  Coach: kein Zugriff (kein Aufrufer in src/).
--   students        Coach: nur SELECT, nur Kinder mit aktiver Akte. Der LSA-Kiosk
--                   braucht nichts: platz_* sind SECURITY DEFINER.
--   profiles        Coach: eigenes Profil, Admins und Coaches (Namen in Authoring,
--                   Report-Ansprechpartner), Kinder mit aktiver Akte. Keine
--                   Eltern-Profile mehr (E-Mail = Elternkontakt).
--   vertraege, vertrag_*  schon heute nur Admin (20260922120000). Hier nur
--                   geprueft: weicht Prod davon ab, bricht die Migration ab.
--   Admin           unveraendert.
--
-- Einheiten und Stichtag erreichen Coaches nur ueber einheiten_stand /
-- board_schueler (SECURITY DEFINER), nie ueber SELECT auf vertraege.

begin;

-- ============================================================================
-- 0. Vorbedingung: vertraege und vertrag_* sind nur fuer Admins lesbar
-- ============================================================================
--
-- Die erwartete Liste ist der Stand der Migrationen (schema-erwartet.sql).
-- Jede weitere Policy auf diesen Tabellen koennte Coaches Zugriff geben und
-- wird hier nicht still hingenommen.

do $$
declare
  v_fremd text;
begin
  select string_agg(p.tablename || '.' || p.policyname, ', ' order by p.tablename, p.policyname)
    into v_fremd
    from pg_policies p
   where p.schemaname = 'public'
     and (p.tablename = 'vertraege' or p.tablename like 'vertrag\_%')
     and (p.tablename, p.policyname) not in (
       ('vertraege',              'vertraege_admin_select'),
       ('vertraege',              'vertraege_admin_update_vorbereitung'),
       ('vertrag_bankdaten',      'vertrag_bankdaten_admin_select'),
       ('vertrag_bankdaten',      'vertrag_bankdaten_admin_update'),
       ('vertrag_bankdaten',      'vertrag_bankdaten_admin_write'),
       ('vertrag_dateien',        'vertrag_dateien_admin_select'),
       ('vertrag_dokumente',      'vertrag_dokumente_admin_select'),
       ('vertrag_einstellungen',  'vertrag_einstellungen_admin_select'),
       ('vertrag_einstellungen',  'vertrag_einstellungen_admin_update'),
       ('vertrag_unterschriften', 'vertrag_unterschriften_admin_select'),
       ('vertrag_versand',        'vertrag_versand_admin_select'),
       ('vertrag_zustimmungen',   'vertrag_zustimmungen_admin_select')
     );
  if v_fremd is not null then
    raise exception 'coach_rls: unerwartete Policies auf Vertragstabellen: %', v_fremd;
  end if;
end;
$$;

-- ============================================================================
-- 1. leads — Coach raus
-- ============================================================================

drop policy leads_coach_admin_all on public.leads;

create policy leads_admin_all on public.leads
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 2. parent_student — Coach raus
-- ============================================================================

drop policy parent_student_coach_admin_all on public.parent_student;

create policy parent_student_admin_all on public.parent_student
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- ============================================================================
-- 3. students — Coach nur lesend, nur aktive Akten
-- ============================================================================

drop policy students_coach_admin_all on public.students;

create policy students_admin_all on public.students
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

create policy students_coach_select on public.students
  for select
  using (public.get_my_role() = 'coach' and public.akte_aktiv(id));

-- ============================================================================
-- 4. profiles — Coach ohne Eltern und ohne Kinder ohne aktive Akte
-- ============================================================================
--
-- SECURITY DEFINER, damit die Policy nicht ueber die students-RLS laeuft
-- (keine Kette profiles -> students -> ...).

create or replace function public.profil_fuer_coach_sichtbar(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles p
     where p.id = p_profile_id
       and (p.id = auth.uid()
            or p.role in ('admin', 'coach')
            or (p.role = 'student'
                and exists (select 1 from public.students s
                             where s.profile_id = p.id and public.akte_aktiv(s.id))))
  );
$$;

comment on function public.profil_fuer_coach_sichtbar(uuid) is
  'Coach-Sicht auf profiles: eigenes Profil, Admins, Coaches und Kinder mit aktiver Akte. Keine Eltern.';

revoke all on function public.profil_fuer_coach_sichtbar(uuid) from public, anon, authenticated;
grant execute on function public.profil_fuer_coach_sichtbar(uuid) to authenticated;

drop policy coaches_admins_see_all_profiles on public.profiles;

create policy profiles_admin_select on public.profiles
  for select
  using (public.get_my_role() = 'admin');

create policy profiles_coach_select on public.profiles
  for select
  using (public.get_my_role() = 'coach' and public.profil_fuer_coach_sichtbar(id));

commit;
