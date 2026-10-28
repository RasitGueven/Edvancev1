"""NS-5 · Wie viele Nullstellen? Aus Scheitel und Öffnung begründen (fkt_quadr_nullstellen, K2). Begründungsbausteine.
S3. Rollen R T."""

from __future__ import annotations

import random
import re

import sympy

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import bausteine_payload, nullstellen_aus_text


class NS5(Bauform):
    key = 'NS-5'
    skill = 'fkt_quadr_nullstellen'
    kernidee = 'fkt_quadr_nullstellen:K2'
    format = 'bausteine'
    rollen = ('recap', 'transfer')
    stufen = {3: 'f(x) = a(x − d)² + e mit e ≠ 0; Öffnung und Lage des Scheitels entscheiden'}
    text = 'Wie viele Nullstellen hat f(x) = {term}? Wähle die richtige Begründung, ohne zu rechnen.'
    fehlbild_steckbrief = [
        {'key': 'qf_scheitel_statt_nullstelle', 'regel': '„Der Scheitel ist die Nullstelle“', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Eine Nullstelle liegt auf der x-Achse. Liegt der Scheitel dort?'},
        {'key': 'qf_oeffnung_aus_e', 'regel': 'Öffnung aus e gelesen', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Die Öffnung hängt von der Zahl vor der Klammer ab, nicht von der Zahl hinten.'},
    ]
    hinweis_vorlagen = ['Wo liegt der Scheitel: über oder unter der x-Achse?', 'Ist die Parabel nach oben oder nach unten geöffnet?',
                        'Kann die Parabel von ihrem Scheitel aus die x-Achse erreichen?']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a, d, e = rng.choice([-2, -1, 1, 2]), rng.randint(-5, 5), rng.choice([-1, 1]) * rng.randint(1, 8)
            if d and abs(d) != abs(e):
                return {'a': a, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        vor = '' if a == 1 else '−' if a == -1 else zahl(a)
        term = f'{vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}'
        lage = 'über' if e > 0 else 'unter'
        auf = 'oben' if a > 0 else 'unten'
        keine = (a > 0) == (e > 0)
        if keine:
            richtig = f'Keine: Der Scheitel liegt {lage} der x-Achse, und die Parabel ist nach {auf} geöffnet.'
            falsch_e = f'Zwei: Der Scheitel liegt {lage} der x-Achse, und die Parabel ist nach {"unten" if e > 0 else "oben"} geöffnet.'
        else:
            richtig = f'Zwei: Der Scheitel liegt {lage} der x-Achse, und die Parabel ist nach {auf} geöffnet.'
            falsch_e = f'Keine: Der Scheitel liegt {lage} der x-Achse, und die Parabel ist nach {"oben" if e > 0 else "unten"} geöffnet.'
        payload, ids = bausteine_payload(self.key, [('r', richtig), ('qf_oeffnung_aus_e', falsch_e),
                                                    ('qf_scheitel_statt_nullstelle', f'Eine: Der Scheitel S({zahl(d)} | {zahl(e)}) ist die Nullstelle.'),
                                                    ('n', 'Zwei: Jede Parabel schneidet die x-Achse zweimal.')])
        fb = [{'key': k, 'gewaehlt': [ids[k]]} for k in ('qf_oeffnung_aus_e', 'qf_scheitel_statt_nullstelle')]
        weg = [f'Scheitel S({zahl(d)} | {zahl(e)}) liegt {lage} der x-Achse.', f'a = {zahl(a)}: nach {auf} geöffnet.',
               'Die Parabel entfernt sich von der x-Achse: keine Nullstelle.' if keine else
               'Die Parabel läuft auf die x-Achse zu: zwei Nullstellen.']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'BAUSTEINE', payload,
                       {'gewaehlt': [ids['r']]}, fb, list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        try:
            n = len(nullstellen_aus_text(inst.frage.split('?')[0].replace('Wie viele Nullstellen hat ', '') + '.'))
        except ValueError:
            n = 2  # irrationale Nullstellen: es sind zwei
        wort = {0: 'Keine', 2: 'Zwei'}[n]
        passend = [b['id'] for b in inst.payload['bausteine'] if b['text'].startswith(wort + ': Der Scheitel liegt')]
        if len(passend) != 1:
            raise ValueError('nicht genau ein passender Baustein')
        return {'gewaehlt': passend}


BAUFORM = NS5()
