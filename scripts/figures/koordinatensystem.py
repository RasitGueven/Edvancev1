#!/usr/bin/env python3
"""
Parametrischer Generator: Koordinatensystem mit Funktionen und Punkten.

WARUM ES DEN GENERATOR GIBT: Excel und GeoGebra sind Handarbeit. Handarbeit
skaliert nicht und laesst sich nicht nachrechnen. Hier kommt die Korrektheit aus
den Parametern und das Design aus den Tokens — beides pruefbar.

WARUM SORGFALT: Ein falsches Bild ist schlimmer als kein Bild. Bei Text faellt
ein Fehler in der fachlichen Pruefung auf; einen Zahlendreher in der Skalierung
sieht niemand. Die Eingaben laufen deshalb durch `pruefungen.py`, und dort
faellt alles durch, was sich nicht sauber darstellen laesst:
  - Bounds muessen ganzzahlig sein und in der richtigen Reihenfolge stehen.
  - Unbekannte Schluessel in einer Funktions- oder Punktangabe sind ein Fehler,
    kein stiller Verzicht ('labl' statt 'label' wuerde sonst die Beschriftung
    verschlucken).
  - Ein Punkt ausserhalb des Fensters ist ein Fehler. Er wuerde weggeschnitten,
    und die Abbildung waere unauffaellig unvollstaendig — der schlimmste Fall.

GLEICHE SKALIERUNG IST BAULICH GARANTIERT: Es gibt genau EINEN Faktor
`einheit` (px pro Einheit) fuer beide Achsen. Eine getrennte x-/y-Skalierung
ist nicht konfigurierbar, also auch nicht versehentlich einstellbar. Damit misst
eine Einheit auf x exakt so viele Pixel wie auf y, eine Steigung von 1 steht
unter 45 Grad und eine Parabel ist nicht gestaucht.
"""

from __future__ import annotations

from .pruefungen import (
    ganzzahl,
    pruefe_funktion,
    pruefe_punkt,
    text_oder_none,
    wahrheitswert,
)
from .svg_basis import (
    beschriftung,
    dokument,
    element,
    kreis,
    linie,
    polygon,
    polylinie,
    zahl,
)
from .tokens import SCHRIFT, palette

# px pro Einheit. Bei -5..5 in beiden Richtungen ergibt das 400 x 400 px Flaeche
# — gross genug, dass die Beschriftung auf der 340 px breiten Buehne lesbar
# bleibt, klein genug fuer den Report.
EINHEIT_STANDARD = 40

# Aussenrand. Traegt die Achsenzahlen, wenn eine Achse am Fensterrand steht
# (etwa bei x_min = 0), plus die Pfeilspitzen.
RAND = 34

# Feste ID. Die SVGs sind eigenstaendige Dateien; werden sie je INLINE in ein
# gemeinsames HTML-Dokument gelegt, kollidieren gleiche IDs — dann braucht der
# Aufrufer einen Praefix. Eine Zufalls-ID kommt nicht in Frage, sie zerstoert
# die Byte-Gleichheit.
CLIP_ID = 'edvance-plot'


# ── Geometrie ────────────────────────────────────────────────────────────────

def _y_wert(funktion: dict, x: float) -> float:
    if funktion['typ'] == 'linear':
        return funktion['m'] * x + funktion['b']
    return funktion['a'] * x * x + funktion['b'] * x + funktion['c']


def _segmente(
    funktion: dict,
    x_min: int,
    x_max: int,
    y_min: int,
    y_max: int,
    schritte: int,
) -> list[list[tuple[float, float]]]:
    """
    Die Kurve in sichtbare Abschnitte zerlegt (in Diagramm-, nicht Pixelkoordinaten).

    Zwei Dinge passieren hier zusammen:

    1. ABSCHNEIDEN. Eine Parabel verlaesst das Fenster oben und kommt weiter
       rechts zurueck. Ohne Zerlegung zoege der Streckenzug eine gerade Sehne
       quer durchs Bild — eine Linie, die die Funktion nie hatte.
    2. TOLERANZ. Behalten wird bis eine Einheit ueber den Rand hinaus, damit die
       Kurve die Fensterkante wirklich beruehrt statt kurz davor aufzuhoeren.
       Den Rest schneidet der clipPath exakt weg.

    Bei 'linear' wird jeder Abschnitt auf seine beiden Endpunkte reduziert: eine
    Gerade braucht keine Stuetzpunkte, und 400 statt 2 Koordinatenpaare
    aufzuschreiben macht die Datei nur groesser.
    """
    toleranz_unten = y_min - 1
    toleranz_oben = y_max + 1
    spanne = x_max - x_min

    abschnitte: list[list[tuple[float, float]]] = []
    laufend: list[tuple[float, float]] = []

    for i in range(schritte + 1):
        x = x_min + spanne * i / schritte
        y = _y_wert(funktion, x)
        if toleranz_unten <= y <= toleranz_oben:
            laufend.append((x, y))
        elif laufend:
            abschnitte.append(laufend)
            laufend = []
    if laufend:
        abschnitte.append(laufend)

    if funktion['typ'] == 'linear':
        abschnitte = [[teil[0], teil[-1]] if len(teil) > 1 else teil for teil in abschnitte]

    # Ein einzelner Punkt zeichnet keine Linie — er wuerde nur als leeres
    # <polyline> im Dokument stehen.
    return [teil for teil in abschnitte if len(teil) >= 2]


