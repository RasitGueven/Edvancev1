"""EX-1 · Zaun mit fester Länge, größte Fläche (fkt_quadr_extrem, K1). Mehrteiler mit Kontext.
S4 rechteckiges Beet, Zaun ringsum · S5 Beet an einer Hauswand, Zaun an drei Seiten. Rollen T G."""

from __future__ import annotations

import random
import re
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, zahl, zahl_antwort
from ..formen import dezimal_oder_bruch
from ..klassisch import teil


class EX1(Bauform):
    key = 'EX-1'
    skill = 'fkt_quadr_extrem'
    kernidee = 'fkt_quadr_extrem:K1'
    format = 'mehrteiler'
    rollen = ('transfer', 'generalprobe')
    kann_entfallen = True
    stufen = {4: 'Zaun ringsum: A(x) = x · (L/2 − x), größte Fläche beim Quadrat', 5: 'an der Hauswand: A(x) = x · (L − 2x)'}
    text = '{kontext}'
    fehlbild_steckbrief = [
        {'key': 'qf_umfang_statt_flaeche', 'regel': 'in Teil 2 die Zaunlänge statt der Fläche', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Gefragt ist die Fläche, nicht die Länge des Zauns. Fläche heißt Länge mal Breite.'},
        {'key': 'qf_stelle_statt_wert', 'regel': 'in Teil 2 x statt der Fläche', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'x ist die Seitenlänge. Gefragt ist der größte Wert der Fläche A(x).'},
    ]
    hinweis_vorlagen = ['Gib die Fläche als Term in x an: Länge mal Breite.', 'A(x) ist eine quadratische Funktion. Wo liegt ihr Scheitel?',
                        'Die Nullstellen von A(x) helfen: Der Scheitel liegt genau in der Mitte.']
    zeit_sek = 300
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'L': rng.choice(range(8, 81, 4)) if stufe == 4 else rng.choice(range(8, 81, 4))}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        L = params['L']
        if stufe == 4:
            kontext = (f'Mit {L} m Zaun soll ein rechteckiges Beet ganz eingezäunt werden. Eine Seite ist x m lang. '
                       'Wie muss man x wählen, damit die Fläche am größten ist?')
            x, A = Fraction(L, 4), Fraction(L, 4) ** 2
            weg = [f'Die andere Seite ist ({zahl(Fraction(L, 2))} − x) m lang.', f'A(x) = x · ({zahl(Fraction(L, 2))} − x)',
                   f'Nullstellen 0 und {zahl(Fraction(L, 2))}, Scheitel in der Mitte: x = {zahl(x)}', f'A = {zahl(x)} · {zahl(x)} = {zahl(A)}']
        else:
            kontext = (f'Ein rechteckiges Beet liegt an einer Hauswand. Die anderen drei Seiten bekommen {L} m Zaun. '
                       'Die beiden Seiten, die von der Wand weggehen, sind je x m lang. Wie muss man x wählen, damit die Fläche am größten ist?')
            x, A = Fraction(L, 4), Fraction(L, 4) * (L - Fraction(L, 2))
            weg = [f'Die Seite gegenüber der Wand ist ({L} − 2x) m lang.', f'A(x) = x · ({L} − 2x)',
                   f'Nullstellen 0 und {zahl(Fraction(L, 2))}, Scheitel in der Mitte: x = {zahl(x)}',
                   f'A = {zahl(x)} · {zahl(L - 2 * x)} = {zahl(A)}']
        teile = [teil(1, 'x in Metern'), teil(2, 'größte Fläche in Quadratmetern')]
        loes = {'teile': {'1': dezimal_oder_bruch(x), '2': dezimal_oder_bruch(A)}}
        fb = [{'key': 'qf_umfang_statt_flaeche', 'teil': 2, 'wert': zahl_antwort(L)}] if A != L else []
        if x != A and x != L:
            fb.append({'key': 'qf_stelle_statt_wert', 'teil': 2, 'wert': zahl_antwort(x)})
        return Instanz(self.key, rolle, stufe, params, kontext, 'MULTI_PART', None, loes, fb, list(self.hinweis_vorlagen),
                       weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        L = int(re.search(r'(\d+) m Zaun', inst.frage).group(1))
        x = sympy.Symbol('x', positive=True)
        A = x * (sympy.Rational(L, 2) - x) if 'ganz eingezäunt' in inst.frage else x * (L - 2 * x)
        xs = sympy.solve(sympy.diff(A, x), x)[0]
        r = lambda v: Fraction(int(sympy.Rational(v).p), int(sympy.Rational(v).q))  # noqa: E731
        return {'teile': {'1': [zahl_antwort(r(xs))], '2': [zahl_antwort(r(A.subs(x, xs)))]}}


BAUFORM = EX1()
