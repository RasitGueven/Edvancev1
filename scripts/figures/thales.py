#!/usr/bin/env python3
"""
Parametrischer Generator: Thaleskreis — Kreis oder Halbkreis ueber dem
Durchmesser AB, Punkt C auf dem Bogen, Dreieck ABC, Winkelboegen mit Text.

WARUM SORGFALT: Ein falsches Bild ist schlimmer als kein Bild. Beim Thales ist
das Bild selbst die Gefahr: Zeichnet man C an seine WAHRE Lage, kann ein Kind
den gesuchten Winkel mit dem Geodreieck abnehmen, statt ihn zu berechnen. Und
ein Rechter-Winkel-Zeichen bei C nimmt den Satz vorweg, um den es geht.

Deshalb ist beides baulich ausgeschlossen:
  - `c_grad` (die gezeichnete Lage von C, als Winkel BMC) und `wahre_lage_grad`
    (die Lage, die aus den Aufgabenzahlen folgt) sind PFLICHT, und sie muessen
    mindestens ABSTAND_MIN Grad auseinanderliegen. Wer beide gleich setzt,
    bekommt einen Fehler und kein Bild.
  - Ein Rechter-Winkel-Zeichen gibt es in diesem Generator nicht. Jeder
    Winkel wird als Bogen gezeichnet, auch einer, der 90 Grad hat.

`pruefe_thales.py` misst das erzeugte SVG zurueck: Lage der Punkte, Bogen,
Winkelboegen, Beschriftung, und dass C nicht an der wahren Lage sitzt.

ZEICHENRAUM 400 x 330; die viewBox ist knapp (svg_basis.dokument_knapp). A liegt links, B
rechts, AB waagerecht. C liegt oberhalb von AB; `c_grad` wird von MB aus gegen
den Uhrzeigersinn gemessen (0 < c_grad < 180).

React-native-svg-tauglich: <circle>, <line>, <polyline>, <text>, keine
Pfadbefehle, kein CSS.
"""

from __future__ import annotations

import math

try:
    from .pruefungen import reelle_zahl, wahrheitswert
    from .svg_basis import beschriftung, dokument_knapp, element, farb_attribute, kreis, linie, polylinie, zahl
    from .tokens import SCHRIFT, SCHRIFTGROESSE, STARK_ACHSE, STARK_BETONT, STARK_KURVE, palette
except ImportError:
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.pruefungen import reelle_zahl, wahrheitswert
    from figures.svg_basis import beschriftung, dokument_knapp, element, farb_attribute, kreis, linie, polylinie, zahl
    from figures.tokens import SCHRIFT, SCHRIFTGROESSE, STARK_ACHSE, STARK_BETONT, STARK_KURVE, palette

BREITE = 400
HOEHE = 330

# Mittelpunkt und Radius je Form. Der Halbkreis sitzt tiefer und ist groesser,
# weil unter AB nichts zu zeichnen ist.
LAGE = {
    'kreis': (200.0, 165.0, 125.0),
    'halbkreis': (200.0, 260.0, 160.0),
}

PUNKT_RADIUS = 3.5
NAME_ABSTAND = 20.0       # Punktname radial ausserhalb des Kreises
M_NAME_ABSTAND = 20.0     # M steht unter dem Mittelpunkt
BOGEN_RADIUS = 34.0
BOGEN_RADIUS_M = 24.0     # bei M ist es enger (zwei Boegen teilen sich den Platz)
BOGEN_STAFFEL = 10.0       # zweiter Bogen an derselben Ecke: weiter aussen, sonst
                          # verschmelzen zwei Nachbarwinkel zu einem Bogen
TEXT_ABSTAND = 8.0        # Text hinter dem Bogen, auf der Winkelhalbierenden
BOGEN_SCHRITT = 3.0       # Grad je Segment des Winkelbogens
KREIS_SCHRITT = 2.0       # Grad je Segment des Halbkreisbogens
# Schrift und Striche aus tokens.py, wie koordinatensystem: Figur = STARK_KURVE,
# Kreis und MC = STARK_ACHSE, Winkelboegen = STARK_BETONT.

# So weit muss C von der wahren Lage weg sein, damit Messen nicht hilft. 10 Grad
# am Mittelpunkt sind am Rand 5 Grad Unterschied im Umfangswinkel — mehr, als
# ein Kind mit dem Geodreieck als "ungefaehr gleich" durchgehen laesst.
ABSTAND_MIN = 10.0
# C darf nicht an A oder B kleben, sonst fallen Winkelbogen und Name zusammen.
C_GRAD_MIN = 20.0
C_GRAD_MAX = 160.0

ECKEN = ('A', 'B', 'C', 'M')
PARAMS_SCHLUESSEL = {'form', 'c_grad', 'wahre_lage_grad', 'mittelpunkt', 'mc', 'winkel'}
WINKEL_SCHLUESSEL = {'ecke', 'schenkel', 'text'}


# ── Eingaben ─────────────────────────────────────────────────────────────────

