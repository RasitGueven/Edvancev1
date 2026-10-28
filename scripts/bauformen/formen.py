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
    """Zahl zum Einsetzen: negative Zahlen und Brüche in Klammern."""
    x = Fraction(x)
    return f'({zahl(x)})' if x < 0 or x.denominator != 1 else zahl(x)


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


def nullstellen_aus_text(frage: str) -> list[Fraction]:
    """Reelle Nullstellen des Terms hinter „f(x) = “ (sympy), aufsteigend; ValueError, wenn eine irrational ist."""
    import re
    import sympy

    from .rechnen import X, ausdruck
    term = re.search(r'f\(x\) = (.+?)\.?$', frage).group(1)
    menge_ = sympy.solveset(ausdruck(term), X, domain=sympy.S.Reals)
    aus = []
    for w in menge_:
        if not w.is_rational:
            raise ValueError('irrationale Nullstelle')
        aus.append(Fraction(int(w.p), int(w.q)))
    return sorted(aus)


# ── Graph-Auswahl (Generator parabel) ─────────────────────────────────────────

def _zahl_json(x: Fraction | int) -> int | float:
    x = Fraction(x)
    return int(x) if x.denominator == 1 else float(x)


def parabel_alt(a: Fraction, d: Fraction, e: Fraction) -> str:
    """Alternativtext ohne Ziffern: Öffnung, Form, Lage des Scheitels."""
    a, d, e = Fraction(a), Fraction(d), Fraction(e)
    oeffnung = 'nach oben geöffnet' if a > 0 else 'nach unten geöffnet'
    form = 'wie die Normalparabel' if abs(a) == 1 else 'schmaler als die Normalparabel' if abs(a) > 1 else \
        'breiter als die Normalparabel'
    if d == 0 and e == 0:
        lage = 'Scheitel im Ursprung'
    else:
        teile = ([] if d == 0 else ['rechts' if d > 0 else 'links']) + ([] if e == 0 else ['oben' if e > 0 else 'unten'])
        lage = 'Scheitel ' + ' '.join(teile).replace('rechts oben', 'rechts oberhalb').replace('links oben', 'links oberhalb') \
            .replace('rechts unten', 'rechts unterhalb').replace('links unten', 'links unterhalb') + ' vom Ursprung'
        lage = lage.replace('Scheitel oben vom', 'Scheitel über dem').replace('Scheitel unten vom', 'Scheitel unter dem') \
            .replace('Scheitel rechts vom', 'Scheitel rechts vom').replace('Scheitel links vom', 'Scheitel links vom')
    return f'Parabel {oeffnung}, {form}, {lage}'


def graph_optionen(key: str, varianten: list[tuple[str, Fraction, Fraction, Fraction]], fenster: dict
                   ) -> tuple[dict, list[dict], str, list[dict]]:
    """varianten: [(rolle, a, d, e)], rolle 'r' = richtig, sonst Fehlbild-Schlüssel. Gemischt nach einem festen Seed.
    Liefert (payload, figuren, richtige_id, fehlbilder)."""
    import random
    v = list(varianten)
    random.Random(f'{key}-{varianten}').shuffle(v)
    ids = 'abcd'
    figuren, optionen, fb, richtig = [], [], [], ''
    alts = [parabel_alt(a, d, e) for _, a, d, e in v]
    # Gleiche Alternativtexte (Zweitprüfung A6 F, Befund 3): innerhalb der Gruppe nach Lage unterscheiden, ohne Ziffern.
    for alt in set(alts):
        gruppe = [i for i, x in enumerate(alts) if x == alt]
        if len(gruppe) < 2:
            continue
        nach_x = sorted(gruppe, key=lambda i: (Fraction(v[i][2]), Fraction(v[i][3])))
        for rang, i in enumerate(nach_x):
            if len({Fraction(v[j][2]) for j in gruppe}) == len(gruppe):
                zusatz = 'Scheitel weiter links' if rang == 0 else 'Scheitel weiter rechts' if rang == len(gruppe) - 1 else 'Scheitel in der Mitte'
            else:
                nach_y = sorted(gruppe, key=lambda j: Fraction(v[j][3]))
                r = nach_y.index(i)
                zusatz = 'Scheitel tiefer' if r == 0 else 'Scheitel höher' if r == len(gruppe) - 1 else 'Scheitel in der Mitte'
            alts[i] = f'{alt}, {zusatz}'
    for i, (rolle, a, d, e) in enumerate(v):
        alt = alts[i]
        optionen.append({'id': ids[i], 'alt': alt})
        figuren.append({'option': ids[i], 'generator': 'parabel', 'alt': alt,
                        'params': {'a': _zahl_json(a), 'd': _zahl_json(d), 'e': _zahl_json(e), **fenster, 'gitter': True}})
        if rolle == 'r':
            richtig = ids[i]
        else:
            fb.append({'key': rolle, 'option': ids[i]})
    return {'format': 'graph_auswahl', 'optionen': optionen}, figuren, richtig, fb


