#!/usr/bin/env python3
"""
Geometriepruefungen fuer den Winkel-Generator — IMPORTIERBAR.

WOZU: `upload_figures.py` (A19) laedt nichts hoch, was `pruefe(svg, params)`
nicht besteht. Ein falsches Bild ist schlimmer als kein Bild — und beim Winkel
ist "falsch" besonders unauffaellig: 110 Grad und 250 Grad haben DIESELBEN zwei
Schenkel. Wer den Bogen auf die falsche Seite legt, zeigt den Gegenwinkel, und
die Figur sieht dabei vollkommen in Ordnung aus.

WIE: Nicht die Parameter nachrechnen, sondern das ERZEUGTE SVG zurueckmessen.
Jede Pruefung liest Koordinaten aus dem SVG-Text, rekonstruiert daraus Scheitel,
Schenkelrichtungen und Bogenverlauf und haelt das gegen die Parameter:

  r) alles Gezeichnete liegt im Rahmen, width/height deckt die viewBox
  s) beide Schenkel gehen vom SELBEN Punkt aus
  u) der Grundschenkel ist waagerecht und zeigt nach rechts
  w) KERNPRUEFUNG: der gemessene Winkel zwischen den Schenkeln ist `grad`
  b) der Bogen laeuft vom Grundschenkel bis zum zweiten Schenkel und
     UEBERSTREICHT `grad` — bei ueberstumpfen Winkeln also aussen herum
  q) bei genau 90 Grad steht das rechteckige Zeichen und KEIN Bogen
  z) Gradzahl und Benennung tragen den Wert der Parameter und stehen an der
     Seite, an die sie gehoeren

Der Scheitel wird NIE aus den Parametern uebernommen — er wird als der
gemeinsame Punkt der beiden laengsten Linien zurueckgerechnet. Nur so schlaegt
ein Versatz an, der die Winkelweite unveraendert laesst.

Die SVG-Leser hier sind absichtlich eigene und nicht aus
`pruefe_koordinatensystem.py` importiert: die Pruefung eines Generators soll
nicht an den Interna eines anderen haengen.
"""

from __future__ import annotations

import math
import re

# Toleranzen. Koordinaten stehen auf zwei Nachkommastellen (svg_basis STELLEN=2);
# ein echter Fehler ist immer groesser.
EPS_PIXEL = 0.5      # Scheitel, Waagerechte, Rahmen: gezeichnet == round(soll, 2)
EPS_GRAD = 0.5       # Kernpruefung: gemessener Winkel gegen `grad`
EPS_RADIUS = 1.0     # Streuung des Bogenradius (ist der Bogen ein Kreisbogen?)
EPS_RUECKWAERTS = 0.1  # zulaessiger Rueckschritt im Bogen (nur Rundung)
EPS_TEXT_GRAD = 2.0  # Winkelabstand eines Textankers von seiner Sollrichtung
EPS_ZAHL = 0.02      # Gradzahl im Text gegen `grad` (zwei Nachkommastellen)

# Wie in winkel.py: "genau 90 Grad" heisst genau 90 Grad.
EPS_RECHTER = 1e-9


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


def _linien(svg: str) -> list[tuple[float, float, float, float]]:
    return [
        (float(m.group(1)), float(m.group(2)), float(m.group(3)), float(m.group(4)))
        for m in re.finditer(
            r'<line x1="([\d.-]+)" y1="([\d.-]+)" x2="([\d.-]+)" y2="([\d.-]+)"', svg
        )
    ]


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


# ── Winkel-Geometrie ─────────────────────────────────────────────────────────

def _laenge(strich: tuple[float, float, float, float]) -> float:
    return math.hypot(strich[2] - strich[0], strich[3] - strich[1])


