#!/bin/bash
INPUT=$(cat)
# Nur in autonomen Läufen aktiv — interaktive Sessions bleiben schnell
[ -f .claude/autonomous ] || exit 0
# Endlosschleife verhindern
[ "$(echo "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0
if ! npm run -s typecheck > /tmp/edvance-gate.log 2>&1; then
  { echo "STOP-GATE: Typecheck rot — du bist NICHT fertig:"; tail -n 40 /tmp/edvance-gate.log; } >&2
  exit 2
fi
if ! npm run -s test > /tmp/edvance-gate.log 2>&1; then
  { echo "STOP-GATE: Tests rot — du bist NICHT fertig:"; tail -n 40 /tmp/edvance-gate.log; } >&2
  exit 2
fi
exit 0
