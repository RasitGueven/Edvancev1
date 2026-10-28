"""NF-6 · Scheitelpunkt aus der Normalform (fkt_quadr_normalform, K2). Feldmaske Punkt S([x] | [y]).
S3 f(x) = x² + bx + c, b gerade · S4 a ∈ {−1, 2}. Rollen Ü G."""

from __future__ import annotations

import random
import re

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte
from ..rechnen import X, ausdruck


class NF6(Bauform):
    key = 'NF-6'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K2'
    format = 'feldmaske'
    rollen = ('uebung', 'generalprobe')
    stufen = {3: 'f(x) = x² + bx + c, b gerade, Scheitel ganzzahlig', 4: 'f(x) = a·x² + bx + c mit a ∈ {−1, 2}'}
    text = 'Bestimme den Scheitelpunkt von f(x) = {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_ergaenzung_nicht_abgezogen', 'regel': 'y = c', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Bei der Ergänzung ziehst du die Zahl wieder ab. Prüf die y-Koordinate mit f(x) am Scheitel.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'x mit falschem Vorzeichen', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Aus (x + 3)² liest du x = −3 ab. Für welches x wird die Klammer null?'},
        {'key': 'qf_ergaenzung_b_statt_halb', 'regel': 'x = −b', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'In die Klammer kommt die Hälfte der Zahl vor x.'},
    ]
    hinweis_vorlagen = ['Bring f(x) zuerst in die Scheitelpunktform.', 'Ergänze quadratisch mit der Hälfte der Zahl vor x.',
                        'Aus f(x) = a(x − d)² + e liest du S(d | e) ab.']
    zeit_sek = 150
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e = rng.randint(-8, 8), rng.randint(-15, 15)
            if d != 0 and e != 0 and abs(d) != abs(e):
                return {'a': 1 if stufe == 3 else rng.choice([-1, 2]), 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        b, c = -2 * a * d, a * d * d + e
        term = summe([(a, 'x²'), (b, 'x'), (c, '')])
        schab = fm('S(', '±x', ' | ', '±y', ')')
        loes = werte(x=d, y=e)
        regeln = {'qf_ergaenzung_nicht_abgezogen': (d, c), 'qf_verschiebung_vorzeichen': (-d, e),
                  'qf_ergaenzung_b_statt_halb': (-b // a, e)}
        fb, gesehen = [], {(d, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen:
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(x=w[0], y=w[1])})
        vor = '' if a == 1 else ('−' if a == -1 else zahl(a))
        weg = [f'f(x) = {term}', f'= {vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}',
               f'S({zahl(d)} | {zahl(e)})']
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'FELDMASKE', feldmaske(schab), loes, fb,
                       list(self.hinweis_vorlagen), weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(re.search(r'f\(x\) = (.+)\.$', inst.frage).group(1))
        xs = sympy.solve(sympy.diff(f, X), X)[0]
        return werte(x=int(xs), y=int(f.subs(X, xs)))


BAUFORM = NF6()
