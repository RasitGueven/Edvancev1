"""KO-1 · Punkt im Koordinatensystem ablesen (geo_koordinaten). Feldmaske P([x] | [y]) mit Figur.
S1 beide Koordinaten positiv · S2 genau eine negativ · S3 beide negativ. Rollen W Ü H."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, zahl
from ..formen import andere_eingabe, feldmaske, fm, werte


class KO1(Bauform):
    key = 'KO-1'
    skill = 'geo_koordinaten'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'x und y von 1 bis 5, x ≠ y', 2: 'genau eine Koordinate negativ (−5 bis 5, ohne 0)',
              3: 'beide Koordinaten negativ, |x| ≠ |y|'}
    text = 'Lies die Koordinaten des Punktes P ab.'
    figur = {'generator': 'koordinatensystem', 'params': 'Fenster −6 bis 6, Gitter, Punkt P'}
    fehlbild_steckbrief = [
        {'key': 'qf_scheitel_koordinaten_vertauscht', 'regel': '(y | x)', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Zuerst kommt die x-Koordinate: wie weit nach rechts oder links. Dann die y-Koordinate.'},
        {'key': 'qf_koordinate_vorzeichen', 'regel': 'negative Koordinate ohne Minus', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Links vom Ursprung ist x negativ, unterhalb ist y negativ. Prüf die Vorzeichen.'},
    ]
    hinweis_vorlagen = ['Wo liegt der Ursprung, also der Punkt (0 | 0)?',
                        'Geh vom Ursprung zuerst waagerecht bis unter oder über P. Zähl die Kästchen.',
                        'Dann zählst du senkrecht bis P. Nach unten wird es negativ.']
    loesungsweg_vorlage = ['Waagerecht vom Ursprung: {x} (x-Koordinate)', 'Senkrecht bis P: {y} (y-Koordinate)',
                           'P({x} | {y})']
    zeit_sek = 45

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            x, y = rng.randint(1, 5), rng.randint(1, 5)
            if stufe == 2:
                if rng.random() < 0.5:
                    x = -x
                else:
                    y = -y
            elif stufe == 3:
                x, y = -x, -y
            if abs(x) != abs(y):
                return {'x': x, 'y': y}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        x, y = params['x'], params['y']
        schab = fm('P(', '±x', ' | ', '±y', ')')
        loes = werte(x=x, y=y)
        fb = [{'key': 'qf_scheitel_koordinaten_vertauscht', **werte(x=y, y=x)}]
        if stufe >= 2:
            fb.append({'key': 'qf_koordinate_vorzeichen', **werte(x=abs(x), y=abs(y))})
        figur = {'generator': 'koordinatensystem', 'alt': 'Koordinatensystem mit Gitter und einem Punkt P',
                 'params': {'x_min': -6, 'x_max': 6, 'y_min': -6, 'y_max': 6, 'gitter': True,
                            'punkte': [{'x': x, 'y': y, 'label': 'P', 'betont': True}]}}
        w = {'x': zahl(x), 'y': zahl(y)}
        anders = andere_eingabe(schab, loes)
        weg = [z.format(**w) for z in self.loesungsweg_vorlage]
        return Instanz(self.key, rolle, stufe, params, self.text, 'FELDMASKE', feldmaske(schab), loes, fb,
                       list(self.hinweis_vorlagen), weg, [anders] if anders else [], figur=figur)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        p = inst.figur['params']['punkte'][0]
        return werte(x=p['x'], y=p['y'])

    def angenehm(self, inst: Instanz) -> str | None:
        x, y = inst.params['x'], inst.params['y']
        neg = (x < 0) + (y < 0)
        ok = {1: neg == 0, 2: neg == 1, 3: neg == 2}[inst.stufe] and abs(x) != abs(y) and x and y
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = KO1()
