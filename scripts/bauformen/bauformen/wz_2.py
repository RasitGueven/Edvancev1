"""WZ-2 · a·x² + b = c (gleichung_quadr_wurzel, K2: erst umstellen, dann Wurzel). Lösungsmenge.
S2 a = 1 · S3 a von 2 bis 5. Rollen Ü H G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload, wurzel
from ..rechnen import gleichung_aus_frage, loesungsmenge


class WZ2(Bauform):
    key = 'WZ-2'
    skill = 'gleichung_quadr_wurzel'
    kernidee = 'gleichung_quadr_wurzel:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'home', 'generalprobe')
    stufen = {2: 'x² + b = c, (c − b) eine Quadratzahl von 1 bis 144', 3: 'a·x² + b = c, a von 2 bis 5, (c − b)/a Quadratzahl'}
    text = 'Löse {gleichung}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nur_positive_loesung', 'regel': 'nur +√((c − b)/a)', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Auch eine negative Zahl ins Quadrat ergibt eine positive Zahl. Gibt es eine zweite Lösung?'},
        {'key': 'qf_gegenoperation_vorzeichen', 'regel': '±√((c + b)/a)', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Beim Umstellen kehrt sich die Rechenart um: aus + b wird − b.'},
        {'key': 'qf_durch_a_vergessen', 'regel': '±√(c − b)', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Vor x² steht noch eine Zahl. Teil durch sie, bevor du die Wurzel ziehst.'},
    ]
    hinweis_vorlagen = ['Was muss weg, damit x² allein steht?', 'Bring zuerst {b_text} auf die andere Seite{teilen}.',
                        'Wenn x² allein steht: Welche Zahlen ergeben quadriert {r}?']
    loesungsweg_vorlage = ['{gleichung}', '{ax2} = {cb}', 'x² = {r}', 'x = {w} oder x = −{w}', 'L = {menge}']
    zeit_sek = 90
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        a = 1 if stufe == 2 else rng.randint(2, 5)
        w = rng.randint(1, 12 if stufe == 2 else 8)
        b = rng.choice([-1, 1]) * rng.randint(1, 30)
        return {'a': a, 'b': b, 'c': a * w * w + b}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b, c = params['a'], params['b'], params['c']
        r = Fraction(c - b, a)
        w = wurzel(r)
        richtig = [w, -w]
        gl = f'{summe([(a, "x²"), (b, "")])} = {zahl(c)}'
        werte = {'gleichung': gl, 'b_text': zahl(b) if b < 0 else f'+ {b}', 'teilen': f' und teil durch {a}' if a != 1 else '',
                 'r': zahl(r), 'ax2': summe([(a, 'x²')]), 'cb': zahl(c - b), 'w': zahl(w), 'menge': menge_text(richtig)}
        r_plus = Fraction(c + b, a)
        regeln = {'qf_nur_positive_loesung': [w],
                  'qf_gegenoperation_vorzeichen': [wurzel(r_plus), -wurzel(r_plus)] if wurzel(r_plus) else None,
                  'qf_durch_a_vergessen': [wurzel(c - b), -wurzel(c - b)] if wurzel(c - b) else None}
        weg = [ersetze(z, werte) for z in self.loesungsweg_vorlage]
        if a == 1:
            weg.pop(1)
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, werte), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln),
                       [ersetze(h, werte) for h in self.hinweis_vorlagen], weg,
                       [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(loesungsmenge(*gleichung_aus_frage(inst.frage)))

    def angenehm(self, inst: Instanz) -> str | None:
        a, b, c = inst.params['a'], inst.params['b'], inst.params['c']
        if wurzel(Fraction(c - b, a)) in (None, 0):
            return 'keine Quadratzahl'
        return None if (inst.stufe == 2) == (a == 1) else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = WZ2()
