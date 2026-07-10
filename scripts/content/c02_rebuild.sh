#!/usr/bin/env bash
# C02 - kompletter Neuaufbau des VERA-Pools aus den Quelldateien.
#
# Reihenfolge ist bindend: Phase 2 setzt die Inhaltsfelder zurueck und baut sie
# aus den Dokumenten neu auf, Phase 3 ergaenzt die Rastergrafik-Staemme,
# Phase 3b verknuepft Ankreuzpositionen mit Optionslisten, Phase 4 leitet
# Status und Matrix ab.
#
# Phase 0 ist NICHT enthalten: sie quarantaeniert den Altbestand und loescht
# data/ref_item.json - das passiert genau einmal.
#
# Nach der .doc->.docx-Konvertierung (Rasit, LibreOffice/Windows) genuegt:
#   ./scripts/content/c02_rebuild.sh
# Die 74 doc_pending-Items durchlaufen dann dieselbe Kette wie die uebrigen.
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "== Phase 1: Medien + EMF-Text =="
python3 scripts/content/c02_phase1_assets.py

echo && echo "== Phase 2: belegte Loesungen =="
python3 scripts/content/c02_phase2_ground.py

echo && echo "== Phase 3: Vision-Transkripte einarbeiten =="
python3 scripts/content/c02_phase3_worklist.py
python3 scripts/content/c02_phase3_validate.py
python3 scripts/content/c02_phase3_merge.py

echo && echo "== Phase 3b: Ankreuzposition + Optionsliste =="
python3 scripts/content/c02_phase3_mc_join.py

echo && echo "== Phase 4: Status, Matrix, Review-CSV =="
python3 scripts/content/c02_phase4_status.py

echo && echo "== Pruefungen =="
python3 scripts/content/c02_phase3_consistency.py
python3 scripts/content/c02_verify_ktags.py
python3 scripts/content/c02_abnahme.py
