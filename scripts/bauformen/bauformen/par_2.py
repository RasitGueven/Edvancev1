"""PAR-2 · Welcher Graph gehört zu f(x) = a·x²? (fkt_quadr_parabel, K2). Graph-Auswahl.
S1 a > 1 · S2 0 < a < 1 · S3 a < 0. Rollen Ü R H."""

from __future__ import annotations

import random
import re
from fractions import Fraction

from ..basis import Bauform, Instanz, zahl
from ..formen import graph_optionen, graph_pruefen
from ..rechnen import ausdruck, X


class PAR2(Bauform):
    key = 'PAR-2'
    skill = 'fkt_quadr_parabel'
    kernidee = 'fkt_quadr_parabel:K2'
    format = 'graph_auswahl'
    rollen = ('uebung', 'recap', 'home')
    stufen = {1: 'a ∈ {3/2, 2, 5/2, 3, 4}', 2: 'a ∈ {1/2, 1/3, 1/4, 2/3, 3/4}', 3: 'a ∈ {−1/3, −1/2, −2, −3, −4}'}
    text = 'Welcher Graph gehört zu f(x) = {term}?'
    fehlbild_steckbrief = [
        {'key': 'qf_streckfaktor_umgekehrt', 'regel': 'Graph zu 1/a (gestaucht statt gestreckt)', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Ist der Betrag von a größer als 1, wird die Parabel schmaler. Ist er kleiner als 1, wird sie breiter.'},
        {'key': 'qf_oeffnung_vertauscht', 'regel': 'Graph zu −a', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Das Vorzeichen von a entscheidet: positiv nach oben geöffnet, negativ nach unten.'},
    ]
    hinweis_vorlagen = ['Schau zuerst auf das Vorzeichen von a.', 'Ist a positiv, ist die Parabel nach oben geöffnet.',
                        'Vergleiche mit der Normalparabel: Ist der Betrag von a größer als 1, wird sie schmaler.']
    zeit_sek = 45

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'a': rng.choice({1: ['3/2', '2', '5/2', '3', '4'], 2: ['1/2', '1/3', '1/4', '2/3', '3/4'],
                                 3: ['-1/3', '-1/2', '-2', '-3', '-4']}[stufe])}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a = Fraction(params['a'])
        term = (('−' if a < 0 else '') + (f'{zahl(abs(a))}x²' if abs(a).denominator == 1 else f'{zahl(abs(a))} · x²'))
        fenster = {'x_min': -4, 'x_max': 4, 'y_min': -6, 'y_max': 6}
        payload, fig, richtig, fb = graph_optionen(self.key, [('r', a, 0, 0), ('qf_streckfaktor_umgekehrt', 1 / a, 0, 0),
                                                              ('qf_oeffnung_vertauscht', -a, 0, 0)], fenster)
        weg = [f'a = {zahl(a)}', 'a ist positiv: nach oben geöffnet.' if a > 0 else 'a ist negativ: nach unten geöffnet.',
               'Der Betrag von a ist größer als 1: schmaler als die Normalparabel.' if abs(a) > 1 else
               'Der Betrag von a ist kleiner als 1: breiter als die Normalparabel.']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'GRAPH_AUSWAHL', payload,
                       {'option': richtig}, fb, list(self.hinweis_vorlagen), weg, figur=fig)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+)\?', inst.frage).group(1))
        a = f.coeff(X, 2)
        return graph_pruefen(inst, Fraction(int(a.p), int(a.q)), Fraction(0), Fraction(0))


BAUFORM = PAR2()
