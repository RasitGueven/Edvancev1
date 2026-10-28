"""DI-1 · Wie viele Lösungen? (gleichung_quadr_anzahl, K1). Multiple Choice (keine, eine, zwei).
S1 p, q klein · S2 größere Zahlen · S3 a ≠ 1 · S4 nicht in Normalform. Rollen W Ü B R H G."""

from __future__ import annotations

import random
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import klammer
from ..klassisch import mc_payload
from ..rechnen import X, gleichung_aus_frage

OPTIONEN = [('a', 'keine Lösung'), ('b', 'genau eine Lösung'), ('c', 'zwei Lösungen')]


def _anzahl(d: Fraction) -> str:
    return 'a' if d < 0 else 'b' if d == 0 else 'c'


class DI1(Bauform):
    key = 'DI-1'
    skill = 'gleichung_quadr_anzahl'
    kernidee = 'gleichung_quadr_anzahl:K1'
    format = 'mc'
    rollen = ('warmup', 'uebung', 'beispiel', 'recap', 'home', 'generalprobe')
    stufen = {1: 'x² + px + q = 0, p und q von −6 bis 6', 2: 'p und q von −20 bis 20',
              3: 'a·x² + b·x + c = 0 mit a von 2 bis 4', 4: 'nicht in Normalform: x² + px = c'}
    text = 'Wie viele Lösungen hat {gleichung}?'
    fehlbild_steckbrief = [
        {'key': 'qf_q_vorzeichen', 'regel': 'D = (p/2)² + q', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Unter der Wurzel steht (p/2)² − q. Achte auf das Vorzeichen von q.'},
        {'key': 'qf_diskriminante_ohne_p', 'regel': 'D = −q ((p/2)² vergessen)', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Unter der Wurzel steht auch (p/2)². Hast du es mitgerechnet?'},
    ]
    hinweis_vorlagen = ['Was entscheidet bei der p-q-Formel, wie viele Lösungen es gibt?',
                        'Rechne nur den Ausdruck unter der Wurzel aus: (p/2)² − q.',
                        'Ist der Ausdruck positiv, null oder negativ?']
    warum = {'bei_schritt': 1, 'frage': 'Warum entscheidet der Ausdruck unter der Wurzel?',
             'bausteine': [{'id': 'a', 'text': 'Aus einer negativen Zahl kann man keine Wurzel ziehen, aus 0 nur eine.'},
                           {'id': 'b', 'text': 'Weil p immer größer als q ist.'},
                           {'id': 'c', 'text': 'Weil die Wurzel immer zwei Lösungen hat.'}],
             'richtig': 'a'}
    zeit_sek = 60
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        g = 6 if stufe == 1 else 20
        art = rng.choice(['a', 'b', 'c'])
        while True:
            p = rng.choice([-2, 2]) * rng.randint(1, g // 2)
            if art == 'b':
                q = (p // 2) ** 2
            else:
                q = rng.randint(-g, g)
            d = Fraction(p, 2) ** 2 - q
            if _anzahl(d) == art and (stufe != 1 or abs(q) <= 6):
                return {'a': rng.randint(2, 4) if stufe == 3 else 1, 'p': p, 'q': q}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q = params['a'], Fraction(params['p']), Fraction(params['q'])
        if stufe == 4:
            gl = f'{summe([(1, "x²"), (p, "x")])} = {zahl(-q)}'
        else:
            gl = f'{summe([(a, "x²"), (a * p, "x"), (a * q, "")])} = 0'
        d = (p / 2) ** 2 - q
        richtig = _anzahl(d)
        fb, gesehen = [], {richtig}
        for key, df in (('qf_q_vorzeichen', (p / 2) ** 2 + q), ('qf_diskriminante_ohne_p', -q)):
            o = _anzahl(df)
            if o not in gesehen:
                gesehen.add(o)
                fb.append({'key': key, 'option': o})
        weg = [gl] + ([f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'] if stufe in (3, 4) else []) + \
              [f'p = {zahl(p)}, q = {zahl(q)}', f'(p/2)² − q = {klammer(p / 2)}² − {klammer(q)} = {zahl(d)}',
               {'a': f'{zahl(d)} ist negativ: keine Lösung.', 'b': 'Der Ausdruck ist 0: genau eine Lösung.',
                'c': f'{zahl(d)} ist positiv: zwei Lösungen.'}[richtig]]
        return Instanz(self.key, rolle, stufe, params, f'Wie viele Lösungen hat {gl}?', 'MC', mc_payload(OPTIONEN),
                       {'option': richtig}, fb, list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        links, rechts = gleichung_aus_frage('Löse ' + inst.frage.removeprefix('Wie viele Lösungen hat ').rstrip('?') + '.')
        poly = sympy.Poly(sympy.expand(links - rechts), X)
        d = poly.discriminant()
        return {'option': 'a' if d < 0 else 'b' if d == 0 else 'c'}


BAUFORM = DI1()
