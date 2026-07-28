#!/usr/bin/env python3
"""
Parametrischer Generator: EIN Dreieck — Grundseite, Hoehe, Masse aussen.

WARUM SORGFALT: Ein falsches Bild ist schlimmer als kein Bild. Bei Text faellt
ein Fehler in der fachlichen Pruefung auf; einen Zahlendreher in der Skalierung
sieht niemand. Beim Dreieck ist die gefaehrlichste Stelle die MASSSTAEBLICHKEIT:
Steht "g = 8 cm" unter einer Grundseite und "h = 2 cm" an einer Hoehe, dann muss
die gezeichnete Hoehe auch ein Viertel der gezeichneten Grundseite messen. Tut
sie es nicht, misst ein Kind mit dem Lineal nach und bekommt eine andere Antwort
als die Aufgabe erwartet — und niemand sieht der Abbildung an, woran es lag.
Deshalb rechnet `pruefe_dreieck.py` das Verhaeltnis aus dem SVG zurueck.

DAS BAND UND DIE KAPPUNG: Der Rahmen ist fest (380 x 300), das Zeichenband
darin ebenfalls. Ein Dreieck mit dem Verhaeltnis 1:40 passt in kein Band, ohne
dass eine der beiden Strecken zum Strich wird. Ueber 1:4 wird deshalb auf den
Bandrand GEKAPPT — und das gekappte Mass traegt ein Zickzack auf seiner
Masslinie, das Zeichen fuer "nicht massstaeblich". Die stille Stauchung waere
der Fehler, den niemand nachsieht: die Abbildung saehe unauffaellig aus und
haette eine andere Aussage als die Zahlen daneben. Innerhalb von 1:4 wird nichts
gekappt, und dann gilt Pixelhoehe/Pixelgrundseite == hoehe/grundseite exakt.

DIE HOEHE BEI 'rechtwinklig' — eine bewusste Entscheidung: Bei einem
rechtwinkligen Dreieck mit dem rechten Winkel an der linken Grundecke IST die
linke Kathete die Hoehe auf die Grundseite. Eine zusaetzliche gestrichelte Linie
laege exakt auf dieser Kathete; eine Seite, die halb durchgezogen und halb
gestrichelt aussieht, ist keine bessere Abbildung, sondern eine verwirrende.
Also wird bei 'rechtwinklig' KEINE gestrichelte Hoehe gezeichnet — das
Winkelzeichen an der linken Grundecke sagt, dass diese Kathete senkrecht auf der
Grundseite steht. Bei den anderen Arten liegt der Hoehenfusspunkt im Inneren der
Grundseite, dort ist die gestrichelte Linie sichtbar und noetig.

DAS ZICKZACK SITZT AUF DER MASSLINIE, nicht auf der Dreiecksseite: Der Umriss
bleibt ein sauberes Dreieck, und das Zeichen steht dort, wo es etwas aussagt —
an dem Mass, das nicht massstaeblich gezeichnet ist. Ein Zickzack quer durch die
Grundseite waere eine Figur, die kein Dreieck mehr ist.

Die Eingaben laufen vorher durch `pruefungen.py` bzw. die Pruefungen hier. Es
gibt keinen stillen Verzicht: eine Laenge <= 0 ist ein Fehler, eine dritte
Nachkommastelle ist ein Fehler (sie wuerde im Text gerundet und die Abbildung
behauptete etwas anderes als der Aufruf), und ein unbekannter Schluessel in
`params` ist ein Fehler — 'hoehe1' statt 'hoehe' wuerde sonst durchfallen.
"""

from __future__ import annotations

import math
import re

try:
    from .pruefungen import reelle_zahl, text_oder_none
    from .svg_basis import (
        beschriftung,
        dokument,
        element,
        farb_attribute,
        linie,
        polylinie,
        zahl,
    )
    from .tokens import SCHRIFT, palette
except ImportError:
    # Flach importiert statt als Paket: `upload_figures.py` legt scripts/figures
    # auf sys.path und macht `import dreieck`. Dann gibt es kein Elternpaket fuer
    # den relativen Import. `pruefungen` traegt selbst relative Importe und
    # laesst sich flach gar nicht laden — also kommt das PAKETVERZEICHNIS auf
    # den Pfad und die Module kommen ueber `figures.…` herein.
    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    from figures.pruefungen import reelle_zahl, text_oder_none
    from figures.svg_basis import (
        beschriftung,
        dokument,
        element,
        farb_attribute,
        linie,
        polylinie,
        zahl,
    )
    from figures.tokens import SCHRIFT, palette

