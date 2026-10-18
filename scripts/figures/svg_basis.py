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


# ── Knappe viewBox ──────────────────────────────────────────────────────────
# Rasit, 18.10.2026: Tablet und Vorschau nehmen die volle Breite und die Hoehe aus
# dem Seitenverhaeltnis der viewBox. Ein fester Rahmen mit viel Leerraum macht die
# Figur dort klein. Die viewBox ist deshalb der Umriss alles Gezeichneten plus
# EIN einheitlicher Rand. Gemessen wird am fertigen SVG-Text — dieselbe Messung
# nutzen die pruefe_*-Module, damit Generator und Pruefung nicht auseinanderlaufen.

RAND_KNAPP = 16.0

# Geschaetzte Laufweite je Zeichen in Schriftgroessen (Schibsted Grotesk, eher
# grosszuegig: lieber ein paar Pixel Rand zu viel als ein abgeschnittener Text).
TEXT_LAUFWEITE = 0.62
TEXT_LAUFWEITE_FETT = 0.66
TEXT_HALBE_HOEHE = 0.62


def _text_roh(inhalt: str) -> str:
    return inhalt.replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')


def text_kasten(x: float, y: float, inhalt: str, groesse: float, anker: str = 'middle',
                fett: bool = False) -> tuple[float, float, float, float]:
    """Geschaetzter Kasten (x0, y0, x1, y1) eines Texts mit dominant-baseline=middle."""
    weite = len(inhalt) * groesse * (TEXT_LAUFWEITE_FETT if fett else TEXT_LAUFWEITE)
    links = x - weite / 2 if anker == 'middle' else x - weite if anker == 'end' else x
    return links, y - groesse * TEXT_HALBE_HOEHE, links + weite, y + groesse * TEXT_HALBE_HOEHE


def textkaesten(svg: str) -> list[tuple[float, float, float, float]]:
    """Die Kaesten aller <text>-Elemente eines SVG, in Dokumentreihenfolge."""
    import re

    aus = []
    for m in re.finditer(r'<text x="([\d.-]+)" y="([\d.-]+)"([^>]*)>([^<]*)</text>', svg):
        attr = m.group(3)
        groesse = float(re.search(r'font-size="([\d.]+)"', attr).group(1))
        anker = (re.search(r'text-anchor="(\w+)"', attr) or [None, 'start'])[1]
        aus.append(text_kasten(float(m.group(1)), float(m.group(2)), _text_roh(m.group(4)), groesse, anker,
                               'font-weight' in attr))
    return aus


def kaesten_ueberlappen(a, b, luft: float = 0.0) -> bool:
    """Ueberlappen zwei Kaesten (x0, y0, x1, y1), mit `luft` Mindestabstand?"""
    return a[0] < b[2] + luft and b[0] < a[2] + luft and a[1] < b[3] + luft and b[1] < a[3] + luft


def strecke_trifft_kasten(p, q, kasten, schritt: float = 1.0) -> bool:
    """Beruehrt die Strecke p-q den Kasten? Abgetastet im Pixelabstand — genau genug fuer Beschriftung."""
    laenge = max(abs(q[0] - p[0]), abs(q[1] - p[1]))
    n = max(1, int(laenge / schritt))
    for i in range(n + 1):
        x = p[0] + (q[0] - p[0]) * i / n
        y = p[1] + (q[1] - p[1]) * i / n
        if kasten[0] <= x <= kasten[2] and kasten[1] <= y <= kasten[3]:
            return True
    return False