def _richtung_grad(scheitel: tuple[float, float], punkt: tuple[float, float]) -> float:
    """
    Richtung von `scheitel` nach `punkt` in Grad, 0 bis 360, gegen den
    Uhrzeigersinn von der Waagerechten nach rechts.

    Das getauschte Vorzeichen bei y dreht die SVG-Spiegelung zurueck: im Bild
    waechst y nach unten, im Winkelmass nach oben.
    """
    return math.degrees(math.atan2(scheitel[1] - punkt[1], punkt[0] - scheitel[0])) % 360.0


def _ccw(von: float, bis: float) -> float:
    """Weg von `von` nach `bis` gegen den Uhrzeigersinn, 0 bis 360."""
    return (bis - von) % 360.0


def _gewickelt(differenz: float) -> float:
    """Eine Winkeldifferenz auf (-180, 180] gebracht."""
    return (differenz + 180.0) % 360.0 - 180.0


def _grad_nah(ist: float, soll: float, eps: float) -> bool:
    """Vergleich MODULO 360: 359,99 und -0,01 sind derselbe Winkel."""
    return abs(_gewickelt(ist - soll)) <= eps


def _gemeinsamer_punkt(
    a: tuple[float, float, float, float],
    b: tuple[float, float, float, float],
) -> tuple[float, float, list[tuple[float, float]]]:
    """
    Der Punkt, in dem sich zwei Striche treffen — zurueckgerechnet, nicht gesetzt.

    Rueckgabe: (Abstand der beiden dichtesten Enden, Mittelpunkt daraus, die
    beiden ANDEREN Enden). Ist der Abstand gross, treffen sich die Striche
    nicht; der Aufrufer meldet das als Befund.
    """
    ecken_a = [(a[0], a[1]), (a[2], a[3])]
    ecken_b = [(b[0], b[1]), (b[2], b[3])]
    i, j = min(
        ((i, j) for i in (0, 1) for j in (0, 1)),
        key=lambda ij: math.dist(ecken_a[ij[0]], ecken_b[ij[1]]),
    )
    nah_a, nah_b = ecken_a[i], ecken_b[j]
    treffpunkt = ((nah_a[0] + nah_b[0]) / 2.0, (nah_a[1] + nah_b[1]) / 2.0)
    return math.dist(nah_a, nah_b), treffpunkt, [ecken_a[1 - i], ecken_b[1 - j]]


# ── Rueckgerechnete Figur ────────────────────────────────────────────────────

class Figur:
    """
    Scheitel, Schenkel und Bogen, ausschliesslich AUS DEM SVG zurueckgerechnet.

    Die beiden Schenkel sind die zwei LAENGSTEN Linien. Das trennt sie sicher
    vom rechtwinkligen Zeichen (Seite 30 px gegen Schenkel 110 px), ohne dass
    die Pruefung die Masse des Generators kennen muesste.
    """

    def __init__(self, svg: str) -> None:
        self.breite, self.hoehe = _kopf(svg)
        self.viewbox = _viewbox(svg)
        self.linien = _linien(svg)
        self.polylinien = _polylinien(svg)
        self.texte = _texte(svg)

        if len(self.linien) < 2:
            raise ValueError(
                f'nur {len(self.linien)} <line>-Element(e) im SVG — ein Winkel '
                f'braucht zwei Schenkel.'
            )

        # Nach Laenge absteigend, bei Gleichstand nach Koordinaten: die Auswahl
        # darf nicht von der Reihenfolge im Dokument abhaengen.
        geordnet = sorted(self.linien, key=lambda strich: (-_laenge(strich), strich))
        self.schenkel = geordnet[:2]
        self.kurz = geordnet[2:]

        self.scheitel_abstand, self.scheitel, enden = _gemeinsamer_punkt(*self.schenkel)
        self.laengen = [math.dist(self.scheitel, ende) for ende in enden]

        # Der Grundschenkel ist der waagerechte. Bei einem Winkel knapp unter
        # 360 Grad liegt der zweite Schenkel fast auch waagerecht — entschieden
        # wird nach dem KLEINEREN senkrechten Versatz, und das ist der exakt
        # waagerechte. Beim gestreckten Winkel (180 Grad) sind BEIDE Schenkel
        # exakt waagerecht; dann entscheidet die Richtung, und Bezug ist der
        # nach rechts zeigende. Ohne diesen zweiten Schluessel haengt es an der
        # Reihenfolge im Dokument, ob die Figur richtig gelesen wird.
        versatz = [abs(ende[1] - self.scheitel[1]) for ende in enden]
        nach_rechts = [ende[0] - self.scheitel[0] for ende in enden]
        i = 0 if (versatz[0], -nach_rechts[0]) <= (versatz[1], -nach_rechts[1]) else 1
        self.grund_ende, self.zweites_ende = enden[i], enden[1 - i]
        self.grund_versatz = versatz[i]
        self.grund_richtung = _richtung_grad(self.scheitel, self.grund_ende)
        self.zweite_richtung = _richtung_grad(self.scheitel, self.zweites_ende)
        self.schenkel_laenge = min(self.laengen)

    def gemessener_winkel(self) -> float:
        """Der ueberstrichene Winkel: vom Grundschenkel gegen den Uhrzeigersinn."""
        return _ccw(self.grund_richtung, self.zweite_richtung)

    def richtung(self, punkt: tuple[float, float]) -> float:
        """Richtung eines Punkts, gemessen ab dem Grundschenkel."""
        return _ccw(self.grund_richtung, _richtung_grad(self.scheitel, punkt))


