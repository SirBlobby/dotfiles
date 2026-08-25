#!/bin/bash

STATE_FILE="$HOME/.local/state/omarchy/indicators/tablet-follow-focus"
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
TABLET_DEVICE="${OMARCHY_TABLET_DEVICE:-hanvon-ugee-6-inch-pentablet-pen}"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/omarchy-tablet-follow-focus.pid"

if [ "$(ps -o pgid= -p $$ | tr -d ' ')" != "$$" ]; then
  exec setsid "$0" "$@"
fi

echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

selected_mode() {
  local mode
  [ -f "$STATE_FILE" ] || { echo all; return; }
  mode=$(cat "$STATE_FILE" 2>/dev/null)
  echo "${mode:-follow}"
}

focused_monitor() {
  hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name'
}

monitor_exists() {
  hyprctl monitors -j | jq -e --arg name "$1" 'any(.[]; .name == $name)' >/dev/null
}

map_to_output() {
  hyprctl eval "hl.device({ name = \"$TABLET_DEVICE\", output = \"$1\" })" >/dev/null
}

apply_selected_mode() {
  local mode target
  mode=$(selected_mode)

  case "$mode" in
    all)
      map_to_output ""
      ;;
    follow)
      target=$(focused_monitor)
      [ -n "$target" ] && map_to_output "$target"
      ;;
    *)
      if monitor_exists "$mode"; then
        map_to_output "$mode"
      else
        target=$(focused_monitor)
        [ -n "$target" ] && map_to_output "$target"
      fi
      ;;
  esac
}

while true; do
  apply_selected_mode

  socat -U - UNIX-CONNECT:"$SOCKET" | while read -r line; do
    case "$line" in
      focusedmon\>\>*)
        [ "$(selected_mode)" = "follow" ] && apply_selected_mode
        ;;
      monitoradded\>\>*|monitorremoved\>\>*)
        apply_selected_mode
        ;;
    esac
  done

  sleep 1
done
