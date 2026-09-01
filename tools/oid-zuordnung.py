#!/usr/bin/env python3
"""
oid-zuordnung.py — ordnet die unklaren Objekte über die OID-Reihenfolge zu.

Postgres vergibt OIDs aufsteigend. Von den vorhandenen Migrationsdateien weisst du,
welches Objekt aus welcher Migration stammt — das ergibt eine datierte Kette. Ein
Objekt ohne Zuordnung fällt zwischen zwei bekannte Nachbarn; liegen beide in
derselben Migration, ist die Sache klar. Liegen sie in verschiedenen, ist es eine
der Migrationen dazwischen — und dazwischen liegen genau deine fehlenden.

Das ist Empirie statt Stichwortraten.

  python3 oid-zuordnung.py
"""

import os, re, subprocess, sys, pathlib, bisect, collections

DATABASE_URL = os.environ.get("DATABASE_URL") or sys.exit("DATABASE_URL nicht gesetzt.")
REPO = pathlib.Path(subprocess.run(["git", "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True).stdout.strip())
MIG = REPO / "supabase" / "migrations"

sys.path.insert(0, str(REPO))
exec(open(REPO / "schema-rekonstruktion.py").read().split("# ── Was legen")[0]
     .replace('APPLY = "--apply" in sys.argv', "APPLY = False"))   # split_statements, ziel

def psql(q):
    return subprocess.run(["psql", DATABASE_URL, "-tAF|", "-c", q],
                          capture_output=True, text=True).stdout.strip()

# ── Objekt → OID ────────────────────────────────────────────────────────────

Q = """
select 'table',    c.relname, c.oid::bigint from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind in ('r','p','v','m')
union all
select 'index',    c.relname, c.oid::bigint from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'i'
union all
select 'function', p.proname, p.oid::bigint from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'
union all
select 'type',     t.typname, t.oid::bigint from pg_type t
  join pg_namespace n on n.oid = t.typnamespace
 where n.nspname = 'public' and t.typtype in ('e','c','d')
union all
select 'trigger',  g.tgname, g.oid::bigint from pg_trigger g
  join pg_class c on c.oid = g.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and not g.tgisinternal
order by 3
"""

objekte = []          # (oid, art, name)
for z in psql(Q).splitlines():
    teile = z.split("|")
    if len(teile) == 3:
        objekte.append((int(teile[2]), teile[0], teile[1]))

# ── Wer legt was an ─────────────────────────────────────────────────────────

herkunft = {}         # name -> version
for f in sorted(MIG.glob("*.sql")):
    version = f.name.split("_")[0]
    for st in split_statements(f.read_text(errors="replace")):
        art, name = ziel(st)
        if name and art in ("table", "function", "type", "view", "index",
                            "policy", "trigger", "schema"):
            herkunft.setdefault(name, version)

versionen = sorted({v for v in herkunft.values()})

# Fehlende Versionen
fehlend = []
for z in psql("select version || '|' || coalesce(name,'') "
              "from supabase_migrations.schema_migrations order by version").splitlines():
    v, _, nm = z.partition("|")
    if not list(MIG.glob(f"{v}_*.sql")):
        fehlend.append((v, nm))
fehlend_v = {v for v, _ in fehlend}

alle_versionen = sorted(set(versionen) | fehlend_v)

# ── Ankerkette ──────────────────────────────────────────────────────────────

anker = [(oid, herkunft[name]) for oid, art, name in objekte if name in herkunft]
anker.sort()
anker_oids = [o for o, _ in anker]

def zwischen(oid):
    i = bisect.bisect_left(anker_oids, oid)
    vor  = anker[i-1][1] if i > 0 else None
    nach = anker[i][1]   if i < len(anker) else None
    return vor, nach

print(f"\n  {len(objekte)} Objekte im Schema, {len(anker)} davon einer Datei zugeordnet.")
print(f"  Fehlende Versionen: {', '.join(sorted(fehlend_v))}\n")

INFRA = re.compile(r"^(pgbouncer|get_auth|pg_|_pg)", re.I)

ohne = [(oid, art, name) for oid, art, name in objekte
        if name not in herkunft and not INFRA.match(name)]

print(f"  {len(ohne)} Objekt(e) ohne Zuordnung:\n")
print(f"    {'objekt':40s} {'art':9s} {'vorheriger':16s} {'nächster':16s} → Vorschlag")
print("    " + "─" * 100)

vorschlag = collections.defaultdict(list)
unklar = []

for oid, art, name in ohne:
    vor, nach = zwischen(oid)

    if vor and nach and vor == nach:
        v = vor
        gueltig = v in fehlend_v
        hinweis = v if gueltig else f"{v} (Datei existiert — Parser hat's übersehen)"
    else:
        # Kandidaten: alle Versionen echt zwischen vor und nach
        kand = [v for v in alle_versionen
                if (vor is None or v > vor) and (nach is None or v < nach)]
        kand_fehlend = [v for v in kand if v in fehlend_v]
        if len(kand_fehlend) == 1:
            v, hinweis, gueltig = kand_fehlend[0], kand_fehlend[0], True
        elif kand_fehlend:
            v, hinweis, gueltig = None, f"mehrdeutig: {', '.join(kand_fehlend)}", False
        else:
            v, hinweis, gueltig = None, "keine fehlende Version im Bereich", False

    print(f"    {name:40s} {art:9s} {str(vor or '—'):16s} {str(nach or '—'):16s} → {hinweis}")
    if gueltig and v in fehlend_v:
        vorschlag[v].append((art, name))
    else:
        unklar.append((art, name, hinweis))

print()
for v, nm in fehlend:
    eintraege = vorschlag[v]
    print(f"  {v}  {nm}")
    if eintraege:
        for art, name in eintraege:
            print(f"      {art:9s} {name}")
    else:
        print("      (nichts über OID zugeordnet)")
    print()

if unklar:
    print("  Weiterhin unklar:")
    for art, name, hinweis in unklar:
        print(f"      {art:9s} {name:38s} {hinweis}")
    print()

print("""  Lesart:

    Liegen vorheriger und nächster Nachbar in derselben Migration, gehört das Objekt
    dort hinein — dann hat der Parser in schema-rekonstruktion.py die Anweisung nur
    nicht erkannt, und es fehlt gar nichts.

    Liegen sie auseinander und dazwischen liegt genau eine fehlende Version, ist die
    Zuordnung so sicher, wie sie ohne den Originaltext werden kann.

    OIDs sind nur fast monoton — bei einzelnen Ausreissern das Ergebnis gegen die
    Stichwort-Zuordnung aus schema-rekonstruktion.py halten. Wo beide übereinstimmen,
    kannst du es glauben.
""")
