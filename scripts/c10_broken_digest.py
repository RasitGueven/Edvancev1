import json, sys
sys.path.insert(0, "scripts")
from c10_sicht import S
from c10_sicht2 import S2

SI = {**S, **S2}
http = json.load(open("data/c10_http_report.json"))
dump = {t["id"]: t for t in json.load(open("data/c10_dump.json"))}

by_item = {}
for h in http:
    by_item.setdefault((h["item_id"], h["title"]), []).append(h["file"])

REAL = {"sauber", "text_eingebrannt"}
targets = []
for (iid, title), files in by_item.items():
    if not any(SI.get(f, ("?",))[0] in REAL for f in files):
        targets.append((iid, title, files))
targets.sort(key=lambda x: x[1].lower())


def parts_text(t):
    out = []
    for p in (t.get("parts") or []):
        if isinstance(p, dict):
            frag = [v.strip() for v in p.values() if isinstance(v, str) and v.strip()]
            if frag:
                out.append(" / ".join(frag))
    return out


lines = [f"# PART A-broken (URL-Item, aber KEINE brauchbare Grafik) — {len(targets)} Items\n"]
for iid, title, files in targets:
    t = dump[iid]
    lines.append(f"## {title}")
    lines.append(f"typ={t.get('input_type')} | status={t.get('status')}")
    lines.append(f"FRAGE: {(t.get('question') or '(leer)').strip()[:600]}")
    for i, p in enumerate(parts_text(t), 1):
        lines.append(f"  Teil {i}: {p[:400]}")
    for f in files:
        lines.append(f"SICHTBEFUND[{f}]: {SI.get(f, ('?',''))[1][:160]}")
    lines.append("")
open("data/c10_partAbroken_digest.md", "w").write("\n".join(lines))
print("wrote", len(targets), "items -> data/c10_partAbroken_digest.md")
