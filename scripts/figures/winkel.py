#!/usr/bin/env python3
"""
Parametrischer Generator: EIN Winkel — zwei Schenkel, Winkelzeichen, Gradzahl.

WARUM SORGFALT: Ein falsches Bild ist schlimmer als kein Bild. Bei Text faellt
ein Fehler in der fachlichen Pruefung auf; einen Zahlendreher in der Skalierung
sieht niemand. Beim Winkel ist es noch tueckischer als beim Koordinatensystem:
110 Grad und 250 Grad haben DIESELBEN zwei Schenkel. Der Unterschied ist allein,
ob der Bogen innen oder aussen liegt. Wer ihn auf die falsche Seite legt, zeigt
den Gegenwinkel — die Abbildung sieht dabei vollkommen unauffaellig aus, und die
Aufgabe hat eine andere Loesung als gedacht. Deshalb misst `pruefe_winkel.py`
den UEBERSTRICHENEN Winkel nach und nicht nur die Lage der Schenkel.

Die Eingaben laufen vorher durch `pruefungen.py`. Es gibt keinen stillen
Verzicht: `grad` ausserhalb von 1..359 ist ein Fehler, eine leere `benennung`
ist ein Fehler (dafuer gibt es None), und ein unbekannter Schluessel in `params`
ist ein Fehler — 'benenung' statt 'benennung' wuerde sonst die Beschriftung
verschlucken.

FESTER RAHMEN: Die viewBox ist immer 300 x 300, unabhaengig von den Parametern.
Der Scheitel sitzt in der Mitte, die Schenkel sind 110 px lang — damit passt
JEDE Winkelweite in denselben Rahmen, ohne dass der Aufrufer die Masse kennen
muss. Bei kleinen Winkeln bleibt links Platz ungenutzt; das ist der Preis fuer
einen Rahmen, der sich mit den Parametern nicht aendert.

GRADZAHL IST OPTIONAL, UND ZWAR AUS FACHLICHEM GRUND: `mit_bogen=False`
zeichnet nur die beiden Schenkel — kein Bogen, kein rechtwinkliges Zeichen,
keine Gradzahl. Das ist die Form fuer "Wie gross ist dieser Winkel?": stuende
die Zahl im Bild, waere die Antwort mitgeliefert.
"""

from __future__ import annotations

import math

try:
    from .pruefungen import reelle_zahl, text_oder_none, wahrheitswert
    from .svg_basis import beschriftung, dokument, element, linie, polylinie, zahl
    from .tokens import SCHRIFT, palette
except ImportError:
    # Flach importiert statt als Paket: `upload_figures.py` legt scripts/figures
    # auf sys.path und macht `import winkel`. Dann gibt es kein Elternpaket fuer
    # den relativen Import. `pruefungen` traegt selbst relative Importe und
    # laesst sich flach gar nicht laden — also kommt das PAKETVERZEICHNIS auf
    # den Pfad und die Module kommen ueber `figures.…` herein.
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.pruefungen import reelle_zahl, text_oder_none, wahrheitswert
    from figures.svg_basis import beschriftung, dokument, element, linie, polylinie, zahl
    from figures.tokens import SCHRIFT, palette

# ── Feste Masse (px) ─────────────────────────────────────────────────────────
# Alles hier ist unabhaengig von den Parametern. Der Rahmen darf sich mit `grad`
# NICHT aendern: die Figur wird in eine Aufgabenkarte gelegt, und eine Karte,
# deren Bildhoehe von der Winkelweite abhaengt, springt beim Blaettern.
BREITE = 300
HOEHE = 300
SCHEITEL_X = 150.0
SCHEITEL_Y = 150.0

# Schenkellaenge. 150 - 110 = 40 px Rand bleiben in jeder Richtung frei — genug
# fuer die Strichstaerke und dafuer, dass nichts an der Kante klebt.
SCHENKEL = 110.0

