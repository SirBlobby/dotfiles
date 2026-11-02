default_theme=flats
wallpaper_dir="$HOME/wallpapers"
current_state_dir="$HOME/.local/state/blob/current"

# ~/wallpapers is what the wallpaper picker and `blob wallpaper set` read, and
# the checkout already carries the collection. Link it for the same reason
# BLOB_PATH is a link: one copy, and edits in the checkout are live.
link_wallpapers() {
  local source="$repo_dir/wallpapers"
  local current=""

  [[ -L $wallpaper_dir ]] && current="$(readlink -f "$wallpaper_dir" || true)"

  if [[ $current == "$source" ]]; then
    say "ok    wallpapers"
    return 0
  fi

  if [[ -d $wallpaper_dir && ! -L $wallpaper_dir ]] && [[ -n "$(ls -A "$wallpaper_dir")" ]]; then
    say "ok    wallpapers (own directory kept)"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would link $wallpaper_dir -> $source"
    return 0
  fi

  [[ -d $wallpaper_dir && ! -L $wallpaper_dir ]] && rmdir "$wallpaper_dir"
  ln -sfn "$source" "$wallpaper_dir"
  say "link  wallpapers -> $source"
}

# Without a theme there is no palette, no themed app config, and no background
# for the shell to draw, so the first login lands on a black screen that looks
# like a failed session. Applied headless: no shell and no session bus exist
# while the installer runs.
install_default_theme() {
  local current_name=""
  [[ -s $current_state_dir/theme.name ]] && current_name="$(cat "$current_state_dir/theme.name")"

  if [[ -n $current_name && -f $current_state_dir/theme/colors.toml ]]; then
    say "ok    theme ($current_name)"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would apply the $default_theme theme"
    return 0
  fi

  if BLOB_PATH="$blob_path" BLOB_THEME_HEADLESS=1 PATH="$repo_dir/bin:$PATH" \
    blob-theme-set "$default_theme" >/dev/null; then
    say "theme $default_theme"
  else
    warn "could not apply the $default_theme theme"
    say "      the session will come up without a palette; run 'blob theme set $default_theme'"
  fi
}

# Only a theme that ships its own backgrounds/ sets this link, and most ship
# none: they are meant to leave the current wallpaper alone. On a first install
# there is no current wallpaper, so pick one.
install_default_background() {
  local link="$current_state_dir/background"
  local search="$wallpaper_dir"
  local first

  if [[ -e $link ]]; then
    say "ok    background"
    return 0
  fi

  # --check writes nothing, so the wallpaper link is not there yet to look in.
  [[ -d $search ]] || search="$repo_dir/wallpapers"

  first="$(find -L "$search" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    2>/dev/null | sort | head -1)"

  if [[ -z $first ]]; then
    say "SKIP  background (no image in $search)"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would set the background to $(basename "$first")"
    return 0
  fi

  ln -nsf "$first" "$link"
  say "bg    $(basename "$first")"
}

# The theme pipeline renders one file per app into the current-theme directory,
# but each app only ever reads its own config tree. These links are what join
# the two. Without them a theme switch silently leaves the app on stock colors,
# because nothing errors: the app just never sees the generated file.
link_theme_file() {
  local theme_file="$1" dest="$2" label="$3"
  local target="$current_state_dir/theme/$theme_file"

  if [[ -L $dest ]] && [[ "$(readlink "$dest")" == "$target" ]]; then
    say "ok    $label"
    return 0
  fi

  if [[ -e $dest && ! -L $dest ]] && [[ $force == false ]]; then
    note_change
    say "DIFF  $label (own file kept; --force to replace)"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would link $label"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  ln -nsf "$target" "$dest"
  say "link  $label"
}

# btop reads color_theme = "current" out of its own themes directory, and
# Neovim loads whatever theme.lua its plugin directory holds. Neovim is only
# linked when that directory already exists: Blob ships no Neovim config, so
# creating the tree would be inventing a layout the user has not chosen.
link_app_themes() {
  link_theme_file btop.theme "$config_dir/btop/themes/current.theme" "btop theme"
  link_theme_file gtk.css "$config_dir/gtk-3.0/gtk.css" "gtk-3.0 theme"
  link_theme_file gtk.css "$config_dir/gtk-4.0/gtk.css" "gtk-4.0 theme"
  link_theme_file starship.toml "$config_dir/starship.toml" "starship prompt"
  link_theme_file fastfetch.jsonc "$config_dir/fastfetch/config.jsonc" "fastfetch"

  if [[ -d $config_dir/nvim/lua/plugins ]]; then
    link_theme_file neovim.lua "$config_dir/nvim/lua/plugins/theme.lua" "neovim theme"
  else
    say "SKIP  neovim theme (no ~/.config/nvim/lua/plugins)"
  fi
}
