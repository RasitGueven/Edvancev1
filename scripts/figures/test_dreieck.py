#!/usr/bin/env python3
"""
Tests fuer den Dreieck-Generator.

    python3 -m pytest scripts/figures/test_dreieck.py -q

Geprueft wird das, was ein Mensch an einer Abbildung NICHT nachsieht: die
Massstaeblichkeit, die Kappung ueber 1:4 samt Zickzack, die Lage des
rechtwinkligen Zeichens, der Determinismus — und die Frage, ob der Generator
laut wird, wenn etwas nicht darstellbar ist, statt still eine falsche Figur zu
liefern.

Die Geometriepruefungen selbst stehen in `pruefe_dreieck.py` (der Upload braucht
sie), hier werden sie nur aufgerufen: einmal ueber ein breites Feld von
Parameterkombinationen (sie duerfen nichts finden) und einmal ueber die
Negativkontrolle (sie MUESSEN anschlagen).
"""

from __future__ import annotations

import math
import re
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.dreieck import (  # noqa: E402
    ARTEN,
    BREITE,
    HOEHE,
    MASS_MAX,
    MASS_MIN,
    VERHAELTNIS_MAX,
    dreieck,
    zeichne,
)
from figures.pruefe_dreieck import (  # noqa: E402
    negativkontrolle,
    pruefe,
    pruefe_geometrie,
)
from figures.tokens import THEMES, pruefe_drift  # noqa: E402

# Randwerte je Parameter plus die fachlich heiklen Lagen dazwischen. Die Paare
# stehen als (grundseite, hoehe).
RANDWERTE: list[tuple[float, float]] = [
    (MASS_MIN, MASS_MIN),          # kleinste erlaubte Masse
    (MASS_MAX, MASS_MAX),          # groesste erlaubte Masse
    (MASS_MIN, MASS_MAX),          # extrem hoch  -> gekappt
    (MASS_MAX, MASS_MIN),          # extrem flach -> gekappt
    (8, 5),                        # Alltagsfall
    (8, 8),                        # Verhaeltnis 1
    (8, 32),                       # GENAU 1:4 — noch nicht gekappt
    (32, 8),                       # GENAU 4:1 — noch nicht gekappt
    (8, 32.01),                    # knapp darueber -> gekappt
    (32.01, 8),                    # knapp darunter -> gekappt
    (0.5, 0.25),                   # kleine Masse mit Nachkommastellen
    (12.5, 7.25),                  # zwei Nachkommastellen
    (999, 1),                      # gekappt, grosse Zahl im Text
]

EINHEITEN = ['cm', 'm', 'mm', 'abcd']


def _polylinien(svg: str) -> list[list[tuple[float, float]]]:
    aus = []
    for treffer in re.finditer(r'<polyline points="([^"]+)"', svg):
        werte = [float(t) for t in re.findall(r'-?\d+(?:\.\d+)?', treffer.group(1))]
        aus.append([(werte[i], werte[i + 1]) for i in range(0, len(werte) - 1, 2)])
    return aus


def _texte(svg: str) -> list[str]:
    return re.findall(r'<text[^>]*>(.*?)</text>', svg)


def _ecken(svg: str) -> tuple[tuple[float, float], tuple[float, float], tuple[float, float]]:
    """(linke Grundecke, rechte Grundecke, Spitze) aus dem Umriss."""
    umriss = [zug for zug in _polylinien(svg) if len(zug) == 4][0]
    ecken = umriss[:3]
    unten = max(y for _, y in ecken)
    grund = sorted(punkt for punkt in ecken if punkt[1] == unten)
    spitze = [punkt for punkt in ecken if punkt[1] != unten][0]
    return grund[0], grund[1], spitze


def _pixelmasse(svg: str) -> tuple[float, float]:
    a, b, spitze = _ecken(svg)
    return b[0] - a[0], a[1] - spitze[1]


def _ohne_farben(text: str) -> str:
    """Farbe UND Deckkraft entfernen, Leerraum einebnen — was bleibt, ist die
    Geometrie. 'dunkel' fuehrt abgestufte Cream-Toene, 'hell' deckende; bliebe
    das stehen, meldete der Vergleich einen Unterschied, der keiner ist."""
    return re.sub(r'\s+', ' ', re.sub(r'(?:stroke|fill)(?:-opacity)?="[^"]*"', '', text))


