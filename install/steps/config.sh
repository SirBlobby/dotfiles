# BLOB_PATH is a symlink to this checkout rather than a copy, so bin/, shell/,
# themes/ and default/ are always the working tree. Every path the shell
# resolves as $BLOB_PATH/... therefore needs no install step at all.
#
# ~/.local/share does not exist on a fresh Arch install, and ln does not create
# the parent of its link, so make it here rather than relying on another step
# having run first.
link_blob_path() {
  local current=""
  [[ -L $blob_path ]] && current="$(readlink -f "$blob_path" || true)"

  if [[ $current == "$repo_dir" ]]; then
    say "ok    BLOB_PATH -> $repo_dir"
    return 0
  fi

  if [[ -e $blob_path && ! -L $blob_path ]]; then
    warn "$blob_path exists and is not a symlink; move it aside first"
    note_change
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would link BLOB_PATH -> $repo_dir"
    return 0
  fi

  mkdir -p "$(dirname "$blob_path")"
  ln -sfn "$repo_dir" "$blob_path"
  say "link  BLOB_PATH -> $repo_dir"
}

# config/ is the shipped-defaults directory. Everything in it is reachable as
# $BLOB_PATH/config/... so `blob-refresh-config` can reset a file, and most of it
# is also the right thing to deploy on a fresh install. Two subdirectories are
# reference-only and must not be copied into ~/.config:
#
#   blob/  the shell defaults; copying them over ~/.config/blob/shell.json would
#          replace the user's bar layout with the stock one
#   hypr/  the stock Hyprland config; the personal hypr/ below is authoritative
#          and is installed to the same place
install_shipped_config() {
  local entry entry_name

  install_tree "$repo_dir/hypr" "$config_dir/hypr" "hypr"

  for entry in "$repo_dir"/config/*; do
    entry_name="$(basename "$entry")"
    [[ $entry_name == blob || $entry_name == hypr ]] && continue
    if [[ -d $entry ]]; then
      install_tree "$entry" "$config_dir/$entry_name" "config/$entry_name"
    else
      install_file "$entry" "$config_dir/$entry_name" "config/$entry_name"
    fi
  done

  install_tree "$repo_dir/hooks" "$config_dir/blob/hooks" "hooks"
  install_tree "$repo_dir/branding" "$config_dir/blob/branding" "branding"
  install_file "$repo_dir/shell.json" "$config_dir/blob/shell.json" "shell.json"
  install_file "$repo_dir/session/uwsm/default" "$config_dir/uwsm/default" "uwsm/default"
  install_file "$repo_dir/session/uwsm/env.d/10-blob" "$config_dir/uwsm/env.d/10-blob" "uwsm/env.d/10-blob"
}

desktop_entry_dir="$HOME/.local/share/applications"
app_icon_dir="$HOME/.local/share/icons/hicolor/32x32/apps"

install_desktop_apps() {
  install_tree "$repo_dir/applications/desktop" "$desktop_entry_dir" "applications"
  install_tree "$repo_dir/applications/icons" "$app_icon_dir" "icons"
}

remove_omarchy_font() {
  local omarchy_font="$font_dir/omarchy.ttf"

  [[ -f $omarchy_font ]] || return 0

  note_change
  if [[ $check == true ]]; then
    say "would remove $omarchy_font"
    return 0
  fi

  rm -f "$omarchy_font"
  say "rm    fonts/omarchy.ttf"
}

bashrc_line='[ -r "$HOME/.local/share/blob/session/bashrc" ] && . "$HOME/.local/share/blob/session/bashrc"'

install_bash_integration() {
  local bashrc="$HOME/.bashrc"

  if [[ -f $bashrc ]] && grep -Fqx "$bashrc_line" "$bashrc"; then
    say "ok    bashrc"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would source session/bashrc from ~/.bashrc"
    return 0
  fi

  [[ -f $bashrc ]] && cp "$bashrc" "$bashrc.bak"
  printf '\n%s\n' "$bashrc_line" >>"$bashrc"
  say "write bashrc"
}

refresh_font_cache() {
  if ! command -v fc-cache &>/dev/null; then
    say "SKIP  font cache (fc-cache not installed)"
    return 0
  fi

  if [[ $check == true ]]; then
    say "would refresh the font cache"
    return 0
  fi

  fc-cache -f "$font_dir" >/dev/null 2>&1 || true
  say "ok    font cache"
}

install_shell_profile() {
  install_root_file "$repo_dir/session/profile.sh" /etc/profile.d/blob.sh "profile.d/blob.sh"
}

install_makepkg_config() {
  install_root_file "$repo_dir/default/makepkg/blob-parallel.conf" \
    /etc/makepkg.conf.d/blob-parallel.conf "makepkg.conf.d/blob-parallel.conf"
}

install_zen_config() {
  local profile
  profile="$(find "$config_dir/zen" -maxdepth 1 -type d -name '*.Default (release)*' 2>/dev/null | head -1)"

  if [[ -z $profile ]]; then
    say "SKIP  zen/userChrome.css (no Zen profile found)"
    return 0
  fi

  install_file "$repo_dir/zen/userChrome.css" "$profile/chrome/userChrome.css" "zen/userChrome.css"
}
