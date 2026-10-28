"""DI-3 · Für welches q gibt es genau eine Lösung? (gleichung_quadr_anzahl, K1). Zahl.
S4 p gerade · S5 p ungerade (q ist ein Bruch). Rollen T G."""

from __future__ import annotations

import random
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..formen import klammer
from ..klassisch import zahl_payload


class DI3(Bauform):
    key = 'DI-3'
    skill = 'gleichung_quadr_anzahl'
    kernidee = 'gleichung_quadr_anzahl:K1'
    format = 'zahl'
    rollen = ('transfer', 'generalprobe')
    stufen = {4: 'x² + px + q = 0, p gerade von −16 bis 16', 5: 'p ungerade von −15 bis 15, q ein Bruch'}
    text = 'Für welche Zahl q hat {gleichung} genau eine Lösung?'
    fehlbild_steckbrief = [
        {'key': 'qf_halbes_p_nicht_quadriert', 'regel': 'q = p/2', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Unter der Wurzel steht (p/2)² − q. Der Ausdruck soll 0 sein. Hast du p/2 quadriert?'},
        {'key': 'qf_q_vorzeichen', 'regel': 'q = −(p/2)²', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Setz (p/2)² − q = 0. Welches Vorzeichen hat q dann?'},
    ]
    hinweis_vorlagen = ['Wann hat eine quadratische Gleichung genau eine Lösung?',
                        'Der Ausdruck unter der Wurzel muss 0 sein: (p/2)² − q = 0.',
                        'Setz p = {p} ein und stell nach q um.']
    zeit_sek = 120
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p = rng.randint(-16, 16)
            if p not in (0, 2, -2, 1, -1) and (p % 2 == 0) == (stufe == 4):
                return {'p': p}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        p = Fraction(params['p'])
        q = (p / 2) ** 2
        gl = f'{summe([(1, "x²"), (p, "x")])} + q = 0'
        frage = f'Für welche Zahl q hat {gl} genau eine Lösung?'
        richtig = [zahl_antwort(q)] + ([] if q.denominator == 1 else [f'{float(q):g}'.replace('.', ','), f'{float(q):g}'])
        fb = [{'key': 'qf_halbes_p_nicht_quadriert', 'wert': zahl_antwort(p / 2)},
              {'key': 'qf_q_vorzeichen', 'wert': zahl_antwort(-q)}]
        h = f'({zahl(p / 2)})' if (p / 2).denominator != 1 else klammer(p / 2)
        weg = ['Genau eine Lösung heißt: (p/2)² − q = 0.', f'{h}² − q = 0', f'q = {h}²',
               f'q = {zahl(q)}']
        return Instanz(self.key, rolle, stufe, params, frage, 'NUMERIC', zahl_payload(frage), {'werte': richtig}, fb,
                       [h.format(p=zahl(p)) for h in self.hinweis_vorlagen], weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        from ..rechnen import X as x, ausdruck
        q = sympy.Symbol('q')
        term = inst.frage.split(' hat ')[1].split(' = 0')[0].replace('+ q', '')
        poly = sympy.Poly(sympy.expand(ausdruck(term)) + q, x)
        loes = sympy.solve(poly.discriminant(), q)
        w = sympy.Rational(loes[0])
        return {'werte': [zahl_antwort(Fraction(int(w.p), int(w.q)))]}


BAUFORM = DI3()
