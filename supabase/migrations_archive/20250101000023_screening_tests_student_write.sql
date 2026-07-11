-- ============================================================================
-- Migration 023 – screening_tests: Schüler-Self-Service-Write (RLS)
--
-- ⚠️  Auth/RLS-ÄNDERUNG – per CLAUDE.md mit Rasit explizit abgestimmt
-- vor Ausführung im Supabase SQL Editor.
--
-- Grund: Der neue stille, adaptive /screening-Lauf läuft ALS Schüler:in
-- (kein Coach mehr im Loop). Migration 014 erlaubt Schüler:innen nur
-- SELECT auf eigene screening_tests; es fehlen INSERT/UPDATE. Dadurch
-- scheitern createScreeningTest/completeScreeningTest an RLS, die
-- Persistenz wird (best effort) still übersprungen → der Coach sieht
-- kein Ergebnis. screening_item_results erlaubt dem Schüler bereits
-- insert/select über die eigene screening_tests-Zeile (Migration 022) —
-- es fehlt nur das Schreibrecht auf screening_tests selbst.
--
-- Additive Policies (Postgres OR-verknüpft permissive Policies):
-- Coach/Admin-Policy aus 014 bleibt unverändert. Kein DELETE für
-- Schüler:innen (Lauf bleibt append/abschließbar, nicht löschbar).
-- ============================================================================

create policy "screening_tests_student_insert" on screening_tests
  for insert
  with check (student_id = public.get_my_student_id());

create policy "screening_tests_student_update" on screening_tests
  for update
  using (student_id = public.get_my_student_id())
  with check (student_id = public.get_my_student_id());
