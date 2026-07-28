#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Dreieck-Generator — IMPORTIERBAR.

WOZU: `upload_figures.py` (A19) laedt nichts hoch, was `pruefe(svg, params)`
nicht besteht. Ein falsches Bild ist schlimmer als kein Bild — und beim Dreieck
ist "falsch" besonders unauffaellig: Steht "8 cm" an der Grundseite und "2 cm"
an der Hoehe, dann MUSS die gezeichnete Hoehe ein Viertel der gezeichneten
Grundseite messen. Eine stille Stauchung sieht kein Mensch; ein Kind, das mit
dem Lineal nachmisst, bekommt eine andere Antwort als die Aufgabe erwartet.

WIE: Nicht die Parameter nachrechnen, sondern das ERZEUGTE SVG zurueckmessen.
Jede Pruefung liest Koordinaten aus dem SVG-Text, rekonstruiert daraus Ecken,
Hoehenfusspunkt, Masslinien und Masstexte und haelt das gegen die Parameter:

  r) alles Gezeichnete liegt im Rahmen, width/height deckt die viewBox
  d) der Umriss ist ein Dreieck mit waagerechter Grundseite, und seine Form
     passt zu `art` (gleichschenklig / rechtwinklig / beliebig)
  m) KERNPRUEFUNG: Pixelhoehe/Pixelgrundseite == hoehe/grundseite, solange das
     Verhaeltnis innerhalb 1:4 liegt; darueber steht die Figur am Bandrand
  k) ist gekappt worden, existiert das Zickzack — kein stilles Stauchen
  h) die Hoehe steht senkrecht auf der Grundseite (Skalarprodukt nahe null) und
     ist so lang wie die gemessene Pixelhoehe
  q) das rechtwinklige Zeichen sitzt an der richtigen Ecke — bei 'rechtwinklig'
     an der linken Grundecke, sonst am Hoehenfusspunkt
  t) Masslinien und Masstexte tragen die Werte der Parameter und stehen aussen

Die Masse werden NIE aus den Generator-Konstanten uebernommen — Grundseite und
Hoehe in Pixeln werden aus den Eckpunkten im SVG zurueckgerechnet. Nur so
schlaegt eine Verzerrung an, die die Beschriftung unveraendert laesst.

