"""NP-3 · Fehler finden: durch x geteilt (gleichung_quadr_faktor, K2). Fehler finden. S3. Rollen T R."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import menge_text
from ..rechnen import zeilen_menge

WARUM = [
    {'id': 'a', 'text': 'Man darf nicht durch x teilen, x könnte 0 sein. So geht die Lösung x = 0 verloren.'},
    {'id': 'b', 'text': 'Die Zahl hätte mit umgekehrtem Vorzeichen auf die andere Seite gemusst.'},
    {'id': 'c', 'text': 'x² geteilt durch x ergibt nicht x.'},
]


class NP3(Bauform):
    key = 'NP-3'
    skill = 'gleichung_quadr_faktor'
    kernidee = 'gleichung_quadr_faktor:K2'
    format = 'fehler_finden'
    rollen = ('transfer', 'recap')
    stufen = {3: 'a·x² = b·x oder a·x² + b·x = 0; im Lösungsweg wird durch x geteilt'}
    text = '{name} hat {gleichung} gelöst. In welcher Zeile steckt der Fehler, und warum?'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Prüf jede Zeile: Hat sie noch dieselben Lösungen wie die Zeile davor?',
                        'Setz x = 0 in die erste Zeile ein. Was fällt dir auf?',
                        'Achte auf die Zeile, in der aus x² plötzlich x wird.']
    zeit_sek = 120

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        a, b = rng.randint(1, 4), rng.choice([-1, 1]) * rng.randint(2, 12)
        # Der Name haengt an den Zahlen, damit dieselbe Aufgabe nicht mit anderem Namen als neue gilt (Pruefung 7).
        return {'a': a, 'b': b, 'form': rng.choice(['rechts', 'null']),
                'name': ['Mia', 'Ben', 'Lea', 'Tom', 'Emma', 'Noah'][(a * 7 + b) % 6]}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b = params['a'], params['b']
        x2 = Fraction(b, a)
        if params['form'] == 'rechts':
            gl = f'{summe([(a, "x²")])} = {summe([(b, "x")])}'
            zeilen = [gl, f'{summe([(a, "x")])} = {zahl(b)}'] + ([f'x = {zahl(x2)}'] if a != 1 else []) + \
                     [f'L = {menge_text([x2])}']
            fehler = 2
        else:
            gl = f'{summe([(a, "x²"), (-b, "x")])} = 0'
            zeilen = [gl, f'{summe([(a, "x²")])} = {summe([(b, "x")])}', f'{summe([(a, "x")])} = {zahl(b)}',
                      f'L = {menge_text([x2])}']
            fehler = 3
        frage = f'{params["name"]} hat {gl} gelöst. In welcher Zeile steckt der Fehler, und warum?'
        # Begründungen gemischt (Zweitprüfung A6 G, Befund 4): sonst ist die richtige immer die erste.
        texte = [w['text'] for w in WARUM]
        random.Random(f'np3-{a}-{b}-{params["form"]}').shuffle(texte)
        warum = [{'id': 'abc'[i], 'text': t} for i, t in enumerate(texte)]
        richtig_id = warum[texte.index(WARUM[0]['text'])]['id']
        payload = {'format': 'fehler_finden', 'zeilen': [{'nr': i + 1, 'text': z} for i, z in enumerate(zeilen)],
                   'warum': warum}
        richtig = sorted([Fraction(0), x2])
        weg = [f'Zeile {fehler}: {zeilen[fehler - 1]} — hier wurde durch x geteilt.',
               'Dabei geht die Lösung x = 0 verloren.', f'Richtig: {summe([(a, "x²"), (-b, "x")])} = 0',
               f'x · ({summe([(a, "x"), (-b, "")])}) = 0', f'L = {menge_text(richtig)}']
        return Instanz(self.key, rolle, stufe, params, frage, 'FEHLER_FINDEN', payload, {'zeile': fehler, 'warum': richtig_id}, [],
                       list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Konzept §5: jede Zeile gegen die vorige; genau eine Zeile ist nicht gleichwertig."""
        mengen = [zeilen_menge(z['text']) for z in inst.payload['zeilen']]
        brueche = [i + 1 for i in range(1, len(mengen)) if mengen[i] != mengen[i - 1]]
        if len(brueche) != 1:
            raise ValueError(f'nicht genau eine falsche Zeile: {brueche}')
        return {'zeile': brueche[0], 'warum': inst.loesung['warum']}


BAUFORM = NP3()
