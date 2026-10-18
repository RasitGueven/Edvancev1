#!/usr/bin/env python3
"""
Tests fuer den Thales-Generator.

    python3 -m pytest scripts/figures/test_thales.py -q

Zwei Richtungen: Gueltige Figuren muessen `pruefe` bestehen (alle Lagen von C,
beide Formen, beide Themes, die sechs Pilot-Aufgaben). Und die Negativkontrolle:
gezielt kaputt gemachte SVGs MUESSEN durchfallen — eine Pruefung, die nie
anschlaegt, prueft nichts.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.pruefe_thales import ecken, pruefe, pruefe_geometrie  # noqa: E402
from figures.svg_basis import zahl  # noqa: E402
from figures.thales import ABSTAND_MIN, BREITE, HOEHE, punkte, thales, zeichne  # noqa: E402
from figures.svg_basis import pruefe_knapper_rahmen  # noqa: E402
from figures.tokens import THEMES  # noqa: E402


def w(ecke, schenkel, text):
    return {'ecke': ecke, 'schenkel': list(schenkel), 'text': text}


# Die sechs Pilot-Aufgaben (docs/figuren/bedarf.json). Wahre Lage = 2·alpha.
PILOT = {
    '11aebc7c': dict(form='halbkreis', c_grad=75, wahre_lage_grad=64, mittelpunkt=False,
                     winkel=[w('A', 'CB', '32°'), w('B', 'CA', '?')]),
    '3e087e16': dict(form='kreis', c_grad=60, wahre_lage_grad=70, mc=True,
                     winkel=[w('M', 'AC', ''), w('M', 'BC', ''), w('A', 'BC', 'α = ?')]),
    '9ca300e1': dict(form='kreis', c_grad=80, wahre_lage_grad=64, mc=True,
                     winkel=[w('M', 'BC', '64°'), w('A', 'BC', 'α = ?')]),
    '9e7c1e4b': dict(form='kreis', c_grad=110, wahre_lage_grad=80, mc=True,
                     winkel=[w('A', 'BC', '40°'), w('C', 'AM', '?')]),
    '22e90366': dict(form='kreis', c_grad=70, wahre_lage_grad=56,
                     winkel=[w('A', 'BC', 'α = 28°'), w('C', 'AB', 'γ = ?')]),
    '9f171c32': dict(form='kreis', c_grad=100, wahre_lage_grad=70,
                     winkel=[w('A', 'BC', 'α = 35°'), w('B', 'AC', 'β = ?')]),
}


@pytest.mark.parametrize('name', sorted(PILOT))
@pytest.mark.parametrize('theme', THEMES)
def test_pilot_aufgaben_bestehen(name, theme):
    assert pruefe(zeichne(PILOT[name], theme), PILOT[name]) == (True, 'ok')


@pytest.mark.parametrize('form', ['kreis', 'halbkreis'])
@pytest.mark.parametrize('c_grad', range(20, 161, 5))
def test_jede_lage_von_c_besteht(form, c_grad):
    params = dict(form=form, c_grad=c_grad, wahre_lage_grad=(c_grad + 40) % 180 or 90,
                  mittelpunkt=True, mc=True,
                  winkel=[w('A', 'BC', 'α'), w('B', 'AC', 'β'), w('C', 'AB', '?'), w('M', 'BC', '')])
    assert pruefe_geometrie(zeichne(params, 'dunkel'), params) == []


def test_gleiche_parameter_gleiche_bytes():
    p = PILOT['9ca300e1']
    assert zeichne(p, 'dunkel') == zeichne(dict(p), 'dunkel')


def test_knappe_viewbox():
    # Kein Leerraum um die Figur: Tablet und Vorschau nehmen die volle Breite.
    for p in PILOT.values():
        svg = zeichne(p, 'hell')
        assert pruefe_knapper_rahmen(svg) == []
        assert f'viewBox="0 0 {BREITE} {HOEHE}"' not in svg


def test_negativkontrolle_zu_viel_rand():
    svg = zeichne(PILOT['11aebc7c'], 'dunkel')
    kopf = re.search(r'viewBox="([^"]+)"', svg).group(1)
    x, y, b, h = map(float, kopf.split())
    weit = svg.replace(f'viewBox="{kopf}"', f'viewBox="{x - 40:g} {y:g} {b + 40:g} {h:g}"').replace(
        f'width="{b:g}"', f'width="{b + 40:g}"', 1)
    bestanden, meldung = pruefe(weit, PILOT['11aebc7c'])
    assert not bestanden and 'Rand links' in meldung, meldung


def test_kein_rechter_winkel_auch_wenn_gamma_gefragt():
    svg = zeichne(PILOT['22e90366'], 'dunkel')
    assert not any(len(m.split()) == 3 for m in re.findall(r'<polyline points="([^"]+)"', svg))
    assert '90' not in ''.join(re.findall(r'>([^<]+)</text>', svg))


def test_nur_was_react_native_svg_kann():
    svg = zeichne(PILOT['3e087e16'], 'dunkel')
    tags = set(re.findall(r'<([a-z]+)\b', svg))
    assert tags <= {'svg', 'circle', 'line', 'polyline', 'text', 'g'}
    assert 'style=' not in svg and 'class=' not in svg and 'rgba(' not in svg


@pytest.mark.parametrize('was, aenderung', [
    ('C an der wahren Lage', dict(c_grad=64)),
    ('C zu nah an der wahren Lage', dict(c_grad=64 + ABSTAND_MIN - 1)),
    ('unbekannter Schluessel', dict(farbe='rot')),
    ('falsche Form', dict(form='ellipse')),
    ('C an A', dict(c_grad=5)),
    ('Winkel an M ohne M', dict(winkel=[w('M', 'BC', '')])),
    ('Schenkel MC ohne Strecke', dict(mittelpunkt=True, winkel=[w('C', 'AM', '?')])),
    ('Schenkel doppelt', dict(winkel=[w('A', 'AB', '?')])),
    ('Text fehlt', dict(winkel=[{'ecke': 'A', 'schenkel': ['B', 'C']}])),
])
def test_ungueltige_parameter_werfen(was, aenderung):
    with pytest.raises(ValueError):
        zeichne({**PILOT['11aebc7c'], **aenderung}, 'dunkel')


def test_theme_in_params_wird_abgewiesen():
    with pytest.raises(ValueError):
        zeichne({**PILOT['11aebc7c'], 'theme': 'hell'}, 'dunkel')


# ── Negativkontrolle ─────────────────────────────────────────────────────────
# Jede Mutation macht das SVG auf eine Art falsch, die man ihm nicht ansieht.
# pruefe MUSS anschlagen, und zwar mit der zustaendigen Pruefung.

def _c_verschieben(svg: str, params: dict, nach_grad: float) -> str:
    alt = punkte(params['form'], params['c_grad'])['C']
    neu = punkte(params['form'], nach_grad)['C']
    return svg.replace(f'"{zahl(alt[0])}"', f'"{zahl(neu[0])}"').replace(f'"{zahl(alt[1])}"', f'"{zahl(neu[1])}"')


def _c_vom_kreis(svg: str, params: dict) -> str:
    alt = punkte(params['form'], params['c_grad'])['C']
    return svg.replace(f'"{zahl(alt[1])}"', f'"{zahl(alt[1] - 12)}"')


def _erster_bogen_weg(svg: str) -> str:
    boegen = re.findall(r'<polyline [^>]*/>', svg)
    return svg.replace(boegen[-1], '', 1)


def _rechter_winkel_bei_c(svg: str, params: dict) -> str:
    x, y = punkte(params['form'], params['c_grad'])['C']
    zeichen = f'<polyline points="{zahl(x - 10)},{zahl(y + 4)} {zahl(x - 6)},{zahl(y + 14)} {zahl(x + 4)},{zahl(y + 10)}" fill="none" stroke="#D4A843" stroke-width="2"/>'
    return svg.replace('</svg>', zeichen + '</svg>')


def _gitterlinie(svg: str) -> str:
    return svg.replace('</svg>', '<line x1="0" y1="20" x2="320" y2="20" stroke="#F7F5EE" stroke-width="1"/></svg>')


def _text_tauschen(svg: str, alt: str, neu: str) -> str:
    return svg.replace(f'>{alt}</text>', f'>{neu}</text>')


NEGATIV = [
    ('C an die wahre Lage geschoben', '11aebc7c', lambda s, p: _c_verschieben(s, p, 64), 'p:'),
    ('C vom Kreis geschoben', '9ca300e1', _c_vom_kreis, 'p:'),
    ('Winkelbogen fehlt', '22e90366', lambda s, p: _erster_bogen_weg(s), 'w:'),
    ('Gradzahl vertauscht', '11aebc7c', lambda s, p: _text_tauschen(s, '32°', '23°'), 't:'),
    ('Fragezeichen fehlt', '9e7c1e4b', lambda s, p: _text_tauschen(s, '?', ''), 't:'),
    ('Rechter-Winkel-Zeichen bei C', '22e90366', _rechter_winkel_bei_c, 'q:'),
    ('90 im Bild', '22e90366', lambda s, p: _text_tauschen(s, 'γ = ?', 'γ = 90°'), 'q:'),
    ('Gitterlinie', '3e087e16', lambda s, p: _gitterlinie(s), 's:'),
    ('Punktname vertauscht', '3e087e16', lambda s, p: _text_tauschen(s, 'M', 'N'), 't:'),
]


@pytest.mark.parametrize('was, name, mutation, code', NEGATIV, ids=[n[0] for n in NEGATIV])
def test_negativkontrolle_schlaegt_an(was, name, mutation, code):
    params = PILOT[name]
    kaputt = mutation(zeichne(params, 'dunkel'), params)
    assert kaputt != zeichne(params, 'dunkel'), f'Mutation {was!r} hat nichts veraendert'
    bestanden, meldung = pruefe(kaputt, params)
    assert not bestanden, f'{was}: pruefe hat nicht angeschlagen'
    assert code in meldung, f'{was}: erwartet Befund {code}, bekommen: {meldung}'


def test_ecken_kommen_aus_dem_svg_nicht_aus_den_params():
    p = PILOT['9f171c32']
    e = ecken(zeichne(p, 'dunkel'))
    assert set(e) == {'A', 'B', 'C', 'M'}


def test_direkter_aufruf_mit_theme():
    assert thales(theme='hell', **PILOT['9f171c32']) == zeichne(PILOT['9f171c32'], 'hell')
