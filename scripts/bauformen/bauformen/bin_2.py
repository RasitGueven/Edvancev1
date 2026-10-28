"""BIN-2 · x² + 2dx + d² als Quadrat schreiben (term_binom_quadrat). Feldmaske (x ± [d])².
S1 d von 3 bis 15 · S2 d von −3 bis −15 · S3 |d| von 16 bis 25. Rollen W Ü H."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import andere_eingabe, feldmaske, fm, poly_koeff, werte


class BIN2(Bauform):
    key = 'BIN-2'
    skill = 'term_binom_quadrat'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'x² + 2dx + d², d von 3 bis 15', 2: 'x² − 2dx + d², d von 3 bis 15',
              3: 'd von 16 bis 25, beide Vorzeichen'}
    text = 'Schreib {trinom} als Quadrat.'
    fehlbild_steckbrief = [
        {'key': 'qf_binom_vorzeichen', 'regel': '(x − d)² statt (x + d)²', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Prüf das Vorzeichen in der Klammer. Es hat dasselbe Vorzeichen wie das Glied mit x.'},
        {'key': 'qf_binom_b_statt_halb', 'regel': '(x + 2d)²', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Das Glied mit x ist 2 · d · x. In die Klammer kommt nur die Hälfte der Zahl vor x.'},
        {'key': 'qf_binom_c_statt_wurzel', 'regel': '(x + d²)²', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Die Zahl am Ende ist d². In die Klammer kommt die Wurzel daraus.'},
    ]
    hinweis_vorlagen = ['Welche binomische Formel hat drei Glieder wie {trinom}?',
                        'Die Zahl am Ende ist ein Quadrat. Von welcher Zahl?',
                        'Vergleiche mit x² + 2 · d · x + d². Was ist d?']
    loesungsweg_vorlage = ['{trinom}', '= x² {vz} 2 · {betrag} · x + {betrag}²', '= {quadrat}']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        if stufe == 1:
            return {'d': rng.randint(3, 15)}
        if stufe == 2:
            return {'d': -rng.randint(3, 15)}
        return {'d': rng.choice([-1, 1]) * rng.randint(16, 25)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        d = params['d']
        trinom = summe([(1, 'x²'), (2 * d, 'x'), (d * d, '')])
        quadrat = f'({summe([(1, "x"), (d, "")])})²'
        w = {'trinom': trinom, 'vz': '+' if d > 0 else '−', 'betrag': abs(d), 'quadrat': quadrat}
        schab = fm('(x ', '±d', ')²')
        loes = werte(d=d)
        regeln = {'qf_binom_vorzeichen': -d, 'qf_binom_b_statt_halb': 2 * d,
                  'qf_binom_c_statt_wurzel': d * abs(d)}
        fb = [{'key': f['key'], **werte(d=regeln[f['key']])} for f in self.fehlbilder_fuer(stufe)]
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, w), 'FELDMASKE', feldmaske(schab), loes, fb,
                       [ersetze(h, w) for h in self.hinweis_vorlagen], [ersetze(z, w) for z in self.loesungsweg_vorlage],
                       [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        _, b, c = poly_koeff(inst.frage.removeprefix('Schreib ').removesuffix(' als Quadrat.'))
        d = b / 2
        if d * d != c:
            raise ValueError('kein vollständiges Quadrat')
        return werte(d=d)

    def angenehm(self, inst: Instanz) -> str | None:
        d = inst.params['d']
        ok = {1: 3 <= d <= 15, 2: -15 <= d <= -3, 3: 16 <= abs(d) <= 25}[inst.stufe]
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = BIN2()
