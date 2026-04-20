#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"

# Create the directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

if [ -z "$1" ]; then
    echo "Usage: blob_wallpaper <filename-or-path>"
    echo "Available wallpapers in $WALLPAPER_DIR:"
    ls -1 "$WALLPAPER_DIR" 2>/dev/null || echo "No wallpapers found."
    exit 1
fi

# Check if the argument is a file in the wallpapers directory
if [ -f "$WALLPAPER_DIR/$1" ]; then
    IMAGE_PATH=$(realpath "$WALLPAPER_DIR/$1")
# Check if the argument is an absolute or relative path
elif [ -f "$1" ]; then
    IMAGE_PATH=$(realpath "$1")
else
    echo "Error: File '$1' does not exist in $WALLPAPER_DIR or as a valid path."
    exit 1
fi

# Point the Omarchy background link to your custom image
ln -nsf "$IMAGE_PATH" "$HOME/.config/omarchy/current/background"

# Relaunch swaybg smoothly
pkill -x swaybg
setsid uwsm-app -- swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &

echo "Wallpaper updated to: $IMAGE_PATH"