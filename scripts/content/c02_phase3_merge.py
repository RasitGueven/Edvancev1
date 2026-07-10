"""C02 Phase 3 - Transkripte in den Pool schreiben.

Quelle des Aufgabenstamms ist hier das Bild. Es wird als solches vermerkt
(`methode: vision_transkription`), damit im Review Bild und Text
nebeneinandergelegt werden koennen - anders als bei den 188 Items, deren Text
woertlich aus der Datei stammt.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from vera_lib import files_of, load_items, save_items, slug_of  # noqa: E402

DIR = "data/c02_transcripts"


def main():
    items = load_items()
    manifest = json.load(open("data/vera8_assets_manifest.json"))
    n_stamm, n_bild, n_problem = 0, 0, 0

    for item in items:
        slug = slug_of(item)
        path = os.path.join(DIR, "%s.json" % slug)
        if not os.path.exists(path):
            continue
        data = json.load(open(path))
        teile = [t for t in data["teile"] if (t.get("text") or "").strip()]
        problems = set(item.get("_problems") or [])
        problems.discard("kein_stamm_extrahierbar")

        if teile:
            item["aufgabe_text"] = "\n\n".join(t["text"] for t in teile)
            item["aufgabe_teile"] = [t["text"] for t in teile]
            item["_grounding"] = item.get("_grounding") or {}
            item["_grounding"]["aufgabe_text"] = {
                "quelle": os.path.basename(files_of(item)["aufgabe"]),
                "methode": "vision_transkription",
                "bilder": [t["bild"] for t in data["teile"]],
                "zitat": item["aufgabe_text"][:200],
            }
            n_stamm += 1
        else:
            problems.add("kein_stamm_extrahierbar")

        if any(t.get("benoetigt_bild") for t in data["teile"]):
            item["benoetigt_bild"] = True
            n_bild += 1

        item["bild_pfade"] = [m["pfad"] for m in manifest[slug]["medien"]
                              if m["typ"] == "raster"]
        for problem in data.get("_problems") or []:
            problems.add(problem)
            n_problem += 1
        item["_problems"] = sorted(problems)

    # Diagramm-EMFs sind nicht renderbar: auch diese Items brauchen ihr Bild.
    for item in items:
        slug = slug_of(item)
        eintrag = manifest.get(slug)
        if not eintrag:
            continue
        if any(m["typ"] == "emf_graphic" for m in eintrag["medien"]):
            item["benoetigt_bild"] = True
            item["_problems"] = sorted(set(item.get("_problems") or [])
                                       | {"grafik_als_emf_nicht_renderbar"})

    save_items(items)
    print("Transkripte eingearbeitet : %d" % n_stamm)
    print("davon benoetigt_bild      : %d" % n_bild)
    print("uebernommene _problems    : %d" % n_problem)
    print("Items mit Stamm gesamt    : %d" % sum(1 for i in items if i.get("aufgabe_text")))


if __name__ == "__main__":
    main()
