"""NP-1 · (x − p)(x − q) = 0 (gleichung_quadr_faktor, K1). Lösungsmenge.
S1 p, q positiv · S2 Vorzeichen gemischt. Rollen W Ü B H."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, ersetze, summe, zahl
from ..formen import menge, menge_text, mengen_fehlbilder, mengen_payload
from ..rechnen import gleichung_aus_frage, loesungsmenge


class NP1(Bauform):
    key = 'NP-1'
    skill = 'gleichung_quadr_faktor'
    kernidee = 'gleichung_quadr_faktor:K1'
    format = 'loesungsmenge'
    rollen = ('warmup', 'uebung', 'beispiel', 'home')
    stufen = {1: '(x − p)(x − q) = 0, p und q von 1 bis 12, verschieden', 2: 'p und q mit gemischten Vorzeichen'}
    text = 'Löse {gleichung}.'
    fehlbild_steckbrief = [
        {'key': 'qf_nullprodukt_vorzeichen', 'regel': '{−p; −q}', 'gilt_fuer_stufen': [1, 2],
         'rueckmeldung': 'Prüf das Vorzeichen: Für welches x wird die Klammer wirklich null?'},
    ]
    hinweis_vorlagen = ['Wann ist ein Produkt gleich null?', 'Ein Produkt ist 0, wenn ein Faktor 0 ist.',
                        'Setz jede Klammer einzeln gleich null: {k1} = 0 oder {k2} = 0.']
    loesungsweg_vorlage = ['{gleichung}', '{k1} = 0 oder {k2} = 0', 'x = {p} oder x = {q}', 'L = {menge}']
    warum = {'bei_schritt': 1, 'frage': 'Warum darf man jede Klammer einzeln null setzen?',
             'bausteine': [{'id': 'a', 'text': 'Ein Produkt ist nur dann 0, wenn ein Faktor 0 ist.'},
                           {'id': 'b', 'text': 'Weil man Klammern immer weglassen darf.'},
                           {'id': 'c', 'text': 'Weil beide Klammern gleich groß sind.'}],
             'richtig': 'a'}
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        while True:
            p, q = rng.randint(1, 12), rng.randint(1, 12)
            if stufe == 2:
                p = -p
            if p != q and p != -q:
                return {'p': p, 'q': q}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        p, q = params['p'], params['q']
        k1, k2 = summe([(1, 'x'), (-p, '')]), summe([(1, 'x'), (-q, '')])
        gl = f'({k1})({k2}) = 0'
        richtig = sorted([p, q])
        w = {'gleichung': gl, 'k1': k1, 'k2': k2, 'p': zahl(p), 'q': zahl(q), 'menge': menge_text(richtig)}
        fb = mengen_fehlbilder(self, stufe, richtig, {'qf_nullprodukt_vorzeichen': [-p, -q]})
        return Instanz(self.key, rolle, stufe, params, ersetze(self.text, w), 'LOESUNGSMENGE', mengen_payload(richtig),
                       menge(richtig), fb, [ersetze(h, w) for h in self.hinweis_vorlagen],
                       [ersetze(z, w) for z in self.loesungsweg_vorlage], [{'werte': list(reversed(menge(richtig)['menge']))}])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        return menge(loesungsmenge(*gleichung_aus_frage(inst.frage)))

    def angenehm(self, inst: Instanz) -> str | None:
        p, q = inst.params['p'], inst.params['q']
        ok = (p > 0 and q > 0) if inst.stufe == 1 else (p < 0 < q)
        return None if ok else f'passt nicht zu Stufe {inst.stufe}'


BAUFORM = NP1()
