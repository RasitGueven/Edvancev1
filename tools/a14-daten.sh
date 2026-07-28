#!/usr/bin/env bash
# a14-daten.sh — ergänzt A14 um die Stammdaten, die pg_dump --schema-only weggelassen hat.
#
# A14 legt skills, skill_kante, themen und skill_voraussetzung an UND befüllt sie.
# Die Rekonstruktion aus dem Schema-Abzug enthält nur die Struktur.
#
# Zeilen, die spätere Migrationen selbst einfügen (A18: die Geometrie-Skills),
# werden ausgenommen — sonst legt A18 sie ein zweites Mal an und seine eigene
# Selbstprüfung schlägt fehl.
#
#   bash tools/a14-daten.sh          # zeigt, was käme
#   bash tools/a14-daten.sh --apply

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"
[[ -n "${DBURL:-}" ]] || { echo "DBURL nicht gesetzt."; exit 1; }

APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
A14="supabase/migrations/20260722130000_a14_skill_substrat.sql"
TABELLEN=(skills themen skill_kante skill_voraussetzung)

# ── Was fügen spätere Migrationen selbst ein ────────────────────────────────
echo
echo "══ Skill-Keys aus späteren Migrationen"

SPAETER=$(mktemp)
for f in supabase/migrations/*.sql; do
  v=$(basename "$f" | cut -d_ -f1)
  [[ "$v" > "20260722130000" ]] || continue
  grep -oiE "insert into (public\.)?skills\b" "$f" >/dev/null 2>&1 || continue
  # skill_key ist die erste Spalte: erstes Literal je values-Zeile
  sed -n "/insert into \(public\.\)\?skills/,/;/p" "$f" \
    | grep -oE "\('[a-z0-9_]+'" | tr -d "('" >> "$SPAETER"
done
sort -u -o "$SPAETER" "$SPAETER"

if [[ -s "$SPAETER" ]]; then
  echo "  $(wc -l < "$SPAETER") Key(s) werden ausgenommen:"
  sed 's/^/      /' "$SPAETER"
else
  echo "  keine — dann wandern alle Zeilen nach A14"
fi

# ── Daten ziehen ────────────────────────────────────────────────────────────
echo
echo "══ Daten aus Produktion"

ROH=$(mktemp)
ARGS=(); for t in "${TABELLEN[@]}"; do ARGS+=(--table "public.$t"); done
pg_dump "$DBURL" --data-only --inserts "${ARGS[@]}" 2>/dev/null \
  | grep -E '^INSERT INTO' > "$ROH"

GEFILTERT=$(mktemp)
if [[ -s "$SPAETER" ]]; then
  grep -vFf <(sed "s/^/'/; s/$/'/" "$SPAETER") "$ROH" > "$GEFILTERT"
else
  cp "$ROH" "$GEFILTERT"
fi

for t in "${TABELLEN[@]}"; do
  a=$(grep -c "INSERT INTO public\.$t " "$ROH" || true)
  b=$(grep -c "INSERT INTO public\.$t " "$GEFILTERT" || true)
  printf '  %-24s %4s Zeilen in Prod, %4s für A14\n' "$t" "$a" "$b"
done

if [[ "$APPLY" -eq 0 ]]; then
  echo
  echo "  Beispielzeilen:"
  head -3 "$GEFILTERT" | cut -c1-120 | sed 's/^/    /'
  echo
  echo "  Trockenlauf. Einsetzen mit: bash tools/a14-daten.sh --apply"
  exit 0
fi

# ── Anhängen ────────────────────────────────────────────────────────────────
# Reihenfolge: skills und themen zuerst, dann die verweisenden Tabellen.
{
  echo
  echo "-- Stammdaten. Aus Produktion nachgetragen; pg_dump --schema-only"
  echo "-- enthält keine Daten, deshalb fehlten sie in der Rekonstruktion."
  echo
  for t in skills themen skill_kante skill_voraussetzung; do
    n=$(grep -c "INSERT INTO public\.$t " "$GEFILTERT" || true)
    [[ "$n" -gt 0 ]] || continue
    echo "-- $t ($n Zeilen)"
    grep "INSERT INTO public\.$t " "$GEFILTERT" | sed 's/;$/ ON CONFLICT DO NOTHING;/'
    echo
  done
} >> "$A14"

echo
echo "  ✓ an $A14 angehängt ($(wc -l < "$A14") Zeilen gesamt)"
echo "  · ON CONFLICT DO NOTHING, damit ein erneuter Lauf nicht bricht"
echo
echo "  Weiter:  bash tools/neuaufbau-test.sh"
echo
rm -f "$SPAETER" "$ROH" "$GEFILTERT"
