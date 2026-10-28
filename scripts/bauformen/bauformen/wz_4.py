"""WZ-4 · Warum hat x² = −c keine Lösung? (gleichung_quadr_wurzel, K1). Begründungsbausteine. S2. Rollen R T."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz


class WZ4(Bauform):
    key = 'WZ-4'
    skill = 'gleichung_quadr_wurzel'
    kernidee = 'gleichung_quadr_wurzel:K1'
    format = 'bausteine'
    rollen = ('recap', 'transfer')
    stufen = {2: 'x² = −c mit c von 1 bis 30; eine richtige Begründung, drei falsche'}
    text = 'Warum hat x² = −{c} keine Lösung? Wähle die passende Begründung.'
    fehlbild_steckbrief = [
        {'key': 'qf_wurzel_aus_negativ', 'regel': 'Begründung „√ von −c ist −√c“', 'gilt_fuer_stufen': [2],
         'rueckmeldung': 'Prüf das mit einer Probe: Ist (−√c)² wirklich negativ?'},
    ]
    hinweis_vorlagen = ['Probier ein paar Zahlen aus: Was kommt heraus, wenn du sie quadrierst?',
                        'Denk an positive und negative Zahlen und an die 0.',
                        'Kann ein Quadrat überhaupt negativ sein?']
    zeit_sek = 60

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'c': rng.randint(1, 30)}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        c = params['c']
        texte = [('r', 'Jede Zahl ins Quadrat ist 0 oder positiv. −{c} kann also kein Quadrat sein.'),
                 ('f', 'Die Lösung ist x = −√{c}, also gibt es doch eine Lösung.'),
                 ('n1', 'Weil {c} keine Quadratzahl ist.'),
                 ('n2', 'Weil man aus einer Gleichung mit x² nie die Wurzel ziehen darf.')]
        rng = random.Random(f'wz4-{c}')
        rng.shuffle(texte)
        ids = 'abcd'
        bausteine = [{'id': ids[i], 'text': t.format(c=c)} for i, (_, t) in enumerate(texte)]
        rolle_id = {k: ids[i] for i, (k, _) in enumerate(texte)}
        payload = {'format': 'bausteine', 'bausteine': bausteine, 'anzahl': 1}
        loes = {'gewaehlt': [rolle_id['r']]}
        fb = [{'key': 'qf_wurzel_aus_negativ', 'gewaehlt': [rolle_id['f']]}]
        weg = [f'x² = −{c}', 'Ein Quadrat ist nie negativ: x² ≥ 0 für jede Zahl x.', f'Also gibt es kein x mit x² = −{c}.',
               'L = { }']
        return Instanz(self.key, rolle, stufe, params, self.text.format(c=c), 'BAUSTEINE', payload, loes, fb,
                       list(self.hinweis_vorlagen), weg)

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        # Begründungsbausteine: keine Rechenprüfung (Konzept §5); hier zählen Blindlöser und Lena.
        return inst.loesung


BAUFORM = WZ4()
