session_entry_dir=/usr/local/share/wayland-sessions
greeter_compositor_config=/etc/sddm/hyprland-greeter.lua

# SDDM's stock Wayland greeter runs on weston, which Blob does not install.
# Point it at Hyprland with a greeter-only config instead.
install_login_config() {
  install_root_file "$repo_dir/default/sddm/hyprland-greeter.lua" \
    "$greeter_compositor_config" "sddm/hyprland-greeter.lua"
  install_root_file "$repo_dir/default/sddm/10-blob.conf" \
    /etc/sddm.conf.d/10-blob.conf "sddm.conf.d/10-blob.conf"
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
  install_root_file "$generated" \
    /etc/sddm.conf.d/99-blob-autologin.conf "sddm.conf.d/99-blob-autologin.conf"
  rm -f "$generated"
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
