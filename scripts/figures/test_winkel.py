#!/usr/bin/env python3
"""
Tests fuer den Winkel-Generator.

    python3 -m pytest scripts/figures/test_winkel.py -q

Geprueft wird das, was ein Mensch an einer Abbildung NICHT nachsieht: die
gemessene Winkelweite, die Seite, auf der der Bogen liegt, der Determinismus —
und die Frage, ob der Generator laut wird, wenn etwas nicht darstellbar ist,
statt still eine falsche Figur zu liefern.

Die Geometriepruefungen selbst stehen in `pruefe_winkel.py` (der Upload braucht
sie), hier werden sie nur aufgerufen: einmal auf JEDEM ganzzahligen Winkel von 1
bis 359 (sie duerfen nichts finden) und einmal ueber die Negativkontrolle
(sie MUESSEN anschlagen).
"""

from __future__ import annotations

import math
import re
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.pruefe_winkel import (  # noqa: E402
    negativkontrolle,
    pruefe,
    pruefe_geometrie,
)
from figures.tokens import THEMES, pruefe_drift  # noqa: E402
from figures.winkel import BREITE, HOEHE, winkel, zeichne  # noqa: E402

# Die Parameterkombinationen, die es gibt: Bogen ja/nein, Benennung ja/nein.
VARIANTEN: list[dict] = [
    {},
    {'benennung': 'alpha'},
    {'mit_bogen': False},
    {'benennung': 'beta', 'mit_bogen': False},
]

# Randwerte je Parameter plus die fachlich heiklen Lagen dazwischen.
RANDWERTE: list[float] = [
    1,        # kleinster erlaubter Winkel
    359,      # groesster erlaubter Winkel
    89,       # knapp unter dem rechten
    90,       # genau rechter Winkel -> rechteckiges Zeichen
    91,       # knapp darueber
    179,
    180,      # gestreckter Winkel: BEIDE Schenkel waagerecht
    181,      # ab hier ueberstumpf, der Bogen liegt aussen
    270,
    1.5,      # Nachkommastellen
    44.55,    # rundet in der Gradzahl auf zwei Stellen
]


def _texte(svg: str) -> list[str]:
    return re.findall(r'<text[^>]*>(.*?)</text>', svg)


def _polylinien(svg: str) -> list[list[tuple[float, float]]]:
    aus = []
    for treffer in re.finditer(r'<polyline points="([^"]+)"', svg):
        werte = [float(t) for t in re.findall(r'-?\d+(?:\.\d+)?', treffer.group(1))]
        aus.append([(werte[i], werte[i + 1]) for i in range(0, len(werte) - 1, 2)])
    return aus


def _ohne_farben(text: str) -> str:
    """Farbe UND Deckkraft entfernen, Leerraum einebnen — was bleibt, ist die
    Geometrie. 'dunkel' fuehrt abgestufte Cream-Toene, 'hell' deckende; bliebe
    das stehen, meldete der Vergleich einen Unterschied, der keiner ist."""
    return re.sub(r'\s+', ' ', re.sub(r'(?:stroke|fill)(?:-opacity)?="[^"]*"', '', text))


# ── Gueltige Parameter ───────────────────────────────────────────────────────

def test_gueltiges_svg():
    svg = winkel(45, benennung='alpha')
    assert svg.startswith('<svg xmlns="http://www.w3.org/2000/svg"')
    assert svg.rstrip().endswith('</svg>')
    assert svg.count('<svg') == svg.count('</svg>') == 1
    # Zwei Schenkel, ein Bogen, zwei Textknoten.
    assert len(re.findall(r'<line\b', svg)) == 2
    assert len(re.findall(r'<polyline\b', svg)) == 1
    assert _texte(svg) == ['45°', 'alpha']
    assert pruefe(svg, {'grad': 45, 'benennung': 'alpha'}) == (True, 'ok')


