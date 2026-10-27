#!/usr/bin/env python3
"""
Tests fuer den Parabel-Generator (Sessionreihe 1).

    python3 -m pytest scripts/figures/test_parabel.py -q

Gueltige Parabeln bestehen `pruefe` in beiden Themes. Jede der drei eigenen Pruefungen (Scheitel, Nullstellen,
Achsenbeschriftung) schlaegt fuer sich allein an, wenn Text und Bild nicht zusammenpassen.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.parabel import koordinaten_params, normalform, nullstellen, zeichne  # noqa: E402
from figures.pruefe_parabel import (  # noqa: E402
    negativkontrolle, pruefe, pruefe_achsenbeschriftung, pruefe_nullstellen, pruefe_scheitel,
)
from figures.tokens import THEMES  # noqa: E402

GUELTIG = [
    dict(a=1, d=0, e=0, x_min=-4, x_max=4, y_min=-1, y_max=9),
    dict(a=1, d=2, e=-4, x_min=-3, x_max=6, y_min=-5, y_max=6, nullstellen=True, scheitel=True),
    dict(a=-1, d=-3, e=2, x_min=-7, x_max=2, y_min=-6, y_max=4, nullstellen=True),
    dict(a=2, d=1, e=1, x_min=-2, x_max=4, y_min=-1, y_max=9),           # keine Nullstelle
    dict(a=0.5, d=0, e=-2, x_min=-4, x_max=4, y_min=-3, y_max=6, gerade_c=2),
    dict(a=-2, d=1, e=0, x_min=-2, x_max=4, y_min=-8, y_max=2, nullstellen=True),  # doppelte Nullstelle
]


@pytest.mark.parametrize('params', GUELTIG)
@pytest.mark.parametrize('theme', THEMES)
def test_gueltige_parabeln_bestehen(params, theme):
    ok, meldung = pruefe(zeichne(params, theme), params)
    assert ok, meldung


def test_normalform_und_nullstellen():
    assert normalform(2, 1, -8) == (2, -4, -6)
    assert nullstellen(1, 2, -4) == [0, 4]
    assert nullstellen(-2, 1, 0) == [1]
    assert nullstellen(2, 1, 1) == []


def test_scheitel_schlaegt_allein_an():
    p = dict(a=1, d=2, e=-4, x_min=-3, x_max=6, y_min=-5, y_max=6)
    assert pruefe_scheitel(zeichne(p, 'dunkel'), p) == []
    assert pruefe_scheitel(zeichne(p, 'dunkel'), {**p, 'd': 3})
    assert pruefe_scheitel(zeichne(p, 'dunkel'), {**p, 'a': -1})


def test_nullstellen_schlaegt_allein_an():
    p = dict(a=1, d=2, e=-4, x_min=-3, x_max=6, y_min=-5, y_max=6)
    assert pruefe_nullstellen(zeichne(p, 'dunkel'), p) == []
    assert pruefe_nullstellen(zeichne(p, 'dunkel'), {**p, 'e': -1})   # andere Nullstellen
    assert pruefe_nullstellen(zeichne(p, 'dunkel'), {**p, 'e': 4})    # behauptet keine, Bild hat zwei


def test_achsenbeschriftung_schlaegt_allein_an():
    p = dict(a=1, d=0, e=0, x_min=-4, x_max=4, y_min=-1, y_max=9)
    svg = zeichne(p, 'dunkel')
    assert pruefe_achsenbeschriftung(svg, p) == []
    assert pruefe_achsenbeschriftung(re.sub(r'>\s*y\s*</text>', '></text>', svg), p)


def test_negativkontrolle_schlaegt_ueberall_an():
    for name, angeschlagen, befunde in negativkontrolle():
        assert angeschlagen, name


def test_eingaben_werden_geprueft():
    with pytest.raises(ValueError):
        koordinaten_params(dict(a=0, d=0, e=0, x_min=-1, x_max=1, y_min=-1, y_max=1))
    with pytest.raises(ValueError):
        koordinaten_params(dict(a=1, d=0, e=0, x_min=-1, x_max=1, y_min=-1, y_max=1, farbe='rot'))
    with pytest.raises(ValueError):
        zeichne(dict(a=1, d=0, e=0, x_min=-1, x_max=1, y_min=-1, y_max=1, theme='hell'), 'dunkel')
