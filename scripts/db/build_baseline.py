#!/usr/bin/env python3
"""Erzeugt die konsolidierte Baseline aus schema.sql.

WARUM eine Baseline und kein Replay der 43 Migrationen:
  Die Dateien migrations/001..043 sind INKREMENTE auf ein Basis-Schema, das nie
  als Migration existierte (es wurde per Hand aus schema.sql / schema_content.sql
  im Supabase-SQL-Editor angelegt). Migration 001 macht direkt
  `delete from skill_clusters` — eine Tabelle, die keine Migration je anlegt.
  Ein Replay von 001 an bricht darum sofort ab (bewiesen: `supabase start`
  -> ERROR: relation "skill_clusters" does not exist).
  => Der einzige vollstaendige Struktur-Stand ist schema.sql. Der wird hier zur
     Baseline-Migration; die 43 Altdateien wandern ins Archiv (Provenienz).

Aufteilung nach Supabase-Konvention:
  - Struktur (Enums/Funktionen/Tabellen/RLS/Trigger/Storage-RLS) -> Baseline-Migration
  - Abschnitt 14 (Seed-/Katalogdaten, idempotent)                -> supabase/seed.sql

Usage: python3 scripts/db/build_baseline.py
"""
from __future__ import annotations

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCHEMA = ROOT / "schema.sql"
BASELINE = ROOT / "supabase" / "migrations" / "20250101000000_baseline.sql"
SEED = ROOT / "supabase" / "seed.sql"

SEED_MARKER = "-- 14. SEED- / KATALOGDATEN"

BASELINE_HEADER = """\
-- ============================================================================
-- Edvance – KONSOLIDIERTE BASELINE (Struktur)
--
-- Generiert von scripts/db/build_baseline.py aus schema.sql — NICHT von Hand
-- editieren. Aenderungen am Schema laufen ab jetzt als NEUE Migration daneben
-- (siehe docs/runbooks/DB-MIGRATIONEN.md).
--
-- Diese Datei bildet den Struktur-Endstand ab, den frueher die haendisch
-- angewendete schema.sql + migrations/001..043 zusammen ergaben. Die 43
-- historischen Inkremente liegen unter supabase/migrations_archive/ und werden
-- BEWUSST NICHT MEHR AUSGEFUEHRT: sie setzen ein Basis-Schema voraus, das nie
-- als Migration existierte (Migration 001 loescht aus skill_clusters, das keine
-- Migration anlegt) — ein Replay bricht sofort ab.
--
-- Seed-/Katalogdaten stehen in supabase/seed.sql.
-- ============================================================================

"""

SEED_HEADER = """\
-- ============================================================================
-- Edvance – Seed-/Katalogdaten
--
-- Generiert von scripts/db/build_baseline.py aus schema.sql (Abschnitt 14).
-- Laeuft automatisch bei `supabase db reset` / `supabase start`.
-- Alle Inserts sind idempotent (where not exists / on conflict do nothing).
-- ============================================================================

"""


def main() -> int:
    if not SCHEMA.is_file():
        print("build_baseline: schema.sql fehlt", file=sys.stderr)
        return 1

    lines = SCHEMA.read_text(encoding="utf-8").splitlines(keepends=True)
    idx = next((i for i, l in enumerate(lines) if l.startswith(SEED_MARKER)), None)
    if idx is None:
        print(f"build_baseline: Marker {SEED_MARKER!r} nicht in schema.sql gefunden", file=sys.stderr)
        return 1

    # Der '-- ====' Rahmen direkt ueber dem Marker gehoert schon zum Seed-Block.
    cut = idx - 1 if idx > 0 and lines[idx - 1].startswith("-- ===") else idx

    structure = "".join(lines[:cut]).rstrip() + "\n"
    seed = "".join(lines[cut:]).rstrip() + "\n"

    BASELINE.parent.mkdir(parents=True, exist_ok=True)
    BASELINE.write_text(BASELINE_HEADER + structure, encoding="utf-8")
    SEED.write_text(SEED_HEADER + seed, encoding="utf-8")

    print(f"baseline -> {BASELINE.relative_to(ROOT)}  ({structure.count(chr(10))} Zeilen Struktur)")
    print(f"seed     -> {SEED.relative_to(ROOT)}  ({seed.count(chr(10))} Zeilen Seed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