# Der Bogen sitzt deutlich innerhalb der Schenkel, die Gradzahl dahinter.
BOGEN_RADIUS = 46.0
ZAHL_RADIUS = 70.0

# Seitenlaenge des rechtwinkligen Zeichens (das kleine Quadrat am Scheitel).
RECHTWINKEL = 30.0

# Die Benennung sitzt am Scheitel auf der dem Winkelzeichen ABGEWANDTEN Seite.
# Zwischen Scheitel und Bogen ist bei kleinen Winkeln kein Platz — dort lief der
# Text ueber die Schenkel hinaus. Gegenueber liegt bei jedem Winkel bis etwa 350
# Grad freie Flaeche. GRENZE, offen benannt: bei ueber ~350 Grad ist auch die
# Gegenseite nur noch ein Spalt, dann liegt die Benennung auf dem Grundschenkel.
# Naeher an den Scheitel hilft nicht — der Spalt wird zum Scheitel hin enger,
# nicht weiter.
BENENNUNG_ABSTAND = 26.0

SCHRIFTGROESSE = 15.0
STARK_SCHENKEL = 2.5
STARK_ZEICHEN = 2.0

# Grad je Bogensegment. Bei Radius 46 px liegt ein 4-Grad-Segment 0,03 px unter
# der echten Kreislinie — unsichtbar, und 359 Grad bleiben bei 90 Punkten.
BOGEN_SCHRITT = 4.0
BOGEN_MIN_SCHRITTE = 12

GRAD_MIN = 1.0
GRAD_MAX = 359.0

# `grad` ist ein Float. Ein exakter Vergleich auf 90 ist trotzdem richtig: die
# Spezifikation sagt "bei GENAU 90 Grad", und 90.001 Grad ist kein rechter
# Winkel. Die Toleranz faengt nur das ab, was aus 90.0 durch eine
# Float-Umrechnung geworden sein kann.
EPS_RECHTER = 1e-9

# Die Schluessel, die `zeichne` in params akzeptiert. Alles andere ist ein
# Fehler und keine Abbildung ohne Beschriftung.
PARAMS_SCHLUESSEL = {'grad', 'benennung', 'mit_bogen'}


# ── Geometrie ────────────────────────────────────────────────────────────────

def _punkt(winkel_grad: float, radius: float) -> tuple[float, float]:
    """
    Punkt im Abstand `radius` vom Scheitel, `winkel_grad` gegen den Uhrzeigersinn
    von der Waagerechten nach rechts.

    Das Minus bei y ist die Spiegelung: In SVG waechst y nach UNTEN, im
    Winkelmass laeuft der Winkel nach OBEN. Ohne die Spiegelung waere jeder
    Winkel im Bild sein Gegenstueck — 60 Grad saehen wie 300 Grad aus.
    """
    bogenmass = math.radians(winkel_grad)
    return (
        SCHEITEL_X + radius * math.cos(bogenmass),
        SCHEITEL_Y - radius * math.sin(bogenmass),
    )


def _bogenpunkte(grad: float) -> list[tuple[float, float]]:
    """
    Der Bogen als Streckenzug vom Grundschenkel bis zum zweiten Schenkel.

    Er laeuft IMMER von 0 nach `grad` gegen den Uhrzeigersinn. Bei einem
    ueberstumpfen Winkel ergibt das den langen Weg — den aussen liegenden Bogen.
    Genau das ist die Aussage der Figur: ueberstrichen wird das Gebiet zwischen
    den Schenkeln, nicht der kuerzere Rest.
    """
    schritte = max(BOGEN_MIN_SCHRITTE, int(math.ceil(grad / BOGEN_SCHRITT)))
    return [_punkt(grad * i / schritte, BOGEN_RADIUS) for i in range(schritte + 1)]


def _ist_rechter(grad: float) -> bool:
    return abs(grad - 90.0) < EPS_RECHTER


