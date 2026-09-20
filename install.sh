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
skip_packages=false
changes=0

usage() {
  cat <<USAGE
Usage: ./install.sh [OPTIONS]

  --check           Report what would change, write nothing
  --force           Overwrite files that have local changes
  --skip-packages   Do not install packages, only directories and config
  --help            Show this message
USAGE
  exit 0
}

while (( $# > 0 )); do
  case "$1" in
    --force) force=true; shift ;;
    --check) check=true; shift ;;
    --skip-packages) skip_packages=true; shift ;;
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

directories=(
  "$HOME/.config/blob/hooks"
  "$HOME/.config/blob/extensions"
  "$HOME/.config/blob/plugins"
  "$HOME/.config/blob/themed"
  "$HOME/.config/blob/themes"
  "$HOME/.config/blob/branding"
  "$HOME/.config/hypr"
  "$HOME/.config/uwsm/env.d"
  "$HOME/.local/state/blob/toggles/hypr"
  "$HOME/.local/state/blob/indicators"
  "$HOME/.local/state/blob/notifications/history"
  "$HOME/.local/state/blob/notifications/images"
  "$HOME/.local/state/blob/backgrounds"
  "$HOME/.local/state/blob/current"
  "$HOME/.local/share/fonts"
  "$HOME/.local/share/applications"
  "$HOME/.local/share/icons/hicolor/256x256/apps"
  "$HOME/wallpapers"
)

create_directories() {
  local missing=()
  local dir
  for dir in "${directories[@]}"; do
    [[ -d $dir ]] || missing+=("$dir")
  done

  if (( ${#missing[@]} == 0 )); then
    say "ok    directories"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would create ${#missing[@]} directory(ies):"
    printf '        %s\n' "${missing[@]}"
    return 0
  fi

  mkdir -p "${missing[@]}"
  say "mkdir ${#missing[@]} directory(ies)"
}

read_package_list() {
  [[ -f $1 ]] || return 0
  grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$1"
}

# A list entry may be "wanted|already-fine", which asks for the first name but
# treats either as satisfying the requirement. That is how the AUR replacement
# for a package still shipped by another repository avoids a file conflict.
missing_packages() {
  local entry wanted alternative
  for entry in $(read_package_list "$1"); do
    wanted=${entry%%|*}
    alternative=${entry#*|}
    pacman -Q "$wanted" &>/dev/null && continue
    [[ $alternative != "$entry" ]] && pacman -Q "$alternative" &>/dev/null && continue
    printf '%s\n' "$wanted"
  done
}

install_packages() {
  if [[ $skip_packages == true ]]; then
    say "skip  packages (--skip-packages)"
    return 0
  fi

  local -a repo_missing aur_missing
  mapfile -t repo_missing < <(missing_packages "$repo_dir/packages/blob.packages")
  mapfile -t aur_missing < <(missing_packages "$repo_dir/packages/blob-aur.packages")

  if (( ${#repo_missing[@]} == 0 && ${#aur_missing[@]} == 0 )); then
    say "ok    packages"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    (( ${#repo_missing[@]} )) && say "would install ${#repo_missing[@]} repo package(s): ${repo_missing[*]}"
    (( ${#aur_missing[@]} )) && say "would install ${#aur_missing[@]} AUR package(s): ${aur_missing[*]}"
    return 0
  fi

  blob_sudo_keepalive

  if (( ${#repo_missing[@]} )); then
    say "install ${#repo_missing[@]} repo package(s)"
    sudo pacman -S --needed --noconfirm "${repo_missing[@]}"
  fi

  if (( ${#aur_missing[@]} )); then
    ensure_aur_helper || {
      say "WARN  no AUR helper; skipping ${#aur_missing[@]} AUR package(s): ${aur_missing[*]}"
      return 0
    }
    say "install ${#aur_missing[@]} AUR package(s)"
    yay -S --needed --noconfirm "${aur_missing[@]}"
  fi
}

# A fresh Arch install has no AUR helper, and yay is not in the official
# repositories, so it is built from the AUR once with makepkg. Everything after
# this point can then use yay normally.
ensure_aur_helper() {
  command -v yay &>/dev/null && return 0

  say "bootstrap yay from the AUR"
  sudo pacman -S --needed --noconfirm base-devel git

  local build_dir
  build_dir="$(mktemp -d)"
  if ! git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"; then
    rm -rf "$build_dir"
    return 1
  fi

  ( cd "$build_dir/yay-bin" && makepkg -si --noconfirm ) || {
    rm -rf "$build_dir"
    return 1
  }

  rm -rf "$build_dir"
  command -v yay &>/dev/null
}

blob_sudo_keepalive() {
  sudo -v 2>/dev/null || true
}

# BLOB_PATH is a symlink to this checkout rather than a copy, so bin/, shell/,
# themes/ and default/ are always the working tree. Every path the shell
# resolves as $BLOB_PATH/... therefore needs no install step at all.
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
    return 0
  fi

  if [[ -e $dest ]] && cmp -s "$source" "$dest"; then
    say "ok    $label"
    return 0
  fi

  note_change

  if [[ -e $dest ]] && [[ $force == false ]]; then
    say "DIFF  $label (local changes kept; --force to overwrite)"
    return 0
  fi

  if [[ $check == true ]]; then
    say "would write $label"
    return 0
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
    return 0
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
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would install wayland session entry (needs sudo)"
    return 0
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
create_directories
install_packages

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