def _grad(params: dict) -> float:
    return float(params['grad'])


def _mit_bogen(params: dict) -> bool:
    # Wie der Generator: ohne Angabe wird das Winkelzeichen gezeichnet.
    return bool(params.get('mit_bogen', True))


def _ist_rechter(grad: float) -> bool:
    return abs(grad - 90.0) < EPS_RECHTER


# ── Einzelpruefungen: SVG-Text rein, Befunde raus ────────────────────────────

def pruefe_rahmen(svg: str, params: dict) -> list[str]:
    """
    r) Der Rahmen deckt die Figur: viewBox == width/height, und kein
    gezeichneter Punkt liegt draussen.

    Ein Schenkel, der aus dem Rahmen laeuft, wird beim Rendern weggeschnitten —
    die Abbildung ist dann unauffaellig unvollstaendig, der schlimmste Fall.
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

    punkte: list[tuple[float, float]] = []
    for strich in figur.linien:
        punkte.extend([(strich[0], strich[1]), (strich[2], strich[3])])
    for zug in figur.polylinien:
        punkte.extend(zug)
    punkte.extend([(x, y) for x, y, _ in figur.texte])

    for x, y in punkte:
        if not (-EPS_PIXEL <= x <= figur.breite + EPS_PIXEL
                and -EPS_PIXEL <= y <= figur.hoehe + EPS_PIXEL):
            befunde.append(
                f'r) Punkt ({x}, {y}) liegt ausserhalb des Rahmens '
                f'(0..{figur.breite} x 0..{figur.hoehe}) — er wuerde weggeschnitten.'
            )
    return befunde


def pruefe_scheitel(svg: str, params: dict) -> list[str]:
    """s) Beide Schenkel gehen vom SELBEN Punkt aus."""
    figur = Figur(svg)
    if figur.scheitel_abstand > EPS_PIXEL:
        return [
            f's) die Schenkel treffen sich nicht: ihre naechsten Enden liegen '
            f'{figur.scheitel_abstand:.2f} px auseinander. Ohne gemeinsamen '
            f'Scheitel ist die Figur kein Winkel.'
        ]
    return []


def pruefe_grundschenkel(svg: str, params: dict) -> list[str]:
    """
    u) Der Grundschenkel ist waagerecht und zeigt nach rechts.

    "Unten" meint den Bezug, nicht die Bildlage: bei einem ueberstumpfen Winkel
    liegt der zweite Schenkel UNTER dem waagerechten. Gemessen wird der Bezug.
    """
    figur = Figur(svg)
    befunde: list[str] = []
    if figur.grund_versatz > EPS_PIXEL:
        befunde.append(
            f'u) kein waagerechter Schenkel: der flachste weicht um '
            f'{figur.grund_versatz:.2f} px von der Waagerechten ab.'
        )
    if figur.grund_ende[0] <= figur.scheitel[0]:
        befunde.append(
            f'u) der waagerechte Schenkel zeigt nicht nach rechts '
            f'(Scheitel x={figur.scheitel[0]:.2f}, Ende x={figur.grund_ende[0]:.2f}).'
        )
    return befunde


def pruefe_winkelmass(svg: str, params: dict) -> list[str]:
    """
    w) DIE KERNPRUEFUNG: der gemessene Winkel zwischen den Schenkeln ist `grad`.

    Gemessen wird gegen den Uhrzeigersinn vom Grundschenkel aus — also
    gerichtet. Waere der zweite Schenkel spiegelbildlich gezeichnet, kaeme
    360 - grad heraus, und das faellt hier durch. Eine ungerichtete Messung
    (nur der kleinere der beiden Winkel) waere bei jedem ueberstumpfen Winkel
    blind.
    """
    figur = Figur(svg)
    soll = _grad(params)
    gemessen = figur.gemessener_winkel()
    if not _grad_nah(gemessen, soll, EPS_GRAD):
        return [
            f'w) gemessener Winkel {gemessen:.3f}°, verlangt {soll:g}° '
            f'(Abweichung {abs(_gewickelt(gemessen - soll)):.3f}°).'
        ]
    return []


def pruefe_bogen(svg: str, params: dict) -> list[str]:
    """
    b) Der Bogen laeuft vom Grundschenkel bis zum zweiten Schenkel und
    ueberstreicht dabei `grad`.

    Der ueberstrichene Weg ist die Summe der Einzelschritte, nicht die
    Differenz der Endpunkte: ein Bogen von 0 nach 250 Grad und einer von 0 nach
    -110 Grad haben DIESELBEN Endpunkte. Nur die Summe unterscheidet sie — und
    genau diese Verwechslung macht aus 250 Grad den Gegenwinkel.
    """
    figur = Figur(svg)
    grad = _grad(params)
    befunde: list[str] = []

    if not _mit_bogen(params):
        if figur.polylinien:
            befunde.append(
                f'b) mit_bogen=False, aber {len(figur.polylinien)} Bogenelement(e) '
                f'im SVG — die Gradzahl waere im Bild und die Aufgabe verraten.'
            )
        if figur.kurz:
            befunde.append(
                f'b) mit_bogen=False, aber {len(figur.kurz)} zusaetzliche Linie(n) '
                f'neben den Schenkeln.'
            )
        return befunde

    if _ist_rechter(grad):
        if figur.polylinien:
            befunde.append(
                'b) bei genau 90° darf kein Bogenelement stehen — an seine '
                'Stelle tritt das rechteckige Zeichen.'
            )
        return befunde

    if len(figur.polylinien) != 1:
        return [f'b) {len(figur.polylinien)} Bogenelement(e) im SVG, erwartet genau eines.']
    if figur.kurz:
        befunde.append(
            f'b) {len(figur.kurz)} zusaetzliche Linie(n) neben den Schenkeln, '
            f'obwohl der Winkel kein rechter ist.'
        )

    zug = figur.polylinien[0]
    if len(zug) < 5:
        return befunde + [f'b) Bogen mit nur {len(zug)} Punkten — kein Bogen.']

    radien = [math.dist(figur.scheitel, punkt) for punkt in zug]
    if max(radien) - min(radien) > EPS_RADIUS:
        befunde.append(
            f'b) der Bogen ist kein Kreisbogen um den Scheitel: Radius schwankt '
            f'zwischen {min(radien):.2f} und {max(radien):.2f} px.'
        )
    if max(radien) >= figur.schenkel_laenge:
        befunde.append(
            f'b) der Bogen (Radius bis {max(radien):.2f} px) liegt nicht innerhalb '
            f'der Schenkel ({figur.schenkel_laenge:.2f} px).'
        )

    if not _grad_nah(figur.richtung(zug[0]), 0.0, EPS_GRAD):
        befunde.append(
            f'b) der Bogen beginnt {figur.richtung(zug[0]):.3f}° neben dem '
            f'Grundschenkel statt an ihm.'
        )
    if not _grad_nah(figur.richtung(zug[-1]), grad, EPS_GRAD):
        befunde.append(
            f'b) der Bogen endet bei {figur.richtung(zug[-1]):.3f}° statt bei '
            f'{grad:g}° — er trifft den zweiten Schenkel nicht.'
        )

    richtungen = [_richtung_grad(figur.scheitel, punkt) for punkt in zug]
    schritte = [
        _gewickelt(richtungen[i + 1] - richtungen[i]) for i in range(len(richtungen) - 1)
    ]
    rueckwaerts = [s for s in schritte if s < -EPS_RUECKWAERTS]
    if rueckwaerts:
        befunde.append(
            f'b) der Bogen laeuft an {len(rueckwaerts)} Stelle(n) zurueck '
            f'(kleinster Schritt {min(schritte):.3f}°) — er ist nicht monoton.'
        )
    ueberstrichen = sum(schritte)
    if abs(ueberstrichen - grad) > EPS_GRAD:
        befunde.append(
            f'b) der Bogen ueberstreicht {ueberstrichen:.3f}° statt {grad:g}°. '
            f'Bei {grad:g}° liegt er '
            f'{"aussen" if grad > 180 else "innen"} — so zeigt die Figur den '
            f'Gegenwinkel ({360 - grad:g}°), und das sieht niemand.'
        )
    return befunde


def pruefe_rechter_winkel(svg: str, params: dict) -> list[str]:
    """
    q) Bei genau 90 Grad steht das rechteckige Zeichen: zwei kurze Striche, die
    sich auf der Winkelhalbierenden treffen und auf den Schenkeln enden.

    Und der Gegenfall: bei jedem anderen Winkel darf es NICHT stehen. Ein
    rechtwinkliges Zeichen an einem Winkel von 88 Grad ist eine falsche Zusage,
    mit der man weiterrechnet.
    """
    figur = Figur(svg)
    grad = _grad(params)

    if not (_ist_rechter(grad) and _mit_bogen(params)):
        if figur.kurz:
            return [
                f'q) {len(figur.kurz)} kurze Linie(n) neben den Schenkeln, obwohl '
                f'kein rechtwinkliges Zeichen verlangt ist (grad={grad:g}, '
                f'mit_bogen={_mit_bogen(params)}).'
            ]
        return []

    if len(figur.kurz) != 2:
        return [
            f'q) das rechteckige Zeichen braucht zwei Striche, gefunden sind '
            f'{len(figur.kurz)}.'
        ]

    befunde: list[str] = []
    abstand, ecke, aussen = _gemeinsamer_punkt(*figur.kurz)
    if abstand > EPS_PIXEL:
        befunde.append(
            f'q) die beiden Striche des Zeichens treffen sich nicht '
            f'({abstand:.2f} px auseinander).'
        )

    # Die beiden freien Enden liegen auf den Schenkeln (0 und 90 Grad), in
    # gleichem Abstand vom Scheitel — sonst ist das Zeichen kein Quadrat.
    richtungen = sorted(figur.richtung(punkt) for punkt in aussen)
    if not (_grad_nah(richtungen[0], 0.0, EPS_TEXT_GRAD)
            and _grad_nah(richtungen[1], 90.0, EPS_TEXT_GRAD)):
        befunde.append(
            f'q) die freien Enden des Zeichens liegen bei '
            f'{richtungen[0]:.2f}° und {richtungen[1]:.2f}° statt auf den '
            f'Schenkeln (0° und 90°).'
        )
    seiten = [math.dist(figur.scheitel, punkt) for punkt in aussen]
    if abs(seiten[0] - seiten[1]) > EPS_PIXEL:
        befunde.append(
            f'q) das Zeichen ist kein Quadrat: die Enden liegen {seiten[0]:.2f} px '
            f'und {seiten[1]:.2f} px vom Scheitel entfernt.'
        )

    # Die Ecke liegt auf der Winkelhalbierenden, im Wurzel-Zwei-fachen Abstand.
    if not _grad_nah(figur.richtung(ecke), 45.0, EPS_TEXT_GRAD):
        befunde.append(
            f'q) die Ecke des Zeichens liegt bei {figur.richtung(ecke):.2f}° statt '
            f'auf der Winkelhalbierenden (45°).'
        )
    soll_ecke = min(seiten) * math.sqrt(2.0)
    ist_ecke = math.dist(figur.scheitel, ecke)
    if abs(ist_ecke - soll_ecke) > EPS_PIXEL:
        befunde.append(
            f'q) die Ecke liegt {ist_ecke:.2f} px vom Scheitel entfernt, '
            f'erwartet {soll_ecke:.2f} px.'
        )
    return befunde


def pruefe_beschriftung(svg: str, params: dict) -> list[str]:
    """
    z) Gradzahl und Benennung: der richtige Wert an der richtigen Seite.

    Die Gradzahl wird nicht auf Zeichengleichheit geprueft, sondern
    ZURUECKGELESEN und als Zahl verglichen — ein Zahlendreher ('52°' zu '25°')
    ist genau der Fehler, den an einer Abbildung niemand nachrechnet.

    Zugeordnet wird ueber die LAGE, nicht ueber den Inhalt: die Gradzahl steht
    auf der Winkelhalbierenden, die Benennung ihr gegenueber. So bleibt die
    Zuordnung auch dann eindeutig, wenn die Benennung selbst nach einer Zahl
    aussieht.
    """
    figur = Figur(svg)
    grad = _grad(params)
    benennung = params.get('benennung')
    mit_bogen = _mit_bogen(params)

    erwartet = (1 if mit_bogen else 0) + (1 if benennung is not None else 0)
    if len(figur.texte) != erwartet:
        return [
            f'z) {len(figur.texte)} Textknoten im SVG, erwartet {erwartet} '
            f'(mit_bogen={mit_bogen}, benennung={benennung!r}).'
        ]

    befunde: list[str] = []
    if mit_bogen:
        soll_richtung = grad / 2.0
        treffer = [
            inhalt for x, y, inhalt in figur.texte
            if _grad_nah(figur.richtung((x, y)), soll_richtung, EPS_TEXT_GRAD)
        ]
        if len(treffer) != 1:
            befunde.append(
                f'z) {len(treffer)} Text(e) auf der Winkelhalbierenden '
                f'({soll_richtung:g}°), erwartet genau die Gradzahl.'
            )
        else:
            gelesen = _als_grad(treffer[0])
            if gelesen is None:
                befunde.append(
                    f'z) der Text am Bogen ({treffer[0]!r}) ist keine Gradangabe.'
                )
            elif abs(gelesen - grad) > EPS_ZAHL:
                befunde.append(
                    f'z) die Gradzahl am Bogen sagt {gelesen:g}°, die Figur zeigt '
                    f'{grad:g}°.'
                )

    if benennung is not None:
        soll_richtung = (grad / 2.0 + 180.0) % 360.0
        treffer = [
            inhalt for x, y, inhalt in figur.texte
            if _grad_nah(figur.richtung((x, y)), soll_richtung, EPS_TEXT_GRAD)
        ]
        if len(treffer) != 1:
            befunde.append(
                f'z) {len(treffer)} Text(e) am Scheitel gegenueber dem Bogen '
                f'({soll_richtung:g}°), erwartet die Benennung {benennung!r}.'
            )
        elif treffer[0] != benennung:
            befunde.append(
                f'z) die Benennung im SVG ist {treffer[0]!r}, verlangt {benennung!r}.'
            )
    return befunde


def _als_grad(inhalt: str) -> float | None:
    """'45,5°' -> 45.5. None, wenn der Text keine Gradangabe ist."""
    text = inhalt.strip()
    if not text.endswith('°'):
        return None
    try:
        return float(text[:-1].replace(',', '.'))
    except ValueError:
        return None


# ── Sammelpruefung + Adapter fuer den Upload ─────────────────────────────────

_ALLE = (
    pruefe_rahmen,
    pruefe_scheitel,
    pruefe_grundschenkel,
    pruefe_winkelmass,
    pruefe_bogen,
    pruefe_rechter_winkel,
    pruefe_beschriftung,
)


def pruefe_geometrie(svg: str, params: dict) -> list[str]:
    """
    Alle Geometriepruefungen. Leere Liste heisst: nichts gefunden.

    Ein SVG, das sich nicht lesen laesst (keine zwei Linien, keine viewBox),
    ergibt einen BEFUND und keine Ausnahme: der Aufrufer ist der Upload, und
    der soll nichts laden statt abzustuerzen.
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
        from figures.winkel import winkel
    except ImportError:
        import sys
        from pathlib import Path

        sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
        from figures.winkel import winkel
    return winkel


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


