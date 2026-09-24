conflicting_network_services=(
  systemd-networkd.service
  iwd.service
  dhcpcd.service
  netctl.service
)

stop_install() {
  printf 'ERROR %s\n' "$1" >&2
  shift
  local detail
  for detail in "$@"; do
    printf '      %s\n' "$detail" >&2
  done
  exit 1
}

require_regular_user() {
  (( EUID != 0 )) && return 0
  stop_install "run install.sh as your own user, not as root" \
    "it installs into \$HOME and builds AUR packages, which makepkg refuses to do as root" \
    "it asks for sudo when it needs it"
}

require_arch() {
  command -v pacman &>/dev/null && return 0
  stop_install "pacman not found; Blob installs on Arch Linux only"
}

require_sudo() {
  [[ $check == true ]] && return 0
  command -v sudo &>/dev/null || stop_install "sudo is not installed" \
    "as root: pacman -S sudo, then add your user with visudo"
  sudo -v || stop_install "sudo did not accept this user" \
    "as root: add your user to the wheel group and allow it in visudo"
}

require_internet() {
  [[ $check == true || $skip_packages == true ]] && return 0
  curl -fsS --max-time 15 -o /dev/null https://archlinux.org && return 0
  stop_install "no internet connection; packages cannot be downloaded" \
    "connect first (iwctl for Wi-Fi), or rerun with --skip-packages"
}

report_network_conflicts() {
  local unit
  local -a enabled=()

  for unit in "${conflicting_network_services[@]}"; do
    [[ "$(system_unit_state "$unit")" == enabled ]] && enabled+=("$unit")
  done

  (( ${#enabled[@]} == 0 )) && return 0

  warn "NetworkManager will be enabled, but so is: ${enabled[*]}"
  say "      two network managers fight over the same interfaces after a reboot"
  say "      once NetworkManager works: sudo systemctl disable ${enabled[*]}"
}

sudo_keepalive_pid=""

start_sudo_keepalive() {
  [[ $check == true ]] && return 0
  while true; do
    sudo -n true 2>/dev/null
    sleep 60
  done &
  sudo_keepalive_pid=$!
  trap stop_sudo_keepalive EXIT
}

stop_sudo_keepalive() {
  [[ -n $sudo_keepalive_pid ]] && kill "$sudo_keepalive_pid" 2>/dev/null
  sudo_keepalive_pid=""
}

run_preflight() {
  require_regular_user
  require_arch
  require_sudo
  require_internet
  report_network_conflicts
  start_sudo_keepalive
  say "ok    preflight"
}
