#!/bin/bash

USAGE_RECORD="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/agents/usage/claude.json"
MAX_RECORD_AGE_SECONDS=900
EMPTY='{"ready":false}'

record_is_fresh() {
    [ -f "$USAGE_RECORD" ] || return 1
    local record_age
    record_age=$(( $(date +%s) - $(stat -c %Y "$USAGE_RECORD") ))
    [ "$record_age" -lt "$MAX_RECORD_AGE_SECONDS" ]
}

if ! record_is_fresh && command -v omarchy-agent-usage-update &> /dev/null; then
    omarchy-agent-usage-update claude >/dev/null 2>&1
fi

if [ -f "$USAGE_RECORD" ]; then
    cat "$USAGE_RECORD"
else
    echo "$EMPTY"
fi
