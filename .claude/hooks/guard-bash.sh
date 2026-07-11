#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
PATTERNS=(
  'git push[^|;&]*( --force| -f)'
  'rm -rf +(/|~|\$HOME|\.\.)'
  'supabase +db +push'
  'supabase +db +reset[^|;&]*(--linked|--db-url)'
  'supabase +migration +up[^|;&]*--linked'
  'git +reset +--hard'
  'git +checkout +\.'
  '(DROP|TRUNCATE) +TABLE'
)
for p in "${PATTERNS[@]}"; do
  if echo "$CMD" | grep -Eiq "$p"; then
    echo "guard-bash: Kommando blockiert (Muster: $p). Sichere Alternative wählen oder Rasit fragen." >&2
    exit 2
  fi
done
exit 0
