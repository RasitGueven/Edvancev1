#!/usr/bin/env bash
# Führt eine Abfrage read-only über dbread aus: ./lauf.sh 05  (stellt die in der Datei genannten Blöcke voran)
set -euo pipefail
cd "$(dirname "$0")"
q=$(ls q"$1"_*.sql)
tmp=$(mktemp)
for b in $(sed -n 's/^-- braucht: //p' "$q"); do cat "$b" >> "$tmp"; done
cat "$q" >> "$tmp"
~/bin/dbread -f "$tmp"
rm -f "$tmp"
