#!/usr/bin/env python3
"""
Unabhaengiges Nachrechnen (Pruefung 1) mit sympy — aus dem angezeigten Text, nicht aus den Generator-Parametern.

sympy liegt lokal unter scripts/bauformen/.pydeps (pip install --target, nicht committet); tools/bauform.sh setzt
PYTHONPATH darauf.
"""

from __future__ import annotations

import re
from fractions import Fraction

import sympy
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)

X = sympy.Symbol('x', real=True)
_TRANS = standard_transformations + (implicit_multiplication_application, convert_xor)


def ausdruck(text: str) -> sympy.Expr:
    """Kindertext-Term → sympy: ² ³, typografisches Minus, ·, Dezimalkomma, a√b."""
    t = text.replace('²', '**2').replace('³', '**3').replace('−', '-').replace('·', '*').replace(',', '.')
    t = re.sub(r'(\d)√(\d+)', r'\1*sqrt(\2)', t)
    t = re.sub(r'√\(([^)]*)\)', r'sqrt(\1)', t)
    t = re.sub(r'√(\d+)', r'sqrt(\1)', t)
    return parse_expr(t, local_dict={'x': X, 'sqrt': sympy.sqrt}, transformations=_TRANS)


def gleichung_aus_frage(frage: str) -> tuple[sympy.Expr, sympy.Expr]:
    """Die erste Gleichung im Text ('… 3x² − 12x = 0.') als (links, rechts)."""
    m = re.search(r'([0-9x(][^=]*?)\s*=\s*([^.?]*?)\s*[.?]?\s*$', frage.split('\n')[0])
    if not m:
        raise ValueError(f'keine Gleichung im Text: {frage!r}')
    links = m.group(1)
    links = re.sub(r'^.*?(Löse|Bestimme|Berechne)\s+', '', links)
    return ausdruck(links), ausdruck(m.group(2))


def loesungsmenge(links: sympy.Expr, rechts: sympy.Expr) -> list[Fraction] | None:
    """Reelle Loesungen als Fractions (aufsteigend); None, wenn eine Loesung nicht rational ist."""
    menge = sympy.solveset(sympy.Eq(links, rechts), X, domain=sympy.S.Reals)
    if menge == sympy.S.EmptySet:
        return []
    if not isinstance(menge, sympy.FiniteSet):
        raise ValueError(f'keine endliche Loesungsmenge: {menge}')
    werte = []
    for w in menge:
        if not w.is_rational:
            return None
        werte.append(Fraction(int(w.p), int(w.q)))
    return sorted(werte)


def bruch(text: str) -> Fraction:
    """Antwort-Text → Fraction (wie format_bruch in der DB, fuer Vergleiche in Python)."""
    t = text.strip().replace('−', '-').replace(',', '.').lstrip('+')
    return Fraction(t)


def zeilen_menge(zeile: str):
    """Loesungsmenge einer Zeile eines Loesungswegs (sympy-Menge, reell), fuer Fehler finden und Schritte ordnen:
    'L = {a; b}', 'L = { }', 'x = a oder x = b', jede Gleichung 'A = B' und 'A = B oder C = D'."""
    t = zeile.strip().rstrip('.')
    if t.startswith('L ='):
        innen = t.split('{', 1)[1].rsplit('}', 1)[0].strip()
        return sympy.FiniteSet(*[ausdruck(w) for w in innen.split(';') if w.strip()]) if innen else sympy.S.EmptySet
    menge = sympy.S.EmptySet
    for teil in re.split(r'\s+oder\s+', t):
        links, rechts = teil.split('=', 1)
        links = re.sub(r'^x[₁₂,]+\s*$', 'x', links.strip())
        if '±' in rechts:
            a, b = rechts.split('±', 1)
            menge = menge | sympy.FiniteSet(ausdruck(a) + ausdruck(b), ausdruck(a) - ausdruck(b))
            continue
        menge = menge | sympy.solveset(sympy.Eq(ausdruck(links), ausdruck(rechts)), X, domain=sympy.S.Reals)
    return menge
