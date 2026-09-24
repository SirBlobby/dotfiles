system_services=(
  NetworkManager.service
  systemd-resolved.service
  bluetooth.service
  cups.service
  avahi-daemon.service
  docker.socket
  power-profiles-daemon.service
  systemd-oomd.service
)

# network-online.target must not hold up graphical.target waiting for DHCP or
# Wi-Fi association. Nothing in the session blocks on the network.
#
# An unconfigured plymouth takes the console at boot and never hands it back,
# and getty@tty1 waits on plymouth-quit-wait.service, so the machine comes up
# with no greeter and no TTY to fix it from. The plymouth units are masked
# until install_boot_splash configures the blob theme, and left alone after.
masked_services=(
  NetworkManager-wait-online.service
  plymouth-start.service
  plymouth-quit-wait.service
)

# blob-speaker-tuning.service is deliberately absent: blob-audio-tuning installs
# and enables it itself, only on machines with a tuning profile.
user_services=(
  bt-agent.service
  blob-sleep-lock.service
  blob-fcitx5.service
  blob-crash-watch.service
)

enable_system_services() {
  local pending=()
  local unit

  for unit in "${system_services[@]}"; do
    system_unit_exists "$unit" || continue
    case "$(system_unit_state "$unit")" in
      enabled | enabled-runtime | static | alias | indirect | masked) continue ;;
    esac
    pending+=("$unit")
  done

  if (( ${#pending[@]} == 0 )); then
    say "ok    system services"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would enable ${#pending[@]} system service(s): ${pending[*]}"
    return 0
  fi

  as_root systemctl enable "${pending[@]}"
  say "enable ${#pending[@]} system service(s)"
}

mask_system_services() {
  local pending=()
  local unit

  for unit in "${masked_services[@]}"; do
    system_unit_exists "$unit" || continue
    [[ $unit == plymouth-* ]] && boot_splash_installed && continue
    [[ "$(system_unit_state "$unit")" == masked ]] && continue
    pending+=("$unit")
  done

  if (( ${#pending[@]} == 0 )); then
    say "ok    masked services"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would mask ${#pending[@]} service(s): ${pending[*]}"
    return 0
  fi

  as_root systemctl mask "${pending[@]}"
  say "mask  ${#pending[@]} service(s)"
}

install_systemd_dropins() {
  local systemd_dir="$repo_dir/default/systemd"

  install_root_file "$systemd_dir/faster-shutdown.conf" \
    /etc/systemd/system.conf.d/10-blob.conf "systemd/system.conf.d/10-blob.conf"
  install_root_file "$systemd_dir/user@.service.d/faster-shutdown.conf" \
    /etc/systemd/system/user@.service.d/10-blob.conf "systemd/user@.service.d/10-blob.conf"
  install_root_file "$systemd_dir/oomd.conf.d/10-blob.conf" \
    /etc/systemd/oomd.conf.d/10-blob.conf "systemd/oomd.conf.d/10-blob.conf"
  install_root_file "$systemd_dir/system-sleep/keyboard-backlight" \
    /etc/systemd/system-sleep/keyboard-backlight "systemd/system-sleep/keyboard-backlight" 0755
  install_root_file "$systemd_dir/system-sleep/unmount-fuse" \
    /etc/systemd/system-sleep/unmount-fuse "systemd/system-sleep/unmount-fuse" 0755

  if system_unit_exists plocate-updatedb.service; then
    install_root_file "$systemd_dir/system/plocate-updatedb.service.d/10-blob.conf" \
      /etc/systemd/system/plocate-updatedb.service.d/10-blob.conf \
      "systemd/plocate-updatedb.service.d/10-blob.conf"
  else
    say "SKIP  systemd/plocate-updatedb.service.d/10-blob.conf (plocate not installed)"
  fi
}

install_user_units() {
  local unit

  for unit in "${user_services[@]}"; do
    install_file "$repo_dir/default/systemd/user/$unit" \
      "$config_dir/systemd/user/$unit" "systemd/user/$unit"
  done

  install_file "$repo_dir/default/systemd/user/app.slice.d/10-oomd.conf" \
    "$config_dir/systemd/user/app.slice.d/10-oomd.conf" "systemd/user/app.slice.d/10-oomd.conf"
}

# Enable only. The units are all WantedBy=graphical-session.target, so they come
# up with the session rather than from a TTY where their conditions cannot pass.
enable_user_units() {
  local pending=()
  local unit

  if ! user_manager_available; then
    say "WARN  no user systemd manager; skipping user services"
    return 0
  fi

  for unit in "${user_services[@]}"; do
    [[ "$(user_unit_state "$unit")" == enabled ]] && continue
    pending+=("$unit")
  done

  if (( ${#pending[@]} == 0 )); then
    say "ok    user services"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would enable ${#pending[@]} user service(s): ${pending[*]}"
    return 0
  fi

  systemctl --user daemon-reload
  systemctl --user enable "${pending[@]}"
  say "enable ${#pending[@]} user service(s)"
}
