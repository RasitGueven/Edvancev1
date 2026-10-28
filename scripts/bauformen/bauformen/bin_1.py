"""BIN-1 · (x ± d)² ausmultiplizieren (term_binom_quadrat). Feldmaske. S1 (x + d)² · S2 (x − d)² · S3 (kx − d)².
Rollen W Ü H."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, ersetze, summe
from ..formen import andere_eingabe, feldmaske, fm, poly_koeff, werte


class BIN1(Bauform):
    key = 'BIN-1'
    skill = 'term_binom_quadrat'
    format = 'feldmaske'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: '(x + d)², d von 1 bis 12', 2: '(x − d)², d von 1 bis 12', 3: '(k·x − d)², k von 2 bis 5, d von 1 bis 9'}
    text = 'Multipliziere {term} aus.'
    fehlbild_steckbrief = [
        {'key': 'qf_binom_mittelglied_fehlt', 'regel': 'k²x² + d² (2·k·d·x fehlt)', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Beim Quadrat einer Summe gibt es ein mittleres Glied. Multipliziere jedes Glied mit jedem.'},
        {'key': 'qf_binom_mittelglied_einfach', 'regel': 'Mittelglied k·d·x statt 2·k·d·x', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Das mittlere Glied kommt zweimal vor. Denk an die 2 in der binomischen Formel.'},
        {'key': 'qf_binom_vorzeichen', 'regel': 'Vorzeichen des Mittelglieds falsch', 'gilt_fuer_stufen': [1, 2, 3],
         'rueckmeldung': 'Prüf das Vorzeichen des mittleren Glieds. Es hat dasselbe Vorzeichen wie d in der Klammer.'},
        {'key': 'qf_binom_quadrat_differenz', 'regel': 'k²x² − d²', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': '(x − d)² ist nicht x² − d². Schreib das Quadrat als Produkt zweier Klammern.'},
        {'key': 'qf_binom_k_nicht_quadriert', 'regel': 'k·x² statt k²·x²', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Auch die Zahl vor x wird quadriert: (k·x)² = k² · x².'},
    ]
    hinweis_vorlagen = ['Welche binomische Formel passt zu {term}?',
                        'Schreib das Quadrat als Produkt: {term} = {produkt}.',
                        'Das mittlere Glied ist 2 · {erst} · {zweit}. Was ergibt das?']
    loesungsweg_vorlage = ['{term}', '= {erst_q} {mitte_rechnung} + {zweit_q}', '= {ergebnis}']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        if stufe == 1:
            return {'k': 1, 'd': rng.randint(1, 12)}
        if stufe == 2:
            return {'k': 1, 'd': -rng.randint(1, 12)}
        return {'k': rng.randint(2, 5), 'd': -rng.randint(1, 9)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        k, d = params['k'], params['d']
        innen = summe([(k, 'x'), (d, '')])
        term = f'({innen})²'
        a, b, c = k * k, 2 * k * d, d * d
        ergebnis = summe([(a, 'x²'), (b, 'x'), (c, '')])
        schab = fm(*(['[a]'] if stufe == 3 else []), 'x² ', '±b', 'x ', '±c')
        erst = 'x' if k == 1 else f'{k}x'
        zweit = summe([(d, '')]).replace('−', '(−') + (')' if d < 0 else '')
        w = {'term': term, 'produkt': f'({innen}) · ({innen})', 'erst': erst, 'zweit': zweit,
             'erst_q': summe([(a, 'x²')]), 'mitte_rechnung': ('+ ' if b > 0 else '− ') + f'2 · {erst} · {abs(d)}',
             'zweit_q': str(c), 'ergebnis': ergebnis}
        loes = werte(**({'a': a} if stufe == 3 else {}), b=b, c=c)
        regeln = {'qf_binom_mittelglied_fehlt': (a, 0, c), 'qf_binom_mittelglied_einfach': (a, k * d, c),
                  'qf_binom_vorzeichen': (a, -b, c), 'qf_binom_quadrat_differenz': (a, 0, -c),
                  'qf_binom_k_nicht_quadriert': (k, b, c)}
        fb = []
        for f in self.fehlbilder_fuer(stufe):
            fa, fb_, fc = regeln[f['key']]
            fb.append({'key': f['key'], **werte(**({'a': fa} if stufe == 3 else {}), b=fb_, c=fc)})
        payload = feldmaske(schab)
        anders = andere_eingabe(schab, loes)
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, w), 'FELDMASKE', payload, loes, fb,
                       [ersetze(h, w) for h in self.hinweis_vorlagen], [ersetze(z, w) for z in self.loesungsweg_vorlage],
                       [anders] if anders else [])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        term = inst.frage.removeprefix('Multipliziere ').removesuffix(' aus.')
        a, b, c = poly_koeff(term)
        return werte(**({'a': a} if inst.stufe == 3 else {}), b=b, c=c)

    def angenehm(self, inst: Instanz) -> str | None:
        k, d = inst.params['k'], inst.params['d']
        ok = {1: k == 1 and 1 <= d <= 12, 2: k == 1 and -12 <= d <= -1, 3: 2 <= k <= 5 and -9 <= d <= -1}[inst.stufe]
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = BIN1()
