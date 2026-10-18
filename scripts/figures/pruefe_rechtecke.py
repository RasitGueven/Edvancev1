#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Rechtecke-Generator — IMPORTIERBAR.

Gemessen wird das ERZEUGTE SVG. Die Abbildung Skizze -> Pixel wird aus den
gezeichneten Rechtecken zurueckgerechnet (Umriss aller Rechtecke gegen den
Umriss der Parameter), nie aus dem Generator uebernommen:

  r) alles liegt im Rahmen
  e) EIN Faktor fuer beide Achsen, jedes Rechteck an seinem Ort und im
     verlangten Stil (kontur / gestrichelt / flaeche)
  m) je Mass eine Masslinie parallel zur Strecke, gleich lang, auf der
     verlangten Seite, mit zwei Endstrichen, und der Text daneben
  t) genau die Texte aus params, an ihrem Ort — kein weiterer Text, also auch
     keine Zahl, die der Aufgabentext nicht nennt
  g) kein Gitter: keine Linie, die nicht zu einer Masslinie gehoert, keine
     Kreise, Pfade oder Streckenzuege
"""

from __future__ import annotations

import re

try:
    from .rechtecke import MASS_ABSTAND, SEITEN, TEXT_ABSTAND, pruefe_params
except ImportError:
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.rechtecke import MASS_ABSTAND, SEITEN, TEXT_ABSTAND, pruefe_params

EPS_PIXEL = 0.6
EPS_FAKTOR = 0.01
EPS_TEXT = 1.0


# ── SVG einlesen ─────────────────────────────────────────────────────────────

def _kopf(svg: str) -> tuple[float, float]:
    m = re.search(r'<svg\b[^>]*\bwidth="([\d.]+)"[^>]*\bheight="([\d.]+)"', svg)
    if not m:
        raise ValueError('SVG ohne width/height.')
    return float(m.group(1)), float(m.group(2))


def _rechtecke(svg: str) -> list[dict]:
    aus = []
    for m in re.finditer(r'<rect x="([\d.-]+)" y="([\d.-]+)" width="([\d.-]+)" height="([\d.-]+)"([^>]*)/>', svg):
        rest = m.group(5)
        stil = ('flaeche' if 'fill-opacity' in rest and 'stroke=' not in rest
                else 'gestrichelt' if 'stroke-dasharray' in rest else 'kontur')
        x, y, b, h = (float(m.group(i)) for i in range(1, 5))
        aus.append({'x0': x, 'y0': y, 'x1': x + b, 'y1': y + h, 'stil': stil})
    return aus


def _linien(svg: str) -> list[tuple[float, float, float, float]]:
    return [tuple(map(float, m.groups())) for m in re.finditer(
        r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', svg)]


def _texte(svg: str) -> list[dict]:
    return [{'x': float(m.group(1)), 'y': float(m.group(2)), 'anker': m.group(3),
             'text': m.group(4).replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')}
            for m in re.finditer(r'<text x="([\d.-]+)" y="([\d.-]+)"[^>]*text-anchor="(\w+)"[^>]*>([^<]*)</text>', svg)]


def abbildung(svg: str, p: dict):
    """
    Skizze -> Pixel aus dem GEZEICHNETEN Umriss: (px, py, faktor_x, faktor_y).
    Zwei Faktoren, damit pruefe_rechtecke eine ungleiche Skalierung melden kann.
    """
    gez = _rechtecke(svg)
    if not gez:
        raise ValueError('keine Rechtecke im SVG.')
    gx0, gy0 = min(r['x0'] for r in gez), min(r['y0'] for r in gez)
    gx1, gy1 = max(r['x1'] for r in gez), max(r['y1'] for r in gez)
    sx0 = min(r['x'] for r in p['rechtecke'])
    sy0 = min(r['y'] for r in p['rechtecke'])
    sx1 = max(r['x'] + r['b'] for r in p['rechtecke'])
    sy1 = max(r['y'] + r['h'] for r in p['rechtecke'])
    fx, fy = (gx1 - gx0) / (sx1 - sx0), (gy1 - gy0) / (sy1 - sy0)
    return (lambda x: gx0 + (x - sx0) * fx), (lambda y: gy1 - (y - sy0) * fy), fx, fy


def _nah(a: float, b: float, eps: float = EPS_PIXEL) -> bool:
    return abs(a - b) <= eps


# ── Pruefungen ───────────────────────────────────────────────────────────────

def pruefe_rahmen(svg: str, params: dict) -> list[str]:
    breite, hoehe = _kopf(svg)
    xs, ys = [], []
    for r in _rechtecke(svg):
        xs += [r['x0'], r['x1']]
        ys += [r['y0'], r['y1']]
    for l in _linien(svg):
        xs += [l[0], l[2]]
        ys += [l[1], l[3]]
    for t in _texte(svg):
        xs.append(t['x'])
        ys.append(t['y'])
    if xs and (min(xs) < 0 or max(xs) > breite or min(ys) < 0 or max(ys) > hoehe):
        return [f'r: ausserhalb des Rahmens ({min(xs):.1f}..{max(xs):.1f} / {min(ys):.1f}..{max(ys):.1f}).']
    return []


def pruefe_rechtecke(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    px, py, fx, fy = abbildung(svg, p)
    befunde = []
    if abs(fx - fy) > EPS_FAKTOR * max(fx, fy):
        befunde.append(f'e: ungleiche Skalierung (waagerecht {fx:.3f}, senkrecht {fy:.3f} px je Einheit).')
    gez = _rechtecke(svg)
    if len(gez) != len(p['rechtecke']):
        befunde.append(f'e: {len(gez)} Rechtecke gezeichnet, verlangt {len(p["rechtecke"])}.')
    frei = list(gez)
    for i, r in enumerate(p['rechtecke']):
        soll = (px(r['x']), py(r['y'] + r['h']), px(r['x'] + r['b']), py(r['y']))
        treffer = [g for g in frei if g['stil'] == r['stil']
                   and all(_nah(a, b) for a, b in zip(soll, (g['x0'], g['y0'], g['x1'], g['y1'])))]
        if not treffer:
            befunde.append(f'e: rechtecke[{i}] ({r["stil"]}) nicht an seinem Ort gezeichnet.')
        else:
            frei.remove(treffer[0])
    return befunde


def pruefe_masse(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    px, py, _, _ = abbildung(svg, p)
    linien = _linien(svg)
    texte = _texte(svg)
    befunde = []
    for i, m in enumerate(p['masse']):
        dx, dy = SEITEN[m['seite']]
        ax, ay = px(m['von'][0]) + dx * MASS_ABSTAND, py(m['von'][1]) - dy * MASS_ABSTAND
        bx, by = px(m['bis'][0]) + dx * MASS_ABSTAND, py(m['bis'][1]) - dy * MASS_ABSTAND
        haupt = [l for l in linien if (_nah(l[0], ax) and _nah(l[1], ay) and _nah(l[2], bx) and _nah(l[3], by))]
        if len(haupt) != 1:
            befunde.append(f'm: Masslinie fuer masse[{i}] ({m["text"]!r}) nicht neben der Strecke auf Seite {m["seite"]!r}.')
            continue
        for ex, ey in ((ax, ay), (bx, by)):
            strich = [l for l in linien if _nah((l[0] + l[2]) / 2, ex) and _nah((l[1] + l[3]) / 2, ey)
                      and l is not haupt[0] and (_nah(l[0], l[2]) if dy else _nah(l[1], l[3]))]
            if not strich:
                befunde.append(f'm: Endstrich fehlt an masse[{i}] ({m["text"]!r}).')
        tx, ty = (ax + bx) / 2 + dx * TEXT_ABSTAND, (ay + by) / 2 - dy * TEXT_ABSTAND
        if not any(t['text'] == m['text'] and _nah(t['x'], tx, EPS_TEXT) and _nah(t['y'], ty, EPS_TEXT) for t in texte):
            befunde.append(f'm: Text {m["text"]!r} steht nicht an masse[{i}].')
    return befunde


def pruefe_texte(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    px, py, _, _ = abbildung(svg, p)
    texte = _texte(svg)
    soll = sorted([m['text'] for m in p['masse']] + [t['text'] for t in p['texte']])
    ist = sorted(t['text'] for t in texte)
    if ist != soll:
        return [f't: Texte {ist} statt {soll}.']
    befunde = []
    for i, t in enumerate(p['texte']):
        if not any(g['text'] == t['text'] and _nah(g['x'], px(t['x']), EPS_TEXT) and _nah(g['y'], py(t['y']), EPS_TEXT)
                   for g in texte):
            befunde.append(f't: texte[{i}] ({t["text"]!r}) nicht an seinem Ort.')
    return befunde


def pruefe_kein_gitter(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    befunde = []
    n = len(_linien(svg))
    if n != 3 * len(p['masse']):
        befunde.append(f'g: {n} Linien, erwartet {3 * len(p["masse"])} (je Mass eine Masslinie und zwei Endstriche) '
                       '— jede weitere Linie waere ein Gitter oder eine Behauptung, die der Text nicht macht.')
    fremd = set(re.findall(r'<(circle|path|polyline|polygon|ellipse)\b', svg))
    if fremd:
        befunde.append(f'g: unerwartete Elemente {sorted(fremd)}.')
    return befunde


PRUEFUNGEN = (pruefe_rahmen, pruefe_rechtecke, pruefe_masse, pruefe_texte, pruefe_kein_gitter)


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    return [b for f in PRUEFUNGEN for b in f(svg, params)]


def pruefe(svg: str, params: dict) -> tuple[bool, str]:
    """Schnittstelle fuer upload_figures.py: (bestanden, meldung)."""
    try:
        befunde = pruefe_geometrie(svg, params)
    except ValueError as fehler:
        return False, f'nicht pruefbar: {fehler}'
    if befunde:
        return False, '; '.join(befunde)
    return True, 'ok'


__all__ = ['pruefe', 'pruefe_geometrie', 'abbildung', *[f.__name__ for f in PRUEFUNGEN]]
