"""NF-2 · Quadratische Ergänzung, a = 1 (fkt_quadr_normalform, K2). Feldmaske (x [±][d])² [±][e].
S2 b gerade, e ≥ 0 · S3 b gerade, e beliebig · S4 b ungerade (Brüche). Rollen Ü B H G."""

from __future__ import annotations

import random
import re
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte
from ..rechnen import X, ausdruck


class NF2(Bauform):
    key = 'NF-2'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K2'
    format = 'feldmaske'
    rollen = ('uebung', 'beispiel', 'home', 'generalprobe')
    stufen = {2: 'f(x) = x² + bx + c, b gerade, e = c − (b/2)² ≥ 0', 3: 'b gerade, e beliebig',
              4: 'b ungerade: d und e sind Brüche'}
    text = 'Schreib f(x) = {term} in der Scheitelpunktform.'
    fehlbild_steckbrief = [
        {'key': 'qf_ergaenzung_nicht_abgezogen', 'regel': 'e = c', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Was du in der Klammer dazugibst, musst du hinten wieder abziehen.'},
        {'key': 'qf_ergaenzung_b_statt_halb', 'regel': '(x + b)² + c − b²', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'In die Klammer kommt die Hälfte der Zahl vor x.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': '(x − b/2)²', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Das Vorzeichen in der Klammer ist dasselbe wie das Vorzeichen vor x.'},
    ]
    hinweis_vorlagen = ['Welche Zahl ist die Hälfte von {b}?',
                        'Ergänze zu einem Quadrat: Gib die Hälfte der Zahl vor x im Quadrat dazu und zieh sie wieder ab.',
                        'Schreib x² {b_glied} + {hq} als Quadrat einer Klammer.']
    warum = {'bei_schritt': 1, 'frage': 'Warum zieht man ({h})² wieder ab?',
             'bausteine': [{'id': 'a', 'text': 'Damit sich der Wert der Funktion nicht ändert: + und − dieselbe Zahl ist 0.'},
                           {'id': 'b', 'text': 'Weil man in der Klammer nur positive Zahlen haben darf.'},
                           {'id': 'c', 'text': 'Weil die Parabel sonst nach unten geöffnet wäre.'}],
             'richtig': 'a'}
    zeit_sek = 150
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            b = rng.choice([-1, 1]) * (2 * rng.randint(1, 8) if stufe < 4 else 2 * rng.randint(0, 6) + 1)
            c = rng.randint(-20, 30)
            e = Fraction(c) - Fraction(b, 2) ** 2
            if stufe == 2 and e < 0:
                continue
            if e != c and e != 0:
                return {'b': b, 'c': c}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        b, c = Fraction(params['b']), Fraction(params['c'])
        h = b / 2
        e = c - h * h
        term = summe([(1, 'x²'), (b, 'x'), (c, '')])
        bruch = stufe == 4
        schab = fm('(x ', '±d/' if bruch else '±d', ')² ', '±e/' if bruch else '±e')
        loes = werte(d=h, e=e)
        regeln = {'qf_ergaenzung_nicht_abgezogen': (h, c), 'qf_ergaenzung_b_statt_halb': (b, c - b * b),
                  'qf_verschiebung_vorzeichen': (-h, e)}
        fb, gesehen = [], {(h, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen:
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(d=w[0], e=w[1])})
        hz = zahl(abs(h)) if h.denominator == 1 else f'{zahl(abs(h))}'
        hq = zahl(h * h)
        weg = [f'f(x) = {term}', f'= x² {summe([(b, "x")]).replace("−", "− ") if b < 0 else "+ " + summe([(b, "x")])} + ({zahl(h)})² − ({zahl(h)})² {"+" if c >= 0 else "−"} {zahl(abs(c))}',
               f'= ({summe([(1, "x"), (h, "")])})² {"+" if e > 0 else "−"} {zahl(abs(e))}']
        hw = {'b': zahl(b), 'h': zahl(h), 'hq': hq, 'b_glied': (f'+ {zahl(b)}x' if b > 0 else f'− {zahl(-b)}x').replace('1x', 'x') if abs(b) == 1 else (f'+ {zahl(b)}x' if b > 0 else f'− {zahl(-b)}x')}
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'FELDMASKE', feldmaske(schab), loes, fb,
                       [x.format(**hw) for x in self.hinweis_vorlagen], weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+) in der', inst.frage).group(1))
        xs = sympy.solve(sympy.diff(f, X), X)[0]
        ys = f.subs(X, xs)
        return werte(d=-Fraction(int(sympy.Rational(xs).p), int(sympy.Rational(xs).q)),
                     e=Fraction(int(sympy.Rational(ys).p), int(sympy.Rational(ys).q)))


BAUFORM = NF2()
