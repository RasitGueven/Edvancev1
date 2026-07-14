"""R01 — Stufe 1 (STRUKTUR) + Stufe 2 (SEHEN, Teil 1) fuer ALLE Items.

Die Kalibrierung lief ueber fuenf fest verdrahtete Items (extract.py). Dieser
Treiber macht dasselbe fuer den ganzen Bestand — und schliesst dabei die Luecke,
die der Altbestand offen gelassen hat:

  .docx (224 Items) -> EMFs aus dem ZIP           (render.emfs_in_docx)
  .doc   (74 Items) -> EMFs aus dem OLE-Container (ole.emfs_in_doc)

Die 74 .doc-Items stehen im Altbestand auf 'doc_pending' — sie wurden nie
extrahiert. Ihr Aufgabentext steckt in denselben EMF-Vektorgrafiken wie bei den
.docx, nur eine Schicht tiefer verpackt.

Diese Datei interpretiert nichts. Sie sammelt Belege:
  - was deterministisch in den DOCX steht (Auswertung: Loesungen als Tabelle,
    Kommentierung: AFB + Kompetenzen als Tabelle),
  - was im EMF steht (Zeichenvorrat + Lage + rekonstruierte Tabellen),
  - welche Bilder an die Vision gehen.

Die Auslegung passiert in Stufe 2 (Vision) und wird von ground.py gegen genau
diese Belege geprueft.

    python3 pipeline.py            # alle Items
    python3 pipeline.py zeitangabe # einzeln
"""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import re

import layout
import table as tbl
import c02_docparse
import c02_kommentierung
from emf import parse, tokens
from ole import media_in_doc
from render import media_in_docx, render_emf

ROOT = Path(__file__).resolve().parents[3]
DOCS = ROOT / "data/vera8_docs"
OUT = ROOT / "data/r01_extract"
RENDER = ROOT / "data/r01_render"

# Der CC-Lizenzblock ist ein eigenes EMF am Fuss der Seite. Er gehoert nicht zum
# Aufgabentext — und sein Zeichenvorrat darf auch nicht als Beleg dafuer
# herhalten (sonst borgt sich eine erfundene Lesung ihre Buchstaben aus der
# Lizenzzeile). Die Erkennung muss eng sein: "Grafik: © IQB" steht als
# Bildunterschrift MITTEN im Aufgaben-EMF — wer danach sucht, wirft den Stamm weg.
LICENSE = re.compile(r"creativecommons|creative commons|licenses/by|\(cc by\)|copyright",
                     re.I)


def _sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()[:16]


def _is_license(text):
    return bool(LICENSE.search(text or ""))


def source_files(item):
    """Die drei Quelldateien — .docx bevorzugt, .doc als Fallback."""
    d = DOCS / item
    out = {}
    for kind in ("Aufgabe", "Auswertung", "Didaktische_Kommentierung"):
        for ext in (".docx", ".doc"):
            p = d / f"{item}_{kind}{ext}"
            if p.exists():
                out[kind] = p
                break
    return out


def media_of(path):
    return media_in_doc(path) if path.suffix == ".doc" else media_in_docx(path)


def aufgabe_struct(item, path):
    """Jedes Bild sichern: Vektor mit Zeichenvorrat, Raster ohne.

    Der Unterschied ist keine Formalie. Ein EMF traegt seinen Text als Records —
    daran laesst sich jede Lesung pruefen (G1). Ein PNG traegt Pixel: die Vision
    kann es lesen, aber es gibt nichts, woran sich das Gelesene messen liesse.
    Solche Items werden deshalb ausdruecklich als 'raster' markiert und im
    Grounding als unbelegbar gefuehrt, statt sie als geprueft auszugeben.
    """
    out = []
    for i, (name, ext, data) in enumerate(media_of(path)):
        rec = {"idx": i, "emf": name, "ext": ext}
        if ext == "emf":
            try:
                p = parse(data)
            except Exception as e:
                rec["fehler"] = f"EMF nicht lesbar: {e}"
                out.append(rec)
                continue
            png = RENDER / item / f"{i:02d}_{name}.png"
            try:
                render_emf(data, png)
            except Exception:
                png = None
            tok = tokens(p)
            rec.update({
                "quelle": "vektor",
                "png": str(png.relative_to(ROOT)) if png else None,
                # Zeichenvorrat = Grundwahrheit fuers Grounding: die Vision darf
                # die Reihenfolge bestimmen, aber keine Zeichen erfinden.
                "tokens": tok,
                "deterministic_text": layout.text(p["texts"]),
                "table": tbl.extract(p),
                "n_fragments": len(p["texts"]),
                "is_license": _is_license(tok),
            })
        elif ext in ("png", "jpeg", "jpg"):
            png = RENDER / item / f"{i:02d}_{name}"
            png.parent.mkdir(parents=True, exist_ok=True)
            png.write_bytes(data)
            rec.update({
                "quelle": "raster",
                "png": str(png.relative_to(ROOT)),
                "tokens": "",            # Pixel tragen keinen Zeichenvorrat
                "deterministic_text": "",
                "table": None,
                "n_fragments": 0,
                "is_license": False,
            })
        else:                            # WMF/DIB/GIF: nicht rasterisierbar
            rec.update({"quelle": ext, "png": None, "tokens": "",
                        "deterministic_text": "", "table": None,
                        "n_fragments": 0, "is_license": False,
                        "fehler": f"Format {ext} wird nicht gerendert"})
        out.append(rec)
    return out


