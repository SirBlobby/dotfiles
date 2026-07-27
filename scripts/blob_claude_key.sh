#!/bin/bash

KEY_FILE="$HOME/.config/ags/secrets/anthropic_admin_key"

usage() {
    echo "Usage: blob_claude_key <set|show|clear>"
    echo "  set <key>   Store your Anthropic Admin API key (sk-ant-admin01-...)"
    echo "  show        Print the stored key, masked"
    echo "  clear       Remove the stored key"
    exit 1
}

case "$1" in
    set)
        key="$2"
        if [ -z "$key" ]; then
            echo "Usage: blob_claude_key set <key>"
            exit 1
        fi
        mkdir -p "$(dirname "$KEY_FILE")"
        printf '%s' "$key" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "Admin key saved to $KEY_FILE"
        ;;
    show)
        if [ -f "$KEY_FILE" ]; then
            key=$(cat "$KEY_FILE")
            echo "${key:0:14}...${key: -4}"
        else
            echo "No admin key stored"
        fi
        ;;
    clear)
        rm -f "$KEY_FILE"
        echo "Admin key removed"
        ;;
    *)
        usage
        ;;
esac
