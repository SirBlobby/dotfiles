#!/bin/bash

# Window transparency toggle. Omarchy's toggles directory is loaded after
# ~/.config/hypr/looknfeel.lua, so dropping a flag file here re-enables the
# default translucency that looknfeel.lua overrides away.

FLAG_FILE="$HOME/.local/state/omarchy/toggles/hypr/blob-glass.lua"

ACTION=$1

if [ -z "$ACTION" ]; then
    ACTION="toggle"
fi

enable_glass() {
    mkdir -p "$(dirname "$FLAG_FILE")"
    cat > "$FLAG_FILE" <<'LUA'
o.window({ tag = "default-opacity" }, { opacity = "0.985 0.96" })
LUA
    echo "Transparency enabled (glass on)."
    hyprctl reload >/dev/null
}

disable_glass() {
    rm -f "$FLAG_FILE"
    echo "Transparency disabled (glass off)."
    hyprctl reload >/dev/null
}

if [ "$ACTION" == "on" ]; then
    enable_glass
elif [ "$ACTION" == "off" ]; then
    disable_glass
elif [ "$ACTION" == "toggle" ]; then
    if [ -f "$FLAG_FILE" ]; then
        disable_glass
    else
        enable_glass
    fi
else
    echo "Usage: blob_glass [on|off|toggle]"
    exit 1
fi
