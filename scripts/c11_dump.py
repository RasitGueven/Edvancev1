#!/usr/bin/env python3
"""C11 Schritt 3a: tasks read-only dumpen (title, question, needs_image).

NUR SELECT. Schreibt data/c11_tasks.json.
"""
from __future__ import annotations

import json
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def db_url() -> str:
    for line in open(os.path.join(ROOT, ".env"), encoding="utf-8"):
        line = line.strip()
        if line.startswith("DATABASE_URL="):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise SystemExit("DATABASE_URL fehlt in .env")


SQL = """
select coalesce(json_agg(row_to_json(t)), '[]'::json) from (
  select id, title, question, needs_image, source
  from tasks
  where source = 'VERA8_IQB'
  order by title
) t;
"""

out = subprocess.run(
    ["psql", db_url(), "-tAc", SQL],
    capture_output=True, text=True, check=True,
).stdout

rows = json.loads(out)
dest = os.path.join(ROOT, "data", "c11_tasks.json")
json.dump(rows, open(dest, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(f"{len(rows)} tasks -> {dest}")
