#!/usr/bin/env python3
"""
Parametrischer Generator: zusammengesetzte Rechtecke und Quadrate — angesetzt,
in einer Ecke abgetrennt, verlaengert oder gekuerzt, mit Rahmen (Weg).

SCHEMATISCH, NICHT MASSSTAEBLICH, UND DAS IST DER PUNKT: Die Aufgaben rechnen
mit Termen ("x cm", "(x + 3) m") oder mit Zahlen, die das Kind verrechnen und
nicht abmessen soll. Die Koordinaten in `params` sind deshalb Skizzen-Einheiten
und keine Masse. Was eine Seite LANG ist, sagt allein ihre Beschriftung — und
die steht nur dort, wo der Aufgabentext ein Mass nennt.

Kein Gitter, keine Kaestchen: an einem Gitter liesse sich eine Flaeche
abzaehlen. `pruefe_rechtecke.py` prueft das nach (keine Linie, die nicht zu
einer Masslinie gehoert).

Bausteine in params (alle Koordinaten in Skizzen-Einheiten, y nach OBEN):
  rechtecke — [{x, y, b, h, stil}], stil: 'kontur' (die Figur), 'gestrichelt'
              (vorher/weggenommen), 'flaeche' (getoente Flaeche ohne Rand)
  masse     — [{von: [x, y], bis: [x, y], text, seite}]: Masslinie parallel zur
              Strecke von..bis, mit Endstrichen, Text daneben. seite: 'unten' /
              'oben' fuer waagerechte, 'links' / 'rechts' fuer senkrechte Strecken.
  texte     — [{x, y, text}]: Benennung einer Flaeche ("Beet", "121 cm²").
"""

from __future__ import annotations

try:
    from .pruefungen import reelle_zahl
    from .svg_basis import beschriftung, dokument, element, farb_attribute, linie, zahl
    from .tokens import SCHRIFT, SCHRIFTGROESSE, STARK_ACHSE, STARK_KURVE, palette
except ImportError:
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.pruefungen import reelle_zahl
    from figures.svg_basis import beschriftung, dokument, element, farb_attribute, linie, zahl
    from figures.tokens import SCHRIFT, SCHRIFTGROESSE, STARK_ACHSE, STARK_KURVE, palette

BREITE = 400
HOEHE = 300
RAND_X = 80.0             # links/rechts: dort stehen senkrechte Masse (Schrift 20)
RAND_Y = 50.0             # oben/unten: dort stehen waagerechte Masse
MASS_ABSTAND = 12.0       # Masslinie neben der Strecke
MASS_STRICH = 5.0         # halbe Laenge der Endstriche
TEXT_ABSTAND = 16.0       # Text hinter der Masslinie
# Schrift und Striche aus tokens.py, wie koordinatensystem.
STRICHMUSTER = '6 4'
FLAECHE_DECKKRAFT = 0.28
KOORD_MAX = 100.0

STILE = ('flaeche', 'gestrichelt', 'kontur')  # zugleich die Zeichenreihenfolge
SEITEN = {'unten': (0, -1), 'oben': (0, 1), 'links': (-1, 0), 'rechts': (1, 0)}
PARAMS_SCHLUESSEL = {'rechtecke', 'masse', 'texte'}
RECHTECK_SCHLUESSEL = {'x', 'y', 'b', 'h', 'stil'}
MASS_SCHLUESSEL = {'von', 'bis', 'text', 'seite'}
TEXT_SCHLUESSEL = {'x', 'y', 'text'}


# ── Eingaben ─────────────────────────────────────────────────────────────────

def _dict(roh: object, stelle: str, erlaubt: set[str]) -> dict:
    if not isinstance(roh, dict):
        raise ValueError(f'{stelle} muss ein dict sein, nicht {roh!r}.')
    unbekannt = set(roh) - erlaubt
    if unbekannt:
        raise ValueError(f'{stelle}: unbekannte Schluessel: {", ".join(sorted(map(repr, unbekannt)))}.')
    fehlt = erlaubt - set(roh)
    if fehlt:
        raise ValueError(f'{stelle}: es fehlt {", ".join(sorted(map(repr, fehlt)))}.')
    return roh


