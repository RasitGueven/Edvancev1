"""NP-2 · a·x² + b·x = 0 (gleichung_quadr_faktor, K2). Lösungsmenge.
S1 a = 1, Lösung > 0 · S2 a = 1, Lösung < 0 · S3 a ≠ 1, ganzzahlig · S4 a ≠ 1, Bruch. Rollen Ü B H G."""

from __future__ import annotations

import random
from fractions import Fraction
from math import gcd

from ..basis import Bauform, Instanz, ersetze, summe, zahl, zahl_antwort
from ..rechnen import gleichung_aus_frage, loesungsmenge


class NP2(Bauform):
    key = 'NP-2'
    skill = 'gleichung_quadr_faktor'
    kernidee = 'gleichung_quadr_faktor:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'beispiel', 'home', 'generalprobe')
    stufen = {1: 'a = 1, zweite Lösung positiv (x² − p·x = 0)',
              2: 'a = 1, zweite Lösung negativ (x² + p·x = 0)',
              3: 'a von 2 bis 5, zweite Lösung ganzzahlig',
              4: 'a von 2 bis 6, zweite Lösung ein gekürzter Bruch (ggT(a, b) = 1)'}
    text = 'Löse {term} = 0.'
    fehlbild_steckbrief = [
        {'key': 'qf_null_vergessen', 'regel': 'nur −b/a', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Ein Faktor ist x selbst. Wann wird dieser Faktor null?'},
        {'key': 'qf_nullprodukt_vorzeichen', 'regel': '{0; b/a}', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Prüf das Vorzeichen: Für welches x wird die Klammer wirklich null?'},
        {'key': 'qf_a_uebersehen', 'regel': '{0; −b}', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'In der Klammer steht noch ein Faktor vor x. Teil auch durch ihn.'},
    ]
    hinweis_vorlagen = ['Was haben beide Summanden gemeinsam?',
                        'Klammere x aus. Ein Produkt ist 0, wenn ein Faktor 0 ist.',
                        'Klammere x aus: x · (…) = 0. Was bleibt in der Klammer?']
    loesungsweg_vorlage = ['{term} = 0', 'x · ({klammer}) = 0', 'x = 0 oder {klammer} = 0', 'x = 0 oder x = {x2}',
                           'L = {menge}']
    warum = {'bei_schritt': 1, 'frage': 'Warum darf man x ausklammern?',
             'bausteine': [{'id': 'a', 'text': 'Beide Summanden enthalten x als Faktor.'},
                           {'id': 'b', 'text': 'Weil man durch x teilen darf.'},
                           {'id': 'c', 'text': 'Weil x² dasselbe ist wie 2x.'}],
             'richtig': 'a'}
    zeit_sek = 90
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        if stufe == 1:
            return {'a': 1, 'b': -rng.randint(2, 20)}
        if stufe == 2:
            return {'a': 1, 'b': rng.randint(2, 20)}
        a = rng.randint(2, 5) if stufe == 3 else rng.randint(2, 6)
        if stufe == 3:
            return {'a': a, 'b': a * rng.choice([-1, 1]) * rng.randint(2, 6)}
        while True:
            b = rng.choice([-1, 1]) * rng.randint(1, 13)
            if b % a != 0 and gcd(a, abs(b)) == 1 and abs(Fraction(b, a)) < 7:
                return {'a': a, 'b': b}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b = params['a'], params['b']
        x2 = Fraction(-b, a)
        term = summe([(a, 'x²'), (b, 'x')])
        klammer = summe([(a, 'x'), (b, '')])
        menge = sorted([Fraction(0), x2])
        werte = {'term': term, 'klammer': klammer, 'x2': zahl(x2),
                 'menge': '{' + '; '.join(zahl(m) for m in menge) + '}'}
        frage = ersetze(self.text, werte)
        payload = {'format': 'loesungsmenge', 'element': 'bruch' if x2.denominator != 1 else 'zahl',
                   'max_felder': 3, 'variable': 'x'}
        loesung = {'menge': [zahl_antwort(m) for m in menge]}
        schreib = [{'werte': [zahl_antwort(m) for m in reversed(menge)]}]
        if x2.denominator != 1:
            dezimal = float(x2)
            if round(dezimal, 6) == dezimal and len(str(abs(dezimal))) <= 6:
                schreib.append({'werte': ['0', str(dezimal).replace('.', ',')]})
        fb = []
        for f in self.fehlbilder_fuer(stufe):
            menge_f = {'qf_null_vergessen': [x2], 'qf_nullprodukt_vorzeichen': [Fraction(0), -x2],
                       'qf_a_uebersehen': [Fraction(0), Fraction(-b)]}[f['key']]
            fb.append({'key': f['key'], 'menge': [zahl_antwort(m) for m in menge_f]})
        return Instanz(self.key, rolle, stufe, {'a': a, 'b': b}, frage, 'LOESUNGSMENGE', payload, loesung, fb,
                       [ersetze(h, werte) for h in self.hinweis_vorlagen],
                       [ersetze(z, werte) for z in self.loesungsweg_vorlage], schreib)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        werte = loesungsmenge(*gleichung_aus_frage(inst.frage))
        if werte is None:
            raise ValueError('nicht rational')
        return {'menge': [zahl_antwort(w) for w in werte]}

    def angenehm(self, inst: Instanz) -> str | None:
        a, b = inst.params['a'], inst.params['b']
        x2 = Fraction(-b, a)
        regeln = {1: a == 1 and x2 > 0, 2: a == 1 and x2 < 0, 3: a != 1 and x2.denominator == 1,
                  4: a != 1 and x2.denominator != 1 and gcd(a, abs(b)) == 1}
        if not regeln[inst.stufe]:
            return f'passt nicht zu Stufe {inst.stufe}'
        if abs(x2) > 20:
            return 'Lösung zu groß'
        return None


BAUFORM = NP2()
