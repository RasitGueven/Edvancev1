"""PQ-1 · Normalform herstellen, p und q ablesen (gleichung_quadr_formel, K1). Mehrteiler (p, q).
S1 schon Normalform · S2 mit negativen Zahlen · S3 a ≠ 1 (durch a teilen) · S4 erst umstellen. Rollen W Ü H."""

from __future__ import annotations

import random
from fractions import Fraction

import sympy

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..klassisch import teil
from ..rechnen import X, gleichung_aus_frage


class PQ1(Bauform):
    key = 'PQ-1'
    skill = 'gleichung_quadr_formel'
    kernidee = 'gleichung_quadr_formel:K1'
    format = 'mehrteiler'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'x² + px + q = 0, p und q positiv', 2: 'p oder q negativ', 3: 'a·x² + b·x + c = 0, a von 2 bis 5',
              4: 'x² + b·x = c oder x² = b·x + c: erst umstellen'}
    text = 'Bring {gleichung} in die Form x² + px + q = 0. Gib p und q an.'
    fehlbild_steckbrief = [
        {'key': 'qf_p_vorzeichen', 'regel': 'p ohne Vorzeichen abgelesen', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'p ist die Zahl vor x, zusammen mit dem Rechenzeichen davor. Prüf das Vorzeichen.'},
        {'key': 'qf_q_vorzeichen', 'regel': 'q ohne Vorzeichen abgelesen', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'q ist die Zahl ohne x mit ihrem Vorzeichen.'},
        {'key': 'qf_durch_a_vergessen', 'regel': 'b und c statt b/a und c/a', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Vor x² muss eine 1 stehen. Teil zuerst alle Glieder durch die Zahl vor x².'},
        {'key': 'qf_gegenoperation_vorzeichen', 'regel': 'beim Umstellen Vorzeichen nicht gewechselt', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Wenn du ein Glied auf die andere Seite bringst, wechselt sein Vorzeichen.'},
    ]
    hinweis_vorlagen = ['In der Normalform steht vor x² eine 1 und rechts eine 0.',
                        '{schritt}', 'p ist die Zahl vor x, q die Zahl ohne x, jeweils mit Vorzeichen.']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p, q = rng.randint(-12, 12), rng.randint(-30, 30)
            if 0 in (p, q) or abs(p) == abs(q):
                continue
            if stufe == 1 and (p < 0 or q < 0):
                continue
            if stufe >= 2 and p > 0 and q > 0:
                continue
            return {'a': rng.randint(2, 5) if stufe == 3 else 1, 'p': p, 'q': q,
                    'form': rng.choice(['rechts_c', 'rechts_bc']) if stufe == 4 else 'null'}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q, form = params['a'], params['p'], params['q'], params['form']
        if form == 'rechts_c':
            gl = f'{summe([(1, "x²"), (p, "x")])} = {zahl(-q)}'
            schritt = f'Bring {zahl(-q)} auf die linke Seite.'
        elif form == 'rechts_bc':
            gl = f'x² = {summe([(-p, "x"), (-q, "")])}'
            schritt = 'Bring alles auf die linke Seite, sodass rechts 0 steht.'
        else:
            gl = f'{summe([(a, "x²"), (a * p, "x"), (a * q, "")])} = 0'
            schritt = f'Teil jedes Glied durch {a}.' if a != 1 else 'Die Gleichung steht schon in der richtigen Form.'
        frage = f'Bring {gl} in die Form x² + px + q = 0. Gib p und q an.'
        teile = [teil(1, 'p ='), teil(2, 'q =')]
        loes = {'teile': {'1': [zahl_antwort(p)] + ([f'+{p}'] if p > 0 else []),
                          '2': [zahl_antwort(q)] + ([f'+{q}'] if q > 0 else [])}}
        kand = []
        if stufe == 4:  # Zweitprüfung A6 G, Befund 2: das Umstell-Fehlbild zuerst, sonst verdrängt es die Ablesefehler
            kand += [('qf_gegenoperation_vorzeichen', 2, -q)] if form == 'rechts_c' else \
                    [('qf_gegenoperation_vorzeichen', 1, -p)]
        if stufe >= 2:
            kand += [('qf_p_vorzeichen', 1, -p), ('qf_q_vorzeichen', 2, -q)]
        if stufe == 3:
            kand += [('qf_durch_a_vergessen', 1, a * p)]
        fb, gesehen = [], {(1, p), (2, q)}
        for key, t, w in kand:
            if (t, w) in gesehen or any(f['key'] == key for f in fb):
                continue
            gesehen.add((t, w))
            fb.append({'key': key, 'teil': t, 'wert': zahl_antwort(w)})
        normal = f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'
        weg = [gl, normal, f'p = {zahl(p)}, q = {zahl(q)}']
        if gl == normal:
            weg.pop(1)
        return Instanz(self.key, rolle, stufe, params, frage, 'MULTI_PART', None, loes, fb,
                       [h.format(schritt=schritt) for h in self.hinweis_vorlagen], weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        links, rechts = gleichung_aus_frage('Löse ' + inst.frage.removeprefix('Bring ').split(' in die Form')[0] + '.')
        a, b, c = sympy.Poly(sympy.expand(links - rechts), X).all_coeffs()
        p, q = sympy.Rational(b, a), sympy.Rational(c, a)
        return {'teile': {'1': [zahl_antwort(Fraction(int(p.p), int(p.q)))], '2': [zahl_antwort(Fraction(int(q.p), int(q.q)))]}}


BAUFORM = PQ1()
