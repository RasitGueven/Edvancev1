#!/usr/bin/env bash
# inspect-pending.sh — zeigt je Datei in supabase/pending/, was drinsteht.
# Entscheidet nichts. Liefert die Belege, damit du in einem Blick einordnen kannst.
#
#   bash inspect-pending.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

APPLIED=""
[[ -n "${DATABASE_URL:-}" ]] && APPLIED=$(psql "$DATABASE_URL" -tAc \
  "select version from supabase_migrations.schema_migrations" 2>/dev/null)

# Kommentare und Leerzeilen raus, damit die Zählung stimmt
entkommentiert() { sed -e 's|--.*$||' -e '/^[[:space:]]*$/d' "$1"; }

zaehl() { grep -icE "$2" <<<"$1" || true; }

for f in supabase/pending/*.sql; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f"); version="${base%%_*}"
  txt=$(entkommentiert "$f")

  echo
  echo "══════════════════════════════════════════════════════════════════"
  echo "  $base"
  echo "  $(wc -l < "$f") Zeilen$( [[ -n "$APPLIED" ]] && { grep -qx "$version" <<<"$APPLIED" \
      && echo "  ·  Version $version IST eingespielt" \
      || echo "  ·  Version $version ist NICHT eingespielt"; } )"
  echo "──────────────────────────────────────────────────────────────────"

  # Schreibende Anweisungen an bleibenden Objekten
  ct=$(zaehl "$txt" '^[[:space:]]*create[[:space:]]+(table|type|schema|extension)')
  cf=$(zaehl "$txt" '^[[:space:]]*create[[:space:]]+(or[[:space:]]+replace[[:space:]]+)?(function|view|index|policy|trigger)')
  cx=$(zaehl "$txt" '^[[:space:]]*create[[:space:]]+(temp|temporary)')
  al=$(zaehl "$txt" '^[[:space:]]*alter[[:space:]]')
  dr=$(zaehl "$txt" '^[[:space:]]*drop[[:space:]]')
  ins=$(zaehl "$txt" '^[[:space:]]*insert[[:space:]]+into')
  upd=$(zaehl "$txt" '^[[:space:]]*(update|delete)[[:space:]]')
  gr=$(zaehl "$txt" '^[[:space:]]*(grant|revoke)[[:space:]]')

  # Prüf-Merkmale
  sel=$(zaehl "$txt" '^[[:space:]]*select[[:space:]]')
  ex=$(zaehl "$txt" 'raise[[:space:]]+(exception|notice)')
  as=$(zaehl "$txt" '\bassert\b')
  do_=$(zaehl "$txt" 'do[[:space:]]*\$\$')
  rb=$(zaehl "$txt" '^[[:space:]]*rollback')

  z() { [[ "$2" -gt 0 ]] && printf '      %-34s %s\n' "$1" "$2"; }
  echo "    schreibt:"
  z "create table/type/schema"  "$ct"
  z "create function/view/index" "$cf"
  z "create TEMP"                "$cx"
  z "alter"                      "$al"
  z "drop"                       "$dr"
  z "insert into"                "$ins"
  z "update / delete"            "$upd"
  z "grant / revoke"             "$gr"
  [[ $((ct+cf+al+dr+ins+upd+gr)) -eq 0 ]] && echo "      (nichts)"

  echo "    prüft:"
  z "select"            "$sel"
  z "raise"             "$ex"
  z "assert"            "$as"
  z "do \$\$-Block"     "$do_"
  z "rollback"          "$rb"
  [[ $((sel+ex+as+do_+rb)) -eq 0 ]] && echo "      (nichts)"

  # Vorschlag
  bleibend=$((ct+cf+al+dr+ins+upd+gr))
  echo
  if [[ "$rb" -gt 0 ]]; then
    echo "    → vermutlich PRÜFSKRIPT  (macht rollback — hinterlässt nichts)"
  elif [[ "$bleibend" -gt 0 && $((ex+as)) -eq 0 ]]; then
    echo "    → vermutlich MIGRATION  (ändert bleibenden Zustand, keine Assertions)"
  elif [[ "$bleibend" -eq 0 ]]; then
    echo "    → vermutlich PRÜFSKRIPT  (ändert nichts Bleibendes)"
  else
    echo "    → BEIDES  (ändert bleibenden Zustand UND prüft) — die musst du trennen"
  fi

  echo
  echo "    erste 8 Anweisungen:"
  grep -nE '^[[:space:]]*(create|alter|drop|insert|update|delete|grant|revoke|select|do|begin|rollback|commit)' \
    <(sed 's|--.*$||' "$f") | head -8 | sed 's/^/      /' | cut -c1-100
done

cat <<'EOF'

══════════════════════════════════════════════════════════════════

  Die Frage je Datei ist nicht "steht DDL drin", sondern:

    Muss das laufen, damit eine leere Datenbank denselben Zustand erreicht?
      ja   → Migration    → supabase/migrations/, Zeitstempel behalten
      nein → Prüfskript   → supabase/checks/, nicht in schema_migrations

  Ein Prüfskript darf durchaus Objekte anlegen (Testhelfer) — entscheidend ist,
  ob es sie wieder abräumt oder ob der Zustand bleiben soll.

  Randnotiz: a21_freigabe_muster.sql und a21_freigabe_muster.PRUEFUNG.sql tragen
  denselben Zeitstempel 20260723160000. Zwei Dateien mit derselben Version gehen
  nicht — ein Grund mehr, Prüfskripte ohne Migrations-Zeitstempel zu benennen.

  Einordnung von Hand:

    mkdir -p supabase/checks
    git mv supabase/pending/<datei>.sql supabase/checks/      # Prüfskript
    git mv supabase/pending/<datei>.sql supabase/migrations/  # Migration, Name behalten

  Danach:  bash phase1-fix.sh
EOF
