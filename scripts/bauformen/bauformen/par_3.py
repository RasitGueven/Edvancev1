"""PAR-3 · Welcher Graph gehört zu f(x) = (x − d)² + e? (fkt_quadr_parabel, K3). Graph-Auswahl.
S1 nur e · S2 nur d · S3 d und e. Rollen Ü H G."""

from __future__ import annotations

import random
import re
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import fenster_fuer, graph_optionen, graph_pruefen
from ..rechnen import X, ausdruck


class PAR3(Bauform):
    key = 'PAR-3'
    skill = 'fkt_quadr_parabel'
    kernidee = 'fkt_quadr_parabel:K3'
    format = 'graph_auswahl'
    rollen = ('uebung', 'home', 'generalprobe')
    stufen = {1: 'f(x) = x² + e, e von −5 bis 5', 2: 'f(x) = (x − d)², d von −5 bis 5', 3: 'f(x) = (x − d)² + e, beide ungleich 0'}
    text = 'Welcher Graph gehört zu f(x) = {term}?'
    fehlbild_steckbrief = [
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'in die falsche Richtung verschoben', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Für welches x wird die Klammer null? Dort liegt der Scheitel. Ein + e hinten schiebt nach oben.'},
        {'key': 'qf_d_e_vertauscht', 'regel': 'Verschiebung nach rechts und nach oben vertauscht', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Die Zahl in der Klammer verschiebt nach rechts oder links, die Zahl hinten nach oben oder unten.'},
    ]
    hinweis_vorlagen = ['Wo liegt der Scheitel dieser Parabel?', 'Aus f(x) = (x − d)² + e liest du S(d | e) ab.',
                        'Such den Graphen, dessen Scheitel an dieser Stelle liegt.']
    zeit_sek = 45
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e = rng.randint(-5, 5), rng.randint(-5, 5)
            if stufe == 1:
                d = 0
            if stufe == 2:
                e = 0
            if (stufe == 1 and e) or (stufe == 2 and d) or (stufe == 3 and d and e and abs(d) != abs(e)):
                return {'d': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        d, e = params['d'], params['e']
        if d == 0:
            term = summe([(1, 'x²'), (e, '')])
        else:
            term = f'({summe([(1, "x"), (-d, "")])})²' + (f' {"+" if e > 0 else "−"} {abs(e)}' if e else '')
        falsch = (-d, e) if d else (d, -e)
        var = [('r', 1, d, e), ('qf_verschiebung_vorzeichen', 1, *falsch), ('qf_d_e_vertauscht', 1, e, d)]
        payload, fig, richtig, fb = graph_optionen(self.key, var, fenster_fuer([(v[2], v[3]) for v in var]))
        weg = [f'f(x) = {term}', f'Scheitel S({zahl(d)} | {zahl(e)})',
               'Der richtige Graph hat seinen Scheitel an dieser Stelle und ist nach oben geöffnet.']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'GRAPH_AUSWAHL', payload,
                       {'option': richtig}, fb, list(self.hinweis_vorlagen), weg, figur=fig)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+)\?', inst.frage).group(1))
        xs = sympy.solve(sympy.diff(f, X), X)[0]
        return graph_pruefen(inst, Fraction(1), Fraction(int(xs)), Fraction(int(f.subs(X, xs))))


BAUFORM = PAR3()
