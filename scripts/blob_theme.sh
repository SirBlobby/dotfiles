#!/bin/bash

# Pull a color theme shared from the wall-styles website and apply it.

THEME_DIR="$HOME/.config/omarchy/themes/blob-dynamic"

# Used only when a bare id is passed instead of a full share link.
# Override with: export BLOB_THEME_URL="https://your-deployment.vercel.app"
BASE_URL="${BLOB_THEME_URL:-https://wall-styles.vercel.app}"

if [ -z "$1" ]; then
    echo "Usage: blob_theme <share-link-or-id>"
    echo "Example: blob_theme \"https://wall-styles.vercel.app/?id=ab12cd34ef\""
    exit 1
fi

INPUT="$1"

if [[ "$INPUT" == http*://* ]]; then
    HOST=$(echo "$INPUT" | sed -E 's#^(https?://[^/]+).*#\1#')
    ID=$(echo "$INPUT" | grep -oE 'id=[A-Za-z0-9]+' | head -1 | cut -d= -f2)
    if [ -z "$ID" ]; then
        echo "Error: no theme id found in link '$INPUT'."
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
    echo "Error: could not fetch theme. The link may be expired (themes last one hour)."
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

# Apply the Blob-Dynamic theme (reloads waybar, ags, etc.)
omarchy-theme-set "blob-dynamic"

echo "Applied shared theme to blob-dynamic."
