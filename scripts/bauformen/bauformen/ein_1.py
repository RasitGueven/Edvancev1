"""EIN-1 · Wert in einen quadratischen Term einsetzen, auch negativ (term_einsetzen). Zahl.
S1 a = 1, x positiv · S2 a = 1, x negativ · S3 a ∈ {±2, ±3}, x negativ. Rollen W Ü H."""

from __future__ import annotations

import random
import re

from ..basis import Bauform, Instanz, ersetze, summe, zahl, zahl_antwort
from ..formen import klammer
from ..klassisch import zahl_payload
from ..rechnen import X, ausdruck


def _wert(a: int, b: int, c: int, x: int) -> int:
    return a * x * x + b * x + c


class EIN1(Bauform):
    key = 'EIN-1'
    skill = 'term_einsetzen'
    format = 'zahl'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'f(x) = x² + b·x + c, x von 1 bis 6 (ohne 2)', 2: 'a = 1, x von −1 bis −6 (ohne −2)',
              3: 'a ∈ {−3, −2, 2, 3}, x von −1 bis −5 (ohne −2)'}
    text = 'Berechne f({x0}) für f(x) = {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_quadrat_als_verdopplung', 'regel': 'x² als 2·x gerechnet', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'x² heißt x mal x, nicht 2 mal x.'},
        {'key': 'qf_einsetzen_vorzeichen', 'regel': '−x² statt (−x)²', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Setz negative Zahlen in Klammern ein: (−3)² = 9.'},
        {'key': 'qf_ax_quadriert', 'regel': '(a·x)² statt a·x²', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Nur x wird quadriert, die Zahl davor nicht. Erst quadrieren, dann malnehmen.'},
    ]
    hinweis_vorlagen = ['Ersetze jedes x durch {xk}.',
                        'Rechne zuerst das Quadrat, dann die Produkte, dann die Summe.',
                        'Schreib es auf: f({x0}) = {eingesetzt}.']
    loesungsweg_vorlage = ['f({x0}) = {eingesetzt}', '= {zwischen}', '= {ergebnis}']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a = 1 if stufe < 3 else rng.choice([-3, -2, 2, 3])
            x = rng.choice([1, 3, 4, 5, 6]) if stufe == 1 else -rng.choice([1, 3, 4, 5, 6] if stufe == 2 else [1, 3, 4, 5])
            b, c = rng.choice([-1, 1]) * rng.randint(1, 9), rng.randint(-9, 9)
            p = {'a': a, 'b': b, 'c': c, 'x': x}
            werte = [_wert(a, b, c, x)] + [f['wert'] for f in self._fehler(p, stufe)]
            if len(set(werte)) == len(werte) and abs(werte[0]) <= 99:
                return p

    def _fehler(self, p: dict, stufe: int) -> list[dict]:
        a, b, c, x = p['a'], p['b'], p['c'], p['x']
        r = {'qf_quadrat_als_verdopplung': a * 2 * x + b * x + c, 'qf_einsetzen_vorzeichen': -a * x * x + b * x + c,
             'qf_ax_quadriert': (a * x) ** 2 + b * x + c}
        return [{'key': f['key'], 'wert': r[f['key']]} for f in self.fehlbilder_fuer(stufe)]

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b, c, x = params['a'], params['b'], params['c'], params['x']
        term = summe([(a, 'x²'), (b, 'x'), (c, '')])
        xk = klammer(x)
        teile = [f'{"" if a == 1 else ("−" if a == -1 else zahl(a) + " · ")}{xk}²', f'{zahl(b)} · {xk}' if b != 1 else xk]
        eingesetzt = ' + '.join(teile) + (f' + {klammer(c)}' if c else '')
        eingesetzt = eingesetzt.replace('+ −', '+ (−').replace('(−(', '(').replace(' (−', ' (−')
        eingesetzt = re.sub(r'\+ \(−(\d+) ·', r'+ (−\1) ·', eingesetzt)
        zwischen = ' + '.join(klammer(v) for v in [a * x * x, b * x] + ([c] if c else []))
        erg = _wert(a, b, c, x)
        w = {'x0': zahl(x), 'term': term, 'xk': xk, 'eingesetzt': eingesetzt, 'zwischen': zwischen, 'ergebnis': zahl(erg)}
        frage = ersetze(self.text, w)
        loes = {'werte': [zahl_antwort(erg)] + ([f'+{erg}'] if erg > 0 else [])}
        fb = [{'key': f['key'], 'wert': zahl_antwort(f['wert'])} for f in self._fehler(params, stufe)]
        return Instanz(self.key, rolle, stufe, params, frage, 'NUMERIC', zahl_payload(frage), loes, fb,
                       [ersetze(h, w) for h in self.hinweis_vorlagen], [ersetze(z, w) for z in self.loesungsweg_vorlage])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        m = re.fullmatch(r'Berechne f\((.+?)\) für f\(x\) = (.+)\.', inst.frage)
        wert = ausdruck(m.group(2)).subs(X, ausdruck(m.group(1)))
        return {'werte': [zahl_antwort(int(wert))]}

    def angenehm(self, inst: Instanz) -> str | None:
        a, x = inst.params['a'], inst.params['x']
        ok = {1: a == 1 and x > 0, 2: a == 1 and x < 0, 3: a not in (0, 1) and x < 0}[inst.stufe]
        return None if ok and abs(x) != 2 else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = EIN1()
