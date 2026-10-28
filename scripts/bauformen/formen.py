#!/usr/bin/env python3
"""
Bausteine, die viele Bauformen teilen: Feldmasken-Schablonen in Kurzschrift, Werte mit Vorzeichen, Zahlentexte.

Schablone in Kurzschrift (fm):  Text bleibt Text; '[a]' Zahlfeld, '[a?]' Zahlfeld „leer heisst 1“, '[a/]' Bruchfeld,
'±d' Vorzeichen-Umschalter 'vd' vor dem Zahlfeld 'd' (Wert der Loesung mit Vorzeichen, Feld zeigt den Betrag).
"""

from __future__ import annotations

import re
from fractions import Fraction

from .basis import zahl, zahl_antwort


def fm(*teile: str) -> list[dict]:
    aus: list[dict] = []
    for t in teile:
        m = re.fullmatch(r'\[(\w+)(\?|/)?\]', t)
        v = re.fullmatch(r'±(\w+)(/)?', t)
        if m:
            f = {'feld': m.group(1), 'typ': 'bruch' if m.group(2) == '/' else 'zahl'}
            if m.group(2) == '?':
                f['leer_heisst_eins'] = True
            aus.append(f)
        elif v:
            aus.append({'feld': 'v' + v.group(1), 'typ': 'vorzeichen'})
            aus.append({'feld': v.group(1), 'typ': 'bruch' if v.group(2) else 'zahl'})
        else:
            aus.append({'text': t})
    return aus


def feldmaske(schablone: list[dict]) -> dict:
    return {'format': 'feldmaske', 'schablone': schablone}


def werte(**w: Fraction | int) -> dict:
    """{'werte': {feld: Antworttext}} fuer Loesung und Fehlbilder."""
    return {'werte': {k: zahl_antwort(Fraction(v)) for k, v in w.items()}}


def vz(x: Fraction | int) -> str:
    """'+ 3' bzw. '− 3' fuer Texte wie „x − 3“."""
    x = Fraction(x)
    return f'− {zahl(-x)}' if x < 0 else f'+ {zahl(x)}'


def klammer(x: Fraction | int) -> str:
    """Zahl zum Einsetzen: negative in Klammern."""
    x = Fraction(x)
    return f'({zahl(x)})' if x < 0 else zahl(x)


def andere_eingabe(schablone: list[dict], loesung: dict) -> dict | None:
    """Dieselbe Bedeutung in anderer Eingabe (Abnahme 4): ein negatives Feld hinter einem Vorzeichen-Umschalter als
    „+“ und negative Zahl. None, wenn es kein solches Feld gibt."""
    felder: dict[str, str] = {}
    gedreht = False
    for i, t in enumerate(schablone):
        if 'feld' not in t or t['typ'] == 'vorzeichen':
            continue
        w = Fraction(loesung['werte'][t['feld']].replace('−', '-'))
        vor = schablone[i - 1] if i > 0 else {}
        if vor.get('typ') == 'vorzeichen':
            if w < 0 and not gedreht:
                felder[vor['feld']], felder[t['feld']], gedreht = '+', zahl_antwort(w), True
            else:
                felder[vor['feld']], felder[t['feld']] = ('−' if w < 0 else '+'), zahl_antwort(abs(w))
        else:
            felder[t['feld']] = zahl_antwort(w)
    return {'felder': felder} if gedreht else None


def poly_koeff(text: str, grad: int = 2) -> list[Fraction]:
    """Koeffizienten [a_grad, …, a_0] des angezeigten Terms (sympy, ausmultipliziert)."""
    import sympy

    from .rechnen import X, ausdruck
    p = sympy.Poly(sympy.expand(ausdruck(text)), X)
    k = [p.coeff_monomial(X ** n) for n in range(grad, -1, -1)]
    return [Fraction(int(sympy.Rational(c).p), int(sympy.Rational(c).q)) for c in k]


def menge_text(werte_: list[Fraction]) -> str:
    return '{' + '; '.join(zahl(w) for w in sorted(werte_)) + '}' if werte_ else '{ }'


def menge(werte_: list[Fraction]) -> dict:
    """Loesung bzw. Fehlbild einer Loesungsmenge."""
    return {'menge': [zahl_antwort(w) for w in sorted(set(werte_))]} if werte_ else {'keine_loesung': True}


def mengen_payload(werte_: list[Fraction], max_felder: int = 3) -> dict:
    bruch = any(Fraction(w).denominator != 1 for w in werte_)
    return {'format': 'loesungsmenge', 'element': 'bruch' if bruch else 'zahl', 'max_felder': max_felder, 'variable': 'x'}


def mengen_fehlbilder(bf, stufe: int, richtig: list[Fraction], regeln: dict) -> list[dict]:
    """Fehlbilder einer Loesungsmenge aus Regeln {key: Liste oder None}; None oder nicht darstellbar (irrational)
    heisst: fuer diese Instanz kein Fehlbild. Gleiche Bedeutung wie richtig oder wie ein frueheres Fehlbild faellt
    weg (Pruefung 3 bliebe sonst rot)."""
    aus, gesehen = [], {tuple(sorted(set(richtig)))}
    for f in bf.fehlbilder_fuer(stufe):
        w = regeln.get(f['key'])
        if w is None:
            continue
        t = tuple(sorted(set(w)))
        if t in gesehen:
            continue
        gesehen.add(t)
        aus.append({'key': f['key'], **menge(list(t))})
    return aus


def wurzel(x: Fraction) -> Fraction | None:
    """Exakte rationale Wurzel oder None."""
    from math import isqrt
    x = Fraction(x)
    if x < 0:
        return None
    n, d = isqrt(x.numerator), isqrt(x.denominator)
    return Fraction(n, d) if n * n == x.numerator and d * d == x.denominator else None