Die SVG-Leser hier sind absichtlich eigene und nicht aus `pruefe_winkel.py` oder
`pruefe_koordinatensystem.py` importiert: die Pruefung eines Generators soll
nicht an den Interna eines anderen haengen.
"""

from __future__ import annotations

import math
import re

# Toleranzen. Koordinaten stehen auf zwei Nachkommastellen (svg_basis STELLEN=2);
# ein echter Fehler ist immer groesser.
EPS_PIXEL = 0.5        # Ecken, Rahmen, Deckungsgleichheit von Punkten
EPS_MASS = 0.5         # Laengen: Masslinie gegen gemessene Strecke, Verhaeltnis
EPS_SENKRECHT = 0.01   # normiertes Skalarprodukt (entspricht rund 0,6 Grad)
EPS_TEXT = 1.0         # Ankerlage eines Masstexts
EPS_ZAHL = 0.005       # Masszahl im Text gegen den Parameter (zwei Stellen)

# Wie im Generator: ueber 1:4 wird gekappt. BEWUSST DOPPELT — die Pruefung darf
# nicht aus derselben Quelle rechnen wie das Gepruefte, sonst prueft sie sich
# selbst und nicht die Abbildung.
VERHAELTNIS_MAX = 4.0
VERHAELTNIS_MIN = 1.0 / VERHAELTNIS_MAX

ARTEN = ('beliebig', 'gleichschenklig', 'rechtwinklig')


# ── SVG einlesen ─────────────────────────────────────────────────────────────

def _floats(text: str) -> list[float]:
    return [float(t) for t in re.findall(r'-?\d+(?:\.\d+)?', text)]


def _kopf(svg: str) -> tuple[float, float]:
    m = re.search(r'<svg\b[^>]*\bwidth="([\d.-]+)"[^>]*\bheight="([\d.-]+)"', svg)
    if not m:
        raise ValueError('SVG ohne width/height im Kopf.')
    return float(m.group(1)), float(m.group(2))


def _viewbox(svg: str) -> tuple[float, float, float, float]:
    m = re.search(r'\bviewBox="([\d.\- ]+)"', svg)
    if not m:
        raise ValueError('SVG ohne viewBox.')
    werte = _floats(m.group(1))
    if len(werte) != 4:
        raise ValueError(f'viewBox mit {len(werte)} Zahlen statt vier.')
    return werte[0], werte[1], werte[2], werte[3]


def _linien(svg: str) -> list[tuple[tuple[float, float], tuple[float, float], bool]]:
    """Alle <line>-Elemente als (Anfang, Ende, gestrichelt)."""
    aus = []
    for treffer in re.finditer(r'<line\b[^>]*/>', svg):
        marke = treffer.group(0)
        koord = re.search(
            r'x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', marke
        )
        if not koord:
            raise ValueError(f'<line> ohne vollstaendige Koordinaten: {marke}')
        x1, y1, x2, y2 = (float(g) for g in koord.groups())
        aus.append(((x1, y1), (x2, y2), 'stroke-dasharray' in marke))
    return aus


def _polylinien(svg: str) -> list[list[tuple[float, float]]]:
    aus = []
    for m in re.finditer(r'<polyline points="([^"]+)"', svg):
        werte = _floats(m.group(1))
        aus.append([(werte[i], werte[i + 1]) for i in range(0, len(werte) - 1, 2)])
    return aus


def _texte(svg: str) -> list[tuple[float, float, str]]:
    """Textanker plus Inhalt — die Entities zurueckgedreht, damit sich der
    Inhalt gegen den Parameter vergleichen laesst."""
    aus = []
    for m in re.finditer(r'<text x="([\d.-]+)" y="([\d.-]+)"[^>]*>(.*?)</text>', svg):
        roh = (m.group(3)
               .replace('&lt;', '<')
               .replace('&gt;', '>')
               .replace('&quot;', '"')
               .replace('&amp;', '&'))
        aus.append((float(m.group(1)), float(m.group(2)), roh))
    return aus


# ── Vektorrechnung ───────────────────────────────────────────────────────────

def _differenz(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return (b[0] - a[0], b[1] - a[1])


def _normiertes_skalarprodukt(u: tuple[float, float], v: tuple[float, float]) -> float:
    """
    Skalarprodukt, geteilt durch die beiden Laengen — also der Kosinus des
    eingeschlossenen Winkels.

    Ohne die Normierung haengt der Wert an der Groesse der Figur: dasselbe
    schiefe Lot ergaebe bei einem grossen Dreieck ein grosses und bei einem
    kleinen ein kleines Skalarprodukt, und eine feste Schranke traefe nur eine
    von beiden Groessen.
    """
    laenge_u = math.hypot(*u)
    laenge_v = math.hypot(*v)
    if laenge_u == 0 or laenge_v == 0:
        return 1.0
    return (u[0] * v[0] + u[1] * v[1]) / (laenge_u * laenge_v)


# ── Rueckgerechnete Figur ────────────────────────────────────────────────────

class Figur:
    """
    Ecken, Hoehenfusspunkt, Masslinien und Texte — ausschliesslich AUS DEM SVG.

    Die Elemente werden ueber ihre GESTALT auseinandergehalten und nicht ueber
    Namen oder Reihenfolge: der Umriss ist der geschlossene Streckenzug mit vier
    Punkten, das rechtwinklige Zeichen der mit dreien, das Zickzack der mit
    fuenfen. So bleibt die Zuordnung auch dann richtig, wenn der Generator die
    Reihenfolge im Dokument einmal aendert.
    """

    def __init__(self, svg: str) -> None:
        self.breite, self.hoehe = _kopf(svg)
        self.viewbox = _viewbox(svg)
        self.linien = _linien(svg)
        self.polylinien = _polylinien(svg)
        self.texte = _texte(svg)

        self.gestrichelt = [strich for strich in self.linien if strich[2]]
        self.masslinien = [strich for strich in self.linien if not strich[2]]
        self.umrisse = [zug for zug in self.polylinien if len(zug) == 4]
        self.zeichen = [zug for zug in self.polylinien if len(zug) == 3]
        self.zacken = [zug for zug in self.polylinien if len(zug) == 5]
        self.fremde = [
            zug for zug in self.polylinien if len(zug) not in (3, 4, 5)
        ]

        if len(self.umrisse) != 1:
            raise ValueError(
                f'{len(self.umrisse)} Streckenzug/-zuege mit vier Punkten — genau '
                f'einer ist der Dreiecksumriss.'
            )
        zug = self.umrisse[0]
        if math.dist(zug[0], zug[-1]) > EPS_PIXEL:
            raise ValueError(
                f'der Umriss ist nicht geschlossen: Anfang {zug[0]} und Ende '
                f'{zug[-1]} liegen {math.dist(zug[0], zug[-1]):.2f} px auseinander.'
            )
        self.ecken = zug[:3]

        # Die Grundseite ist die waagerechte UNTEN. "Unten" heisst in SVG das
        # groesste y — die Spiegelung wird hier nicht zurueckgedreht, weil alle
        # Vergleiche in Pixelkoordinaten bleiben.
        unten = max(y for _, y in self.ecken)
        auf_grund = [
            i for i, punkt in enumerate(self.ecken) if abs(punkt[1] - unten) <= EPS_PIXEL
        ]
        if len(auf_grund) != 2:
            raise ValueError(
                f'{len(auf_grund)} Ecke(n) auf der untersten Waagerechten — ohne '
                f'genau zwei gibt es keine waagerechte Grundseite.'
            )
        oben = [i for i in range(3) if i not in auf_grund][0]
        self.spitze = self.ecken[oben]
        self.a, self.b = sorted(self.ecken[i] for i in auf_grund)

        self.grund_px = self.b[0] - self.a[0]
        self.hoehe_px = self.a[1] - self.spitze[1]
        if self.grund_px <= EPS_PIXEL or self.hoehe_px <= EPS_PIXEL:
            raise ValueError(
                f'entartetes Dreieck: Grundseite {self.grund_px:.2f} px, '
                f'Hoehe {self.hoehe_px:.2f} px.'
            )
        # Der Fusspunkt der Hoehe: senkrecht unter der Spitze, auf Grundseiten-
        # hoehe. Er wird gerechnet und nicht aus dem SVG gelesen — die
        # gezeichnete Hoehe wird GEGEN ihn geprueft.
        self.fuss = (self.spitze[0], self.a[1])

    def punkte(self) -> list[tuple[float, float]]:
        """Alles Gezeichnete als Punktliste — fuer die Rahmenpruefung."""
        aus: list[tuple[float, float]] = []
        for anfang, ende, _ in self.linien:
            aus.extend([anfang, ende])
        for zug in self.polylinien:
            aus.extend(zug)
        aus.extend([(x, y) for x, y, _ in self.texte])
        return aus


# ── Parameter lesen ──────────────────────────────────────────────────────────

def _laenge(params: dict, name: str) -> float:
    if name not in params:
        raise ValueError(f'params ohne {name!r} — nicht pruefbar.')
    wert = params[name]
    if isinstance(wert, bool) or not isinstance(wert, (int, float)):
        raise ValueError(f'params[{name!r}] ist keine Zahl: {wert!r}.')
    wert = float(wert)
    if not math.isfinite(wert) or wert <= 0:
        raise ValueError(f'params[{name!r}] = {wert!r} ist keine Laenge.')
    return wert


def _art(params: dict) -> str:
    art = params.get('art', 'beliebig')
    if art not in ARTEN:
        raise ValueError(f'params["art"] = {art!r} ist keine bekannte Art.')
    return art


def _verhaeltnis(params: dict) -> tuple[float, float, bool]:
    """(verlangtes Verhaeltnis, gezeichnetes Verhaeltnis, gekappt)."""
    verlangt = _laenge(params, 'hoehe') / _laenge(params, 'grundseite')
    gezeichnet = min(max(verlangt, VERHAELTNIS_MIN), VERHAELTNIS_MAX)
    return verlangt, gezeichnet, gezeichnet != verlangt


# ── Einzelpruefungen: SVG-Text rein, Befunde raus ────────────────────────────

def pruefe_rahmen(svg: str, params: dict) -> list[str]:
    """
    r) Der Rahmen deckt die Figur: viewBox == width/height, und kein
    gezeichneter Punkt liegt draussen.

    Was aus dem Rahmen laeuft, wird beim Rendern weggeschnitten — die Abbildung
    ist dann unauffaellig unvollstaendig, der schlimmste Fall.
    """
    figur = Figur(svg)
    befunde: list[str] = []

    x0, y0, vb_breite, vb_hoehe = figur.viewbox
    if (abs(x0) > EPS_PIXEL or abs(y0) > EPS_PIXEL
            or abs(vb_breite - figur.breite) > EPS_PIXEL
            or abs(vb_hoehe - figur.hoehe) > EPS_PIXEL):
        befunde.append(
            f'r) viewBox ({x0}, {y0}, {vb_breite}, {vb_hoehe}) deckt nicht '
            f'width/height ({figur.breite}, {figur.hoehe}).'
        )

    for x, y in figur.punkte():
        if not (-EPS_PIXEL <= x <= figur.breite + EPS_PIXEL
                and -EPS_PIXEL <= y <= figur.hoehe + EPS_PIXEL):
            befunde.append(
                f'r) Punkt ({x}, {y}) liegt ausserhalb des Rahmens '
                f'(0..{figur.breite} x 0..{figur.hoehe}) — er wuerde weggeschnitten.'
            )
    return befunde


def pruefe_umriss(svg: str, params: dict) -> list[str]:
    """
    d) Der Umriss ist ein Dreieck mit waagerechter Grundseite, und seine Form
    passt zu `art`.

    Die Art ist keine Beschriftung, sondern eine Zusage ueber die Figur: ein als
    'gleichschenklig' gefuehrtes Dreieck, dessen Schenkel verschieden lang sind,
    ist eine falsche Aufgabe — und am Bild sieht man den Unterschied von wenigen
    Pixeln nicht.
    """
    figur = Figur(svg)
    art = _art(params)
    befunde: list[str] = []

    if figur.fremde:
        laengen = ', '.join(str(len(zug)) for zug in figur.fremde)
        befunde.append(
            f'd) {len(figur.fremde)} Streckenzug/-zuege mit unerwarteter '
            f'Punktzahl ({laengen}) im SVG.'
        )

    if abs(figur.a[1] - figur.b[1]) > EPS_PIXEL:
        befunde.append(
            f'd) die Grundseite ist nicht waagerecht: y={figur.a[1]} gegen '
            f'y={figur.b[1]}.'
        )

    schenkel_links = math.dist(figur.a, figur.spitze)
    schenkel_rechts = math.dist(figur.b, figur.spitze)

    if art == 'gleichschenklig':
        if abs(schenkel_links - schenkel_rechts) > EPS_MASS:
            befunde.append(
                f'd) art="gleichschenklig", aber die Schenkel messen '
                f'{schenkel_links:.2f} px und {schenkel_rechts:.2f} px.'
            )
    elif art == 'rechtwinklig':
        kosinus = _normiertes_skalarprodukt(
            _differenz(figur.a, figur.b), _differenz(figur.a, figur.spitze)
        )
        if abs(kosinus) > EPS_SENKRECHT:
            befunde.append(
                f'd) art="rechtwinklig", aber der Winkel an der linken Grundecke '
                f'misst {math.degrees(math.acos(max(-1.0, min(1.0, kosinus)))):.3f}° '
                f'statt 90° (Skalarprodukt normiert {kosinus:.4f}).'
            )
        if abs(figur.spitze[0] - figur.a[0]) > EPS_PIXEL:
            befunde.append(
                f'd) art="rechtwinklig", aber die Spitze steht {abs(figur.spitze[0] - figur.a[0]):.2f} px '
                f'neben der linken Grundecke statt senkrecht ueber ihr.'
            )
    else:
        # 'beliebig' sagt nichts ueber Schenkel oder Winkel zu — aber der
        # Hoehenfusspunkt muss INNEN liegen, sonst laege die gestrichelte Hoehe
        # ausserhalb des Dreiecks und die Figur zeigte etwas anderes.
        if not (figur.a[0] + EPS_PIXEL < figur.fuss[0] < figur.b[0] - EPS_PIXEL):
            befunde.append(
                f'd) art="beliebig", aber der Hoehenfusspunkt x={figur.fuss[0]:.2f} '
                f'liegt nicht echt zwischen den Grundecken '
                f'({figur.a[0]:.2f} .. {figur.b[0]:.2f}).'
            )
    return befunde


def pruefe_massstab(svg: str, params: dict) -> list[str]:
    """
    m) DIE KERNPRUEFUNG: Pixelhoehe/Pixelgrundseite entspricht hoehe/grundseite.

    Solange das verlangte Verhaeltnis innerhalb 1:4 liegt, wird nichts gekappt
    und die Figur ist massstaeblich. Darueber steht sie am Bandrand — dann muss
    das gezeichnete Verhaeltnis GENAU die Grenze treffen und nicht irgendwo
    dazwischen liegen, sonst ist es eine Stauchung nach Gutduenken.
    """
    figur = Figur(svg)
    verlangt, gezeichnet, gekappt = _verhaeltnis(params)
    ist = figur.hoehe_px / figur.grund_px

    if abs(figur.hoehe_px - figur.grund_px * gezeichnet) > EPS_MASS:
        if gekappt:
            return [
                f'm) gekappte Figur: gezeichnet ist 1:{1 / ist:.4f} '
                f'(Verhaeltnis {ist:.4f}), am Bandrand waeren es {gezeichnet:g}. '
                f'Grundseite {figur.grund_px:.2f} px, Hoehe {figur.hoehe_px:.2f} px.'
            ]
        return [
            f'm) nicht massstaeblich: gezeichnet {figur.hoehe_px:.2f} px Hoehe zu '
            f'{figur.grund_px:.2f} px Grundseite (Verhaeltnis {ist:.4f}), verlangt '
            f'{verlangt:.4f} aus hoehe/grundseite. Wer mit dem Lineal nachmisst, '
            f'bekommt eine andere Antwort als die Aufgabe erwartet.'
        ]
    return []


def pruefe_kappung(svg: str, params: dict) -> list[str]:
    """
    k) Ist gekappt worden, steht das Zickzack im Bild — sonst nicht.

    Das ist die Pruefung gegen die STILLE Stauchung. Ohne das Zeichen sieht eine
    gekappte Abbildung aus wie eine massstaebliche, und die Masszahlen daneben
    behaupten etwas, das die Figur nicht zeigt.
    """
    figur = Figur(svg)
    verlangt, _gezeichnet, gekappt = _verhaeltnis(params)

    if not gekappt:
        if figur.zacken:
            return [
                f'k) {len(figur.zacken)} Zickzack im SVG, obwohl das Verhaeltnis '
                f'{verlangt:.4f} innerhalb 1:{VERHAELTNIS_MAX:g} liegt und nichts '
                f'gekappt wurde.'
            ]
        return []

    if len(figur.zacken) != 1:
        return [
            f'k) Verhaeltnis {verlangt:.4f} liegt ausserhalb 1:{VERHAELTNIS_MAX:g}, '
            f'also wurde gekappt — aber {len(figur.zacken)} Zickzack im SVG statt '
            f'einem. Eine stille Stauchung sieht niemand.'
        ]

    # Das Zeichen gehoert an das GEKAPPTE Mass: bei zu hoher Figur an die
    # senkrechte Masslinie, bei zu flacher an die waagerechte.
    zacke = figur.zacken[0]
    mitte = (
        sum(x for x, _ in zacke) / len(zacke),
        sum(y for _, y in zacke) / len(zacke),
    )
    zu_hoch = verlangt > VERHAELTNIS_MAX
    soll = (
        (figur.a[1] + figur.spitze[1]) / 2.0 if zu_hoch
        else (figur.a[0] + figur.b[0]) / 2.0
    )
    ist = mitte[1] if zu_hoch else mitte[0]
    if abs(ist - soll) > EPS_MASS + 1.0:
        welches = 'Hoehe' if zu_hoch else 'Grundseite'
        befund = (
            f'k) das Zickzack sitzt nicht auf der Mitte der Masslinie fuer die '
            f'{welches} ({ist:.2f} statt {soll:.2f}) — es steht am falschen Mass.'
        )
        return [befund]
    return []


def pruefe_hoehe(svg: str, params: dict) -> list[str]:
    """
    h) Die Hoehe steht senkrecht auf der Grundseite und ist so lang wie die
    gemessene Pixelhoehe.

    Gemessen wird ueber das Skalarprodukt aus Grundseitenrichtung und
    Hoehenrichtung, normiert auf beide Laengen — es muss nahe null sein.

    Bei 'rechtwinklig' faellt die Hoehe mit der linken Kathete zusammen; dann
    darf KEINE gestrichelte Linie im Bild stehen (sie laege auf der Kathete) und
    geprueft wird die Kathete selbst. Bei den anderen Arten ist die gestrichelte
    Linie Pflicht — ohne sie ist die Hoehe im Bild nicht zu sehen, und die
    Masszahl daneben bezieht sich auf nichts.
    """
    figur = Figur(svg)
    art = _art(params)
    grund = _differenz(figur.a, figur.b)
    befunde: list[str] = []

    if art == 'rechtwinklig':
        if figur.gestrichelt:
            return [
                f'h) art="rechtwinklig": {len(figur.gestrichelt)} gestrichelte '
                f'Linie(n) im SVG. Die Hoehe IST die linke Kathete — eine Seite, '
                f'die halb durchgezogen und halb gestrichelt aussieht, ist keine '
                f'Abbildung, sondern eine Verwechslung.'
            ]
        strecke = (figur.a, figur.spitze)
    else:
        if len(figur.gestrichelt) != 1:
            return [
                f'h) {len(figur.gestrichelt)} gestrichelte Linie(n) im SVG, '
                f'erwartet genau eine (die Hoehe) fuer art={art!r}.'
            ]
        anfang, ende, _ = figur.gestrichelt[0]
        strecke = (anfang, ende)

    hoch, tief = sorted(strecke, key=lambda punkt: punkt[1])
    kosinus = _normiertes_skalarprodukt(grund, _differenz(tief, hoch))
    if abs(kosinus) > EPS_SENKRECHT:
        befunde.append(
            f'h) die Hoehe steht nicht senkrecht auf der Grundseite: normiertes '
            f'Skalarprodukt {kosinus:.4f} statt nahe null '
            f'({math.degrees(math.asin(max(-1.0, min(1.0, kosinus)))):.3f}° schief).'
        )
    if math.dist(hoch, figur.spitze) > EPS_PIXEL:
        befunde.append(
            f'h) die Hoehe beginnt nicht in der Spitze: oberes Ende {hoch} liegt '
            f'{math.dist(hoch, figur.spitze):.2f} px daneben.'
        )
    if math.dist(tief, figur.fuss) > EPS_PIXEL:
        befunde.append(
            f'h) die Hoehe endet nicht im Fusspunkt: unteres Ende {tief} liegt '
            f'{math.dist(tief, figur.fuss):.2f} px daneben.'
        )
    laenge = math.dist(hoch, tief)
    if abs(laenge - figur.hoehe_px) > EPS_MASS:
        befunde.append(
            f'h) die gezeichnete Hoehe misst {laenge:.2f} px, der Abstand der '
            f'Spitze von der Grundseite aber {figur.hoehe_px:.2f} px.'
        )
    return befunde


def pruefe_winkelzeichen(svg: str, params: dict) -> list[str]:
    """
    q) Das rechtwinklige Zeichen sitzt an der richtigen Ecke.

    Bei 'rechtwinklig' ist das die linke Grundecke — dort ist der rechte Winkel
    des Dreiecks. Bei den anderen Arten der Hoehenfusspunkt. Ein Zeichen an der
    falschen Ecke ist eine falsche Zusage, mit der man weiterrechnet, und es
    faellt an der Abbildung niemandem auf.
    """
    figur = Figur(svg)
    art = _art(params)

    if len(figur.zeichen) != 1:
        return [
            f'q) {len(figur.zeichen)} Streckenzug/-zuege mit drei Punkten im SVG, '
            f'erwartet genau einen (das rechtwinklige Zeichen).'
        ]

    erst, ecke, letzt = figur.zeichen[0]
    befunde: list[str] = []

    seite_a, seite_b = math.dist(erst, ecke), math.dist(letzt, ecke)
    if abs(seite_a - seite_b) > EPS_PIXEL:
        befunde.append(
            f'q) das Zeichen ist kein Quadrat: seine Schenkel messen '
            f'{seite_a:.2f} px und {seite_b:.2f} px.'
        )
    kosinus = _normiertes_skalarprodukt(
        _differenz(ecke, erst), _differenz(ecke, letzt)
    )
    if abs(kosinus) > EPS_SENKRECHT:
        befunde.append(
            f'q) die Schenkel des Zeichens stehen nicht senkrecht zueinander '
            f'(normiertes Skalarprodukt {kosinus:.4f}).'
        )

    # Bezugsecke: bei 'rechtwinklig' die linke Grundecke, sonst der Fusspunkt.
    # Bei 'rechtwinklig' fallen beide zusammen — der Bezug wird trotzdem an der
    # ECKE genommen, damit ein verschobenes Zeichen auch dann auffaellt, wenn
    # sich die Spitze mitverschoben hat.
    bezug = figur.a if art == 'rechtwinklig' else figur.fuss
    seite = max(seite_a, seite_b)
    soll = {
        (round(bezug[0] + seite, 2), round(bezug[1], 2)),
        (round(bezug[0], 2), round(bezug[1] - seite, 2)),
    }
    ist = {(round(erst[0], 2), round(erst[1], 2)), (round(letzt[0], 2), round(letzt[1], 2))}
    passt = all(
        any(abs(i[0] - s[0]) <= EPS_PIXEL and abs(i[1] - s[1]) <= EPS_PIXEL for s in soll)
        for i in ist
    )
    if not passt:
        wo = 'der linken Grundecke' if art == 'rechtwinklig' else 'dem Hoehenfusspunkt'
        befunde.append(
            f'q) die freien Enden des Zeichens liegen bei {sorted(ist)} statt an '
            f'{wo} {tuple(round(w, 2) for w in bezug)} (erwartet {sorted(soll)}).'
        )
    return befunde


def pruefe_masslinien(svg: str, params: dict) -> list[str]:
    """
    t) Die Masslinien liegen AUSSEN und sind so lang wie das, was sie messen.

    Eine Masslinie, die kuerzer ist als ihre Strecke, behauptet ein Mass, das
    die Figur nicht hat — und sie steht genau dort, wo ein Kind mit dem Lineal
    ansetzt.
    """
    figur = Figur(svg)
    if len(figur.masslinien) != 2:
        return [
            f't) {len(figur.masslinien)} durchgezogene Linie(n) im SVG, erwartet '
            f'zwei Masslinien (Grundseite und Hoehe).'
        ]

    befunde: list[str] = []
    waagerecht = [
        (anfang, ende) for anfang, ende, _ in figur.masslinien
        if abs(anfang[1] - ende[1]) <= EPS_PIXEL
    ]
    senkrecht = [
        (anfang, ende) for anfang, ende, _ in figur.masslinien
        if abs(anfang[0] - ende[0]) <= EPS_PIXEL
    ]
    if len(waagerecht) != 1 or len(senkrecht) != 1:
        return [
            f't) {len(waagerecht)} waagerechte und {len(senkrecht)} senkrechte '
            f'Masslinie(n) — erwartet je eine.'
        ]

    (wa, we), (sa, se) = waagerecht[0], senkrecht[0]

    if wa[1] <= figur.a[1] + EPS_PIXEL:
        befunde.append(
            f't) die Masslinie der Grundseite liegt bei y={wa[1]} nicht UNTER der '
            f'Grundseite (y={figur.a[1]}) — sie steht im Bild statt daneben.'
        )
    if abs(min(wa[0], we[0]) - figur.a[0]) > EPS_MASS or abs(max(wa[0], we[0]) - figur.b[0]) > EPS_MASS:
        befunde.append(
            f't) die Masslinie der Grundseite spannt {min(wa[0], we[0]):.2f}..'
            f'{max(wa[0], we[0]):.2f}, die Grundseite aber {figur.a[0]:.2f}..'
            f'{figur.b[0]:.2f}.'
        )

    if sa[0] >= figur.a[0] - EPS_PIXEL:
        befunde.append(
            f't) die Masslinie der Hoehe liegt bei x={sa[0]} nicht LINKS der '
            f'Figur (linke Grundecke x={figur.a[0]}).'
        )
    if (abs(max(sa[1], se[1]) - figur.a[1]) > EPS_MASS
            or abs(min(sa[1], se[1]) - figur.spitze[1]) > EPS_MASS):
        befunde.append(
            f't) die Masslinie der Hoehe spannt {min(sa[1], se[1]):.2f}..'
            f'{max(sa[1], se[1]):.2f}, die Hoehe aber {figur.spitze[1]:.2f}..'
            f'{figur.a[1]:.2f}.'
        )
    return befunde


def pruefe_masstexte(svg: str, params: dict) -> list[str]:
    """
    t) Die Masstexte tragen die Werte der Parameter und stehen an ihrem Mass.

    Die Zahlen werden nicht auf Zeichengleichheit geprueft, sondern
    ZURUECKGELESEN und als Zahl verglichen — ein Zahlendreher ('52' zu '25') ist
    genau der Fehler, den an einer Abbildung niemand nachrechnet.

    Zugeordnet wird ueber die LAGE: der Text unter der Grundseite gehoert zur
    Grundseite, der links neben der Figur zur Hoehe. So bleibt die Zuordnung
    eindeutig, auch wenn beide Masse zufaellig gleich sind.
    """
    figur = Figur(svg)
    grundseite = _laenge(params, 'grundseite')
    hoehe = _laenge(params, 'hoehe')
    einheit = params.get('einheit', 'cm')

    if len(figur.texte) != 2:
        return [
            f't) {len(figur.texte)} Textknoten im SVG, erwartet zwei '
            f'(Grundseite und Hoehe).'
        ]

    unten = [t for t in figur.texte if t[1] > figur.a[1] + EPS_PIXEL]
    links = [t for t in figur.texte if t[0] < figur.a[0] - EPS_PIXEL and t[1] <= figur.a[1]]
    befunde: list[str] = []

    for name, treffer, wert, anker in (
        ('Grundseite', unten, grundseite,
         (figur.a[0] + figur.grund_px / 2.0, None)),
        ('Hoehe', links, hoehe,
         (None, figur.a[1] - figur.hoehe_px / 2.0)),
    ):
        if len(treffer) != 1:
            befunde.append(
                f't) {len(treffer)} Masstext(e) an der Stelle der {name}, '
                f'erwartet genau einen.'
            )
            continue
        x, y, inhalt = treffer[0]
        gelesen = _als_mass(inhalt)
        if gelesen is None:
            befunde.append(f't) der Text {inhalt!r} an der {name} ist keine Massangabe.')
            continue
        zahl_ist, einheit_ist = gelesen
        if abs(zahl_ist - wert) > EPS_ZAHL:
            befunde.append(
                f't) der Masstext an der {name} sagt {zahl_ist:g}, die Parameter '
                f'verlangen {wert:g}.'
            )
        if einheit_ist != einheit:
            befunde.append(
                f't) der Masstext an der {name} traegt die Einheit {einheit_ist!r}, '
                f'verlangt ist {einheit!r}.'
            )
        soll_x, soll_y = anker
        if soll_x is not None and abs(x - soll_x) > EPS_TEXT:
            befunde.append(
                f't) der Masstext an der {name} steht bei x={x:.2f} statt mittig '
                f'unter der Strecke (x={soll_x:.2f}).'
            )
        if soll_y is not None and abs(y - soll_y) > EPS_TEXT:
            befunde.append(
                f't) der Masstext an der {name} steht bei y={y:.2f} statt auf '
                f'halber Hoehe (y={soll_y:.2f}).'
            )
    return befunde


def _als_mass(inhalt: str) -> tuple[float, str] | None:
    """'12,5 cm' -> (12.5, 'cm'). None, wenn der Text keine Massangabe ist."""
    teile = inhalt.strip().split(' ')
    if len(teile) != 2 or not teile[1]:
        return None
    try:
        return float(teile[0].replace(',', '.')), teile[1]
    except ValueError:
        return None


# ── Sammelpruefung + Adapter fuer den Upload ─────────────────────────────────

_ALLE = (
    pruefe_rahmen,
    pruefe_umriss,
    pruefe_massstab,
    pruefe_kappung,
    pruefe_hoehe,
    pruefe_winkelzeichen,
    pruefe_masslinien,
    pruefe_masstexte,
)


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    """
    Alle Geometriepruefungen. Leere Liste heisst: nichts gefunden.

    Ein SVG, das sich nicht lesen laesst (kein Umriss, keine viewBox), ergibt
    einen BEFUND und keine Ausnahme: der Aufrufer ist der Upload, und der soll
    nichts laden statt abzustuerzen.
    """
    befunde: list[str] = []
    for pruefung in _ALLE:
        try:
            befunde.extend(pruefung(svg, params))
        except ValueError as fehler:
            befunde.append(f'{pruefung.__name__}: SVG nicht lesbar — {fehler}')
    return befunde


def pruefe(svg: str, params: dict) -> tuple[bool, str]:
    """
    Die Schnittstelle fuer upload_figures.py: (bestanden, meldung).

    bestanden == True nur, wenn KEIN Befund vorliegt — dann darf hochgeladen
    werden. Sonst traegt die Meldung alle Befunde, und der Aufrufer laedt nichts.
    """
    befunde = pruefe_geometrie(svg, params)
    if befunde:
        return False, ' | '.join(befunde)
    return True, 'ok'


# ── Negativkontrolle ─────────────────────────────────────────────────────────
#
# Der Test prueft mit ungueltigen EINGABEN, ob der Generator laut wird — das ist
# Eingabevalidierung. Die Negativkontrolle beweist das Gegenstueck: dass die
# Geometriepruefungen bei schlechter AUSGABE anschlagen. Sie nimmt ein KORREKTES
# SVG, verletzt es an genau einer Stelle und stellt sicher, dass ein Befund
# faellt. Eine Pruefung, die nie anschlaegt, beweist nichts.

def _generator():
    """Den Generator holen — auch wenn nur scripts/figures auf dem Pfad liegt."""
    try:
        from figures.dreieck import dreieck
    except ImportError:
        import sys
        from pathlib import Path

        sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
        from figures.dreieck import dreieck
    return dreieck


def _linie_verschieben(svg: str, index: int, feld: str, delta: float) -> str:
    """Ein Koordinatenfeld der `index`-ten <line> verschieben ('x1'…'y2')."""
    stand = {'n': 0}

    def einmal(treffer: re.Match) -> str:
        n = stand['n']
        stand['n'] = n + 1
        if n != index:
            return treffer.group(0)
        return re.sub(
            rf'({feld}=")([\d.-]+)(")',
            lambda t: f'{t.group(1)}{float(t.group(2)) + delta:g}{t.group(3)}',
            treffer.group(0), count=1,
        )

    return re.sub(r'<line\b[^>]*/>', einmal, svg)


def _punkt_verschieben(svg: str, index: int, punkt: int, dx: float, dy: float) -> str:
    """Einen einzelnen Punkt der `index`-ten <polyline> verschieben."""
    stand = {'n': 0}

    def einmal(treffer: re.Match) -> str:
        n = stand['n']
        stand['n'] = n + 1
        if n != index:
            return treffer.group(0)

        def punkte(t: re.Match) -> str:
            paare = t.group(1).split(' ')
            x, y = paare[punkt].split(',')
            paare[punkt] = f'{float(x) + dx:g},{float(y) + dy:g}'
            return f'points="{" ".join(paare)}"'

        return re.sub(r'points="([^"]+)"', punkte, treffer.group(0), count=1)

    return re.sub(r'<polyline\b[^>]*/>', einmal, svg)


def _polylinie_schieben(svg: str, index: int, dx: float, dy: float) -> str:
    """Eine ganze <polyline> verschieben — das Zeichen wandert an eine andere Ecke."""
    stand = {'n': 0}

    def einmal(treffer: re.Match) -> str:
        n = stand['n']
        stand['n'] = n + 1
        if n != index:
            return treffer.group(0)

        def punkte(t: re.Match) -> str:
            paare = []
            for paar in t.group(1).split(' '):
                x, y = paar.split(',')
                paare.append(f'{float(x) + dx:g},{float(y) + dy:g}')
            return f'points="{" ".join(paare)}"'

        return re.sub(r'points="([^"]+)"', punkte, treffer.group(0), count=1)

    return re.sub(r'<polyline\b[^>]*/>', einmal, svg)


def _zickzack_entfernen(svg: str) -> str:
    """Das Zickzack loeschen — aus der gekappten wird eine still gestauchte Figur."""
    for treffer in re.finditer(r'<polyline\b[^>]*/>', svg):
        if len(_floats(re.search(r'points="([^"]+)"', treffer.group(0)).group(1))) == 10:
            return svg.replace(treffer.group(0), '', 1)
    raise ValueError('kein Zickzack im SVG — die Vorlage war nicht gekappt.')


def _zahlendreher(svg: str) -> str:
    """Die Ziffern der ersten Masszahl vertauschen — der klassische Zahlendreher."""
    return re.sub(
        r'(<text\b[^>]*>)(\d+)( )',
        lambda t: f'{t.group(1)}{t.group(2)[::-1]}{t.group(3)}',
        svg, count=1,
    )


def negativkontrolle() -> list[tuple[str, bool, list[str]]]:
    """
    Verletzungen an korrekten SVGs. Rueckgabe je Fall:
    (Name, hat_angeschlagen, Befunde). hat_angeschlagen == False ist ein
    Versagen der Pruefung selbst.
    """
    dreieck = _generator()

    schief = {'grundseite': 8, 'hoehe': 5, 'art': 'beliebig', 'einheit': 'cm'}
    gleich = {'grundseite': 6, 'hoehe': 4, 'art': 'gleichschenklig', 'einheit': 'cm'}
    recht = {'grundseite': 6, 'hoehe': 4, 'art': 'rechtwinklig', 'einheit': 'cm'}
    hoch = {'grundseite': 2, 'hoehe': 40, 'art': 'beliebig', 'einheit': 'm'}
    flach = {'grundseite': 40, 'hoehe': 2, 'art': 'beliebig', 'einheit': 'm'}

    # Element-Reihenfolge im SVG (fuer die Indizes unten):
    #   polyline 0 = Umriss, 1 = rechtwinkliges Zeichen, 2 = Zickzack
    #   line     0 = gestrichelte Hoehe (nur wenn art != 'rechtwinklig'),
    #            danach Masslinie Grundseite, Masslinie Hoehe
    faelle = [
        ('Spitze angehoben (Verhaeltnis stimmt nicht mehr)',
         _punkt_verschieben(dreieck(**schief), 0, 2, 0.0, -30.0), schief),
        ('Grundseite verkuerzt (Verhaeltnis stimmt nicht mehr)',
         _punkt_verschieben(dreieck(**schief), 0, 1, -40.0, 0.0), schief),
        ('Hoehenlinie gekippt (nicht mehr senkrecht)',
         _linie_verschieben(dreieck(**schief), 0, 'x2', 12.0), schief),
        ('Schenkel ungleich lang trotz art="gleichschenklig"',
         _punkt_verschieben(dreieck(**gleich), 0, 2, 25.0, 0.0), gleich),
        ('Winkelzeichen an der falschen Ecke',
         _polylinie_schieben(dreieck(**recht), 1, 60.0, 0.0), recht),
        ('Zickzack entfernt (stille Stauchung, zu hohe Figur)',
         _zickzack_entfernen(dreieck(**hoch)), hoch),
        ('Zickzack entfernt (stille Stauchung, zu flache Figur)',
         _zickzack_entfernen(dreieck(**flach)), flach),
        ('Zahlendreher im Masstext',
         _zahlendreher(dreieck(grundseite=52, hoehe=25, einheit='cm')),
         {'grundseite': 52, 'hoehe': 25, 'einheit': 'cm'}),
        ('Masslinie der Grundseite zu kurz',
         _linie_verschieben(dreieck(**schief), 1, 'x2', -30.0), schief),
        ('Ecke aus dem Rahmen geschoben',
         _punkt_verschieben(dreieck(**schief), 0, 1, 9000.0, 0.0), schief),
    ]

    ergebnis = []
    for name, svg, params in faelle:
        befunde = pruefe_geometrie(svg, params)
        ergebnis.append((name, bool(befunde), befunde))
    return ergebnis


def _main() -> int:
    print('Negativkontrolle — jede Zeile ist ein absichtlich kaputtes SVG.')
    print('Die Pruefung MUSS bei jeder anschlagen; Stille waere das Versagen.\n')
    alle_gut = True
    for name, angeschlagen, befunde in negativkontrolle():
        marke = 'ANGESCHLAGEN' if angeschlagen else 'STILL GEBLIEBEN (!!)'
        print(f'[{marke}] {name}')
        for befund in befunde:
            print(f'    -> {befund}')
        if not angeschlagen:
            alle_gut = False
        print()

    if not alle_gut:
        print('FEHLER: mindestens eine Verletzung blieb unentdeckt.')
        return 1
    print('Alle Verletzungen wurden erkannt.')
    return 0


if __name__ == '__main__':
    raise SystemExit(_main())