# ── Fester Rahmen (px) ───────────────────────────────────────────────────────
# Alles hier ist unabhaengig von den Parametern. Der Rahmen darf sich mit
# `grundseite`/`hoehe` NICHT aendern: die Figur wird in eine Aufgabenkarte
# gelegt, und eine Karte, deren Bildhoehe an den Massen haengt, springt beim
# Blaettern.
BREITE = 380
HOEHE = 300

# ── Das Zeichenband ──────────────────────────────────────────────────────────
# Links vom Band bleiben 124 px fuer die senkrechte Masslinie und den Text
# daneben, unten 74 px fuer die waagerechte Masslinie und ihren Text. Das
# Dreieck steht LINKSBUENDIG im Band — so liegt die senkrechte Masslinie immer
# im gleichen Abstand neben der linken Grundecke, egal wie breit das Dreieck
# gerade ist.
BAND_LINKS = 124.0
BAND_UNTEN = 226.0
BAND_BREITE = 224.0
BAND_HOEHE = 180.0

# Die Grenze, ab der gekappt wird. 1:4 ist die Spanne, in der beide Strecken
# noch als Strecken lesbar bleiben; darueber wuerde die kuerzere zum Punkt.
VERHAELTNIS_MAX = 4.0
VERHAELTNIS_MIN = 1.0 / VERHAELTNIS_MAX

# Masslinien und ihre Texte — aussen, nie im Dreieck.
MASS_X = 108.0        # senkrechte Masslinie (Hoehe), 16 px links vom Band
MASS_TEXT_X = 100.0   # Text rechtsbuendig davor
MASS_Y = 248.0        # waagerechte Masslinie (Grundseite), 22 px unter der Grundseite
MASS_TEXT_Y = 268.0   # Text darunter

# Seitenlaenge des rechtwinkligen Zeichens am Hoehenfusspunkt. 12 px passen auch
# in das flachste zeichenbare Dreieck (Verhaeltnis 1:4, Hoehe 56 px).
RECHTWINKEL = 12.0

# Das Zickzack auf der Masslinie eines gekappten Masses: halbe Laenge und
# Auslenkung quer zur Linie.
ZACKE_LAENGE = 14.0
ZACKE_TIEFE = 6.0

SCHRIFTGROESSE = 15.0
STARK_FIGUR = 2.5
STARK_ZEICHEN = 2.0
STARK_MASS = 1.5
STRICHELUNG = (6.0, 4.0)

# Wo der Hoehenfusspunkt auf der Grundseite sitzt, als Anteil der Grundseite.
# 'beliebig' steht bewusst nicht bei 0.5 — sonst waere jedes "beliebige"
# Dreieck gleichschenklig gezeichnet und die drei Arten saehen zu zweit gleich
# aus. 'rechtwinklig' setzt den Fusspunkt auf die linke Grundecke; damit ist die
# linke Kathete die Hoehe und der rechte Winkel sitzt dort, wo er hingehoert.
FUSS_ANTEIL: dict[str, float] = {
    'beliebig': 0.35,
    'gleichschenklig': 0.5,
    'rechtwinklig': 0.0,
}
ARTEN = tuple(sorted(FUSS_ANTEIL))

# Grenzen der Masszahlen. Die Obergrenze haengt am festen Rahmen: '999,99 abcd'
# ist der laengste Text, der links vom Band noch vollstaendig Platz hat.
MASS_MIN = 0.01
MASS_MAX = 999.0
EINHEIT_MUSTER = re.compile(r'[A-Za-z]{1,4}')

# Die Schluessel, die `zeichne` in params akzeptiert. Alles andere ist ein
# Fehler und keine Abbildung mit stillschweigend anderen Massen.
PARAMS_SCHLUESSEL = {'grundseite', 'hoehe', 'art', 'einheit'}


# ── Eingabepruefungen ────────────────────────────────────────────────────────

