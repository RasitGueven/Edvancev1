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
import re
import subprocess
import sys
from pathlib import Path

import pytest

WURZEL = Path(__file__).resolve().parents[2]

PARAMS = {
    "koordinatensystem": {"x_min": -4, "x_max": 4, "y_min": -4, "y_max": 4,
                          "punkte": [{"x": -3, "y": 2, "label": "A"}]},
    "winkel": {"grad": 40},
    "thales": {"form": "kreis", "c_grad": 70, "wahre_lage_grad": 56,
               "winkel": [{"ecke": "A", "schenkel": ["B", "C"], "text": "α = 28°"}]},
    "rechtecke": {"rechtecke": [{"x": 0, "y": 0, "b": 4, "h": 2, "stil": "kontur"}],
                  "masse": [{"von": [0, 0], "bis": [4, 0], "text": "x cm", "seite": "unten"}]},
    "rechteck": {"laenge_text": "x cm", "breite_text": "5 cm", "verhaeltnis": 2},
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


@pytest.mark.parametrize("name", ["thales", "rechtecke", "rechteck"])
def test_welle1_generatoren_laden_als_paket(name):
    r = _lauf(name)
    assert r.returncode == 0, r.stderr
    assert r.stdout.strip() == "ok"


def test_positivliste_gleich_dem_check_in_der_migration():
    # Die Migration, die den CHECK zuletzt setzt, muss dieselben Namen tragen.
    migrationen = sorted((WURZEL / "supabase" / "migrations").glob("*.sql"))
    letzte = [m for m in migrationen if "task_figures_generator_check" in m.read_text(encoding="utf-8")][-1]
    im_check = set(re.findall(r"'([a-z_]+)'", letzte.read_text(encoding="utf-8").split("task_figures_generator_check")[-1]))
    code = "import sys; sys.path.insert(0, 'scripts/figures'); import upload_figures as u; print(' '.join(u.GENERATOREN))"
    r = subprocess.run([sys.executable, "-c", code], cwd=WURZEL, capture_output=True, text=True)
    assert set(r.stdout.split()) == im_check, (letzte.name, im_check)


def test_unbekannter_generator_bricht_ab():
    code = ("import sys; sys.path.insert(0, 'scripts/figures'); "
            "import upload_figures as u; u._lade_generator('phantasie')")
    r = subprocess.run([sys.executable, "-c", code], cwd=WURZEL,
                       capture_output=True, text=True)
    assert r.returncode != 0
    assert "Unbekannter Generator" in r.stderr


def test_dateiname_fuer_optionen_der_graph_auswahl():
    # Reihe 1 A3: format_kindersicht erwartet generiert/<task>/option-<id>-<theme>.svg
    code = ("import sys; sys.path.insert(0, 'scripts/figures'); import upload_figures as u; "
            "print(u.dateiname({'task_id': 't', 'generator': 'parabel', 'option_id': 'b'}, 'hell'), "
            "u.dateiname({'task_id': 't', 'generator': 'parabel', 'option_id': None}, 'dunkel'))")
    r = subprocess.run([sys.executable, "-c", code], cwd=WURZEL, capture_output=True, text=True)
    assert r.stdout.split() == ["generiert/t/option-b-hell.svg", "generiert/t/parabel-dunkel.svg"], r.stderr
