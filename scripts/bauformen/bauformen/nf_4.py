"""NF-4 · Schritte der quadratischen Ergänzung ordnen (fkt_quadr_normalform, K2). Schritte ordnen. S2–S3. Rollen Ü R."""

from __future__ import annotations

import random
import re

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import scheitel_von
from ..rechnen import X, ausdruck


class NF4(Bauform):
    key = 'NF-4'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K2'
    format = 'schritte_ordnen'
    rollen = ('uebung', 'recap')
    stufen = {2: 'f(x) = x² + bx + c, b gerade, vier Schritte bis zum Scheitel', 3: 'wie S2, e negativ'}
    text = 'Bring die Schritte der quadratischen Ergänzung für f(x) = {term} in die richtige Reihenfolge.'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Was ist der erste Schritt der quadratischen Ergänzung?',
                        'Der erste Schritt sieht noch fast aus wie die Aufgabe.',
                        'Am Ende liest man den Scheitel ab.']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            h, e = rng.choice([-1, 1]) * rng.randint(1, 7), rng.randint(1, 15) * (1 if stufe == 2 else -1)
            if abs(h) != abs(e):
                return {'h': h, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        h, e = params['h'], params['e']
        b, c = 2 * h, h * h + e
        term = summe([(1, 'x²'), (b, 'x'), (c, '')])
        q = f'({summe([(1, "x"), (h, "")])})²'
        schritte = [f'f(x) = {summe([(1, "x²"), (b, "x")])} + {h * h} − {h * h} {"+" if c >= 0 else "−"} {abs(c)}',
                    f'f(x) = {q} − {h * h} {"+" if c >= 0 else "−"} {abs(c)}',
                    f'f(x) = {q} {"+" if e > 0 else "−"} {abs(e)}', f'S({zahl(-h)} | {zahl(e)})']
        rng = random.Random(f'nf4-{h}-{e}')
        reihe = list(range(4))
        while reihe == list(range(4)):
            rng.shuffle(reihe)
        ids = 'abcd'
        payload = {'format': 'schritte_ordnen', 'schritte': [{'id': ids[k], 'text': schritte[i]} for k, i in enumerate(reihe)]}
        richtig = [ids[reihe.index(i)] for i in range(4)]
        weg = [f'{n + 1}. {s}' for n, s in enumerate(schritte)]
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'SCHRITTE_ORDNEN', payload,
                       {'reihenfolgen': [richtig]}, [], list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Jeder Term-Schritt ist gleich f(x); geordnet: ergänzt (vier Zahlen), Quadrat mit zwei Zahlen dahinter,
        Quadrat mit einer Zahl, Scheitel; der Scheitel passt zu f."""
        f = ausdruck(re.search(r'f\(x\) = (.+) in die', inst.frage).group(1))
        def stelle(t: str) -> int:
            if t.startswith('S('):
                return 3
            rest = t.split(')²')[1] if ')²' in t else ''
            return 0 if ')²' not in t else 1 if len(re.findall(r'\d+', rest)) == 2 else 2
        nach = {s['id']: s['text'] for s in inst.payload['schritte']}
        for t in nach.values():
            if not t.startswith('S(') and sympy.simplify(ausdruck(t.split('= ', 1)[1]) - f) != 0:
                raise ValueError(f'Schritt nicht gleichwertig: {t}')
        sx, sy = scheitel_von(str(f).replace('**', '^'))
        if f'S({zahl(sx)} | {zahl(sy)})' not in nach.values():
            raise ValueError('Scheitel passt nicht')
        return {'reihenfolgen': [sorted(nach, key=lambda i: stelle(nach[i]))]}


BAUFORM = NF4()
