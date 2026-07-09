#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
case "$FILE" in
  *.ts|*.tsx)
    OUT=$(npx eslint --no-warn-ignored "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
      { echo "post-edit: ESLint-Fehler in $FILE — beheben:"; echo "$OUT" | tail -n 30; } >&2
      exit 2
    fi
    LINES=$(wc -l < "$FILE")
    if [ "$LINES" -gt 400 ]; then
      echo "post-edit: $FILE hat $LINES Zeilen (Limit 400, CLAUDE.md §4). Jetzt aufteilen." >&2
      exit 2
    fi
    ;;
esac
exit 0