# ── Gueltige Parameter ───────────────────────────────────────────────────────

def test_gueltiges_svg():
    svg = dreieck(8, 5)
    assert svg.startswith('<svg xmlns="http://www.w3.org/2000/svg"')
    assert svg.rstrip().endswith('</svg>')
    assert svg.count('<svg') == svg.count('</svg>') == 1
    # Umriss + rechtwinkliges Zeichen, gestrichelte Hoehe + zwei Masslinien,
    # zwei Masstexte.
    assert len(re.findall(r'<polyline\b', svg)) == 2
    assert len(re.findall(r'<line\b', svg)) == 3
    assert _texte(svg) == ['8 cm', '5 cm']
    assert pruefe(svg, {'grundseite': 8, 'hoehe': 5}) == (True, 'ok')


@pytest.mark.parametrize('grundseite, hoehe', RANDWERTE)
@pytest.mark.parametrize('art', ARTEN)
def test_randwerte_bestehen_die_geometriepruefung(grundseite, hoehe, art):
    params = {'grundseite': grundseite, 'hoehe': hoehe, 'art': art}
    for theme in THEMES:
        assert pruefe_geometrie(zeichne(params, theme), params) == []


@pytest.mark.parametrize('einheit', EINHEITEN)
def test_einheiten_bestehen_die_geometriepruefung(einheit):
    params = {'grundseite': 7.5, 'hoehe': 3.25, 'einheit': einheit}
    assert pruefe_geometrie(zeichne(params, 'dunkel'), params) == []
    assert _texte(dreieck(7.5, 3.25, einheit=einheit)) == [f'7,5 {einheit}', f'3,25 {einheit}']


def test_grundseite_waagerecht_und_spitze_darueber():
    a, b, spitze = _ecken(dreieck(8, 5))
    assert a[1] == b[1], 'Grundseite nicht waagerecht.'
    assert b[0] > a[0], 'Grundseite zeigt nicht nach rechts.'
    assert spitze[1] < a[1], 'Spitze liegt nicht ueber der Grundseite.'


# ── Massstaeblichkeit und Kappung ────────────────────────────────────────────

@pytest.mark.parametrize('grundseite, hoehe', [
    (8, 2), (8, 5), (8, 8), (8, 32), (32, 8), (10, 2.5), (3, 7), (999, 400),
])
def test_pixelverhaeltnis_entspricht_dem_sachverhaeltnis(grundseite, hoehe):
    """
    Der Kern der Sache: solange das Verhaeltnis innerhalb 1:4 liegt, misst die
    gezeichnete Hoehe genau denselben Anteil der gezeichneten Grundseite wie
    hoehe von grundseite. Sonst bekommt ein Kind, das mit dem Lineal nachmisst,
    eine andere Antwort als die Aufgabe erwartet.
    """
    grund_px, hoehe_px = _pixelmasse(dreieck(grundseite, hoehe))
    assert math.isclose(hoehe_px / grund_px, hoehe / grundseite, abs_tol=0.001)
    assert not [zug for zug in _polylinien(dreieck(grundseite, hoehe)) if len(zug) == 5], \
        'Zickzack, obwohl nichts gekappt wurde.'


@pytest.mark.parametrize('grundseite, hoehe, gekappt_auf', [
    (2, 40, VERHAELTNIS_MAX),            # zu hoch
    (40, 2, 1 / VERHAELTNIS_MAX),        # zu flach
    (1, 999, VERHAELTNIS_MAX),
    (999, 1, 1 / VERHAELTNIS_MAX),
])
def test_ueber_1_zu_4_wird_gekappt_und_zeigt_es(grundseite, hoehe, gekappt_auf):
    """
    Ueber 1:4 wird auf den Bandrand gekappt — und die Figur SAGT es. Eine stille
    Stauchung waere der Fehler, den niemand nachsieht.
    """
    svg = dreieck(grundseite, hoehe)
    grund_px, hoehe_px = _pixelmasse(svg)
    assert math.isclose(hoehe_px / grund_px, gekappt_auf, abs_tol=0.005)
    zacken = [zug for zug in _polylinien(svg) if len(zug) == 5]
    assert len(zacken) == 1, 'gekappt, aber kein Zickzack — stille Stauchung.'