def test_schenkel_vom_scheitel_und_grundschenkel_waagerecht():
    """Beide Schenkel starten im selben Punkt, der erste liegt waagerecht."""
    linien = re.findall(
        r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"',
        winkel(60),
    )
    (ax1, ay1, ax2, ay2), (bx1, by1, _, _) = (
        tuple(float(w) for w in linien[0]),
        tuple(float(w) for w in linien[1]),
    )
    assert (ax1, ay1) == (bx1, by1)
    assert ay1 == ay2, 'Grundschenkel nicht waagerecht.'
    assert ax2 > ax1, 'Grundschenkel zeigt nicht nach rechts.'


@pytest.mark.parametrize('grad', RANDWERTE)
@pytest.mark.parametrize('variante', VARIANTEN, ids=lambda v: '+'.join(v) or 'nur-grad')
def test_randwerte_bestehen_die_geometriepruefung(grad, variante):
    params = dict(grad=grad, **variante)
    for theme in THEMES:
        assert pruefe_geometrie(zeichne(params, theme), params) == []


def test_jeder_ganze_grad_von_1_bis_359():
    """
    Die Vollprobe. 110 und 250 Grad haben dieselben Schenkel und
    unterscheiden sich nur in der Seite des Bogens — ein Stichprobentest
    koennte die halbe Skala verfehlen.
    """
    schlecht = {
        grad: befunde
        for grad in range(1, 360)
        if (befunde := pruefe_geometrie(winkel(grad), {'grad': grad}))
    }
    assert schlecht == {}


@pytest.mark.parametrize('grad', [110, 250])
def test_bogen_liegt_bei_ueberstumpfem_winkel_aussen(grad):
    """
    Der Kern der Sache: bei 250 Grad muss der Bogen durch die UNTERE
    Halbebene laufen (aussen herum), bei 110 Grad nicht. Waere er innen,
    zeigte die Figur den Gegenwinkel — bei gleichen Schenkeln, gleicher
    Groesse, gleichem Aussehen.
    """
    zug = _polylinien(winkel(grad))[0]
    unterhalb = [punkt for punkt in zug if punkt[1] > 150.0 + 0.5]
    if grad > 180:
        assert unterhalb, 'ueberstumpfer Winkel: Bogen laeuft nicht aussen herum.'
    else:
        assert not unterhalb, 'spitzer/stumpfer Winkel: Bogen laeuft aussen herum.'


def test_rechter_winkel_hat_zeichen_statt_bogen():
    recht = winkel(90)
    assert '<polyline' not in recht, 'bei 90 Grad steht ein Bogen statt des Zeichens.'
    assert len(re.findall(r'<line\b', recht)) == 4, 'Zeichen fehlt (zwei kurze Striche).'
    # Der Gegenfall, damit das Zeichen nicht ueberall auftaucht.
    for grad in (89, 91, 90.5):
        assert len(_polylinien(winkel(grad))) == 1
        assert len(re.findall(r'<line\b', winkel(grad))) == 2


def test_ohne_bogen_keine_gradzahl():
    """
    mit_bogen=False ist die Form fuer "Wie gross ist dieser Winkel?". Stuende
    die Zahl im Bild, waere die Antwort mitgeliefert.
    """
    svg = winkel(50, benennung='alpha', mit_bogen=False)
    assert '°' not in svg
    assert '<polyline' not in svg
    assert len(re.findall(r'<line\b', svg)) == 2
    assert _texte(svg) == ['alpha']


def test_gradzahl_traegt_den_wert():
    assert _texte(winkel(45))[0] == '45°'
    assert _texte(winkel(44.55))[0] == '44,55°', 'Dezimalkomma fehlt.'
    assert _texte(winkel(120.5))[0] == '120,5°'


def test_fremdtext_wird_escaped():
    svg = winkel(30, benennung='<a & b>')
    assert '&lt;a &amp; b&gt;' in svg
    assert '<a & b>' not in svg


# ── Fester Rahmen ────────────────────────────────────────────────────────────

