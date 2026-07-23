#!/usr/bin/env python3
"""
SVG-Grundlagen: Zahlformat, Escaping, Elemente.

Hier haengt der DETERMINISMUS. Gleiche Parameter muessen ein byteidentisches
SVG ergeben, und die drei Stellen, an denen das kippen kann, sind alle hier:

1. ZAHLEN. `str(0.1+0.2)` ist '0.30000000000000004'. Jede Koordinate laeuft
   deshalb durch `zahl()`: feste Rundung, danach ein kanonischer String.
2. MINUS NULL. `-0.0` ist ein voellig normales Float-Ergebnis (etwa aus
   `0.0 * -1`) und wuerde als '-0' im Pfad landen — dieselbe Geometrie, anderes
   Byte. `zahl()` faengt es ab.
3. REIHENFOLGE. Attribute werden als Liste gefuehrt, nie aus einem Dict
   iteriert, das irgendwo unterwegs neu aufgebaut wurde.

Was hier bewusst NICHT vorkommt: Zeitstempel, Zufalls-IDs, Hashes ueber
Speicheradressen, `id(...)`. Ein Generator, dessen Ausgabe sich zwischen zwei
Laeufen unterscheidet, ist beim Diffen wertlos.
"""

from __future__ import annotations

# Zwei Nachkommastellen sind bei ~40 px pro Einheit deutlich feiner als ein
# Bildschirm- oder Druckpunkt. Mehr Stellen blaehen nur die Datei.
STELLEN = 2


def zahl(wert: float) -> str:
    """
    Kanonischer Zahlstring: gerundet, ohne Nullschwanz, ohne '-0'.

    >>> zahl(120.0), zahl(0.1 + 0.2), zahl(-0.0), zahl(-0.001)
    ('120', '0.3', '0', '0')
    """
    gerundet = round(float(wert), STELLEN)
    if gerundet == 0:
        # Faengt -0.0 UND -0.001 ab: beide runden auf null, beide sollen '0'
        # heissen. `== 0` ist fuer -0.0 wahr, das ist hier genau richtig.
        return '0'
    text = f'{gerundet:.{STELLEN}f}'
    if '.' in text:
        text = text.rstrip('0').rstrip('.')
    return text


class Farbe:
    """
    Ein Farbwert plus Deckkraft — GETRENNT, und das ist der ganze Punkt.

    `stroke="rgba(247,245,238,0.18)"` ist in SVG 1.1 kein gueltiger
    Praesentationsattribut-Wert. Renderer verwerfen ihn und fallen auf den
    Vorgabewert zurueck: Schwarz. Auf der dunklen Buehne heisst das schwarze
    Achsen auf Navy — eine Abbildung, die fachlich stimmt und trotzdem
    unlesbar ist. (Genau so gesehen, Inkscape-Probe 23.07.2026.)

    Richtig ist die Trennung in Farbe und `*-opacity`. Das versteht jeder
    Renderer, auch aeltere Druck-Pipelines.
    """

    __slots__ = ('hex', 'deckkraft')

    def __init__(self, hex_wert: str, deckkraft: float = 1.0) -> None:
        if not (isinstance(hex_wert, str) and hex_wert.startswith('#') and len(hex_wert) == 7):
            raise ValueError(f'Farbe erwartet #RRGGBB, nicht {hex_wert!r}.')
        if not 0 <= deckkraft <= 1:
            raise ValueError(f'Deckkraft muss zwischen 0 und 1 liegen, nicht {deckkraft!r}.')
        self.hex = hex_wert.upper()
        self.deckkraft = float(deckkraft)


def farb_attribute(rolle: str, farbe: Farbe) -> list[tuple[str, str]]:
    """`stroke`/`fill` plus zugehoerige Deckkraft — letztere nur, wenn noetig."""
    attribute = [(rolle, farbe.hex)]
    if farbe.deckkraft < 1:
        attribute.append((f'{rolle}-opacity', zahl(farbe.deckkraft)))
    return attribute


def text_escape(roh: str) -> str:
    """
    Escaped Zeichendaten. Labels kommen aus Aufgabeninhalten, also aus fremder
    Hand — ein '<' im Label darf das Dokument nicht zerlegen.
    """
    return (
        str(roh)
        .replace('&', '&amp;')
        .replace('<', '&lt;')
        .replace('>', '&gt;')
    )