def test_genau_1_zu_4_wird_noch_nicht_gekappt():
    """Die Grenze gehoert zum massstaeblichen Bereich, sonst traegt jede
    Viertel-Figur ohne Not das Zeichen fuer "nicht massstaeblich"."""
    for grundseite, hoehe in ((8, 32), (32, 8)):
        svg = dreieck(grundseite, hoehe)
        assert not [zug for zug in _polylinien(svg) if len(zug) == 5]
        grund_px, hoehe_px = _pixelmasse(svg)
        assert math.isclose(hoehe_px / grund_px, hoehe / grundseite, abs_tol=0.001)


# ── Die drei Arten ───────────────────────────────────────────────────────────

def test_gleichschenklig_hat_gleich_lange_schenkel():
    a, b, spitze = _ecken(dreieck(8, 5, art='gleichschenklig'))
    assert math.isclose(math.dist(a, spitze), math.dist(b, spitze), abs_tol=0.01)


def test_rechtwinklig_hat_den_rechten_winkel_an_der_linken_grundecke():
    svg = dreieck(8, 5, art='rechtwinklig')
    a, b, spitze = _ecken(svg)
    assert math.isclose(spitze[0], a[0], abs_tol=0.01), 'Spitze nicht ueber der linken Ecke.'
    # Die linke Kathete IST die Hoehe — eine zusaetzliche gestrichelte Linie
    # laege exakt auf ihr und machte die Seite halb durchgezogen, halb
    # gestrichelt.
    assert 'stroke-dasharray' not in svg
    assert len(re.findall(r'<line\b', svg)) == 2, 'mehr als die zwei Masslinien.'
    # Das Winkelzeichen sitzt an dieser Ecke.
    zeichen = [zug for zug in _polylinien(svg) if len(zug) == 3][0]
    assert min(math.dist(a, punkt) for punkt in zeichen) <= 12.01


def test_beliebig_ist_weder_gleichschenklig_noch_rechtwinklig_gezeichnet():
    a, b, spitze = _ecken(dreieck(8, 5, art='beliebig'))
    assert not math.isclose(math.dist(a, spitze), math.dist(b, spitze), abs_tol=1.0)
    assert a[0] < spitze[0] < b[0], 'Hoehenfusspunkt liegt nicht innen.'


@pytest.mark.parametrize('art', ARTEN)
def test_hoehe_steht_senkrecht_auf_der_grundseite(art):
    """Skalarprodukt aus Grundseitenrichtung und Hoehenrichtung nahe null —
    bei 'rechtwinklig' gemessen an der linken Kathete, sonst an der
    gestrichelten Linie."""
    svg = dreieck(8, 5, art=art)
    a, b, spitze = _ecken(svg)
    if art == 'rechtwinklig':
        hoch, tief = spitze, a
    else:
        koord = re.search(
            r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"[^>]*'
            r'stroke-dasharray', svg,
        )
        x1, y1, x2, y2 = (float(g) for g in koord.groups())
        hoch, tief = (x1, y1), (x2, y2)
    grund = (b[0] - a[0], b[1] - a[1])
    hoehe = (hoch[0] - tief[0], hoch[1] - tief[1])
    assert abs(grund[0] * hoehe[0] + grund[1] * hoehe[1]) < 0.01


# ── Masstexte ────────────────────────────────────────────────────────────────

def test_masstexte_tragen_die_werte():
    assert _texte(dreieck(8, 5)) == ['8 cm', '5 cm']
    assert _texte(dreieck(12.5, 7.25, einheit='m')) == ['12,5 m', '7,25 m'], 'Dezimalkomma fehlt.'
    assert _texte(dreieck(MASS_MIN, MASS_MAX)) == ['0,01 cm', '999 cm']


# ── Fester Rahmen ────────────────────────────────────────────────────────────

