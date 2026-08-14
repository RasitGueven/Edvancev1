#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE" ] && exit 0
# Schema-Zone: nur mit bewusstem Opt-in (Schema-Drift-Regel, CLAUDE.md).
# Neben den Spec-Mustern (supabase/…) hier auch die REALEN Root-Pfade dieses
# Repos: migrations/ liegt im Root, das Schema als schema.sql / schema_content.sql
# (kein supabase/migrations/, kein supabase/schema.sql vorhanden). Beide Muster
# bleiben aktiv, damit der Guard nach einer späteren Umstrukturierung (P00b) greift.
if echo "$FILE" | grep -Eq '(supabase/migrations/|supabase/schema\.sql|(^|/)migrations/|(^|/)schema(_content)?\.sql)'; then
  if [ "$ALLOW_MIGRATIONS" != "1" ]; then
    echo "guard-paths: $FILE ist Schema-Zone. Nur in expliziten Schema-Sessions mit ALLOW_MIGRATIONS=1 erlaubt." >&2
    exit 2
  fi
fi
# Shared-Lib in autonomen Läufen tabu (File-Ownership-Regel)
if [ -f .claude/autonomous ] && echo "$FILE" | grep -q 'src/lib/'; then
  echo "guard-paths: src/lib/** ist in autonomen Läufen gesperrt. Nötige Lib-Änderung stattdessen in AUTONOMY_NOTES.md beschreiben." >&2
  exit 2
fi
exit 0