def _pruefe_winkel(roh: object, i: int, mit_m: bool, mit_mc: bool) -> dict:
    stelle = f'winkel[{i}]'
    if not isinstance(roh, dict):
        raise ValueError(f'{stelle} muss ein dict sein, nicht {roh!r}.')
    unbekannt = set(roh) - WINKEL_SCHLUESSEL
    if unbekannt:
        raise ValueError(f'{stelle}: unbekannte Schluessel: {", ".join(sorted(map(repr, unbekannt)))}.')
    ecke = roh.get('ecke')
    schenkel = roh.get('schenkel')
    text = roh.get('text')
    if ecke not in ECKEN:
        raise ValueError(f'{stelle}: ecke muss einer von {ECKEN} sein, nicht {ecke!r}.')
    if not (isinstance(schenkel, list) and len(schenkel) == 2 and all(s in ECKEN for s in schenkel)
            and len({ecke, *schenkel}) == 3):
        raise ValueError(f'{stelle}: schenkel muss zwei andere Ecken nennen, nicht {schenkel!r}.')
    if not isinstance(text, str):
        raise ValueError(f'{stelle}: text muss Text sein ("" fuer einen Bogen ohne Text), nicht {text!r}.')
    if 'M' in (ecke, *schenkel) and not mit_m:
        raise ValueError(f'{stelle}: Winkel an M, aber mittelpunkt ist aus.')
    strecken = {frozenset((ecke, s)) for s in schenkel}
    if frozenset('MC') in strecken and not mit_mc:
        raise ValueError(f'{stelle}: Schenkel MC, aber die Strecke MC ist nicht gezeichnet (mc).')
    if frozenset('MA') in strecken or frozenset('MB') in strecken:
        pass  # liegen auf dem Durchmesser, immer gezeichnet
    return {'ecke': ecke, 'schenkel': list(schenkel), 'text': text}


def pruefe_params(params: object) -> dict:
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    if 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    unbekannt = set(params) - PARAMS_SCHLUESSEL
    if unbekannt:
        raise ValueError(f'params: unbekannte Schluessel: {", ".join(sorted(map(repr, unbekannt)))}.')
    form = params.get('form')
    if form not in LAGE:
        raise ValueError(f"form muss 'kreis' oder 'halbkreis' sein, nicht {form!r}.")
    for pflicht in ('c_grad', 'wahre_lage_grad'):
        if pflicht not in params:
            raise ValueError(f'params braucht {pflicht!r}.')
    c_grad = reelle_zahl(params['c_grad'], 'c_grad')
    wahr = reelle_zahl(params['wahre_lage_grad'], 'wahre_lage_grad')
    if not C_GRAD_MIN <= c_grad <= C_GRAD_MAX:
        raise ValueError(f'c_grad muss zwischen {zahl(C_GRAD_MIN)} und {zahl(C_GRAD_MAX)} liegen, nicht {c_grad!r}.')
    if not 0 < wahr < 180:
        raise ValueError(f'wahre_lage_grad muss zwischen 0 und 180 liegen, nicht {wahr!r}.')
    if abs(c_grad - wahr) < ABSTAND_MIN:
        raise ValueError(
            f'c_grad ({zahl(c_grad)}) liegt naeher als {zahl(ABSTAND_MIN)} Grad an der wahren Lage '
            f'({zahl(wahr)}). Dann liesse sich der Winkel abmessen statt berechnen.'
        )
    mit_m = wahrheitswert(params.get('mittelpunkt', True), 'mittelpunkt')
    mit_mc = wahrheitswert(params.get('mc', False), 'mc')
    if mit_mc and not mit_m:
        raise ValueError('mc braucht mittelpunkt.')
    roh_winkel = params.get('winkel', [])
    if not isinstance(roh_winkel, list):
        raise ValueError(f'winkel muss eine Liste sein, nicht {roh_winkel!r}.')
    winkel = [_pruefe_winkel(w, i, mit_m, mit_mc) for i, w in enumerate(roh_winkel)]
    return {'form': form, 'c_grad': c_grad, 'wahre_lage_grad': wahr,
            'mittelpunkt': mit_m, 'mc': mit_mc, 'winkel': winkel}


# ── Geometrie ────────────────────────────────────────────────────────────────

def punkte(form: str, c_grad: float) -> dict[str, tuple[float, float]]:
    """A, B, C, M in Pixeln. y waechst in SVG nach unten, darum das Minus."""
    mx, my, r = LAGE[form]
    b = math.radians(c_grad)
    return {
        'A': (mx - r, my),
        'B': (mx + r, my),
        'C': (mx + r * math.cos(b), my - r * math.sin(b)),
        'M': (mx, my),
    }


def richtung(von: tuple[float, float], nach: tuple[float, float]) -> float:
    """Richtung in Grad, mathematisch (gegen den Uhrzeigersinn, y nach oben)."""
    return math.degrees(math.atan2(von[1] - nach[1], nach[0] - von[0]))


def winkelbereich(scheitel, p, q) -> tuple[float, float]:
    """Start und Weite des KLEINEREN Winkels zwischen den Strahlen nach p und q."""
    a, b = richtung(scheitel, p), richtung(scheitel, q)
    weite = (b - a) % 360.0
    if weite > 180.0:
        return b, 360.0 - weite
    return a, weite


