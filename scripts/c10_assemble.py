#!/usr/bin/env python3
"""C10 Voll-Audit — Zusammenbau der Berichte (read-only auf DB; schreibt nur Dateien).
Erzeugt:
  data/audit-bilder.csv        (pro URL-Bild)
  data/audit-2026-07.csv       (pro Item)
  docs/content/AUDIT-2026-07.md
  data/stoffanker-revert.sql   (setzt die vorbelegten IDs auf NULL zurueck)
  data/stoffanker-apply.sql    (die EINE Teil-4-Transaktion; wird separat ausgefuehrt)
Quellen: c10_stoffanker.T, c10_sicht.S + c10_sicht2.S2, c10_broken_loesbar.BROKEN,
         data/c10_db_complete.json (live), c10_master.json, c10_http_report.json,
         data/c10_partB_loesbar.json, data/c10_partC_loesbar.json
"""
import csv, json, os, sys, collections
sys.path.insert(0, "scripts")
from c10_stoffanker import T
from c10_sicht import S
from c10_sicht2 import S2
from c10_broken_loesbar import BROKEN

SICHT = {**S, **S2}
REAL = {"sauber", "text_eingebrannt"}

db = json.load(open("data/c10_db_complete.json"))
by_id = {r["id"]: r for r in db}
master = {r["id"]: r for r in json.load(open("data/c10_master.json"))}
http = json.load(open("data/c10_http_report.json"))
partB = json.load(open("data/c10_partB_loesbar.json"))
partC = json.load(open("data/c10_partC_loesbar.json"))

# images grouped by item
imgs_by_item = collections.defaultdict(list)
for h in http:
    imgs_by_item[h["item_id"]].append(h)

# ---- sanity: every title in T? ----
missing_T = [r["title"] for r in db if r["title"] not in T]
assert not missing_T, f"Titel ohne Stoffanker-Urteil: {missing_T}"

# ============ 1) audit-bilder.csv ============
with open("data/audit-bilder.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["url", "item_id", "title", "http_status", "content_type",
                "sichtbefund", "crop_beschreibung", "passt_zum_text"])
    for h in sorted(http, key=lambda x: (x["title"].lower(), x["file"])):
        sb = SICHT.get(h["file"], ("(nicht gesichtet)", "", "", ""))
        w.writerow([h["url"], h["item_id"], h["title"], h["http_status"],
                    h.get("content_type", ""), sb[0], sb[1], sb[2]])

