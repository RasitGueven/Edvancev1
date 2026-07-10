"""C02 Phase 0 - Quarantaene + Census.

1. Alle Items auf status='quarantined', alter Status nach 'status_vorher'.
   Fabrizierte Inhaltsfelder werden nach '_fabriziert_backup' verschoben und
   aus den Live-Feldern entfernt - sie duerfen ab jetzt nichts mehr speisen.
2. Census: welche Quelldateien existieren, welches Format, wieviele Bilder.

Output: data/c02_census.json  (+ Konsolenreport)
"""
import json
import os
import sys
import zipfile

sys.path.insert(0, os.path.dirname(__file__))
from vera_lib import convert, files_of, load_items, save_items, slug_of  # noqa: E402

CENSUS = "data/c02_census.json"
REF_ITEM = "data/ref_item.json"

# Inhaltsfelder, die laut RETRO-C01 ueberwiegend KI-fabriziert sind.
FABRIZIERT = ["aufgabe_text", "akzeptierte_antworten", "loesung_pro_ta",
              "kontext", "diagnostik"]

IMG_EXT = (".png", ".jpg", ".jpeg", ".gif", ".bmp", ".emf", ".wmf", ".tiff")


def count_media(path):
    """Anzahl eingebetteter Medien. -1 = nicht ermittelbar (.doc/.ggb)."""
    if path is None or not path.endswith(".docx"):
        return -1
    try:
        with zipfile.ZipFile(path) as zf:
            return sum(1 for n in zf.namelist()
                       if n.startswith("word/media/") and n.lower().endswith(IMG_EXT))
    except Exception:
        return -1


def main():
    items = load_items()
    rows = []

    for item in items:
        item["status_vorher"] = item.get("status")
        item["status"] = "quarantined"

        backup = {}
        for key in FABRIZIERT:
            if key in item:
                backup[key] = item.pop(key)
        item["_fabriziert_backup"] = backup
        item["_grounding"] = {}
        item["_problems"] = ["c02_quarantine_pending_rebuild"]

        paths = files_of(item)
        aufg = paths["aufgabe"]
        fmt = os.path.splitext(aufg)[1].lower() if aufg else None
        rows.append({
            "id": item["id"],
            "titel": item["titel"],
            "slug": slug_of(item),
            "hat_ordner": any(paths.values()),
            "aufgabe_datei": os.path.basename(aufg) if aufg else None,
            "aufgabe_format": fmt,
            "auswertung_datei": os.path.basename(paths["auswertung"]) if paths["auswertung"] else None,
            "kommentierung_datei": os.path.basename(paths["kommentierung"]) if paths["kommentierung"] else None,
            "bilder_in_aufgabe": count_media(aufg),
            "auswertung_konvertierbar": convert(paths["auswertung"]) is not None,
            "kommentierung_konvertierbar": convert(paths["kommentierung"]) is not None,
        })

    save_items(items)
    json.dump(rows, open(CENSUS, "w"), ensure_ascii=False, indent=1)

    if os.path.exists(REF_ITEM):
        os.remove(REF_ITEM)
        print(f"geloescht: {REF_ITEM} (Fabrikations-Vorlage)")

    print(f"\nItems quarantaeniert: {len(items)}")
    fmts = {}
    for r in rows:
        fmts[r["aufgabe_format"]] = fmts.get(r["aufgabe_format"], 0) + 1
    print("Aufgaben-Dateiformat:")
    for fmt, n in sorted(fmts.items(), key=lambda x: -x[1]):
        print(f"  {str(fmt):8s} {n:3d}")
    docx = [r for r in rows if r["aufgabe_format"] == ".docx"]
    print(f"\nBilder in den {len(docx)} .docx-Aufgaben:")
    print(f"  gesamt          : {sum(r['bilder_in_aufgabe'] for r in docx)}")
    print(f"  Items ohne Bild : {sum(1 for r in docx if r['bilder_in_aufgabe'] == 0)}")
    print(f"\nAuswertung konvertierbar   : {sum(1 for r in rows if r['auswertung_konvertierbar'])}/{len(rows)}")
    print(f"Kommentierung konvertierbar: {sum(1 for r in rows if r['kommentierung_konvertierbar'])}/{len(rows)}")
    print(f"Ohne Quellordner           : {sum(1 for r in rows if not r['hat_ordner'])}")
    print(f"\n-> {CENSUS}")


if __name__ == "__main__":
    main()