def bogen_radius(winkel: list[dict], index: int) -> float:
    """Radius des index-ten Bogens; jeder weitere an derselben Ecke liegt weiter aussen."""
    ecke = winkel[index]['ecke']
    vorher = sum(1 for w in winkel[:index] if w['ecke'] == ecke)
    return (BOGEN_RADIUS_M if ecke == 'M' else BOGEN_RADIUS) + BOGEN_STAFFEL * vorher


def text_lage(scheitel, radius: float, mitte_grad: float) -> tuple[float, float, str]:
    """
    Ort und Anker des Winkeltexts auf der Winkelhalbierenden, hinter dem Bogen.

    Der Anker zeigt vom Scheitel WEG: Zeigt die Halbierende nach rechts, beginnt
    der Text dort ('start') und laeuft weiter in den Winkel hinein. Mittig
    gesetzt stuende er bei spitzen Winkeln halb auf dem Schenkel.
    """
    cos = math.cos(math.radians(mitte_grad))
    anker = 'start' if cos > 0.5 else 'end' if cos < -0.5 else 'middle'
    abstand = radius + TEXT_ABSTAND + (0.0 if anker != 'middle' else 6.0)
    x, y = _auf_kreis(scheitel, abstand, mitte_grad)
    return x, y, anker


def _auf_kreis(zentrum, radius: float, grad: float) -> tuple[float, float]:
    t = math.radians(grad)
    return zentrum[0] + radius * math.cos(t), zentrum[1] - radius * math.sin(t)


# ── Hauptfunktion ────────────────────────────────────────────────────────────

def thales(theme: str = 'dunkel', **params) -> str:
    p = pruefe_params(params)
    farben = palette(theme)
    pt = punkte(p['form'], p['c_grad'])
    mx, my, r = LAGE[p['form']]
    inhalt: list[str] = []

    # Kreis bzw. Halbkreisbogen: die Hilfsfigur, darum die leisere Farbe.
    if p['form'] == 'kreis':
        inhalt.append(element('circle', [
            ('cx', zahl(mx)), ('cy', zahl(my)), ('r', zahl(r)), ('fill', 'none'),
            *farb_attribute('stroke', farben.achse), ('stroke-width', zahl(STARK_ACHSE)),
        ]))
    else:
        schritte = int(180 / KREIS_SCHRITT)
        inhalt.append(polylinie(
            [_auf_kreis((mx, my), r, 180.0 * i / schritte) for i in range(schritte + 1)],
            farben.achse, STARK_ACHSE,
        ))

    # Dreieck ABC: die Figur selbst, volle Farbe. AB zuerst (der Durchmesser).
    for s, z in (('A', 'B'), ('A', 'C'), ('C', 'B')):
        inhalt.append(linie(*pt[s], *pt[z], farben.kurve, STARK_KURVE))
    if p['mc']:
        inhalt.append(linie(*pt['M'], *pt['C'], farben.kurve, STARK_ACHSE))

    # Winkelboegen (Gold). Nie ein Rechter-Winkel-Zeichen, siehe Modulkopf.
    texte: list[str] = []
    for i, w in enumerate(p['winkel']):
        scheitel = pt[w['ecke']]
        start, weite = winkelbereich(scheitel, pt[w['schenkel'][0]], pt[w['schenkel'][1]])
        radius = bogen_radius(p['winkel'], i)
        schritte = max(6, int(math.ceil(weite / BOGEN_SCHRITT)))
        inhalt.append(polylinie(
            [_auf_kreis(scheitel, radius, start + weite * i / schritte) for i in range(schritte + 1)],
            farben.kurve_betont, STARK_BETONT,
        ))
        if w['text']:
            tx, ty, anker = text_lage(scheitel, radius, start + weite / 2)
            texte.append(beschriftung(tx, ty, w['text'], farben.kurve_betont, SCHRIFTGROESSE, SCHRIFT,
                                      anker=anker, fett=True))

    # Punkte und Namen. Namen radial nach aussen, M darunter.
    namen = ['A', 'B', 'C'] + (['M'] if p['mittelpunkt'] else [])
    for n in namen:
        x, y = pt[n]
        inhalt.append(kreis(x, y, PUNKT_RADIUS, farben.kurve))
        if n == 'M':
            nx, ny = x, y + M_NAME_ABSTAND
        else:
            nx, ny = _auf_kreis((mx, my), r + NAME_ABSTAND, richtung((mx, my), (x, y)))
        texte.append(beschriftung(nx, ny, n, farben.beschriftung, SCHRIFTGROESSE, SCHRIFT))

    inhalt.append(element('g', [], ''.join(texte)))
    return dokument_knapp(inhalt)


def zeichne(params: dict, theme: str) -> str:
    """Schnittstelle fuer upload_figures.py: `thales.zeichne(params, theme) -> str`."""
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    if 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    return thales(theme=theme, **params)


__all__ = ['thales', 'zeichne', 'punkte', 'pruefe_params', 'winkelbereich', 'bogen_radius', 'richtung', 'BREITE', 'HOEHE', 'LAGE', 'ABSTAND_MIN']
