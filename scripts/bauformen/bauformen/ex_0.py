"""EX-0 · Größter oder kleinster Wert einer gegebenen Kontextfunktion (fkt_quadr_extrem, K1). Mehrteiler mit Kontext.
S1 Scheitelpunktform, nach unten geöffnet · S2 Scheitelpunktform, nach oben geöffnet · S3 Normalform. Rollen W Ü B H."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..formen import scheitel_aus_kontext
from ..klassisch import teil

KONTEXTE = {
    'ball': ('Ein Ball wird geworfen. Seine Höhe über dem Boden ist h(t) = {term} (t in Sekunden, h in Metern).', 'h', 't',
             'Nach wie vielen Sekunden ist der Ball am höchsten?', 'Wie hoch ist er dann (in Metern)?', -1),
    'kosten': ('Eine Firma stellt x Kisten am Tag her. Die Kosten je Kiste sind K(x) = {term} (in Euro).', 'K', 'x',
               'Bei wie vielen Kisten sind die Kosten je Kiste am kleinsten?', 'Wie hoch sind sie dann (in Euro)?', 1),
}


class EX0(Bauform):
    key = 'EX-0'
    skill = 'fkt_quadr_extrem'
    kernidee = 'fkt_quadr_extrem:K1'
    format = 'mehrteiler'
    rollen = ('warmup', 'uebung', 'beispiel', 'home')
    kann_entfallen = True
    stufen = {1: 'h(t) = −(t − d)² + e (Wurf), Scheitel ganzzahlig', 2: 'K(x) = (x − d)² + e (Kosten), Scheitel ganzzahlig',
              3: 'Funktion in Normalform, erst den Scheitel bestimmen'}
    text = '{kontext}'
    fehlbild_steckbrief = [
        {'key': 'qf_stelle_statt_wert', 'regel': 'in Teil 2 die Stelle statt des Werts', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Gefragt ist der Wert der Funktion, also die y-Koordinate des Scheitels.'},
        {'key': 'qf_hoch_tief_verwechselt', 'regel': 'in Teil 3 Hoch- und Tiefpunkt verwechselt', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Schau auf die Zahl vor dem Quadrat: negativ heißt nach unten geöffnet, also ein größter Wert.'},
    ]
    hinweis_vorlagen = ['Der größte oder kleinste Wert liegt am Scheitel.', '{schritt}',
                        'Die Stelle ist die x-Koordinate des Scheitels, der Wert die y-Koordinate.']
    zeit_sek = 150

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        art = 'ball' if stufe == 1 else 'kosten' if stufe == 2 else rng.choice(['ball', 'kosten'])
        d = rng.randint(1, 5) if art == 'ball' else rng.randint(3, 12)
        e = rng.randint(6, 30) if art == 'ball' else rng.randint(5, 40)
        return {'art': art, 'd': d, 'e': e}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        art, d, e = params['art'], params['d'], params['e']
        satz, name, var, f1, f2, a = KONTEXTE[art]
        if stufe == 3:
            term = summe([(a, f'{var}²'), (-2 * a * d, var), (a * d * d + e, '')])
        else:
            term = f'{"−" if a < 0 else ""}({summe([(1, var), (-d, "")])})² + {e}'
        kontext = satz.format(term=term)
        frage = kontext
        opts = [('gross', 'ein größter Wert'), ('klein', 'ein kleinster Wert')]
        teile = [teil(1, f1), teil(2, f2), teil(3, 'Ist das ein größter oder ein kleinster Wert?', opts)]
        richtig_3 = 'gross' if a < 0 else 'klein'
        loes = {'teile': {'1': [zahl_antwort(d)], '2': [zahl_antwort(e)], '3': [richtig_3]}}
        fb = [{'key': 'qf_stelle_statt_wert', 'teil': 2, 'wert': zahl_antwort(d)},
              {'key': 'qf_hoch_tief_verwechselt', 'teil': 3, 'wert': 'klein' if a < 0 else 'gross'}]
        schritt = ('Bring die Funktion in die Scheitelpunktform.' if stufe == 3 else
                   f'Lies den Scheitel aus der Scheitelpunktform ab.')
        weg = [f'{name}({var}) = {term}'] + ([f'{name}({var}) = {"−" if a < 0 else ""}({summe([(1, var), (-d, "")])})² + {e}']
                                              if stufe == 3 else []) + \
              [f'Scheitel S({d} | {e})', f'1) {var} = {d}', f'2) {name} = {e}',
               f'3) {"größter" if a < 0 else "kleinster"} Wert, weil die Parabel nach {"unten" if a < 0 else "oben"} geöffnet ist']
        return Instanz(self.key, rolle, stufe, params, frage, 'MULTI_PART', None, loes,
                       [f for f in fb if f['wert'] != loes['teile'][str(f['teil'])][0]],
                       [h.format(schritt=schritt) for h in self.hinweis_vorlagen], weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        name, var = ('h', 't') if 'h(t)' in inst.frage else ('K', 'x')
        sx, sy, a = scheitel_aus_kontext(inst.frage, name, var)
        return {'teile': {'1': [zahl_antwort(sx)], '2': [zahl_antwort(sy)], '3': ['gross' if a < 0 else 'klein']}}


BAUFORM = EX0()
