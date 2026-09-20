directories=(
  "$HOME/.config/blob/hooks"
  "$HOME/.config/blob/extensions"
  "$HOME/.config/blob/plugins"
  "$HOME/.config/blob/themed"
  "$HOME/.config/blob/themes"
  "$HOME/.config/blob/branding"
  "$HOME/.config/hypr"
  "$HOME/.config/uwsm/env.d"
  "$HOME/.config/systemd/user/app.slice.d"
  "$HOME/.local/state/blob/toggles/hypr"
  "$HOME/.local/state/blob/indicators"
  "$HOME/.local/state/blob/notifications/history"
  "$HOME/.local/state/blob/notifications/images"
  "$HOME/.local/state/blob/backgrounds"
  "$HOME/.local/state/blob/current"
  "$HOME/.local/share/fonts"
  "$HOME/.local/share/applications"
  "$HOME/.local/share/icons/hicolor/256x256/apps"
  "$HOME/wallpapers"
)

create_directories() {
  local missing=()
  local dir
  for dir in "${directories[@]}"; do
    [[ -d $dir ]] || missing+=("$dir")
  done

  if (( ${#missing[@]} == 0 )); then
    say "ok    directories"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would create ${#missing[@]} directory(ies):"
    printf '        %s\n' "${missing[@]}"
    return 0
  fi

  mkdir -p "${missing[@]}"
  say "mkdir ${#missing[@]} directory(ies)"
}
