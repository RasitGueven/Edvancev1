#!/usr/bin/env python3
"""C11 Wiederaufnahme: nur die noch nicht extrahierten Aufgaben nachziehen.

Vergleicht data/vera8_docs/<slug>/ mit data/vera8_sichtung/<slug>/ und ruft
c11_extract.py ausschliesslich fuer die fehlenden Slugs auf. Bereits fertige
Ordner werden nicht angefasst. Zusaetzlich wird der zuletzt geschriebene Ordner
neu eingelesen, weil er von einem Abbruch halb gefuellt sein kann.
"""
from __future__ import annotations

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "data", "vera8_docs")
DEST = os.path.join(ROOT, "data", "vera8_sichtung")


def unterordner(pfad: str):
    return sorted(d for d in os.listdir(pfad) if os.path.isdir(os.path.join(pfad, d)))


def main() -> None:
    docs = unterordner(SRC)
    fertig = unterordner(DEST)
    offen = [d for d in docs if d not in set(fertig)]

    # Der juengste Ordner kann ein abgebrochener Teilstand sein -> neu einlesen.
    if fertig:
        juengster = max(fertig, key=lambda d: os.path.getmtime(os.path.join(DEST, d)))
        offen.append(juengster)

    print(f"Docs {len(docs)} | fertig {len(fertig)} | offen {len(offen)}", flush=True)
    if not offen:
        print("nichts zu tun")
        return
    subprocess.run([sys.executable, os.path.join(ROOT, "scripts", "c11_extract.py"), *offen])


if __name__ == "__main__":
    main()
