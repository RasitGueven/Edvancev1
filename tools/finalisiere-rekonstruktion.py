#!/usr/bin/env python3
"""
finalisiere-rekonstruktion.py — schreibt die drei fehlenden Migrationsdateien.

Die Zuordnung steht unten in ZUORDNUNG und ist bewusst sichtbar statt geraten:
sie ergibt sich aus OID-Reihenfolge plus Migrationsnamen. Prüfen, bei Bedarf
ändern, dann laufen lassen.

Übernommen wird die Anweisungsreihenfolge aus pg_dump — die ist
abhängigkeitssicher, anders als jede selbst gebaute.

  python3 finalisiere-rekonstruktion.py
  python3 finalisiere-rekonstruktion.py --apply
"""

import os, re, subprocess, sys, pathlib, collections

APPLY = "--apply" in sys.argv
DATABASE_URL = os.environ.get("DATABASE_URL") or sys.exit("DATABASE_URL nicht gesetzt.")
REPO = pathlib.Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True).stdout.strip())
OUT = REPO / "supabase" / "rekonstruktion"

sys.path.insert(0, str(REPO))
exec(open(REPO / "schema-rekonstruktion.py").read().split("# ── Was legen")[0]
     .replace('APPLY = "--apply" in sys.argv', "pass"))   # split_statements, ziel

# ─────────────────────────────────────────────────────────────────────────────
# Zuordnung — Ergebnis aus oid-zuordnung.py, hier zum Prüfen und Ändern.
# ─────────────────────────────────────────────────────────────────────────────

ZUORDNUNG = {
    "20260722120000_a13_grader_split_und_abgabeart": [
        "lsa_normalize_term",
        "lsa_is_unit",
        "lsa_term_acceptance_guard",
        "tasks_term_acceptance",
        "task_solutions_term_acceptance",
        "lsa_abgabeart",
    ],
    "20260722130000_a14_skill_substrat": [
        "skills",
        "skill_kante",
        "skill_kante_voraussetzt_idx",
        "skill_kante_tiefe_guard",
        "skill_kante_tiefe",
        "themen",
        "skill_voraussetzung",
        "tasks_skill_key_idx",
    ],
    "20260726100000_af1_fehlbild_capture": [
        "lsa_fehlbild_match",
        "lsa_fehlbild_capture",
        "trg_lsa_fehlbild_capture",
        "lsa_responses_fehlbild_idx",
    ],
}

# ─────────────────────────────────────────────────────────────────────────────

def psql(q):
    return subprocess.run(["psql", DATABASE_URL, "-tAF|", "-c", q],
                          capture_output=True, text=True).stdout.strip()

# Indizes, die zu einem Constraint gehören — die erzeugt Postgres selbst,
# pg_dump gibt sie als ALTER TABLE ADD CONSTRAINT aus, nicht als CREATE INDEX.
implizit = set(psql("""
    select c.relname from pg_index i
      join pg_class c on c.oid = i.indexrelid
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and exists (select 1 from pg_constraint k where k.conindid = i.indexrelid)
""").splitlines())

cmd = ["pg_dump", DATABASE_URL, "--schema-only", "--no-owner", "--no-acl", "--schema", "public"]
r = subprocess.run(cmd, capture_output=True, text=True)
if r.returncode != 0:
    sys.exit("pg_dump fehlgeschlagen:\n" + r.stderr[:800])

anweisungen = split_statements(r.stdout)

# Objektname → Zieldatei
gehoert_zu = {}
for datei, namen in ZUORDNUNG.items():
    for n in namen:
        gehoert_zu[n.lower()] = datei

IGNORIEREN = re.compile(r"^\s*(set|select\s+pg_catalog|create\s+extension|"
                        r"alter\s+default|create\s+schema)", re.I)

gesammelt = collections.defaultdict(list)
getroffen = collections.defaultdict(set)

for st in anweisungen:
    if IGNORIEREN.match(st):
        continue
    art, name = ziel(st)
    if not name:
        continue
    name = name.lower()

    datei = gehoert_zu.get(name)
    # ALTER TABLE / COMMENT / INDEX auf einer zugeordneten Tabelle geht mit
    if not datei and art in ("alter", "comment", "index", "acl", "policy", "trigger"):
        for kandidat, d in gehoert_zu.items():
            if re.search(rf"\b{re.escape(kandidat)}\b", st.lower()[:400]):
                datei = d
                break
    if not datei:
        continue

    gesammelt[datei].append(st)
    getroffen[datei].add(name)

# ── Bericht ─────────────────────────────────────────────────────────────────
print()
for datei, namen in ZUORDNUNG.items():
    print(f"  {datei}")
    print(f"    {len(gesammelt[datei])} Anweisung(en) aus dem Schema-Abzug")
    fehlt = [n for n in namen
             if n.lower() not in getroffen[datei] and n not in implizit]
    if fehlt:
        print(f"    ✗ nicht im Abzug gefunden: {', '.join(fehlt)}")
        print(f"      (existiert das Objekt wirklich? Name im ZUORDNUNG-Block prüfen)")
    print()

if not APPLY:
    print("  Trockenlauf. Schreiben mit: python3 finalisiere-rekonstruktion.py --apply\n")
    sys.exit(0)

# ── Schreiben ───────────────────────────────────────────────────────────────
OUT.mkdir(parents=True, exist_ok=True)
for datei, sts in gesammelt.items():
    p = OUT / f"{datei}.sql"
    kopf = f"""-- {datei}
--
-- Rekonstruiert aus dem Prod-Schema am {subprocess.run(['date','-u','+%F'],
    capture_output=True, text=True).stdout.strip()}.
-- Der ursprüngliche Wortlaut ist verloren; die Version steht bereits in
-- supabase_migrations.schema_migrations. Massgeblich ist allein, dass ein
-- Neuaufbau aus dem Repo denselben Zustand erreicht.
--
-- NICHT einspielen. Die Version gilt als angewandt.

"""
    p.write_text(kopf + "\n\n".join(sts) + "\n")
    print(f"  ✓ {p.relative_to(REPO)}  ({len(sts)} Anweisungen, {len(p.read_text().splitlines())} Zeilen)")

print(f"""
  Durchsehen, dann übernehmen:

    less supabase/rekonstruktion/*.sql
    git mv supabase/rekonstruktion/*.sql supabase/migrations/
    rmdir supabase/rekonstruktion
    scripts/check-migration-drift.sh

  Danach der Beweis — ohne den ist es geraten, nicht rekonstruiert:

    supabase db reset                                        # leere lokale Instanz
    pg_dump "$LOCAL_DBURL" --schema-only --no-owner --no-acl --schema public \\
      | grep -v '^--' | sort > /tmp/neu.txt
    pg_dump "$DATABASE_URL" --schema-only --no-owner --no-acl --schema public \\
      | grep -v '^--' | sort > /tmp/prod.txt
    diff /tmp/neu.txt /tmp/prod.txt

  Ein leerer diff heisst: das Repo baut Prod nach. Erst dann ist der Drift zu.
""")
