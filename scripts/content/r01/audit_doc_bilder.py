"""R01 — Audit: die .doc-Extraktion verliert Bilder.

BEFUND (aus dem Vision-Nachlauf): Bei rund 50 Items liest die Vision-Stufe nur
den Stamm und findet keine einzige Teilaufgabe — obwohl die Auswertung 2 bis 5
erwartet. Elf unabhaengige Leser haben denselben Verdacht gemeldet: "nur EIN
gerendertes Bild, darin nur der Stamm".

Der Verdacht stimmt, aber die Ursache liegt frueher als vermutet. Es ist kein
Render-Problem, sondern ein EXTRAKTIONS-Problem:

Ein VERA8-.doc legt JEDE Teilaufgabe als EIGENES eingebettetes Bild ab:

    $ antiword temperaturen_Aufgabe.doc
    Temperaturen in Frankfurt am Main
    [pic]                 <- Stamm
    Teilaufgabe 1
    [pic]                 <- die Frage
    Teilaufgabe 2
    [pic]
    Teilaufgabe 3
    [pic][pic]

ole.media_in_doc() holt aus diesem Container aber nur EIN Bild. Die Fragen
bleiben in der Datei liegen. Die Vision-Stufe konnte sie nie sehen — sie hat
voellig korrekt gemeldet, dass im Bild keine Frage steht.

Dieses Skript misst den Schaden: es zaehlt die [pic]-Marken im Dokument gegen
die tatsaechlich extrahierten Medien.

    python3 audit_doc_bilder.py     ->  data/r01_doc_bildverlust.json
"""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ole import media_in_doc

ROOT = Path(__file__).resolve().parents[3]
DOCS = ROOT / "data/vera8_docs"
OUT = ROOT / "data/r01_doc_bildverlust.json"


def main():
    if not DOCS.is_dir():
        print(f"{DOCS} fehlt (data/vera8_docs/ ist gitignored) — Audit uebersprungen")
        return 0

    betroffen, geprueft = [], 0
    for d in sorted(p.name for p in DOCS.iterdir() if p.is_dir()):
        doc = DOCS / d / f"{d}_Aufgabe.doc"
        if not doc.exists():
            continue
        geprueft += 1
        try:
            txt = subprocess.run(["antiword", str(doc)], capture_output=True,
                                 text=True, timeout=30).stdout
        except (OSError, subprocess.SubprocessError):
            continue
        im_dokument = txt.count("[pic]")
        extrahiert = len(media_in_doc(doc))
        if im_dokument > extrahiert:
            betroffen.append({
                "item": d,
                "bilder_im_dokument": im_dokument,
                "bilder_extrahiert": extrahiert,
                "verloren": im_dokument - extrahiert,
            })

    verloren = sum(b["verloren"] for b in betroffen)
    ergebnis = {
        "befund": "ole.media_in_doc() extrahiert pro .doc nur EIN Bild. VERA8 "
                  "legt jede Teilaufgabe als eigenes eingebettetes Bild ab — die "
                  "Fragen bleiben in der Datei liegen und erreichen die "
                  "Vision-Stufe nie.",
        "doc_items_geprueft": geprueft,
        "doc_items_mit_verlust": len(betroffen),
        "bilder_verloren": verloren,
        "items": betroffen,
    }
    OUT.write_text(json.dumps(ergebnis, ensure_ascii=False, indent=1) + "\n",
                   encoding="utf-8")
    print(f".doc-Items geprueft:      {geprueft}")
    print(f"davon mit Bildverlust:   {len(betroffen)}")
    print(f"verlorene Bilder gesamt: {verloren}")
    print(f"-> {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
