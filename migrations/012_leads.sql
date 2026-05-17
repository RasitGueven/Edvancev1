-- ============================================================================
-- Migration 012 – leads (Erstgespraech Stufe A: Lead/Erstkontakt vor Account)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- leads ist mutabel und rein intern: nur Coach/Admin. Enthaelt PII von
-- Nicht-Usern (contact_email/phone) -> bewusst KEIN Public-/anon-Zugriff.
-- 'rejected'-/Retention-Handling siehe docs/SCHEMA.md.
-- ============================================================================

create table leads (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  full_name text not null,
  contact_email text,
  contact_phone text,
  class_level integer check (class_level between 5 and 13),
  school_type text check (
    school_type in ('Gymnasium','Gesamtschule','Realschule','Hauptschule')
  ),
  school_name text,
  subjects text[] default '{}',
  goal text check (goal in ('IMPROVE_GRADES','CLOSE_GAPS','EXAM_PREP','GENERAL')),
  known_weak_topics text[] default '{}',
  source text,
  status text not null default 'new' check (
    status in ('new','contacted','onboarding_scheduled','converted','rejected')
  ),
  owner_id uuid references profiles (id) on delete set null,
  notes text,
  converted_student_id uuid references students (id) on delete set null,
  contacted_at timestamptz,
  onboarding_scheduled_at timestamptz
);

create index leads_status_idx on leads (status);
create index leads_owner_idx on leads (owner_id);

alter table leads enable row level security;

create policy "leads_coach_admin_all" on leads
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));
