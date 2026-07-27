#!/bin/bash

KEY_FILE="$HOME/.config/ags/secrets/ANTHROPIC_ADMIN_KEY"

if [ ! -f "$KEY_FILE" ]; then
    echo '{"available":false,"tokens":0,"costUsd":0}'
    exit 0
fi

ADMIN_KEY=$(cat "$KEY_FILE")
TODAY_START=$(date -u '+%Y-%m-%dT00:00:00Z')
TODAY_END=$(date -u -d tomorrow '+%Y-%m-%dT00:00:00Z')

USAGE_JSON=$(curl -fsS --max-time 6 \
    -H "anthropic-version: 2023-06-01" \
    -H "x-api-key: $ADMIN_KEY" \
    "https://api.anthropic.com/v1/organizations/usage_report/messages?starting_at=${TODAY_START}&ending_at=${TODAY_END}&bucket_width=1d")

COST_JSON=$(curl -fsS --max-time 6 \
    -H "anthropic-version: 2023-06-01" \
    -H "x-api-key: $ADMIN_KEY" \
    "https://api.anthropic.com/v1/organizations/cost_report?starting_at=${TODAY_START}&ending_at=${TODAY_END}&bucket_width=1d")

if [ -z "$USAGE_JSON" ] || [ -z "$COST_JSON" ]; then
    echo '{"available":false,"tokens":0,"costUsd":0}'
    exit 0
fi

TOKENS=$(echo "$USAGE_JSON" | jq '[(.data // [])[].results[]? | (.uncached_input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation.ephemeral_1h_input_tokens // 0) + (.cache_creation.ephemeral_5m_input_tokens // 0) + (.output_tokens // 0)] | add // 0')

COST_CENTS=$(echo "$COST_JSON" | jq '[(.data // [])[].results[]?.amount | tonumber] | add // 0')

jq -n --argjson tokens "$TOKENS" --argjson costCents "$COST_CENTS" \
    '{available: true, tokens: $tokens, costUsd: ($costCents / 100)}'
