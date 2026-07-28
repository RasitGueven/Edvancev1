#!/usr/bin/env bash
# guard-paths.sh — PreToolUse-Hook für Claude Code.
#
# Alte Regel:  supabase/migrations/** ist gesperrt, ausser ALLOW_MIGRATIONS=1.
#              → jede normale Arbeit braucht die Ausnahme → Umweg über pending/ → Drift.
#
# Neue Regel:  Migrationshistorie ist append-only.
#              NEUE Datei in supabase/migrations/   → erlaubt, ohne Ausnahme.
#              BESTEHENDE (git-getrackte) Datei     → blockiert, ausser ALLOW_MIGRATIONS=1.
#              supabase/pending/                    → immer blockiert.
#
# Damit ist der Normalfall frei und nur der echte Schadensfall gesperrt.
#
# Registrierung in .claude/settings.json siehe README-drift.md.

set -euo pipefail

payload=$(cat)

tool=$(jq -r '.tool_name // ""'                             <<<"$payload")
file=$(jq -r '.tool_input.file_path // .tool_input.path // ""' <<<"$payload")
cmd=$( jq -r '.tool_input.command // ""'                    <<<"$payload")

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

deny() { echo "$1" >&2; exit 2; }   # exit 2 = blockieren, stderr geht ans Modell
allow() { exit 0; }

# Lesende Tools nie blockieren
case "$tool" in
  Read|Grep|Glob|NotebookRead|WebFetch|WebSearch|Task|TodoWrite) allow ;;
esac

# ── Bash: destruktive Zugriffe auf die Historie abfangen ────────────────────
if [[ "$tool" == "Bash" && -n "$cmd" ]]; then
  if [[ "$cmd" =~ supabase/pending ]]; then
    deny "supabase/pending/ ist abgeschafft. Migration direkt in supabase/migrations/ anlegen
und mit scripts/db-migrate.sh einspielen — das Skript setzt den Historieneintrag mit."
  fi
  if [[ "$cmd" =~ (rm|mv|sed|truncate|\>)[^|]*supabase/migrations/ ]] && [[ "${ALLOW_MIGRATIONS:-0}" != "1" ]]; then
    deny "Verändernder Zugriff auf supabase/migrations/ über die Shell ist gesperrt.
Neue Migrationen mit Write anlegen. Reparatur an bestehenden nur mit ALLOW_MIGRATIONS=1."
  fi
  allow
fi

[[ -n "$file" ]] || allow

# Pfad repo-relativ machen
rel="${file#"$repo_root"/}"
rel="${rel#./}"

# ── Schema-Abzuege: nur ueber tools/schema-snapshot.sh ──────────────────────
# Wer sie von Hand aendert, kann den CI-Vergleich an sein Ergebnis anpassen,
# statt das Ergebnis an das Schema.
if [[ "$rel" =~ ^(supabase/)?(schema|schema-erwartet|schema_content)\.sql$ ]] \
   && [[ "${ALLOW_MIGRATIONS:-0}" != "1" ]]; then
  deny "$rel ist ein erzeugter Schema-Abzug und wird nicht von Hand bearbeitet.
Neu erzeugen mit:  bash tools/schema-snapshot.sh"
fi

# ── Shared-Lib in autonomen Laeufen tabu (File-Ownership-Regel) ─────────────
if [ -f "$repo_root/.claude/autonomous" ] && [[ "$rel" == src/lib/* ]]; then
  deny "src/lib/** ist in autonomen Laeufen gesperrt.
Noetige Lib-Aenderung stattdessen in AUTONOMY_NOTES.md beschreiben."
fi

# ── pending/ ist tot ────────────────────────────────────────────────────────
if [[ "$rel" == supabase/pending/* ]]; then
  deny "supabase/pending/ existiert nicht mehr.

Migration direkt anlegen:  supabase/migrations/<UTC-Zeitstempel>_<name>.sql
Einspielen mit:            scripts/db-migrate.sh <datei>

Das Skript spielt ein, trägt in supabase_migrations.schema_migrations ein und staged die
Datei in einem Schritt. Genau dieser Umweg über pending/ hat sechs Migrationen driften lassen."
fi

# ── Alles ausserhalb von migrations/ geht den Guard nichts an ───────────────
[[ "$rel" == supabase/migrations/* ]] || allow

# ── Append-only: neu = erlaubt, bestehend = geschützt ───────────────────────
if git -C "$repo_root" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
  if [[ "${ALLOW_MIGRATIONS:-0}" == "1" ]]; then
    echo "guard-paths: ALLOW_MIGRATIONS=1 — Änderung an eingespielter Migration $rel zugelassen." >&2
    allow
  fi
  deny "$rel ist bereits committet und damit potenziell in Produktion eingespielt.
Migrationshistorie ist append-only — eine eingespielte Datei nachträglich zu ändern lässt
Repo und Datenbank auseinanderlaufen.

Stattdessen: neue Migration anlegen, die den Zustand korrigiert.
Echte Reparatur an der Historie (selten): mit ALLOW_MIGRATIONS=1 starten."
fi

# Neue Datei — das ist der Normalfall, der bisher fälschlich blockiert war.
allow
