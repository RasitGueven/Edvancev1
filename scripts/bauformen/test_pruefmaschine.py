#!/usr/bin/env python3
"""
Negativkontrollen der Pruefmaschine (Bauauftrag A4.3): Jede absichtlich kaputte Instanz MUSS an der richtigen
Pruefung rot werden — eine Pruefung, die nie anschlaegt, prueft nichts.

    PYTHONPATH=scripts/bauformen/.pydeps python3 -m pytest scripts/bauformen/test_pruefmaschine.py -q

Pruefung 4 und der LSA-Abgleich laufen lesend gegen Prod (~/bin/dbread); ohne dbread werden diese Faelle uebersprungen.
"""

from __future__ import annotations

import copy
import os
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from bauformen.bauformen.np_2 import BAUFORM as NP2  # noqa: E402
from bauformen.bauformen.wz_1 import BAUFORM as WZ1  # noqa: E402
from bauformen.pruefmaschine import pruefen  # noqa: E402

MIT_DB = os.path.exists(os.path.expanduser('~/bin/dbread'))


def instanz(bf, stufe=3, rolle='uebung', **params):
    p = {'a': 2, 'b': -10} if bf is NP2 else {'k': 6}
    p.update(params)
    return bf.erzeugen(p, rolle, stufe)


def rot(bf, inst, mit_db=False) -> dict[str, str]:
    pruefen(bf, [inst], mit_db=mit_db)
    return {k: v['grund'] for k, v in inst.pruefmaschine.items() if not v['ok']}


def test_gesunde_instanz_ist_gruen():
    assert rot(NP2, instanz(NP2)) == {}
    assert rot(WZ1, instanz(WZ1, stufe=1)) == {}


def test_falsche_loesung():
    i = instanz(NP2)
    i.loesung = {'menge': ['0', '4']}
    assert '1' in rot(NP2, i)


def test_kollidierende_fehlbilder():
    i = instanz(NP2)
    i.fehlbilder[1] = {**i.fehlbilder[1], 'menge': list(i.fehlbilder[0]['menge'])}
    assert '3' in rot(NP2, i)


def test_fehlbild_gleich_der_loesung():
    # „a übersehen“ bei a = 1 ergaebe die richtige Antwort; deshalb gilt es nur ab Stufe 3 (Konzept §3.1).
    i = instanz(NP2, stufe=1, a=1, b=-6)
    i.fehlbilder.append({'key': 'qf_a_uebersehen', 'menge': ['0', '6']})
    assert '3' in rot(NP2, i)


def test_plus_minus():
    i = instanz(NP2)
    i.frage = 'Löse 2x² + −10x = 0.'
    assert '5' in rot(NP2, i)


def test_eins_x_quadrat():
    i = instanz(NP2)
    i.frage = 'Löse 1x² − 6x = 0.'
    assert '5' in rot(NP2, i)


def test_leerer_platzhalter():
    i = instanz(NP2)
    i.hinweise[2] = 'Schreib die Gleichung als x · ({klammer}) = 0.'
    assert '5' in rot(NP2, i)


def test_ascii_minus():
    i = instanz(NP2)
    i.loesungsweg[-1] = 'L = {-5; 0}'
    assert '5' in rot(NP2, i)


def test_dublette():
    a, b = instanz(NP2), instanz(NP2)
    pruefen(NP2, [a, b], mit_db=False)
    assert b.pruefmaschine['7']['ok'] is False


def test_stufe_falsch():
    i = instanz(NP2, stufe=4)  # a = 2, b = −10 ergibt eine ganze Zahl, Stufe 4 verlangt einen Bruch
    assert '2' in rot(NP2, i)


@pytest.mark.skipif(not MIT_DB, reason='dbread fehlt')
def test_lsa_zwilling():
    # Prod hat die LSA-Aufgabe „x² − 5x = 0“ (gleichung_quadr_faktor); dieselben Zahlen sind eine Dublette.
    i = instanz(NP2, stufe=1, a=1, b=-5)
    assert '7' in rot(NP2, i, mit_db=True)


@pytest.mark.skipif(not MIT_DB, reason='dbread fehlt')
def test_wertung_echte_datenbank_findet_falsches_fehlbild():
    i = instanz(NP2)
    i.fehlbilder[0] = {**i.fehlbilder[0], 'menge': list(i.loesung['menge'])}  # Fehlbild = richtige Antwort
    r = rot(NP2, i, mit_db=True)
    assert '4' in r and '3' in r


@pytest.mark.skipif(not MIT_DB, reason='dbread fehlt')
def test_wertung_echte_datenbank_alle_schreibweisen():
    i = instanz(NP2, stufe=4, a=2, b=3)  # Lösung {−3/2; 0}, Schreibweise „−1,5“
    assert any('-1,5' in str(s) for s in i.schreibweisen)
    assert rot(NP2, copy.deepcopy(i), mit_db=True) == {}
