#!/usr/bin/env python3
"""Laedt die Mathe-Schulplaene aus schulen.json nach cache/ und extrahiert Text.

    python3 scripts/schulplaene/laden.py            # alle Schulen
    python3 scripts/schulplaene/laden.py <slug> ... # nur diese

    python3 scripts/schulplaene/laden.py --plumber <slug> ...  # Text mit pdfplumber

cache/ ist per .gitignore ausgeschlossen: die PDFs gehoeren den Schulen und
werden nicht committet. Aus jedem PDF entsteht cache/<slug>-<n>.txt, dazu
cache/laden.log mit dem Ergebnis je URL. Text per pypdf; zerreisst es die
Tabellen, mit --plumber erneut. Beide liegen in .pylib/ (gitignored):
    pip install --target scripts/schulplaene/.pylib pypdf pdfplumber
"""

import json
import subprocess
import sys
from pathlib import Path

HIER = Path(__file__).resolve().parent
sys.path.insert(0, str(HIER / ".pylib"))
CACHE = HIER / "cache"
UA = "Mozilla/5.0 (X11; Linux x86_64) Edvance-Schulplanrecherche"


def laden(url: str, ziel: Path) -> str:
    r = subprocess.run(
        ["curl", "-sSL", "--max-time", "60", "-A", UA, "-o", str(ziel),
         "-w", "%{http_code} %{content_type}", url],
        capture_output=True, text=True,
    )
    return r.stdout.strip() if r.returncode == 0 else f"curl-fehler {r.returncode}"


def text(pdf: Path, plumber: bool) -> str:
    if plumber:
        import pdfplumber
        with pdfplumber.open(pdf) as d:
            seiten = [p.extract_text(layout=True) or "" for p in d.pages]
    else:
        import pypdf
        seiten = [p.extract_text(extraction_mode="layout") or "" for p in pypdf.PdfReader(pdf).pages]
    return "".join(f"\n===== Seite {i} =====\n{t}" for i, t in enumerate(seiten, start=1))


def main() -> None:
    CACHE.mkdir(exist_ok=True)
    schulen = json.loads((HIER / "schulen.json").read_text())
    args = sys.argv[1:]
    plumber = "--plumber" in args
    nur = {a for a in args if a != "--plumber"}
    log = []
    for s in schulen:
        if nur and s["slug"] not in nur:
            continue
        for n, plan in enumerate(s["plaene"], start=1):
            pdf = CACHE / f"{s['slug']}-{n}.pdf"
            status = laden(plan["url"], pdf)
            ist_pdf = pdf.exists() and pdf.read_bytes()[:5] == b"%PDF-"
            if ist_pdf:
                pdf.with_suffix(".txt").write_text(text(pdf, plumber))
            log.append(f"{s['slug']}-{n}\t{status}\t{'pdf' if ist_pdf else 'KEIN PDF'}\t{plan['url']}")
    (CACHE / "laden.log").write_text("\n".join(log) + "\n")
    print("\n".join(log))


if __name__ == "__main__":
    main()
