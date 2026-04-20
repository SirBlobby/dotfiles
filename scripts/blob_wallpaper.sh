#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: blob_wallpaper <path-to-image>"
    exit 1
fi

IMAGE_PATH=$(realpath "$1")

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: File '$IMAGE_PATH' does not exist."
    exit 1
fi

# Point the Omarchy background link to your custom image
ln -nsf "$IMAGE_PATH" "$HOME/.config/omarchy/current/background"

# Relaunch swaybg smoothly
pkill -x swaybg
setsid uwsm-app -- swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &

echo "Wallpaper updated to: $IMAGE_PATH"