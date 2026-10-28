"""NP-4 · a·x² = b·x, erst umstellen (gleichung_quadr_faktor, K2). Lösungsmenge. S4. Rollen Ü T G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload
from ..rechnen import gleichung_aus_frage, loesungsmenge


class NP4(Bauform):
    key = 'NP-4'
    skill = 'gleichung_quadr_faktor'
    kernidee = 'gleichung_quadr_faktor:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'transfer', 'generalprobe')
    stufen = {4: 'a·x² = b·x, a von 1 bis 4, b von −15 bis 15 (ohne 0), Lösung b/a ganzzahlig oder Bruch'}
    text = 'Löse {gleichung}.'
    fehlbild_steckbrief = [
        {'key': 'qf_durch_x_geteilt', 'regel': 'nur b/a (durch x geteilt)', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Wenn du durch x teilst, geht x = 0 verloren. Bring alles auf eine Seite und klammere x aus.'},
        {'key': 'qf_nullprodukt_vorzeichen', 'regel': '{0; −b/a}', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Prüf das Vorzeichen: Für welches x wird die Klammer wirklich null?'},
    ]
    hinweis_vorlagen = ['Darf man hier durch x teilen? Was wäre, wenn x = 0 ist?',
                        'Bring alles auf eine Seite, sodass rechts 0 steht.',
                        'Klammere x aus: x · (…) = 0.']
    loesungsweg_vorlage = ['{gleichung}', '{links} = 0', 'x · ({klammer}) = 0', 'x = 0 oder {klammer} = 0',
                           'L = {menge}']
    zeit_sek = 90
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a, b = rng.randint(1, 4), rng.choice([-1, 1]) * rng.randint(1, 15)
            if abs(Fraction(b, a)) <= 12 and (a == 1 or b % a != 0 or rng.random() < 0.5):
                return {'a': a, 'b': b}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b = params['a'], params['b']
        x2 = Fraction(b, a)
        richtig = sorted([Fraction(0), x2])
        gl = f'{summe([(a, "x²")])} = {summe([(b, "x")])}'
        w = {'gleichung': gl, 'links': summe([(a, 'x²'), (-b, 'x')]), 'klammer': summe([(a, 'x'), (-b, '')]),
             'menge': menge_text(richtig)}
        fb = mengen_fehlbilder(self, stufe, richtig, {'qf_durch_x_geteilt': [x2], 'qf_nullprodukt_vorzeichen': [0, -x2]})
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, w), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), fb, [ersetze(h, w) for h in self.hinweis_vorlagen],
                       [ersetze(z, w) for z in self.loesungsweg_vorlage], [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(loesungsmenge(*gleichung_aus_frage(inst.frage)))


BAUFORM = NP4()
