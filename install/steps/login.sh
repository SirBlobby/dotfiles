session_entry_dir=/usr/local/share/wayland-sessions
session_entry_search_dirs=(/usr/local/share/wayland-sessions /usr/share/wayland-sessions)
greeter_config_dir=/etc/sddm.conf.d
greeter_compositor_config=/etc/sddm/hyprland-greeter.lua

# SDDM reads /etc/sddm.conf.d in alphabetical order and the last file wins, so
# Blob's drop-ins are named to sort after anything a distribution, an installer
# ISO, or a previous desktop left behind.
blob_greeter_conf="$greeter_config_dir/zz-blob.conf"
blob_autologin_conf="$greeter_config_dir/zzz-blob-autologin.conf"
greeter_gpu_detector=/usr/local/bin/blob-hw-gpu-accelerated
greeter_theme_dir=/usr/share/sddm/themes/blob
greeter_theme_files=(Main.qml metadata.desktop theme.conf)

# SDDM's stock Wayland greeter runs on weston, which Blob does not install.
# Point it at Hyprland with a greeter-only config instead. That config is Lua:
# Hyprland dropped the old hyprlang format, and a config it cannot parse leaves
# the greeter with no compositor and the screen black.
install_login_config() {
  install_greeter_theme
  install_greeter_branding
  install_root_file "$repo_dir/default/sddm/hyprland-greeter.lua" \
    "$greeter_compositor_config" "sddm/hyprland-greeter.lua"
  install_root_file "$repo_dir/default/sddm/zz-blob.conf" \
    "$blob_greeter_conf" "sddm.conf.d/zz-blob.conf"
  install_root_file "$repo_dir/bin/blob-hw-gpu-accelerated" \
    "$greeter_gpu_detector" "blob-hw-gpu-accelerated" 0755
  install_root_file "$repo_dir/default/pam.d/blob-lock-password" \
    /etc/pam.d/blob-lock-password "pam.d/blob-lock-password"
}

install_greeter_theme() {
  local file force=true
  for file in "${greeter_theme_files[@]}"; do
    install_root_file "$repo_dir/default/sddm/blob/$file" \
      "$greeter_theme_dir/$file" "sddm/themes/blob/$file"
  done
  install_root_file "$repo_dir/branding/blob_icon.svg" \
    "$greeter_theme_dir/logo.svg" "sddm/themes/blob/logo.svg"
}

install_greeter_branding() {
  local source="$HOME/.config/blob/branding/screensaver.txt"
  [[ -r $source ]] || source="$repo_dir/branding/screensaver.txt"
  [[ -r $source ]] && command -v jq >/dev/null || return 0

  local generated force=true
  generated="$(mktemp)"
  printf 'import QtQuick\n\nQtObject {\n  readonly property string text: %s\n}\n' \
    "$(jq -Rs . <"$source")" >"$generated"
  install_root_file "$generated" "$greeter_theme_dir/Branding.qml" "sddm/themes/blob/Branding.qml"
  rm -f "$generated"
}

install_session_entry() {
  install_root_file "$repo_dir/session/blob.desktop" \
    "$session_entry_dir/blob.desktop" "wayland session entry"
}

install_autologin() {
  if [[ $autologin == false ]]; then
    return 0
  fi

  local generated
  generated="$(mktemp)"
  printf '[Autologin]\nUser=%s\nSession=blob.desktop\n' "$USER" >"$generated"
  install_root_file "$generated" "$blob_autologin_conf" "sddm.conf.d/zzz-blob-autologin.conf"
  rm -f "$generated"
}

session_entry_exists() {
  local entry="$1"
  local dir

  for dir in "${session_entry_search_dirs[@]}"; do
    [[ -e $dir/$entry ]] && return 0
  done

  return 1
}

setting_value() {
  local file="$1" key="$2"

  sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p" "$file" | tail -1
}

# SDDM runs CompositorCommand to get a Wayland greeter on screen. When that
# binary is not installed SDDM fails with no greeter at all, which reads as a
# machine that boots to a console for no reason, so name it here instead.
report_greeter_compositor() {
  local command_line binary

  command_line="$(setting_value "$repo_dir/default/sddm/zz-blob.conf" CompositorCommand)"
  binary="${command_line%% *}"

  [[ -n $binary ]] || return 0
  command -v "$binary" &>/dev/null && return 0

  warn "the greeter's compositor command '$binary' is not installed"
  say "      SDDM cannot draw a greeter without it; it is set in $blob_greeter_conf"
}

