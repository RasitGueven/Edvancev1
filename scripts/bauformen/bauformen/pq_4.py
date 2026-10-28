"""PQ-4 · Schritte der p-q-Formel ordnen (gleichung_quadr_formel, K1). Schritte ordnen. S2. Rollen Ü R."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import klammer, menge_text, wurzel
from ..rechnen import zeilen_menge


class PQ4(Bauform):
    key = 'PQ-4'
    skill = 'gleichung_quadr_formel'
    kernidee = 'gleichung_quadr_formel:K1'
    format = 'schritte_ordnen'
    rollen = ('uebung', 'recap')
    stufen = {2: 'a·x² + b·x + c = 0 mit a von 2 bis 4, vier Schritte bis zur Lösungsmenge'}
    text = 'Bring die Schritte zum Lösen von {gleichung} in die richtige Reihenfolge.'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Welcher Schritt braucht noch keine Formel?', 'In welchem Schritt tauchen p und q zum ersten Mal auf?',
                        'Vergleiche zwei Schritte: Welcher ist näher an der Lösung?']
    zeit_sek = 90

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            r1, r2 = rng.randint(-9, 9), rng.randint(-9, 9)
            if r1 != r2 and 0 not in (r1, r2) and r1 + r2 != 0 and (r1 + r2) % 2 == 0:
                return {'a': rng.randint(2, 4), 'p': -(r1 + r2), 'q': r1 * r2}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q = params['a'], Fraction(params['p']), Fraction(params['q'])
        m, d = -p / 2, (p / 2) ** 2 - q
        w = wurzel(d)
        gl = f'{summe([(a, "x²"), (a * p, "x"), (a * q, "")])} = 0'
        schritte = [f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0', f'x₁,₂ = {zahl(m)} ± √({klammer(m)}² − {klammer(q)})',
                    f'x₁,₂ = {zahl(m)} ± {zahl(w)}', f'L = {menge_text([m + w, m - w])}']
        # gemischt, aber nie schon in der richtigen Reihenfolge
        rng = random.Random(f'{a}-{p}-{q}')
        reihenfolge = list(range(4))
        while reihenfolge == list(range(4)):
            rng.shuffle(reihenfolge)
        ids = 'abcd'
        payload = {'format': 'schritte_ordnen',
                   'schritte': [{'id': ids[k], 'text': schritte[i]} for k, i in enumerate(reihenfolge)]}
        richtig = [ids[reihenfolge.index(i)] for i in range(4)]
        frage = f'Bring die Schritte zum Lösen von {gl} in die richtige Reihenfolge.'
        weg = [f'1. Durch {a} teilen: {schritte[0]}', f'2. p und q in die Formel einsetzen: {schritte[1]}',
               f'3. Wurzel ziehen: {schritte[2]}', f'4. Lösungsmenge: {schritte[3]}']
        return Instanz(self.key, rolle, stufe, params, frage, 'SCHRITTE_ORDNEN', payload, {'reihenfolgen': [richtig]}, [],
                       list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        """Konzept §5: die Schritte in dieser Reihenfolge ergeben die Lösung, jeder Schritt ist gleichwertig zur
        Aufgabe; Reihenfolge: Normalform, Formel mit Wurzel, Wurzel gezogen, Lösungsmenge."""
        from ..rechnen import gleichung_aus_frage, loesungsmenge
        import sympy
        ziel = sympy.FiniteSet(*[sympy.Rational(w.numerator, w.denominator) for w in
                                 loesungsmenge(*gleichung_aus_frage('Löse ' + inst.frage.split(' von ')[1].split(' in die')[0] + '.'))])
        nach_id = {s['id']: s['text'] for s in inst.payload['schritte']}

        def stelle(t: str) -> int:
            return 3 if t.startswith('L =') else 1 if '√' in t else 2 if '±' in t else 0
        reihe = sorted(nach_id, key=lambda i: stelle(nach_id[i]))
        if any(zeilen_menge(nach_id[i]) != ziel for i in reihe):
            raise ValueError('ein Schritt ist nicht gleichwertig')
        return {'reihenfolgen': [reihe]}


BAUFORM = PQ4()
