"""NS-4 · Welche Parabel hat die Nullstellen p und q? (fkt_quadr_nullstellen, K1). Graph-Auswahl.
S2 nach oben geöffnet · S3 auch nach unten geöffnet. Rollen Ü R."""

from __future__ import annotations

import random
import re
from fractions import Fraction

from ..basis import Bauform, Instanz, zahl
from ..formen import fenster_fuer, graph_optionen, graph_pruefen


def _scheitel(a: int, p: int, q: int) -> tuple[Fraction, Fraction]:
    d = Fraction(p + q, 2)
    return d, a * (d - p) * (d - q)


class NS4(Bauform):
    key = 'NS-4'
    skill = 'fkt_quadr_nullstellen'
    kernidee = 'fkt_quadr_nullstellen:K1'
    format = 'graph_auswahl'
    rollen = ('uebung', 'recap')
    stufen = {2: 'Nullstellen p und q ganzzahlig, gleicher Abstand gerade, a = 1', 3: 'a = −1 oder a = 1'}
    text = 'Welche Parabel hat die Nullstellen x = {p} und x = {q}{zusatz}?'
    fehlbild_steckbrief = [
        {'key': 'qf_scheitel_statt_nullstelle', 'regel': 'Scheitel bei (p | q) statt Nullstellen p und q', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Nullstellen sind die Stellen, an denen der Graph die x-Achse schneidet, nicht der Scheitel.'},
        {'key': 'qf_nullprodukt_vorzeichen', 'regel': 'Nullstellen −p und −q', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Schau genau auf die x-Achse: Liegen die Schnittpunkte rechts oder links vom Ursprung?'},
    ]
    hinweis_vorlagen = ['Nullstellen sind die Schnittpunkte mit der x-Achse.', 'Wo schneidet jeder Graph die x-Achse?',
                        'Such den Graphen, der die x-Achse genau bei x = {p} und x = {q} schneidet.']
    zeit_sek = 45

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p, q = sorted(rng.sample(range(-5, 6), 2))
            a = 1 if stufe == 2 else rng.choice([-1, 1])
            d, e = _scheitel(a, p, q)
            if (q - p) % 2 == 0 and 0 not in (p, q) and p != -q and abs(e) <= 9 and (p, q) != (d, e):
                return {'a': a, 'p': p, 'q': q}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q = params['a'], params['p'], params['q']
        d, e = _scheitel(a, p, q)
        dn, en = _scheitel(a, -q, -p)
        var = [('r', a, d, e), ('qf_scheitel_statt_nullstelle', a, Fraction(p), Fraction(q)),
               ('qf_nullprodukt_vorzeichen', a, dn, en)]
        zusatz = '' if stufe == 2 else (' und ist nach oben geöffnet' if a > 0 else ' und ist nach unten geöffnet')
        payload, fig, richtig, fb = graph_optionen(self.key, var, fenster_fuer([(v[2], v[3]) for v in var] + [(p, 0), (q, 0)], 2))
        weg = [f'Die Parabel schneidet die x-Achse bei x = {zahl(p)} und x = {zahl(q)}.',
               f'Ihr Scheitel liegt in der Mitte: x = {zahl(d)}.', f'f(x) = {"−" if a < 0 else ""}(x − {zahl(p)})(x − {zahl(q)})'.replace('− −', '+ ')]
        return Instanz(self.key, rolle, stufe, params, self.text.format(p=zahl(p), q=zahl(q), zusatz=zusatz), 'GRAPH_AUSWAHL',
                       payload, {'option': richtig}, fb, [h.format(p=zahl(p), q=zahl(q)) for h in self.hinweis_vorlagen],
                       weg, figur=fig)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        m = re.search(r'x = (\S+) und x = (\S+?)(\?| und)', inst.frage)
        p, q = (Fraction(m.group(i).replace('−', '-')) for i in (1, 2))
        a = -1 if 'unten' in inst.frage else 1
        d = (p + q) / 2
        return graph_pruefen(inst, Fraction(a), d, a * (d - p) * (d - q))


BAUFORM = NS4()
