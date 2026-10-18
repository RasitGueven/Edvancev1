#!/usr/bin/env python3
"""
Tests fuer den Rechtecke-Generator.

    python3 -m pytest scripts/figures/test_rechtecke.py -q

Gueltige Figuren (die fuenf Pilot-Aufgaben, beide Themes) muessen `pruefe`
bestehen; die Negativkontrolle macht SVGs gezielt kaputt und verlangt, dass die
zustaendige Pruefung anschlaegt.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.pruefe_rechtecke import pruefe, pruefe_geometrie  # noqa: E402
from figures.rechtecke import BREITE, HOEHE, rechtecke, zeichne  # noqa: E402
from figures.tokens import THEMES  # noqa: E402


def R(x, y, b, h, stil='kontur'):
    return {'x': x, 'y': y, 'b': b, 'h': h, 'stil': stil}


def M(von, bis, text, seite):
    return {'von': list(von), 'bis': list(bis), 'text': text, 'seite': seite}


def T(x, y, text):
    return {'x': x, 'y': y, 'text': text}


# Die fuenf Pilot-Aufgaben (docs/figuren/bedarf.json). Koordinaten sind
# Skizzen-Einheiten; was eine Seite misst, sagt nur ihr Text.
PILOT = {
    '11390e1a': {'rechtecke': [R(0, 0, 7, 4), R(7, 0, 4, 4)],
                 'masse': [M((0, 0), (7, 0), 'x cm', 'unten'), M((0, 0), (0, 4), '4 cm', 'links'),
                           M((7, 0), (11, 0), '4 cm', 'unten')]},
    'f8364853': {'rechtecke': [R(5, 0, 3, 8, 'flaeche'), R(0, 5, 5, 3, 'flaeche'), R(0, 0, 8, 8), R(0, 0, 5, 5)],
                 'masse': [M((0, 8), (8, 8), '(x + 3) m', 'oben'), M((0, 0), (5, 0), '(x - 1) m', 'unten')],
                 'texte': [T(2.5, 2.5, 'Beet')]},
    '113aea0a': {'rechtecke': [R(0, 0, 6, 6, 'gestrichelt'), R(0, 0, 8, 4)],
                 'masse': [M((0, 0), (6, 0), 'x m', 'unten'), M((6, 0), (8, 0), '5 m', 'unten'),
                           M((0, 4), (0, 6), '5 m', 'links')]},
    '3a42b89c': {'rechtecke': [R(0, 0, 5, 5, 'gestrichelt'), R(0, 0, 7, 7)],
                 'masse': [M((0, 0), (5, 0), '?', 'unten'), M((5, 0), (7, 0), '3 cm', 'unten'),
                           M((0, 5), (0, 7), '3 cm', 'links')],
                 'texte': [T(3.5, 7.9, 'neues Quadrat: 121 cm²')]},
    '5b36238f': {'rechtecke': [R(0, 0, 11, 9), R(1.5, 1.5, 8, 6)],
                 'masse': [M((9.5, 4.5), (11, 4.5), '?', 'oben')],
                 'texte': [T(6, 3.2, 'Beet'), T(5.5, 6.8, '20 m'), T(2.8, 4.5, '15 m'), T(5.5, 0.75, 'Weg')]},
}


@pytest.mark.parametrize('name', sorted(PILOT))
@pytest.mark.parametrize('theme', THEMES)
def test_pilot_aufgaben_bestehen(name, theme):
    assert pruefe(zeichne(PILOT[name], theme), PILOT[name]) == (True, 'ok')


@pytest.mark.parametrize('b, h', [(1, 1), (1, 9), (9, 1), (40, 3), (0.5, 0.5)])
@pytest.mark.parametrize('seite', ['unten', 'oben', 'links', 'rechts'])
def test_formen_und_seiten_bestehen(b, h, seite):
    strecke = ((0, 0), (b, 0)) if seite in ('unten', 'oben') else ((0, 0), (0, h))
    params = {'rechtecke': [R(0, 0, b, h)], 'masse': [M(*strecke, 'a', seite)]}
    assert pruefe_geometrie(zeichne(params, 'hell'), params) == []


def test_gleiche_parameter_gleiche_bytes():
    assert zeichne(PILOT['f8364853'], 'dunkel') == zeichne(dict(PILOT['f8364853']), 'dunkel')


def test_fester_rahmen():
    for p in PILOT.values():
        assert f'viewBox="0 0 {BREITE} {HOEHE}"' in zeichne(p, 'hell')


def test_nur_was_react_native_svg_kann():
    svg = zeichne(PILOT['f8364853'], 'dunkel')
    assert set(re.findall(r'<([a-z]+)\b', svg)) <= {'svg', 'rect', 'line', 'text', 'g'}
    assert 'style=' not in svg and 'class=' not in svg and 'rgba(' not in svg


def test_keine_zahl_ausser_den_massen():
    # Die Skizzen-Koordinaten (7, 4, 11 …) duerfen nirgends als Text auftauchen.
    texte = re.findall(r'>([^<]+)</text>', zeichne(PILOT['11390e1a'], 'dunkel'))
    assert sorted(texte) == ['4 cm', '4 cm', 'x cm']


@pytest.mark.parametrize('was, params', [
    ('ohne kontur', {'rechtecke': [R(0, 0, 1, 1, 'gestrichelt')]}),
    ('unbekannter Stil', {'rechtecke': [R(0, 0, 1, 1, 'gepunktet')]}),
    ('negative Breite', {'rechtecke': [R(0, 0, -1, 1)]}),
    ('fehlender Schluessel', {'rechtecke': [{'x': 0, 'y': 0, 'b': 1, 'stil': 'kontur'}]}),
    ('unbekannter Schluessel', {'rechtecke': [R(0, 0, 1, 1)], 'gitter': True}),
    ('schraeges Mass', {'rechtecke': [R(0, 0, 1, 1)], 'masse': [M((0, 0), (1, 1), 'a', 'unten')]}),
    ('Mass falsche Seite', {'rechtecke': [R(0, 0, 1, 1)], 'masse': [M((0, 0), (1, 0), 'a', 'links')]}),
    ('Mass rueckwaerts', {'rechtecke': [R(0, 0, 1, 1)], 'masse': [M((1, 0), (0, 0), 'a', 'unten')]}),
    ('leerer Text', {'rechtecke': [R(0, 0, 1, 1)], 'texte': [T(0, 0, ' ')]}),
    ('Koordinate zu gross', {'rechtecke': [R(0, 0, 500, 1)]}),
])
def test_ungueltige_parameter_werfen(was, params):
    with pytest.raises(ValueError):
        zeichne(params, 'dunkel')


def test_theme_in_params_wird_abgewiesen():
    with pytest.raises(ValueError):
        zeichne({**PILOT['11390e1a'], 'theme': 'hell'}, 'dunkel')


# ── Negativkontrolle ─────────────────────────────────────────────────────────

def _erste_zahl_in(svg: str, tag: str, attr: str, delta: float) -> str:
    m = re.search(rf'<{tag} [^>]*\b{attr}="([\d.-]+)"', svg)
    alt = m.group(0)
    neu = alt[: -len(m.group(1)) - 1] + f'{float(m.group(1)) + delta:g}"'
    return svg.replace(alt, neu, 1)


def _gitter(svg: str) -> str:
    zeilen = ''.join(f'<line x1="0" y1="{y}" x2="320" y2="{y}" stroke="#E8E8E5" stroke-width="1"/>' for y in (60, 80))
    return svg.replace('</svg>', zeilen + '</svg>')


NEGATIV = [
    ('Rechteck verschoben', '11390e1a', lambda s: _erste_zahl_in(s, 'rect', 'x', 15), 'e:'),
    ('Rechteck gestaucht', '113aea0a', lambda s: _erste_zahl_in(s, 'rect', 'height', -30), 'e:'),
    ('Stil vertauscht', '113aea0a', lambda s: s.replace(' stroke-dasharray="6 4"', ''), 'e:'),
    ('Masslinie auf der falschen Seite', '11390e1a', lambda s: _erste_zahl_in(s, 'line', 'y1', -24), 'm:'),
    ('Masstext vertauscht', 'f8364853', lambda s: s.replace('>(x - 1) m<', '>(x + 1) m<'), 't:'),
    ('Loesung als Text', '5b36238f', lambda s: s.replace('>?</text>', '>2,5 m</text>'), 't:'),
    ('Zusatztext', '3a42b89c', lambda s: s.replace('</svg>', '<text x="100" y="100" fill="#4A4A47" font-family="x" font-size="15" text-anchor="middle" dominant-baseline="middle">11 cm</text></svg>'), 't:'),
    ('Gitter', 'f8364853', _gitter, 'g:'),
    ('Endstrich fehlt', '11390e1a', lambda s: s.replace(re.findall(r'<line [^>]*/>', s)[1], '', 1), 'm:'),
]


@pytest.mark.parametrize('was, name, mutation, code', NEGATIV, ids=[n[0] for n in NEGATIV])
def test_negativkontrolle_schlaegt_an(was, name, mutation, code):
    params = PILOT[name]
    heil = zeichne(params, 'dunkel')
    kaputt = mutation(heil)
    assert kaputt != heil, f'Mutation {was!r} hat nichts veraendert'
    bestanden, meldung = pruefe(kaputt, params)
    assert not bestanden, f'{was}: pruefe hat nicht angeschlagen'
    assert code in meldung, f'{was}: erwartet Befund {code}, bekommen: {meldung}'


def test_direkter_aufruf_mit_theme():
    assert rechtecke(theme='hell', **PILOT['5b36238f']) == zeichne(PILOT['5b36238f'], 'hell')
