#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"
THEME_DIR="$HOME/.config/omarchy/themes/blob-dynamic"

# Create the directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$THEME_DIR/backgrounds"

if [ -z "$1" ]; then
    # Use walker dmenu for GUI selection
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

# Apply the Blob-Dynamic theme
# omarchy-theme-set manages the background and reloads waybar and AGS
omarchy-theme-set "blob-dynamic"

# If it's a GIF, override swaybg with awww (swww replacement)
if [[ "${IMAGE_PATH,,}" == *.gif ]]; then
    echo "GIF detected, switching to awww..."
    pkill -x swaybg
    
    # Start awww daemon if not running
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon >/dev/null 2>&1 &
        sleep 1
    fi
    
    awww img "$IMAGE_PATH"
else
    # Ensure awww is stopped for static wallpapers so swaybg can render them
    if pgrep -x awww-daemon >/dev/null; then
        pkill -x awww-daemon
    fi
fi

echo "Wallpaper and dynamic theme applied successfully: $IMAGE_PATH"