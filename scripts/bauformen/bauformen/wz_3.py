"""WZ-3 · (x − d)² = c (gleichung_quadr_wurzel, K3). Lösungsmenge.
S3 c Quadratzahl, d positiv · S4 c Quadratzahl, 0 oder negativ, d beliebig. Rollen Ü T G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload, wurzel
from ..rechnen import gleichung_aus_frage, loesungsmenge


class WZ3(Bauform):
    key = 'WZ-3'
    skill = 'gleichung_quadr_wurzel'
    kernidee = 'gleichung_quadr_wurzel:K3'
    format = 'loesungsmenge'
    rollen = ('uebung', 'transfer', 'generalprobe')
    stufen = {3: '(x − d)² = c, d von 1 bis 9, c Quadratzahl von 1 bis 81',
              4: '(x ± d)² = c, c Quadratzahl, 0 oder negativ'}
    text = 'Löse {gleichung}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nur_positive_loesung', 'regel': 'nur d + √c', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Die Klammer kann √c oder −√c sein. Rechne beide Fälle.'},
        {'key': 'qf_verschiebung_vorzeichen', 'regel': '−d ± √c', 'gilt_fuer_stufen': [3, 4],
         'rueckmeldung': 'Prüf das Vorzeichen von d: Für welches x wird die Klammer null?'},
        {'key': 'qf_wurzel_aus_negativ', 'regel': 'd ± √|c| bei c < 0', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Ein Quadrat ist nie negativ. Kann die Klammer im Quadrat eine negative Zahl sein?'},
    ]
    hinweis_vorlagen = ['Was steht in der Klammer, bevor quadriert wird?',
                        'Zieh auf beiden Seiten die Wurzel. Die Klammer ist dann √c oder −√c.',
                        'Schreib zwei Gleichungen: {klammer} = {w} und {klammer} = −{w}.']
    loesungsweg_vorlage = ['{gleichung}', '{klammer} = {w} oder {klammer} = −{w}', 'x = {x1} oder x = {x2}', 'L = {menge}']
    zeit_sek = 120
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        if stufe == 3:
            return {'d': rng.randint(1, 9), 'c': rng.randint(1, 9) ** 2}
        d = rng.choice([-1, 1]) * rng.randint(1, 9)
        art = rng.choice(['quadrat', 'quadrat', 'null', 'negativ'])
        c = {'quadrat': rng.randint(1, 10) ** 2, 'null': 0, 'negativ': -rng.randint(1, 8) ** 2}[art]
        return {'d': d, 'c': c}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        d, c = params['d'], params['c']
        klammer = summe([(1, 'x'), (-d, '')])
        gl = f'({klammer})² = {zahl(c)}'
        w = wurzel(c)
        richtig = [] if c < 0 else sorted({d + w, d - w})
        b = wurzel(abs(c))
        regeln = {'qf_nur_positive_loesung': [d + w] if c > 0 else None,
                  'qf_verschiebung_vorzeichen': sorted({-d + b, -d - b}) if c >= 0 else None,
                  'qf_wurzel_aus_negativ': sorted({d + b, d - b}) if c < 0 else None}
        werte = {'gleichung': gl, 'klammer': klammer, 'w': zahl(b), 'menge': menge_text(richtig),
                 'x1': zahl(d + (w or 0)), 'x2': zahl(d - (w or 0))}
        if c < 0:
            weg = [gl, f'Ein Quadrat ist nie negativ, also gibt es kein x mit ({klammer})² = {zahl(c)}.', 'L = { }']
        elif c == 0:
            weg = [gl, f'{klammer} = 0', f'x = {zahl(d)}', f'L = {menge_text(richtig)}']
        else:
            weg = [ersetze(z, werte) for z in self.loesungsweg_vorlage]
        schreib = [{'werte': list(reversed(menge(richtig)['menge']))}] if len(richtig) > 1 else []
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, werte), 'LOESUNGSMENGE', mengen_payload(richtig or [0]),
                       menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln),
                       [ersetze(h, werte) for h in self.hinweis_vorlagen], weg, schreib)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(loesungsmenge(*gleichung_aus_frage(inst.frage)))

    def angenehm(self, inst: Instanz) -> str | None:
        d, c = inst.params['d'], inst.params['c']
        if c > 0 and wurzel(c) is None:
            return 'c keine Quadratzahl'
        ok = (d > 0 and c > 0) if inst.stufe == 3 else True
        return None if ok else 'passt nicht zu Stufe 3'


BAUFORM = WZ3()
