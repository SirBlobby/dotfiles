#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$(eval echo ~$(whoami))"
FORCE=false
CHECK=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force    Overwrite all local changes"
    echo "  --check    Show what would change without applying"
    echo "  --help     Show this help message"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --force) FORCE=true; shift ;;
        --check) CHECK=true; shift ;;
        --help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

echo "=== Omarchy Config Installer ==="
echo ""
echo "Installing for user: $(whoami)"
echo "Home directory: $HOME_DIR"
echo ""

compute_hash() {
    if [ -d "$1" ]; then
        find "$1" -type f 2>/dev/null | sort | xargs -I{} sha256sum {} 2>/dev/null | sha256sum | cut -d' ' -f1
    else
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    fi
}

check_file() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ ! -e "$dest" ]; then
        echo "✓ $name: New (will be created)"
        return 1
    fi
    
    local src_hash=$(compute_hash "$src")
    local dest_hash=$(compute_hash "$dest")
    
    if [ "$src_hash" = "$dest_hash" ]; then
        echo "✓ $name: Up to date"
        return 0
    else
        echo "✗ $name: Has local changes"
        return 1
    fi
}

backup_and_copy() {
    local src="$1"
    local dest="$2"
    local name="$3"
    
    if [ ! -e "$dest" ]; then
        echo "[COPY] $name: New directory (creating)"
        mkdir -p "$dest"
        cp -r "$src"/* "$dest"/
        return
    fi
    
    local src_hash=$(compute_hash "$src")
    local dest_hash=$(compute_hash "$dest")
    
    if [ "$src_hash" = "$dest_hash" ]; then
        echo "[SKIP] $name: Up to date"
        return
    fi
    
    if [ "$FORCE" = true ]; then
        echo "[BACKUP] $name: Backing up..."
        rm -rf "$dest.bak"
        mkdir -p "$dest.bak"
        cp -r "$dest"/* "$dest.bak/" 2>/dev/null || true

        echo "[COPY] $name: Overwriting (--force)"
        cp -r "$src"/* "$dest"/
    else
        echo "[SKIP] $name: Has local changes (use --force to overwrite)"
    fi
}

# Like backup_and_copy, but for destinations that are pure git-tracked
# mirrors with no local state worth protecting (wallpapers, themes).
# No .bak sibling is created — a stale one would otherwise show up
# alongside the real thing (e.g. in the theme picker's directory scan).
replace_and_copy() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -e "$dest" ]; then
        echo "[COPY] $name: New directory (creating)"
        mkdir -p "$dest"
        cp -r "$src"/* "$dest"/
        return
    fi

    local src_hash=$(compute_hash "$src")
    local dest_hash=$(compute_hash "$dest")

    if [ "$src_hash" = "$dest_hash" ]; then
        echo "[SKIP] $name: Up to date"
        return
    fi

    if [ "$FORCE" = true ]; then
        echo "[COPY] $name: Replacing (--force)"
        rm -rf "$dest"
        mkdir -p "$dest"
        cp -r "$src"/* "$dest"/
    else
        echo "[SKIP] $name: Has local changes (use --force to overwrite)"
    fi
}

backup_and_copy_file() {
    local src="$1"
    local dest="$2"
    local name="$3"

    if [ ! -e "$dest" ]; then
        echo "[COPY] $name: New file (creating)"
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        return
    fi

    if [ "$(compute_hash "$src")" = "$(compute_hash "$dest")" ]; then
        echo "[SKIP] $name: Up to date"
        return
    fi

    if [ "$FORCE" = true ]; then
        echo "[BACKUP] $name: Backing up..."
        cp "$dest" "$dest.bak"

        echo "[COPY] $name: Overwriting (--force)"
        cp "$src" "$dest"
    else
        echo "[SKIP] $name: Has local changes (use --force to overwrite)"
    fi
}

install_dependencies() {
    echo "=== Checking Dependencies ==="
    local deps_needed=()
    if ! command -v wal &> /dev/null; then
        deps_needed+=("python-pywal")
    fi
    if ! command -v magick &> /dev/null && ! command -v convert &> /dev/null; then
        deps_needed+=("imagemagick")
    fi
    if ! command -v awww &> /dev/null; then
        deps_needed+=("awww")
    fi
    if ! command -v playerctl &> /dev/null; then
        deps_needed+=("playerctl")
    fi
    
    if [ ${#deps_needed[@]} -gt 0 ]; then
        echo "Installing missing dependencies: ${deps_needed[*]}"
        if command -v sudo &> /dev/null; then
            sudo pacman -S --needed --noconfirm "${deps_needed[@]}"
        else
            echo "Warning: sudo not found. Please install manually: ${deps_needed[*]}"
        fi
    else
        echo "All dependencies are installed."
    fi
    echo ""
}

install_dependencies

echo "=== Checking for local changes ==="
echo ""

check_status=0

check_file "$SCRIPT_DIR/hypr/hyprland.lua" "$HOME_DIR/.config/hypr/hyprland.lua" "hypr/hyprland.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/monitors.lua" "$HOME_DIR/.config/hypr/monitors.lua" "hypr/monitors.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/input.lua" "$HOME_DIR/.config/hypr/input.lua" "hypr/input.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/autostart.lua" "$HOME_DIR/.config/hypr/autostart.lua" "hypr/autostart.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/looknfeel.lua" "$HOME_DIR/.config/hypr/looknfeel.lua" "hypr/looknfeel.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/bindings.lua" "$HOME_DIR/.config/hypr/bindings.lua" "hypr/bindings.lua" || check_status=1
check_file "$SCRIPT_DIR/hypr/hyprsunset.conf" "$HOME_DIR/.config/hypr/hyprsunset.conf" "hypr/hyprsunset.conf" || check_status=1
check_file "$SCRIPT_DIR/hypr/xdph.conf" "$HOME_DIR/.config/hypr/xdph.conf" "hypr/xdph.conf" || check_status=1
check_file "$SCRIPT_DIR/omarchy/shell.json" "$HOME_DIR/.config/omarchy/shell.json" "omarchy/shell.json" || check_status=1
check_file "$SCRIPT_DIR/omarchy/extensions/omarchy-menu.jsonc" "$HOME_DIR/.config/omarchy/extensions/omarchy-menu.jsonc" "omarchy/extensions/omarchy-menu.jsonc" || check_status=1
check_file "$SCRIPT_DIR/omarchy/hooks/theme-set" "$HOME_DIR/.config/omarchy/hooks/theme-set" "omarchy/hooks/theme-set" || check_status=1
check_file "$SCRIPT_DIR/omarchy/themed/zen.css.tpl" "$HOME_DIR/.config/omarchy/themed/zen.css.tpl" "omarchy/themed/zen.css.tpl" || check_status=1
check_file "$SCRIPT_DIR/ags/app.ts" "$HOME_DIR/.config/ags/app.ts" "ags/app.ts" || check_status=1
check_file "$SCRIPT_DIR/ags/style.css" "$HOME_DIR/.config/ags/style.css" "ags/style.css" || check_status=1
check_file "$SCRIPT_DIR/ags/lib/utils.ts" "$HOME_DIR/.config/ags/lib/utils.ts" "ags/lib/utils.ts" || check_status=1
check_file "$SCRIPT_DIR/ags/lib/claude-usage.sh" "$HOME_DIR/.config/ags/lib/claude-usage.sh" "ags/lib/claude-usage.sh" || check_status=1
check_file "$SCRIPT_DIR/ags/lib/weather.sh" "$HOME_DIR/.config/ags/lib/weather.sh" "ags/lib/weather.sh" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/ClaudeUsage.tsx" "$HOME_DIR/.config/ags/widget/ClaudeUsage.tsx" "ags/widget/ClaudeUsage.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/Media.tsx" "$HOME_DIR/.config/ags/widget/Media.tsx" "ags/widget/Media.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/Notifications.tsx" "$HOME_DIR/.config/ags/widget/Notifications.tsx" "ags/widget/Notifications.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/QuickSettings.tsx" "$HOME_DIR/.config/ags/widget/QuickSettings.tsx" "ags/widget/QuickSettings.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/SysMonitor.tsx" "$HOME_DIR/.config/ags/widget/SysMonitor.tsx" "ags/widget/SysMonitor.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/ThemePicker.tsx" "$HOME_DIR/.config/ags/widget/ThemePicker.tsx" "ags/widget/ThemePicker.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/WallPicker.tsx" "$HOME_DIR/.config/ags/widget/WallPicker.tsx" "ags/widget/WallPicker.tsx" || check_status=1
check_file "$SCRIPT_DIR/ags/widget/WidgetCard.tsx" "$HOME_DIR/.config/ags/widget/WidgetCard.tsx" "ags/widget/WidgetCard.tsx" || check_status=1
check_file "$SCRIPT_DIR/branding/about.txt" "$HOME_DIR/.config/omarchy/branding/about.txt" "branding/about.txt" || check_status=1
check_file "$SCRIPT_DIR/branding/screensaver.txt" "$HOME_DIR/.config/omarchy/branding/screensaver.txt" "branding/screensaver.txt" || check_status=1

zen_profile=$(find "$HOME_DIR/.config/zen" -maxdepth 1 -type d -name "*.Default (release)*" 2>/dev/null | head -n 1)
if [ -n "$zen_profile" ]; then
    check_file "$SCRIPT_DIR/zen/userChrome.css" "$zen_profile/chrome/userChrome.css" "zen/userChrome.css" || check_status=1
fi

for script in "$SCRIPT_DIR/scripts"/*.sh; do
    if [ -f "$script" ]; then
        base_name=$(basename "$script" .sh)
        check_file "$script" "$HOME_DIR/scripts/$base_name.sh" "scripts/$base_name.sh" || check_status=1
    fi
done

if [ -d "$SCRIPT_DIR/themes" ]; then
    for theme_dir in "$SCRIPT_DIR/themes"/*/; do
        [ -d "$theme_dir" ] || continue
        theme_name=$(basename "$theme_dir")
        check_file "$theme_dir/colors.toml" "$HOME_DIR/.config/omarchy/themes/$theme_name/colors.toml" "themes/$theme_name/colors.toml" || check_status=1
    done
fi

echo ""

if [ "$CHECK" = true ]; then
    echo "=== Check complete ==="
    if [ $check_status -eq 0 ]; then
        echo "All files are up to date."
    else
        echo "Some files have local changes. Use --force to overwrite."
    fi
    exit 0
fi

if [ $check_status -eq 0 ] && [ "$FORCE" = false ]; then
    echo "=== All configs up to date - nothing to do ==="
    exit 0
fi

echo "=== Applying changes ==="
echo ""

backup_and_copy "$SCRIPT_DIR/ags" "$HOME_DIR/.config/ags" "AGS config"
backup_and_copy "$SCRIPT_DIR/hypr" "$HOME_DIR/.config/hypr" "Hyprland config"
backup_and_copy "$SCRIPT_DIR/branding" "$HOME_DIR/.config/omarchy/branding" "Branding files"
backup_and_copy "$SCRIPT_DIR/omarchy/hooks" "$HOME_DIR/.config/omarchy/hooks" "Omarchy hooks"
backup_and_copy "$SCRIPT_DIR/omarchy/themed" "$HOME_DIR/.config/omarchy/themed" "Omarchy custom templates"
backup_and_copy "$SCRIPT_DIR/omarchy/extensions" "$HOME_DIR/.config/omarchy/extensions" "Omarchy menu extensions"
backup_and_copy_file "$SCRIPT_DIR/omarchy/shell.json" "$HOME_DIR/.config/omarchy/shell.json" "Omarchy shell config"
replace_and_copy "$SCRIPT_DIR/wallpapers" "$HOME_DIR/wallpapers" "Custom wallpapers"

if [ -d "$SCRIPT_DIR/themes" ]; then
    for theme_dir in "$SCRIPT_DIR/themes"/*/; do
        [ -d "$theme_dir" ] || continue
        theme_name=$(basename "$theme_dir")
        replace_and_copy "$theme_dir" "$HOME_DIR/.config/omarchy/themes/$theme_name" "Theme: $theme_name"
    done
fi

zen_profile=$(find "$HOME_DIR/.config/zen" -maxdepth 1 -type d -name "*.Default (release)*" 2>/dev/null | head -n 1)
if [ -n "$zen_profile" ]; then
    backup_and_copy "$SCRIPT_DIR/zen" "$zen_profile/chrome" "Zen Browser config"
else
    echo "[WARN] Zen Browser profile not found. Skipping Zen theme."
fi

mkdir -p "$HOME_DIR/scripts"
backup_and_copy "$SCRIPT_DIR/scripts" "$HOME_DIR/scripts" "Custom scripts"

create_command_wrappers() {
    local bin_dir="$HOME_DIR/.local/bin"
    local scripts_dir="$HOME_DIR/scripts"
    mkdir -p "$bin_dir"
    
    for script in "$SCRIPT_DIR/scripts"/*.sh; do
        if [ -f "$script" ]; then
            local base_name=$(basename "$script" .sh)
            local wrapper_name="$base_name"
            local wrapper_path="$bin_dir/$wrapper_name"
            
            cat > "$wrapper_path" <<EOF
#!/bin/bash
# Blob-Config command: $base_name
# Generated by install.sh

SCRIPT_DIR="$scripts_dir"
"\$SCRIPT_DIR/$base_name.sh" "\$@"
EOF
            chmod +x "$wrapper_path"
            echo "[WRAPPER] Created command: $wrapper_name"
        fi
    done
}

create_command_wrappers

add_system_path() {
    local profile_script="/etc/profile.d/omarchy-scripts.sh"
    local path_line='export PATH="$HOME/scripts:$HOME/.local/bin:$PATH"'
    if [ ! -f "$profile_script" ]; then
        if echo "$path_line" | sudo tee "$profile_script" > /dev/null 2>&1; then
            sudo chmod 644 "$profile_script"
            echo "Added system-wide PATH in /etc/profile.d/"
        else
            echo "Skipped system PATH (no sudo available)"
        fi
    else
        echo "System PATH already configured"
    fi
}

add_system_path

# Keep the laptop awake with the lid closed while docked / on AC, so the two
# external monitors stay usable. Omarchy's own lid-switch binds disable eDP-1
# on close so no workspace is stranded.
configure_lid_switch() {
    local dropin="/etc/systemd/logind.conf.d/10-lid.conf"
    local content="[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore"

    if [ -f "$dropin" ] && [ "$(cat "$dropin" 2>/dev/null)" = "$content" ]; then
        echo "Lid switch behavior already configured"
        return
    fi

    if sudo mkdir -p "$(dirname "$dropin")" 2>/dev/null \
        && printf '%s\n' "$content" | sudo tee "$dropin" > /dev/null 2>&1; then
        sudo chmod 644 "$dropin"
        sudo systemctl restart systemd-logind 2>/dev/null || true
        echo "Configured lid switch (suspend on battery, ignore when docked/on AC)"
    else
        echo "Skipped lid switch config (no sudo available)"
    fi
}

configure_lid_switch

add_path_to_shell() {
    local shell_rc="$1"
    local path_line='export PATH="$HOME/scripts:$HOME/.local/bin:$PATH"'
    
    if [ -f "$shell_rc" ]; then
        if ! grep -q 'scripts' "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Added by Omarchy-Config installer" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            echo "Added to $shell_rc"
        else
            echo "$path_line already in $shell_rc"
        fi
    fi
}

add_path_to_shell "$HOME_DIR/.bashrc"
add_path_to_shell "$HOME_DIR/.zshrc"

chmod +x "$HOME_DIR/scripts/"*.sh 2>/dev/null || true

echo ""
echo "=== Restarting the Omarchy shell ==="
if command -v omarchy-restart-shell &> /dev/null; then
    omarchy-restart-shell
else
    echo "Warning: omarchy-restart-shell not found. Please restart the shell manually."
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
echo "=== Reapplying current theme (to pick up new templates) ==="
current_theme_name=$(cat "$HOME_DIR/.local/state/omarchy/current/theme.name" 2>/dev/null)
if [ -n "$current_theme_name" ] && command -v omarchy-theme-set &> /dev/null; then
    OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy-theme-set "$current_theme_name" || true
else
    echo "Warning: no active theme found. Run blob_theme to generate zen.css."
fi

echo ""
echo "=== Installation Complete ==="
echo "Scripts are in: $HOME_DIR/scripts/"
echo "Custom commands: blob_wifi"
echo ""
echo "To apply PATH changes, run: source ~/.bashrc (or ~/.zshrc)"
