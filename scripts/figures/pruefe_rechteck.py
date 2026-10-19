#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Rechteck-Generator (rechteck.ts) — IMPORTIERBAR.

Der Generator ist TypeScript und hat eigene Tests (tests/figur-rechteck.test.ts).
Fuer den Upload braucht upload_figures.py aber eine Pruefung in Python, die das
ERZEUGTE SVG zurueckliest — unabhaengig vom Generator:

  r) alles liegt im Rahmen
  f) die Kontur ist ein achsenparalleles Rechteck; jede Linie liegt auf seinem
     Rand (oder ist die verlangte Diagonale)
  v) das gezeichnete Seitenverhaeltnis ist das verlangte (bei Text-Massen
     `verhaeltnis`, sonst laenge:breite, auf 1:4 bzw. 4:1 gekappt)
  w) das Zeichen fuer den rechten Winkel sitzt innen an der unteren linken Ecke
  t) genau zwei Texte: die Laenge mittig unter der unteren Seite, die Breite
     links neben der linken — mit dem Wortlaut aus params
"""

from __future__ import annotations

import re

EPS_PIXEL = 0.6
EPS_VERHAELTNIS = 0.01
VERHAELTNIS_MAX = 4.0            # wie rechteckParams.ts
VERHAELTNIS_TEXT_STANDARD = 1.6  # wie rechteckParams.ts
TEXT_UNTEN = 20.0                # Abstand der Laengenangabe unter der Seite
TEXT_LINKS = 12.0                # Abstand der Breitenangabe links der Seite


def _kopf(svg: str) -> tuple[float, float]:
    m = re.search(r'<svg\b[^>]*\bwidth="([\d.]+)"[^>]*\bheight="([\d.]+)"', svg)
    if not m:
        raise ValueError('SVG ohne width/height.')
    return float(m.group(1)), float(m.group(2))


def _linien(svg: str) -> list[tuple[float, float, float, float]]:
    return [tuple(map(float, m.groups())) for m in re.finditer(
        r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', svg)]


def _polylinien(svg: str) -> list[list[tuple[float, float]]]:
    return [[tuple(map(float, p.split(','))) for p in m.group(1).split()]
            for m in re.finditer(r'<polyline points="([^"]+)"', svg)]


def _texte(svg: str) -> list[dict]:
    return [{'x': float(m.group(1)), 'y': float(m.group(2)), 'anker': m.group(3),
             'text': m.group(4).replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')}
            for m in re.finditer(r'<text x="([\d.-]+)" y="([\d.-]+)"[^>]*text-anchor="(\w+)"[^>]*>([^<]*)</text>', svg)]


def _nah(a: float, b: float, eps: float = EPS_PIXEL) -> bool:
    return abs(a - b) <= eps


def rahmen(svg: str) -> tuple[float, float, float, float]:
    """Der gezeichnete Umriss: kleinstes Rechteck um alle Linien."""
    linien = _linien(svg)
    if not linien:
        raise ValueError('keine Linien im SVG.')
    xs = [v for l in linien for v in (l[0], l[2])]
    ys = [v for l in linien for v in (l[1], l[3])]
    return min(xs), min(ys), max(xs), max(ys)


def _mass(wert: float) -> str:
    """Wie mass() in svgBasis.ts: zwei Stellen, ohne Nullschwanz, Dezimalkomma."""
    text = f'{round(float(wert), 2):.2f}'.rstrip('0').rstrip('.')
    return ('0' if text in ('-0', '') else text).replace('.', ',')


def soll_texte(params: dict) -> tuple[str, str]:
    if 'laenge_text' in params or 'breite_text' in params:
        return params['laenge_text'], params['breite_text']
    einheit = params.get('einheit')
    angabe = (lambda w: f'{_mass(w)} {einheit}') if einheit else _mass
    return angabe(params['laenge']), angabe(params['breite'])


def soll_verhaeltnis(params: dict) -> float:
    if 'laenge_text' in params or 'breite_text' in params:
        return float(params.get('verhaeltnis', VERHAELTNIS_TEXT_STANDARD))
    echt = params['laenge'] / params['breite']
    return min(max(echt, 1 / VERHAELTNIS_MAX), VERHAELTNIS_MAX)


# ── Pruefungen ───────────────────────────────────────────────────────────────

def pruefe_rahmen(svg: str, params: dict) -> list[str]:
    breite, hoehe = _kopf(svg)
    x0, y0, x1, y1 = rahmen(svg)
    xs = [x0, x1] + [t['x'] for t in _texte(svg)]
    ys = [y0, y1] + [t['y'] for t in _texte(svg)]
    if min(xs) < 0 or max(xs) > breite or min(ys) < 0 or max(ys) > hoehe:
        return ['r: ausserhalb des Rahmens.']
    return []


def pruefe_form(svg: str, params: dict) -> list[str]:
    x0, y0, x1, y1 = rahmen(svg)
    befunde = []
    for l in _linien(svg):
        waagerecht = _nah(l[1], l[3]) and (_nah(l[1], y0) or _nah(l[1], y1))
        senkrecht = _nah(l[0], l[2]) and (_nah(l[0], x0) or _nah(l[0], x1))
        diagonale = params.get('diagonale') and _nah(l[0], x0) and _nah(l[1], y0) and _nah(l[2], x1) and _nah(l[3], y1)
        if not (waagerecht or senkrecht or diagonale):
            befunde.append(f'f: Linie {l} liegt nicht auf dem Rand des Rechtecks.')
    for seite, kanten in (('unten', [l for l in _linien(svg) if _nah(l[1], y1) and _nah(l[3], y1)]),
                          ('links', [l for l in _linien(svg) if _nah(l[0], x0) and _nah(l[2], x0)])):
        if not kanten:
            befunde.append(f'f: die Seite {seite} fehlt.')
    return befunde


def pruefe_verhaeltnis(svg: str, params: dict) -> list[str]:
    x0, y0, x1, y1 = rahmen(svg)
    ist, soll = (x1 - x0) / (y1 - y0), soll_verhaeltnis(params)
    if abs(ist - soll) > EPS_VERHAELTNIS * soll:
        return [f'v: Seitenverhaeltnis {ist:.3f} gezeichnet, verlangt {soll:.3f}.']
    return []


def pruefe_rechter_winkel(svg: str, params: dict) -> list[str]:
    x0, _, _, y1 = rahmen(svg)
    zeichen = [p for p in _polylinien(svg) if len(p) == 3]
    if len(zeichen) != 1:
        return [f'w: {len(zeichen)} Winkelzeichen statt einem.']
    a, b, c = zeichen[0]
    if not (_nah(a[0], x0) and _nah(c[1], y1) and _nah(b[0], c[0]) and _nah(b[1], a[1]) and b[0] > x0 and b[1] < y1):
        return ['w: das Winkelzeichen sitzt nicht innen an der unteren linken Ecke.']
    return []


def pruefe_beschriftung(svg: str, params: dict) -> list[str]:
    x0, y0, x1, y1 = rahmen(svg)
    laenge, breite = soll_texte(params)
    texte = _texte(svg)
    if sorted(t['text'] for t in texte) != sorted([laenge, breite]):
        return [f't: Texte {sorted(t["text"] for t in texte)} statt {sorted([laenge, breite])}.']
    befunde = []
    if not any(t['text'] == laenge and t['anker'] == 'middle' and _nah(t['x'], (x0 + x1) / 2)
               and _nah(t['y'], y1 + TEXT_UNTEN) for t in texte):
        befunde.append(f't: {laenge!r} steht nicht mittig unter der unteren Seite.')
    if not any(t['text'] == breite and t['anker'] == 'end' and _nah(t['x'], x0 - TEXT_LINKS)
               and _nah(t['y'], (y0 + y1) / 2) for t in texte):
        befunde.append(f't: {breite!r} steht nicht links neben der linken Seite.')
    return befunde


PRUEFUNGEN = (pruefe_rahmen, pruefe_form, pruefe_verhaeltnis, pruefe_rechter_winkel, pruefe_beschriftung)


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    return [b for f in PRUEFUNGEN for b in f(svg, params)]


def pruefe(svg: str, params: dict) -> tuple[bool, str]:
    """Schnittstelle fuer upload_figures.py: (bestanden, meldung)."""
    try:
        befunde = pruefe_geometrie(svg, params)
    except (ValueError, KeyError, ZeroDivisionError) as fehler:
        return False, f'nicht pruefbar: {fehler!r}'
    if befunde:
        return False, '; '.join(befunde)
    return True, 'ok'


__all__ = ['pruefe', 'pruefe_geometrie', 'rahmen', 'soll_texte', *[f.__name__ for f in PRUEFUNGEN]]
