"""EX-3 · Gewinn G(x) maximal (fkt_quadr_extrem, K1). Mehrteiler mit Kontext. S4. Rolle T."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..formen import scheitel_aus_kontext
from ..klassisch import teil


class EX3(Bauform):
    key = 'EX-3'
    skill = 'fkt_quadr_extrem'
    kernidee = 'fkt_quadr_extrem:K1'
    format = 'mehrteiler'
    rollen = ('transfer',)
    kann_entfallen = True
    stufen = {4: 'G(x) = −a·x² + bx − c mit a ∈ {1, 2}, ganzzahliger Scheitel'}
    text = '{kontext}'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Der größte Gewinn liegt am Scheitel.', 'Bring G(x) in die Scheitelpunktform.',
                        'Die Stückzahl ist die erste Koordinate des Scheitels, der Gewinn die zweite.']
    zeit_sek = 240

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'a': rng.choice([1, 2]), 'd': rng.randint(10, 60), 'e': rng.randint(100, 900)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        term = summe([(-a, 'x²'), (2 * a * d, 'x'), (e - a * d * d, '')])
        kontext = (f'Ein Café verkauft x Stücke Kuchen am Tag. Der Gewinn ist G(x) = {term} (in Euro). '
                   'Bei welcher Stückzahl ist der Gewinn am größten, und wie groß ist er?')
        teile = [teil(1, 'Stückzahl'), teil(2, 'größter Gewinn in Euro')]
        loes = {'teile': {'1': [zahl_antwort(d)], '2': [zahl_antwort(e)]}}
        weg = [f'G(x) = {term}', f'= {"−" if a == 1 else "−2"}(x − {d})² + {e}', f'Scheitel S({d} | {e})',
               f'Bei {d} Stück ist der Gewinn am größten: {e} Euro.']
        return Instanz(self.key, rolle, stufe, params, kontext, 'MULTI_PART', None, loes, [], list(self.hinweis_vorlagen),
                       weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        sx, sy, _ = scheitel_aus_kontext(inst.frage, 'G', 'x')
        return {'teile': {'1': [zahl_antwort(sx)], '2': [zahl_antwort(sy)]}}


BAUFORM = EX3()
