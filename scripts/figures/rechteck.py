#!/usr/bin/env python3
"""
Python-Adapter fuer den TypeScript-Generator `rechteck.ts`.

upload_figures.py laedt Generatoren als Python-Module (`figures.<name>.zeichne`).
Der Rechteck-Generator ist bewusst TypeScript (siehe Kopf von rechteck.ts). Statt
ihn ein zweites Mal in Python zu schreiben — zwei Implementierungen derselben
Figur koennten auseinanderlaufen —, ruft dieser Adapter ihn ueber tsx auf
(rechteck_cli.ts). Voraussetzung: `npm ci` im Repo, dann liegt
node_modules/.bin/tsx bereit.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
TSX = WURZEL / 'node_modules' / '.bin' / 'tsx'
CLI = Path(__file__).resolve().parent / 'rechteck_cli.ts'


def zeichne(params: dict, theme: str) -> str:
    """Schnittstelle fuer upload_figures.py: `rechteck.zeichne(params, theme) -> str`."""
    if not TSX.is_file():
        raise ValueError(f'{TSX} fehlt — vorher `npm ci` im Repo ausfuehren.')
    ergebnis = subprocess.run(
        [str(TSX), str(CLI)],
        input=json.dumps({'params': params, 'theme': theme}, ensure_ascii=False),
        capture_output=True, text=True, cwd=WURZEL, check=False,
    )
    if ergebnis.returncode != 0:
        raise ValueError(f'rechteck.ts: {ergebnis.stderr.strip()}')
    return ergebnis.stdout


__all__ = ['zeichne']