def umriss(svg: str) -> tuple[float, float, float, float]:
    """
    (x0, y0, x1, y1) aller gezeichneten Elemente: Linien und Streckenzuege mit
    halber Strichstaerke, Kreise, Rechtecke, Texte mit geschaetzter Ausdehnung.
    """
    import re

    xs: list[float] = []
    ys: list[float] = []

    def strich(attr: str) -> float:
        m = re.search(r'stroke-width="([\d.]+)"', attr)
        return float(m.group(1)) / 2 if m else 0.0

    for m in re.finditer(r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"([^>]*)>', svg):
        s = strich(m.group(5))
        x1, y1, x2, y2 = (float(m.group(i)) for i in range(1, 5))
        xs += [min(x1, x2) - s, max(x1, x2) + s]
        ys += [min(y1, y2) - s, max(y1, y2) + s]
    for m in re.finditer(r'<polyline points="([^"]+)"([^>]*)>', svg):
        s = strich(m.group(2))
        for p in m.group(1).split():
            x, y = map(float, p.split(','))
            xs += [x - s, x + s]
            ys += [y - s, y + s]
    for m in re.finditer(r'<circle cx="([\d.-]+)" cy="([\d.-]+)" r="([\d.-]+)"([^>]*)>', svg):
        r = float(m.group(3)) + strich(m.group(4))
        xs += [float(m.group(1)) - r, float(m.group(1)) + r]
        ys += [float(m.group(2)) - r, float(m.group(2)) + r]
    for m in re.finditer(r'<rect x="([\d.-]+)" y="([\d.-]+)" width="([\d.-]+)" height="([\d.-]+)"([^>]*)>', svg):
        s = strich(m.group(5))
        x, y, b, h = (float(m.group(i)) for i in range(1, 5))
        xs += [x - s, x + b + s]
        ys += [y - s, y + h + s]
    for k in textkaesten(svg):
        xs += [k[0], k[2]]
        ys += [k[1], k[3]]
    if not xs:
        raise ValueError('Nichts gezeichnet — kein Umriss.')
    return min(xs), min(ys), max(xs), max(ys)


def dokument_knapp(inhalt: list[str], rand: float = RAND_KNAPP) -> str:
    """Wie `dokument`, aber die viewBox ist der Umriss der Figur plus `rand` ringsum."""
    x0, y0, x1, y1 = umriss('\n'.join(inhalt))
    x0, y0 = round(x0 - rand, 2), round(y0 - rand, 2)
    breite, hoehe = round(x1 + rand - x0, 2), round(y1 + rand - y0, 2)
    kopf = (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{zahl(breite)}" height="{zahl(hoehe)}" '
        f'viewBox="{zahl(x0)} {zahl(y0)} {zahl(breite)} {zahl(hoehe)}" '
        f'role="img">'
    )
    return '\n'.join([kopf, *inhalt, '</svg>', ''])


def pruefe_knapper_rahmen(svg: str, rand: float = RAND_KNAPP, eps: float = 0.6) -> list[str]:
    """
    Die viewBox deckt width/height, alles Gezeichnete liegt darin, und an keiner
    Seite ist mehr Rand als `rand` — eine Figur mit Leerraum waere in Vorschau und
    App unnoetig klein.
    """
    import re

    kopf = re.search(r'<svg\b[^>]*\bwidth="([\d.]+)"[^>]*\bheight="([\d.]+)"[^>]*\bviewBox="([^"]+)"', svg)
    if not kopf:
        return ['r: SVG ohne width/height/viewBox.']
    breite, hoehe = float(kopf.group(1)), float(kopf.group(2))
    vx, vy, vb, vh = map(float, kopf.group(3).split())
    befunde = []
    if abs(vb - breite) > eps or abs(vh - hoehe) > eps:
        befunde.append(f'r: viewBox {vb}x{vh} deckt width/height {breite}x{hoehe} nicht.')
    x0, y0, x1, y1 = umriss(svg)
    raender = {'links': x0 - vx, 'oben': y0 - vy, 'rechts': vx + vb - x1, 'unten': vy + vh - y1}
    for seite, r in raender.items():
        if r < -eps:
            befunde.append(f'r: Figur ragt {seite} {-r:.1f} px aus der viewBox — sie wuerde abgeschnitten.')
        elif r > rand + eps:
            befunde.append(f'r: {r:.1f} px Rand {seite}, erlaubt {rand:g} — die Figur waere unnoetig klein.')
    return befunde
