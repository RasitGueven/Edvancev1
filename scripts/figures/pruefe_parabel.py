#!/usr/bin/env python3
"""
Pruefungen fuer den Parabel-Generator — IMPORTIERBAR (upload_figures.py ruft `pruefe(svg, params)`).

Misst das gezeichnete SVG zurueck, nie die Eingabe gegen sich selbst:
  - alle Pruefungen des Koordinatensystems (Skalierung, Achsenkreuz, Bogen, Punkte, Gitter, Beschriftung frei)
  - pruefe_scheitel: der Bogen hat sein Extremum am Pixelort von (d | e) — oben bei a < 0, unten bei a > 0
  - pruefe_nullstellen: jede reelle Nullstelle im Fenster liegt auf dem Bogen und auf der x-Achse; ohne reelle
    Nullstelle beruehrt der Bogen die x-Achse nicht
  - pruefe_achsenbeschriftung: die Achsen tragen ihre Namen (Standard x und y)
"""

from __future__ import annotations

import math
import re

from .parabel import koordinaten_params, normalform, nullstellen
from .pruefe_koordinatensystem import EPS_PARABEL, Abbild, _dist_zu_zug, _polylinien, pruefe_geometrie as _geometrie


def _bogen(svg: str, params: dict) -> tuple[Abbild, list[tuple[float, float]]]:
    ab = Abbild(svg, params['x_min'], params['x_max'], params['y_min'], params['y_max'])
    zuege = [z for z in _polylinien(svg) if len(z) >= 2]
    # Der Bogen ist der laengste Zug (die Gerade y = c hat zwei Punkte).
    return ab, max(zuege, key=len) if zuege else []


def pruefe_scheitel(svg: str, params: dict) -> list[str]:
    a, d, e = params['a'], params['d'], params['e']
    if not (params['x_min'] <= d <= params['x_max'] and params['y_min'] <= e <= params['y_max']):
        return []  # Scheitel ausserhalb des Fensters: nichts zu messen
    ab, bogen = _bogen(svg, params)
    if not bogen:
        return ['scheitel: kein Bogen gefunden.']
    soll = (ab.px(d), ab.py(e))
    befunde = []
    abstand = _dist_zu_zug(soll, bogen)
    if abstand > EPS_PARABEL:
        befunde.append(f'scheitel: S({d}|{e}) liegt {abstand:.2f} px neben dem Bogen.')
    # SVG-y waechst nach unten: a > 0 → Tiefpunkt = groesstes Pixel-y.
    extrem = max(bogen, key=lambda p: p[1]) if a > 0 else min(bogen, key=lambda p: p[1])
    if math.hypot(extrem[0] - soll[0], extrem[1] - soll[1]) > 2 * EPS_PARABEL + 1:
        befunde.append(f'scheitel: das Extremum des Bogens liegt bei ({extrem[0]:.1f}, {extrem[1]:.1f}) statt '
                       f'({soll[0]:.1f}, {soll[1]:.1f}).')
    return befunde


def pruefe_nullstellen(svg: str, params: dict) -> list[str]:
    a, d, e = params['a'], params['d'], params['e']
    ab, bogen = _bogen(svg, params)
    if not bogen or not (params['y_min'] <= 0 <= params['y_max']):
        return []
    achse_y = ab.py(0)
    befunde = []
    stellen = [x for x in nullstellen(a, d, e) if params['x_min'] <= x <= params['x_max']]
    for x in stellen:
        abstand = _dist_zu_zug((ab.px(x), achse_y), bogen)
        if abstand > EPS_PARABEL:
            befunde.append(f'nullstellen: x = {x:.2f} liegt {abstand:.2f} px neben dem Bogen.')
    if not nullstellen(a, d, e):
        seiten = {math.copysign(1, p[1] - achse_y) for p in bogen if abs(p[1] - achse_y) > EPS_PARABEL}
        if len(seiten) > 1:
            befunde.append('nullstellen: der Bogen kreuzt die x-Achse, obwohl es keine reelle Nullstelle gibt.')
    return befunde


def pruefe_achsenbeschriftung(svg: str, params: dict) -> list[str]:
    achsen = params.get('achsen') or {'x': 'x', 'y': 'y'}
    befunde = []
    for name in ('x', 'y'):
        titel = achsen.get(name, name)
        if titel and not re.search(r'>\s*' + re.escape(titel) + r'\s*</text>', svg):
            befunde.append(f'achsen: Beschriftung {titel!r} fehlt.')
    return befunde


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    befunde = _geometrie(svg, koordinaten_params(params))
    for pruefung in (pruefe_scheitel, pruefe_nullstellen, pruefe_achsenbeschriftung):
        befunde.extend(pruefung(svg, params))
    return befunde


def pruefe(svg: str, params: dict) -> tuple[bool, str]:
    befunde = pruefe_geometrie(svg, params)
    return (False, ' | '.join(befunde)) if befunde else (True, 'ok')


def negativkontrolle() -> list[tuple[str, bool, list[str]]]:
    """Korrekte SVGs, absichtlich falsch beschrieben bzw. veraendert — jede Pruefung muss anschlagen."""
    from .parabel import zeichne

    basis = dict(a=1, d=2, e=-4, x_min=-3, x_max=6, y_min=-5, y_max=6)
    svg = zeichne(basis, 'dunkel')
    faelle = [
        ('Scheitel verschoben (Text sagt d = 3, Bild zeigt d = 2)', svg, {**basis, 'd': 3}),
        ('Nullstellen falsch (Text sagt e = −1)', svg, {**basis, 'e': -1}),
        ('keine Nullstelle behauptet, Bild hat zwei', svg, {**basis, 'e': 4}),
        ('Achsenbeschriftung x fehlt', re.sub(r'>\s*x\s*</text>', '></text>', svg), basis),
        ('Oeffnung falsch (Text sagt a = −1)', svg, {**basis, 'a': -1}),
    ]
    return [(name, bool(b := pruefe_geometrie(s, p)), b) for name, s, p in faelle]


def _main() -> int:
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    gut = True
    for name, angeschlagen, befunde in negativkontrolle():
        print(f"[{'ANGESCHLAGEN' if angeschlagen else 'STILL GEBLIEBEN (!!)'}] {name}")
        for b in befunde[:3]:
            print(f'    -> {b}')
        gut = gut and angeschlagen
    return 0 if gut else 1


if __name__ == '__main__':
    raise SystemExit(_main())


__all__ = ['pruefe', 'pruefe_geometrie', 'pruefe_scheitel', 'pruefe_nullstellen', 'pruefe_achsenbeschriftung',
           'negativkontrolle', 'normalform']