@pytest.mark.parametrize('grundseite, hoehe', RANDWERTE)
def test_rahmen_haengt_nicht_an_den_parametern(grundseite, hoehe):
    svg = dreieck(grundseite, hoehe)
    assert f'width="{BREITE}" height="{HOEHE}"' in svg
    assert f'viewBox="0 0 {BREITE} {HOEHE}"' in svg


def test_alles_liegt_im_rahmen():
    """Eine Ecke oder ein Text ausserhalb wuerde weggeschnitten — die Abbildung
    waere unauffaellig unvollstaendig."""
    for grundseite, hoehe in RANDWERTE:
        for art in ARTEN:
            svg = dreieck(grundseite, hoehe, art=art, einheit='abcd')
            punkte = [
                (float(m.group(1)), float(m.group(2)))
                for m in re.finditer(r'<(?:line|text) x1?="([\d.-]+)" y1?="([\d.-]+)"', svg)
            ]
            for treffer in re.finditer(r'<line[^>]*x2="([\d.-]+)" y2="([\d.-]+)"', svg):
                punkte.append((float(treffer.group(1)), float(treffer.group(2))))
            for zug in _polylinien(svg):
                punkte.extend(zug)
            for x, y in punkte:
                assert 0 <= x <= BREITE and 0 <= y <= HOEHE, \
                    f'{grundseite}/{hoehe} {art}: ({x}, {y})'


# ── Determinismus ────────────────────────────────────────────────────────────

def test_gleiche_parameter_gleiche_bytes():
    argumente = dict(grundseite=12.5, hoehe=7.25, art='gleichschenklig', einheit='mm')
    laeufe = [dreieck(**argumente) for _ in range(3)]
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
@pytest.mark.parametrize('art', ARTEN)
def test_theme_farben_sind_svg_gueltig(theme, art):
    svg = dreieck(8, 5, art=art, theme=theme)
    # REGRESSION (Inkscape-Probe 23.07.2026): rgba() ist in SVG-1.1-
    # Praesentationsattributen ungueltig. Renderer verwerfen den Wert und
    # zeichnen SCHWARZ — auf der dunklen Buehne unsichtbar.
    assert 'rgba(' not in svg and 'hsl(' not in svg
    for wert in re.findall(r'(?:stroke|fill)="([^"]+)"', svg):
        assert wert == 'none' or re.fullmatch(r'#[0-9A-F]{6}', wert), wert
    assert 'Schibsted Grotesk, Helvetica, Arial, sans-serif' in svg


def test_themes_unterscheiden_sich_nur_in_der_farbe():
    assert (_ohne_farben(dreieck(8, 5, theme='dunkel'))
            == _ohne_farben(dreieck(8, 5, theme='hell')))
    assert '#D4A843' in dreieck(8, 5, theme='dunkel'), 'dunkel: Hoehe nicht in Altgold.'
    assert '#DA9721' in dreieck(8, 5, theme='hell'), 'hell: Hoehe nicht in Report-Gold.'


def test_kein_hintergrund_und_nichts_was_react_native_svg_nicht_kann():
    svg = dreieck(8, 5)
    for verboten in ('<rect', '<foreignObject', '<style', 'class=', 'style=', '@font-face', 'url('):
        assert verboten not in svg, f'{verboten} im SVG.'


def test_tokens_ohne_drift():
    assert pruefe_drift() == []


# ── Laute Fehler statt stiller Bilder ────────────────────────────────────────

