#!/usr/bin/env python3
"""
Tests fuer die Python-Seite des Rechteck-Generators: Adapter (rechteck.py ruft
rechteck.ts ueber tsx) und Pruefung (pruefe_rechteck.py).

    python3 -m pytest scripts/figures/test_rechteck.py -q

Der Generator selbst ist in tests/figur-rechteck.test.ts getestet. Hier geht es
darum, dass der Upload-Weg funktioniert und dass die Pruefung anschlaegt, wenn
das SVG nicht zu den params passt (Negativkontrolle).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.pruefe_rechteck import pruefe, pruefe_geometrie  # noqa: E402
from figures.rechteck import TSX, zeichne  # noqa: E402

pytestmark = pytest.mark.skipif(not TSX.is_file(), reason='node_modules fehlt (npm ci)')

# Die zwei Pilot-Aufgaben (docs/figuren/bedarf.json).
PILOT = {
    '46192474': {'laenge_text': 'x cm', 'breite_text': '5 cm', 'verhaeltnis': 2},
    '770f72e9': {'laenge_text': '(x + 3) cm', 'breite_text': '4 cm', 'verhaeltnis': 2},
}

ZAHLEN = [
    {'laenge': 5, 'breite': 3, 'einheit': 'cm'},
    {'laenge': 4, 'breite': 4},
    {'laenge': 2.5, 'breite': 7.25, 'einheit': 'm', 'diagonale': True},
    {'laenge': 40, 'breite': 1, 'einheit': 'cm'},  # gekappt, mit Bruchzeichen
]


@pytest.fixture(scope='module')
def svgs():
    return {k: {t: zeichne(p, t) for t in ('dunkel', 'hell')} for k, p in PILOT.items()}


@pytest.mark.parametrize('name', sorted(PILOT))
@pytest.mark.parametrize('theme', ['dunkel', 'hell'])
def test_pilot_aufgaben_bestehen(svgs, name, theme):
    assert pruefe(svgs[name][theme], PILOT[name]) == (True, 'ok')


@pytest.mark.parametrize('params', ZAHLEN, ids=lambda p: str(p))
def test_zahlen_masse_bestehen(params):
    assert pruefe_geometrie(zeichne(params, 'hell'), params) == []


def test_fehler_im_generator_wird_valueerror():
    with pytest.raises(ValueError, match='rechteck.ts'):
        zeichne({'laenge_text': 'x cm', 'breite_text': '5 cm', 'laenge': 5}, 'hell')


# ── Negativkontrolle ─────────────────────────────────────────────────────────

NEGATIV = [
    ('Text vertauscht', lambda s: s.replace('>x cm<', '>5 cm<'), 't:'),
    ('Loesung als Text', lambda s: s.replace('>x cm<', '>10 cm<'), 't:'),
    ('Seitenverhaeltnis falsch', lambda s: s.replace('x2="296"', 'x2="250"').replace('x1="296"', 'x1="250"'), 'v:'),
    ('Gitterlinie', lambda s: s.replace('</svg>', '<line x1="100" y1="60" x2="100" y2="150" stroke="#E8E8E5" stroke-width="1"/></svg>'), 'f:'),
    ('Winkelzeichen fehlt', lambda s: re.sub(r'<polyline [^>]*/>', '', s), 'w:'),
    ('Breite auf der falschen Seite', lambda s: s.replace('text-anchor="end"', 'text-anchor="start"'), 't:'),
]


@pytest.mark.parametrize('was, mutation, code', NEGATIV, ids=[n[0] for n in NEGATIV])
def test_negativkontrolle_schlaegt_an(svgs, was, mutation, code):
    heil = svgs['46192474']['dunkel']
    kaputt = mutation(heil)
    assert kaputt != heil, f'Mutation {was!r} hat nichts veraendert'
    bestanden, meldung = pruefe(kaputt, PILOT['46192474'])
    assert not bestanden, f'{was}: pruefe hat nicht angeschlagen'
    assert code in meldung, f'{was}: erwartet Befund {code}, bekommen: {meldung}'
