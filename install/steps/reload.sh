reloaded_system_services=(
  systemd-oomd.service
)

session_running() {
  pgrep -u "$UID" -x Hyprland &>/dev/null
}

reload_system_services() {
  if [[ $check == true ]]; then
    say "would reload systemd and restart ${reloaded_system_services[*]}"
    return 0
  fi

  if ! as_root systemctl daemon-reload; then
    warn "could not reload systemd"
    return 0
  fi

  local unit
  for unit in "${reloaded_system_services[@]}"; do
    system_unit_exists "$unit" || continue
    as_root systemctl try-restart "$unit" || warn "could not restart $unit"
  done

  say "ok    system services reloaded"
}

reload_user_services() {
  if ! user_manager_available; then
    say "SKIP  user services reload (no user systemd manager)"
    return 0
  fi

  if [[ $check == true ]]; then
    say "would restart the running user services"
    return 0
  fi

  systemctl --user daemon-reload

  local unit failed=()
  for unit in "${user_services[@]}"; do
    systemctl --user try-restart "$unit" &>/dev/null || failed+=("$unit")
  done

  if (( ${#failed[@]} > 0 )); then
    warn "could not restart: ${failed[*]}"
  else
    say "ok    user services reloaded"
  fi
}

run_session_reload() {
  local label="$1"
  shift

  if BLOB_PATH="$blob_path" PATH="$blob_path/bin:$PATH" "$@" &>/dev/null; then
    say "ok    $label reloaded"
  else
    warn "could not reload $label"
  fi
}

reload_session() {
  if ! session_running; then
    say "SKIP  session reload (Blob is not running)"
    return 0
  fi

  if [[ $check == true ]]; then
    say "would reload the theme, Hyprland, and the Blob shell"
    return 0
  fi

  run_session_reload "theme" blob-theme-refresh
  run_session_reload "Hyprland" blob-hypr-restart
  run_session_reload "Blob shell" blob-shell-restart
}
