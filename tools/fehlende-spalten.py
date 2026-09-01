#!/usr/bin/env python3
"""
fehlende-spalten.py — vergleicht alle Spalten in Produktion mit denen, die die
Migrationsdateien anlegen. Findet die Lücke, die pg_dump systematisch verbirgt:
angehängte Spalten faltet der Abzug ins CREATE TABLE der ursprünglichen Tabelle,
sodass sie in der rekonstruierten Migration fehlen.

  python3 tools/fehlende-spalten.py
"""

import os, re, subprocess, sys, pathlib, collections

DATABASE_URL = os.environ.get("DATABASE_URL") or sys.exit("DATABASE_URL nicht gesetzt.")
REPO = pathlib.Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True).stdout.strip())
MIG = REPO / "supabase" / "migrations"

sys.path.insert(0, str(REPO))
quelle = (REPO / "schema-rekonstruktion.py")
if not quelle.exists(): quelle = REPO / "tools" / "schema-rekonstruktion.py"
exec(quelle.read_text().split("# ── Was legen")[0]
     .replace('APPLY = "--apply" in sys.argv', "APPLY = False"))   # split_statements

CONSTRAINT = re.compile(r"^\s*(constraint|primary|unique|foreign|check|exclude|like)\b", re.I)

def klammerinhalt(s, start):
    tiefe, i = 0, start
    while i < len(s):
        if s[i] == "(": tiefe += 1
        elif s[i] == ")":
            tiefe -= 1
            if tiefe == 0: return s[start+1:i]
        i += 1
    return ""

def top_split(s):
    teile, tiefe, buf = [], 0, []
    for c in s:
        if c == "(": tiefe += 1
        elif c == ")": tiefe -= 1
        if c == "," and tiefe == 0:
            teile.append("".join(buf)); buf = []
        else:
            buf.append(c)
    if buf: teile.append("".join(buf))
    return teile

# ── Was legt das Repo an ────────────────────────────────────────────────────

repo_spalten = collections.defaultdict(set)   # tabelle -> {spalten}

for f in sorted(MIG.glob("*.sql")):
    for st in split_statements(f.read_text(errors="replace")):
        s = re.sub(r"--.*$", "", st, flags=re.M)

        m = re.search(r"create\s+table\s+(?:if\s+not\s+exists\s+)?([\w.\"]+)", s, re.I)
        if m:
            tab = m.group(1).strip('"').split(".")[-1].lower()
            inhalt = klammerinhalt(s, s.index("(", m.end()-1))
            for teil in top_split(inhalt):
                teil = teil.strip()
                if not teil or CONSTRAINT.match(teil): continue
                name = re.match(r"[\"\w]+", teil)
                if name: repo_spalten[tab].add(name.group(0).strip('"').lower())
            continue

        m = re.search(r"alter\s+table\s+(?:only\s+)?([\w.\"]+)(.*)", s, re.I | re.S)
        if m:
            tab = m.group(1).strip('"').split(".")[-1].lower()
            for a in re.finditer(r"add\s+(?:column\s+)?(?:if\s+not\s+exists\s+)?([\"\w]+)",
                                 m.group(2), re.I):
                wort = a.group(1).strip('"').lower()
                if not CONSTRAINT.match(wort):
                    repo_spalten[tab].add(wort)

# ── Was hat Produktion ──────────────────────────────────────────────────────

roh = subprocess.run(["psql", DATABASE_URL, "-tAF|", "-c", """
select c.table_name, c.column_name,
       case when c.data_type = 'USER-DEFINED' then c.udt_name else c.data_type end,
       coalesce(c.column_default,''), c.is_nullable, c.ordinal_position
  from information_schema.columns c
  join information_schema.tables t
    on t.table_schema = c.table_schema and t.table_name = c.table_name
 where c.table_schema = 'public' and t.table_type = 'BASE TABLE'
 order by c.table_name, c.ordinal_position
"""], capture_output=True, text=True).stdout

prod = collections.defaultdict(list)
for z in roh.strip().splitlines():
    t = z.split("|")
    if len(t) >= 6:
        prod[t[0].lower()].append((t[1].lower(), t[2], t[3], t[4], int(t[5])))

# ── Vergleich ───────────────────────────────────────────────────────────────

STICHWORT = {
    "20260722120000_a13_grader_split_und_abgabeart": ["grader", "abgabe", "acceptance", "term", "bewert"],
    "20260722130000_a14_skill_substrat":             ["skill", "substrat", "thema", "themen", "sondier", "kante", "fundament"],
    "20260726100000_af1_fehlbild_capture":           ["fehlbild", "capture", "known_error"],
}

fehlend = collections.defaultdict(list)
for tab, spalten in sorted(prod.items()):
    if tab not in repo_spalten:
        continue                              # Tabelle selbst fehlt — anderes Problem
    for name, typ, default, nullable, pos in spalten:
        if name not in repo_spalten[tab]:
            fehlend[tab].append((name, typ, default, nullable, pos))

if not fehlend:
    print("\n  Keine fehlende Spalte. Die Migrationen legen jede Spalte aus Prod an.\n")
    sys.exit(0)

anzahl = sum(len(v) for v in fehlend.values())
print(f"\n  {anzahl} Spalte(n) in Produktion, die keine Migration anlegt:\n")

vorschlag = collections.defaultdict(list)
for tab, spalten in fehlend.items():
    print(f"  {tab}")
    for name, typ, default, nullable, pos in spalten:
        ddl = f"ALTER TABLE public.{tab} ADD COLUMN IF NOT EXISTS {name} {typ}"
        if default: ddl += f" DEFAULT {default}"
        if nullable == "NO": ddl += " NOT NULL"
        ddl += ";"

        treffer = [d for d, woerter in STICHWORT.items()
                   if any(w in name or w in tab for w in woerter)]
        ziel = treffer[0] if len(treffer) == 1 else None
        print(f"      {name:28s} {typ:14s} → {ziel.split('_',1)[1] if ziel else 'unklar'}")
        vorschlag[ziel or "UNKLAR"].append(ddl)
    print()

print("  Vorschlag — je Datei einfügen, VOR dem jeweiligen COMMENT ON COLUMN:\n")
for datei, ddls in vorschlag.items():
    print(f"    ── {datei}")
    for d in ddls: print(f"       {d}")
    print()

print("""  Hinweis: 'unklar' heisst nur, dass die Stichwörter nicht greifen. Solche Spalten
  gehören meist trotzdem in eine der drei rekonstruierten Migrationen — entscheidend
  ist, dass sie VOR der ersten Migration steht, die die Spalte benutzt.

  Prüfen, wer sie benutzt:
      grep -ln '<spaltenname>' supabase/migrations/*.sql | head -3
""")
