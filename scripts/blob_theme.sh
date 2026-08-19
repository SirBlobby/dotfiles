#!/bin/bash

# Manage color themes: local static themes installed under
# ~/.config/omarchy/themes/, the pywal-generated dynamic theme
# (blob-dynamic), and themes shared from the wall-styles website.

THEME_DIR="$HOME/.config/omarchy/themes/blob-dynamic"
USER_THEMES_DIR="$HOME/.config/omarchy/themes"
CURRENT_DIR="$HOME/.local/state/omarchy/current"

# Used only when a bare id is passed instead of a full share link.
# Override with: export BLOB_THEME_URL="https://your-deployment.vercel.app"
BASE_URL="${BLOB_THEME_URL:-https://wall-styles.vercel.app}"

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

prettify() {
    echo "$1" | sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g'
}

current_mode() {
    local name
    name=$(cat "$CURRENT_DIR/theme.name" 2>/dev/null)
    if [ "$name" = "blob-dynamic" ]; then
        echo "dynamic"
    else
        echo "static"
    fi
}

theme_exists_locally() {
    local slug
    slug=$(slugify "$1")
    [ -d "$USER_THEMES_DIR/$slug" ] || [ -d "$OMARCHY_PATH/themes/$slug" ]
}

# Rows for omarchy-menu-select, as "<label><TAB><slug>". The menu returns the
# label and the subtext, so the slug comes back as a stable key.
list_theme_rows() {
    printf 'Dynamic (from wallpaper)\tblob-dynamic\n'

    {
        find "$USER_THEMES_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
        find "$OMARCHY_PATH/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
    } | while read -r theme_dir; do
        [ -f "$theme_dir/colors.toml" ] || continue
        slug=$(basename "$theme_dir")
        [ "$slug" = "blob-dynamic" ] && continue
        printf '%s\t%s\n' "$(prettify "$slug")" "$slug"
    done | sort -u -t$'\t' -k2,2
}

select_theme() {
    local selection slug
    selection=$(list_theme_rows | omarchy-menu-select "Select Theme" -- --width 800) || return 1
    slug=$(printf '%s' "$selection" | cut -f2)
    [ -n "$slug" ] || return 1
    echo "$slug"
}

apply_static() {
    local name="$1"
    # Clean up a lingering gif-animation daemon from a previous dynamic
    # wallpaper before switching to a static theme's own background.
    awww kill --all >/dev/null 2>&1
    omarchy-theme-set "$name"
}

apply_dynamic() {
    if [ ! -f "$THEME_DIR/colors.toml" ]; then
        echo "No dynamic theme yet. Pick a wallpaper first: blob_wallpaper"
        exit 1
    fi
    # Skip the background step: this is purely a recolor of whatever
    # wallpaper is already showing, not a wallpaper change.
    OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "blob-dynamic"
}

case "$1" in
    "")
        ags toggle theme-picker
        ;;
    --menu)
        selected=$(select_theme) || exit 0
        if [ "$selected" = "blob-dynamic" ]; then
            apply_dynamic
        else
            apply_static "$selected"
        fi
        ;;
    --mode)
        current_mode
        ;;
    --print)
        CURRENT_COLORS="$CURRENT_DIR/theme/colors.toml"
        if [ ! -f "$CURRENT_COLORS" ]; then
            echo "No active theme colors.toml found at $CURRENT_COLORS" >&2
            exit 1
        fi
        # awk always terminates the last line with a newline, even if the
        # source file doesn't. Omarchy's template engine reads colors.toml
        # with a bash `while read` loop, which silently drops a final line
        # missing its newline (e.g. color15) - some built-in themes are
        # missing it too, so this guards every theme saved via --print.
        awk '1' "$CURRENT_COLORS"
        ;;
    --dynamic)
        apply_dynamic
        ;;
    *)
        if theme_exists_locally "$1"; then
            apply_static "$1"
        else
            # Not a local theme: treat it as a wall-styles share link or id.
            INPUT="$1"

            if [[ "$INPUT" == http*://* ]]; then
                HOST=$(echo "$INPUT" | sed -E 's#^(https?://[^/]+).*#\1#')
                ID=$(echo "$INPUT" | grep -oE 'id=[A-Za-z0-9]+' | head -1 | cut -d= -f2)
                if [ -z "$ID" ]; then
                    echo "Error: '$INPUT' is not a local theme, and no share id was found in the link."
                    exit 1
                fi
                API="$HOST/api/theme?id=$ID&format=toml"
            else
                API="$BASE_URL/api/theme?id=$INPUT&format=toml"
            fi

            mkdir -p "$THEME_DIR/backgrounds"

            echo "Fetching theme..."
            TMP=$(mktemp)
            if ! curl -fsSL "$API" -o "$TMP"; then
                echo "Error: could not fetch theme, and '$1' is not a local theme name. The link may be expired (themes last one hour)."
                rm -f "$TMP"
                exit 1
            fi

            if ! grep -q '^background = ' "$TMP"; then
                echo "Error: the response did not look like a valid colors.toml."
                rm -f "$TMP"
                exit 1
            fi

            mv "$TMP" "$THEME_DIR/colors.toml"

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

            # Apply the Blob-Dynamic theme (reloads the Omarchy shell, ags, etc.)
            omarchy-theme-set "blob-dynamic"

            echo "Applied shared theme to blob-dynamic."
        fi
        ;;
esac