def _mass(wert: object, name: str) -> float:
    """
    Eine Laenge in Sachmass (cm, m, …) — endlich, positiv, hoechstens zwei
    Nachkommastellen.

    Die zwei Nachkommastellen sind keine Schikane: der Masstext entsteht ueber
    `zahl()` und rundet auf zwei Stellen. Ein Aufruf mit 3.456 ergaebe die
    Beschriftung "3,46 cm" — die Abbildung behauptete dann etwas anderes als der
    Aufruf, und das faellt niemandem auf. Also faellt es hier durch.
    """
    wert = reelle_zahl(wert, name)
    if not math.isfinite(wert):
        raise ValueError(f'{name} muss endlich sein, nicht {wert!r}.')
    if not (MASS_MIN <= wert <= MASS_MAX):
        raise ValueError(
            f'{name} muss zwischen {zahl(MASS_MIN)} und {zahl(MASS_MAX)} liegen, '
            f'nicht {wert!r}. Eine Laenge <= 0 ist keine Strecke, und oberhalb '
            f'der Grenze passt der Masstext nicht mehr in den festen Rahmen.'
        )
    if round(wert, 2) != wert:
        raise ValueError(
            f'{name} = {wert!r} traegt mehr als zwei Nachkommastellen. Der '
            f'Masstext wuerde auf {zahl(wert)} gerundet und die Abbildung ein '
            f'anderes Mass behaupten als der Aufruf.'
        )
    return wert


def _einheit(wert: object) -> str:
    """Die Masseinheit als kurzes Kuerzel ('cm', 'm', 'mm', 'LE', …)."""
    wert = text_oder_none(wert, 'einheit')
    if wert is None:
        raise ValueError(
            "einheit ist Pflicht — eine Masszahl ohne Einheit ist keine Angabe."
        )
    if not EINHEIT_MUSTER.fullmatch(wert):
        raise ValueError(
            f'einheit muss ein Kuerzel aus 1 bis 4 Buchstaben sein, nicht {wert!r}. '
            f'Laengere Angaben laufen im festen Rahmen aus dem Bild.'
        )
    return wert


def _art(wert: object) -> str:
    if wert not in ARTEN:
        erlaubt = ', '.join(repr(a) for a in ARTEN)
        raise ValueError(f'art muss eines von {erlaubt} sein, nicht {wert!r}.')
    return str(wert)


# ── Geometrie ────────────────────────────────────────────────────────────────

def _masstext(wert: float, einheit: str) -> str:
    """
    Die Masszahl in deutscher Schreibweise: Dezimalkomma, dann die Einheit.

    `zahl()` liefert den kanonischen Punkt-String (gerundet, ohne Nullschwanz,
    ohne '-0'); das Komma kommt danach. So haengt das Zahlformat an genau einer
    Stelle und nicht an einem zweiten f-String.
    """
    return f'{zahl(wert).replace(".", ",")} {einheit}'


def _bandmasse(verhaeltnis: float) -> tuple[float, float]:
    """
    Grundseite und Hoehe in Pixeln, so gross wie das Band es zulaesst.

    `verhaeltnis` ist bereits gekappt. Eine der beiden Strecken stoesst immer an
    den Bandrand — welche, entscheidet das Verhaeltnis. Damit ist die Figur so
    gross wie moeglich, ohne dass der Rahmen sich mit den Parametern aendert.
    """
    grund_px = min(BAND_BREITE, BAND_HOEHE / verhaeltnis)
    return grund_px, grund_px * verhaeltnis


def _zickzack(
    mitte: tuple[float, float],
    entlang: tuple[float, float],
    quer: tuple[float, float],
) -> list[tuple[float, float]]:
    """
    Fuenf Punkte, die eine Masslinie an ihrer Mitte durchkreuzen — das Zeichen
    fuer "dieses Mass ist nicht massstaeblich gezeichnet".

    `entlang` und `quer` sind Einheitsvektoren; damit gilt dieselbe Formel fuer
    die waagerechte wie fuer die senkrechte Masslinie.
    """
    mx, my = mitte
    ex, ey = entlang
    qx, qy = quer
    schritte = (-1.0, -0.5, 0.0, 0.5, 1.0)
    auslenkung = (0.0, 1.0, -1.0, 1.0, 0.0)
    return [
        (mx + ex * ZACKE_LAENGE * s + qx * ZACKE_TIEFE * a,
         my + ey * ZACKE_LAENGE * s + qy * ZACKE_TIEFE * a)
        for s, a in zip(schritte, auslenkung)
    ]


