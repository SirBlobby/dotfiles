#!/bin/bash

PROJECTS_DIR="$HOME/.claude/projects"
TODAY=$(date -u '+%Y-%m-%d')

if [ ! -d "$PROJECTS_DIR" ]; then
    echo '{"available":false,"tokens":0,"messages":0}'
    exit 0
fi

FILES=$(find "$PROJECTS_DIR" -name "*.jsonl" -newermt "$TODAY")

if [ -z "$FILES" ]; then
    echo '{"available":true,"tokens":0,"messages":0}'
    exit 0
fi

jq -s --arg today "$TODAY" '
  [.[] | select(.timestamp != null and (.timestamp | startswith($today)) and .message.usage != null) | .message.usage] as $usages
  | {
      available: true,
      tokens: ([$usages[] | (.input_tokens // 0) + (.output_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)] | add // 0),
      messages: ($usages | length)
    }
' $FILES 2>/dev/null || echo '{"available":false,"tokens":0,"messages":0}'
