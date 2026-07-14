"""Vision-Queue: was Stufe 2 pro Item zu lesen bekommt.

Nur Inhaltsbilder — der Lizenzblock ist kein Aufgabentext. Dazu die Zahl der
Teilaufgaben, wie sie die AUSWERTUNG kennt (RICHTIG-Zellen je 'Teilaufgabe N').
Das ist der Gegencheck: Sieht die Vision eine andere Zahl von Teilaufgaben als
die Auswertung, stimmt eine der beiden Lesungen nicht — und das gehoert gemeldet,
nicht stillschweigend geglaettet.
"""
import collections
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
EXTRACT = ROOT / "data/r01_extract"
OUT = ROOT / "data/r01_vision_queue.json"

TA = re.compile(r"Teilaufgabe\s*(\d+)", re.I)


def richtig_je_teilaufgabe(rec):
    """{TA-Nr: [RICHTIG-Zelle, ...]} — aus der Blockreihenfolge der Auswertung.

    Die Zuordnung Loesung -> Teilaufgabe darf nicht ueber den Index geraten
    werden: 'Teilaufgabe 2' steht als Absatz VOR ihrer Tabelle.
    """
    ta, out = 0, collections.OrderedDict()
    for b in rec["stufe1_auswertung"]["blocks"]:
        if b["kind"] == "para":
            m = TA.search(b["payload"] or "")
            if m:
                ta = int(m.group(1))
        else:
            for row in b["payload"]:
                if row and row[0].strip().upper().startswith("RICHTIG"):
                    out.setdefault(ta or 1, []).append(" | ".join(row[1:]))
    return out


def build():
    q = {}
    for f in sorted(EXTRACT.glob("*.json")):
        rec = json.loads(f.read_text(encoding="utf-8"))
        inhalt = [e for e in rec["stufe2_aufgabe_emf"]
                  if e.get("png") and not e.get("is_license") and not e.get("fehler")]
        if not inhalt:
            continue
        richtig = richtig_je_teilaufgabe(rec)
        q[rec["item"]] = {
            "pngs": [e["png"] for e in inhalt],
            "n_teilaufgaben_laut_auswertung": len(richtig) or None,
            "hat_tabelle_im_emf": any(e.get("table") for e in inhalt),
            "nur_raster": all(e.get("quelle") == "raster" for e in inhalt),
        }
    OUT.write_text(json.dumps(q, ensure_ascii=False, indent=1), encoding="utf-8")
    n_ta = collections.Counter(v["n_teilaufgaben_laut_auswertung"] for v in q.values())
    print(f"Items: {len(q)} · PNGs: {sum(len(v['pngs']) for v in q.values())}")
    print(f"Teilaufgaben laut Auswertung: {dict(sorted(n_ta.items(), key=lambda x: (x[0] is None, x[0])))}")
    print(f"nur Raster: {sum(1 for v in q.values() if v['nur_raster'])}")
    return q


if __name__ == "__main__":
    build()
