"""SCH-3 · Hoch- oder Tiefpunkt, und wo? (fkt_quadr_scheitel, K1). Begründungsbausteine (zwei wählen).
S2 a = ±1 · S3 a = ±2 oder ±1/2. Rollen R T."""

from __future__ import annotations

import random
import re
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import bausteine_payload, scheitel_von


class SCH3(Bauform):
    key = 'SCH-3'
    skill = 'fkt_quadr_scheitel'
    kernidee = 'fkt_quadr_scheitel:K1'
    format = 'bausteine'
    rollen = ('recap', 'transfer')
    stufen = {2: 'f(x) = ±(x − d)² + e, Vorzeichen von a und e verschieden', 3: 'a ∈ {−2, −1/2, 1/2, 2}'}
    text = 'Hat f(x) = {term} einen Hochpunkt oder einen Tiefpunkt, und wo liegt er? Wähle zwei Bausteine.'
    fehlbild_steckbrief = [
        {'key': 'qf_oeffnung_aus_e', 'regel': 'Art aus dem Vorzeichen von e gelesen', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Ob Hoch- oder Tiefpunkt, entscheidet die Zahl vor der Klammer, nicht die Zahl hinten.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'S(−d | e)', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Für welches x wird die Klammer null? Das ist die x-Koordinate.'},
    ]
    hinweis_vorlagen = ['Schau auf die Zahl vor der Klammer: Ist die Parabel nach oben oder nach unten geöffnet?',
                        'Nach oben geöffnet hat einen Tiefpunkt, nach unten geöffnet einen Hochpunkt.',
                        'Den Punkt liest du aus der Scheitelpunktform ab: S(d | e).']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a = rng.choice(['1', '-1']) if stufe == 2 else rng.choice(['-2', '-1/2', '1/2', '2'])
            d, e = rng.randint(-6, 6), rng.randint(1, 9)
            e = e if Fraction(a) < 0 else -e  # Vorzeichen von e anders als a, damit das Fehlbild greift
            if d != 0 and abs(d) != abs(e):
                return {'a': a, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = Fraction(params['a']), params['d'], params['e']
        vor = '' if a == 1 else '−' if a == -1 else zahl(a)
        term = f'{vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}'
        art = 'Hochpunkt' if a < 0 else 'Tiefpunkt'
        andere = 'Tiefpunkt' if a < 0 else 'Hochpunkt'
        payload, ids = bausteine_payload(self.key, [('art', f'Es ist ein {art}.'), ('falsch_art', f'Es ist ein {andere}.'),
                                                    ('ort', f'Er liegt bei S({zahl(d)} | {zahl(e)}).'),
                                                    ('falsch_ort', f'Er liegt bei S({zahl(-d)} | {zahl(e)}).')], anzahl=2)
        loes = {'gewaehlt': sorted([ids['art'], ids['ort']])}
        fb = [{'key': 'qf_oeffnung_aus_e', 'gewaehlt': sorted([ids['falsch_art'], ids['ort']])},
              {'key': 'qf_verschiebung_vorzeichen', 'gewaehlt': sorted([ids['art'], ids['falsch_ort']])}]
        weg = [f'f(x) = {term}', f'a = {zahl(a)} ist {"negativ" if a < 0 else "positiv"}: nach {"unten" if a < 0 else "oben"} geöffnet, also ein {art}.',
               f'Der Scheitel ist S({zahl(d)} | {zahl(e)}).']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'BAUSTEINE', payload, loes, fb,
                       list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        term = re.search(r'f\(x\) = (.+) einen Hoch', inst.frage).group(1)
        from ..rechnen import X, ausdruck
        a = sympy.Poly(ausdruck(term), X).LC()
        sx, sy = scheitel_von(term)
        art = 'Hochpunkt' if a < 0 else 'Tiefpunkt'
        ids = [b['id'] for b in inst.payload['bausteine']
               if b['text'] == f'Es ist ein {art}.' or b['text'] == f'Er liegt bei S({zahl(sx)} | {zahl(sy)}).']
        return {'gewaehlt': sorted(ids)}


BAUFORM = SCH3()
