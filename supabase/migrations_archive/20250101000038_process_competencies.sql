-- ============================================================================
-- Migration 038 – process_competencies (Achse B: Prozesskompetenzen)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Fuehrt die Zwei-Achsen-Kompetenz-Matrix ein. Achse A (Inhaltsfeld) ist
-- bereits als skill_clusters modelliert. Achse B (Prozesskompetenz) fehlte als
-- eigene Achse – die 6 KMK-Prozesskompetenzen lebten bislang nirgends
-- strukturiert (und "Modellieren" war faelschlich als Inhalts-Cluster
-- "Sachrechnen & Modellieren" vermischt; aufgeloest in Migration 041).
--
-- Referenzdaten: lesbar fuer alle authentifizierten Rollen, schreibbar nur
-- fuer admin (Schema-Konvention wie subjects/skill_clusters + xp_rules).
-- ============================================================================

create table public.process_competencies (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,        -- Ope|Mod|Pro|Arg|Kom|Wkz
  name        text not null,               -- interner Klartext
  sort_order  integer not null
);

-- Seed: die 6 Prozesskompetenzen (idempotent ueber code).
insert into public.process_competencies (code, name, sort_order)
values
  ('Ope', 'Operieren',        1),
  ('Mod', 'Modellieren',      2),
  ('Pro', 'Problemlösen',     3),
  ('Arg', 'Argumentieren',    4),
  ('Kom', 'Kommunizieren',    5),
  ('Wkz', 'Werkzeuge nutzen', 6)
on conflict (code) do nothing;

alter table public.process_competencies enable row level security;

create policy "authenticated_read_process_competencies"
  on public.process_competencies for select
  using (auth.role() = 'authenticated');

create policy "process_competencies_admin_write"
  on public.process_competencies for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
