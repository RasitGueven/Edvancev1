"""C02 Phase 3 - strukturelle Pruefung der Transkripte.

Prueft, was sich ohne Augenschein pruefen laesst: Vollstaendigkeit gegenueber
dem Manifest, Schema, leere Texte, verdaechtige Marker. Der inhaltliche
Abgleich Bild<->Text bleibt Sache der Stichprobe.
"""
import json
import os

WORK = json.load(open("data/c02_phase3_worklist.json"))
DIR = "data/c02_transcripts"

fehlend, schema, leer, unleserlich, probleme = [], [], [], [], []
gesamt_teile = 0

for eintrag in WORK:
    slug = eintrag["slug"]
    path = os.path.join(DIR, "%s.json" % slug)
    if not os.path.exists(path):
        fehlend.append(slug)
        continue
    try:
        data = json.load(open(path))
    except json.JSONDecodeError as exc:
        schema.append("%s: %s" % (slug, exc))
        continue

    teile = data.get("teile") or []
    gesamt_teile += len(teile)
    erwartet = len(eintrag["bilder"])
    if len(teile) != erwartet:
        schema.append("%s: %d Teile, aber %d Bilder" % (slug, len(teile), erwartet))
    for teil in teile:
        if not set(teil) >= {"bild", "text", "benoetigt_bild"}:
            schema.append("%s/%s: Felder fehlen" % (slug, teil.get("bild")))
        if not (teil.get("text") or "").strip():
            leer.append("%s/%s" % (slug, teil.get("bild")))
        if "[unleserlich]" in (teil.get("text") or ""):
            unleserlich.append("%s/%s" % (slug, teil.get("bild")))
    if data.get("_problems"):
        probleme.append("%s: %s" % (slug, data["_problems"]))

print("Transkripte erwartet : %d" % len(WORK))
print("Transkripte gefunden : %d" % (len(WORK) - len(fehlend)))
print("Teile gesamt         : %d" % gesamt_teile)
print("\nfehlend      : %s" % (fehlend or "-"))
print("schemafehler : %s" % (schema or "-"))
print("leerer text  : %s" % (leer or "-"))
print("[unleserlich]: %s" % (unleserlich or "-"))
print("\n_problems:")
for row in probleme:
    print("  %s" % row)