@pytest.mark.parametrize('was, argumente', [
    ('grundseite null', dict(grundseite=0, hoehe=5)),
    ('grundseite negativ', dict(grundseite=-8, hoehe=5)),
    ('hoehe null', dict(grundseite=8, hoehe=0)),
    ('hoehe negativ', dict(grundseite=8, hoehe=-5)),
    ('grundseite unter der Untergrenze', dict(grundseite=0.009, hoehe=5)),
    ('hoehe ueber der Obergrenze', dict(grundseite=8, hoehe=1000)),
    ('grundseite als Text', dict(grundseite='8', hoehe=5)),
    ('hoehe als bool', dict(grundseite=8, hoehe=True)),
    ('hoehe als None', dict(grundseite=8, hoehe=None)),
    ('grundseite unendlich', dict(grundseite=math.inf, hoehe=5)),
    ('hoehe NaN', dict(grundseite=8, hoehe=math.nan)),
    ('dritte Nachkommastelle', dict(grundseite=8.125, hoehe=5)),
    ('unbekannte art', dict(grundseite=8, hoehe=5, art='spitzwinklig')),
    ('art als None', dict(grundseite=8, hoehe=5, art=None)),
    ('einheit leer', dict(grundseite=8, hoehe=5, einheit='')),
    ('einheit zu lang', dict(grundseite=8, hoehe=5, einheit='Zentimeter')),
    ('einheit mit Sonderzeichen', dict(grundseite=8, hoehe=5, einheit='<b>')),
    ('einheit als Zahl', dict(grundseite=8, hoehe=5, einheit=7)),
    ('einheit als None', dict(grundseite=8, hoehe=5, einheit=None)),
    ('unbekanntes theme', dict(grundseite=8, hoehe=5, theme='sepia')),
])
def test_ungueltige_parameter_werfen(was, argumente):
    with pytest.raises(ValueError):
        dreieck(**argumente)


@pytest.mark.parametrize('was, params', [
    ('kein dict', ['grundseite', 8]),
    ('theme in params', {'grundseite': 8, 'hoehe': 5, 'theme': 'hell'}),
    ('Tippfehler im Schluessel', {'grundseite': 8, 'hoehe1': 5}),
    ('grundseite fehlt', {'hoehe': 5}),
    ('hoehe fehlt', {'grundseite': 8}),
    ('leere params', {}),
])
def test_zeichne_weist_falsche_params_ab(was, params):
    with pytest.raises(ValueError):
        zeichne(params, 'dunkel')


# ── Negativkontrolle ─────────────────────────────────────────────────────────

def test_negativkontrolle_schlaegt_bei_kaputter_ausgabe_an():
    """
    Der Gegenbeweis zur Vollprobe: absichtlich verfaelschte SVGs (eine
    Koordinate verschoben, das Zickzack entfernt, ein Zahlendreher im Masstext)
    MUESSEN abgelehnt werden. Ohne diese Kontrolle ist nicht belegt, dass die
    Pruefung ueberhaupt greifen kann.
    """
    faelle = negativkontrolle()
    assert len(faelle) >= 5
    still = [name for name, angeschlagen, _ in faelle if not angeschlagen]
    assert still == [], f'Pruefung blieb still bei: {still}'


def test_pruefe_meldet_die_befunde_weiter():
    """upload_figures.py laedt nur, was `pruefe` besteht — und braucht im
    Fehlerfall eine Meldung, die etwas sagt."""
    svg = dreieck(8, 5)
    umriss = re.findall(r'<polyline\b[^>]*/>', svg)[0]
    gestaucht = umriss.replace('86', '146', 1)
    bestanden, meldung = pruefe(svg.replace(umriss, gestaucht, 1), {'grundseite': 8, 'hoehe': 5})
    assert bestanden is False
    assert 'm)' in meldung and 'massstaeblich' in meldung


# ── Der Weg, den upload_figures.py nimmt ─────────────────────────────────────

def test_flach_importierbar():
    """
    `_lade_generator` legt scripts/figures auf sys.path und macht
    `import dreieck`. Dann gibt es kein Elternpaket — die relativen Importe im
    Modul muessen das ueberleben, sonst faellt der Upload beim ersten Dreieck um.
    """
    wurzel = Path(__file__).resolve().parents[2]
    ergebnis = subprocess.run(
        [sys.executable, '-c',
         'import sys; sys.path.insert(0, "scripts/figures");'
         'import dreieck, pruefe_dreieck;'
         'p = {"grundseite": 8, "hoehe": 5, "art": "rechtwinklig"};'
         'print(pruefe_dreieck.pruefe(dreieck.zeichne(p, "hell"), p))'],
        cwd=wurzel, capture_output=True, text=True,
    )
    assert ergebnis.returncode == 0, ergebnis.stderr
    assert ergebnis.stdout.strip() == "(True, 'ok')"
