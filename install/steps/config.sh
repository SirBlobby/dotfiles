# BLOB_PATH is a symlink to this checkout rather than a copy, so bin/, shell/,
# themes/ and default/ are always the working tree. Every path the shell
# resolves as $BLOB_PATH/... therefore needs no install step at all.
#
# ~/.local/share does not exist on a fresh Arch install, and ln does not create
# the parent of its link, so make it here rather than relying on another step
# having run first.
link_blob_path() {
  local current=""
  [[ -L $blob_path ]] && current="$(readlink -f "$blob_path")"

  if [[ $current == "$repo_dir" ]]; then
    say "ok    BLOB_PATH -> $repo_dir"
    return 0
  fi

  if [[ -e $blob_path && ! -L $blob_path ]]; then
    say "WARN  $blob_path exists and is not a symlink; move it aside first"
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
  install_file "$repo_dir/fonts/omarchy.ttf" "$font_dir/omarchy.ttf" "fonts/omarchy.ttf"
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
