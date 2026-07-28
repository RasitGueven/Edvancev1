#!/usr/bin/env bash
# check-migration-drift.sh — findet die Lücke, bevor sie jemand merkt.
#
# Lokal (immer):    supabase/pending/ muss leer sein; Dateinamen müssen stimmen.
# Gegen die DB:     jede eingespielte Version braucht eine Datei im Repo.  (nur wenn DBURL gesetzt)
#
# Einsatz:
#   scripts/check-migration-drift.sh          # von Hand
#   in CI                                     # blockiert den Merge
#   .git/hooks/pre-push                       # blockiert den Push
#
# Diese Prüfung hätte A13 und A14 am selben Tag gefunden statt Wochen später.

set -uo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fail=0
note() { echo "  $*"; }
err()  { echo "✗ $*"; fail=1; }
ok()   { echo "✓ $*"; }

# ── 1 · pending/ muss weg sein ──────────────────────────────────────────────
if [[ -d supabase/pending ]]; then
  n=$(find supabase/pending -name '*.sql' | wc -l | tr -d ' ')
  if [[ "$n" -gt 0 ]]; then
    err "supabase/pending/ enthält $n Migration(en) — das ist per Definition Drift."
    find supabase/pending -name '*.sql' -exec note "{}" \;
    note "→ git mv nach supabase/migrations/, dann scripts/db-migrate.sh"
  else
    err "supabase/pending/ existiert noch (leer). Verzeichnis löschen, sonst wird es wieder benutzt."
  fi
else
  ok "supabase/pending/ existiert nicht."
fi

# ── 2 · Namensschema ────────────────────────────────────────────────────────
bad=0
while IFS= read -r f; do
  b=$(basename "$f" .sql)
  [[ "$b" =~ ^[0-9]{14}_.+$ ]] || { err "Dateiname passt nicht auf <14 Ziffern>_<name>.sql: $f"; bad=1; }
done < <(find supabase/migrations -name '*.sql' 2>/dev/null | sort)
[[ "$bad" -eq 0 ]] && ok "Alle Dateinamen folgen dem Schema."

# ── 3 · Ungetrackte Migrationen ─────────────────────────────────────────────
untracked=$(git ls-files --others --exclude-standard supabase/migrations/ 2>/dev/null || true)
if [[ -n "$untracked" ]]; then
  err "Migrationen liegen im Verzeichnis, sind aber nicht im Git:"
  echo "$untracked" | while read -r f; do note "$f"; done
  note "→ git add"
else
  ok "Keine ungetrackten Migrationen."
fi

# ── 4 · Repo gegen Produktion ───────────────────────────────────────────────
if [[ -z "${DBURL:-}" ]]; then
  echo "· DBURL nicht gesetzt — Abgleich mit der Datenbank übersprungen."
else
  applied=$(psql "$DBURL" -tAc \
    "select version from supabase_migrations.schema_migrations order by version" 2>/dev/null) || {
      err "Datenbank nicht erreichbar."; applied=""; }

  if [[ -n "$applied" ]]; then
    missing=0
    while IFS= read -r v; do
      [[ -n "$v" ]] || continue
      if ! ls supabase/migrations/"${v}"_*.sql >/dev/null 2>&1; then
        err "Version $v ist eingespielt, aber es gibt keine Datei im Repo."
        missing=1
      fi
    done <<<"$applied"
    [[ "$missing" -eq 0 ]] && ok "Jede eingespielte Version hat eine Datei im Repo."

    # Umgekehrt nur als Hinweis — kann legitim sein (noch nicht deployed)
    while IFS= read -r f; do
      v=$(basename "$f" | cut -d_ -f1)
      grep -qx "$v" <<<"$applied" || echo "· $f liegt im Repo, ist aber nicht eingespielt."
    done < <(find supabase/migrations -name '*.sql' | sort)
  fi
fi

echo
if [[ "$fail" -eq 0 ]]; then
  echo "Kein Drift."
else
  echo "Drift gefunden — siehe oben."
fi
exit "$fail"
