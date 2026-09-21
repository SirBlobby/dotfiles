#!/bin/bash

set -e

blob_path="$HOME/.local/share/blob"
config_dir="$HOME/.config"
session_entry="/usr/local/share/wayland-sessions/blob.desktop"

root_files=(
  /etc/profile.d/blob.sh
  /usr/local/bin/blob-hw-gpu-accelerated
  /etc/sddm.conf.d/zz-blob.conf
  /etc/sddm.conf.d/zzz-blob-autologin.conf
  /etc/sddm/hyprland-greeter.conf
  /etc/sddm.conf.d/10-blob.conf
  /etc/sddm.conf.d/99-blob-autologin.conf
  /etc/sddm/hyprland-greeter.lua
  /etc/systemd/system.conf.d/10-blob.conf
  /etc/systemd/system/user@.service.d/10-blob.conf
  /etc/systemd/oomd.conf.d/10-blob.conf
  /etc/systemd/system/plocate-updatedb.service.d/10-blob.conf
  /etc/systemd/system-sleep/keyboard-backlight
  /etc/systemd/system-sleep/unmount-fuse
)

user_units=(
  bt-agent.service
  blob-sleep-lock.service
  blob-fcitx5.service
  blob-crash-watch.service
)

keep_state=false
keep_session=false
assume_yes=false

usage() {
  cat <<USAGE
Usage: ./uninstall.sh [OPTIONS]

Removes what install.sh wrote. The checkout itself is never touched.

  --keep-state   Leave ~/.local/state/blob in place
  --keep-session Leave the Blob session entry and the login screen config
  --yes          Do not prompt
  --help         Show this message
USAGE
  exit 0
}

while (( $# > 0 )); do
  case "$1" in
    --keep-state) keep_state=true; shift ;;
    --keep-session) keep_session=true; shift ;;
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
    return 0
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

if [[ -L $HOME/wallpapers ]]; then
  rm -f "$HOME/wallpapers"
  say "remove  ~/wallpapers symlink"
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

for gtk in gtk-3.0 gtk-4.0; do
  [[ -L $config_dir/$gtk/gtk.css ]] && restore_or_remove "$config_dir/$gtk/gtk.css" "$gtk/gtk.css"
done

if [[ $keep_state == false && -d $HOME/.local/state/blob ]]; then
  rm -rf "$HOME/.local/state/blob"
  say "remove  ~/.local/state/blob"
fi

for unit in "${user_units[@]}"; do
  if [[ "$(systemctl --user is-enabled -- "$unit" 2>/dev/null || true)" == enabled ]]; then
    systemctl --user disable --now "$unit" >/dev/null 2>&1 || true
    say "disable $unit"
  fi
  rm -f "$config_dir/systemd/user/$unit"
done
rm -f "$config_dir/systemd/user/app.slice.d/10-oomd.conf"

if [[ $keep_session == true ]]; then
  say ""
  say "Done. The Blob session entry and the login screen config were kept."
  exit 0
fi

for path in "${root_files[@]}"; do
  if [[ -e $path ]]; then
    sudo rm -f "$path"
    say "remove  $path"
  fi
done

if [[ -e $session_entry ]]; then
  sudo rm -f "$session_entry"
  say "remove  wayland session entry"
fi

say ""
say "Done. Pick another session at the login screen before rebooting."
