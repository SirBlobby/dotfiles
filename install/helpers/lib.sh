source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/as-root.sh"

say() {
  printf '%s\n' "$1"
}

note_change() {
  changes=$((changes + 1))
}

unit_search_dirs=(
  /etc/systemd/system
  /run/systemd/system
  /usr/local/lib/systemd/system
  /usr/lib/systemd/system
)

system_unit_exists() {
  local unit="$1" dir

  systemctl cat -- "$unit" &>/dev/null && return 0

  for dir in "${unit_search_dirs[@]}"; do
    [[ -e $dir/$unit ]] && return 0
  done

  return 1
}

user_manager_available() {
  systemctl --user show-environment &>/dev/null
}

system_unit_state() {
  systemctl is-enabled -- "$1" 2>/dev/null || true
}

user_unit_state() {
  systemctl --user is-enabled -- "$1" 2>/dev/null || true
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

# Same reporting as install_file for a destination outside $HOME. The mode is
# explicit because these land in /etc and /usr/local, and no .bak is kept: the
# only writer of these paths is the installer.
install_root_file() {
  local source="$1" dest="$2" label="$3" mode="${4:-0644}"

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
    say "would write $label (needs sudo)"
    return 0
  fi

  as_root install -Dm "$mode" "$source" "$dest"
  say "write $label"
}
