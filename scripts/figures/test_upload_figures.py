#!/usr/bin/env python3
"""
Tests fuer den Generator-Adapter in upload_figures.py — ohne DB, ohne Upload.

    python3 -m pytest scripts/figures/test_upload_figures.py -q

Der Adapter lud koordinatensystem frueher als loses Modul; dessen relative
Imports (from .pruefungen ...) scheiterten dann mit "attempted relative import
with no known parent package". Beide Generatoren muessen ueber DENSELBEN Weg
laden, wie upload_figures sie aufruft — in einem frischen Interpreter, damit
kein Import aus einem anderen Test den Fehler verdeckt.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]

PARAMS = {
    "koordinatensystem": {"x_min": -4, "x_max": 4, "y_min": -4, "y_max": 4,
                          "punkte": [{"x": -3, "y": 2, "label": "A"}]},
    "winkel": {"grad": 40},
}


def _lauf(name: str) -> subprocess.CompletedProcess:
    code = (
        "import sys, json; sys.path.insert(0, 'scripts/figures'); "
        "import upload_figures as u; "
        "zeichne, pruefe = u._lade_generator(sys.argv[1]); "
        "p = json.loads(sys.argv[2]); "
        "ok = all(pruefe(zeichne(p, t), p)[0] for t in u.THEMES); "
        "print('ok' if ok else 'pruefung fehlgeschlagen')"
    )
    return subprocess.run([sys.executable, "-c", code, name, json.dumps(PARAMS[name])],
                          cwd=WURZEL, capture_output=True, text=True)


def test_koordinatensystem_laedt_als_paket():
    r = _lauf("koordinatensystem")
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == "ok"


def test_winkel_laedt_als_paket():
    r = _lauf("winkel")
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == "ok"


def test_unbekannter_generator_bricht_ab():
    code = ("import sys; sys.path.insert(0, 'scripts/figures'); "
            "import upload_figures as u; u._lade_generator('phantasie')")
    r = subprocess.run([sys.executable, "-c", code], cwd=WURZEL,
                       capture_output=True, text=True)
    assert r.returncode != 0
    assert "Unbekannter Generator" in r.stderr