def _gradtext(grad: float) -> str:
    """
    Die Gradzahl in deutscher Schreibweise: Dezimalkomma, dann das Gradzeichen.

    `zahl()` liefert den kanonischen Punkt-String (gerundet, ohne Nullschwanz,
    ohne '-0'); das Komma kommt danach. So haengt das Zahlformat an genau einer
    Stelle und nicht an einem zweiten f-String.
    """
    return zahl(grad).replace('.', ',') + '°'


# ── Hauptfunktion ────────────────────────────────────────────────────────────

def winkel(
    grad: float,
    benennung: str | None = None,
    mit_bogen: bool = True,
    theme: str = 'dunkel',
) -> str:
    """
    Baut ein vollstaendiges SVG als String.

    grad       — Winkelweite in Grad, 1 bis 359 (auch ueberstumpf, auch mit
                 Nachkommastellen). Gemessen vom waagerechten Grundschenkel
                 gegen den Uhrzeigersinn.
    benennung  — Name des Winkels ('alpha', 'ASB', …) oder None. Steht am
                 Scheitel auf der dem Bogen abgewandten Seite. Ein leerer Text
                 ist ein Fehler; "keine Benennung" heisst None.
    mit_bogen  — Winkelzeichen und Gradzahl zeichnen. False liefert nur die
                 beiden Schenkel — die Form fuer Aufgaben, in denen der Winkel
                 gemessen oder geschaetzt werden soll.
    theme      — 'dunkel' (Schueler-Buehne) oder 'hell' (Eltern-Report, Druck).

    Zuordnung der Tokens zu den Rollen (die einzige Designentscheidung hier):
    Die Schenkel sind die Figur selbst und tragen die lauteste Ebene
    (`kurve`). Das Winkelzeichen und die Gradzahl sind das, worum es geht, und
    tragen den betonten Strich (`kurve_betont`, Gold). Die Benennung ist
    Beiwerk und traegt die Beschriftungsfarbe.
    """
    grad = reelle_zahl(grad, 'grad')
    if not (GRAD_MIN <= grad <= GRAD_MAX):
        raise ValueError(
            f'grad muss zwischen {zahl(GRAD_MIN)} und {zahl(GRAD_MAX)} liegen, '
            f'nicht {grad!r}. 0 und 360 Grad sind keine zeichenbaren Winkel — '
            f'die Schenkel lagen uebereinander.'
        )
    benennung = text_oder_none(benennung, 'benennung')
    if benennung is not None and not benennung.strip():
        raise ValueError(
            'benennung ist leer. Fuer "keine Benennung" None uebergeben — ein '
            'leerer Text ist an der Aufrufstelle ein Fehler und kein Wunsch.'
        )
    mit_bogen = wahrheitswert(mit_bogen, 'mit_bogen')
    farben = palette(theme)

    inhalt: list[str] = []

    # ── Schenkel ─────────────────────────────────────────────────────────────
    # Der Grundschenkel steht zuerst und waagerecht: beide Endpunkte auf
    # SCHEITEL_Y, also byteweise dieselbe y-Koordinate. Ein "fast waagerecht"
    # gibt es hier bauartbedingt nicht.
    grund_ende = _punkt(0.0, SCHENKEL)
    zweites_ende = _punkt(grad, SCHENKEL)
    inhalt.append(element('g', [], ''.join([
        linie(SCHEITEL_X, SCHEITEL_Y, grund_ende[0], grund_ende[1],
              farben.kurve, STARK_SCHENKEL),
        linie(SCHEITEL_X, SCHEITEL_Y, zweites_ende[0], zweites_ende[1],
              farben.kurve, STARK_SCHENKEL),
    ])))

    # ── Winkelzeichen ────────────────────────────────────────────────────────
    if mit_bogen:
        if _ist_rechter(grad):
            # Das rechteckige Zeichen ERSETZT den Bogen. Ein Bogen mit
            # danebenstehender 90 waere fachlich zwar nicht falsch, aber im
            # Unterricht ist das Quadrat die Schreibweise, an der man den
            # rechten Winkel ohne Nachmessen erkennt.
            ecke_a = _punkt(0.0, RECHTWINKEL)
            ecke_c = _punkt(90.0, RECHTWINKEL)
            ecke_b = (ecke_a[0], ecke_c[1])
            inhalt.append(element('g', [], ''.join([
                linie(ecke_a[0], ecke_a[1], ecke_b[0], ecke_b[1],
                      farben.kurve_betont, STARK_ZEICHEN),
                linie(ecke_b[0], ecke_b[1], ecke_c[0], ecke_c[1],
                      farben.kurve_betont, STARK_ZEICHEN),
            ])))
        else:
            inhalt.append(element('g', [], polylinie(
                _bogenpunkte(grad), farben.kurve_betont, STARK_ZEICHEN,
            )))

    # ── Beschriftung ─────────────────────────────────────────────────────────
    schrift_teile: list[str] = []
    if mit_bogen:
        # Auf der Winkelhalbierenden, hinter dem Bogen: bei einem
        # ueberstumpfen Winkel wandert die Zahl damit nach AUSSEN mit — dorthin,
        # wo der Bogen liegt. Stuende sie fest innen, widerspraeche die Zahl
        # dem Bogen, und niemand wuesste, welche der beiden Angaben gilt.
        zahl_x, zahl_y = _punkt(grad / 2.0, ZAHL_RADIUS)
        schrift_teile.append(beschriftung(
            zahl_x, zahl_y, _gradtext(grad),
            farben.kurve_betont, SCHRIFTGROESSE, SCHRIFT,
            anker='middle', grundlinie='middle', fett=True,
        ))
    if benennung is not None:
        name_x, name_y = _punkt(grad / 2.0 + 180.0, BENENNUNG_ABSTAND)
        schrift_teile.append(beschriftung(
            name_x, name_y, benennung,
            farben.beschriftung, SCHRIFTGROESSE, SCHRIFT,
            anker='middle', grundlinie='middle',
        ))
    if schrift_teile:
        inhalt.append(element('g', [], ''.join(schrift_teile)))

    return dokument(BREITE, HOEHE, inhalt)


