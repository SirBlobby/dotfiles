read_package_list() {
  [[ -f $1 ]] || return 0
  grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$1"
}

package_installed() {
  local name="$1" member

  pacman -Q "$name" &>/dev/null && return 0
  pacman -T "$name" &>/dev/null && return 0

  local -a members=()
  mapfile -t members < <(pacman -Sg "$name" 2>/dev/null | awk '{print $2}')
  (( ${#members[@]} )) || return 1

  for member in "${members[@]}"; do
    pacman -Q "$member" &>/dev/null || return 1
  done
}

# A list entry may be "wanted|already-fine", which asks for the first name but
# treats either as satisfying the requirement. That is how the AUR replacement
# for a package still shipped by another repository avoids a file conflict.
missing_packages() {
  local entry wanted alternative
  for entry in $(read_package_list "$1"); do
    wanted=${entry%%|*}
    alternative=${entry#*|}
    package_installed "$wanted" && continue
    [[ $alternative != "$entry" ]] && package_installed "$alternative" && continue
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
    as_root pacman -S --needed --noconfirm "${repo_missing[@]}"
  fi

  if (( ${#aur_missing[@]} )); then
    ensure_aur_helper || {
      say "WARN  no AUR helper; skipping ${#aur_missing[@]} AUR package(s): ${aur_missing[*]}"
      return 0
    }
    say "install ${#aur_missing[@]} AUR package(s)"
    install_aur_packages "${aur_missing[@]}"
  fi
}

install_aur_packages() {
  local package
  local -a failed=()

  for package in "$@"; do
    yay -S --needed --noconfirm "$package" || failed+=("$package")
  done

  (( ${#failed[@]} == 0 )) && return 0

  say "WARN  ${#failed[@]} AUR package(s) failed to build: ${failed[*]}"
  say "WARN  the install continued; retry them with 'yay -S <name>'"
}

# A fresh Arch install has no AUR helper, and yay is not in the official
# repositories, so it is built from the AUR once with makepkg. Everything after
# this point can then use yay normally.
ensure_aur_helper() {
  command -v yay &>/dev/null && return 0

  say "bootstrap yay from the AUR"
  as_root pacman -S --needed --noconfirm base-devel git

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
