#!/bin/bash

set -e

HOME_DIR="$(eval echo ~$(whoami))"
FORCE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force    Revert without prompting"
    echo "  --help     Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        --help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

echo "=== Omarchy Config Reverter ==="
echo ""
echo "Reverting for user: $(whoami)"
echo "Home directory: $HOME_DIR"
echo ""

if [ "$FORCE" = false ]; then
    read -p "This will overwrite current configs with their .bak versions. Are you sure? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Revert cancelled."
        exit 0
    fi
fi

revert_dir() {
    local dest="$1"
    local name="$2"
    local bak_dir="${dest}.bak"

    if [ -d "$bak_dir" ]; then
        echo "[REVERT] Restoring $name from $bak_dir..."
        rm -rf "$dest"
        cp -r "$bak_dir" "$dest"
        echo "✓ Restored $name"
    else
        echo "[SKIP] No backup found for $name at $bak_dir"
    fi
}

echo "=== Reverting changes ==="
echo ""

revert_dir "$HOME_DIR/.config/waybar" "Waybar config"
revert_dir "$HOME_DIR/.config/ags" "AGS config"
revert_dir "$HOME_DIR/.config/hypr" "Hyprland config"
revert_dir "$HOME_DIR/.config/omarchy/branding" "Branding files"
revert_dir "$HOME_DIR/.config/elephant" "Elephant configs"
revert_dir "$HOME_DIR/.config/omarchy/hooks" "Omarchy hooks"
revert_dir "$HOME_DIR/wallpapers" "Custom wallpapers"
revert_dir "$HOME_DIR/scripts" "Custom scripts"

zen_profile=$(find "$HOME_DIR/.config/zen" -maxdepth 1 -type d -name "*.Default (release)*" 2>/dev/null | head -n 1)
if [ -n "$zen_profile" ]; then
    revert_dir "$zen_profile/chrome" "Zen Browser config"
fi

# Undo the lid-switch override installed by install.sh (restores default
# logind behavior: suspend on lid close regardless of power/dock state).
remove_lid_switch() {
    local dropin="/etc/systemd/logind.conf.d/10-lid.conf"
    if [ ! -f "$dropin" ]; then
        echo "[SKIP] No lid switch config to remove"
        return
    fi
    if sudo rm -f "$dropin" 2>/dev/null; then
        sudo systemctl restart systemd-logind 2>/dev/null || true
        echo "✓ Removed lid switch config ($dropin)"
    else
        echo "[SKIP] Could not remove $dropin (no sudo available)"
    fi
}

remove_lid_switch

echo ""
echo "=== Restarting Waybar ==="
if command -v omarchy-restart-waybar &> /dev/null; then
    omarchy-restart-waybar
else
    echo "Warning: omarchy-restart-waybar not found. Please restart waybar manually."
fi

echo ""
echo "=== Restarting AGS ==="
if command -v ags &> /dev/null; then
    ags quit || true
    nohup ags run -d "$HOME_DIR/.config/ags" >/dev/null 2>&1 &
else
    echo "Warning: ags not found. Please start ags manually."
fi

echo ""
echo "=== Reloading Hyprland ==="
if command -v hyprctl &> /dev/null; then
    hyprctl reload || true
else
    echo "Warning: hyprctl not found. Please reload Hyprland manually."
fi

echo ""
echo "=== Restarting hypridle ==="
if command -v hypridle &> /dev/null; then
    pkill -x hypridle 2>/dev/null || true
    nohup hypridle >/dev/null 2>&1 &
else
    echo "Warning: hypridle not found. Please restart hypridle manually."
fi

echo ""
echo "=== Revert Complete ==="
