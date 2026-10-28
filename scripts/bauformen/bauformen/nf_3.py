"""NF-3 · Quadratische Ergänzung mit a ≠ 1 (fkt_quadr_normalform, K3). Feldmaske [a](x [±][d])² [±][e].
S4 a ∈ {2, 3}, ganzzahliger Scheitel · S5 a ∈ {−2, −1, 4, 5}. Rollen Ü T G."""

from __future__ import annotations

import random
import re
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte
from ..rechnen import X, ausdruck


class NF3(Bauform):
    key = 'NF-3'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K3'
    format = 'feldmaske'
    rollen = ('uebung', 'transfer', 'generalprobe')
    stufen = {4: 'f(x) = a·x² + b·x + c mit a ∈ {2, 3}, Scheitel ganzzahlig', 5: 'a ∈ {−2, −1, 4, 5}, Scheitel ganzzahlig'}
    text = 'Schreib f(x) = {term} in der Scheitelpunktform.'
    fehlbild_steckbrief = [
        {'key': 'qf_ausklammern_a_verloren', 'regel': 'a(x + b/2)² …: b nicht durch a geteilt', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Klammere a zuerst aus. In der Klammer steht dann x² + (b/a)x.'},
        {'key': 'qf_ergaenzung_ohne_a', 'regel': 'e = c − (b/(2a))²', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Die Ergänzung steht in der Klammer mit a davor. Beim Herausziehen musst du sie mit a malnehmen.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'Vorzeichen in der Klammer falsch', 'gilt_fuer_stufen': [4, 5],
         'rueckmeldung': 'Das Vorzeichen in der Klammer ist dasselbe wie das Vorzeichen vor x nach dem Ausklammern.'},
    ]
    hinweis_vorlagen = ['Klammere zuerst die Zahl vor x² aus: f(x) = {a}(x² {bx_text}) {c_text}.',
                        'Ergänze in der Klammer zu einem Quadrat.', 'Was du in der Klammer dazugibst, zählt außen {a}-mal.']
    zeit_sek = 180
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a = rng.choice([2, 3] if stufe == 4 else [-2, -1, 4, 5])
            d, e = rng.randint(-6, 6), rng.randint(-15, 15)
            if d != 0 and e != 0:
                return {'a': a, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        b, c = -2 * a * d, a * d * d + e
        term = summe([(a, 'x²'), (b, 'x'), (c, '')])
        schab = fm('[a]', '(x ', '±d', ')² ', '±e')
        loes = werte(a=a, d=-d, e=e)
        regeln = {'qf_ausklammern_a_verloren': (a, Fraction(b, 2), c - Fraction(b, 2) ** 2),
                  'qf_ergaenzung_ohne_a': (a, -d, c - d * d), 'qf_verschiebung_vorzeichen': (a, d, e)}
        fb, gesehen = [], {(a, -d, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen and all(Fraction(x).denominator == 1 for x in w):
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(a=w[0], d=w[1], e=w[2])})
        innen = summe([(1, 'x²'), (Fraction(b, a), 'x')])
        va = '−' if a == -1 else zahl(a)
        weg = [f'f(x) = {term}', f'= {va}({innen}) {"+" if c >= 0 else "−"} {abs(c)}',
               f'= {va}({innen} + {zahl(d * d)} − {zahl(d * d)}) {"+" if c >= 0 else "−"} {abs(c)}',
               f'= {va}({summe([(1, "x"), (-d, "")])})² {"−" if a * d * d >= 0 else "+"} {abs(a * d * d)} {"+" if c >= 0 else "−"} {abs(c)}',
               f'= {va}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}']
        hw = {'a': zahl(a), 'bx_text': summe([(Fraction(b, a), 'x')]).join(['+ ', '']) if b * a > 0 else summe([(Fraction(b, a), 'x')]).replace('−', '− '),
              'c_text': f'+ {c}' if c >= 0 else f'− {-c}'}
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'FELDMASKE', feldmaske(schab), loes, fb,
                       [h.format(**hw) for h in self.hinweis_vorlagen], weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+) in der', inst.frage).group(1))
        a = sympy.Poly(f, X).LC()
        xs = sympy.solve(sympy.diff(f, X), X)[0]
        return werte(a=int(a), d=-int(xs), e=int(f.subs(X, xs)))


BAUFORM = NF3()
