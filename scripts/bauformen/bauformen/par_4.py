"""PAR-4 · Gleichung zu „um d nach rechts, um e nach oben“ (fkt_quadr_parabel, K3). Feldmaske.
S2 rechts und oben · S3 links oder unten · S4 dazu gestreckt oder gestaucht. Rollen Ü T."""

from __future__ import annotations

import random
import re
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte


class PAR4(Bauform):
    key = 'PAR-4'
    skill = 'fkt_quadr_parabel'
    kernidee = 'fkt_quadr_parabel:K3'
    format = 'feldmaske'
    rollen = ('uebung', 'transfer')
    stufen = {2: 'nach rechts und nach oben, je 1 bis 8', 3: 'nach links oder nach unten',
              4: 'zusätzlich mit dem Faktor 2, 3 oder 1/2 gestreckt bzw. gestaucht'}
    text = 'Die Normalparabel wird {wie}. Gib die Gleichung der neuen Parabel an.'
    fehlbild_steckbrief = [
        {'key': 'qf_verschiebung_vorzeichen', 'regel': '(x + d)² für „nach rechts“', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Nach rechts heißt: Die Klammer wird erst für ein positives x null. Also (x − d).'},
        {'key': 'qf_d_e_vertauscht', 'regel': 'd und e vertauscht', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Die Verschiebung nach rechts oder links steht in der Klammer, nach oben oder unten steht hinten.'},
        {'key': 'qf_streckfaktor_vergessen', 'regel': 'a vergessen', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Die Parabel ist auch gestreckt oder gestaucht. Diese Zahl steht vor der Klammer.'},
    ]
    hinweis_vorlagen = ['Die Scheitelpunktform ist f(x) = a(x − d)² + e.', 'Wo liegt der neue Scheitel?',
                        'Setz den Scheitel S(d | e) in die Scheitelpunktform ein.']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e = rng.randint(1, 8), rng.randint(1, 8)
            if stufe >= 3:
                d, e = rng.choice([-1, 1]) * d, rng.choice([-1, 1]) * e
                if d > 0 and e > 0:
                    continue
            if abs(d) != abs(e):
                return {'a': rng.choice(['2', '3', '1/2']) if stufe == 4 else '1', 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = Fraction(params['a']), params['d'], params['e']
        teile = [f'um {abs(d)} nach {"rechts" if d > 0 else "links"}', f'um {abs(e)} nach {"oben" if e > 0 else "unten"}']
        wie = ' und '.join(teile)
        if a != 1:
            wie = f'mit dem Faktor {zahl(a)} {"gestreckt" if a > 1 else "gestaucht"} und dann ' + wie + ' verschoben'
        else:
            wie += ' verschoben'
        mit_a = stufe == 4
        schab = fm('f(x) = ', *(['[a/]'] if mit_a else []), '(x ', '±d', ')² ', '±e')
        loes = werte(**({'a': a} if mit_a else {}), d=-d, e=e)
        regeln = {'qf_verschiebung_vorzeichen': (a, d, e), 'qf_d_e_vertauscht': (a, -e, d),
                  'qf_streckfaktor_vergessen': (1, -d, e)}
        fb, gesehen = [], {(a, -d, e)}
        for f in self.fehlbilder_fuer(stufe):
            w = regeln[f['key']]
            if w not in gesehen:
                gesehen.add(w)
                fb.append({'key': f['key'], **werte(**({'a': w[0]} if mit_a else {}), d=w[1], e=w[2])})
        vor = '' if a == 1 else zahl(a)
        weg = [f'Neuer Scheitel: S({zahl(d)} | {zahl(e)})',
               f'f(x) = {vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}']
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, self.text.format(wie=wie), 'FELDMASKE', feldmaske(schab), loes, fb,
                       list(self.hinweis_vorlagen), weg, [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        t = inst.frage
        md, me = re.search(r'um (\d+) nach (rechts|links)', t), re.search(r'um (\d+) nach (oben|unten)', t)
        d = int(md.group(1)) * (1 if md.group(2) == 'rechts' else -1)
        e = int(me.group(1)) * (1 if me.group(2) == 'oben' else -1)
        m = re.search(r'Faktor (\S+)', t)
        return werte(**({'a': Fraction(m.group(1))} if m else {}), d=-d, e=e)


BAUFORM = PAR4()
