"""EX-2 · Wurf h(t) gegeben: größte Höhe, und wann (fkt_quadr_extrem, K1). Mehrteiler mit Kontext.
S3 h(t) = −5t² + bt + c, Scheitel ganzzahlig · S4 Scheitel bei halben Sekunden. Rollen T G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..formen import dezimal_oder_bruch, scheitel_aus_kontext
from ..klassisch import teil


class EX2(Bauform):
    key = 'EX-2'
    skill = 'fkt_quadr_extrem'
    kernidee = 'fkt_quadr_extrem:K1'
    format = 'mehrteiler'
    rollen = ('transfer', 'generalprobe')
    kann_entfallen = True
    stufen = {3: 'h(t) = −5t² + bt + c mit b = 10, 20, 30', 4: 'b = 5, 15, 25, 35: der Scheitel liegt bei einer halben Sekunde'}
    text = '{kontext}'
    fehlbild_steckbrief = [
        {'key': 'qf_stelle_statt_wert', 'regel': 'in Teil 2 t statt h', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Gefragt ist die Höhe, also der Wert h am Scheitel, nicht die Zeit.'},
    ]
    hinweis_vorlagen = ['Die größte Höhe liegt am Scheitel der Parabel.', 'Bring h(t) in die Scheitelpunktform oder nutze die Symmetrie.',
                        'Die Zeit ist die erste Koordinate des Scheitels, die Höhe die zweite.']
    zeit_sek = 240
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'b': rng.choice([10, 20, 30] if stufe == 3 else [5, 15, 25, 35]), 'c': rng.randint(1, 20)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        b, c = params['b'], params['c']
        t = Fraction(b, 10)
        h = c + Fraction(b * b, 20)
        term = summe([(-5, 't²'), (b, 't'), (c, '')])
        kontext = (f'Ein Ball wird von einem Turm nach oben geworfen. Seine Höhe ist h(t) = {term} (t in Sekunden, h in Metern). '
                   'Wann ist der Ball am höchsten, und wie hoch ist er dann?')
        teile = [teil(1, 'Zeitpunkt in Sekunden'), teil(2, 'größte Höhe in Metern')]
        loes = {'teile': {'1': dezimal_oder_bruch(t), '2': dezimal_oder_bruch(h)}}
        fb = [{'key': 'qf_stelle_statt_wert', 'teil': 2, 'wert': zahl_antwort(t)}]
        weg = [f'h(t) = {term}', f'= −5(t² − {zahl(Fraction(b, 5))}t) + {c}',
               f'= −5(t − {zahl(t)})² + {zahl(h)}', f'Scheitel S({zahl(t)} | {zahl(h)}): nach {zahl(t)} s, {zahl(h)} m hoch']
        return Instanz(self.key, rolle, stufe, params, kontext, 'MULTI_PART', None, loes, fb, list(self.hinweis_vorlagen),
                       weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        sx, sy, _ = scheitel_aus_kontext(inst.frage, 'h', 't')
        return {'teile': {'1': [zahl_antwort(sx)], '2': [zahl_antwort(sy)]}}


BAUFORM = EX2()
