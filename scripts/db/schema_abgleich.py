#!/usr/bin/env python3
"""Schema-Abgleich: DB (lokale Baseline) x schema.sql x migrations_archive x Code.

Erzeugt docs/audits/SCHEMA-ABGLEICH.md.

Quellen:
  1. DB   — Introspektion der lokal aus der Baseline gebauten DB
            (docs/audits/_db_local_baseline.json, via db_introspect.py).
            Die PROD-DB ist von hier aus nicht erreichbar (siehe Doc).
  2. schema.sql — statisch geparst (create table / alter table add column).
  3. supabase/migrations_archive/*.sql — die 43 historischen Inkremente.
  4. Code — der Contract aus src/lib/supabase/**, src/types/**, supabase/functions/**.

Usage: python3 scripts/db/schema_abgleich.py
"""
from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
DB_JSON = ROOT / "docs" / "audits" / "_db_local_baseline.json"
SCHEMA = ROOT / "schema.sql"
ARCHIVE = ROOT / "supabase" / "migrations_archive"
OUT = ROOT / "docs" / "audits" / "SCHEMA-ABGLEICH.md"

# --- Code-Contract: was der Code tatsaechlich von der DB verlangt --------------
# Erhoben aus src/lib/supabase/**, src/types/**, supabase/functions/**.
CODE_TABLES = [
    "profiles", "students", "subjects", "student_subjects", "skill_clusters",
    "process_competencies", "microskills", "tasks", "behavior_snapshots", "leads",
    "intake_sessions", "screening_tests", "screening_ratings", "screening_items",
    "screening_item_results", "screening_item_ratings", "tiers",
    "student_subscriptions", "student_coach", "student_focus_areas",
    "coaching_sessions", "session_students", "interventions",
    "student_task_progress", "student_progress", "xp_events", "xp_rules",
    "badge_catalog", "student_badges", "streak_repair_inventory", "parent_reports",
    "parent_report_generations", "student_competency_mastery",
    # Von supabase/functions/generate_parent_report/index.ts:327 abgefragt:
    "clusters",
]
CODE_RPCS = ["complete_task", "app_provision_student", "get_my_role"]
# (Tabelle, Spalte, Fundstelle im Code)
CODE_COLUMNS = [
    ("tasks", "assets", "src/lib/supabase/tasks.ts:228"),
    ("tasks", "content_type", "src/types/content.ts:50"),
    ("tasks", "input_type", "src/lib/supabase/tasks.ts"),
    ("screening_items", "microskill_id", "src/lib/supabase/screeningItems.ts"),
    ("screening_items", "canonical", "src/lib/supabase/screeningItems.ts"),
    ("student_progress", "xp_total", "src/lib/supabase/progress.ts:11"),
    ("student_progress", "level", "src/lib/supabase/progress.ts:11"),
    ("student_progress", "streak_days", "supabase/functions/generate_parent_report/index.ts:305"),
    ("student_competency_mastery", "mastered", "src/lib/supabase/competencyMastery.ts"),
]
# Die drei Behauptungen aus der P00b+-Spec, die zu pruefen waren.
CLAIMS = [
    ("tasks.task_type", "tasks", "task_type"),
    ("task_assets (TABELLE)", "task_assets", None),
    ("tasks.assets", "tasks", "assets"),
]

CREATE_RE = re.compile(r"create\s+table\s+(?:if\s+not\s+exists\s+)?(?:public\.)?(\w+)", re.I)
ALTER_RE = re.compile(r"alter\s+table\s+(?:only\s+)?(?:public\.)?(\w+)\s+add\s+column\s+(?:if\s+not\s+exists\s+)?(\w+)", re.I)
DROP_COL_RE = re.compile(r"alter\s+table\s+(?:public\.)?(\w+)\s+drop\s+column\s+(?:if\s+exists\s+)?(\w+)", re.I)


def strip_comments(sql: str) -> str:
    return "\n".join(l.split("--")[0] for l in sql.splitlines())


