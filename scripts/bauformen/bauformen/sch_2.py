"""SCH-2 · Gleichung aus dem Graphen (fkt_quadr_scheitel, K2). Feldmaske mit Figur.
S2 a = 1 · S3 a = −1 · S4 a = 2 oder 1/2. Rollen Ü T G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import _zahl_json, andere_eingabe, feldmaske, fenster_fuer, fm, werte


class SCH2(Bauform):
    key = 'SCH-2'
    skill = 'fkt_quadr_scheitel'
    kernidee = 'fkt_quadr_scheitel:K2'
    format = 'feldmaske'
    rollen = ('uebung', 'transfer', 'generalprobe')
    stufen = {2: 'a = 1, Scheitel ganzzahlig von −4 bis 4', 3: 'a = −1', 4: 'a = 2 oder a = 1/2'}
    text = 'Die Abbildung zeigt eine Parabel. Gib ihre Gleichung in der Scheitelpunktform an.'
    figur = {'generator': 'parabel', 'params': 'a, d, e wie die Lösung; Gitter; Scheitel markiert'}
    fehlbild_steckbrief = [
        {'key': 'qf_verschiebung_vorzeichen', 'regel': 'Vorzeichen von d in der Klammer falsch', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Liegt der Scheitel rechts vom Ursprung, steht in der Klammer ein Minus: (x − d).'},
        {'key': 'qf_streckfaktor_vergessen', 'regel': 'a weggelassen', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Die Parabel ist nicht die verschobene Normalparabel. Prüf Öffnung und Form: Welche Zahl steht vor der Klammer?'},
        {'key': 'qf_d_e_vertauscht', 'regel': 'd und e vertauscht', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Die x-Koordinate des Scheitels gehört in die Klammer, die y-Koordinate nach hinten.'},
    ]
    hinweis_vorlagen = ['Lies zuerst den Scheitel ab.', 'Setz den Scheitel S(d | e) in f(x) = a(x − d)² + e ein.',
                        'Für a: Geh vom Scheitel eins nach rechts. Um wie viel geht es nach oben oder unten?']
    zeit_sek = 120
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e = rng.randint(-4, 4), rng.randint(-4, 4)
            if d and e and abs(d) != abs(e):
                return {'a': {2: '1', 3: '-1', 4: rng.choice(['2', '1/2'])}[stufe], 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = Fraction(params['a']), params['d'], params['e']
        mit_a = stufe >= 3
        schab = fm('f(x) = ', *(['[a/]'] if stufe == 4 else ['[a]'] if mit_a else []), '(x ', '±d', ')² ', '±e')
        loes = werte(**({'a': a} if mit_a else {}), d=-d, e=e)
        regeln = {'qf_verschiebung_vorzeichen': (a, d, e), 'qf_streckfaktor_vergessen': (1, -d, e),
                  'qf_d_e_vertauscht': (a, -e, d)}
        fb, gesehen = [], {(a, -d, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen:
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(**({'a': w[0]} if mit_a else {}), d=w[1], e=w[2])})
        fenster = fenster_fuer([(d, e), (d + 2, e + a * 4), (d - 2, e + a * 4)], 2)
        figur = {'generator': 'parabel', 'alt': 'Koordinatensystem mit Gitter und einer Parabel, ihr Scheitel ist markiert',
                 'params': {'a': _zahl_json(a), 'd': d, 'e': e, **fenster, 'gitter': True, 'scheitel': True}}
        vor = '' if a == 1 else '−' if a == -1 else zahl(a)
        weg = [f'Scheitel ablesen: S({zahl(d)} | {zahl(e)})',
               f'Vom Scheitel eins nach rechts: {"+" if a > 0 else "−"} {zahl(abs(a))}, also a = {zahl(a)}',
               f'f(x) = {vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}']
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text, 'FELDMASKE', feldmaske(schab), loes, fb,
                       list(self.hinweis_vorlagen), weg, [anders] if anders else [], figur=figur)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        p = inst.figur['params']
        a = Fraction(p['a']).limit_denominator(100)
        return werte(**({'a': a} if inst.stufe >= 3 else {}), d=-p['d'], e=p['e'])


BAUFORM = SCH2()
