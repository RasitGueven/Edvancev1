"""SCH-4 · Fehler finden beim Ablesen des Scheitels (fkt_quadr_scheitel, K1). Fehler finden. S3. Rollen T R."""

from __future__ import annotations

import random
import re

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import scheitel_von

WARUM = [{'id': 'a', 'text': 'Die x-Koordinate hat das umgekehrte Vorzeichen der Zahl in der Klammer.'},
         {'id': 'b', 'text': 'Die y-Koordinate ist die Zahl hinten, mit ihrem Vorzeichen.'},
         {'id': 'c', 'text': 'Die Zahl vor der Klammer gehört nicht zum Scheitel.'}]
NAMEN = ['Mia', 'Ben', 'Lea', 'Tom', 'Emma', 'Noah', 'Ella', 'Finn']


class SCH4(Bauform):
    key = 'SCH-4'
    skill = 'fkt_quadr_scheitel'
    kernidee = 'fkt_quadr_scheitel:K1'
    format = 'fehler_finden'
    rollen = ('transfer', 'recap')
    stufen = {3: 'f(x) = a(x − d)² + e; ein Fehler beim Ablesen (Vorzeichen von d, Vorzeichen von e oder a als Koordinate)'}
    text = '{name} liest den Scheitel von f(x) = {term} ab. In welcher Zeile steckt der Fehler, und warum?'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Prüf jede Zeile einzeln.', 'Für welches x wird die Klammer null?',
                        'Welche Zahl steht hinten, und welches Vorzeichen hat sie?']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            d, e, a = rng.randint(-7, 7), rng.randint(-9, 9), rng.choice([-3, -2, 2, 3, 1])
            art = rng.choice(['d', 'e'] + (['a'] if a != 1 else []))
            if d and e and abs(d) != abs(e) and abs(a) != abs(d):
                return {'a': a, 'd': d, 'e': e, 'art': art, 'name': NAMEN[(d * 3 + e * 7 + a) % 8]}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e, art = params['a'], params['d'], params['e'], params['art']
        vor = '' if a == 1 else zahl(a)
        term = f'{vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}'
        x_ab = -d if art == 'd' else (a if art == 'a' else d)
        y_ab = -e if art == 'e' else e
        zeilen = [f'Die Klammer wird null für x = {zahl(x_ab)}.' if art != 'a' else f'Die x-Koordinate ist die Zahl vorne: x = {zahl(a)}.',
                  f'Die Zahl hinten ist {zahl(y_ab)}.', f'S({zahl(x_ab)} | {zahl(y_ab)})']
        fehler = 2 if art == 'e' else 1
        frage = self.text.format(name=params['name'], term=term)
        payload = {'format': 'fehler_finden', 'zeilen': [{'nr': i + 1, 'text': z} for i, z in enumerate(zeilen)], 'warum': WARUM}
        weg = [f'Zeile {fehler}: {zeilen[fehler - 1]}', WARUM[{'d': 0, 'e': 1, 'a': 2}[art]]['text'],
               f'Richtig: S({zahl(d)} | {zahl(e)})']
        return Instanz(self.key, rolle, stufe, params, frage, 'FEHLER_FINDEN', payload,
                       {'zeile': fehler, 'warum': {'d': 'a', 'e': 'b', 'a': 'c'}[art]}, [], list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Die erste Zeile, deren Zahl nicht zum nachgerechneten Scheitel passt, ist die falsche."""
        term = re.search(r'f\(x\) = (.+) ab\.', inst.frage).group(1)
        sx, sy = scheitel_von(term)
        z1, z2, _ = (z['text'] for z in inst.payload['zeilen'])
        x1 = re.search(r'x = (\S+)\.', z1).group(1)
        y2 = re.search(r'ist (\S+)\.', z2).group(1)
        if x1 != zahl(sx):
            return {'zeile': 1, 'warum': inst.loesung['warum']}
        if y2 != zahl(sy):
            return {'zeile': 2, 'warum': inst.loesung['warum']}
        raise ValueError('keine falsche Zeile')


BAUFORM = SCH4()
