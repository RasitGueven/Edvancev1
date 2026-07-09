#!/bin/bash
# Autonomer Lauf: ./scripts/claude-auto.sh prompts/<spec>.md
#
# Permission-Modus verifiziert gegen die installierte CLI (claude 2.1.205):
#   `claude --help` listet `--permission-mode <mode>` mit den Choices
#   "acceptEdits" | "auto" | "bypassPermissions" | "manual". Der Flag-Name
#   stimmt also mit der Spec überein — acceptEdits erlaubt Datei-Edits ohne
#   Rückfrage, aber KEINE Bash-Bypässe. Volle Autonomie (bypassPermissions /
#   --dangerously-skip-permissions) nur bewusst in Sandbox/Container.
set -euo pipefail
SPEC="${1:?Usage: claude-auto.sh <spec.md>}"
git diff --quiet && git diff --cached --quiet || { echo "Working tree nicht sauber — erst committen."; exit 1; }
BRANCH="auto/$(basename "$SPEC" .md)-$(date +%Y%m%d-%H%M)"
git checkout -b "$BRANCH"
touch .claude/autonomous
# Marker IMMER entfernen — auch bei Fehler (set -e) oder Abbruch (Ctrl-C / kill),
# damit kein verwaister .claude/autonomous spätere interaktive Sessions ausbremst.
trap 'rm -f .claude/autonomous' EXIT INT TERM
claude -p "$(cat "$SPEC")" --permission-mode acceptEdits
echo "Lauf beendet auf Branch $BRANCH — PR nach dev öffnen und reviewen."
