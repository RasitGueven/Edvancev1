#!/usr/bin/env python3
"""Verschiebt die 43 historischen Inkremente aus supabase/migrations/ ins Archiv.

Sie bleiben im Repo (Provenienz, git-Historie), werden aber von der Supabase-CLI
nicht mehr ausgefuehrt — sie sind nicht replay-faehig (siehe build_baseline.py).

Usage: python3 scripts/db/archive_migrations.py
"""
from __future__ import annotations

import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "supabase" / "migrations"
DST = ROOT / "supabase" / "migrations_archive"

# Nur die umgezogenen Altdateien (2025-01-01 00:00:01..43) — die Baseline
# (…000000_baseline.sql) bleibt bewusst stehen.
OLD = re.compile(r"^202501010000(0[1-9]|[1-4][0-9])_.+\.sql$")


def main() -> int:
    DST.mkdir(parents=True, exist_ok=True)
    moved = 0
    for f in sorted(SRC.glob("*.sql")):
        if not OLD.match(f.name):
            continue
        subprocess.run(
            ["git", "mv", str(f.relative_to(ROOT)), str((DST / f.name).relative_to(ROOT))],
            cwd=ROOT, check=True,
        )
        moved += 1
    print(f"archiviert: {moved} historische Migrationen -> supabase/migrations_archive/")
    rest = sorted(p.name for p in SRC.glob("*.sql"))
    print(f"aktiv in supabase/migrations/: {rest or '(leer)'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
