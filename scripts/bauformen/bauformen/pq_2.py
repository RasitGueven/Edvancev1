"""PQ-2 · Mit der p-q-Formel lösen (gleichung_quadr_formel, K2). Lösungsmenge.
S1 p, q > 0 · S2 p oder q negativ · S3 a ≠ 1 (erst teilen) · S4 nicht in Normalform (erst umstellen). Rollen Ü B H G."""

from __future__ import annotations

import random
from fractions import Fraction

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import vz, klammer, menge, menge_text, mengen_fehlbilder, mengen_payload, wurzel
from ..rechnen import gleichung_aus_frage, loesungsmenge


def _pq(p: Fraction, q: Fraction) -> list[Fraction] | None:
    """Lösungen von x² + px + q = 0, wenn rational (sonst None)."""
    w = wurzel((p / 2) ** 2 - q)
    return None if w is None else sorted({-p / 2 + w, -p / 2 - w})


class PQ2(Bauform):
    key = 'PQ-2'
    skill = 'gleichung_quadr_formel'
    kernidee = 'gleichung_quadr_formel:K2'
    format = 'loesungsmenge'
    rollen = ('uebung', 'beispiel', 'home', 'generalprobe')
    stufen = {1: 'x² + px + q = 0, p und q positiv, zwei ganzzahlige Lösungen',
              2: 'p oder q negativ, zwei ganzzahlige Lösungen',
              3: 'a·x² + b·x + c = 0 mit a von 2 bis 3, erst durch a teilen',
              4: 'nicht in Normalform: x² + b·x = c, erst umstellen'}
    text = 'Löse mit der p-q-Formel: {gleichung}.'
    fehlbild_steckbrief = [
        {'key': 'qf_p_vorzeichen', 'regel': 'p/2 statt −p/2', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Vor p/2 steht in der Formel ein Minus. Setz −p/2 ein.'},
        {'key': 'qf_halbes_p_nicht_quadriert', 'regel': 'p/2 statt (p/2)² unter der Wurzel', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Unter der Wurzel steht (p/2)². Hast du quadriert?'},
        {'key': 'qf_q_vorzeichen', 'regel': '+ q statt − q unter der Wurzel', 'gilt_fuer_stufen': [1, 2, 3, 4],
         'rueckmeldung': 'Unter der Wurzel wird q abgezogen. Achte auf das Vorzeichen von q.'},
        {'key': 'qf_durch_a_vergessen', 'regel': 'b und c ohne Teilen durch a eingesetzt', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Die Formel gilt nur, wenn vor x² eine 1 steht. Teil zuerst durch die Zahl vor x².'},
        {'key': 'qf_gegenoperation_vorzeichen', 'regel': 'c beim Umstellen ohne Vorzeichenwechsel', 'gilt_fuer_stufen': [4],
         'rueckmeldung': 'Bring alles auf eine Seite. Aus = c wird − c auf der linken Seite.'},
    ]
    hinweis_vorlagen = ['Steht die Gleichung schon in der Form x² + px + q = 0?',
                        'Lies p und q ab. Achte auf die Vorzeichen.',
                        'Setz ein: x = −p/2 ± √((p/2)² − q) mit p = {p} und q = {q}.']
    warum = {'bei_schritt': 1, 'frage': 'Warum muss vor x² eine 1 stehen?',
             'bausteine': [{'id': 'a', 'text': 'Die p-q-Formel gilt nur für x² + px + q = 0.'},
                           {'id': 'b', 'text': 'Weil die Wurzel sonst negativ wird.'},
                           {'id': 'c', 'text': 'Weil p immer positiv sein muss.'}],
             'richtig': 'a'}
    zeit_sek = 150
    anzahl = {'generalprobe': 12}

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            r1, r2 = rng.randint(-12, 12), rng.randint(-12, 12)
            if r1 == r2 or 0 in (r1, r2):
                continue
            p, q = -(r1 + r2), r1 * r2
            if stufe == 1 and not (p > 0 and q > 0):
                continue
            if stufe == 2 and not (p < 0 or q < 0):
                continue
            if abs(p) > 20 or abs(q) > 60 or p == 0:
                continue
            return {'a': rng.randint(2, 3) if stufe == 3 else 1, 'p': p, 'q': q}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        a, p, q = params['a'], Fraction(params['p']), Fraction(params['q'])
        richtig = _pq(p, q)
        normal = f'{summe([(1, "x²"), (p, "x"), (q, "")])} = 0'
        if stufe == 3:
            gl = f'{summe([(a, "x²"), (a * p, "x"), (a * q, "")])} = 0'
        elif stufe == 4:
            gl = f'{summe([(1, "x²"), (p, "x")])} = {zahl(-q)}'
        else:
            gl = normal
        m, d = -p / 2, (p / 2) ** 2 - q
        regeln = {'qf_p_vorzeichen': _pq(-p, q), 'qf_halbes_p_nicht_quadriert': (
                      None if wurzel(p / 2 - q) is None else sorted({m + wurzel(p / 2 - q), m - wurzel(p / 2 - q)})),
                  'qf_q_vorzeichen': _pq(p, -q), 'qf_durch_a_vergessen': _pq(a * p, a * q),
                  'qf_gegenoperation_vorzeichen': _pq(p, -q)}
        werte = {'gleichung': gl, 'p': zahl(p), 'q': zahl(q)}
        weg = [gl]
        if stufe == 3:
            weg.append(f'{normal}   (durch {a} geteilt)')
        if stufe == 4:
            weg.append(f'{normal}   (auf beiden Seiten {vz(q)})')
        weg += [f'p = {zahl(p)}, q = {zahl(q)}',
                f'x₁,₂ = {zahl(m)} ± √({klammer(m)}² − {klammer(q)})',
                f'x₁,₂ = {zahl(m)} ± √{zahl(d)}',
                f'x₁,₂ = {zahl(m)} ± {zahl(wurzel(d))}',
                f'x = {zahl(richtig[0])} oder x = {zahl(richtig[1])}', f'L = {menge_text(richtig)}']
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, werte), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), mengen_fehlbilder(self, stufe, richtig, regeln),
                       [ersetze(h, werte) for h in self.hinweis_vorlagen], weg,
                       [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(loesungsmenge(*gleichung_aus_frage(inst.frage)))

    def angenehm(self, inst: Instanz) -> str | None:
        a, p, q = inst.params['a'], inst.params['p'], inst.params['q']
        r = _pq(Fraction(p), Fraction(q))
        if not r or len(r) != 2 or any(x.denominator != 1 for x in r):
            return 'keine zwei ganzzahligen Lösungen'
        ok = {1: p > 0 and q > 0 and a == 1, 2: (p < 0 or q < 0) and a == 1, 3: a in (2, 3), 4: a == 1}[inst.stufe]
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = PQ2()
