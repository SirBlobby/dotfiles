#!/bin/bash

WALLPAPER_DIR="$HOME/wallpapers"
THEME_DIR="$HOME/.config/omarchy/themes/blob-dynamic"

# Create the directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$THEME_DIR/backgrounds"

if [ -z "$1" ]; then
    echo "Available wallpapers in $WALLPAPER_DIR:"
    
    # Read files into an array
    mapfile -t files < <(ls -1 "$WALLPAPER_DIR" 2>/dev/null)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo "No wallpapers found."
        exit 1
    fi
    
    # Print the menu
    for i in "${!files[@]}"; do
        printf "%3d. %s\n" "$((i+1))" "${files[$i]}"
    done
    
    echo ""
    read -p "Select a wallpaper number (1-${#files[@]}): " selection
    
    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#files[@]}" ]; then
        echo "Invalid selection."
        exit 1
    fi
    
    SELECTED_FILE="${files[$((selection-1))]}"
    IMAGE_PATH=$(realpath "$WALLPAPER_DIR/$SELECTED_FILE")
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

echo "Wallpaper and dynamic theme applied successfully: $IMAGE_PATH"