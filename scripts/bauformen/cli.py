#!/usr/bin/env python3
"""
tools/bauform.sh — erzeugt, prueft und exportiert Bauformen (Sessionreihe 1, A4.5).

  bauform.sh <KEY>                     erzeugen, Pruefmaschine (inkl. Wertung gegen Prod, lesend), Vorschau-JSON,
                                       Kindertexte fuer den Blindloeser (docs/reihe1/A/blindloeser/<KEY>/aufgaben.md)
  bauform.sh <KEY> --blind <datei>     Antworten des Blindloesers ({"1": "…", …}) auswerten, dann Migration schreiben
  bauform.sh --skill <skill>           alle Bauformen eines Skills (Schritt 1)
  bauform.sh --alle                    alle Bauformen (Schritt 1)

Den Blindloeser startet der Orchestrator als frischen Subagenten (das Skript kann keinen starten).
"""

from __future__ import annotations

import argparse
import importlib
import json
import pkgutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from bauformen import bauformen as paket  # noqa: E402
from bauformen.export import blind_auswerten, blindaufgaben, migration, vorschau  # noqa: E402
from bauformen.pruefmaschine import gruene, pruefen  # noqa: E402


def alle():
    for m in sorted(pkgutil.iter_modules(paket.__path__), key=lambda m: m.name):
        mod = importlib.import_module(f'bauformen.bauformen.{m.name}')
        if hasattr(mod, 'BAUFORM'):
            yield mod.BAUFORM


def schritt1(bf) -> None:
    inst = bf.alle_instanzen()
    proto = pruefen(bf, inst)
    vorschau(bf, inst, proto)
    datei = blindaufgaben(bf)
    print(f'{bf.key}: {len(inst)} erzeugt, {proto["gruen"]} grün, {proto["rot"]} rot {proto["gruende"]}'
          f'{" — VERDACHT " + proto["verdacht"] if proto["verdacht"] else ""}; Blindlöser: {datei}')
    if len(gruene(inst)) == 0:
        print(f'{bf.key}: keine grüne Instanz')


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('key', nargs='?')
    ap.add_argument('--skill')
    ap.add_argument('--alle', action='store_true')
    ap.add_argument('--blind')
    a = ap.parse_args()
    formen = {bf.key: bf for bf in alle()}
    if a.blind:
        bf = formen[a.key]
        befund = blind_auswerten(bf, json.loads(Path(a.blind).read_text()))
        print(f'{bf.key}: Blindlöser {befund["geloest"]} gelöst, abweichend {befund["abweichend"]}, '
              f'{"bestanden" if befund["bestanden"] else "NICHT bestanden"}')
        print(f'Migration: {migration(bf)}')
        return 0
    auswahl = [formen[a.key]] if a.key else [b for b in formen.values() if a.alle or b.skill == a.skill]
    if not auswahl:
        print('keine Bauform gewählt'); return 2
    for bf in auswahl:
        schritt1(bf)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
