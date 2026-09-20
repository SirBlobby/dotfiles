#!/bin/bash

set -e

blob_path="$HOME/.local/share/blob"
config_dir="$HOME/.config"
session_entry="/usr/share/wayland-sessions/blob.desktop"

keep_state=false
assume_yes=false

usage() {
  cat <<USAGE
Usage: ./uninstall.sh [OPTIONS]

Removes what install.sh wrote. The checkout itself is never touched.

  --keep-state   Leave ~/.local/state/blob in place
  --yes          Do not prompt
  --help         Show this message
USAGE
  exit 0
}

while (( $# > 0 )); do
  case "$1" in
    --keep-state) keep_state=true; shift ;;
    --yes) assume_yes=true; shift ;;
    --help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

say() {
  printf '%s\n' "$1"
}

restore_or_remove() {
  local path="$1" label="$2"

  if [[ -e $path.bak ]]; then
    mv "$path.bak" "$path"
    say "restore $label (from .bak)"
    return
  fi

  if [[ -e $path ]]; then
    rm -f "$path"
    say "remove  $label"
  fi
}

say "This removes the Blob session, its config, and the BLOB_PATH symlink."
say "Your checkout, wallpapers, and themes stay where they are."
if [[ $keep_state == false ]]; then
  say "It also removes ~/.local/state/blob (active theme, toggles, notifications)."
fi
say ""

if [[ $assume_yes == false ]]; then
  read -rp "Continue? [y/N] " answer
  [[ $answer == [yY] ]] || exit 0
fi

if [[ -L $blob_path ]]; then
  rm -f "$blob_path"
  say "remove  BLOB_PATH symlink"
fi

for relative in blob/shell.json uwsm/default uwsm/env.d/10-blob; do
  restore_or_remove "$config_dir/$relative" "$relative"
done

if [[ -d $config_dir/blob ]]; then
  rm -rf "$config_dir/blob"
  say "remove  ~/.config/blob"
fi

for lua in hyprland.lua monitors.lua input.lua looknfeel.lua bindings.lua autostart.lua hyprsunset.conf xdph.conf; do
  restore_or_remove "$config_dir/hypr/$lua" "hypr/$lua"
done

if [[ $keep_state == false && -d $HOME/.local/state/blob ]]; then
  rm -rf "$HOME/.local/state/blob"
  say "remove  ~/.local/state/blob"
fi

if [[ -e $session_entry ]]; then
  sudo rm -f "$session_entry"
  say "remove  wayland session entry"
fi

say ""
say "Done. Pick another session at the login screen before rebooting."