@pytest.mark.parametrize('grad', [1, 90, 180, 359])
def test_rahmen_haengt_nicht_an_den_parametern(grad):
    svg = winkel(grad, benennung='alpha')
    assert f'width="{BREITE}" height="{HOEHE}"' in svg
    assert f'viewBox="0 0 {BREITE} {HOEHE}"' in svg


def test_alles_liegt_im_rahmen():
    """Ein Schenkel oder Text ausserhalb wuerde weggeschnitten — die Abbildung
    waere unauffaellig unvollstaendig."""
    for grad in range(1, 360):
        svg = winkel(grad, benennung='alpha')
        zahlen = [
            (float(m.group(1)), float(m.group(2)))
            for m in re.finditer(r'<(?:line|text) x1?="([\d.-]+)" y1?="([\d.-]+)"', svg)
        ]
        for zug in _polylinien(svg):
            zahlen.extend(zug)
        for x, y in zahlen:
            assert 0 <= x <= BREITE and 0 <= y <= HOEHE, f'{grad} Grad: ({x}, {y})'


# ── Determinismus ────────────────────────────────────────────────────────────

def test_gleiche_parameter_gleiche_bytes():
    argumente = dict(grad=137.5, benennung='alpha', mit_bogen=True)
    laeufe = [winkel(**argumente) for _ in range(3)]
    assert laeufe[0] == laeufe[1] == laeufe[2]
    # Auf ZIFFER-e-ZIFFER pruefen, nicht auf 'e-': das traefe sonst
    # 'stroke-width' und meldete einen Fehler, den es nicht gibt.
    assert not re.search(r'\d[eE][+-]?\d', laeufe[0]), 'Exponentialschreibweise im Output.'
    assert '-0"' not in laeufe[0] and '-0,' not in laeufe[0] and '-0 ' not in laeufe[0]
    assert not re.search(r'20\d\d-\d\d-\d\d|\d\d:\d\d:\d\d', laeufe[0]), 'Zeitstempel im SVG.'
    # Der Weg, den upload_figures.py nimmt, muss dieselben Bytes liefern.
    assert zeichne(argumente, 'dunkel') == laeufe[0]


# ── Beide Themes ─────────────────────────────────────────────────────────────

@pytest.mark.parametrize('theme', THEMES)
def test_theme_farben_sind_svg_gueltig(theme):
    svg = winkel(70, benennung='alpha', theme=theme)
    # REGRESSION (Inkscape-Probe 23.07.2026): rgba() ist in SVG-1.1-
    # Praesentationsattributen ungueltig. Renderer verwerfen den Wert und
    # zeichnen SCHWARZ — auf der dunklen Buehne unsichtbar.
    assert 'rgba(' not in svg and 'hsl(' not in svg
    for wert in re.findall(r'(?:stroke|fill)="([^"]+)"', svg):
        assert wert == 'none' or re.fullmatch(r'#[0-9A-F]{6}', wert), wert
    assert 'Schibsted Grotesk, Helvetica, Arial, sans-serif' in svg


def test_themes_unterscheiden_sich_nur_in_der_farbe():
    assert (_ohne_farben(winkel(70, benennung='alpha', theme='dunkel'))
            == _ohne_farben(winkel(70, benennung='alpha', theme='hell')))
    assert '#D4A843' in winkel(70, theme='dunkel'), 'dunkel: Bogen nicht in Altgold.'
    assert '#DA9721' in winkel(70, theme='hell'), 'hell: Bogen nicht in Report-Gold.'


def test_kein_hintergrund_und_nichts_was_react_native_svg_nicht_kann():
    svg = winkel(70, benennung='alpha')
    for verboten in ('<rect', '<foreignObject', '<style', 'class=', 'style=', '@font-face', 'url('):
        assert verboten not in svg, f'{verboten} im SVG.'


def test_tokens_ohne_drift():
    assert pruefe_drift() == []


# ── Laute Fehler statt stiller Bilder ────────────────────────────────────────

