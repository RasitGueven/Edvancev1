"""WZ-5 · Lösungen mit Wurzel, z. B. x² = 7 (gleichung_quadr_wurzel, K1). Multiple Choice. S4. Rolle Ü."""

from __future__ import annotations

import random
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, zahl
from ..formen import wurzel
from ..klassisch import mc_payload
from ..rechnen import zeilen_menge


def _dez(x: Fraction) -> str:
    return zahl(x) if x.denominator == 1 else f'{float(x):g}'.replace('.', ',')


class WZ5(Bauform):
    key = 'WZ-5'
    skill = 'gleichung_quadr_wurzel'
    kernidee = 'gleichung_quadr_wurzel:K1'
    format = 'mc'
    rollen = ('uebung',)
    stufen = {4: 'x² = c, c keine Quadratzahl von 2 bis 60'}
    text = 'Welche Lösungen hat x² = {c}?'
    fehlbild_steckbrief = [
        {'key': 'qf_nur_positive_loesung', 'regel': 'nur √c', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Auch −√c ins Quadrat ergibt c. Gibt es eine zweite Lösung?'},
        {'key': 'qf_wurzel_als_haelfte', 'regel': '±c/2', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Die Wurzel ist nicht die Hälfte. Prüf: Ergibt (c/2)² wirklich c?'},
        {'key': 'qf_quadriert_statt_wurzel', 'regel': '±c²', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Um x² rückgängig zu machen, zieht man die Wurzel, man quadriert nicht noch einmal.'},
    ]
    hinweis_vorlagen = ['Ist {c} eine Quadratzahl?', 'Wenn nicht, bleibt die Wurzel als Zahl stehen.',
                        'Denk daran: Auch eine negative Zahl ins Quadrat ist positiv.']
    zeit_sek = 45

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            c = rng.randint(2, 60)
            if wurzel(c) is None:
                return {'c': c}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        c = params['c']
        h = _dez(Fraction(c, 2))
        opts = [('r', f'x = √{c} oder x = −√{c}'), ('qf_nur_positive_loesung', f'x = √{c}'),
                ('qf_wurzel_als_haelfte', f'x = {h} oder x = −{h}'), ('qf_quadriert_statt_wurzel', f'x = {c * c} oder x = −{c * c}')]
        rng = random.Random(f'wz5-{c}')
        rng.shuffle(opts)
        ids = 'abcd'
        payload = mc_payload([(ids[i], t) for i, (_, t) in enumerate(opts)])
        richtig = next(ids[i] for i, (k, _) in enumerate(opts) if k == 'r')
        fb = [{'key': k, 'option': ids[i]} for i, (k, _) in enumerate(opts) if k != 'r']
        weg = [f'x² = {c}', f'{c} ist keine Quadratzahl, die Wurzel bleibt stehen.', f'x = √{c} oder x = −√{c}']
        return Instanz(self.key, rolle, stufe, params, self.text.format(c=c), 'MC', payload, {'option': richtig}, fb,
                       [h_.format(c=c) for h_ in self.hinweis_vorlagen], weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        c = int(inst.frage.split('= ')[1].rstrip('?'))
        ziel = sympy.solveset(sympy.Symbol('x', real=True) ** 2 - c, sympy.Symbol('x', real=True), sympy.S.Reals)
        passend = [o['id'] for o in inst.payload['options'] if zeilen_menge(o['label'].replace(',', '.')) == ziel]
        if len(passend) != 1:
            raise ValueError(f'nicht genau eine passende Option: {passend}')
        return {'option': passend[0]}


BAUFORM = WZ5()
