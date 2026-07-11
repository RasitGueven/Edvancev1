#!/usr/bin/env python3
"""Liest den IST-Zustand der Remote-DB (READ-ONLY) und legt ihn als JSON ab.

Kein lokales psql vorhanden -> psql laeuft in einem Wegwerf-Container
(postgres:16-alpine). Der Connection-String kommt aus .env, wird nur per Env in
den Container gereicht und NIE geloggt.

Usage:  python3 scripts/db/db_introspect.py [--out docs/audits/_db_ist.json] [--url-env DATABASE_URL]
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]

# Ein einziges read-only SELECT. Keine Schreib-Statements — bewusst.
SQL = r"""
select json_build_object(
  'tables', (
    select coalesce(json_agg(json_build_object(
      'table', c.relname,
      'kind',  case c.relkind when 'r' then 'table' when 'v' then 'view'
                              when 'm' then 'matview' when 'p' then 'partitioned' end,
      'rls',   c.relrowsecurity,
      'columns', (
        select coalesce(json_agg(json_build_object(
          'name',    a.attname,
          'type',    format_type(a.atttypid, a.atttypmod),
          'notnull', a.attnotnull,
          'default', pg_get_expr(d.adbin, d.adrelid)
        ) order by a.attnum), '[]'::json)
        from pg_attribute a
        left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
        where a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
      )
    ) order by c.relname), '[]'::json)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r','v','m','p')
  ),
  'enums', (
    select coalesce(json_agg(json_build_object(
      'name', t.typname,
      'values', (select coalesce(json_agg(e.enumlabel order by e.enumsortorder), '[]'::json)
                 from pg_enum e where e.enumtypid = t.oid)
    ) order by t.typname), '[]'::json)
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public' and t.typtype = 'e'
  ),
  'functions', (
    select coalesce(json_agg(distinct p.proname), '[]'::json)
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  ),
  'triggers', (
    select coalesce(json_agg(json_build_object('name', t.tgname, 'table', c.relname)
           order by t.tgname), '[]'::json)
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and not t.tgisinternal
  ),
  'policies', (
    select coalesce(json_agg(json_build_object('table', tablename, 'policy', policyname)
           order by tablename, policyname), '[]'::json)
    from pg_policies where schemaname = 'public'
  ),
  'schema_migrations', (
    select coalesce(json_agg(json_build_object('schema', table_schema, 'table', table_name)), '[]'::json)
    from information_schema.tables where table_name = 'schema_migrations'
  )
) as ist;
"""


def load_env(path: pathlib.Path) -> dict[str, str]:
    """Minimaler .env-Parser (KEY=VALUE, # Kommentare, optionale Quotes)."""
    env: dict[str, str] = {}
    if not path.is_file():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        val = val.strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        env[key.strip()] = val
    return env


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="docs/audits/_db_ist.json")
    ap.add_argument("--url-env", default="DATABASE_URL",
                    help="Env/.env-Key mit dem Connection-String (Remote-Modus)")
    ap.add_argument("--container", default=None,
                    help="Statt Remote: psql IM laufenden lokalen DB-Container "
                         "(z.B. supabase_db_Edvancev1). Kein Netzwerk noetig.")
    args = ap.parse_args()

    if args.container:
        cmd = ["docker", "exec", "-i", args.container,
               "psql", "-U", "postgres", "-d", "postgres",
               "-tAX", "-v", "ON_ERROR_STOP=1", "-f", "-"]
    else:
        env = load_env(ROOT / ".env")
        url = os.environ.get(args.url_env) or env.get(args.url_env)
        if not url:
            print(f"db_introspect: {args.url_env} weder in Umgebung noch in .env gefunden.", file=sys.stderr)
            return 1
        cmd = ["docker", "run", "--rm", "-i",
               "-e", f"PGCONNSTR={url}",        # nur hier, nie in Logs
               "postgres:16-alpine",
               "sh", "-c", 'exec psql "$PGCONNSTR" -tAX -v ON_ERROR_STOP=1 -f -']

    proc = subprocess.run(cmd, input=SQL, capture_output=True, text=True)
    if proc.returncode != 0:
        # stderr von psql kann den Host enthalten, aber nie das Passwort.
        print("db_introspect: psql fehlgeschlagen:\n" + proc.stderr.strip(), file=sys.stderr)
        return proc.returncode

    payload = proc.stdout.strip()
    if not payload:
        print("db_introspect: leere Antwort von psql.", file=sys.stderr)
        return 1

    data = json.loads(payload)
    out = ROOT / args.out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"db_introspect: {len(data['tables'])} Relationen, {len(data['enums'])} Enums, "
          f"{len(data['triggers'])} Trigger, {len(data['policies'])} Policies -> {args.out}")
    print(f"db_introspect: schema_migrations vorhanden: {bool(data['schema_migrations'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