def _koord(wert: object, stelle: str) -> float:
    z = reelle_zahl(wert, stelle)
    if not 0 <= z <= KOORD_MAX:
        raise ValueError(f'{stelle} muss zwischen 0 und {zahl(KOORD_MAX)} liegen, nicht {z!r}.')
    return z


def _text(wert: object, stelle: str) -> str:
    if not isinstance(wert, str) or not wert.strip():
        raise ValueError(f'{stelle} muss ein nicht leerer Text sein, nicht {wert!r}.')
    return wert


def _punkt(roh: object, stelle: str) -> tuple[float, float]:
    if not (isinstance(roh, list) and len(roh) == 2):
        raise ValueError(f'{stelle} muss [x, y] sein, nicht {roh!r}.')
    return _koord(roh[0], f'{stelle}[0]'), _koord(roh[1], f'{stelle}[1]')


def pruefe_params(params: object) -> dict:
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    if 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    unbekannt = set(params) - PARAMS_SCHLUESSEL
    if unbekannt:
        raise ValueError(f'params: unbekannte Schluessel: {", ".join(sorted(map(repr, unbekannt)))}.')
    rechtecke = []
    for i, roh in enumerate(params.get('rechtecke') or []):
        r = _dict(roh, f'rechtecke[{i}]', RECHTECK_SCHLUESSEL)
        x, y = _koord(r['x'], f'rechtecke[{i}].x'), _koord(r['y'], f'rechtecke[{i}].y')
        b, h = _koord(r['b'], f'rechtecke[{i}].b'), _koord(r['h'], f'rechtecke[{i}].h')
        if b <= 0 or h <= 0:
            raise ValueError(f'rechtecke[{i}]: b und h muessen groesser als null sein.')
        if r['stil'] not in STILE:
            raise ValueError(f'rechtecke[{i}].stil muss einer von {STILE} sein, nicht {r["stil"]!r}.')
        rechtecke.append({'x': x, 'y': y, 'b': b, 'h': h, 'stil': r['stil']})
    if not any(r['stil'] == 'kontur' for r in rechtecke):
        raise ValueError("Es braucht mindestens ein Rechteck mit stil 'kontur' — sonst gibt es keine Figur.")
    masse = []
    for i, roh in enumerate(params.get('masse') or []):
        m = _dict(roh, f'masse[{i}]', MASS_SCHLUESSEL)
        von, bis = _punkt(m['von'], f'masse[{i}].von'), _punkt(m['bis'], f'masse[{i}].bis')
        seite = m['seite']
        if seite not in SEITEN:
            raise ValueError(f'masse[{i}].seite muss einer von {tuple(SEITEN)} sein, nicht {seite!r}.')
        waagerecht = von[1] == bis[1] and von[0] < bis[0]
        senkrecht = von[0] == bis[0] and von[1] < bis[1]
        if seite in ('unten', 'oben') and not waagerecht:
            raise ValueError(f'masse[{i}]: {seite!r} verlangt eine waagerechte Strecke von links nach rechts.')
        if seite in ('links', 'rechts') and not senkrecht:
            raise ValueError(f'masse[{i}]: {seite!r} verlangt eine senkrechte Strecke von unten nach oben.')
        masse.append({'von': von, 'bis': bis, 'text': _text(m['text'], f'masse[{i}].text'), 'seite': seite})
    texte = []
    for i, roh in enumerate(params.get('texte') or []):
        t = _dict(roh, f'texte[{i}]', TEXT_SCHLUESSEL)
        texte.append({'x': _koord(t['x'], f'texte[{i}].x'), 'y': _koord(t['y'], f'texte[{i}].y'),
                      'text': _text(t['text'], f'texte[{i}].text')})
    return {'rechtecke': rechtecke, 'masse': masse, 'texte': texte}


# ── Abbildung Skizze -> Pixel ────────────────────────────────────────────────

