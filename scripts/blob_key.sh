#!/bin/bash

SECRETS_DIR="$HOME/.config/ags/secrets"

usage() {
    echo "Usage: blob_key <set|show|clear|list> [NAME] [VALUE]"
    echo "  set <NAME> <VALUE>   Store a secret (e.g. ANTHROPIC_ADMIN_KEY)"
    echo "  show <NAME>          Print a stored secret, masked"
    echo "  clear <NAME>         Remove a stored secret"
    echo "  list                 List the names of stored secrets"
    exit 1
}

case "$1" in
    set)
        name="$2"
        value="$3"
        if [ -z "$name" ] || [ -z "$value" ]; then
            echo "Usage: blob_key set <NAME> <VALUE>"
            exit 1
        fi
        mkdir -p "$SECRETS_DIR"
        printf '%s' "$value" > "$SECRETS_DIR/$name"
        chmod 600 "$SECRETS_DIR/$name"
        echo "Saved $name to $SECRETS_DIR/$name"
        ;;
    show)
        name="$2"
        if [ -z "$name" ]; then
            echo "Usage: blob_key show <NAME>"
            exit 1
        fi
        if [ -f "$SECRETS_DIR/$name" ]; then
            value=$(cat "$SECRETS_DIR/$name")
            echo "${value:0:6}...${value: -4}"
        else
            echo "No key stored for $name"
        fi
        ;;
    clear)
        name="$2"
        if [ -z "$name" ]; then
            echo "Usage: blob_key clear <NAME>"
            exit 1
        fi
        rm -f "$SECRETS_DIR/$name"
        echo "Removed $name"
        ;;
    list)
        if [ -d "$SECRETS_DIR" ]; then
            ls -1 "$SECRETS_DIR"
        else
            echo "No keys stored"
        fi
        ;;
    *)
        usage
        ;;
esac
