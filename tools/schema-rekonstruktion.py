#!/usr/bin/env python3
"""
schema-rekonstruktion.py — baut fehlende Migrationsdateien aus dem Prod-Schema.

Verfahren:
  1. pg_dump des Schemas
  2. In Einzelanweisungen zerlegen (dollar-quoting- und literalfest)
  3. Je Anweisung das Zielobjekt bestimmen
  4. Abziehen, was die vorhandenen Migrationsdateien nachweislich anlegen
  5. Rest den fehlenden Versionen zuordnen — über Stichwörter aus deren Namen
  6. Vorschlag nach supabase/rekonstruktion/ schreiben, NICHT nach migrations/

Der Vorschlag ist ein Vorschlag. Vor dem Übernehmen prüfen, danach den
Neuaufbau testen (siehe Ausgabe am Ende).

  python3 schema-rekonstruktion.py
  python3 schema-rekonstruktion.py --apply
"""

import os, re, subprocess, sys, pathlib, collections

APPLY = "--apply" in sys.argv
DATABASE_URL = os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    sys.exit("DATABASE_URL nicht gesetzt.")

REPO = pathlib.Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True).stdout.strip())
MIG = REPO / "supabase" / "migrations"
OUT = REPO / "supabase" / "rekonstruktion"

# ── Anweisungen zerlegen ────────────────────────────────────────────────────

def split_statements(sql: str):
    """Teilt an ';' auf oberster Ebene. Beachtet '...', "...", $tag$...$tag$, -- und /* */."""
    out, buf, i, n = [], [], 0, len(sql)
    while i < n:
        c = sql[i]
        if c == "-" and sql[i:i+2] == "--":
            j = sql.find("\n", i); j = n if j == -1 else j
            buf.append(sql[i:j]); i = j; continue
        if c == "/" and sql[i:i+2] == "/*":
            j = sql.find("*/", i); j = n if j == -1 else j + 2
            buf.append(sql[i:j]); i = j; continue
        if c in "'\"":
            j = i + 1
            while j < n:
                if sql[j] == c:
                    if j + 1 < n and sql[j+1] == c: j += 2; continue
                    j += 1; break
                j += 1
            buf.append(sql[i:j]); i = j; continue
        if c == "$":
            m = re.match(r"\$[A-Za-z_]\w*\$|\$\$", sql[i:])
            if m:
                tag = m.group(0)
                j = sql.find(tag, i + len(tag))
                j = n if j == -1 else j + len(tag)
                buf.append(sql[i:j]); i = j; continue
        if c == ";":
            s = "".join(buf).strip()
            if s: out.append(s + ";")
            buf, i = [], i + 1; continue
        buf.append(c); i += 1
    s = "".join(buf).strip()
    if s: out.append(s)
    return out

# ── Zielobjekt einer Anweisung ──────────────────────────────────────────────

MUSTER = [
    (r"create\s+(?:or\s+replace\s+)?function\s+([\w.\"]+)",              "function"),
    (r"create\s+table\s+(?:if\s+not\s+exists\s+)?([\w.\"]+)",            "table"),
    (r"create\s+(?:unique\s+)?index\s+(?:concurrently\s+)?(?:if\s+not\s+exists\s+)?([\w.\"]+)", "index"),
    (r"create\s+(?:or\s+replace\s+)?view\s+([\w.\"]+)",                  "view"),
    (r"create\s+type\s+([\w.\"]+)",                                      "type"),
    (r"create\s+policy\s+\"?([\w ]+)\"?\s+on\s+([\w.\"]+)",              "policy"),
    (r"create\s+trigger\s+([\w.\"]+)",                                   "trigger"),
    (r"create\s+schema\s+(?:if\s+not\s+exists\s+)?([\w.\"]+)",           "schema"),
    (r"alter\s+table\s+(?:only\s+)?([\w.\"]+)",                          "alter"),
    (r"comment\s+on\s+\w+\s+([\w.\"(),\s]+?)\s+is",                      "comment"),
    (r"(?:grant|revoke)\b.*?\son\s+(?:function|table|schema)?\s*([\w.\"]+)", "acl"),
    (r"insert\s+into\s+([\w.\"]+)",                                      "insert"),
]