def _gestrichelt(
    x1: float, y1: float, x2: float, y2: float, farbe, breite: float,
) -> str:
    """
    Eine gestrichelte Linie. `svg_basis.linie` kennt keine Strichelung, und sie
    dort zu ergaenzen hiesse, eine gemeinsame Datei fuer einen einzelnen
    Generator zu aendern — also steht sie hier, gebaut aus demselben `element`.
    """
    return element('line', [
        ('x1', zahl(x1)), ('y1', zahl(y1)),
        ('x2', zahl(x2)), ('y2', zahl(y2)),
        *farb_attribute('stroke', farbe),
        ('stroke-width', zahl(breite)),
        ('stroke-linecap', 'round'),
        ('stroke-dasharray', f'{zahl(STRICHELUNG[0])} {zahl(STRICHELUNG[1])}'),
    ])


# ── Hauptfunktion ────────────────────────────────────────────────────────────

def dreieck(
    grundseite: float,
    hoehe: float,
    art: str = 'beliebig',
    einheit: str = 'cm',
    theme: str = 'dunkel',
) -> str:
    """
    Baut ein vollstaendiges SVG als String.

    grundseite — Laenge der waagerechten Grundseite in `einheit`, 0,01 bis 999,
                 hoechstens zwei Nachkommastellen.
    hoehe      — Hoehe auf die Grundseite, gleiche Grenzen.
    art        — 'beliebig' (Fusspunkt innen, weder gleichschenklig noch
                 rechtwinklig gezeichnet), 'gleichschenklig' (Fusspunkt in der
                 Mitte, beide Schenkel gleich lang) oder 'rechtwinklig' (rechter
                 Winkel an der linken Grundecke, die linke Kathete IST die
                 Hoehe).
    einheit    — Kuerzel aus 1 bis 4 Buchstaben ('cm', 'm', 'mm', 'LE', …).
    theme      — 'dunkel' (Schueler-Buehne) oder 'hell' (Eltern-Report, Druck).

    Zuordnung der Tokens zu den Rollen (die einzige Designentscheidung hier):
    Der Umriss ist die Figur selbst und traegt die lauteste Ebene (`kurve`).
    Hoehe, Winkelzeichen und Zickzack sind das, worum es geht, und tragen den
    betonten Strich (`kurve_betont`, Gold). Die Masslinien sind Hilfslinien und
    tragen die Achsenfarbe, die Masstexte die Beschriftungsfarbe.
    """
    grundseite = _mass(grundseite, 'grundseite')
    hoehe = _mass(hoehe, 'hoehe')
    art = _art(art)
    einheit = _einheit(einheit)
    farben = palette(theme)

    # ── Massstab und Kappung ─────────────────────────────────────────────────
    verhaeltnis = hoehe / grundseite
    gezeichnet = min(max(verhaeltnis, VERHAELTNIS_MIN), VERHAELTNIS_MAX)
    gekappt = gezeichnet != verhaeltnis
    grund_px, hoehe_px = _bandmasse(gezeichnet)

    # ── Ecken ────────────────────────────────────────────────────────────────
    ecke_a = (BAND_LINKS, BAND_UNTEN)                 # linke Grundecke
    ecke_b = (BAND_LINKS + grund_px, BAND_UNTEN)      # rechte Grundecke
    fuss = (BAND_LINKS + grund_px * FUSS_ANTEIL[art], BAND_UNTEN)
    spitze = (fuss[0], BAND_UNTEN - hoehe_px)

    inhalt: list[str] = []

    # ── Umriss ───────────────────────────────────────────────────────────────
    # Als geschlossener Streckenzug (A, B, C, A) und nicht als <polygon>:
    # `polylinie` setzt `fill="none"`, ein gefuelltes Dreieck waere hier eine
    # Flaeche statt einer Figur aus drei Strecken.
    inhalt.append(element('g', [], polylinie(
        [ecke_a, ecke_b, spitze, ecke_a], farben.kurve, STARK_FIGUR,
    )))

    # ── Hoehe ────────────────────────────────────────────────────────────────
    # Bei 'rechtwinklig' faellt sie mit der linken Kathete zusammen und wird
    # deshalb nicht doppelt gezeichnet (siehe Modul-Docstring).
    if art != 'rechtwinklig':
        inhalt.append(element('g', [], _gestrichelt(
            spitze[0], spitze[1], fuss[0], fuss[1],
            farben.kurve_betont, STARK_ZEICHEN,
        )))

    # ── Rechtwinkliges Zeichen am Hoehenfusspunkt ────────────────────────────
    # Immer zur rechten Seite der Hoehe hin geoeffnet — eine feste Seite, damit
    # das Zeichen nicht je nach Art irgendwo sitzt. Bei 'rechtwinklig' faellt
    # der Fusspunkt auf die linke Grundecke, und dasselbe Zeichen markiert dort
    # den rechten Winkel des Dreiecks.
    inhalt.append(element('g', [], polylinie([
        (fuss[0] + RECHTWINKEL, fuss[1]),
        (fuss[0] + RECHTWINKEL, fuss[1] - RECHTWINKEL),
        (fuss[0], fuss[1] - RECHTWINKEL),
    ], farben.kurve_betont, STARK_ZEICHEN)))

    # ── Masslinien (aussen) plus Zickzack beim gekappten Mass ────────────────
    mass_teile = [
        linie(ecke_a[0], MASS_Y, ecke_b[0], MASS_Y, farben.achse, STARK_MASS),
        linie(MASS_X, BAND_UNTEN, MASS_X, spitze[1], farben.achse, STARK_MASS),
    ]
    if gekappt:
        if verhaeltnis > VERHAELTNIS_MAX:
            # Zu hoch fuer das Band: die HOEHE ist gekappt.
            zacken = _zickzack(
                (MASS_X, BAND_UNTEN - hoehe_px / 2.0), (0.0, -1.0), (1.0, 0.0),
            )
        else:
            # Zu flach fuer das Band: die GRUNDSEITE ist gekappt.
            zacken = _zickzack(
                (ecke_a[0] + grund_px / 2.0, MASS_Y), (1.0, 0.0), (0.0, -1.0),
            )
        mass_teile.append(polylinie(zacken, farben.kurve_betont, STARK_ZEICHEN))
    inhalt.append(element('g', [], ''.join(mass_teile)))

    # ── Masstexte ────────────────────────────────────────────────────────────
    inhalt.append(element('g', [], ''.join([
        beschriftung(
            ecke_a[0] + grund_px / 2.0, MASS_TEXT_Y, _masstext(grundseite, einheit),
            farben.beschriftung, SCHRIFTGROESSE, SCHRIFT,
            anker='middle', grundlinie='middle',
        ),
        beschriftung(
            MASS_TEXT_X, BAND_UNTEN - hoehe_px / 2.0, _masstext(hoehe, einheit),
            farben.beschriftung, SCHRIFTGROESSE, SCHRIFT,
            anker='end', grundlinie='middle',
        ),
    ])))

    return dokument(BREITE, HOEHE, inhalt)


# ── Adapter fuer den Upload (upload_figures.py: zeichne(params, theme)) ───────

def zeichne(params: dict, theme: str) -> str:
    """
    Baut ein SVG aus einem params-DICT — die Schnittstelle, die upload_figures.py
    (A19) erwartet: `dreieck.zeichne(params, theme) -> str`.

    `params` traegt genau die Schluesselwort-Argumente von `dreieck`
    (grundseite, hoehe, art, einheit). `theme` kommt getrennt, weil der Aufrufer
    beide Themes aus DENSELBEN params erzeugt; ein 'theme' IN params waere
    doppelt vergeben und wird darum abgewiesen.

    Unbekannte Schluessel fallen HIER durch, mit Klartext. `dreieck(**params)`
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
    for pflicht in ('grundseite', 'hoehe'):
        if pflicht not in params:
            raise ValueError(f'params braucht {pflicht!r}.')
    return dreieck(theme=theme, **params)


__all__ = ['dreieck', 'zeichne', 'ARTEN', 'BREITE', 'HOEHE', 'VERHAELTNIS_MAX']
