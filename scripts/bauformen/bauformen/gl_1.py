"""GL-1 · a·x + b = c (gleichung_zweischrittig). Zahl oder Bruch.
S1 Lösung positiv ganzzahlig · S2 Lösung negativ ganzzahlig · S3 Lösung ein gekürzter Bruch. Rollen W Ü H."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl, zahl_antwort
from ..klassisch import zahl_payload
from ..rechnen import gleichung_aus_frage, loesungsmenge


def _dezimal(x: Fraction) -> list[str]:
    if x.denominator in (2, 4, 5, 8, 10, 20, 25):
        t = f'{float(x):.6f}'.rstrip('0').rstrip('.')
        return [t, t.replace('.', ',')]
    return []


class GL1(Bauform):
    key = 'GL-1'
    skill = 'gleichung_zweischrittig'
    format = 'zahl'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'a von 2 bis 9, Lösung von 1 bis 12', 2: 'a von 2 bis 9, Lösung von −12 bis −1',
              3: 'a von 2 bis 9, Lösung ein gekürzter Bruch'}
    text = 'Löse {gleichung}. Gib x an.'
    fehlbild_steckbrief = [
        {'key': 'qf_gegenoperation_vorzeichen', 'regel': '(c + b) / a', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Beim Umstellen kehrt sich die Rechenart um: aus + b wird − b.'},
        {'key': 'qf_durch_a_vergessen', 'regel': 'c − b', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Da steht noch eine Zahl vor x. Teil auch durch sie.'},
        {'key': 'qf_umstellen_reihenfolge', 'regel': 'c / a − b', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Bring zuerst die Zahl ohne x auf die andere Seite. Teil erst danach.'},
    ]
    hinweis_vorlagen = ['Was muss weg, damit x allein steht?', 'Rechne zuerst auf beiden Seiten {gegen}.',
                        'Danach steht {a}x = … da. Wodurch teilst du?']
    loesungsweg_vorlage = ['{gleichung}', '{a}x = {rechts}', 'x = {rechts} : {a}', 'x = {x}']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            a, b = rng.randint(2, 9), rng.choice([-1, 1]) * rng.randint(1, 15)
            if stufe == 3:
                x = Fraction(rng.choice([-1, 1]) * rng.randint(1, 30), a)
                if x.denominator == 1:
                    continue
            else:
                x = Fraction(rng.randint(1, 12) * (1 if stufe == 1 else -1))
            c = a * x + b
            if c.denominator != 1:
                continue
            p = {'a': a, 'b': b, 'c': int(c)}
            alle = [x] + [f['wert'] for f in self._fehler(p)]
            if len(set(alle)) == len(alle):
                return p

    def _fehler(self, p: dict) -> list[dict]:
        a, b, c = p['a'], p['b'], p['c']
        return [{'key': 'qf_gegenoperation_vorzeichen', 'wert': Fraction(c + b, a)},
                {'key': 'qf_durch_a_vergessen', 'wert': Fraction(c - b)},
                {'key': 'qf_umstellen_reihenfolge', 'wert': Fraction(c, a) - b}]

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, b, c = params['a'], params['b'], params['c']
        x = Fraction(c - b, a)
        gleichung = f'{summe([(a, "x"), (b, "")])} = {zahl(c)}'
        w = {'gleichung': gleichung, 'gegen': f'− {b}' if b > 0 else f'+ {-b}', 'a': a, 'rechts': zahl(c - b),
             'x': zahl(x)}
        frage = ersetze(self.text, w)
        richtig = [zahl_antwort(x)] + _dezimal(x)
        fb = [{'key': f['key'], 'wert': zahl_antwort(f['wert'])} for f in self._fehler(params)]
        return Instanz(self.key, rolle, stufe, params, frage, 'NUMERIC', zahl_payload(frage), {'werte': richtig}, fb,
                       [ersetze(h, w) for h in self.hinweis_vorlagen], [ersetze(z, w) for z in self.loesungsweg_vorlage])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        werte = loesungsmenge(*gleichung_aus_frage(inst.frage.split('. Gib')[0] + '.'))
        if not werte or len(werte) != 1:
            raise ValueError('nicht eindeutig')
        return {'werte': [zahl_antwort(werte[0])]}

    def angenehm(self, inst: Instanz) -> str | None:
        x = Fraction(inst.params['c'] - inst.params['b'], inst.params['a'])
        ok = {1: x.denominator == 1 and 1 <= x <= 12, 2: x.denominator == 1 and -12 <= x <= -1,
              3: x.denominator != 1}[inst.stufe]
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = GL1()
