-- ============================================================================
-- Migration 043 – screening_items.microskill_id (Microskill-Lokalisierung)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Haengt das Microskill (feinste Inhalts-Granularitaet, unterhalb
-- skill_clusters) an Screening-Items. Bisher mappen Items nur auf cluster_id
-- (Achse A) und competency_id (Achse B) — damit endet die Screening-Auswertung
-- auf Cluster-Ebene. Mit microskill_id laesst sich ein Item-Ergebnis auf einen
-- Microskill-Knoten abbilden und ueber microskills.prerequisite_ids die
-- Voraussetzungskette rueckwaerts laufen (Root-Gap / Lernpfad-Vorschlag).
--
-- Nullable, weil das inhaltliche Tagging Content-Arbeit ist (Lena) und nicht
-- geraten wird — exakt wie competency_id in Migration 039.
--
-- KEINE RLS-Aenderung: bestehende screening_items-Policies (read active /
-- admin all / coach read) gelten unveraendert fuer die neue Spalte.
-- ============================================================================

alter table public.screening_items
  add column if not exists microskill_id uuid
  references public.microskills(id) on delete set null;

create index if not exists screening_items_microskill_idx
  on public.screening_items (microskill_id);

comment on column public.screening_items.microskill_id is
  'Feinste Inhalts-Granularitaet (Microskill-Knoten, unterhalb cluster_id). '
  'Basis fuer Root-Gap-Walk ueber microskills.prerequisite_ids. '
  'Nullable; Backfill = Content (Lena).';
