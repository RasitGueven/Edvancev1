"""NF-1 · Scheitelpunktform in Normalform (fkt_quadr_normalform, K1). Feldmaske x² + [b]x + [c].
S1 (x − d)² + e mit d, e > 0 · S2 Vorzeichen gemischt · S3 a ≠ 1. Rollen W Ü H."""

from __future__ import annotations

import random
import re

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, poly_koeff, werte


class NF1(Bauform):
    key = 'NF-1'
    skill = 'fkt_quadr_normalform'
    kernidee = 'fkt_quadr_normalform:K1'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'f(x) = (x − d)² + e, d und e von 1 bis 9', 2: 'd und e mit beliebigem Vorzeichen',
              3: 'f(x) = a(x − d)² + e mit a ∈ {−2, −1, 2, 3}'}
    text = 'Schreib f(x) = {term} in der Normalform.'
    fehlbild_steckbrief = [
        {'key': 'qf_binom_mittelglied_fehlt', 'regel': 'x² + d² + e (2dx fehlt)', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Beim Quadrat einer Klammer gibt es ein mittleres Glied. Multipliziere die Klammer mit sich selbst.'},
        {'key': 'qf_binom_vorzeichen', 'regel': 'Vorzeichen des Glieds mit x falsch', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Prüf das Vorzeichen des Glieds mit x. Es hat dasselbe Vorzeichen wie die Zahl in der Klammer.'},
        {'key': 'qf_faktor_nicht_verteilt', 'regel': 'a nur mit x² multipliziert', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Die Zahl vor der Klammer gilt für jedes Glied der ausmultiplizierten Klammer.'},
    ]
    hinweis_vorlagen = ['Multipliziere zuerst das Quadrat aus: (x − d)² = x² − 2dx + d².',
                        'Danach {a_schritt}fasse die Zahlen zusammen.', 'Für die Klammer gilt: {klammer}² = {binom}.']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        d, e = rng.randint(1, 9), rng.randint(1, 9)
        if stufe >= 2:
            d, e = rng.choice([-1, 1]) * d, rng.choice([-1, 1]) * e
        return {'a': rng.choice([-2, -1, 2, 3]) if stufe == 3 else 1, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        klammer = f'({summe([(1, "x"), (-d, "")])})'
        vor = '' if a == 1 else ('−' if a == -1 else zahl(a))
        term = f'{vor}{klammer}² {"+" if e > 0 else "−"} {abs(e)}'
        A, B, C = a, -2 * a * d, a * d * d + e
        mit_a = {'a': A} if stufe == 3 else {}
        schab = fm(*(['[a]'] if stufe == 3 else []), 'x² ', '±b', 'x ', '±c')
        loes = werte(**mit_a, b=B, c=C)
        regeln = {'qf_binom_mittelglied_fehlt': (A, 0, a * d * d + e), 'qf_binom_vorzeichen': (A, -B, C),
                  'qf_faktor_nicht_verteilt': (A, -2 * d, d * d + e)}
        fb, gesehen = [], {(A, B, C)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen:
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(**({'a': w[0]} if stufe == 3 else {}), b=w[1], c=w[2])})
        binom = summe([(1, 'x²'), (-2 * d, 'x'), (d * d, '')])
        weg = [f'f(x) = {term}', f'= {vor}({binom}) {"+" if e > 0 else "−"} {abs(e)}' if a != 1 else
               f'= {binom} {"+" if e > 0 else "−"} {abs(e)}', f'= {summe([(A, "x²"), (B, "x"), (C, "")])}']
        hw = {'a_schritt': f'multiplizierst du jedes Glied mit {zahl(a)} und ' if a != 1 else '', 'klammer': klammer,
              'binom': binom}
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'FELDMASKE', feldmaske(schab), loes, fb,
                       [h.format(**hw) for h in self.hinweis_vorlagen], weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        A, B, C = poly_koeff(re.search(r'f\(x\) = (.+) in der', inst.frage).group(1))
        return werte(**({'a': A} if inst.stufe == 3 else {}), b=B, c=C)


BAUFORM = NF1()