def graph_pruefen(inst, a: Fraction, d: Fraction, e: Fraction) -> dict:
    """Prüfung 1 (Konzept §5): aus den Figur-Parametern jeder Option die Funktion; genau eine passt zu (a, d, e),
    jede andere ist die Option genau eines Fehlbilds."""
    def bruch_(x) -> Fraction:
        return Fraction(x).limit_denominator(100)
    passend = [f['option'] for f in inst.figur
               if (bruch_(f['params']['a']), bruch_(f['params']['d']), bruch_(f['params']['e'])) == (a, d, e)]
    if len(passend) != 1:
        raise ValueError(f'nicht genau eine passende Option: {passend}')
    andere = {f['option'] for f in inst.figur} - set(passend)
    if andere != {f['option'] for f in inst.fehlbilder} or len({f['option'] for f in inst.fehlbilder}) != len(inst.fehlbilder):
        raise ValueError('nicht jede andere Option gehört zu genau einem Fehlbild')
    if len({(f['params']['a'], f['params']['d'], f['params']['e']) for f in inst.figur}) != len(inst.figur):
        raise ValueError('zwei Optionen zeigen dieselbe Parabel')
    return {'option': passend[0]}


def fenster_fuer(punkte: list[tuple[Fraction, Fraction]], rand: int = 3) -> dict:
    xs = [int(p[0]) for p in punkte]
    ys = [int(p[1]) for p in punkte]
    return {'x_min': min(xs + [0]) - rand, 'x_max': max(xs + [0]) + rand, 'y_min': min(ys + [0]) - rand,
            'y_max': max(ys + [0]) + rand + 2}


def bausteine_payload(key: str, texte: list[tuple[str, str]], anzahl: int = 1) -> tuple[dict, dict[str, str]]:
    """texte: [(rolle, text)] → gemischte Bausteine mit ids a–e; liefert (payload, rolle → id)."""
    import random
    t = list(texte)
    random.Random(f'{key}-{texte}').shuffle(t)
    ids = 'abcde'
    return ({'format': 'bausteine', 'bausteine': [{'id': ids[i], 'text': x} for i, (_, x) in enumerate(t)], 'anzahl': anzahl},
            {r: ids[i] for i, (r, _) in enumerate(t)})


def scheitel_von(text: str) -> tuple[Fraction, Fraction]:
    """Scheitel des Terms (sympy, aus dem angezeigten Text)."""
    import sympy

    from .rechnen import X, ausdruck
    f = ausdruck(text)
    xs = sympy.solve(sympy.diff(f, X), X)[0]
    ys = f.subs(X, xs)
    return Fraction(int(sympy.Rational(xs).p), int(sympy.Rational(xs).q)), Fraction(int(sympy.Rational(ys).p), int(sympy.Rational(ys).q))


def scheitel_aus_kontext(frage: str, name: str, var: str) -> tuple[Fraction, Fraction, int]:
    """Scheitel (Stelle, Wert) und Vorzeichen von a der Funktion `name(var) = …` im Text (sympy)."""
    import re
    import sympy

    from .rechnen import X, ausdruck
    term = re.search(rf'{name}\({var}\) = (.+?) \(', frage).group(1)
    f = ausdruck(term.replace(var, 'x')) if var != 'x' else ausdruck(term)
    xs = sympy.solve(sympy.diff(f, X), X)[0]
    ys = f.subs(X, xs)
    a = sympy.Poly(f, X).LC()
    r = lambda v: Fraction(int(sympy.Rational(v).p), int(sympy.Rational(v).q))  # noqa: E731
    return r(xs), r(ys), (1 if a > 0 else -1)


def dezimal_oder_bruch(x: Fraction) -> list[str]:
    """Antwortschreibweisen: gekürzter Bruch, bei endlicher Dezimalzahl auch mit Komma und Punkt."""
    x = Fraction(x)
    aus = [zahl_antwort(x)]
    d = x.denominator
    for p in (2, 5):
        while d % p == 0:
            d //= p
    if x.denominator != 1 and d == 1:
        t = f'{float(x):.6f}'.rstrip('0').rstrip('.')
        aus += [t.replace('.', ','), t]
    return aus
