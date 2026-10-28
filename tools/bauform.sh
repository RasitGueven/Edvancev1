#!/usr/bin/env bash
# bauform.sh — Bauformen der Sessionreihe 1 erzeugen, pruefen, exportieren (scripts/bauformen/cli.py).
#   bash tools/bauform.sh <KEY> | --skill <skill> | --alle      Schritt 1: erzeugen, Pruefmaschine, Blindloeser-Texte
#   bash tools/bauform.sh <KEY> --blind <antworten.json>         Schritt 2: Blindloeser auswerten, Migration schreiben
# sympy liegt lokal: python3 -m pip install --target scripts/bauformen/.pydeps sympy
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[ -d scripts/bauformen/.pydeps ] || { echo "sympy fehlt: python3 -m pip install --target scripts/bauformen/.pydeps sympy"; exit 1; }
PYTHONPATH="scripts/bauformen/.pydeps" python3 scripts/bauformen/cli.py "$@"