def _label_anker(
    funktion: dict,
    x_min: int,
    x_max: int,
    y_min: int,
    y_max: int,
    schritte: int,
) -> tuple[float, float] | None:
    """
    Der letzte Abtastpunkt INNERHALB des Fensters — dort sitzt die Beschriftung.

    Eigene Abtastung statt eines Blicks in `_segmente`, und zwar aus einem
    konkreten Grund: Dort wird eine Gerade auf ihre zwei Endpunkte reduziert,
    und deren oberer liegt im Toleranzband ausserhalb des Fensters. Ein Anker
    aus dieser Liste landete beim Test einer steigenden Geraden unten LINKS
    statt oben rechts — richtig gezeichnet, falsch beschriftet.
    """
    spanne = x_max - x_min
    letzter: tuple[float, float] | None = None
    for i in range(schritte + 1):
        x = x_min + spanne * i / schritte
        y = _y_wert(funktion, x)
        if y_min <= y <= y_max:
            letzter = (x, y)
    return letzter


# ── Hauptfunktion ────────────────────────────────────────────────────────────

def koordinatensystem(
    x_min: int,
    x_max: int,
    y_min: int,
    y_max: int,
    funktionen: list[dict] | None = None,
    punkte: list[dict] | None = None,
    gitter: bool = True,
    achsen: dict | None = None,
    theme: str = 'dunkel',
    einheit: int = EINHEIT_STANDARD,
) -> str:
    """
    Baut ein vollstaendiges SVG als String.

    x_min, x_max, y_min, y_max — Fenster, ganzzahlig, min < max.
    funktionen — [{'typ': 'linear', 'm':…, 'b':…, 'label'?, 'betont'?},
                  {'typ': 'quadratisch', 'a':…, 'b':…, 'c':…, 'label'?, 'betont'?}]
    punkte     — [{'x':…, 'y':…, 'label'?, 'betont'?}]
    gitter     — Einheitsraster hinter den Achsen.
    achsen     — {'x': 'x', 'y': 'y'}; einzelne Beschriftung leer lassen ('')
                 unterdrueckt sie.
    theme      — 'dunkel' (Buehne) oder 'hell' (Eltern-Report, Druck).
    einheit    — px pro Einheit, fuer BEIDE Achsen. Der einzige Skalenfaktor.

    Die Vorgaben stehen als None statt als [] bzw. {} — veraenderliche
    Standardwerte sind in Python geteilter Zustand ueber alle Aufrufe hinweg.
    Das Verhalten nach aussen ist dasselbe.
    """
    x_min = ganzzahl(x_min, 'x_min')
    x_max = ganzzahl(x_max, 'x_max')
    y_min = ganzzahl(y_min, 'y_min')
    y_max = ganzzahl(y_max, 'y_max')
    if x_min >= x_max:
        raise ValueError(f'x_min ({x_min}) muss kleiner als x_max ({x_max}) sein.')
    if y_min >= y_max:
        raise ValueError(f'y_min ({y_min}) muss kleiner als y_max ({y_max}) sein.')
    if isinstance(einheit, bool) or not isinstance(einheit, int) or einheit <= 0:
        raise ValueError(f'einheit muss eine positive ganze Zahl sein, nicht {einheit!r}.')

    farben = palette(theme)
    _gitter = wahrheitswert(gitter, 'gitter')

    if achsen is None:
        achsen = {'x': 'x', 'y': 'y'}
    if not isinstance(achsen, dict):
        raise ValueError(f'achsen muss ein dict sein, nicht {achsen!r}.')
    unbekannt = set(achsen) - {'x', 'y'}
    if unbekannt:
        namen = ', '.join(repr(s) for s in sorted(unbekannt))
        raise ValueError(f'achsen: unbekannte Schluessel: {namen}.')
    titel_x = text_oder_none(achsen.get('x', 'x'), "achsen['x']") or ''
    titel_y = text_oder_none(achsen.get('y', 'y'), "achsen['y']") or ''

    geprueft_f = [pruefe_funktion(f, i) for i, f in enumerate(funktionen or [])]
    grenzen = (x_min, x_max, y_min, y_max)
    geprueft_p = [pruefe_punkt(p, i, grenzen) for i, p in enumerate(punkte or [])]

    # ── Masse ────────────────────────────────────────────────────────────────
    breite_plot = (x_max - x_min) * einheit
    hoehe_plot = (y_max - y_min) * einheit
    breite = breite_plot + 2 * RAND
    hoehe = hoehe_plot + 2 * RAND
    links, oben = RAND, RAND
    rechts, unten = RAND + breite_plot, RAND + hoehe_plot

    def px(x: float) -> float:
        return links + (x - x_min) * einheit

    def py(y: float) -> float:
        return oben + (y_max - y) * einheit

    # Strichstaerken und Schrift skalieren mit der Einheit, damit eine Abbildung
    # mit einheit=20 nicht wie mit einem Filzstift gezeichnet aussieht.
    skala = einheit / EINHEIT_STANDARD
    stark_gitter = 1 * skala
    stark_achse = 1.5 * skala
    stark_kurve = 2.5 * skala
    stark_betont = 3.5 * skala
    schriftgroesse = 13 * skala

    # Achsenlage. Liegt die Null ausserhalb des Fensters, rueckt die Achse an
    # den Rand — die Teilstriche tragen dann trotzdem ihre echten Werte, es wird
    # also nichts Falsches behauptet, nur der Nullpunkt ist nicht im Bild.
    achse_y = min(max(py(0), oben), unten)      # Lage der x-Achse
    achse_x = min(max(px(0), links), rechts)    # Lage der y-Achse
    null_sichtbar = y_min <= 0 <= y_max and x_min <= 0 <= x_max

    inhalt: list[str] = []

    inhalt.append(element('clipPath', [('id', CLIP_ID)], element('rect', [
        ('x', zahl(links)), ('y', zahl(oben)),
        ('width', zahl(breite_plot)), ('height', zahl(hoehe_plot)),
    ])))

    # ── Gitter ───────────────────────────────────────────────────────────────
    if _gitter:
        striche = [
            linie(px(x), oben, px(x), unten, farben.gitter, stark_gitter)
            for x in range(x_min, x_max + 1)
        ] + [
            linie(links, py(y), rechts, py(y), farben.gitter, stark_gitter)
            for y in range(y_min, y_max + 1)
        ]
        inhalt.append(element('g', [('aria-hidden', 'true')], ''.join(striche)))

    # ── Achsen, Teilstriche, Zahlen ──────────────────────────────────────────
    achsen_teile = [
        linie(links, achse_y, rechts, achse_y, farben.achse, stark_achse),
        linie(achse_x, oben, achse_x, unten, farben.achse, stark_achse),
    ]

    # Pfeilspitzen als Dreiecke: keine Marker-Definition noetig, damit auch
    # Renderer ohne Marker-Unterstuetzung (manche Druck-Pipelines) sie zeigen.
    spitze = 5 * skala
    achsen_teile.append(polygon([
        (rechts + 9 * skala, achse_y),
        (rechts, achse_y - spitze),
        (rechts, achse_y + spitze),
    ], farben.achse))
    achsen_teile.append(polygon([
        (achse_x, oben - 9 * skala),
        (achse_x - spitze, oben),
        (achse_x + spitze, oben),
    ], farben.achse))

    strich = 4 * skala
    for x in range(x_min, x_max + 1):
        if x == 0:
            continue
        achsen_teile.append(
            linie(px(x), achse_y - strich, px(x), achse_y + strich, farben.achse, stark_achse)
        )
        achsen_teile.append(beschriftung(
            px(x), achse_y + strich + schriftgroesse, str(x),
            farben.beschriftung, schriftgroesse, SCHRIFT, anker='middle', grundlinie='middle',
        ))
    for y in range(y_min, y_max + 1):
        if y == 0:
            continue
        achsen_teile.append(
            linie(achse_x - strich, py(y), achse_x + strich, py(y), farben.achse, stark_achse)
        )
        achsen_teile.append(beschriftung(
            achse_x - strich - 4 * skala, py(y), str(y),
            farben.beschriftung, schriftgroesse, SCHRIFT, anker='end', grundlinie='middle',
        ))

    if null_sichtbar:
        # Die Null steht EINMAL, links unter dem Ursprung — nicht zweimal
        # uebereinander wie es zwei unabhaengige Achsenschleifen taeten.
        achsen_teile.append(beschriftung(
            achse_x - strich - 4 * skala, achse_y + strich + schriftgroesse, '0',
            farben.beschriftung, schriftgroesse, SCHRIFT, anker='end', grundlinie='middle',
        ))

    if titel_x:
        achsen_teile.append(beschriftung(
            rechts - 2 * skala, achse_y - schriftgroesse, titel_x,
            farben.beschriftung, schriftgroesse, SCHRIFT, anker='end', grundlinie='middle',
        ))
    if titel_y:
        achsen_teile.append(beschriftung(
            achse_x + schriftgroesse, oben + 2 * skala, titel_y,
            farben.beschriftung, schriftgroesse, SCHRIFT, anker='start', grundlinie='middle',
        ))

    inhalt.append(element('g', [], ''.join(achsen_teile)))

    # ── Funktionen ───────────────────────────────────────────────────────────
    # Ein Abtastpunkt je Pixel: feiner als die Ausgabe aufloest, damit eine
    # Parabel als Kurve und nicht als Polygonzug erscheint.
    schritte = max(2, int(breite_plot))
    kurven_teile: list[str] = []
    label_teile: list[str] = []
    for funktion in geprueft_f:
        farbe = farben.kurve_betont if funktion['betont'] else farben.kurve
        breite_strich = stark_betont if funktion['betont'] else stark_kurve
        abschnitte = _segmente(funktion, x_min, x_max, y_min, y_max, schritte)
        for teil in abschnitte:
            kurven_teile.append(
                polylinie([(px(x), py(y)) for x, y in teil], farbe, breite_strich)
            )

        if not funktion['label']:
            continue

        # Ankerpunkt aus dem ECHTEN Fenster, nicht aus dem Toleranzband — sonst
        # saesse die Beschriftung ausserhalb des Bildes und der clipPath naehme
        # sie weg.
        anker = _label_anker(funktion, x_min, x_max, y_min, y_max, schritte)
        if anker is None:
            continue

        x_letzt, y_letzt = anker
        nah_am_rand = px(x_letzt) > rechts - 3 * einheit
        label_teile.append(beschriftung(
            px(x_letzt) + (-6 * skala if nah_am_rand else 6 * skala),
            py(y_letzt) - schriftgroesse,
            funktion['label'], farbe, schriftgroesse, SCHRIFT,
            anker='end' if nah_am_rand else 'start', grundlinie='middle', fett=True,
        ))

    if kurven_teile:
        inhalt.append(element(
            'g', [('clip-path', f'url(#{CLIP_ID})')], ''.join(kurven_teile)
        ))
    # Labels stehen AUSSERHALB der Clip-Gruppe: Ein Text direkt an der
    # Fensterkante wuerde sonst zur Haelfte abgeschnitten. Der Aussenrand traegt
    # ihn.
    if label_teile:
        inhalt.append(element('g', [], ''.join(label_teile)))

    # ── Punkte ───────────────────────────────────────────────────────────────
    punkt_teile: list[str] = []
    for punkt in geprueft_p:
        farbe = farben.kurve_betont if punkt['betont'] else farben.kurve
        radius = (5.5 if punkt['betont'] else 4) * skala
        punkt_teile.append(kreis(px(punkt['x']), py(punkt['y']), radius, farbe))
        if punkt['label']:
            punkt_teile.append(beschriftung(
                px(punkt['x']), py(punkt['y']) - radius - schriftgroesse * 0.8,
                punkt['label'], farbe, schriftgroesse, SCHRIFT,
                anker='middle', grundlinie='middle', fett=True,
            ))
    if punkt_teile:
        inhalt.append(element('g', [], ''.join(punkt_teile)))

    return dokument(breite, hoehe, inhalt)


__all__ = ['koordinatensystem', 'EINHEIT_STANDARD']
