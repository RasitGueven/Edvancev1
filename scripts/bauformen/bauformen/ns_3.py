"""NS-3 · Nullstellen aus der faktorisierten Form (fkt_quadr_nullstellen, K1). Lösungsmenge.
S1 f(x) = (x − p)(x − q) · S2 f(x) = a(x − p)(x − q) oder x(x − p). Rollen W Ü B H."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload, nullstellen_aus_text


class NS3(Bauform):
    key = 'NS-3'
    skill = 'fkt_quadr_nullstellen'
    kernidee = 'fkt_quadr_nullstellen:K1'
    format = 'loesungsmenge'
    rollen = ('warmup', 'uebung', 'beispiel', 'home')
    stufen = {1: 'f(x) = (x − p)(x − q), p und q von −9 bis 9', 2: 'f(x) = a(x − p)(x − q) mit a ∈ {−2, 2, 3} oder f(x) = x(x − p)'}
    text = 'Bestimme die Nullstellen von f(x) = {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nullprodukt_vorzeichen', 'regel': '{−p; −q}', 'gilt_fuer_stufen': [1, 2],
         'rueckmeldung': 'Für welches x wird die Klammer null? Aus (x − 3) wird x = 3.'},
        {'key': 'qf_null_vergessen', 'regel': 'bei x(x − p) nur p', 'gilt_fuer_stufen': [2],
         'rueckmeldung': 'Auch der Faktor x allein kann null werden.'},
    ]
    hinweis_vorlagen = ['Nullstellen heißt: f(x) = 0.', 'Ein Produkt ist 0, wenn ein Faktor 0 ist.',
                        'Setz jeden Faktor mit x einzeln gleich null.']
    warum = {'bei_schritt': 1, 'frage': 'Warum spielt die Zahl vor den Klammern keine Rolle?',
             'bausteine': [{'id': 'a', 'text': 'Eine Zahl ungleich 0 macht das Produkt nicht zu 0. Nur die Klammern können 0 werden.'},
                           {'id': 'b', 'text': 'Weil man die Zahl einfach weglassen darf.'},
                           {'id': 'c', 'text': 'Weil die Zahl immer 1 ist.'}],
             'richtig': 'a'}
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p, q = rng.randint(-9, 9), rng.randint(-9, 9)
            form = 'x' if stufe == 2 and rng.random() < 0.4 else 'pq'
            if form == 'x':
                q = 0
            if p != q and p != 0 and (form == 'x' or (q != 0 and p != -q)):
                return {'a': 1 if stufe == 1 or form == 'x' else rng.choice([-2, 2, 3]), 'p': p, 'q': q, 'form': form}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q, form = params['a'], params['p'], params['q'], params['form']
        vor = '' if a == 1 else zahl(a)
        k1 = f'({summe([(1, "x"), (-p, "")])})'
        term = f'x{k1}' if form == 'x' else f'{vor}{k1}({summe([(1, "x"), (-q, "")])})'
        richtig = sorted({p, q})
        regeln = {'qf_nullprodukt_vorzeichen': sorted({-p, -q}), 'qf_null_vergessen': [p] if form == 'x' else None}
        weg = ['f(x) = 0', f'{term} = 0', f'x = {zahl(richtig[0])} oder x = {zahl(richtig[1])}', f'L = {menge_text(richtig)}']
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln), list(self.hinweis_vorlagen), weg,
                       [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(nullstellen_aus_text(inst.frage))


BAUFORM = NS3()