@pytest.mark.parametrize('was, argumente', [
    ('grad 0', dict(grad=0)),
    ('grad 360', dict(grad=360)),
    ('grad negativ', dict(grad=-45)),
    ('grad knapp unter 1', dict(grad=0.5)),
    ('grad knapp ueber 359', dict(grad=359.5)),
    ('grad als Text', dict(grad='45')),
    ('grad als bool', dict(grad=True)),
    ('grad fehlt nicht, ist aber None', dict(grad=None)),
    ('grad unendlich', dict(grad=math.inf)),
    ('grad NaN', dict(grad=math.nan)),
    ('benennung leer', dict(grad=45, benennung='')),
    ('benennung nur Leerraum', dict(grad=45, benennung='   ')),
    ('benennung als Zahl', dict(grad=45, benennung=7)),
    ('mit_bogen als Zahl', dict(grad=45, mit_bogen=1)),
    ('mit_bogen als Text', dict(grad=45, mit_bogen='ja')),
    ('unbekanntes theme', dict(grad=45, theme='sepia')),
])
def test_ungueltige_parameter_werfen(was, argumente):
    with pytest.raises(ValueError):
        winkel(**argumente)


@pytest.mark.parametrize('was, params', [
    ('kein dict', ['grad', 45]),
    ('theme in params', {'grad': 45, 'theme': 'hell'}),
    ('Tippfehler im Schluessel', {'grad': 45, 'benenung': 'alpha'}),
    ('grad fehlt', {'benennung': 'alpha'}),
    ('leere params', {}),
])
def test_zeichne_weist_falsche_params_ab(was, params):
    with pytest.raises(ValueError):
        zeichne(params, 'dunkel')


# ── Negativkontrolle ─────────────────────────────────────────────────────────

def test_negativkontrolle_schlaegt_bei_kaputter_ausgabe_an():
    """
    Der Gegenbeweis zur Vollprobe: absichtlich verfaelschte SVGs (eine
    Koordinate verschoben, der Bogen von der falschen Seite, ein Zahlendreher in
    der Gradzahl) MUESSEN abgelehnt werden. Ohne diese Kontrolle ist nicht
    belegt, dass die Pruefung ueberhaupt greifen kann.
    """
    faelle = negativkontrolle()
    assert len(faelle) >= 5
    still = [name for name, angeschlagen, _ in faelle if not angeschlagen]
    assert still == [], f'Pruefung blieb still bei: {still}'


def test_pruefe_meldet_die_befunde_weiter():
    """upload_figures.py laedt nur, was `pruefe` besteht — und braucht im
    Fehlerfall eine Meldung, die etwas sagt."""
    svg = winkel(60)
    zweiter = re.findall(r'<line\b[^>]*/>', svg)[1]
    verdreht = re.sub(
        r'y2="([\d.-]+)"', lambda m: f'y2="{float(m.group(1)) + 25}"', zweiter,
    )
    bestanden, meldung = pruefe(svg.replace(zweiter, verdreht, 1), {'grad': 60})
    assert bestanden is False
    assert 'w)' in meldung and '60' in meldung


# ── Der Weg, den upload_figures.py nimmt ─────────────────────────────────────

def test_flach_importierbar():
    """
    `_lade_generator` legt scripts/figures auf sys.path und macht
    `import winkel`. Dann gibt es kein Elternpaket — die relativen Importe im
    Modul muessen das ueberleben, sonst faellt der Upload beim ersten Winkel um.
    """
    wurzel = Path(__file__).resolve().parents[2]
    ergebnis = subprocess.run(
        [sys.executable, '-c',
         'import sys; sys.path.insert(0, "scripts/figures");'
         'import winkel, pruefe_winkel;'
         'svg = winkel.zeichne({"grad": 30}, "hell");'
         'print(pruefe_winkel.pruefe(svg, {"grad": 30}))'],
        cwd=wurzel, capture_output=True, text=True,
    )
    assert ergebnis.returncode == 0, ergebnis.stderr
    assert ergebnis.stdout.strip() == "(True, 'ok')"