def abbildung(rechtecke: list[dict]):
    """
    EIN Faktor fuer beide Achsen (Skizzen-Proportionen bleiben), zentriert.
    Liefert px(x), py(y) und den Faktor. y wird gespiegelt: in SVG waechst y nach unten.
    """
    x0 = min(r['x'] for r in rechtecke)
    y0 = min(r['y'] for r in rechtecke)
    x1 = max(r['x'] + r['b'] for r in rechtecke)
    y1 = max(r['y'] + r['h'] for r in rechtecke)
    flaeche_b, flaeche_h = BREITE - 2 * RAND_X, HOEHE - 2 * RAND_Y
    faktor = min(flaeche_b / (x1 - x0), flaeche_h / (y1 - y0))
    links = (BREITE - faktor * (x1 - x0)) / 2
    unten = (HOEHE + faktor * (y1 - y0)) / 2
    return (lambda x: links + (x - x0) * faktor), (lambda y: unten - (y - y0) * faktor), faktor


# ── Hauptfunktion ────────────────────────────────────────────────────────────

def rechtecke(theme: str = 'dunkel', **params) -> str:
    p = pruefe_params(params)
    farben = palette(theme)
    px, py, _ = abbildung(p['rechtecke'])
    inhalt: list[str] = []

    for stil in STILE:
        for r in (r for r in p['rechtecke'] if r['stil'] == stil):
            attr = [('x', zahl(px(r['x']))), ('y', zahl(py(r['y'] + r['h']))),
                    ('width', zahl(px(r['x'] + r['b']) - px(r['x']))),
                    ('height', zahl(py(r['y']) - py(r['y'] + r['h'])))]
            if stil == 'flaeche':
                attr += [('fill', farben.kurve_betont.hex), ('fill-opacity', zahl(FLAECHE_DECKKRAFT))]
            elif stil == 'gestrichelt':
                attr += [('fill', 'none'), *farb_attribute('stroke', farben.achse),
                         ('stroke-width', zahl(STARK_ACHSE)), ('stroke-dasharray', STRICHMUSTER)]
            else:
                attr += [('fill', 'none'), *farb_attribute('stroke', farben.kurve),
                         ('stroke-width', zahl(STARK_KURVE))]
            inhalt.append(element('rect', attr))

    texte: list[str] = []
    for m in p['masse']:
        dx, dy = SEITEN[m['seite']]           # Richtung in Skizzen-Koordinaten (y nach oben)
        ox, oy = dx * MASS_ABSTAND, -dy * MASS_ABSTAND
        ax, ay = px(m['von'][0]) + ox, py(m['von'][1]) + oy
        bx, by = px(m['bis'][0]) + ox, py(m['bis'][1]) + oy
        teile = [linie(ax, ay, bx, by, farben.beschriftung, STARK_ACHSE)]
        sx, sy = (0, MASS_STRICH) if dy else (MASS_STRICH, 0)
        for x, y in ((ax, ay), (bx, by)):
            teile.append(linie(x - sx, y - sy, x + sx, y + sy, farben.beschriftung, STARK_ACHSE))
        inhalt.append(element('g', [], ''.join(teile)))
        mx, my = (ax + bx) / 2 + dx * TEXT_ABSTAND, (ay + by) / 2 - dy * TEXT_ABSTAND
        anker = 'end' if dx < 0 else 'start' if dx > 0 else 'middle'
        texte.append(beschriftung(mx, my, m['text'], farben.beschriftung, SCHRIFTGROESSE, SCHRIFT, anker=anker))
    for t in p['texte']:
        texte.append(beschriftung(px(t['x']), py(t['y']), t['text'], farben.kurve, SCHRIFTGROESSE, SCHRIFT))
    if texte:
        inhalt.append(element('g', [], ''.join(texte)))
    return dokument(BREITE, HOEHE, inhalt)


def zeichne(params: dict, theme: str) -> str:
    """Schnittstelle fuer upload_figures.py: `rechtecke.zeichne(params, theme) -> str`."""
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    if 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    return rechtecke(theme=theme, **params)


__all__ = ['rechtecke', 'zeichne', 'pruefe_params', 'abbildung', 'BREITE', 'HOEHE',
           'MASS_ABSTAND', 'TEXT_ABSTAND', 'SEITEN']
