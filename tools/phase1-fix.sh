#!/usr/bin/env bash
# phase1-fix.sh — ersetzt Phase 1 aus runbook.sh.
#
# Zwei Korrekturen gegenüber dem Original:
#   1. Prüfskripte (.PRUEFUNG.sql, .E2E.sql) sind keine Migrationen und gehen nach
#      supabase/checks/ — nicht nach migrations/, nicht in schema_migrations.
#   2. Der Zeitstempel im Dateinamen bleibt erhalten. Er ist der Schlüssel zum
#      Historieneintrag; neu vergeben zerreisst den Bezug unwiederbringlich.
#
#   bash phase1-fix.sh            # zeigt den Plan, ändert nichts
#   bash phase1-fix.sh --apply    # führt aus, mit Rückfrage je Schritt

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
# Verbindung. Der Text hinter :? wird von der Shell EXPANDIERT — dort darf keine
# Kommandosubstitution stehen, sonst landet der Zugangsstring bei jedem
# Fehlschlag im Terminal. Der Weg zum Wert:
#   export DATABASE_URL="$(grep '^DATABASE_URL=' .env | cut -d= -f2- | tr -d "'\"")"
: "${DATABASE_URL:?nicht gesetzt (frueher DBURL) — siehe Kommentar in diesem Skript}"

ok(){ echo "  ✓ $*"; }; warn(){ echo "  ! $*"; }; bad(){ echo "  ✗ $*"; }; info(){ echo "  · $*"; }
frage(){ [[ "$APPLY" -eq 1 ]] || return 1; local a; read -rp "  → $1 [j/N] " a </dev/tty; [[ "$a" =~ ^[jJyY]$ ]]; }

APPLIED=$(psql "$DATABASE_URL" -tAc "select version from supabase_migrations.schema_migrations order by version")
ist_eingespielt(){ grep -qx "$1" <<<"$APPLIED"; }

echo
echo "══ Klassifizierung von supabase/pending/"
echo

MIGRATIONEN=(); CHECKS=(); UNKLAR=()

for f in supabase/pending/*.sql; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  version="${base%%_*}"

  # DDL an persistenten Objekten? Temporäre Tabellen zählen nicht.
  ddl=$(grep -icE '^[[:space:]]*(create|alter|drop)[[:space:]]+(table|type|function|view|index|policy|trigger|schema|extension)' "$f" || true)
  tmp=$(grep -icE '^[[:space:]]*create[[:space:]]+(temp|temporary)' "$f" || true)
  ddl=$(( ddl - tmp ))
  namen_check=0
  [[ "$base" == *.PRUEFUNG.sql || "$base" == *.E2E.sql ]] && namen_check=1

  printf '  %-52s ' "$base"
  if [[ "$namen_check" -eq 1 && "$ddl" -le 0 ]]; then
    echo "→ Prüfskript"; CHECKS+=("$f")
  elif [[ "$namen_check" -eq 0 && "$ddl" -gt 0 ]]; then
    st=$(ist_eingespielt "$version" && echo "bereits eingespielt" || echo "noch nicht eingespielt")
    echo "→ Migration ($st)"; MIGRATIONEN+=("$f")
  else
    echo "→ UNKLAR (Name sagt $( ((namen_check)) && echo Prüfskript || echo Migration ), Inhalt hat $ddl DDL-Anweisung(en))"
    UNKLAR+=("$f")
  fi
done

if [[ ${#UNKLAR[@]} -gt 0 ]]; then
  echo
  bad "Name und Inhalt widersprechen sich. Diese Dateien selbst ansehen:"
  for f in "${UNKLAR[@]}"; do echo "      less $f"; done
  echo "     Danach umbenennen oder von Hand einsortieren, dann erneut starten."
  exit 1
fi

# ── Prüfskripte ─────────────────────────────────────────────────────────────
echo
echo "══ Prüfskripte → supabase/checks/"
echo
if [[ ${#CHECKS[@]} -eq 0 ]]; then info "keine"; else
  for f in "${CHECKS[@]}"; do echo "      $(basename "$f")"; done
  echo
  info "Werden NICHT eingespielt und NICHT in schema_migrations eingetragen."
  if frage "Verschieben?"; then
    mkdir -p supabase/checks
    for f in "${CHECKS[@]}"; do git mv "$f" "supabase/checks/$(basename "$f")" && ok "$(basename "$f")"; done
  fi
fi

# ── Migrationen ─────────────────────────────────────────────────────────────
echo
echo "══ Migrationen → supabase/migrations/"
echo
for f in "${MIGRATIONEN[@]}"; do
  base=$(basename "$f"); version="${base%%_*}"
  ziel="supabase/migrations/$base"

  echo "  ── $base"

  if [[ ! "$version" =~ ^[0-9]{14}$ ]]; then
    bad "kein 14-stelliger Zeitstempel — von Hand klären, übersprungen"; continue
  fi
  if [[ -e "$ziel" ]]; then bad "$ziel existiert bereits — übersprungen"; continue; fi

  if ist_eingespielt "$version"; then
    ok "Version $version ist eingespielt — nur die Datei fehlt am richtigen Ort."
    info "Name bleibt unverändert, sonst reisst der Bezug zur Historie."
    frage "Verschieben (ohne Einspielen)?" && { git mv "$f" "$ziel" && ok "verschoben"; }
  else
    warn "Version $version ist NICHT eingespielt."
    echo "     ── erste 25 Zeilen ──"
    head -25 "$f" | sed 's/^/       /'
    echo "     ─────────────────────"
    if frage "Verschieben und in PRODUKTION einspielen?"; then
      git mv "$f" "$ziel" && scripts/db-migrate.sh "$ziel" || bad "gescheitert — angehalten"
    fi
  fi
  echo
done

# ── Rest ────────────────────────────────────────────────────────────────────
echo "══ Danach noch offen"
echo
FEHLT=()
while IFS= read -r v; do
  [[ -n "$v" ]] || continue
  ls supabase/migrations/"${v}"_*.sql >/dev/null 2>&1 || FEHLT+=("$v")
done <<<"$APPLIED"

if [[ ${#FEHLT[@]} -eq 0 ]]; then
  ok "Kein Drift mehr — weiter mit: bash runbook.sh --from 2"
else
  bad "${#FEHLT[@]} eingespielte Version(en) ohne Datei im Repo:"
  for v in "${FEHLT[@]}"; do
    n=$(psql "$DATABASE_URL" -tAc "select coalesce(name,'(ohne Namen)') from supabase_migrations.schema_migrations where version='$v'")
    echo "      $v  $n"
  done
  echo
  info "Diese brauchen Rekonstruktion aus dem Prod-Schema. Vorher kommt runbook.sh"
  info "in Phase 3 nicht durch — zu Recht."
fi

[[ "$APPLY" -eq 0 ]] && { echo; info "Trockenlauf. Ausführen mit: bash phase1-fix.sh --apply"; }
echo
