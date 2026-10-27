"""WZ-1 · x² = c (gleichung_quadr_wurzel, K1). Lösungsmenge. S1 c Quadratzahl · S2 c = 0 oder c < 0. Rollen W Ü B H."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, zahl, zahl_antwort
from ..rechnen import gleichung_aus_frage, loesungsmenge


class WZ1(Bauform):
    key = 'WZ-1'
    skill = 'gleichung_quadr_wurzel'
    kernidee = 'gleichung_quadr_wurzel:K1'
    format = 'loesungsmenge'
    rollen = ('warmup', 'uebung', 'beispiel', 'home')
    stufen = {1: 'c ist eine Quadratzahl von 9 bis 400, zwei ganzzahlige Lösungen',
              2: 'c = 0 (eine Lösung) oder c negativ (keine Lösung)'}
    text = 'Löse x² = {c}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nur_positive_loesung', 'regel': 'nur +√c', 'gilt_fuer_stufen': [1],
         'rueckmeldung': 'Auch eine negative Zahl ins Quadrat ergibt eine positive Zahl.'},
        {'key': 'qf_wurzel_als_haelfte', 'regel': '±c/2', 'gilt_fuer_stufen': [1],
         'rueckmeldung': 'Die Wurzel ist nicht die Hälfte. Welche Zahl mal sich selbst ergibt c?'},
        {'key': 'qf_wurzel_aus_negativ', 'regel': '±√|c| bei c < 0', 'gilt_fuer_stufen': [2],
         'rueckmeldung': 'Ein Quadrat ist nie negativ. Prüf, ob es überhaupt eine Zahl geben kann.'},
    ]
    hinweis_vorlagen = ['Welche Zahl ergibt mit sich selbst malgenommen {c}?',
                        'Denk auch an negative Zahlen. Wie viele Zahlen können es sein?',
                        'Schreib die Gleichung als x = √{c} oder x = −√{c}, wenn das geht.']
    loesungsweg_vorlage = ['x² = {c}', 'x = √{c} oder x = −√{c}', 'x = {w} oder x = −{w}', 'L = {{−{w}; {w}}}']
    warum = {'bei_schritt': 1, 'frage': 'Warum gibt es zwei Lösungen?',
             'bausteine': [{'id': 'a', 'text': 'Auch eine negative Zahl ins Quadrat ist positiv.'},
                           {'id': 'b', 'text': 'Weil man die Wurzel immer zweimal zieht.'},
                           {'id': 'c', 'text': 'Weil c eine ungerade Zahl ist.'}],
             'richtig': 'a'}
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        if stufe == 1:
            return {'k': rng.randint(3, 20)}
        return {'k': rng.choice([0] + list(range(2, 11))), 'negativ': True}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        k = params['k']
        c = -k * k if params.get('negativ') else k * k
        werte = {'c': zahl(c), 'w': zahl(k)}
        frage = ersetze(self.text, werte)
        payload = {'format': 'loesungsmenge', 'element': 'zahl', 'max_felder': 3, 'variable': 'x'}
        if c > 0:
            loesung = {'menge': [zahl_antwort(-k), zahl_antwort(k)]}
            weg = [ersetze(z, werte) for z in self.loesungsweg_vorlage]
            schreib = [{'werte': [zahl_antwort(k), zahl_antwort(-k)]}, {'werte': [f'+{k}', zahl_antwort(-k), zahl_antwort(k)]}]
        elif c == 0:
            loesung = {'menge': ['0']}
            weg = ['x² = 0', 'Nur 0 · 0 ergibt 0.', 'L = {0}']
            schreib = [{'werte': ['0', '0']}]
        else:
            loesung = {'keine_loesung': True}
            weg = [f'x² = {zahl(c)}', 'Ein Quadrat ist nie negativ.', 'L = { }']
            schreib = []
        fb = []
        for f in self.fehlbilder_fuer(stufe):
            if f['key'] == 'qf_nur_positive_loesung':
                fb.append({'key': f['key'], 'menge': [zahl_antwort(k)]})
            elif f['key'] == 'qf_wurzel_als_haelfte':
                h = Fraction(c, 2)
                fb.append({'key': f['key'], 'menge': [zahl_antwort(-h), zahl_antwort(h)]})
            elif f['key'] == 'qf_wurzel_aus_negativ' and c < 0:
                fb.append({'key': f['key'], 'menge': [zahl_antwort(-k), zahl_antwort(k)]})
        hinweise = ([ersetze(h, werte) for h in self.hinweis_vorlagen] if c > 0 else
                    ['Welche Zahl ergibt mit sich selbst malgenommen ' + zahl(c) + '?',
                     'Was kommt heraus, wenn man eine Zahl mit sich selbst malnimmt: positiv, negativ oder null?',
                     'Prüf zuerst, ob x² überhaupt ' + zahl(c) + ' sein kann.'])
        return Instanz(self.key, rolle, stufe, {'c': c}, frage, 'LOESUNGSMENGE', payload, loesung, fb, hinweise,
                       weg, schreib)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        werte = loesungsmenge(*gleichung_aus_frage(inst.frage))
        if werte is None:
            raise ValueError('nicht rational')
        return {'keine_loesung': True} if not werte else {'menge': [zahl_antwort(w) for w in werte]}

    def angenehm(self, inst: Instanz) -> str | None:
        c = inst.params['c']
        if inst.stufe == 1 and not (9 <= c <= 400 and int(c ** 0.5) ** 2 == c):
            return 'Stufe 1 verlangt eine Quadratzahl von 9 bis 400'
        if inst.stufe == 2 and c > 0:
            return 'Stufe 2 verlangt c = 0 oder c < 0'
        return None


BAUFORM = WZ1()
