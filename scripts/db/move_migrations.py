#!/usr/bin/env python3
"""Einmal-Umzug: migrations/NNN_name.sql -> supabase/migrations/<ts>_name.sql.

Die Supabase-Konvention verlangt einen 14-stelligen Timestamp-Prefix
(YYYYMMDDHHMMSS). Die alten Dateien tragen eine numerische Ordnung (001..043);
genau diese Ordnung muss erhalten bleiben, weil spaetere Migrationen frueheres
Schema veraendern (z.B. 036 dropt streak_days, 037 repariert apply_xp_event).

Abbildung: laufende Nummer N -> 2025-01-01 00:00:<N> (sekundengenau, monoton).
Die Timestamps sind reine Ordnungs-Schluessel, kein echtes Datum — die echte
Historie steht im git-Log (der Umzug laeuft ueber `git mv`).

Usage: python3 scripts/db/move_migrations.py [--apply]
"""
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "migrations"
DST = ROOT / "supabase" / "migrations"
BASE = dt.datetime(2025, 1, 1, 0, 0, 0)
PAT = re.compile(r"^(\d{3})_(.+)\.sql$")


def plan() -> list[tuple[pathlib.Path, pathlib.Path, int, str]]:
    rows = []
    for f in sorted(SRC.glob("*.sql")):
        m = PAT.match(f.name)
        if not m:
            sys.exit(f"move_migrations: unerwarteter Dateiname: {f.name}")
        num, name = int(m.group(1)), m.group(2)
        ts = (BASE + dt.timedelta(seconds=num)).strftime("%Y%m%d%H%M%S")
        rows.append((f, DST / f"{ts}_{name}.sql", num, ts))
    return rows


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="git mv wirklich ausfuehren")
    args = ap.parse_args()

    rows = plan()
    if not rows:
        print("move_migrations: nichts zu tun (migrations/ leer oder weg).")
        return 0

    # Monotonie ist die einzige Eigenschaft, auf die es ankommt.
    tss = [ts for *_, ts in rows]
    assert tss == sorted(tss), "Timestamps nicht monoton — Reihenfolge waere kaputt"
    assert len(set(tss)) == len(tss), "Timestamp-Kollision"

    DST.mkdir(parents=True, exist_ok=True)
    print(f"{len(rows)} Migrationen: migrations/ -> supabase/migrations/\n")
    print("| # | alt | neu |")
    print("|---|-----|-----|")
    for src, dst, num, _ in rows:
        print(f"| {num:03d} | `{src.name}` | `{dst.name}` |")

    if not args.apply:
        print("\n(dry-run — mit --apply ausfuehren)")
        return 0

    for src, dst, *_ in rows:
        subprocess.run(["git", "mv", str(src.relative_to(ROOT)), str(dst.relative_to(ROOT))],
                       cwd=ROOT, check=True)
    print(f"\nverschoben: {len(rows)} Dateien (git mv — Historie bleibt erhalten)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