# zz-blob.conf pins Theme to Blob's own and blanks Autologin, so a leftover
# drop-in cannot point the greeter at a theme that was uninstalled or autolog
# into a session that no
# longer exists. Either one leaves SDDM on a black screen it never falls back
# from. Report the leftovers anyway: the file is confusing to find later, and the
# Omarchy ISO wrote an autologin that no package owns, so it outlives Omarchy.
report_login_conflicts() {
  local file session
  local found=false

  for file in "$greeter_config_dir"/*.conf; do
    [[ -e $file ]] || continue
    [[ $file == "$blob_greeter_conf" || $file == "$blob_autologin_conf" ]] && continue

    session="$(setting_value "$file" Session)"
    [[ -n $session ]] || continue
    session_entry_exists "$session" && continue

    found=true
    warn "$file autologs into $session, which is not installed"
  done

  if [[ $found == true ]]; then
    say "      Blob's config overrides it, so the greeter still comes up."
    say "      Delete the file to stop it coming back."
  fi
}

# Enabling sddm is not enough on a machine installed without a display manager:
# its default target is multi-user.target, which never pulls in graphical.target.
enable_display_manager() {
  if ! system_unit_exists sddm.service; then
    if package_installed sddm; then
      warn "sddm is installed but sddm.service is not visible to systemd"
      say "      run 'sudo systemctl daemon-reload', then ./install.sh again"
    else
      warn "sddm is not installed; the desktop cannot start at boot"
      say "      install it with 'sudo pacman -S sddm', then ./install.sh again"
    fi
    return 0
  fi

  local enable_needed=false
  case "$(system_unit_state sddm.service)" in
    enabled | enabled-runtime) ;;
    *) enable_needed=true ;;
  esac

  local default_target
  default_target="$(systemctl get-default 2>/dev/null || true)"

  local target_needed=false
  [[ $default_target == graphical.target ]] || target_needed=true

  if [[ $enable_needed == false && $target_needed == false ]]; then
    say "ok    display manager"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    [[ $enable_needed == true ]] && say "would enable sddm.service"
    [[ $target_needed == true ]] && say "would set the default target to graphical.target"
    return 0
  fi

  if [[ $enable_needed == true ]]; then
    if as_root systemctl enable sddm.service; then
      say "enable sddm.service"
    else
      warn "could not enable sddm.service"
    fi
  fi

  if [[ $target_needed == true ]]; then
    if as_root systemctl set-default graphical.target; then
      say "set   default target to graphical.target"
    else
      warn "could not set the default target to graphical.target"
    fi
  fi
}

# The installer is usually run from a bare console on a fresh machine, where
# enabling the display manager alone leaves the user looking at a shell prompt.
launch_desktop() {
  if [[ $check == true ]]; then
    return 0
  fi

  if [[ $no_launch == true ]]; then
    say "Run 'sudo systemctl start sddm' or reboot to reach the desktop."
    return 0
  fi

  if ! system_unit_exists sddm.service; then
    say "No login screen to start: sddm is not installed."
    return 0
  fi

  if [[ -n ${WAYLAND_DISPLAY:-} || -n ${DISPLAY:-} ]]; then
    say "Log out and pick the Blob session at the login screen."
    return 0
  fi

  if systemctl is-active --quiet sddm.service; then
    say "The login screen is already running."
    return 0
  fi

  if reboot_chosen; then
    say "Rebooting into Blob."
    as_root systemctl reboot
    return 0
  fi

  say "Starting the login screen. Pick the Blob session to log in."
  as_root systemctl start sddm.service || {
    warn "sddm.service did not start; see 'systemctl status sddm'"
  }
}

reboot_chosen() {
  [[ -r /dev/tty ]] || return 1
  local answer
  say "A reboot brings up the network, boot splash and new kernel modules together."
  read -rp "Reboot now? [Y/n] " answer </dev/tty
  [[ -z $answer || $answer == [yY]* ]]
}
