"""PQ-3 · Fehler finden im Lösungsweg der p-q-Formel (gleichung_quadr_formel, K2). Fehler finden. S3–S4. Rollen T R."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, summe, zahl
from ..formen import klammer, menge_text, wurzel
from ..rechnen import zeilen_menge

# Fehlerarten: (Schluessel, Zeile, Begruendung)
WARUM = {
    'p': {'id': 'a', 'text': 'Vor p/2 gehört ein Minus: Es heißt −p/2.'},
    'q': {'id': 'b', 'text': 'Unter der Wurzel wird q abgezogen, nicht addiert.'},
    'quadrat': {'id': 'c', 'text': 'p/2 muss unter der Wurzel quadriert werden.'},
    'wurzel': {'id': 'd', 'text': 'Die Wurzel ist falsch gezogen.'},
}
NAMEN = ['Mia', 'Ben', 'Lea', 'Tom', 'Emma', 'Noah', 'Ella', 'Finn']


def _rat(x) -> str:
    return zahl(x)


class PQ3(Bauform):
    key = 'PQ-3'
    skill = 'gleichung_quadr_formel'
    kernidee = 'gleichung_quadr_formel:K2'
    format = 'fehler_finden'
    rollen = ('transfer', 'recap')
    stufen = {3: 'Fehler beim Einsetzen: −p/2 mit falschem Vorzeichen oder q mit falschem Vorzeichen',
              4: 'Fehler unter der Wurzel: p/2 nicht quadriert, oder die Wurzel falsch gezogen'}
    text = '{name} löst {gleichung} mit der p-q-Formel. In welcher Zeile steckt der Fehler, und warum?'
    fehlbild_steckbrief = []
    hinweis_vorlagen = ['Rechne Zeile für Zeile nach. Wo ändert sich etwas, das nicht stimmt?',
                        'Schreib die Formel daneben: x = −p/2 ± √((p/2)² − q). Vergleiche jedes Zeichen.',
                        'Prüf besonders die Zeile, in der p und q eingesetzt werden, und die Zeile danach.']
    zeit_sek = 150

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            r1, r2 = rng.randint(-9, 9), rng.randint(-9, 9)
            if r1 != r2 and 0 not in (r1, r2) and (r1 + r2) % 2 == 0 and r1 + r2 != 0:
                art = rng.choice(['p', 'q']) if stufe == 3 else rng.choice(['quadrat', 'wurzel'])
                p, q = -(r1 + r2), r1 * r2
                m = Fraction(-p, 2)
                # Der Fehler muss weiterrechenbar sein: Ausdruck unter der Wurzel ≥ 0 und anders als richtig (sonst ist
                # die Zeile gar nicht falsch). Ist er keine Quadratzahl, endet der Lösungsweg mit der Wurzel.
                df = {'q': m * m + q, 'quadrat': m - q}.get(art, m * m - q)
                if df >= 0 and (art in ('p', 'wurzel') or df != m * m - q):
                    return {'p': p, 'q': q, 'art': art, 'name': NAMEN[(r1 * 3 + r2 * 5) % 8]}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        p, q, art = Fraction(params['p']), Fraction(params['q']), params['art']
        m = -p / 2
        gl = f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'
        # richtige Zeilen
        z2 = f'x₁,₂ = {zahl(m)} ± √({klammer(m)}² − {klammer(q)})'
        d = m * m - q
        z3, z4 = f'x₁,₂ = {zahl(m)} ± √{zahl(d)}', f'x₁,₂ = {zahl(m)} ± {zahl(wurzel(d))}'
        if art == 'p':
            mf = -m
            zeilen = [gl, f'x₁,₂ = {zahl(mf)} ± √({klammer(mf)}² − {klammer(q)})', f'x₁,₂ = {zahl(mf)} ± √{zahl(d)}',
                      f'x₁,₂ = {zahl(mf)} ± {zahl(wurzel(d))}', f'L = {menge_text([mf + wurzel(d), mf - wurzel(d)])}']
            fehler = 2
        elif art == 'q':
            df = m * m + q
            w = wurzel(df)
            zeilen = [gl, f'x₁,₂ = {zahl(m)} ± √({klammer(m)}² + {klammer(q)})', f'x₁,₂ = {zahl(m)} ± √{zahl(df)}']
            zeilen += [f'x₁,₂ = {zahl(m)} ± {zahl(w)}', f'L = {menge_text([m + w, m - w])}'] if w is not None else []
            fehler = 2
        elif art == 'quadrat':
            df = m - q
            w = wurzel(df)
            zeilen = [gl, z2, f'x₁,₂ = {zahl(m)} ± √{zahl(df)}']
            zeilen += [f'x₁,₂ = {zahl(m)} ± {zahl(w)}', f'L = {menge_text([m + w, m - w])}'] if w is not None else []
            fehler = 3
        else:
            wf = wurzel(d) + 1
            zeilen = [gl, z2, z3, f'x₁,₂ = {zahl(m)} ± {zahl(wf)}', f'L = {menge_text([m + wf, m - wf])}']
            fehler = 4
        warum = sorted(WARUM.values(), key=lambda w: w['id'])
        payload = {'format': 'fehler_finden', 'zeilen': [{'nr': i + 1, 'text': z} for i, z in enumerate(zeilen)],
                   'warum': warum}
        richtig = sorted([m + wurzel(d), m - wurzel(d)])
        weg = [f'Zeile {fehler}: {zeilen[fehler - 1]}', WARUM[art]['text'], f'Richtig: {[z2, z2, z3, z4][fehler - 1] if fehler > 1 else gl}',
               f'L = {menge_text(richtig)}']
        frage = f'{params["name"]} löst {gl} mit der p-q-Formel. In welcher Zeile steckt der Fehler, und warum?'
        return Instanz(self.key, rolle, stufe, params, frage, 'FEHLER_FINDEN', payload,
                       {'zeile': fehler, 'warum': WARUM[art]['id']}, [], list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        mengen = [zeilen_menge(z['text']) for z in inst.payload['zeilen']]
        brueche = [i + 1 for i in range(1, len(mengen)) if mengen[i] != mengen[i - 1]]
        if len(brueche) != 1:
            raise ValueError(f'nicht genau eine falsche Zeile: {brueche}')
        return {'zeile': brueche[0], 'warum': inst.loesung['warum']}

    def angenehm(self, inst: Instanz) -> str | None:
        p, q = Fraction(inst.params['p']), Fraction(inst.params['q'])
        return None if wurzel((p / 2) ** 2 - q) else 'Diskriminante keine Quadratzahl'


BAUFORM = PQ3()