# ── Adapter fuer den Upload (upload_figures.py: zeichne(params, theme)) ───────

def zeichne(params: dict, theme: str) -> str:
    """
    Baut ein SVG aus einem params-DICT — die Schnittstelle, die upload_figures.py
    (A19) erwartet: `winkel.zeichne(params, theme) -> str`.

    `params` traegt genau die Schluesselwort-Argumente von `winkel` (grad,
    benennung, mit_bogen). `theme` kommt getrennt, weil der Aufrufer beide
    Themes aus DENSELBEN params erzeugt; ein 'theme' IN params waere doppelt
    vergeben und wird darum abgewiesen.

    Unbekannte Schluessel fallen HIER durch, mit Klartext. `winkel(**params)`
    allein wuerde einen TypeError ueber ein "unexpected keyword argument"
    werfen — richtig, aber nicht die Meldung, die jemand beim Einpflegen einer
    task_figures-Zeile lesen will.
    """
    if not isinstance(params, dict):
        raise ValueError(f'params muss ein dict sein, nicht {params!r}.')
    if 'theme' in params:
        raise ValueError('theme gehoert nicht in params — es wird getrennt uebergeben.')
    unbekannt = set(params) - PARAMS_SCHLUESSEL
    if unbekannt:
        namen = ', '.join(repr(s) for s in sorted(unbekannt))
        erlaubt = ', '.join(repr(s) for s in sorted(PARAMS_SCHLUESSEL))
        raise ValueError(f'params: unbekannte Schluessel: {namen}. Erlaubt: {erlaubt}.')
    if 'grad' not in params:
        raise ValueError("params braucht 'grad'.")
    return winkel(theme=theme, **params)


__all__ = ['winkel', 'zeichne', 'BREITE', 'HOEHE']
