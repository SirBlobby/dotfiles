#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"
THEME_DIR="$HOME/.config/omarchy/themes/blob-dynamic"

# Create the directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$THEME_DIR/backgrounds"

{
    echo "=== $(date '+%F %T') invoked with: $* ==="
    echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
    echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
    echo "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
    echo "PATH=$PATH"
} >> "$HOME/.cache/blob-wallpaper.log"

if [ -z "$1" ]; then
    # Open the AGS wallpaper selector widget
    ags toggle wall-picker
    exit 0
elif [ "$1" = "--menu" ]; then
    # Fallback: walker dmenu selection
    omarchy-launch-walker -m menus:blobBackgroundSelector --width 800 --minheight 400 -p "Select Wallpaper…"
    exit 0
else
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
fi

echo "Extracting colors using Pywal..."
wal -i "$IMAGE_PATH" -n -q 2> >(grep -v "deprecated in IMv7" >&2)

# Enhance colors if the palette is too monotone
python3 "$HOME/scripts/blob_color_fixer.py" "$HOME/.cache/wal/colors"

# Clear old backgrounds and copy the new one into the dynamic theme
rm -f "$THEME_DIR/backgrounds/"*
cp "$IMAGE_PATH" "$THEME_DIR/backgrounds/"

# Parse pywal colors and write to colors.toml in the dynamic theme
cat <<EOF > "$THEME_DIR/colors.toml"
accent = "$(sed -n '2p' ~/.cache/wal/colors)"
cursor = "$(sed -n '8p' ~/.cache/wal/colors)"
foreground = "$(sed -n '8p' ~/.cache/wal/colors)"
background = "$(sed -n '1p' ~/.cache/wal/colors)"
selection_foreground = "$(sed -n '1p' ~/.cache/wal/colors)"
selection_background = "$(sed -n '2p' ~/.cache/wal/colors)"

color0 = "$(sed -n '1p' ~/.cache/wal/colors)"
color1 = "$(sed -n '2p' ~/.cache/wal/colors)"
color2 = "$(sed -n '3p' ~/.cache/wal/colors)"
color3 = "$(sed -n '4p' ~/.cache/wal/colors)"
color4 = "$(sed -n '5p' ~/.cache/wal/colors)"
color5 = "$(sed -n '6p' ~/.cache/wal/colors)"
color6 = "$(sed -n '7p' ~/.cache/wal/colors)"
color7 = "$(sed -n '8p' ~/.cache/wal/colors)"
color8 = "$(sed -n '9p' ~/.cache/wal/colors)"
color9 = "$(sed -n '10p' ~/.cache/wal/colors)"
color10 = "$(sed -n '11p' ~/.cache/wal/colors)"
color11 = "$(sed -n '12p' ~/.cache/wal/colors)"
color12 = "$(sed -n '13p' ~/.cache/wal/colors)"
color13 = "$(sed -n '14p' ~/.cache/wal/colors)"
color14 = "$(sed -n '15p' ~/.cache/wal/colors)"
color15 = "$(sed -n '16p' ~/.cache/wal/colors)"
EOF

# Write neovim.lua to satisfy LazyVim's theme symlink requirement
cat <<EOF > "$THEME_DIR/neovim.lua"
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
EOF

# Only switch the active color theme to blob-dynamic if you're already
# in dynamic mode. The palette above and the background below are kept
# up to date regardless, so `blob_theme --dynamic` always reflects the
# latest wallpaper — but picking a wallpaper while on a static theme
# should change the wallpaper, not silently pull you out of it.
#
# When it does apply, skip omarchy-theme-set's own background step: it
# launches swaybg asynchronously, which races with the gif handling
# below and can leave a static swaybg frame on top of an animated gif.
CURRENT_THEME_NAME=$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null)
if [ "$CURRENT_THEME_NAME" = "blob-dynamic" ]; then
    OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "blob-dynamic"
fi

CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"
ln -nsf "$THEME_DIR/backgrounds/$(basename "$IMAGE_PATH")" "$CURRENT_BACKGROUND_LINK"

# Stop whichever daemon was previously rendering the background before
# starting the one this wallpaper needs. `awww kill` shuts the daemon down
# via its own IPC so it cleans up its socket, unlike a raw `pkill`.
pkill -x swaybg 2>/dev/null
awww kill --all >/dev/null 2>&1
pkill -x awww-daemon 2>/dev/null

if [[ "${IMAGE_PATH,,}" == *.gif ]]; then
    echo "GIF detected, using awww for animation..."
    setsid uwsm-app -- awww-daemon >>"$HOME/.cache/awww-daemon.log" 2>&1 &

    # Poll until the daemon's IPC socket is ready instead of guessing a fixed sleep
    IMG_ERROR=""
    for _ in {1..15}; do
        IMG_ERROR=$(awww img "$CURRENT_BACKGROUND_LINK" 2>&1) && break
        sleep 0.3
    done
    if [[ -n "$IMG_ERROR" ]]; then
        echo "awww failed to set the wallpaper: $IMG_ERROR"
        echo "See $HOME/.cache/awww-daemon.log for daemon output."
    fi
else
    setsid uwsm-app -- swaybg -i "$CURRENT_BACKGROUND_LINK" -m fill >/dev/null 2>&1 &
fi

echo "Wallpaper and dynamic theme applied successfully: $IMAGE_PATH"