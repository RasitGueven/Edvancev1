"""NS-2 · Nullstellen aus der Normalform (fkt_quadr_nullstellen, K2). Lösungsmenge.
S3 f(x) = x² + px + q · S4 a ≠ 1. Rollen Ü B G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import klammer, menge, menge_text, mengen_fehlbilder, mengen_payload, nullstellen_aus_text, wurzel


def _pq(p: Fraction, q: Fraction) -> list[Fraction] | None:
    w = wurzel((p / 2) ** 2 - q)
    return None if w is None else sorted({-p / 2 + w, -p / 2 - w})


class NS2(Bauform):
    key = 'NS-2'
    skill = 'fkt_quadr_nullstellen'
    kernidee = 'fkt_quadr_nullstellen:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'beispiel', 'generalprobe')
    stufen = {3: 'f(x) = x² + px + q, zwei ganzzahlige Nullstellen', 4: 'f(x) = a·x² + bx + c, a ∈ {−1, 2, 3}'}
    text = 'Bestimme die Nullstellen von f(x) = {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_p_vorzeichen', 'regel': 'p/2 statt −p/2', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Vor p/2 steht in der Formel ein Minus. Setz −p/2 ein.'},
        {'key': 'qf_q_vorzeichen', 'regel': '+ q unter der Wurzel', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Unter der Wurzel wird q abgezogen. Achte auf das Vorzeichen von q.'},
        {'key': 'qf_durch_a_vergessen', 'regel': 'ohne Teilen durch a', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Die p-q-Formel gilt nur mit einer 1 vor x². Teil zuerst durch die Zahl vor x².'},
    ]
    hinweis_vorlagen = ['Nullstellen heißt: Setz f(x) = 0.', 'Bring die Gleichung in die Form x² + px + q = 0.',
                        'Löse mit der p-q-Formel: x = −p/2 ± √((p/2)² − q).']
    warum = {'bei_schritt': 0, 'frage': 'Warum setzt man f(x) = 0?',
             'bausteine': [{'id': 'a', 'text': 'An einer Nullstelle schneidet der Graph die x-Achse, dort ist y = 0.'},
                           {'id': 'b', 'text': 'Weil x an der Nullstelle 0 ist.'},
                           {'id': 'c', 'text': 'Weil man sonst die p-q-Formel nicht braucht.'}],
             'richtig': 'a'}
    zeit_sek = 150
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            r1, r2 = rng.randint(-9, 9), rng.randint(-9, 9)
            if r1 != r2 and 0 not in (r1, r2) and r1 + r2 != 0:
                return {'a': 1 if stufe == 3 else rng.choice([-1, 2, 3]), 'p': -(r1 + r2), 'q': r1 * r2}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q = params['a'], Fraction(params['p']), Fraction(params['q'])
        term = summe([(a, 'x²'), (a * p, 'x'), (a * q, '')])
        richtig = _pq(p, q)
        regeln = {'qf_p_vorzeichen': _pq(-p, q), 'qf_q_vorzeichen': _pq(p, -q),
                  'qf_durch_a_vergessen': _pq(a * p, a * q) if a != 1 else None}
        m, d = -p / 2, (p / 2) ** 2 - q
        weg = ['f(x) = 0', f'{term} = 0'] + ([f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'] if a != 1 else []) + \
              [f'x₁,₂ = {zahl(m)} ± √({klammer(m)}² − {klammer(q)})', f'x₁,₂ = {zahl(m)} ± {zahl(wurzel(d))}',
               f'L = {menge_text(richtig)}']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln), list(self.hinweis_vorlagen), weg,
                       [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(nullstellen_aus_text(inst.frage))


BAUFORM = NS2()