# ============ 2) audit-2026-07.csv ============
rows_out = []
vorbelegt_ids = []
for r in sorted(db, key=lambda x: x["title"].lower()):
    iid, title = r["id"], r["title"]
    tv = T[title]
    grade, konf = tv[0], tv[1]
    m = master.get(iid, {})
    imgs = imgs_by_item.get(iid, [])

    vorbelegt = (konf == "sicher" and r["status"] == "draft"
                 and r["curriculum_grade"] is None)
    if vorbelegt:
        vorbelegt_ids.append((iid, grade))

    # asset assessment
    crop_noetig = ""
    ohne_bild = ""
    alt_text = ""
    if imgs:
        verdicts = [SICHT.get(h["file"], ("?", "", "", "")) for h in imgs]
        present = any(v[0] in REAL for v in verdicts)
        if present:
            asset_status = "bild_vorhanden"
            crop_noetig = "ja" if any(v[0] == "text_eingebrannt" for v in verdicts) else "nein"
            for v in verdicts:
                if v[0] in REAL and v[3]:
                    alt_text = v[3]
                    break
        else:
            asset_status = "bild_ohne_grafik"  # Foto/Grafik im Render verloren o. nur MC-Optionen als Bild
            ohne_bild = BROKEN.get(title, ("?", ""))[0]
    elif m.get("dead_assets"):
        asset_status = "tote_pfade_nachladbar"
        ohne_bild = partB.get(title, {}).get("ohne_bild_loesbar", "?")
    elif m.get("img_mentions"):
        asset_status = "text_verweis"
        ohne_bild = partC.get(title, {}).get("ohne_bild_loesbar", "?")
    else:
        asset_status = "kein_bild"

    loesung_da = "ja" if r["has_correct"] else "nein"
    beleg_da = "ja" if r["has_beleg"] else "nein"

    # empfohlene aktion (dominant, most-blocking first)
    it_null = r["input_type"] is None
    mc_no_opt = (r["input_type"] == "MC" and not r["has_correct"])
    incomplete = (not r["has_correct"]) or it_null
    bild_decision = (asset_status in ("bild_ohne_grafik", "tote_pfade_nachladbar", "text_verweis")
                     and ohne_bild in ("nein", "vielleicht"))
    if incomplete:
        det = []
        if not r["has_correct"]:
            det.append("kein Loesungsschluessel")
        if it_null:
            det.append("input_type fehlt")
        if mc_no_opt:
            det.append("MC ohne Optionen")
        aktion = "P5 unvollstaendig: " + ", ".join(det)
    elif bild_decision:
        if asset_status == "tote_pfade_nachladbar":
            aktion = "P4 Bild-Entscheidung: Grafik nachladen (lizenziert) oder ohne Bild pruefen"
        elif asset_status == "bild_ohne_grafik":
            aktion = "P4 Bild-Entscheidung: Render verloren — Grafik neu einbetten/zeichnen"
        else:
            aktion = "P4 Bild-Entscheidung: Eigengrafik noetig oder Text ergaenzen"
    elif crop_noetig == "ja":
        aktion = "P2 Crop noetig"
    elif asset_status == "bild_vorhanden":
        aktion = "P3 Alt-Text ergaenzen"
    elif vorbelegt:
        aktion = f"P1 Anker bestaetigen (Vorschlag Kl. {grade})"
    elif konf == "sicher":
        aktion = "ok (Anker bereits gesetzt / ready)"
    else:
        aktion = f"Anker offen ({konf}) — menschliche Entscheidung"

    rows_out.append({
        "id": iid, "title": title, "status": r["status"],
        "input_type": r["input_type"] or "",
        "stoffanker_vorschlag": grade if grade is not None else "",
        "konfidenz": konf, "vorbelegt": "ja" if vorbelegt else "nein",
        "duration_vorschlag": tv[5] if tv[5] is not None else "",
        "asset_status": asset_status, "crop_noetig": crop_noetig,
        "ohne_bild_loesbar": ohne_bild, "alt_text_vorschlag": alt_text,
        "loesung_da": loesung_da, "beleg_da": beleg_da,
        "empfohlene_aktion": aktion,
    })

cols = ["id", "title", "status", "input_type", "stoffanker_vorschlag", "konfidenz",
        "vorbelegt", "duration_vorschlag", "asset_status", "crop_noetig",
        "ohne_bild_loesbar", "alt_text_vorschlag", "loesung_da", "beleg_da",
        "empfohlene_aktion"]
with open("data/audit-2026-07.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=cols)
    w.writeheader()
    w.writerows(rows_out)

# ============ 4) stoffanker SQL ============
vorbelegt_ids.sort(key=lambda x: x[0])
ids_list = ",\n  ".join(f"'{i}'" for i, _ in vorbelegt_ids)
values = ",\n  ".join(f"('{i}'::uuid, {g}::smallint)" for i, g in vorbelegt_ids)

with open("data/stoffanker-revert.sql", "w") as f:
    f.write("-- C10 Voll-Audit: Revert der Stoffanker-Vorbelegung (Teil 4).\n")
    f.write(f"-- Setzt exakt die {len(vorbelegt_ids)} vorbelegten Items wieder auf curriculum_grade = NULL.\n")
    f.write("BEGIN;\n\nUPDATE tasks SET curriculum_grade = NULL\nWHERE id IN (\n  ")
    f.write(ids_list)
    f.write("\n);\n\nCOMMIT;\n")

with open("data/stoffanker-apply.sql", "w") as f:
    f.write("-- C10 Voll-Audit Teil 4: EINE Transaktion, setzt curriculum_grade NUR fuer\n")
    f.write("-- Items mit Konfidenz 'sicher' UND status='draft' UND curriculum_grade IS NULL.\n")
    f.write(f"-- {len(vorbelegt_ids)} Items. Guard-Bedingungen zusaetzlich im WHERE (idempotent/sicher).\n")
    f.write("BEGIN;\n\nUPDATE tasks AS t\n   SET curriculum_grade = v.grade\n  FROM (VALUES\n  ")
    f.write(values)
    f.write("\n) AS v(id, grade)\n WHERE t.id = v.id\n   AND t.status = 'draft'\n"
            "   AND t.curriculum_grade IS NULL;\n\nCOMMIT;\n")

print("audit-bilder.csv rows:", len(http))
print("audit-2026-07.csv rows:", len(rows_out))
print("vorbelegt (Teil-4 Kandidaten):", len(vorbelegt_ids))
print("OK — Berichte geschrieben (MD folgt separat).")