def ziel(stmt: str):
    s = re.sub(r"--.*$", "", stmt, flags=re.M).strip().lower()
    for muster, art in MUSTER:
        m = re.search(muster, s, re.S)
        if m:
            name = m.group(1).strip().strip('"').split("(")[0].strip()
            if "." in name: name = name.split(".")[-1]
            return art, name
    return None, None

# ── Was legen die vorhandenen Dateien an ────────────────────────────────────

belegt = collections.defaultdict(list)   # objektname -> [dateiname]
for f in sorted(MIG.glob("*.sql")):
    for st in split_statements(f.read_text(errors="replace")):
        art, name = ziel(st)
        if name and art in ("table", "function", "type", "view", "index",
                            "policy", "trigger", "schema"):
            belegt[name].append(f.name)

print(f"\n  {len(list(MIG.glob('*.sql')))} vorhandene Migrationen legen "
      f"{len(belegt)} benannte Objekte an.\n")

# ── Fehlende Versionen ──────────────────────────────────────────────────────

def psql(q):
    r = subprocess.run(["psql", DATABASE_URL, "-tAc", q], capture_output=True, text=True)
    return r.stdout.strip()

fehlend = []
for zeile in psql("select version || '|' || coalesce(name,'') "
                  "from supabase_migrations.schema_migrations order by version").splitlines():
    v, _, name = zeile.partition("|")
    if not list(MIG.glob(f"{v}_*.sql")):
        fehlend.append((v, name))

if not fehlend:
    sys.exit("  Keine Datei fehlt.")

print("  Fehlend:")
for v, name in fehlend:
    print(f"    {v}  {name}")

# Stichwörter aus dem Namen — 'a13', 'grader', 'split', 'abgabeart' …
STOPP = {"und", "der", "die", "das", "von", "fuer", "mit", "a13", "a14", "af1"}
schluessel = []
for v, name in fehlend:
    woerter = [w for w in re.split(r"[_\W]+", name.lower()) if len(w) > 3 and w not in STOPP]
    schluessel.append((v, name, woerter))
    print(f"    → {v}: Stichwörter {woerter}")

# ── Schema ziehen ───────────────────────────────────────────────────────────

schemas = [s for s in psql(
    "select nspname from pg_namespace where nspname not like 'pg\\_%' "
    "and nspname not in ('information_schema','extensions','graphql','graphql_public',"
    "'realtime','storage','vault','supabase_migrations','auth','net','cron','pgsodium',"
    "'pgsodium_masks','supabase_functions')").splitlines() if s]
print(f"\n  Schemata: {', '.join(schemas)}")

cmd = ["pg_dump", DATABASE_URL, "--schema-only", "--no-owner", "--no-acl", "--no-comments"]
for s in schemas: cmd += ["--schema", s]
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode != 0:
    print("\n  pg_dump fehlgeschlagen:\n" + "\n".join("    " + z for z in r.stderr.splitlines()[:12]))
    if "version mismatch" in r.stderr or "server version" in r.stderr:
        print("\n  Client-Version zu alt. Abhilfe:\n"
              "    sudo apt install -y postgresql-client-17\n"
              "    export PATH=/usr/lib/postgresql/17/bin:$PATH")
    sys.exit(1)

alle = split_statements(r.stdout)
print(f"  {len(alle)} Anweisungen im Schema-Abzug.")

# ── Zuordnen ────────────────────────────────────────────────────────────────

IGNORIEREN = re.compile(
    r"^\s*(set|select\s+pg_catalog|create\s+extension|alter\s+default|"
    r"revoke|grant|create\s+schema\s+(public|auth|storage))", re.I)

zuordnung = collections.defaultdict(list)
nicht_zuordenbar = []
uebrig = 0

