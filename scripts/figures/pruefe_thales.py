#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Thales-Generator — IMPORTIERBAR.

`upload_figures.py` laedt nichts hoch, was `pruefe(svg, params)` nicht besteht.
Gemessen wird das ERZEUGTE SVG, nicht die Parameter:

  r) knappe viewBox: alles liegt darin, kein Rand groesser als RAND_KNAPP
  p) Punkte: A und B waagerecht, M in der Mitte, C auf dem Kreis, der gemessene
     Winkel BMC ist `c_grad` — und liegt NICHT an der wahren Lage
  k) Kreis bzw. Halbkreisbogen um M mit Radius MA, der Halbkreis oberhalb von AB
  s) genau die Strecken AB, AC, CB (und MC, wenn verlangt), sonst keine Linie
  w) je Winkel ein Bogen um die richtige Ecke, der genau den Winkel zwischen den
     beiden Schenkeln ueberstreicht
  t) Beschriftung: Punktnamen und Winkeltexte wie in params, an der richtigen
     Stelle, kein weiterer Text
  q) kein Rechter-Winkel-Zeichen, keine 90 im Bild

Die Ecken werden aus den gezeichneten Punkten und ihren Namen zurueckgerechnet,
nie aus den Parametern uebernommen.
"""

from __future__ import annotations

import math
import re

try:
    from .svg_basis import pruefe_knapper_rahmen
    from .thales import ABSTAND_MIN, pruefe_params
except ImportError:
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.svg_basis import pruefe_knapper_rahmen
    from figures.thales import ABSTAND_MIN, pruefe_params

EPS_PIXEL = 0.6
EPS_GRAD = 0.6
EPS_BOGEN = 1.5          # Weite eines Winkelbogens gegen den gemessenen Winkel
EPS_TEXT_GRAD = 12.0     # Richtung eines Winkeltexts gegen die Winkelhalbierende
NAME_MAX_ABSTAND = 30.0  # so weit darf ein Punktname von seinem Punkt stehen


# ── SVG einlesen ─────────────────────────────────────────────────────────────

def _kopf(svg: str) -> tuple[float, float]:
    m = re.search(r'<svg\b[^>]*\bwidth="([\d.]+)"[^>]*\bheight="([\d.]+)"', svg)
    if not m:
        raise ValueError('SVG ohne width/height.')
    return float(m.group(1)), float(m.group(2))


def _kreise(svg: str) -> list[dict]:
    aus = []
    for m in re.finditer(r'<circle cx="([\d.-]+)" cy="([\d.-]+)" r="([\d.-]+)"([^>]*)/>', svg):
        aus.append({'x': float(m.group(1)), 'y': float(m.group(2)), 'r': float(m.group(3)),
                    'gefuellt': 'fill="none"' not in m.group(4)})
    return aus


def _linien(svg: str) -> list[tuple[float, float, float, float]]:
    return [tuple(map(float, m.groups())) for m in re.finditer(
        r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', svg)]


def _polylinien(svg: str) -> list[dict]:
    aus = []
    for m in re.finditer(r'<polyline points="([^"]+)"[^>]*stroke="(#[0-9A-F]{6})"', svg):
        pkt = [tuple(map(float, p.split(','))) for p in m.group(1).split()]
        aus.append({'punkte': pkt, 'farbe': m.group(2)})
    return aus


def _texte(svg: str) -> list[dict]:
    aus = []
    for m in re.finditer(r'<text x="([\d.-]+)" y="([\d.-]+)" fill="(#[0-9A-F]{6})"[^>]*'
                         r'text-anchor="(\w+)"[^>]*>([^<]*)</text>', svg):
        aus.append({'x': float(m.group(1)), 'y': float(m.group(2)), 'farbe': m.group(3),
                    'anker': m.group(4), 'text': m.group(5).replace('&lt;', '<').replace('&gt;', '>')
                    .replace('&amp;', '&')})
    return aus


def _abstand(a, b) -> float:
    return math.hypot(a[0] - b[0], a[1] - b[1])


def _richtung(von, nach) -> float:
    return math.degrees(math.atan2(von[1] - nach[1], nach[0] - von[0]))


def _winkel_zwischen(scheitel, p, q) -> float:
    d = abs(_richtung(scheitel, p) - _richtung(scheitel, q)) % 360.0
    return 360.0 - d if d > 180.0 else d


def _differenz(a: float, b: float) -> float:
    d = abs(a - b) % 360.0
    return 360.0 - d if d > 180.0 else d


def ecken(svg: str) -> dict[str, tuple[float, float]]:
    """Die gezeichneten Punkte, zugeordnet ueber den naechsten Namenstext."""
    punkte = [k for k in _kreise(svg) if k['gefuellt']]
    namen = [t for t in _texte(svg) if t['text'] in ('A', 'B', 'C', 'M')]
    aus: dict[str, tuple[float, float]] = {}
    for t in namen:
        if not punkte:
            break
        naechster = min(punkte, key=lambda k: _abstand((k['x'], k['y']), (t['x'], t['y'])))
        if _abstand((naechster['x'], naechster['y']), (t['x'], t['y'])) <= NAME_MAX_ABSTAND:
            aus[t['text']] = (naechster['x'], naechster['y'])
    return aus


def _mittelpunkt(e: dict) -> tuple[float, float]:
    return ((e['A'][0] + e['B'][0]) / 2, (e['A'][1] + e['B'][1]) / 2)


# ── Pruefungen ───────────────────────────────────────────────────────────────

def pruefe_rahmen(svg: str, params: dict) -> list[str]:
    """Knappe viewBox: deckt width/height, alles liegt darin, kein Rand groesser als RAND_KNAPP."""
    return pruefe_knapper_rahmen(svg)


def pruefe_punkte(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    e = ecken(svg)
    soll = {'A', 'B', 'C'} | ({'M'} if p['mittelpunkt'] else set())
    if set(e) != soll:
        return [f'p: Punkte {sorted(e)} statt {sorted(soll)}.']
    befunde = []
    if abs(e['A'][1] - e['B'][1]) > EPS_PIXEL or e['A'][0] >= e['B'][0]:
        befunde.append('p: AB ist nicht waagerecht mit A links.')
    m = _mittelpunkt(e)
    if 'M' in e and _abstand(e['M'], m) > EPS_PIXEL:
        befunde.append('p: M liegt nicht in der Mitte von AB.')
    r = _abstand(m, e['A'])
    if abs(_abstand(m, e['C']) - r) > EPS_PIXEL:
        befunde.append(f'p: C liegt nicht auf dem Kreis (MC {_abstand(m, e["C"]):.1f}, Radius {r:.1f}).')
    if e['C'][1] >= m[1]:
        befunde.append('p: C liegt nicht oberhalb von AB.')
    bmc = _winkel_zwischen(m, e['B'], e['C'])
    if abs(bmc - p['c_grad']) > EPS_GRAD:
        befunde.append(f'p: Winkel BMC gemessen {bmc:.2f}°, verlangt {p["c_grad"]:g}°.')
    if abs(bmc - p['wahre_lage_grad']) < ABSTAND_MIN - EPS_GRAD:
        befunde.append(f'p: C sitzt an der wahren Lage ({bmc:.1f}° gegen {p["wahre_lage_grad"]:g}°) — '
                       'der Winkel liesse sich abmessen.')
    return befunde


def pruefe_kreis(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    e = ecken(svg)
    if not {'A', 'B'} <= set(e):
        return ['k: A oder B fehlt, Kreis nicht pruefbar.']
    m, r = _mittelpunkt(e), _abstand(_mittelpunkt(e), e['A'])
    umrisse = [k for k in _kreise(svg) if not k['gefuellt']]
    if p['form'] == 'kreis':
        if len(umrisse) != 1:
            return [f'k: {len(umrisse)} Kreislinien statt einer.']
        k = umrisse[0]
        if _abstand((k['x'], k['y']), m) > EPS_PIXEL or abs(k['r'] - r) > EPS_PIXEL:
            return ['k: Kreis nicht um M mit Radius MA.']
        return []
    if umrisse:
        return ['k: Halbkreis verlangt, aber eine volle Kreislinie gezeichnet.']
    boegen = [pl for pl in _polylinien(svg)
              if len(pl['punkte']) > 20 and all(abs(_abstand(q, m) - r) < EPS_PIXEL for q in pl['punkte'])]
    if len(boegen) != 1:
        return [f'k: {len(boegen)} Halbkreisboegen um M statt einem.']
    b = boegen[0]['punkte']
    befunde = []
    if any(q[1] > m[1] + EPS_PIXEL for q in b):
        befunde.append('k: Halbkreisbogen reicht unter AB.')
    enden = {b[0], b[-1]}
    if not all(min(_abstand(x, y) for y in enden) < EPS_PIXEL for x in (e['A'], e['B'])):
        befunde.append('k: Halbkreisbogen endet nicht in A und B.')
    return befunde


def pruefe_strecken(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    e = ecken(svg)
    soll = [('A', 'B'), ('A', 'C'), ('C', 'B')] + ([('M', 'C')] if p['mc'] else [])
    if not all(n in e for s in soll for n in s):
        return ['s: Ecken fehlen, Strecken nicht pruefbar.']
    linien = _linien(svg)
    befunde = []
    for s, z in soll:
        if not any((_abstand(l[:2], e[s]) < EPS_PIXEL and _abstand(l[2:], e[z]) < EPS_PIXEL)
                   or (_abstand(l[:2], e[z]) < EPS_PIXEL and _abstand(l[2:], e[s]) < EPS_PIXEL) for l in linien):
            befunde.append(f's: Strecke {s}{z} fehlt.')
    if len(linien) != len(soll):
        befunde.append(f's: {len(linien)} Linien statt {len(soll)} — eine Linie zu viel ist eine Behauptung zu viel.')
    return befunde


def _boegen_um(svg: str, scheitel) -> list[list[tuple[float, float]]]:
    aus = []
    for pl in _polylinien(svg):
        abst = [_abstand(q, scheitel) for q in pl['punkte']]
        if len(abst) >= 4 and max(abst) - min(abst) < EPS_PIXEL and max(abst) < 60:
            aus.append(pl['punkte'])
    return aus


def pruefe_winkelboegen(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    e = ecken(svg)
    befunde = []
    gesamt = 0
    for w in p['winkel']:
        if any(n not in e for n in (w['ecke'], *w['schenkel'])):
            befunde.append(f'w: Ecken zu {w["ecke"]} fehlen.')
            continue
        s, a, b = e[w['ecke']], e[w['schenkel'][0]], e[w['schenkel'][1]]
        soll = _winkel_zwischen(s, a, b)
        ra, rb = _richtung(s, a), _richtung(s, b)
        passt = []
        for bogen in _boegen_um(svg, s):
            weite = sum(_differenz(_richtung(s, bogen[i]), _richtung(s, bogen[i + 1])) for i in range(len(bogen) - 1))
            r0, r1 = _richtung(s, bogen[0]), _richtung(s, bogen[-1])
            enden_ok = ((_differenz(r0, ra) < EPS_BOGEN and _differenz(r1, rb) < EPS_BOGEN)
                        or (_differenz(r0, rb) < EPS_BOGEN and _differenz(r1, ra) < EPS_BOGEN))
            if enden_ok and abs(weite - soll) < EPS_BOGEN:
                passt.append(bogen)
        if len(passt) != 1:
            befunde.append(f'w: Bogen fuer den Winkel bei {w["ecke"]} zwischen {"".join(w["schenkel"])} '
                           f'({soll:.1f}°) {len(passt)}-mal gefunden statt einmal.')
    for n in e:
        gesamt += len(_boegen_um(svg, e[n]))
    if gesamt != len(p['winkel']):
        befunde.append(f'w: {gesamt} Winkelboegen im Bild, verlangt {len(p["winkel"])}.')
    return befunde


def pruefe_beschriftung(svg: str, params: dict) -> list[str]:
    p = pruefe_params(params)
    e = ecken(svg)
    texte = _texte(svg)
    befunde = []
    namen = sorted(t['text'] for t in texte if t['text'] in ('A', 'B', 'C', 'M'))
    soll_namen = sorted(['A', 'B', 'C'] + (['M'] if p['mittelpunkt'] else []))
    if namen != soll_namen:
        befunde.append(f't: Punktnamen {namen} statt {soll_namen}.')
    winkeltexte = [t for t in texte if t['text'] not in ('A', 'B', 'C', 'M')]
    soll_texte = [w for w in p['winkel'] if w['text']]
    if sorted(t['text'] for t in winkeltexte) != sorted(w['text'] for w in soll_texte):
        befunde.append(f't: Winkeltexte {sorted(t["text"] for t in winkeltexte)} '
                       f'statt {sorted(w["text"] for w in soll_texte)}.')
        return befunde
    for w in soll_texte:
        if any(n not in e for n in (w['ecke'], *w['schenkel'])):
            continue
        s = e[w['ecke']]
        ra, rb = _richtung(s, e[w['schenkel'][0]]), _richtung(s, e[w['schenkel'][1]])
        mitte = ra + (((rb - ra + 180) % 360) - 180) / 2
        if not any(t['text'] == w['text'] and _differenz(_richtung(s, (t['x'], t['y'])), mitte) < EPS_TEXT_GRAD
                   and _abstand(s, (t['x'], t['y'])) < 90 for t in winkeltexte):
            befunde.append(f't: Text {w["text"]!r} steht nicht im Winkel bei {w["ecke"]}.')
    return befunde


def pruefe_kein_rechter_winkel(svg: str, params: dict) -> list[str]:
    befunde = []
    if any(re.search(r'(?<![\d,])90(?![\d,])', t['text']) for t in _texte(svg)):
        befunde.append('q: eine 90 steht im Bild — sie nimmt den Satz des Thales vorweg.')
    for pl in _polylinien(svg):
        q = pl['punkte']
        if len(q) == 3:
            v1 = (q[0][0] - q[1][0], q[0][1] - q[1][1])
            v2 = (q[2][0] - q[1][0], q[2][1] - q[1][1])
            if abs(v1[0] * v2[0] + v1[1] * v2[1]) < 1e-6 * (1 + _abstand(q[0], q[1]) * _abstand(q[2], q[1])):
                befunde.append('q: ein Rechter-Winkel-Zeichen ist gezeichnet.')
    return befunde


PRUEFUNGEN = (pruefe_rahmen, pruefe_punkte, pruefe_kreis, pruefe_strecken,
              pruefe_winkelboegen, pruefe_beschriftung, pruefe_kein_rechter_winkel)


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


__all__ = ['pruefe', 'pruefe_geometrie', 'ecken', *[f.__name__ for f in PRUEFUNGEN]]
