#!/usr/bin/env python3
"""
Tests fuer den Koordinatensystem-Generator.

Ohne Fremdbibliothek, damit der Lauf ueberall geht:
    python3 scripts/figures/test_koordinatensystem.py

Geprueft wird das, was ein Mensch an einer Abbildung NICHT nachsieht:
Skalierung, Determinismus, Abschneiden am Rand — und die Frage, ob der
Generator laut wird, wenn etwas nicht darstellbar ist, statt still ein
unvollstaendiges Bild zu liefern.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from figures.koordinatensystem import koordinatensystem  # noqa: E402
from figures.svg_basis import zahl  # noqa: E402
from figures.tokens import THEMES, pruefe_drift  # noqa: E402

FEHLER: list[str] = []


def pruefe(bedingung: bool, was: str) -> None:
    if not bedingung:
        FEHLER.append(was)


def erwarte_fehler(was: str, **argumente) -> None:
    try:
        koordinatensystem(**argumente)
    except ValueError:
        return
    FEHLER.append(f'{was}: haette ValueError werfen muessen, tat es aber nicht.')


# ── Gleiche Skalierung ───────────────────────────────────────────────────────
# Der Kern der Zusage. Ein asymmetrisches Fenster ist der Fall, in dem eine
# getrennte Skalierung durchrutschen wuerde: 20 Einheiten breit, 4 hoch.
svg = koordinatensystem(-10, 10, -2, 2, einheit=40)
masse = re.search(r'width="(\d+)" height="(\d+)"', svg)
pruefe(masse is not None, 'Kopf ohne width/height.')
if masse:
    breite, hoehe = int(masse.group(1)), int(masse.group(2))
    # 20 Einheiten * 40 px + 2 * 34 Rand = 868; 4 * 40 + 68 = 228.
    pruefe(breite == 868, f'Breite {breite}, erwartet 868.')
    pruefe(hoehe == 228, f'Hoehe {hoehe}, erwartet 228.')
    px_pro_x = (breite - 68) / 20
    px_pro_y = (hoehe - 68) / 4
    pruefe(px_pro_x == px_pro_y == 40, f'Skalen {px_pro_x} vs {px_pro_y} — muessen gleich sein.')

# Eine Steigung von 1 muss unter 45 Grad stehen: gleiche Pixeldifferenz in x
# und y. Gemessen an der gezeichneten Geraden selbst, nicht an der Rechnung.
gerade = koordinatensystem(-4, 4, -4, 4, funktionen=[{'typ': 'linear', 'm': 1, 'b': 0}])
punkte = re.search(r'<polyline points="([^"]+)"', gerade)
pruefe(punkte is not None, 'Gerade nicht gezeichnet.')
if punkte:
    paare = [tuple(float(t) for t in p.split(',')) for p in punkte.group(1).split()]
    (x1, y1), (x2, y2) = paare[0], paare[-1]
    pruefe(abs(abs(x2 - x1) - abs(y2 - y1)) < 0.01,
           f'Steigung 1 nicht unter 45 Grad: dx={x2 - x1}, dy={y2 - y1}.')
    # y waechst nach oben, im Bild also nach unten kleiner werdende Pixel.
    pruefe(y2 < y1, 'y-Achse nicht gespiegelt — die Gerade steigt im Bild nach unten.')

# ── Determinismus ────────────────────────────────────────────────────────────
argumente = dict(
    x_min=-6, x_max=6, y_min=-4, y_max=8,
    funktionen=[
        {'typ': 'linear', 'm': 0.5, 'b': -1, 'label': 'f(x) = 0,5x - 1'},
        {'typ': 'quadratisch', 'a': 0.3, 'b': 0.1, 'c': -2, 'label': 'g', 'betont': True},
    ],
    punkte=[{'x': 2, 'y': 0, 'label': 'N', 'betont': True}],
)
laeufe = [koordinatensystem(**argumente) for _ in range(3)]
pruefe(laeufe[0] == laeufe[1] == laeufe[2], 'Drei Laeufe, nicht byteidentisch.')
# Auf ZIFFER-e-ZIFFER pruefen, nicht auf 'e-': das traefe sonst 'edvance-plot'
# und 'stroke-width' und meldete einen Fehler, den es nicht gibt.
pruefe(not re.search(r'\d[eE][+-]?\d', laeufe[0]),
       'Exponentialschreibweise im Output — Zahlformat greift nicht.')
pruefe('-0"' not in laeufe[0] and '-0,' not in laeufe[0] and '-0 ' not in laeufe[0],
       'Negative Null im Output.')

# Kein Zeitstempel, kein Datum, keine Zufallsmarke.
pruefe(not re.search(r'20\d\d-\d\d-\d\d|\d\d:\d\d:\d\d', laeufe[0]),
       'Datum oder Uhrzeit im SVG.')

# ── Abschneiden am Rand ──────────────────────────────────────────────────────
# y = x^2 im Fenster y[4, 20]: der Scheitel liegt UNTER dem Fenster, die Aeste
# treten links und rechts ein. Genau der Fall, in dem ein ungetrennter
# Streckenzug eine Sehne quer durchs Bild zoege — eine Linie, die die Funktion
# nie hatte.
#
# Nicht geeignet waere y[-1, 3]: dort liegt der Scheitel IM Fenster, die Kurve
# ist ein einziger zusammenhaengender Bogen. Ein Test darauf pruefte nichts.
geteilt = koordinatensystem(-5, 5, 4, 20, funktionen=[{'typ': 'quadratisch', 'a': 1, 'b': 0, 'c': 0}])
linien = re.findall(r'<polyline points="([^"]+)"', geteilt)
pruefe(len(linien) == 2, f'Parabel ergibt {len(linien)} Abschnitte, erwartet 2 (links und rechts).')
for zug in linien:
    ys = [float(p.split(',')[1]) for p in zug.split()]
    # Toleranz ist eine Einheit ueber dem Rand (40 px), der clipPath nimmt den Rest.
    pruefe(min(ys) >= 34 - 40 - 0.5, f'Abschnitt laeuft {min(ys)} weit ueber den Rahmen hinaus.')
pruefe('clip-path="url(#edvance-plot)"' in geteilt, 'Kurvengruppe ohne clipPath.')

# Der Gegenfall, damit die Zerlegung nicht ueberreagiert: Scheitel im Fenster
# heisst genau EIN Abschnitt.
ganz = koordinatensystem(-5, 5, -1, 3, funktionen=[{'typ': 'quadratisch', 'a': 1, 'b': 0, 'c': 0}])
pruefe(len(re.findall(r'<polyline', ganz)) == 1,
       'Bogen mit Scheitel im Fenster wurde zerlegt.')

# Eine Gerade wird auf zwei Stuetzpunkte reduziert, eine Parabel nicht.
nur_gerade = koordinatensystem(-5, 5, -5, 5, funktionen=[{'typ': 'linear', 'm': 0.2, 'b': 1}])
zug = re.search(r'<polyline points="([^"]+)"', nur_gerade).group(1)
pruefe(len(zug.split()) == 2, f'Gerade mit {len(zug.split())} Punkten statt 2.')

# ── Transparenz und Themes ───────────────────────────────────────────────────
for theme in THEMES:
    bild = koordinatensystem(-3, 3, -3, 3, theme=theme,
                             funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'betont': True}])
    pruefe('<rect' not in bild.split('</clipPath>')[1],
           f'{theme}: Rechteck ausserhalb des clipPath — Hintergrund gefuellt?')
    pruefe('Schibsted Grotesk, Helvetica, Arial, sans-serif' in bild,
           f'{theme}: Schrift-Fallbackkette fehlt.')

    # REGRESSION (Inkscape-Probe 23.07.2026): rgba() ist in SVG-1.1-
    # Praesentationsattributen ungueltig. Renderer verwerfen den Wert und
    # zeichnen SCHWARZ — auf der Buehne waren Achsen und Zahlen dadurch
    # unsichtbar, waehrend die Kurve (Hex) korrekt aussah. Deckkraft gehoert in
    # stroke-opacity/fill-opacity.
    pruefe('rgba(' not in bild, f'{theme}: rgba() im SVG — Renderer zeichnen das schwarz.')
    pruefe('hsl(' not in bild, f'{theme}: hsl() im SVG — gleiches Problem wie rgba().')
    # Jede Farbe muss als #RRGGBB dastehen.
    for treffer in re.findall(r'(?:stroke|fill)="([^"]+)"', bild):
        pruefe(treffer == 'none' or re.fullmatch(r'#[0-9A-F]{6}', treffer) is not None,
               f'{theme}: Farbwert {treffer!r} ist kein #RRGGBB.')
pruefe('#D4A843' in koordinatensystem(-3, 3, -3, 3, theme='dunkel',
                                      funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'betont': True}]),
       'dunkel: betonte Kurve nicht in Altgold.')
pruefe('#DA9721' in koordinatensystem(-3, 3, -3, 3, theme='hell',
                                      funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'betont': True}]),
       'hell: betonte Kurve nicht in Report-Gold.')

# Beide Themes liefern dieselbe Geometrie — nur die Farben unterscheiden sich.
def _ohne_farben(text: str) -> str:
    # Auch die Deckkraft gehoert zur Farbe: 'dunkel' fuehrt abgestufte
    # Cream-Toene, 'hell' deckende. Bliebe sie stehen, meldete der Vergleich
    # einen Geometrie-Unterschied, der keiner ist.
    ohne = re.sub(r'(?:stroke|fill)(?:-opacity)?="[^"]*"', '', text)
    # Leerraum einebnen: 'dunkel' hinterlaesst zwei entfernte Attribute, 'hell'
    # eines — der Rest waeren unterschiedlich viele Leerzeichen und ein
    # gemeldeter Unterschied, der keine andere Geometrie ist.
    return re.sub(r'\s+', ' ', ohne)

pruefe(
    _ohne_farben(koordinatensystem(-3, 3, -3, 3, theme='dunkel'))
    == _ohne_farben(koordinatensystem(-3, 3, -3, 3, theme='hell')),
    'Themes unterscheiden sich in der Geometrie, nicht nur in der Farbe.',
)

# ── Beschriftung ─────────────────────────────────────────────────────────────
mit_null = koordinatensystem(-2, 2, -2, 2)
pruefe(mit_null.count('>0</text>') == 1, 'Die Null steht nicht genau einmal.')
ohne_null = koordinatensystem(2, 6, 2, 6)
pruefe(ohne_null.count('>0</text>') == 0,
       'Null beschriftet, obwohl der Ursprung nicht im Fenster liegt.')

# REGRESSION: Eine Gerade, die das Fenster oben rechts verlaesst, hatte ihr
# Label am Ende des TOLERANZBANDES — also ausserhalb des Bildes, wo der
# clipPath es wegschnitt. Die Beschriftung fehlte kommentarlos.
raus = koordinatensystem(-5, 5, -5, 5, funktionen=[
    {'typ': 'linear', 'm': 1, 'b': 1, 'label': 'f'},
    {'typ': 'linear', 'm': -0.5, 'b': 4, 'label': 'g'},
])
pruefe('>f</text>' in raus and '>g</text>' in raus,
       'Label einer aus dem Fenster laufenden Geraden fehlt.')

# Und es muss am RICHTIGEN Ende stehen. f(x) = x + 1 steigt; das Label gehoert
# nach oben rechts, dorthin wo die Gerade das Fenster verlaesst. Vorher landete
# es unten links am Startpunkt — gezeichnet war die Gerade richtig, beschriftet
# war sie falsch, und das faellt an einer Abbildung niemandem auf.
f_label = re.search(r'<text x="([\d.-]+)" y="([\d.-]+)"[^>]*>f</text>', raus)
pruefe(f_label is not None, 'Label f nicht als Textknoten gefunden.')
if f_label:
    fx, fy = float(f_label.group(1)), float(f_label.group(2))
    # Fenster -5..5 bei einheit 40, Rand 34: Mitte liegt bei 234/234.
    pruefe(fx > 234, f'Label f steht bei x={fx}, gehoert in die rechte Haelfte.')
    pruefe(fy < 234, f'Label f steht bei y={fy}, gehoert in die obere Haelfte.')
# Und es darf nicht IN der abgeschnittenen Gruppe haengen — dort wuerde ein
# Text an der Fensterkante zur Haelfte weggeschnitten.
geclippt = re.search(r'<g clip-path="url\(#edvance-plot\)">(.*?)</g>', raus, re.S)
pruefe(geclippt is not None, 'Kurvengruppe nicht gefunden.')
if geclippt:
    pruefe('<text' not in geclippt.group(1),
           'Funktionslabel steht in der abgeschnittenen Gruppe.')

# Fremdtext darf das Dokument nicht zerlegen.
boese = koordinatensystem(-2, 2, -2, 2, punkte=[{'x': 1, 'y': 1, 'label': '<a & b>'}])
pruefe('&lt;a &amp; b&gt;' in boese, 'Label nicht escaped.')

# ── Laute Fehler statt stiller Bilder ────────────────────────────────────────
erwarte_fehler('Punkt ausserhalb', x_min=-2, x_max=2, y_min=-2, y_max=2,
               punkte=[{'x': 99, 'y': 0}])
erwarte_fehler('Bounds nicht ganzzahlig', x_min=-2.5, x_max=2, y_min=-2, y_max=2)
erwarte_fehler('Bounds verdreht', x_min=2, x_max=-2, y_min=-2, y_max=2)
erwarte_fehler('bool als Bound', x_min=True, x_max=2, y_min=-2, y_max=2)
erwarte_fehler('unbekannter typ', x_min=-2, x_max=2, y_min=-2, y_max=2,
               funktionen=[{'typ': 'kubisch', 'a': 1}])
erwarte_fehler('Tippfehler im Schluessel', x_min=-2, x_max=2, y_min=-2, y_max=2,
               funktionen=[{'typ': 'linear', 'm': 1, 'b': 0, 'labl': 'f'}])
erwarte_fehler('fehlender Koeffizient', x_min=-2, x_max=2, y_min=-2, y_max=2,
               funktionen=[{'typ': 'quadratisch', 'a': 1, 'b': 0}])
erwarte_fehler('a = 0 als Parabel', x_min=-2, x_max=2, y_min=-2, y_max=2,
               funktionen=[{'typ': 'quadratisch', 'a': 0, 'b': 1, 'c': 0}])
erwarte_fehler('unbekanntes theme', x_min=-2, x_max=2, y_min=-2, y_max=2, theme='sepia')
erwarte_fehler('einheit null', x_min=-2, x_max=2, y_min=-2, y_max=2, einheit=0)

# ── Zahlformat ───────────────────────────────────────────────────────────────
pruefe(zahl(-0.0) == '0', f'zahl(-0.0) = {zahl(-0.0)!r}')
pruefe(zahl(0.1 + 0.2) == '0.3', f'zahl(0.1+0.2) = {zahl(0.1 + 0.2)!r}')
pruefe(zahl(120.0) == '120', f'zahl(120.0) = {zahl(120.0)!r}')
pruefe(zahl(-0.004) == '0', f'zahl(-0.004) = {zahl(-0.004)!r}')

# ── Tokens ───────────────────────────────────────────────────────────────────
for befund in pruefe_drift():
    FEHLER.append(f'Token-Drift: {befund}')


if FEHLER:
    print(f'{len(FEHLER)} FEHLER:')
    for eintrag in FEHLER:
        print(f'  - {eintrag}')
    raise SystemExit(1)
print('Alle Pruefungen bestanden.')
