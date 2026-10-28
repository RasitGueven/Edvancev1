#!/usr/bin/env python3
"""
Parametrischer Generator: Parabel f(x) = a·(x − d)² + e (Sessionreihe 1, Format Graph-Auswahl und Figuren).

WARUM EIN EIGENER GENERATOR: Die Bauformen der Reihe beschreiben Parabeln in der Scheitelpunktform (a, d, e). Das
Koordinatensystem kennt nur die Normalform (a, b, c). Wer umrechnet, kann sich verrechnen — hier passiert es an EINER
Stelle, und pruefe_parabel.py misst das Ergebnis im SVG zurueck (Scheitel, Nullstellen, Achsen).

Gezeichnet wird ueber koordinatensystem.py (gleiche Skalierung, Tokens, Gitter, Clip), also sieht jede Parabel aus wie
jede andere Figur.

params:
  a, d, e        — Streckfaktor (≠ 0), Verschiebung nach rechts, nach oben
  x_min … y_max  — Fenster, ganzzahlig (Pflicht)
  punkte         — optional [{'x', 'y', 'label'?, 'betont'?}] wie im Koordinatensystem
  gerade_c       — optional: waagerechte Gerade y = c (z. B. fuer x² = c)
  nullstellen    — optional true: die reellen Nullstellen im Fenster als Punkte markieren
  scheitel       — optional true: den Scheitel als Punkt markieren
  label          — optional Beschriftung der Parabel
  gitter, achsen, einheit, id_praefix — durchgereicht
"""

from __future__ import annotations

import math

from .koordinatensystem import koordinatensystem
from .pruefungen import reelle_zahl, text_oder_none, wahrheitswert

SCHLUESSEL = {'a', 'd', 'e', 'x_min', 'x_max', 'y_min', 'y_max', 'punkte', 'gerade_c', 'nullstellen', 'scheitel',
              'label', 'gitter', 'achsen', 'einheit', 'id_praefix'}


def normalform(a: float, d: float, e: float) -> tuple[float, float, float]:
    """a·(x − d)² + e = a·x² − 2ad·x + (a·d² + e)."""
    return a, -2 * a * d, a * d * d + e


def nullstellen(a: float, d: float, e: float) -> list[float]:
    """Reelle Nullstellen von a·(x − d)² + e, aufsteigend; doppelte nur einmal."""
    q = -e / a
    if q < 0:
        return []
    if q == 0:
        return [d]
    w = math.sqrt(q)
    return [d - w, d + w]


def koordinaten_params(params: dict) -> dict:
    """Uebersetzt parabel-params in die Schluesselwort-Argumente von koordinatensystem()."""
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    unbekannt = set(params) - SCHLUESSEL
    if unbekannt:
        raise ValueError('parabel: unbekannte Schluessel: ' + ', '.join(sorted(map(repr, unbekannt))) + '.')
    for pflicht in ('a', 'd', 'e', 'x_min', 'x_max', 'y_min', 'y_max'):
        if pflicht not in params:
            raise ValueError(f'parabel: braucht {pflicht!r}.')
    a = reelle_zahl(params['a'], "params['a']")
    d = reelle_zahl(params['d'], "params['d']")
    e = reelle_zahl(params['e'], "params['e']")
    if a == 0:
        raise ValueError('parabel: a = 0 ist keine Parabel.')
    _, b, c = normalform(a, d, e)
    funktionen = [{'typ': 'quadratisch', 'a': a, 'b': b, 'c': c, 'betont': True,
                   'label': text_oder_none(params.get('label'), "params['label']")}]
    if params.get('gerade_c') is not None:
        funktionen.append({'typ': 'linear', 'm': 0, 'b': reelle_zahl(params['gerade_c'], "params['gerade_c']")})
    punkte = list(params.get('punkte') or [])
    x_min, x_max, y_min, y_max = (params[k] for k in ('x_min', 'x_max', 'y_min', 'y_max'))
    if wahrheitswert(params.get('nullstellen', False), "params['nullstellen']"):
        punkte += [{'x': x, 'y': 0} for x in nullstellen(a, d, e) if x_min <= x <= x_max]
    if wahrheitswert(params.get('scheitel', False), "params['scheitel']") and y_min <= e <= y_max:
        punkte.append({'x': d, 'y': e})
    weiter = {k: params[k] for k in ('gitter', 'achsen', 'einheit', 'id_praefix') if k in params}
    return {'x_min': x_min, 'x_max': x_max, 'y_min': y_min, 'y_max': y_max, 'funktionen': funktionen,
            'punkte': punkte, **weiter}


def zeichne(params: dict, theme: str) -> str:
    """Schnittstelle fuer upload_figures.py: `parabel.zeichne(params, theme) -> str`."""
    if isinstance(params, dict) and 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    return koordinatensystem(theme=theme, **koordinaten_params(params))


__all__ = ['zeichne', 'normalform', 'nullstellen', 'koordinaten_params']
