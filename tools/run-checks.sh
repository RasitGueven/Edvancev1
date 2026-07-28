#!/usr/bin/env bash
# ============================================================================
# run-checks — fuehrt die Pruefharnische aus supabase/checks/ gegen eine DB aus.
#
# Die Dateien dort sind aus Migrationen herausgeloeste Harnische (PRUEFUNG/E2E).
# Sie pruefen gegen vorhandene Daten und werfen bei Fehlschlag eine Exception.
#
# Jede Datei laeuft in begin/…/rollback — der Lauf hinterlaesst nichts in der
# Datenbank. Dateien, die ihren eigenen Transaktionsblock mitbringen, erzeugen
# dabei eine harmlose WARNING ("there is already a transaction in progress").
# Aufgerufen wird immer mit `psql -f <datei>`, damit `\ir`-Includes relativ zur
# Pruefdatei aufloesen.
#
# Usage:
#   DBURL='postgresql://…' bash tools/run-checks.sh     # alle Pruefungen
#   bash tools/run-checks.sh --list                     # nur auflisten
#
# Exit: 0 alles gruen · 1 mindestens eine Pruefung fehlgeschlagen · 2 Aufruf-
#       oder Verbindungsfehler
#
# Leere Datenbank: manche Pruefungen brauchen Produktionsdaten. Der Lauf probt
# die Datenlage vorab; ist sie leer, werden Fehlschlaege als "leere DB"
# markiert — sie sind dann kein Beleg fuer einen Defekt.
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/.."

CHECKS_DIR="${CHECKS_DIR:-supabase/checks}"

if [ -t 1 ]; then C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else C_RED=''; C_GRN=''; C_DIM=''; C_OFF=''; fi

die() { printf '%srun-checks: %s%s\n' "$C_RED" "$1" "$C_OFF" >&2; exit "${2:-2}"; }

usage() {
  printf 'Usage: DBURL=… bash tools/run-checks.sh [--list]\n'
  printf '  --list   gefundene Pruefskripte auflisten (braucht kein DBURL)\n'
}

# ── Pruefskripte einsammeln (Zeitstempel-Praefix = Reihenfolge) ──────────────
checks=()
if [ -d "$CHECKS_DIR" ]; then
  while IFS= read -r f; do checks+=("$f"); done \
    < <(find "$CHECKS_DIR" -maxdepth 1 -type f -name '*.sql' | LC_ALL=C sort)
fi

case "${1:-}" in
  --list)
    if [ ${#checks[@]} -eq 0 ]; then echo "keine Pruefskripte in $CHECKS_DIR/"
    else printf '%s\n' "${checks[@]}"; fi
    exit 0 ;;
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) usage >&2; die "unbekannte Option: $1" ;;
esac

# ── Vorbedingungen ──────────────────────────────────────────────────────────
[ -n "${DBURL:-}" ] || die "DBURL ist nicht gesetzt. Beispiel: DBURL='postgresql://…' bash tools/run-checks.sh"
command -v psql >/dev/null 2>&1 || die "psql nicht gefunden — PostgreSQL-Client installieren."
if [ ${#checks[@]} -eq 0 ]; then echo "keine Pruefskripte in $CHECKS_DIR/ — nichts zu tun."; exit 0; fi

if ! conn_err=$(psql "$DBURL" -X -Atqc 'select 1' 2>&1 >/dev/null); then
  die "keine Verbindung zur Datenbank aus \$DBURL — $conn_err"
fi

# Datenlage: schlaegt die Probe fehl (Tabellen fehlen), bleibt sie unbekannt.
datenlage=$(psql "$DBURL" -X -Atqc \
  'select (select count(*) from public.students) + (select count(*) from public.tasks)' 2>/dev/null) || datenlage=''
leere_db=0
if [ "$datenlage" = "0" ]; then
  leere_db=1
  printf '%sHinweis: students und tasks sind leer — datenabhaengige Pruefungen schlagen hier erwartungsgemaess fehl.%s\n\n' "$C_DIM" "$C_OFF"
fi

# ── Lauf ────────────────────────────────────────────────────────────────────
ok=0; fehl=0; fehlgeschlagen=()
for f in "${checks[@]}"; do
  name=$(basename "$f")
  printf '── %-58s ' "$name"
  if out=$(psql "$DBURL" -X -v ON_ERROR_STOP=1 -q -P pager=off \
             -c 'begin;' -f "$f" -c 'rollback;' 2>&1); then
    printf '%sok%s\n' "$C_GRN" "$C_OFF"
    ok=$((ok + 1))
  else
    if [ "$leere_db" -eq 1 ]; then printf '%sfehlgeschlagen (leere DB)%s\n' "$C_RED" "$C_OFF"
    else printf '%sfehlgeschlagen%s\n' "$C_RED" "$C_OFF"; fi
    fehl=$((fehl + 1)); fehlgeschlagen+=("$name")
    printf '%s\n' "$out" | tail -n 20 | sed 's/^/     /'
  fi
done

# ── Zusammenfassung ─────────────────────────────────────────────────────────
printf '\n%d Pruefungen · %d ok · %d fehlgeschlagen\n' "${#checks[@]}" "$ok" "$fehl"
for name in ${fehlgeschlagen[@]+"${fehlgeschlagen[@]}"}; do printf '  ✗ %s\n' "$name"; done
if [ "$fehl" -gt 0 ] && [ "$leere_db" -eq 1 ]; then
  printf '%sDie Datenbank aus $DBURL enthaelt keine Produktionsdaten. Fehlschlaege oben sind\ndamit erklaerbar und kein Beleg fuer einen Defekt — gegen eine befuellte DB wiederholen.%s\n' "$C_DIM" "$C_OFF"
fi
[ "$fehl" -eq 0 ] || exit 1
