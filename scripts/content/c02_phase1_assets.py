"""C02 Phase 1 - Medien aus den .docx extrahieren + Aufgabentext aus EMF gewinnen.

Erkenntnis aus der Sonde: Die IQB-.docx betten den Aufgabenstamm als EMF ein.
EMF ist Vektor, kein Pixel - der Text steckt als EMR_EXTTEXTOUTW-Record drin und
ist damit *woertlich* auslesbar. Kein OCR, kein Raten.

Pro Medium wird klassifiziert:
  logo            - das in allen 222 Dateien identische IQB-Logo
  license         - EMF, die nur den CC-Lizenzblock rendert
  emf_text        - EMF mit Aufgabentext -> Quelle fuer aufgabe_text
  emf_graphic     - EMF ohne Text (Diagramm/Zeichnung) -> nicht renderbar
  raster          - PNG/JPEG -> als Asset abgelegt, Vision-Transkription moeglich

Output:
  data/vera8_assets/<slug>/...           Binaries (gitignored)
  data/vera8_assets_manifest.json        Item -> Medien -> sha256 (committet)
  data/c02_stems.json                    Item -> EMF-Rohtext je Medium
"""
import hashlib
import json
import os
import re
import shutil
import sys
import zipfile

sys.path.insert(0, os.path.dirname(__file__))
from emf_text import emf_to_text, is_license_emf, is_pure_graphic  # noqa: E402
from vera_lib import ASSETS_DIR, MANIFEST, files_of, load_items, slug_of  # noqa: E402

STEMS = "data/c02_stems.json"
LOGO_MD5 = "5ff00bff1e0d7d18ec2d0dbc0b8ee0e1"  # wird beim ersten Lauf verifiziert
RASTER_EXT = (".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff")

A_NS = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
R_NS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"
V_NS = "{urn:schemas-microsoft-com:vml}"


def natural_key(name):
    return [int(p) if p.isdigit() else p for p in re.split(r"(\d+)", name)]


def media_in_document_order(path):
    """Medien-Namen in Lese-Reihenfolge des Dokuments.

    Wichtig, weil image1/image2/... die Teilaufgaben-Reihenfolge tragen und eine
    lexikalische Sortierung 'image10' vor 'image2' einordnen wuerde.
    """
    try:
        import docx
        doc = docx.Document(path)
        rels = doc.part.rels
        order, seen = [], set()
        for el in doc.element.body.iter():
            rid = None
            if el.tag == A_NS + "blip":
                rid = el.get(R_NS + "embed")
            elif el.tag == V_NS + "imagedata":
                rid = el.get(R_NS + "id")
            if rid and rid in rels and rid not in seen:
                seen.add(rid)
                name = str(rels[rid].target_partname).lstrip("/")
                order.append(name)
        return order
    except Exception:
        return []


def classify(name, data, logo_md5):
    if hashlib.md5(data).hexdigest() == logo_md5:
        return "logo", ""
    if name.lower().endswith(".emf"):
        if is_pure_graphic(data):
            return "emf_graphic", ""
        if is_license_emf(data):
            return "license", ""
        return "emf_text", emf_to_text(data)
    if name.lower().endswith(RASTER_EXT):
        return "raster", ""
    return "other", ""


def detect_logo_md5(items):
    """Das Logo ist das Medium, das in fast allen Aufgaben-Dateien byteidentisch ist."""
    counts = {}
    for item in items:
        path = files_of(item)["aufgabe"]
        if not path or not path.endswith(".docx"):
            continue
        with zipfile.ZipFile(path) as zf:
            for n in zf.namelist():
                if n.startswith("word/media/"):
                    counts[hashlib.md5(zf.read(n)).hexdigest()] = \
                        counts.get(hashlib.md5(zf.read(n)).hexdigest(), 0) + 1
    md5, n = max(counts.items(), key=lambda kv: kv[1])
    return (md5, n) if n > 100 else (None, 0)


def main():
    items = load_items()
    logo_md5, logo_n = detect_logo_md5(items)
    print("Logo erkannt: md5=%s in %d Dateien" % (logo_md5, logo_n))

    if os.path.isdir(ASSETS_DIR):
        shutil.rmtree(ASSETS_DIR)

    manifest, stems, stats = {}, {}, {}
    for item in items:
        path = files_of(item)["aufgabe"]
        slug = slug_of(item)
        if not path:
            stats["keine_datei"] = stats.get("keine_datei", 0) + 1
            continue
        if not path.endswith(".docx"):
            kind = "ggb" if path.endswith(".ggb") else "doc"
            stats[kind] = stats.get(kind, 0) + 1
            continue

        with zipfile.ZipFile(path) as zf:
            names = media_in_document_order(path)
            present = [n for n in zf.namelist() if n.startswith("word/media/")]
            if sorted(names) != sorted(present):
                names = sorted(present, key=natural_key)  # Fallback
            entries, texts = [], []
            out_dir = os.path.join(ASSETS_DIR, slug)
            for idx, name in enumerate(names, 1):
                data = zf.read(name)
                kind, text = classify(name, data, logo_md5)
                if kind == "logo":
                    continue
                ext = os.path.splitext(name)[1].lower()
                dest = os.path.join(out_dir, "aufgabe_%02d%s" % (idx, ext))
                os.makedirs(out_dir, exist_ok=True)
                with open(dest, "wb") as fh:
                    fh.write(data)
                entries.append({
                    "pfad": os.path.relpath(dest, "data"),
                    "quelle": name,
                    "typ": kind,
                    "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(),
                })
                if kind == "emf_text" and text:
                    texts.append({"medium": os.path.basename(dest), "text": text})
                stats[kind] = stats.get(kind, 0) + 1

        manifest[slug] = {"titel": item["titel"], "quelle_datei": os.path.basename(path),
                          "medien": entries}
        stems[slug] = {"titel": item["titel"], "teile": texts}

    json.dump(manifest, open(MANIFEST, "w"), ensure_ascii=False, indent=1)
    json.dump(stems, open(STEMS, "w"), ensure_ascii=False, indent=1)

    print("\nMedien-Klassifikation:")
    for k, v in sorted(stats.items(), key=lambda kv: -kv[1]):
        print("  %-14s %4d" % (k, v))

    mit_text = [s for s, v in stems.items() if v["teile"]]
    ohne_text = [s for s, v in stems.items() if not v["teile"]]
    grafik = [s for s, v in manifest.items()
              if any(m["typ"] in ("emf_graphic", "raster") for m in v["medien"])]
    print("\n.docx-Items                       : %d" % len(stems))
    print("  mit EMF-Aufgabentext            : %d" % len(mit_text))
    print("  ohne jeden EMF-Text             : %d" % len(ohne_text))
    print("  mit Grafik (Diagramm/Raster)    : %d" % len(grafik))
    print("\n-> %s\n-> %s" % (MANIFEST, STEMS))


if __name__ == "__main__":
    main()
