#!/bin/bash

PROJECTS_DIR="$HOME/.claude/projects"
TODAY=$(date -u '+%Y-%m-%d')
EMPTY='{"available":false,"tokens":0,"messages":0,"cacheHitPercent":0}'

if [ ! -d "$PROJECTS_DIR" ]; then
    echo "$EMPTY"
    exit 0
fi

FILES=$(find "$PROJECTS_DIR" -name "*.jsonl" -newermt "$TODAY")

if [ -z "$FILES" ]; then
    echo '{"available":true,"tokens":0,"messages":0,"cacheHitPercent":0}'
    exit 0
fi

jq -s --arg today "$TODAY" '
  [.[] | select(.timestamp != null and (.timestamp | startswith($today)) and .message.usage != null) | .message.usage] as $usages
  | ([$usages[] | .input_tokens // 0] | add // 0) as $input
  | ([$usages[] | .output_tokens // 0] | add // 0) as $output
  | ([$usages[] | .cache_creation_input_tokens // 0] | add // 0) as $cacheCreate
  | ([$usages[] | .cache_read_input_tokens // 0] | add // 0) as $cacheRead
  | ($input + $cacheCreate + $cacheRead) as $totalInput
  | {
      available: true,
      tokens: ($totalInput + $output),
      messages: ($usages | length),
      cacheHitPercent: (if $totalInput > 0 then (($cacheRead / $totalInput) * 100) else 0 end)
    }
' $FILES 2>/dev/null || echo "$EMPTY"
