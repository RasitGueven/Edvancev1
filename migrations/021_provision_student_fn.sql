-- ============================================================================
-- Migration 021 – app_provision_student (atomare Lead->Student-Conversion)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Wird AUSSCHLIESSLICH von der Edge Function provision_student (service-role)
-- aufgerufen, nachdem die auth-User (Schueler + optional Elternteil) via
-- Auth-Admin-API angelegt wurden. Die Funktion erledigt den kompletten
-- DB-Teil in EINER Transaktion (plpgsql-Funktion = implizite Transaktion):
-- profiles -> students -> parent_student -> student_subjects -> student_coach
-- -> student_subscriptions -> leads. Unbekanntes Fach => raise => Rollback.
-- EXECUTE nur fuer service_role.
-- ============================================================================

create or replace function public.app_provision_student(
  p_student_uid uuid,
  p_student_email text,
  p_parent_uid uuid,
  p_parent_email text,
  p_full_name text,
  p_class_level integer,
  p_school_type text,
  p_school_name text,
  p_subjects text[],
  p_coach_id uuid,
  p_tier_id uuid,
  p_lead_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_subj text;
  v_subject_id uuid;
begin
  insert into profiles (id, email, role, full_name)
  values (p_student_uid, p_student_email, 'student', p_full_name);

  if p_parent_uid is not null then
    insert into profiles (id, email, role, full_name)
    values (p_parent_uid, p_parent_email, 'parent', null);
  end if;

  insert into students (profile_id, class_level, school_name, school_type)
  values (p_student_uid, p_class_level, p_school_name, p_school_type)
  returning id into v_student_id;

  if p_parent_uid is not null then
    insert into parent_student (parent_id, student_id)
    values (p_parent_uid, p_student_uid);
  end if;

  if p_subjects is not null then
    foreach v_subj in array p_subjects loop
      select id into v_subject_id from subjects where name = v_subj;
      if v_subject_id is null then
        raise exception 'Fach unbekannt: %', v_subj;
      end if;
      insert into student_subjects (student_id, subject_id)
      values (v_student_id, v_subject_id);
    end loop;
  end if;

  if p_coach_id is not null then
    insert into student_coach (student_id, coach_id)
    values (v_student_id, p_coach_id);
  end if;

  if p_tier_id is not null then
    insert into student_subscriptions (student_id, tier_id)
    values (v_student_id, p_tier_id);
  end if;

  if p_lead_id is not null then
    update leads
       set status = 'converted',
           converted_student_id = v_student_id
     where id = p_lead_id;
  end if;

  return v_student_id;
end;
$$;

revoke all on function public.app_provision_student(
  uuid,text,uuid,text,text,integer,text,text,text[],uuid,uuid,uuid
) from public, anon, authenticated;

grant execute on function public.app_provision_student(
  uuid,text,uuid,text,text,integer,text,text,text[],uuid,uuid,uuid
) to service_role;
