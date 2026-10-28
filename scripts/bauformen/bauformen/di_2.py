"""DI-2 · Warum hat die Gleichung keine Lösung? (gleichung_quadr_anzahl, K1). Begründungsbausteine. S3. Rollen R T."""

from __future__ import annotations

import random
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import klammer
from ..rechnen import X, gleichung_aus_frage


class DI2(Bauform):
    key = 'DI-2'
    skill = 'gleichung_quadr_anzahl'
    kernidee = 'gleichung_quadr_anzahl:K1'
    format = 'bausteine'
    rollen = ('recap', 'transfer')
    stufen = {3: 'x² + px + q = 0 mit (p/2)² − q < 0; eine richtige Begründung mit der Rechnung, drei falsche'}
    text = 'Warum hat {gleichung} keine Lösung? Wähle die passende Begründung.'
    fehlbild_steckbrief = [
        {'key': 'qf_q_vorzeichen', 'regel': 'Begründung mit (p/2)² + q', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Unter der Wurzel wird q abgezogen. Rechne (p/2)² − q noch einmal.'},
    ]
    hinweis_vorlagen = ['Welcher Teil der p-q-Formel entscheidet über die Anzahl der Lösungen?',
                        'Rechne (p/2)² − q aus.', 'Kann man aus dem Ergebnis eine Wurzel ziehen?']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p = rng.choice([-2, 2]) * rng.randint(1, 6)
            q = rng.randint(1, 50)
            if Fraction(p, 2) ** 2 - q < 0 and Fraction(p, 2) ** 2 + q != Fraction(p, 2) ** 2 - q:
                return {'p': p, 'q': q}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        p, q = Fraction(params['p']), Fraction(params['q'])
        gl = f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'
        d, df = (p / 2) ** 2 - q, (p / 2) ** 2 + q
        texte = [('r', f'Unter der Wurzel steht {klammer(p / 2)}² − {zahl(q)} = {zahl(d)}. Das ist negativ.'),
                 ('f', f'Unter der Wurzel steht {klammer(p / 2)}² + {zahl(q)} = {zahl(df)}. Das ist positiv.'),
                 ('n1', 'Weil q positiv ist, hat die Gleichung nie eine Lösung.'),
                 ('n2', 'Weil p eine gerade Zahl ist.')]
        rng = random.Random(f'di2-{p}-{q}')
        rng.shuffle(texte)
        ids = 'abcd'
        payload = {'format': 'bausteine', 'bausteine': [{'id': ids[i], 'text': t} for i, (_, t) in enumerate(texte)],
                   'anzahl': 1}
        nach = {k: ids[i] for i, (k, _) in enumerate(texte)}
        weg = [gl, f'p = {zahl(p)}, q = {zahl(q)}', f'(p/2)² − q = {klammer(p / 2)}² − {zahl(q)} = {zahl(d)}',
               'Aus einer negativen Zahl kann man keine Wurzel ziehen.', 'L = { }']
        return Instanz(self.key, rolle, stufe, params, f'Warum hat {gl} keine Lösung? Wähle die passende Begründung.',
                       'BAUSTEINE', payload, {'gewaehlt': [nach['r']]},
                       [{'key': 'qf_q_vorzeichen', 'gewaehlt': [nach['f']]}], list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Rechnet D aus dem Text nach; der richtige Baustein nennt genau diesen Wert und „negativ“."""
        links, rechts = gleichung_aus_frage('Löse ' + inst.frage.removeprefix('Warum hat ').split(' keine')[0] + '.')
        poly = sympy.Poly(sympy.expand(links - rechts), X)
        _, b, c = poly.all_coeffs()
        d = Fraction(int(b)) ** 2 / 4 - Fraction(int(c))
        passend = [x['id'] for x in inst.payload['bausteine'] if x['text'].endswith(f'= {zahl(d)}. Das ist negativ.')]
        if len(passend) != 1 or d >= 0:
            raise ValueError('kein eindeutiger richtiger Baustein')
        return {'gewaehlt': passend}


BAUFORM = DI2()
