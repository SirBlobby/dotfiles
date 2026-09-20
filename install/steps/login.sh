session_entry_dir=/usr/local/share/wayland-sessions
session_entry_search_dirs=(/usr/local/share/wayland-sessions /usr/share/wayland-sessions)
greeter_config_dir=/etc/sddm.conf.d
greeter_compositor_config=/etc/sddm/hyprland-greeter.lua

# SDDM reads /etc/sddm.conf.d in alphabetical order and the last file wins, so
# Blob's drop-ins are named to sort after anything a distribution, an installer
# ISO, or a previous desktop left behind.
blob_greeter_conf="$greeter_config_dir/zz-blob.conf"
blob_autologin_conf="$greeter_config_dir/zzz-blob-autologin.conf"

# SDDM's stock Wayland greeter runs on weston, which Blob does not install.
# Point it at Hyprland with a greeter-only config instead. That config is Lua:
# Hyprland dropped the old hyprlang format, and a config it cannot parse leaves
# the greeter with no compositor and the screen black.
install_login_config() {
  install_root_file "$repo_dir/default/sddm/hyprland-greeter.lua" \
    "$greeter_compositor_config" "sddm/hyprland-greeter.lua"
  install_root_file "$repo_dir/default/sddm/zz-blob.conf" \
    "$blob_greeter_conf" "sddm.conf.d/zz-blob.conf"
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

# zz-blob.conf blanks Theme and Autologin, so a leftover drop-in cannot point the
# greeter at a theme that was uninstalled or autolog into a session that no
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
    say "WARN  $file autologs into $session, which is not installed"
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
    say "WARN  sddm.service not found; the desktop cannot start at boot"
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
    as_root systemctl enable sddm.service
    say "enable sddm.service"
  fi

  if [[ $target_needed == true ]]; then
    as_root systemctl set-default graphical.target
    say "set   default target to graphical.target"
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

  say "Starting the login screen. Pick the Blob session to log in."
  as_root systemctl start sddm.service
}