def auswertung_struct(path):
    """Bloecke in Dokumentreihenfolge — 'Teilaufgabe N' trennt die Tabellen."""
    blocks = c02_docparse.blocks(str(path))
    return {
        "paragraphs": [b for k, b in blocks if k == "para"],
        "tables": [{"cells": b} for k, b in blocks if k == "table"],
        "blocks": [{"kind": k, "payload": b} for k, b in blocks],
    }


def lizenz(emfs):
    """Der im Item eingebettete Lizenzhinweis — woertlich, und was er deckt.

    Die IQB-Zeile nennt ausdruecklich, WAS unter CC BY steht:
        "Copyright Text und Teilaufgaben: IQB e. V., Lizenz: Creative Commons ..."
        "Copyright Text, Grafik und Teilaufgaben: IQB e. V., ..."
    Nur die zweite Variante deckt die Grafik. Fehlt das Wort 'Grafik', ist die
    Abbildung NICHT lizenziert — unabhaengig davon, was ein pauschales Feld in
    irgendeiner JSON behauptet. Fehlt der Hinweis ganz, ist erst recht nichts
    gedeckt: dann wird nichts angenommen, sondern geflaggt.
    """
    hinweise = [e["tokens"].strip() for e in emfs if e.get("is_license")]
    if not hinweise:
        return {"hinweis": None, "grafik_gedeckt": False,
                "begruendung": "kein Lizenzhinweis im Item gefunden"}
    text = " ".join(hinweise)
    deckt = "grafik" in text.lower()
    return {
        "hinweis": text,
        "grafik_gedeckt": deckt,
        "begruendung": ("Lizenzzeile nennt 'Grafik' -> Abbildung von CC BY gedeckt"
                        if deckt else
                        "Lizenzzeile nennt NUR Text/Teilaufgaben, keine 'Grafik' "
                        "-> Abbildung NICHT von CC BY gedeckt"),
    }


def run(item):
    src = source_files(item)
    rec = {
        "item": item,
        "sources": {k: {"file": p.name, "format": p.suffix.lstrip("."),
                        "sha256_16": _sha(p)} for k, p in src.items()},
        "flags": [],
    }
    if "Aufgabe" not in src:
        rec["flags"].append("keine Aufgaben-Datei")
        rec["stufe2_aufgabe_emf"] = []
    else:
        rec["stufe2_aufgabe_emf"] = aufgabe_struct(item, src["Aufgabe"])
        if not rec["stufe2_aufgabe_emf"]:
            rec["flags"].append("keine Bilder in der Aufgabe gefunden")

    emfs = rec["stufe2_aufgabe_emf"]
    rec["lizenz"] = lizenz(emfs)
    inhalt = [e for e in emfs if not e.get("is_license") and not e.get("fehler")]
    if inhalt and all(e.get("quelle") == "raster" for e in inhalt):
        rec["flags"].append("Aufgabentext nur als Rasterbild (kein Zeichenvorrat) "
                            "-> G1 nicht anwendbar, Stamm bleibt ungeprueft")
    if not inhalt:
        rec["flags"].append("kein Inhaltsbild -> kein Stamm extrahierbar")

    rec["stufe1_auswertung"] = (auswertung_struct(src["Auswertung"])
                               if "Auswertung" in src
                               else {"paragraphs": [], "tables": [], "blocks": []})
    if not rec["stufe1_auswertung"]["tables"]:
        rec["flags"].append("keine Auswertungstabelle -> keine Loesung belegbar")

    if "Didaktische_Kommentierung" in src:
        try:
            rec["stufe1_kommentierung"] = c02_kommentierung.parse(
                str(src["Didaktische_Kommentierung"]))
        except Exception as e:
            rec["stufe1_kommentierung"] = None
            rec["flags"].append(f"Kommentierung nicht lesbar: {e}")
    else:
        rec["stufe1_kommentierung"] = None
        rec["flags"].append("keine Didaktische Kommentierung -> AFB/Kompetenzen fehlen")

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{item}.json").write_text(
        json.dumps(rec, ensure_ascii=False, indent=2), encoding="utf-8")
    return rec


def main(argv):
    items = argv[1:] or sorted(d.name for d in DOCS.iterdir() if d.is_dir())
    n_emf = n_tbl = n_flag = 0
    for it in items:
        rec = run(it)
        emfs = [e for e in rec["stufe2_aufgabe_emf"] if not e.get("fehler")]
        inhalt = [e for e in emfs if not e["is_license"]]
        n_emf += len(emfs)
        n_tbl += sum(1 for e in emfs if e.get("table"))
        n_flag += len(rec["flags"])
        print(f"{it:32s} fmt={rec['sources'].get('Aufgabe', {}).get('format', '-'):4s} "
              f"EMF={len(emfs):2d} (Inhalt {len(inhalt)}) "
              f"Tab={sum(1 for e in emfs if e.get('table'))} "
              f"Ausw-Tab={len(rec['stufe1_auswertung']['tables'])} "
              f"{'FLAGS: ' + '; '.join(rec['flags']) if rec['flags'] else ''}")
    print(f"\n{len(items)} Items · {n_emf} EMFs · {n_tbl} Tabellen · {n_flag} Flags")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
