"""QW-1 · Quadratzahlen und Wurzeln bis 20² (zahl_wurzel_quadrat). Zahl.
S1 n² mit n von 3 bis 12 · S2 √m mit m = n², n von 3 bis 15 · S3 (−n)² mit n von 3 bis 20. Rollen W Ü H."""

from __future__ import annotations

import random

from ..basis import Bauform, Instanz, ersetze, zahl_antwort
from ..klassisch import zahl_payload
from ..rechnen import ausdruck


class QW1(Bauform):
    key = 'QW-1'
    skill = 'zahl_wurzel_quadrat'
    format = 'zahl'
    rollen = ('warmup', 'uebung', 'home')
    stufen = {1: 'n², n von 3 bis 12', 2: '√m, m Quadratzahl von 9 bis 225', 3: '(−n)², n von 3 bis 20'}
    text = 'Berechne {aufgabe}.'
    fehlbild_steckbrief = [
        {'key': 'qf_quadrat_als_verdopplung', 'regel': 'n² als 2·n', 'gilt_fuer_stufen': [1, 3],
         'rueckmeldung': 'Quadrieren heißt: die Zahl mit sich selbst malnehmen, nicht mit 2.'},
        {'key': 'qf_wurzel_als_haelfte', 'regel': '√m als m/2', 'gilt_fuer_stufen': [2],
         'rueckmeldung': 'Die Wurzel ist nicht die Hälfte. Welche Zahl mal sich selbst ergibt die Zahl?'},
        {'key': 'qf_quadrat_negativ', 'regel': '(−n)² = −n²', 'gilt_fuer_stufen': [3],
         'rueckmeldung': 'Minus mal Minus ergibt Plus. Ein Quadrat ist nie negativ.'},
    ]
    hinweis_vorlagen = ['{frage_hinweis}', '{strategie}', '{schritt}']
    loesungsweg_vorlage = ['{aufgabe}', '= {rechnung}', '= {ergebnis}']
    zeit_sek = 30

    def parameter(self, stufe: int, rng: random.Random) -> dict:
        return {'n': rng.randint(3, {1: 12, 2: 15, 3: 20}[stufe])}

    def erzeugen(self, params: dict, rolle: str, stufe: int) -> Instanz:
        n = params['n']
        if stufe == 1:
            aufg, erg, rechnung = f'{n}²', n * n, f'{n} · {n}'
            h = ['Was bedeutet die kleine 2 oben?', 'Nimm die Zahl mit sich selbst mal.', f'Rechne {n} · {n}.']
            fb = [{'key': 'qf_quadrat_als_verdopplung', 'wert': zahl_antwort(2 * n)}]
        elif stufe == 2:
            aufg, erg, rechnung = f'√{n * n}', n, f'√({n} · {n})'
            h = ['Welche Zahl mal sich selbst ergibt die Zahl unter der Wurzel?', 'Denk an die Quadratzahlen.',
                 'Probier Zahlen aus und rechne sie mal sich selbst.']
            m = n * n
            fb = [{'key': 'qf_wurzel_als_haelfte', 'wert': zahl_antwort(m // 2) if m % 2 == 0 else f'{m}/2'}]
        else:
            aufg, erg, rechnung = f'(−{n})²', n * n, f'(−{n}) · (−{n})'
            h = ['Was bedeutet die kleine 2 hinter der Klammer?', 'Die ganze Klammer wird mit sich selbst malgenommen.',
                 f'Rechne (−{n}) · (−{n}). Welches Vorzeichen hat das Ergebnis?']
            fb = [{'key': 'qf_quadrat_als_verdopplung', 'wert': zahl_antwort(-2 * n)},
                  {'key': 'qf_quadrat_negativ', 'wert': zahl_antwort(-n * n)}]
        w = {'aufgabe': aufg, 'rechnung': rechnung, 'ergebnis': str(erg),
             'frage_hinweis': h[0], 'strategie': h[1], 'schritt': h[2]}
        frage = ersetze(self.text, w)
        return Instanz(self.key, rolle, stufe, params, frage, 'NUMERIC', zahl_payload(frage),
                       {'werte': [str(erg), f'+{erg}']}, fb, h, [ersetze(z, w) for z in self.loesungsweg_vorlage])

    def loesen_unabhaengig(self, inst: Instanz) -> dict:
        wert = ausdruck(inst.frage.removeprefix('Berechne ').removesuffix('.'))
        return {'werte': [str(int(wert))]}

    def angenehm(self, inst: Instanz) -> str | None:
        n = inst.params['n']
        return None if 3 <= n <= {1: 12, 2: 15, 3: 20}[inst.stufe] else 'Zahl ausserhalb der Stufe'


BAUFORM = QW1()