for st in alle:
    if IGNORIEREN.match(st): continue
    art, name = ziel(st)
    if not name: continue
    if name in belegt: continue            # gehört einer vorhandenen Datei
    uebrig += 1
    treffer = [v for v, _, woerter in schluessel
               if any(w in name.lower() or w in st.lower()[:300] for w in woerter)]
    if len(treffer) == 1:
        zuordnung[treffer[0]].append(st)
    else:
        nicht_zuordenbar.append((name, art, st, treffer))

print(f"\n  {uebrig} Anweisung(en) keiner vorhandenen Datei zuzuordnen.\n")
for v, name, _ in schluessel:
    print(f"    {v}  {name:34s} {len(zuordnung[v]):3d} Anweisung(en)")
print(f"    {'':16s} {'nicht zuordenbar':34s} {len(nicht_zuordenbar):3d}")

if nicht_zuordenbar:
    print("\n  Nicht eindeutig — von Hand einsortieren:")
    for name, art, _, treffer in nicht_zuordenbar[:25]:
        hinweis = f"passt auf {treffer}" if treffer else "kein Stichwort trifft"
        print(f"      {art:9s} {name:38s} {hinweis}")
    if len(nicht_zuordenbar) > 25:
        print(f"      … und {len(nicht_zuordenbar)-25} weitere")

# ── Schreiben ───────────────────────────────────────────────────────────────

if not APPLY:
    print("\n  Trockenlauf. Schreiben mit: python3 schema-rekonstruktion.py --apply\n")
    sys.exit(0)

OUT.mkdir(parents=True, exist_ok=True)
for v, name, woerter in schluessel:
    ziel_datei = OUT / f"{v}_{name}.sql"
    kopf = [
        f"-- {v}_{name}",
        f"-- Rekonstruiert aus dem Prod-Schema. Der ursprüngliche Wortlaut ist verloren;",
        f"-- massgeblich ist, dass ein Neuaufbau denselben Zustand erreicht.",
        f"-- Zuordnung über Stichwörter: {', '.join(woerter) or '(keine)'}",
        "",
    ]
    koerper = zuordnung[v] or ["-- Keine Anweisung automatisch zugeordnet.\n"
                              "-- Aus der Liste 'nicht zuordenbar' ergänzen."]
    ziel_datei.write_text("\n".join(kopf) + "\n\n".join(koerper) + "\n")
    print(f"  ✓ {ziel_datei.relative_to(REPO)}  ({len(zuordnung[v])} Anweisungen)")

if nicht_zuordenbar:
    rest = OUT / "ZZZ_nicht_zugeordnet.sql"
    rest.write_text(
        "-- Diese Anweisungen liessen sich keiner fehlenden Migration eindeutig zuordnen.\n"
        "-- Von Hand in die passende Datei oben verschieben, dann diese Datei löschen.\n\n"
        + "\n\n".join(st for _, _, st, _ in nicht_zuordenbar) + "\n")
    print(f"  ✓ {rest.relative_to(REPO)}  ({len(nicht_zuordenbar)} Anweisungen)")

print(f"""
  Nächste Schritte:

    1. Dateien in supabase/rekonstruktion/ durchsehen und einsortieren,
       ZZZ_nicht_zugeordnet.sql auflösen und löschen.

    2. Übernehmen:
         git mv supabase/rekonstruktion/2026*.sql supabase/migrations/
         rmdir supabase/rekonstruktion

    3. NICHT einspielen — die Versionen stehen schon in der Historie.

    4. Beweis antreten. Nur ein Neuaufbau zeigt, ob die Rekonstruktion trägt:
         supabase db reset                     # gegen eine lokale Instanz
         pg_dump <lokal>  --schema-only --no-owner --no-acl | sort > /tmp/neu.txt
         pg_dump "$DATABASE_URL" --schema-only --no-owner --no-acl | sort > /tmp/prod.txt
         diff /tmp/neu.txt /tmp/prod.txt

       Ohne diesen Schritt hast du geraten, nicht rekonstruiert.
""")
