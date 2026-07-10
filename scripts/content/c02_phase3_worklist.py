"""C02 Phase 3 - Arbeitsliste fuer die Vision-Transkription.

Betroffen sind die .docx-Items, deren Aufgabenstamm nicht als EMF-Text vorliegt,
sondern nur als Rastergrafik. Sie sind die einzigen, fuer die transkribiert
werden muss - fuer die uebrigen 188 ist die Datei selbst schon die Quelle.
"""
import json
import os

MANIFEST = json.load(open("data/vera8_assets_manifest.json"))
STEMS = json.load(open("data/c02_stems.json"))
OUT = "data/c02_phase3_worklist.json"

work = []
for slug, eintrag in sorted(MANIFEST.items()):
    if STEMS.get(slug, {}).get("teile"):
        continue  # Stamm liegt bereits woertlich vor
    bilder = [os.path.join("data", m["pfad"]) for m in eintrag["medien"]
              if m["typ"] == "raster"]
    if not bilder:
        continue
    work.append({
        "slug": slug,
        "titel": eintrag["titel"],
        "bilder": bilder,
        "fremde_medien": [f["pfad"] for f in eintrag.get("fremde_medien", [])],
    })

json.dump(work, open(OUT, "w"), ensure_ascii=False, indent=1)
print("Items zu transkribieren: %d" % len(work))
print("Bilder gesamt          : %d" % sum(len(w["bilder"]) for w in work))
for w in work:
    warn = "  << fremdes Medium" if w["fremde_medien"] else ""
    print("  %-30s %d Bilder%s" % (w["slug"][:30], len(w["bilder"]), warn))
print("\n-> %s" % OUT)
