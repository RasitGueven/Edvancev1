#!/usr/bin/env python3
"""
Eingabepruefungen fuer die Abbildungs-Generatoren.

Getrennt vom Zeichnen, weil es die HAELFTE der Arbeit ist und einen eigenen
Zweck hat: Ein falsches Bild ist schlimmer als kein Bild. Bei Text faellt ein
Fehler in der fachlichen Pruefung auf, bei einer Abbildung sieht niemand einen
Zahlendreher. Also faellt hier alles durch, was sich nicht sauber darstellen
laesst — laut, mit Klartext und der Stelle im Aufruf.

Die Haltung dahinter: Es gibt keinen stillen Verzicht. Ein Tippfehler im
Schluessel ('labl' statt 'label') ist ein Fehler und keine Abbildung ohne
Beschriftung. Ein Punkt ausserhalb des Fensters ist ein Fehler und kein
weggeschnittener Punkt.
"""

from __future__ import annotations

from .svg_basis import zahl

FUNKTIONS_SCHLUESSEL = {
    'linear': {'typ', 'm', 'b', 'label', 'betont'},
    'quadratisch': {'typ', 'a', 'b', 'c', 'label', 'betont'},
}
FUNKTIONS_PFLICHT = {'linear': ('m', 'b'), 'quadratisch': ('a', 'b', 'c')}
PUNKT_SCHLUESSEL = {'x', 'y', 'label', 'betont'}


# ── Prüfungen ────────────────────────────────────────────────────────────────

def ganzzahl(wert: object, name: str) -> int:
    # `bool` ist in Python eine `int`-Unterklasse. `True` als x_max waere ein
    # Tippfehler, der sonst als 1 durchginge.
    if isinstance(wert, bool) or not isinstance(wert, int):
        raise ValueError(f'{name} muss ganzzahlig sein, nicht {wert!r}.')
    return wert


def reelle_zahl(wert: object, name: str) -> float:
    if isinstance(wert, bool) or not isinstance(wert, (int, float)):
        raise ValueError(f'{name} muss eine Zahl sein, nicht {wert!r}.')
    return float(wert)


def pruefe_funktion(roh: object, index: int) -> dict:
    stelle = f'funktionen[{index}]'
    if not isinstance(roh, dict):
        raise ValueError(f'{stelle} muss ein dict sein, nicht {roh!r}.')

    typ = roh.get('typ')
    if typ not in FUNKTIONS_SCHLUESSEL:
        erlaubt = ', '.join(repr(t) for t in sorted(FUNKTIONS_SCHLUESSEL))
        raise ValueError(f'{stelle}: typ muss {erlaubt} sein, nicht {typ!r}.')

    unbekannt = set(roh) - FUNKTIONS_SCHLUESSEL[typ]
    if unbekannt:
        namen = ', '.join(repr(s) for s in sorted(unbekannt))
        raise ValueError(f'{stelle}: unbekannte Schluessel fuer {typ!r}: {namen}.')

    geprueft: dict = {'typ': typ}
    for pflicht in FUNKTIONS_PFLICHT[typ]:
        if pflicht not in roh:
            raise ValueError(f'{stelle}: {typ!r} braucht {pflicht!r}.')
        geprueft[pflicht] = reelle_zahl(roh[pflicht], f'{stelle}[{pflicht!r}]')

    if typ == 'quadratisch' and geprueft['a'] == 0:
        # a = 0 ist rechnerisch eine Gerade. Als 'quadratisch' deklariert waere
        # es eine falsche Zusage an den Aufrufer.
        raise ValueError(f'{stelle}: a = 0 ist keine Parabel — nutze typ "linear".')

    geprueft['label'] = text_oder_none(roh.get('label'), f'{stelle}[\'label\']')
    geprueft['betont'] = wahrheitswert(roh.get('betont', False), f'{stelle}[\'betont\']')
    return geprueft


def text_oder_none(wert: object, name: str) -> str | None:
    if wert is None:
        return None
    if not isinstance(wert, str):
        raise ValueError(f'{name} muss Text sein, nicht {wert!r}.')
    return wert


def wahrheitswert(wert: object, name: str) -> bool:
    if not isinstance(wert, bool):
        raise ValueError(f'{name} muss True oder False sein, nicht {wert!r}.')
    return wert


def pruefe_punkt(roh: object, index: int, grenzen: tuple[int, int, int, int]) -> dict:
    stelle = f'punkte[{index}]'
    if not isinstance(roh, dict):
        raise ValueError(f'{stelle} muss ein dict sein, nicht {roh!r}.')

    unbekannt = set(roh) - PUNKT_SCHLUESSEL
    if unbekannt:
        namen = ', '.join(repr(s) for s in sorted(unbekannt))
        raise ValueError(f'{stelle}: unbekannte Schluessel: {namen}.')
    for pflicht in ('x', 'y'):
        if pflicht not in roh:
            raise ValueError(f'{stelle}: braucht {pflicht!r}.')

    x = reelle_zahl(roh['x'], f'{stelle}[\'x\']')
    y = reelle_zahl(roh['y'], f'{stelle}[\'y\']')
    x_min, x_max, y_min, y_max = grenzen
    if not (x_min <= x <= x_max and y_min <= y <= y_max):
        raise ValueError(
            f'{stelle}: ({zahl(x)}|{zahl(y)}) liegt ausserhalb des Fensters '
            f'x[{x_min}, {x_max}] y[{y_min}, {y_max}]. Der Punkt waere '
            f'weggeschnitten worden — Fenster anpassen oder Punkt korrigieren.'
        )

    return {
        'x': x,
        'y': y,
        'label': text_oder_none(roh.get('label'), f'{stelle}[\'label\']'),
        'betont': wahrheitswert(roh.get('betont', False), f'{stelle}[\'betont\']'),
    }

