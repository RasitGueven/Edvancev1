#!/usr/bin/env bash
# check-migration-drift.sh — findet die Lücke, bevor sie jemand merkt.
#
# Lokal (immer):    supabase/pending/ muss leer sein; Dateinamen müssen stimmen.
# Gegen die DB:     jede eingespielte Version braucht eine Datei im Repo.
#
# Der DB-Abgleich ist der Teil, der Drift überhaupt findet — die drei lokalen
# Prüfungen sehen eine eingespielte Migration ohne Datei nie. Darum braucht das
# Skript DATABASE_URL und bricht sonst ab. Wer nur die lokalen Prüfungen will,
# sagt das mit --ohne-db; dann steht am Ende, was NICHT geprüft wurde.
# Vorher hiess die Variable hier DBURL und war nirgends gesetzt: Abschnitt 4 fiel
# still aus, das Skript meldete trotzdem "Kein Drift".
#
# Einsatz:
#   scripts/check-migration-drift.sh          # von Hand
#   scripts/check-migration-drift.sh --ohne-db   # nur die lokalen Prüfungen
#   in CI                                     # blockiert den Merge
#   .git/hooks/pre-push                       # blockiert den Push
#
# Diese Prüfung hätte A13 und A14 am selben Tag gefunden statt Wochen später.

set -uo pipefail

# Verbindung. Ohne sie fällt Abschnitt 4 aus — das darf nie unbemerkt passieren.
# Kein $(...) im :?-Text: der wird expandiert und würde den Zugangsstring drucken.
#   export DATABASE_URL="$(grep '^DATABASE_URL=' .env | cut -d= -f2- | tr -d "'\"")"
ohne_db=0
[[ "${1:-}" == "--ohne-db" ]] && ohne_db=1
[[ "$ohne_db" -eq 1 ]] || : "${DATABASE_URL:?nicht gesetzt (frueher DBURL) — siehe Kommentar in diesem Skript, oder --ohne-db}"

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fail=0
uebersprungen=0
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
if [[ "$ohne_db" -eq 1 ]]; then
  uebersprungen=1
  echo "· --ohne-db: Abgleich mit der Datenbank NICHT gelaufen."
else
  applied=$(psql "$DATABASE_URL" -tAc \
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
if [[ "$fail" -ne 0 ]]; then
  echo "Drift gefunden — siehe oben."
elif [[ "$uebersprungen" -eq 1 ]]; then
  echo "Lokal kein Drift. Gegen die Datenbank wurde NICHT geprüft (--ohne-db)."
  echo "Das ist keine Freigabe — genau dieser Abgleich findet die fehlenden Dateien."
else
  echo "Kein Drift."
fi
exit "$fail"