def parse_sql(text: str) -> tuple[set[str], set[tuple[str, str]], set[tuple[str, str]]]:
    """-> (tabellen, (tabelle, spalte) via add column, (tabelle, spalte) via drop column)"""
    t = strip_comments(text)
    tables = {m.group(1).lower() for m in CREATE_RE.finditer(t)}
    added = {(m.group(1).lower(), m.group(2).lower()) for m in ALTER_RE.finditer(t)}
    dropped = {(m.group(1).lower(), m.group(2).lower()) for m in DROP_COL_RE.finditer(t)}
    return tables, added, dropped


def schema_sql_columns() -> dict[str, set[str]]:
    """Spalten je Tabelle aus den create-table-Bloecken von schema.sql."""
    text = SCHEMA.read_text(encoding="utf-8")
    cols: dict[str, set[str]] = {}
    for m in CREATE_RE.finditer(strip_comments(text)):
        name = m.group(1).lower()
        start = text.find("(", m.end())
        if start < 0:
            continue
        depth, i = 0, start
        while i < len(text):
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        body = strip_comments(text[start + 1:i])
        found: set[str] = set()
        for line in body.splitlines():
            line = line.strip().rstrip(",")
            if not line:
                continue
            first = line.split()[0].lower()
            if first in {"primary", "unique", "check", "constraint", "foreign", "exclude"}:
                continue
            found.add(first)
        cols[name] = found
    # spaetere add-column-Statements in schema.sql
    _, added, _ = parse_sql(text)
    for tbl, col in added:
        cols.setdefault(tbl, set()).add(col)
    return cols


