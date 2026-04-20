#!/bin/bash

# Configuration files to modify
ACTIVE_CONF="$HOME/.config/hypr/looknfeel.conf"
REPO_CONF="$HOME/Documents/dotfiles/hypr/looknfeel.conf"

# The rule to enforce solid opacity
OVERRIDE_RULE="windowrule = opacity 1.0 override 1.0 override, match:tag default-opacity"
# A marker comment
MARKER="# Remove default window transparency"

ACTION=$1

if [ -z "$ACTION" ]; then
    ACTION="toggle"
fi

enable_glass() {
    # Remove the rules
    sed -i "/$MARKER/d" "$ACTIVE_CONF" "$REPO_CONF" 2>/dev/null
    sed -i "/opacity 1.0 override/d" "$ACTIVE_CONF" "$REPO_CONF" 2>/dev/null
    echo "Transparency enabled (glass on)."
    hyprctl reload >/dev/null
}

disable_glass() {
    # Add the rules if they don't exist
    if ! grep -q "opacity 1.0 override" "$ACTIVE_CONF"; then
        echo -e "\n$MARKER\n$OVERRIDE_RULE" >> "$ACTIVE_CONF"
        echo -e "\n$MARKER\n$OVERRIDE_RULE" >> "$REPO_CONF"
    fi
    echo "Transparency disabled (glass off)."
    hyprctl reload >/dev/null
}

if [ "$ACTION" == "on" ]; then
    enable_glass
elif [ "$ACTION" == "off" ]; then
    disable_glass
elif [ "$ACTION" == "toggle" ]; then
    if grep -q "opacity 1.0 override" "$ACTIVE_CONF"; then
        enable_glass
    else
        disable_glass
    fi
else
    echo "Usage: blob_glass [on|off|toggle]"
    exit 1
fi