def attr_escape(roh: str) -> str:
    """Wie `text_escape`, zusaetzlich die Anfuehrungszeichen des Attributwerts."""
    return text_escape(roh).replace('"', '&quot;')


def element(name: str, attribute: list[tuple[str, str]], inhalt: str | None = None) -> str:
    """
    Ein SVG-Element. Attribute als LISTE von Paaren — die Reihenfolge im Output
    ist damit die Reihenfolge im Aufruf und nicht die Laune eines Dicts.
    """
    teile = ' '.join(f'{schluessel}="{wert}"' for schluessel, wert in attribute)
    kopf = f'<{name} {teile}' if teile else f'<{name}'
    if inhalt is None:
        return f'{kopf}/>'
    return f'{kopf}>{inhalt}</{name}>'


def linie(x1: float, y1: float, x2: float, y2: float, farbe: Farbe, breite: float) -> str:
    return element('line', [
        ('x1', zahl(x1)), ('y1', zahl(y1)),
        ('x2', zahl(x2)), ('y2', zahl(y2)),
        *farb_attribute('stroke', farbe),
        ('stroke-width', zahl(breite)),
    ])


def polygon(punkte: list[tuple[float, float]], farbe: Farbe) -> str:
    daten = ' '.join(f'{zahl(x)},{zahl(y)}' for x, y in punkte)
    return element('polygon', [('points', daten), *farb_attribute('fill', farbe)])


def polylinie(punkte: list[tuple[float, float]], farbe: Farbe, breite: float) -> str:
    """
    Offener Streckenzug. `fill="none"` ist Pflicht: Ohne das fuellt der Renderer
    die Flaeche unter der Kurve schwarz — der klassische Weg zu einem Bild, das
    fachlich richtig gerechnet und trotzdem unbrauchbar ist.
    """
    daten = ' '.join(f'{zahl(x)},{zahl(y)}' for x, y in punkte)
    return element('polyline', [
        ('points', daten),
        ('fill', 'none'),
        *farb_attribute('stroke', farbe),
        ('stroke-width', zahl(breite)),
        ('stroke-linecap', 'round'),
        ('stroke-linejoin', 'round'),
    ])


def kreis(x: float, y: float, radius: float, fuellung: Farbe) -> str:
    return element('circle', [
        ('cx', zahl(x)), ('cy', zahl(y)), ('r', zahl(radius)),
        *farb_attribute('fill', fuellung),
    ])


def beschriftung(
    x: float,
    y: float,
    inhalt: str,
    farbe: Farbe,
    groesse: float,
    schrift: str,
    anker: str = 'middle',
    grundlinie: str = 'middle',
    fett: bool = False,
) -> str:
    """
    Ein Textknoten.

    `dominant-baseline` wird von aelteren Renderern unterschiedlich ausgelegt;
    fuer die Sichtprobe reicht es, fuer den Druck ist es das gaengige Mittel.
    Wenn die Geraeteprobe zeigt, dass Zahlen verrutschen, ist das die Stelle —
    dann wird die Grundlinie manuell gerechnet statt deklariert.
    """
    attribute = [
        ('x', zahl(x)), ('y', zahl(y)),
        *farb_attribute('fill', farbe),
        ('font-family', attr_escape(schrift)),
        ('font-size', zahl(groesse)),
        ('text-anchor', anker),
        ('dominant-baseline', grundlinie),
    ]
    if fett:
        attribute.append(('font-weight', '600'))
    return element('text', attribute, text_escape(inhalt))


def dokument(breite: float, hoehe: float, inhalt: list[str]) -> str:
    """
    Der Rahmen. OHNE Hintergrundrechteck — die Abbildung ist transparent und
    liegt auf dem Traeger (dunkle Buehne oder weisses Papier).

    `viewBox` deckt exakt die Pixelmasse, damit 1 Nutzereinheit = 1 px bleibt
    und die gleiche Skalierung beider Achsen auch nach dem Skalieren gilt.
    """
    kopf = (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{zahl(breite)}" height="{zahl(hoehe)}" '
        f'viewBox="0 0 {zahl(breite)} {zahl(hoehe)}" '
        f'role="img">'
    )
    return '\n'.join([kopf, *inhalt, '</svg>', ''])
