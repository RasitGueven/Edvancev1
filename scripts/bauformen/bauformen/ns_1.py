"""NS-1 · Nullstellen aus der Scheitelpunktform (fkt_quadr_nullstellen, K2). Lösungsmenge.
S2 a = 1, e < 0 · S3 a = −1, e > 0 · S4 a ∈ {−2, 2}, auch ohne Nullstelle. Rollen Ü H G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload, nullstellen_aus_text, wurzel


class NS1(Bauform):
    key = 'NS-1'
    skill = 'fkt_quadr_nullstellen'
    kernidee = 'fkt_quadr_nullstellen:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'home', 'generalprobe')
    stufen = {2: 'f(x) = (x − d)² + e mit e < 0, −e Quadratzahl', 3: 'f(x) = −(x − d)² + e mit e > 0, e Quadratzahl',
              4: 'f(x) = a(x − d)² + e mit a ∈ {−2, 2}, auch Parabeln ohne Nullstelle'}
    text = 'Bestimme die Nullstellen von f(x) = {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nur_positive_loesung', 'regel': 'nur d + √(−e/a)', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Die Klammer kann eine positive oder eine negative Zahl sein. Rechne beide Fälle.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': '−d ± √(−e/a)', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Prüf das Vorzeichen von d: Für welches x wird die Klammer null?'},
        {'key': 'qf_e_vorzeichen', 'regel': 'e ohne Vorzeichenwechsel auf die andere Seite', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Wenn du e auf die andere Seite bringst, wechselt sein Vorzeichen.'},
    ]
    hinweis_vorlagen = ['Nullstellen heißt: f(x) = 0.', 'Bring e auf die andere Seite{teilen}.',
                        'Zieh dann die Wurzel. Die Klammer kann positiv oder negativ sein.']
    zeit_sek = 120
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        d, w = rng.choice([-1, 1]) * rng.randint(1, 8), rng.randint(1, 6)
        if stufe == 2:
            return {'a': 1, 'd': d, 'e': -w * w}
        if stufe == 3:
            return {'a': -1, 'd': d, 'e': w * w}
        a = rng.choice([-2, 2])
        e = -a * w * w if rng.random() < 0.75 else a * w * w
        return {'a': a, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, d, e = params['a'], params['d'], params['e']
        vor = '' if a == 1 else '−' if a == -1 else zahl(a)
        term = f'{vor}({summe([(1, "x"), (-d, "")])})² {"+" if e > 0 else "−"} {abs(e)}'
        r = Fraction(-e, a)
        w = wurzel(r)
        richtig = [] if r < 0 else sorted({d + w, d - w})
        wf = wurzel(Fraction(e, a))
        regeln = {'qf_nur_positive_loesung': [d + w] if richtig else None,
                  'qf_verschiebung_vorzeichen': sorted({-d + w, -d - w}) if richtig else None,
                  'qf_e_vorzeichen': (sorted({d + wf, d - wf}) if wf is not None and Fraction(e, a) > 0 else [])}
        klammer = f'({summe([(1, "x"), (-d, "")])})'
        weg = [f'f(x) = 0', f'{vor}{klammer}² {"+" if e > 0 else "−"} {abs(e)} = 0',
               f'{klammer}² = {zahl(r)}']
        weg += ([f'{klammer[1:-1]} = {zahl(w)} oder {klammer[1:-1]} = −{zahl(w)}', f'L = {menge_text(richtig)}'] if richtig
                else ['Ein Quadrat ist nie negativ: keine Nullstelle.', 'L = { }'])
        return Instanz(self.key, rolle, stufe, params, self.text.format(term=term), 'LOESUNGSMENGE',
                       mengen_payload(richtig or [0]), menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln),
                       [h.format(teilen=f' und teil durch {zahl(a)}' if a != 1 else '') for h in self.hinweis_vorlagen],
                       weg, [{'werte': list(reversed(menge(richtig)['menge']))}] if len(richtig) > 1 else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(nullstellen_aus_text(inst.frage))


BAUFORM = NS1()
