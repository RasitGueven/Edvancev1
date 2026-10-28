"""PAR-5 · Aussagen zum Streckfaktor a (fkt_quadr_parabel, K2). Multiple Choice. S2–S3. Rollen R T."""

from __future__ import annotations

import random
import re
from fractions import Fraction

from ..basis import Bauform, Instanz, zahl
from ..klassisch import mc_payload


def _term(a: Fraction) -> str:
    vz = '−' if a < 0 else ''
    b = abs(a)
    return f'{vz}{zahl(b)}x²' if b.denominator == 1 else f'{vz}{zahl(b)} · x²'


class PAR5(Bauform):
    key = 'PAR-5'
    skill = 'fkt_quadr_parabel'
    kernidee = 'fkt_quadr_parabel:K2'
    format = 'mc'
    rollen = ('recap', 'transfer')
    stufen = {2: 'f und g beide nach oben geöffnet, verschiedene Beträge von a', 3: 'eines der beiden a negativ'}
    text = 'Gegeben sind f(x) = {f} und g(x) = {g}. Welche Aussage stimmt?'
    fehlbild_steckbrief = [
        {'key': 'qf_streckfaktor_umgekehrt', 'regel': '„größeres a heißt weiter“', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Je größer der Betrag von a, desto schneller steigen die Werte: Die Parabel wird schmaler.'},
        {'key': 'qf_oeffnung_vertauscht', 'regel': 'Öffnung falsch zugeordnet', 'gilt_fuer_stufen': [2, 3],
         'rueckmeldung': 'Nur ein negatives a öffnet die Parabel nach unten.'},
    ]
    hinweis_vorlagen = ['Vergleiche die Beträge der Zahlen vor x².', 'Größerer Betrag heißt: schmalere Parabel.',
                        'Das Vorzeichen von a entscheidet über die Öffnung.']
    zeit_sek = 45

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        werte_ = ['1/4', '1/3', '1/2', '2', '3', '4']
        while True:
            fa, ga = (Fraction(x) for x in rng.sample(werte_, 2))
            if stufe == 3:
                if rng.random() < 0.5:
                    fa = -fa
                else:
                    ga = -ga
            if abs(fa) != abs(ga):
                return {'f': str(fa), 'g': str(ga)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        fa, ga = Fraction(params['f']), Fraction(params['g'])
        schmal, breit = ('f', 'g') if abs(fa) > abs(ga) else ('g', 'f')
        unten = 'f' if fa < 0 else 'g' if ga < 0 else None
        opts = [('r', f'Der Graph von {schmal} ist schmaler als der Graph von {breit}.'),
                ('qf_streckfaktor_umgekehrt', f'Der Graph von {schmal} ist breiter als der Graph von {breit}.'),
                ('n', 'Beide Graphen sind gleich breit.')]
        if unten:
            oben = 'g' if unten == 'f' else 'f'
            opts.append(('qf_oeffnung_vertauscht', f'Der Graph von {oben} ist nach unten geöffnet.'))
        else:
            opts.append(('qf_oeffnung_vertauscht', 'Beide Graphen sind nach unten geöffnet.'))
        rng = random.Random(f'par5-{fa}-{ga}')
        rng.shuffle(opts)
        ids = 'abcd'
        payload = mc_payload([(ids[i], t) for i, (_, t) in enumerate(opts)])
        richtig = next(ids[i] for i, (k, _) in enumerate(opts) if k == 'r')
        fb = [{'key': k, 'option': ids[i]} for i, (k, _) in enumerate(opts) if k.startswith('qf_')]
        weg = [f'|{zahl(fa)}| {">" if abs(fa) > abs(ga) else "<"} |{zahl(ga)}|',
               f'Größerer Betrag von a: schmalere Parabel. Also ist {schmal} schmaler als {breit}.']
        return Instanz(self.key, rolle, stufe, params, self.text.format(f=_term(fa), g=_term(ga)), 'MC', payload,
                       {'option': richtig}, fb, list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        from ..rechnen import X, ausdruck
        m = re.search(r'f\(x\) = (.+) und g\(x\) = (.+)\. Welche', inst.frage)
        fa, ga = (abs(ausdruck(m.group(i)).coeff(X, 2)) for i in (1, 2))
        schmal, breit = ('f', 'g') if fa > ga else ('g', 'f')
        ziel = f'Der Graph von {schmal} ist schmaler als der Graph von {breit}.'
        return {'option': next(o['id'] for o in inst.payload['options'] if o['label'] == ziel)}


BAUFORM = PAR5()
