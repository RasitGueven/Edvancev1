-- ============================================================================
-- Migration 028 – Screening v2: AFB + Phasen + manuelle Coach-Bewertung
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abgestimmt
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Additiver Brownfield-Schnitt:
--   - screening_items: optionale Spalten afb + phase (nullable);
--     bestehende Items bleiben im Legacy-Pfad nutzbar.
--   - input_type/check_type erweitert um 'OPEN'/'manual' fuer offene Items.
--   - screening_item_results.correct -> nullable (offene Items haben zur
--     Insert-Zeit kein Auto-Grade).
--   - Neue Tabelle screening_item_ratings: append-only manuelle Coach-
--     Bewertung pro offener Antwort. Schueler/Eltern lesen NICHT direkt.
-- ============================================================================

-- 1. screening_items: neue optionale Spalten ────────────────────────────────
alter table screening_items
  add column afb text check (afb in ('I','II','III')),
  add column phase text check (phase in ('sprint','tiefe'));

-- 2. CHECK-Constraints lockern (OPEN + manual) ──────────────────────────────
alter table screening_items
  drop constraint screening_items_input_type_check,
  add constraint screening_items_input_type_check
    check (input_type in ('MC','NUMERIC','MATCHING','STEPS_FINAL','OPEN'));

alter table screening_items
  drop constraint screening_items_check_type_check,
  add constraint screening_items_check_type_check
    check (check_type in ('mc_index','numeric','matching_set','normalized','manual'));

-- 3. Cross-Constraint: OPEN <=> manual ──────────────────────────────────────
alter table screening_items
  add constraint screening_items_open_iff_manual
    check ((input_type = 'OPEN') = (check_type = 'manual'));

-- 4. screening_item_results.correct nullable ────────────────────────────────
alter table screening_item_results
  alter column correct drop not null;

-- 5. v2-Pool-Index ──────────────────────────────────────────────────────────
create index screening_items_v2_pool_idx
  on screening_items (cluster_id, phase, afb)
  where active = true and afb is not null and phase is not null;

-- 6. screening_item_ratings (append-only, manuelle Coach-Bewertung) ─────────
create table screening_item_ratings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  screening_item_result_id uuid not null
    references screening_item_results (id) on delete cascade,
  coach_id uuid references profiles (id) on delete set null,
  reached_afb text check (reached_afb in ('I','II','III')),
  note text
);

create index screening_item_ratings_result_idx
  on screening_item_ratings (screening_item_result_id);
create index screening_item_ratings_coach_idx
  on screening_item_ratings (coach_id);

alter table screening_item_ratings enable row level security;

-- Coach + Admin schreiben/lesen. Schueler/Eltern lesen NICHT direkt
-- (CLAUDE §6 – Kind sieht nie richtig/falsch im Screening; Eltern via
-- Coach-kuratierten Report).
create policy "screening_item_ratings_coach_insert" on screening_item_ratings
  for insert with check (public.get_my_role() in ('coach','admin'));

create policy "screening_item_ratings_coach_read" on screening_item_ratings
  for select using (public.get_my_role() in ('coach','admin'));

-- bewusst: KEIN update-/delete-Policy -> append-only,
-- Korrektur einer Bewertung = neuer Eintrag, "letzte gilt" (created_at DESC).
