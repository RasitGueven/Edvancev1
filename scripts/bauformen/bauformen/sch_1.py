"""SCH-1 · Scheitelpunkt von f(x) = a(x − d)² + e (fkt_quadr_scheitel, K1). Feldmaske Punkt S([x] | [y]).
S1 d, e > 0 · S2 Vorzeichen gemischt · S3 Form (x + d) · S4 a ≠ 1. Rollen W Ü B H G."""

from __future__ import annotations

import random
import re

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte
from ..rechnen import X, ausdruck


class SCH1(Bauform):
    key = 'SCH-1'
    skill = 'fkt_quadr_scheitel'
    kernidee = 'fkt_quadr_scheitel:K1'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'beispiel', 'home', 'generalprobe')
    stufen = {1: 'f(x) = (x − d)² + e, d und e von 1 bis 9', 2: 'e negativ, d positiv',
              3: 'f(x) = (x + d)² + e: d negativ, e beliebig', 4: 'a ∈ {−3, −2, 2, 3, 1/2}, d und e beliebig'}
    text = 'Gib den Scheitelpunkt von f(x) = {term} an.'
    fehlbild_steckbrief = [
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'S(−d | e)', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Für welches x wird die Klammer null? Das ist die x-Koordinate des Scheitels.'},
        {'key': 'qf_d_e_vertauscht', 'regel': 'S(e | d)', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Die Zahl in der Klammer gehört zu x, die Zahl hinten zu y.'},
        {'key': 'qf_a_als_koordinate', 'regel': 'S(a | e) bzw. S(d | a)', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Die Zahl vor der Klammer streckt die Parabel. Sie verschiebt den Scheitel nicht.'},
    ]
    hinweis_vorlagen = ['In der Scheitelpunktform f(x) = a(x − d)² + e liest du S(d | e) ab.',
                        'Für welches x wird die Klammer null?', 'Die y-Koordinate ist die Zahl, die hinten addiert wird.']
    warum = {'bei_schritt': 1, 'frage': 'Warum liest man das Vorzeichen in der Klammer umgekehrt ab?',
             'bausteine': [{'id': 'a', 'text': 'Für x = d wird die Klammer null, dort liegt der Scheitel.'},
                           {'id': 'b', 'text': 'Weil man das Vorzeichen in der Klammer immer übernimmt.'},
                           {'id': 'c', 'text': 'Weil die Parabel nach oben geöffnet ist.'}],
             'richtig': 'a'}
    zeit_sek = 45
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e = rng.randint(1, 9), rng.randint(1, 9)
            a = '1'
            if stufe == 2:
                e = -e
            elif stufe == 3:
                d, e = -d, rng.choice([-1, 1]) * e
            elif stufe == 4:
                d, e = rng.choice([-1, 1]) * d, rng.choice([-1, 1]) * e
                a = rng.choice(['-3', '-2', '2', '3', '1/2'])
            if abs(d) != abs(e):
                return {'a': a, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        from fractions import Fraction
        a, d, e = Fraction(params['a']), params['d'], params['e']
        vor = '' if a == 1 else ('−' if a == -1 else f'{zahl(a)}')
        term = f'{vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}'
        schab = fm('S(', '±x', ' | ', '±y', ')')
        loes = werte(x=d, y=e)
        regeln = {'qf_verschiebung_vorzeichen': (-d, e), 'qf_d_e_vertauscht': (e, d)}
        if stufe == 4:
            regeln['qf_a_als_koordinate'] = (a, e)
        fb, gesehen = [], {(d, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w in gesehen:
                continue
            gesehen.add(w)
            fb.append({'key': f['key'], **werte(x=w[0], y=w[1])})
        weg = [f'f(x) = {term}', f'Die Klammer wird null für x = {zahl(d)}.', f'Dann ist f({zahl(d)}) = {zahl(e)}.',
               f'S({zahl(d)} | {zahl(e)})']
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'FELDMASKE', feldmaske(schab), loes,
                       fb, list(self.hinweis_vorlagen), weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+) an\.', inst.frage).group(1))
        xs = sympy.solve(sympy.diff(f, X), X)[0]
        return werte(x=int(xs), y=int(f.subs(X, xs)))


BAUFORM = SCH1()