def _bogen_ersetzen(svg: str, quelle: str) -> str:
    """Den Bogen durch den aus einem anderen SVG ersetzen (falsche Seite)."""
    stueck = re.search(r'<polyline\b[^>]*/>', quelle)
    if stueck is None:
        raise ValueError('Quelle ohne Bogen.')
    return re.sub(r'<polyline\b[^>]*/>', stueck.group(0), svg, count=1)


def _bogen_einfuegen(svg: str, quelle: str) -> str:
    """Einen Bogen in ein SVG legen, das keinen haben darf (90 Grad)."""
    stueck = re.search(r'<polyline\b[^>]*/>', quelle)
    if stueck is None:
        raise ValueError('Quelle ohne Bogen.')
    return svg.replace('</svg>', f'{stueck.group(0)}\n</svg>', 1)


def _gradzahl_verdrehen(svg: str) -> str:
    """Die Ziffern der Gradzahl vertauschen — der klassische Zahlendreher."""
    return re.sub(
        r'(>)(\d+)(°</text>)',
        lambda t: f'{t.group(1)}{t.group(2)[::-1]}{t.group(3)}',
        svg, count=1,
    )


def negativkontrolle() -> list[tuple[str, bool, list[str]]]:
    """
    Verletzungen an korrekten SVGs. Rueckgabe je Fall:
    (Name, hat_angeschlagen, Befunde). hat_angeschlagen == False ist ein
    Versagen der Pruefung selbst.
    """
    winkel = _generator()

    schraeg = {'grad': 60}
    ueberstumpf = {'grad': 250}
    recht = {'grad': 90}
    dreher = {'grad': 52}

    faelle = [
        ('zweiter Schenkel verdreht (falsche Winkelweite)',
         _linie_verschieben(winkel(**schraeg), 1, 'y2', 20.0), schraeg),
        ('Grundschenkel gekippt (nicht mehr waagerecht)',
         _linie_verschieben(winkel(**schraeg), 0, 'y2', 6.0), schraeg),
        ('Schenkel ohne gemeinsamen Scheitel',
         _linie_verschieben(winkel(**schraeg), 1, 'x1', 8.0), schraeg),
        ('Schenkel aus dem Rahmen geschoben',
         _linie_verschieben(winkel(**schraeg), 1, 'x2', 9000.0), schraeg),
        ('Bogen auf der falschen Seite (Gegenwinkel gezeigt)',
         _bogen_ersetzen(winkel(**ueberstumpf), winkel(grad=110)), ueberstumpf),
        ('Bogenelement bei genau 90 Grad',
         _bogen_einfuegen(winkel(**recht), winkel(grad=89)), recht),
        ('rechteckiges Zeichen verschoben',
         _linie_verschieben(_linie_verschieben(winkel(**recht), 2, 'x1', 7.0),
                            2, 'x2', 7.0), recht),
        ('Zahlendreher in der Gradzahl',
         _gradzahl_verdrehen(winkel(**dreher)), dreher),
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
