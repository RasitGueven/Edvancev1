"""AUS-1 · Gemeinsamen Faktor ausklammern (term_ausklammern). Feldmaske.
S1 a·x² + b·x = x · (a·x + b) · S2 k·m·x + k·n = k · (m·x + n) · S3 k·m·x² + k·n·x = k·x · (m·x + n). Rollen W Ü H."""

from __future__ import annotations

import random
from math import gcd

from ..basis import Bauform, Instanz, ersetze, summe
from ..formen import andere_eingabe, feldmaske, fm, poly_koeff, werte

ZUSAMMENGESETZT = [4, 6, 8, 9, 10, 12]


def _kleinster_teiler(k: int) -> int:
    return next(p for p in range(2, k + 1) if k % p == 0)


class AUS1(Bauform):
    key = 'AUS-1'
    skill = 'term_ausklammern'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'a·x² + b·x: x ausklammern', 2: 'k·m·x + k·n: die Zahl k ausklammern (k zusammengesetzt)',
              3: 'k·m·x² + k·n·x: k·x ausklammern'}
    text = 'Klammere den größten gemeinsamen Faktor aus: {term}.'
    fehlbild_steckbrief = [
        {'key': 'qf_ausklammern_vorzeichen', 'regel': 'Vorzeichen in der Klammer falsch', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Prüf das Vorzeichen in der Klammer. Multipliziere zur Probe wieder aus.'},
        {'key': 'qf_ausklammern_unvollstaendig', 'regel': 'nur ein Teiler von k ausgeklammert', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Da geht noch mehr. Schau, ob die Zahlen in der Klammer noch einen gemeinsamen Teiler haben.'},
        {'key': 'qf_ausklammern_nicht_geteilt', 'regel': 'zweiter Summand nicht geteilt', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Teil jeden Summanden durch den Faktor, nicht nur den ersten.'},
    ]
    hinweis_vorlagen = ['Was steckt in beiden Summanden?',
                        'Such den größten Teiler beider Zahlen und denk an x.',
                        'Teil jeden Summanden durch den Faktor. Was bleibt übrig?']
    loesungsweg_vorlage = ['{term}', '= {faktor} · {erst} {vz} {faktor} · {zweit}', '= {ergebnis}']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            m, n = rng.randint(1, 6), rng.choice([-1, 1]) * rng.randint(1, 9)
            if gcd(m, abs(n)) == 1:
                break
        if stufe == 1:
            return {'k': 1, 'm': m, 'n': n}
        return {'k': rng.choice(ZUSAMMENGESETZT), 'm': m, 'n': n}

    def _schablone(self, stufe: int):
        if stufe == 1:
            return fm('x · (', '[a?]', 'x ', '±b', ')')
        return fm('[k]', ' · (' if stufe == 2 else 'x · (', '[a?]', 'x ', '±b', ')')

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        k, m, n = params['k'], params['m'], params['n']
        if stufe == 1:
            term = summe([(m, 'x²'), (n, 'x')])
            faktor, erst, zweit = 'x', summe([(m, 'x')]), str(abs(n))
        elif stufe == 2:
            term = summe([(k * m, 'x'), (k * n, '')])
            faktor, erst, zweit = str(k), summe([(m, 'x')]), str(abs(n))
        else:
            term = summe([(k * m, 'x²'), (k * n, 'x')])
            faktor, erst, zweit = f'{k}x', summe([(m, 'x')]), str(abs(n))
        ergebnis = (f'{"" if stufe == 1 else k}x · ({summe([(m, "x"), (n, "")])})' if stufe != 2
                    else f'{k} · ({summe([(m, "x"), (n, "")])})')
        w = {'term': term, 'faktor': faktor, 'erst': erst, 'vz': '+' if n > 0 else '−', 'zweit': zweit,
             'ergebnis': ergebnis}
        schab = self._schablone(stufe)
        mit_k = {} if stufe == 1 else {'k': k}
        loes = werte(**mit_k, a=m, b=n)
        fb = []
        for f in self.fehlbilder_fuer(stufe):
            if f['key'] == 'qf_ausklammern_vorzeichen':
                fw = werte(**mit_k, a=m, b=-n)
            elif f['key'] == 'qf_ausklammern_unvollstaendig':
                p = _kleinster_teiler(k)
                fw = werte(k=k // p, a=m * p, b=n * p)
            else:
                fw = werte(k=k, a=m, b=k * n)
            fb.append({'key': f['key'], **fw})
        anders = andere_eingabe(schab, loes)
        leer = {'felder': {**({'k': str(k)} if stufe > 1 else {}), 'a': '', 'vb': '+' if n > 0 else '−',
                           'b': str(abs(n))}} if m == 1 else None
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, w), 'FELDMASKE', feldmaske(schab), loes, fb,
                       [ersetze(h, w) for h in self.hinweis_vorlagen], [ersetze(z, w) for z in self.loesungsweg_vorlage],
                       [x for x in (anders, leer) if x])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        term = inst.frage.split(': ', 1)[1].removesuffix('.')
        a2, a1, a0 = poly_koeff(term)
        if inst.stufe == 1:
            return werte(a=a2, b=a1)
        if inst.stufe == 2:
            k = gcd(int(a1), int(a0))
            return werte(k=k, a=a1 / k, b=a0 / k)
        k = gcd(int(a2), int(a1))
        return werte(k=k, a=a2 / k, b=a1 / k)

    def angenehm(self, inst: Instanz) -> str | None:
        k, m, n = inst.params['k'], inst.params['m'], inst.params['n']
        if gcd(m, abs(n)) != 1 or m < 1:
            return 'Klammer lässt sich weiter kürzen'
        return None if (inst.stufe == 1) == (k == 1) else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = AUS1()
