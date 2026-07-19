#!/usr/bin/env python3
"""C11 Schritt 1: Bilder aus den VERA8-Aufgaben-Dokumenten extrahieren.

docx = zip; Bilder liegen in word/media/. Aeltere Aufgaben liegen als binaeres
.doc vor — die werden vorher per LibreOffice nach .docx konvertiert (nur um an
die eingebetteten Medien zu kommen; das Original bleibt unangetastet).
EMF/WMF wird per Inkscape nach PNG gerendert, PNG/JPEG direkt uebernommen. Jedes PNG wird per ImageMagick
-trim von den weissen A4-Raendern befreit. Ursprungsnamen bleiben erhalten.

Ziel: data/vera8_sichtung/<slug>/<name>.<ext>
Kein DB-Zugriff, kein Upload, nichts wird geloescht.
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data", "vera8_docs")
DEST = os.path.join(ROOT, "data", "vera8_sichtung")

KEEP = (".png", ".jpg", ".jpeg", ".emf", ".wmf")
VEKTOR = (".emf", ".wmf")


def run(cmd) -> bool:
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode == 0


def trim(png: str) -> None:
    """Weisse Raender wegschneiden. Schlaegt der Trim fehl (z.B. komplett
    weisses Bild), bleibt das Original unangetastet."""
    tmp = png + ".trim.png"
    if run(["magick", png, "-fuzz", "2%", "-trim", "+repage", tmp]):
        if os.path.getsize(tmp) > 0:
            os.replace(tmp, png)
            return
    if os.path.exists(tmp):
        os.remove(tmp)


def doc_zu_docx(doc: str, tmpdir: str):
    """Binaeres .doc per LibreOffice nach .docx. Nur lesend auf dem Original."""
    ok = run(["libreoffice", "--headless", "--convert-to", "docx",
              "--outdir", tmpdir, doc])
    ziel = os.path.join(tmpdir, os.path.basename(doc)[:-4] + ".docx")
    return ziel if ok and os.path.exists(ziel) else None


def main() -> None:
    os.makedirs(DEST, exist_ok=True)
    nur = set(sys.argv[1:])  # optional: nur diese Slugs neu einlesen
    slugs = sorted(d for d in os.listdir(SRC) if os.path.isdir(os.path.join(SRC, d)))
    if nur:
        slugs = [s for s in slugs if s in nur]
    total = emf_ok = emf_fail = 0
    tmpdir = tempfile.mkdtemp(prefix="c11_doc_")

    for i, slug in enumerate(slugs, 1):
        docx = os.path.join(SRC, slug, f"{slug}_Aufgabe.docx")
        if not os.path.exists(docx):
            alt = os.path.join(SRC, slug, f"{slug}_Aufgabe.doc")
            docx = doc_zu_docx(alt, tmpdir) if os.path.exists(alt) else None
            if not docx:
                print(f"[{i}/{len(slugs)}] {slug}: keine lesbare _Aufgabe-Datei",
                      file=sys.stderr)
                continue

        outdir = os.path.join(DEST, slug)
        if os.path.isdir(outdir):
            shutil.rmtree(outdir)
        os.makedirs(outdir)

        with zipfile.ZipFile(docx) as z:
            media = [n for n in z.namelist()
                     if n.startswith("word/media/") and n.lower().endswith(KEEP)]
            for name in sorted(media):
                base = os.path.basename(name)
                raw = os.path.join(outdir, base)
                with open(raw, "wb") as fh:
                    fh.write(z.read(name))
                total += 1

                if base.lower().endswith(VEKTOR):
                    png = raw + ".png"
                    ok = run(["inkscape", raw, "--export-type=png",
                              f"--export-filename={png}"])
                    if ok and os.path.exists(png):
                        emf_ok += 1
                        trim(png)
                        os.remove(raw)  # Zwischenprodukt, PNG ist das Ergebnis
                    else:
                        emf_fail += 1  # EMF bleibt liegen, damit nichts verloren geht
                elif base.lower().endswith(".png"):
                    trim(raw)

        print(f"[{i}/{len(slugs)}] {slug}: {len(media)} Bilder")

    shutil.rmtree(tmpdir, ignore_errors=True)
    print(f"\ngesamt {total} Medien | Vektor gerendert {emf_ok} | "
          f"Vektor fehlgeschlagen {emf_fail}")


if __name__ == "__main__":
    main()
