#!/bin/bash

STATE_DIR="$HOME/.local/state/omarchy/indicators"
STATE_FILE="$STATE_DIR/tablet-follow-focus"
DAEMON="omarchy-tablet-follow-focus"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/omarchy-tablet-follow-focus.pid"
TABLET_DEVICE="${OMARCHY_TABLET_DEVICE:-hanvon-ugee-6-inch-pentablet-pen}"

selected_mode() {
  local mode
  [ -f "$STATE_FILE" ] || { echo all; return; }
  mode=$(cat "$STATE_FILE" 2>/dev/null)
  echo "${mode:-follow}"
}

write_mode() {
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$1" >"$STATE_FILE"
}

daemon_pid() {
  [ -f "$PIDFILE" ] || return 1
  local pid
  pid=$(<"$PIDFILE")
  [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && echo "$pid"
}

daemon_running() {
  daemon_pid >/dev/null
}

start_daemon() {
  daemon_running && return
  setsid uwsm-app -- "$DAEMON" >/dev/null 2>&1 &
  disown
}

stop_daemon() {
  local pid
  pid=$(daemon_pid) && kill -- "-$pid" 2>/dev/null
  rm -f "$PIDFILE"
  return 0
}

map_to_output() {
  hyprctl eval "hl.device({ name = \"$TABLET_DEVICE\", output = \"$1\" })" >/dev/null
}

focused_monitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name'
}

monitor_exists() {
  hyprctl monitors -j | jq -e --arg name "$1" 'any(.[]; .name == $name)' >/dev/null
}

active_output() {
  local mode
  mode=$(selected_mode)
  case "$mode" in
    all) echo "" ;;
    follow) focused_monitor ;;
    *) echo "$mode" ;;
  esac
}

describe_mode() {
  case "$1" in
    all) echo "Tablet spans all monitors" ;;
    follow) echo "Tablet follows focused monitor" ;;
    *) echo "Tablet locked to $1" ;;
  esac
}

select_mode() {
  local mode="$1"

  case "$mode" in
    all)
      write_mode all
      stop_daemon
      map_to_output ""
      ;;
    follow)
      write_mode follow
      start_daemon
      ;;
    *)
      if ! monitor_exists "$mode"; then
        echo "Unknown monitor: $mode" >&2
        exit 1
      fi
      write_mode "$mode"
      start_daemon
      map_to_output "$mode"
      ;;
  esac
}

print_status() {
  local mode enabled
  mode=$(selected_mode)
  if [ "$mode" = "all" ]; then enabled=false; else enabled=true; fi

  jq -nc \
    --argjson enabled "$enabled" \
    --arg mode "$mode" \
    --arg output "$(active_output)" \
    --arg tooltip "$(describe_mode "$mode")" \
    '{enabled: $enabled, mode: $mode, output: $output, class: (if $enabled then "enabled" else "disabled" end), tooltip: $tooltip}'
}

print_monitors() {
  local mode
  mode=$(selected_mode)
  hyprctl monitors -j | jq -c --arg mode "$mode" \
    '[.[] | {name, description, model, focused, selected: (.name == $mode)}]'
}

case "${1:-toggle}" in
  toggle)
    if [ "$(selected_mode)" = "all" ]; then select_mode follow; else select_mode all; fi
    ;;
  on|enable)
    select_mode follow
    ;;
  off|disable)
    select_mode all
    ;;
  set)
    [ -n "$2" ] || { echo "Usage: omarchy-toggle-tablet-follow set <monitor|follow|all>" >&2; exit 1; }
    select_mode "$2"
    ;;
  status|--status)
    print_status
    ;;
  monitors)
    print_monitors
    ;;
  autostart)
    [ "$(selected_mode)" = "all" ] || start_daemon
    ;;
  *)
    echo "Usage: omarchy-toggle-tablet-follow [toggle|on|off|set <monitor|follow|all>|status|monitors|autostart]" >&2
    exit 1
    ;;
esac
