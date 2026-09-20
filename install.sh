#!/bin/bash

set -e

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
blob_path="$HOME/.local/share/blob"
config_dir="$HOME/.config"
state_dir="$HOME/.local/state/blob"
session_dir="/usr/share/wayland-sessions"
font_dir="$HOME/.local/share/fonts"

force=false
check=false
changes=0

usage() {
  cat <<USAGE
Usage: ./install.sh [OPTIONS]

  --check    Report what would change, write nothing
  --force    Overwrite files that have local changes
  --help     Show this message
USAGE
  exit 0
}

while (( $# > 0 )); do
  case "$1" in
    --force) force=true; shift ;;
    --check) check=true; shift ;;
    --help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

say() {
  printf '%s\n' "$1"
}

note_change() {
  changes=$((changes + 1))
}

# BLOB_PATH is a symlink to this checkout rather than a copy, so bin/, shell/,
# themes/ and default/ are always the working tree. Every path the shell
# resolves as $BLOB_PATH/... therefore needs no install step at all.
link_blob_path() {
  local current=""
  [[ -L $blob_path ]] && current="$(readlink -f "$blob_path")"

  if [[ $current == "$repo_dir" ]]; then
    say "ok    BLOB_PATH -> $repo_dir"
    return
  fi

  if [[ -e $blob_path && ! -L $blob_path ]]; then
    say "WARN  $blob_path exists and is not a symlink; move it aside first"
    note_change
    return
  fi

  note_change
  if [[ $check == true ]]; then
    say "would link BLOB_PATH -> $repo_dir"
    return
  fi

  ln -sfn "$repo_dir" "$blob_path"
  say "link  BLOB_PATH -> $repo_dir"
}

# Copy a file only when the destination is missing or matches what we last
# wrote. A destination that differs is a local edit, reported and kept unless
# --force says otherwise.
install_file() {
  local source="$1" dest="$2" label="$3"

  if [[ ! -e $source ]]; then
    say "SKIP  $label (missing in repo)"
    return
  fi

  if [[ -e $dest ]] && cmp -s "$source" "$dest"; then
    say "ok    $label"
    return
  fi

  note_change

  if [[ -e $dest ]] && [[ $force == false ]]; then
    say "DIFF  $label (local changes kept; --force to overwrite)"
    return
  fi

  if [[ $check == true ]]; then
    say "would write $label"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  [[ -e $dest ]] && cp "$dest" "$dest.bak"
  cp "$source" "$dest"
  say "write $label"
}

install_tree() {
  local source="$1" dest="$2" label="$3"

  if [[ ! -d $source ]]; then
    say "SKIP  $label (missing in repo)"
    return
  fi

  local relative
  while IFS= read -r relative; do
    install_file "$source/$relative" "$dest/$relative" "$label/$relative"
  done < <(cd "$source" && find . -type f -printf '%P\n' | sort)
}

install_session_entry() {
  local source="$repo_dir/session/blob.desktop"
  local dest="$session_dir/blob.desktop"

  if [[ -e $dest ]] && cmp -s "$source" "$dest"; then
    say "ok    wayland session entry"
    return
  fi

  note_change
  if [[ $check == true ]]; then
    say "would install wayland session entry (needs sudo)"
    return
  fi

  sudo install -Dm644 "$source" "$dest"
  say "write wayland session entry"
}

say "Blob installer"
say "repo: $repo_dir"
if [[ $check == true ]]; then
  say "mode: check (nothing will be written)"
fi
say ""

link_blob_path

if [[ $check == false ]]; then
  mkdir -p "$state_dir"/{toggles/hypr,indicators,notifications}
  mkdir -p "$config_dir/blob"/{hooks,extensions,plugins,themed,themes}
  mkdir -p "$HOME/wallpapers"
fi

install_tree "$repo_dir/hypr" "$config_dir/hypr" "hypr"
# config/ is the shipped-defaults directory. Everything in it is reachable as
# $BLOB_PATH/config/... so `blob-refresh-config` can reset a file, and most of it
# is also the right thing to deploy on a fresh install. Two subdirectories are
# reference-only and must not be copied into ~/.config:
#
#   blob/  the shell defaults; copying them over ~/.config/blob/shell.json would
#          replace the user's bar layout with the stock one
#   hypr/  the stock Hyprland config; the personal hypr/ below is authoritative
#          and is installed to the same place
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
install_session_entry

zen_profile="$(find "$config_dir/zen" -maxdepth 1 -type d -name '*.Default (release)*' 2>/dev/null | head -1)"
if [[ -n $zen_profile ]]; then
  install_file "$repo_dir/zen/userChrome.css" "$zen_profile/chrome/userChrome.css" "zen/userChrome.css"
else
  say "SKIP  zen/userChrome.css (no Zen profile found)"
fi

say ""
if [[ $check == true ]]; then
  say "$changes item(s) would change."
  (( changes == 0 )) || exit 1
else
  say "$changes item(s) changed."
  say ""
  say "Next: log out and pick the Blob session, then run 'blob theme set <name>'."
fi
