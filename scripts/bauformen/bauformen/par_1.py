"""PAR-1 · Wertetabelle zu f(x) = a·x² (fkt_quadr_parabel, K1). Tabelle (je Feld ein Wert).
S1 a = 1 · S2 a ganzzahlig (2, 3) · S3 a negativ · S4 a als Bruch (1/2, 1/4). Rollen W Ü B H."""

from __future__ import annotations

import random
import re
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl, zahl_antwort
from ..formen import klammer
from ..klassisch import teil
from ..rechnen import X, ausdruck


class PAR1(Bauform):
    key = 'PAR-1'
    skill = 'fkt_quadr_parabel'
    kernidee = 'fkt_quadr_parabel:K1'
    format = 'tabelle'
    rollen = ('warmup', 'uebung', 'beispiel', 'home')
    stufen = {1: 'a = 1, vier x-Werte von −3 bis 3, mindestens zwei negativ', 2: 'a = 2 oder 3',
              3: 'a = −1, −2 oder −3', 4: 'a = 1/2 oder 1/4, gerade x-Werte von −6 bis 6'}
    text = 'Fülle die Wertetabelle für f(x) = {term} aus.'
    fehlbild_steckbrief = [
        {'key': 'qf_quadrat_negativ', 'regel': '(−x)² als negativ gerechnet', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Minus mal Minus ergibt Plus. (−2)² ist 4, nicht −4.'},
        {'key': 'qf_ax_statt_ax2', 'regel': 'a·x statt a·x²', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Hast du x quadriert? f(x) = a · x · x.'},
        {'key': 'qf_ax_quadriert', 'regel': '(a·x)² statt a·x²', 'gilt_fuer_stufen': [2, 3, 4],
         'rueckmeldung': 'Nur x wird quadriert, die Zahl davor nicht. Erst x², dann mal a.'},
    ]
    hinweis_vorlagen = ['Setz jeden x-Wert für x ein.', 'Rechne zuerst x², dann mal {a}.',
                        'Für x = {x0}: f({x0}) = {a} · {x0k}².']
    warum = {'bei_schritt': 0, 'frage': 'Warum haben f(−2) und f(2) denselben Wert?',
             'bausteine': [{'id': 'a', 'text': '(−2)² und 2² sind beide 4.'},
                           {'id': 'b', 'text': 'Weil man das Minus beim Einsetzen weglässt.'},
                           {'id': 'c', 'text': 'Weil a positiv ist.'}],
             'richtig': 'a'}
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        a = {1: Fraction(1), 2: Fraction(rng.choice([2, 3])), 3: Fraction(rng.choice([-1, -2, -3])),
             4: Fraction(1, rng.choice([2, 4]))}[stufe]
        pool = [-6, -4, -2, 2, 4, 6] if stufe == 4 else [-3, -2, -1, 1, 2, 3]
        while True:
            xs = sorted(rng.sample(pool, 4))
            if sum(x < 0 for x in xs) >= 2:
                return {'a': str(a), 'xs': xs}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, xs = Fraction(params['a']), params['xs']
        term = summe([(a, 'x²')]) if a.denominator == 1 else f'{zahl(a)} · x²' if a > 0 else f'−{zahl(-a)} · x²'
        frage = f'Fülle die Wertetabelle für f(x) = {term} aus.'
        teile = [teil(i + 1, f'f({zahl(x)}) =') for i, x in enumerate(xs)]
        loes, fb, weg = {'teile': {}}, [], []
        for i, x in enumerate(xs):
            nr, y = str(i + 1), a * x * x
            loes['teile'][nr] = [zahl_antwort(y)]
            kand = {'qf_quadrat_negativ': -a * x * x if x < 0 else None, 'qf_ax_statt_ax2': a * x,
                    'qf_ax_quadriert': (a * x) ** 2}
            gesehen = {y}
            for f in self.fehlbilder_fuer(stufe):
                w = kand[f['key']]
                if w is None or w in gesehen:
                    continue
                gesehen.add(w)
                fb.append({'key': f['key'], 'teil': i + 1, 'wert': zahl_antwort(w)})
            weg.append(f'f({zahl(x)}) = {zahl(a) if a != 1 else ""}{" · " if a != 1 else ""}{klammer(x)}² = {zahl(y)}'
                       .replace('−1 · ', '−'))
        werte = {'a': zahl(a), 'x0': zahl(xs[0]), 'x0k': klammer(xs[0])}
        return Instanz(self.key, rolle, stufe, params, frage, 'MULTI_PART', None, loes, fb,
                       [h.format(**werte) for h in self.hinweis_vorlagen], weg, teile=teile)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        f = ausdruck(inst.frage.split('f(x) = ')[1].removesuffix(' aus.'))
        aus = {}
        for t in inst.teile:
            x0 = ausdruck(re.fullmatch(r'f\((.+)\) =', t['prompt']).group(1))
            y = f.subs(X, x0)
            aus[str(t['nr'])] = [zahl_antwort(Fraction(int(y.p), int(y.q)))]
        return {'teile': aus}

    def angenehm(self, inst: Instanz) -> str | None:
        a = Fraction(inst.params['a'])
        ok = {1: a == 1, 2: a in (2, 3), 3: a in (-1, -2, -3), 4: a in (Fraction(1, 2), Fraction(1, 4))}[inst.stufe]
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = PAR1()
