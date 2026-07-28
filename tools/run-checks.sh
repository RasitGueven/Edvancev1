#!/usr/bin/env bash
# ============================================================================
# run-checks — faehrt die Pruefskripte aus supabase/checks/ gegen eine DB.
#
# Die Dateien dort sind aus Migrationen herausgeloeste Pruefharnische
# (PRUEFUNG/E2E). Sie pruefen gegen vorhandene Daten und werfen bei Fehlschlag
# eine Exception. Viele von ihnen mutieren dabei (insert/update) und bringen
# KEIN eigenes begin/rollback mit — sie liefen frueher im Transaktionsblock
# ihrer Migration. Deshalb klammert der Runner jede Datei selbst in
# begin/…/rollback: nichts wird dauerhaft geschrieben. Bringt eine Datei ihre
# eigene Transaktion mit, meldet psql dazu nur Warnungen — das ist harmlos.
#
# Verbindung: $DBURL (psql-URL). Ohne DBURL bricht der Runner ab.
#
# Leere Datenbank: ein Teil der Pruefungen braucht Produktionsdaten
# (Schueler, Aufgaben, Admin-Profil). Fehlt diese Grundlage, sind Fehlschlaege
# erwartet und kein echter Befund. Der Runner probt die Grundlage einmal vorab
# und meldet die Fehlschlaege dann als "uebersprungen" statt als
# "fehlgeschlagen" — der Lauf bleibt gruen, die Zeilen bleiben sichtbar.
#
# Usage:
#   bash tools/run-checks.sh --list       # gefundene Pruefskripte auflisten
#   DBURL='postgresql://…' bash tools/run-checks.sh
#
# Exit: 0 = alles ok · 1 = mindestens eine Pruefung fehlgeschlagen
#       2 = Aufrufproblem (Argument, DBURL, psql, Datenbank nicht nutzbar)
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/.."

CHECK_DIR="supabase/checks"

if [ -t 1 ]; then
  B=$'\033[1m'; R=$'\033[31m'; G=$'\033[32m'; Y=$'\033[33m'; N=$'\033[0m'
else
  B=''; R=''; G=''; Y=''; N=''
fi

usage() {
  cat <<'EOF'
Usage:
  bash tools/run-checks.sh --list       gefundene Pruefskripte auflisten
  DBURL='postgresql://…' bash tools/run-checks.sh
                                        alle Pruefskripte laufen lassen
EOF
}

# --- Pruefskripte einsammeln ------------------------------------------------
CHECKS=()
if [ -d "$CHECK_DIR" ]; then
  while IFS= read -r f; do
    CHECKS+=("$f")
  done < <(find "$CHECK_DIR" -maxdepth 1 -type f -name '*.sql' | sort)
fi

# --- Argumente --------------------------------------------------------------
if [ "$#" -gt 1 ]; then
  echo "zu viele Argumente" >&2
  usage >&2
  exit 2
fi

case "${1:-}" in
  --list)
    if [ "${#CHECKS[@]}" -eq 0 ]; then
      echo "keine Pruefskripte in $CHECK_DIR/"
    else
      printf '%s\n' "${CHECKS[@]}"
    fi
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  '')
    ;;
  *)
    echo "unbekanntes Argument: $1" >&2
    usage >&2
    exit 2
    ;;
esac

# --- Voraussetzungen fuer den Lauf ------------------------------------------
if [ -z "${DBURL:-}" ]; then
  echo "${R}DBURL ist nicht gesetzt — ohne Verbindung laeuft keine Pruefung.${N}" >&2
  echo "  DBURL='postgresql://…' bash tools/run-checks.sh" >&2
  exit 2
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "${R}psql nicht gefunden — bitte den PostgreSQL-Client installieren.${N}" >&2
  exit 2
fi

if [ "${#CHECKS[@]}" -eq 0 ]; then
  echo "keine Pruefskripte in $CHECK_DIR/ — nichts zu tun."
  exit 0
fi

PSQL=(psql "$DBURL" -X -q -P pager=off -v ON_ERROR_STOP=1)

# --- Datengrundlage proben --------------------------------------------------
# Eine Abfrage, drei Zahlen: ohne Schueler, Aufgaben oder Admin-Profil koennen
# die Pruefungen ihre Faelle nicht aufbauen.
probe=$("${PSQL[@]}" -At -c "select (select count(*) from public.students)
                                || ' ' || (select count(*) from public.tasks)
                                || ' ' || (select count(*) from public.profiles where role = 'admin')" 2>&1)
probe_rc=$?
read -r n_students n_tasks n_admins <<<"$probe"
if [ "$probe_rc" -ne 0 ] || ! [[ "${n_admins:-}" =~ ^[0-9]+$ ]]; then
  printf '%s\n' "$probe" >&2
  echo "${R}Datenbank nicht nutzbar — Verbindung fehlgeschlagen oder Edvance-Schema fehlt.${N}" >&2
  exit 2
fi

datenarm=0
if [ "$n_students" -eq 0 ] || [ "$n_tasks" -eq 0 ] || [ "$n_admins" -eq 0 ]; then
  datenarm=1
  printf '%sDatenbank ohne Produktionsdaten%s (students=%s, tasks=%s, admins=%s) — Fehlschlaege gelten als uebersprungen.\n\n' \
    "$Y" "$N" "$n_students" "$n_tasks" "$n_admins"
fi

# --- Lauf -------------------------------------------------------------------
printf '%s%d Pruefskript(e) aus %s/%s\n\n' "$B" "${#CHECKS[@]}" "$CHECK_DIR" "$N"

n_ok=0
n_fail=0
n_skip=0

for f in "${CHECKS[@]}"; do
  printf '  %-62s ' "$(basename "$f")"
  # -c/-f laufen in der angegebenen Reihenfolge in derselben Sitzung. Bricht die
  # Datei ab, beendet ON_ERROR_STOP psql sofort — die offene Transaktion faellt
  # mit der Verbindung, geschrieben wird auch dann nichts.
  out=$("${PSQL[@]}" -c 'begin;' -f "$f" -c 'rollback;' 2>&1)
  rc=$?

  if [ "$rc" -eq 0 ]; then
    printf '%sok%s\n' "$G" "$N"
    n_ok=$((n_ok + 1))
  elif [ "$datenarm" -eq 1 ]; then
    printf '%suebersprungen (keine Produktionsdaten)%s\n' "$Y" "$N"
    n_skip=$((n_skip + 1))
    printf '%s\n' "$out" | grep -m1 -E 'FEHLER|ERROR' | sed 's/^/      /'
  else
    printf '%sfehlgeschlagen%s\n' "$R" "$N"
    n_fail=$((n_fail + 1))
    printf '%s\n' "$out" | tail -n 20 | sed 's/^/      /'
  fi
done

# --- Zusammenfassung --------------------------------------------------------
printf '\n%s%d Pruefung(en): %d ok, %d fehlgeschlagen, %d uebersprungen%s\n' \
  "$B" "${#CHECKS[@]}" "$n_ok" "$n_fail" "$n_skip" "$N"

if [ "$n_fail" -gt 0 ]; then
  printf '%srun-checks ROT%s\n' "$R" "$N"
  exit 1
fi
if [ "$n_skip" -gt 0 ]; then
  printf '%srun-checks gruen, aber %d Pruefung(en) ohne Datengrundlage nicht bewiesen.%s\n' "$Y" "$n_skip" "$N"
  exit 0
fi
printf '%srun-checks GRUEN%s\n' "$G" "$N"
exit 0
