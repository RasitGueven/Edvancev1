"""NF-5 · Fehler finden in der quadratischen Ergänzung (fkt_quadr_normalform, K2/K3). Fehler finden.
S3 a = 1 · S4 a ∈ {2, 3}. Rolle T."""

from __future__ import annotations

import random
import re

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..rechnen import X, ausdruck

WARUM = [{'id': 'a', 'text': 'Die Ergänzung wurde nur dazugegeben und nicht wieder abgezogen.'},
         {'id': 'b', 'text': 'In die Klammer gehört die Hälfte der Zahl vor x.'},
         {'id': 'c', 'text': 'Was in der Klammer abgezogen wird, zählt außen mal a.'}]
NAMEN = ['Mia', 'Ben', 'Lea', 'Tom', 'Emma', 'Noah', 'Ella', 'Finn']


class NF5(Bauform):
    key = 'NF-5'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K2'
    format = 'fehler_finden'
    rollen = ('transfer',)
    stufen = {3: 'f(x) = x² + bx + c; Fehler: Ergänzung nur addiert', 4: 'f(x) = a·x² + bx + c mit a ∈ {2, 3}; Fehler: Ergänzung nicht mit a multipliziert'}
    text = '{name} bringt f(x) = {term} in die Scheitelpunktform. In welcher Zeile steckt der Fehler, und warum?'
    fehlbild_steckbrief = [
        {'key': 'qf_ergaenzung_nicht_abgezogen', 'regel': 'richtige Zeile, falsche Begründung (a = 1)', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Die Zeile stimmt. Schau, was mit der Ergänzung passiert: Wird sie auch wieder abgezogen?'},
        {'key': 'qf_ergaenzung_ohne_a', 'regel': 'richtige Zeile, falsche Begründung (a ≠ 1)', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Die Zeile stimmt. Schau, mit welcher Zahl die abgezogene Ergänzung außen malgenommen wird.'},
    ]
    hinweis_vorlagen = ['Prüf jede Zeile: Ist der Term noch derselbe wie in der Zeile davor?',
                        'Rechne zur Probe eine Zeile wieder aus.', 'Achte darauf, was dazugegeben und was abgezogen wird.']
    zeit_sek = 150

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            h, e = rng.choice([-1, 1]) * rng.randint(1, 6), rng.randint(-12, 12)
            if e and abs(h) != abs(e):
                return {'a': 1 if stufe == 3 else rng.choice([2, 3]), 'h': h, 'e': e,
                        'name': NAMEN[(h * 5 + e * 3) % 8]}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, h, e = params['a'], params['h'], params['e']
        b, c = 2 * a * h, a * h * h + e
        term = summe([(a, 'x²'), (b, 'x'), (c, '')])
        q = f'({summe([(1, "x"), (h, "")])})²'
        cz = f'{"+" if c >= 0 else "−"} {abs(c)}'
        if a == 1:
            zeilen = [f'f(x) = {term}', f'= {summe([(1, "x²"), (b, "x")])} + {h * h} {cz}', f'= {q} {cz}', f'S({zahl(-h)} | {zahl(c)})']
            fehler, warum = 2, 'a'
        else:
            zeilen = [f'f(x) = {term}', f'= {a}({summe([(1, "x²"), (2 * h, "x")])}) {cz}',
                      f'= {a}({summe([(1, "x²"), (2 * h, "x")])} + {h * h} − {h * h}) {cz}',
                      f'= {a}{q} − {h * h} {cz}']
            fehler, warum = 4, 'c'
        payload = {'format': 'fehler_finden', 'zeilen': [{'nr': i + 1, 'text': z} for i, z in enumerate(zeilen)], 'warum': WARUM}
        weg = [f'Zeile {fehler}: {zeilen[fehler - 1]}', next(w['text'] for w in WARUM if w['id'] == warum),
               f'Richtig: f(x) = {"" if a == 1 else a}{q} {"+" if e > 0 else "−"} {abs(e)}']
        frage = self.text.format(name=params['name'], term=term)
        fb = [{'key': 'qf_ergaenzung_nicht_abgezogen' if a == 1 else 'qf_ergaenzung_ohne_a', 'zeile': fehler}]
        return Instanz(self.key, rolle, stufe, params, frage, 'FEHLER_FINDEN', payload, {'zeile': fehler, 'warum': warum},
                       fb, list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Jede Term-Zeile gegen die vorige (gleicher Term?); die Scheitel-Zeile gegen den Scheitel davor."""
        terme = []
        for z in inst.payload['zeilen']:
            t = z['text']
            if t.startswith('S('):
                m = re.fullmatch(r'S\((\S+) \| (\S+)\)', t)
                f = terme[-1]
                xs = sympy.solve(sympy.diff(f, X), X)[0]
                ok = (sympy.Rational(m.group(1).replace('−', '-')), sympy.Rational(m.group(2).replace('−', '-'))) == (xs, f.subs(X, xs))
                terme.append(f if ok else None)
                continue
            terme.append(ausdruck(t.split('= ', 1)[1]))
        brueche = [i + 1 for i in range(1, len(terme))
                   if terme[i] is None or terme[i - 1] is None or sympy.simplify(terme[i] - terme[i - 1]) != 0]
        if not brueche:
            raise ValueError('keine falsche Zeile')
        return {'zeile': brueche[0], 'warum': inst.loesung['warum']}


BAUFORM = NF5()
