import json

master = {r["id"]: r for r in json.load(open("data/c10_master.json"))}
dump = json.load(open("data/c10_dump.json"))
by_id = {t["id"]: t for t in dump}


def parts_text(t):
    out = []
    for p in (t.get("parts") or []):
        if isinstance(p, dict):
            frag = []
            for v in p.values():
                if isinstance(v, str) and v.strip():
                    frag.append(v.strip())
            if frag:
                out.append(" / ".join(frag))
    return out


def emit(items, label, path):
    lines = [f"# {label} — {len(items)} Items\n"]
    for r in items:
        t = by_id[r["id"]]
        lines.append(f"## {t['title']}")
        lines.append(f"typ={t.get('input_type')} | status={t.get('status')}")
        q = (t.get("question") or "").strip()
        lines.append(f"FRAGE: {q[:700] if q else '(leer)'}")
        pts = parts_text(t)
        for i, p in enumerate(pts, 1):
            lines.append(f"  Teil {i}: {p[:500]}")
        ments = r.get("img_mentions") or []
        if ments:
            lines.append("BILDVERWEIS: " + " | ".join(m.strip()[:120] for m in ments[:3]))
        lines.append("")
    open(path, "w").write("\n".join(lines))
    print(f"{label}: {len(items)} -> {path}")


part_b = sorted([r for r in master.values() if r["dead_assets"] and not r["url_assets"]],
                key=lambda r: by_id[r["id"]]["title"].lower())
part_c = sorted([r for r in master.values()
                 if r["img_mentions"] and not r["url_assets"] and not r["dead_assets"]],
                key=lambda r: by_id[r["id"]]["title"].lower())

emit(part_b, "PART B (tote Pfade, Grafik-lizenziert)", "data/c10_partB_digest.md")
emit(part_c, "PART C (nur Text-Bildverweis)", "data/c10_partC_digest.md")