def main() -> int:
    db = json.loads(DB_JSON.read_text(encoding="utf-8"))
    db_cols = {t["table"]: {c["name"] for c in t["columns"]} for t in db["tables"]}
    db_tables = set(db_cols)
    db_funcs = set(db["functions"])

    s_cols = schema_sql_columns()
    s_tables = set(s_cols)

    # Archiv: welche Migration legt was an / droppt was
    mig_tables: dict[str, str] = {}
    mig_cols: dict[tuple[str, str], str] = {}
    mig_drops: dict[tuple[str, str], str] = {}
    for f in sorted(ARCHIVE.glob("*.sql")):
        tag = f.name.split("_", 1)[1].replace(".sql", "")
        tables, added, dropped = parse_sql(f.read_text(encoding="utf-8"))
        for t in tables:
            mig_tables.setdefault(t, tag)
        for tc in added:
            mig_cols.setdefault(tc, tag)
        for tc in dropped:
            mig_drops[tc] = tag

    yn = lambda b: "✅" if b else "❌"
    L: list[str] = []
    A = L.append

    A("# Schema-Abgleich — Ist-Zustand (P00b+)\n")
    A("> Erzeugt von `scripts/db/schema_abgleich.py`. Stand: Phase 1–3 des P00b+-Laufs.\n")

    A("## Kernbefund (bitte zuerst lesen)\n")
    A("**Die 43 Migrationen in `migrations/` können die DB nicht aufbauen — und konnten es nie.**")
    A("Migration `001_competency_areas.sql` beginnt mit `delete from skill_clusters`, aber *keine*")
    A("Migration legt `skill_clusters` je an. Das Basis-Schema (profiles/students/subjects/")
    A("skill_clusters/microskills/tasks) existierte nur in `schema.sql` / `schema_content.sql` und")
    A("wurde per Hand im Supabase-SQL-Editor angewendet. Die 43 Dateien sind reine *Inkremente*")
    A("obendrauf.\n")
    A("Bewiesen, nicht vermutet — `supabase start` gegen die umgezogene Kette:\n")
    A("```")
    A("Applying migration 20250101000001_competency_areas.sql...")
    A('ERROR: relation "skill_clusters" does not exist (SQLSTATE 42P01)')
    A("```\n")
    A("**Empfehlung (umgesetzt):** `schema.sql` ist die einzige verlässliche Wahrheit für den")
    A("Neuaufbau. Daraus wurde die konsolidierte Baseline")
    A("`supabase/migrations/20250101000000_baseline.sql` erzeugt; die Katalogdaten liegen in")
    A("`supabase/seed.sql`. Die 43 Altdateien liegen unverändert in")
    A("`supabase/migrations_archive/` (Provenienz, aber nicht mehr ausgeführt).\n")

    A("## Die drei Behauptungen aus der Spec\n")
    A("Alle drei wurden gegen Code **und** DB geprüft. Zwei davon treffen nicht zu:\n")
    A("| Behauptung | Realität | Beleg |")
    A("|---|---|---|")
    A("| Code erwartet Spalte `tasks.task_type` | **Falsch.** `task_type` kommt in `src/`, "
      "`supabase/`, `schema.sql` und allen 43 Migrationen **kein einziges Mal** vor. Der "
      "Diskriminator heißt `content_type`. | `src/types/content.ts:50`, `schema.sql:285` |")
    A("| Code erwartet Tabelle `task_assets` | **Falsch.** Es gibt kein `.from('task_assets')`. "
      "Der String ist ausschließlich ein *Storage-Bucket* (`task-assets`, mit Bindestrich) bzw. "
      "ein Policy-/Dateiname. | `src/lib/supabase/storage.ts:8`, `schema.sql:1481-1493` |")
    A("| Verhältnis `tasks.assets` ↔ `task_assets` | `tasks.assets` ist eine **jsonb-Spalte** "
      "(Migration 009) mit `{url, alt, caption}[]`; `task-assets` ist der **Storage-Bucket**, in "
      "den die Bilder hochgeladen werden. Kein Join-Table, keine fehlende Tabelle. | "
      "`src/lib/supabase/tasks.ts:227-230`, `schema.sql:319` |")
    A("")
    for label, tbl, col in CLAIMS:
        if col is None:
            present = tbl in db_tables
        else:
            present = col in db_cols.get(tbl, set())
        A(f"- `{label}` in der gebauten DB vorhanden: {yn(present)}")
    A("")

    A("## Diff-Tabelle: Tabelle × {DB · schema.sql · migrations_archive}\n")
    A("„DB\" = die lokal aus der Baseline gebaute Datenbank (die Prod-DB ist von hier aus nicht")
    A("erreichbar, s.u.). „migrations/\" = legt *diese* Migration die Tabelle an?\n")
    A("| Tabelle | DB | schema.sql | angelegt in migrations/ | vom Code benutzt |")
    A("|---|:--:|:--:|---|:--:|")
    for t in sorted(db_tables | s_tables | set(mig_tables) | set(CODE_TABLES)):
        if t in mig_tables:
            origin = mig_tables[t]
        elif t in db_tables or t in s_tables:
            origin = "— (Basis-Schema, nie migriert)"
        else:
            origin = "**existiert nirgends**"
        A(f"| `{t}` | {yn(t in db_tables)} | {yn(t in s_tables)} | {origin} | "
          f"{yn(t in CODE_TABLES)} |")
    A("")

    A("## Spalten-Stichproben (inkl. der bekannten Streitfälle)\n")
    A("| Tabelle.Spalte | DB | schema.sql | Herkunft/Drop | Code-Fundstelle |")
    A("|---|:--:|:--:|---|---|")
    for tbl, col, where in CODE_COLUMNS:
        note = ""
        if (tbl, col) in mig_drops:
            note = f"**gedroppt in {mig_drops[(tbl, col)]}**"
        elif (tbl, col) in mig_cols:
            note = f"add column in {mig_cols[(tbl, col)]}"
        else:
            note = "— (Basis-Schema)"
        A(f"| `{tbl}.{col}` | {yn(col in db_cols.get(tbl, set()))} | "
          f"{yn(col in s_cols.get(tbl, set()))} | {note} | `{where}` |")
    A("")

    A("## Code → DB: echte Mismatches\n")
    missing_t = [t for t in CODE_TABLES if t not in db_tables]
    missing_r = [r for r in CODE_RPCS if r not in db_funcs]
    if missing_t or missing_r:
        A("Der Code greift auf Objekte zu, die es **nicht gibt**. Beides schlägt zur Laufzeit fehl,")
        A("wird aber im Edge-Function-Code stillschweigend verschluckt (`?? []` / `?? null`):\n")
        for t in missing_t:
            A(f"- **Tabelle `{t}` fehlt.** Abgefragt in "
              "`supabase/functions/generate_parent_report/index.ts:327`. Gemeint ist "
              "`skill_clusters` — der Elternbericht verliert dadurch **alle** Cluster-Namen.")
        for r in missing_r:
            A(f"- **RPC `{r}` fehlt.**")
        A("- **`student_progress.streak_days` fehlt.** Selektiert in "
          "`supabase/functions/generate_parent_report/index.ts:304-306`, aber von Migration 036 "
          "gedroppt (ersetzt durch `presence_streak_*`/`home_streak_*`, Migration 032). "
          "PostgREST antwortet mit 400 → XP/Level im Elternbericht degradieren still.")
    else:
        A("Keine.")
    A("")
    A("Beides sind **Code**-Fehler, keine Schema-Lücken: die DB ist korrekt, der Edge-Function-Code")
    A("ist gegen ein veraltetes Schema geschrieben. Fix gehört in")
    A("`supabase/functions/generate_parent_report/index.ts` — nicht in eine Migration.\n")

    A("## Prod-DB: nicht erreichbar (offen)\n")
    A("Der Ist-Zustand der **echten** Prod-DB konnte **nicht** erhoben werden. Zwei Gründe:\n")
    A("1. **`DATABASE_URL` in `.env` enthält noch den Platzhalter** `[YOUR-PASSWORD]` aus dem")
    A("   Supabase-Dashboard — es sind schlicht keine Zugangsdaten hinterlegt.")
    A("2. Der Direkt-Host `db.<ref>.supabase.co` löst **nur auf IPv6** auf; die WSL2-Umgebung hat")
    A("   keine IPv6-Route (`Network is unreachable`). Selbst mit Passwort bräuchte es den")
    A("   **IPv4-Pooler** (Supavisor, `postgres.<ref>@aws-N-<region>.pooler.supabase.com:5432`).\n")
    A("Sobald Rasit einen funktionierenden Pooler-String in `.env` legt, liefert")
    A("`python3 scripts/db/db_introspect.py` den Prod-Ist-Zustand und diese Tabelle bekommt ihre")
    A("vierte Spalte. Für den geplanten Neuaufbau ist das aber **nicht blockierend**: die Daten")
    A("sind wegwerfbar, und der Zielzustand steht fest (die Baseline).\n")

    A("## Zahlen der gebauten DB\n")
    A(f"- Relationen: **{len(db_tables)}**")
    A(f"- Enums: **{len(db['enums'])}** ({', '.join(e['name'] for e in db['enums'])})")
    A(f"- Funktionen: **{len(db_funcs)}**")
    A(f"- Trigger: **{len(db['triggers'])}** ({', '.join(t['name'] for t in db['triggers'])})")
    A(f"- RLS-Policies: **{len(db['policies'])}**")
    A("- Migrations-Tracking (`supabase_migrations.schema_migrations`): ✅ vorhanden — vorher gab es")
    A("  **keinerlei** Tracking, deshalb war nie feststellbar, welche Migration lief.\n")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(L), encoding="utf-8")
    print(f"schema_abgleich -> {OUT.relative_to(ROOT)}")
    print(f"  Tabellen DB={len(db_tables)} schema.sql={len(s_tables)} archiv-neu={len(mig_tables)}")
    print(f"  Code-Mismatches: Tabellen fehlen={missing_t} RPCs fehlen={missing_r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
