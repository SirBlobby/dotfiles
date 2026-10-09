bar_widgets=(
  "blob.agents:blob.tray"
)

make_scripts_executable() {
  local not_executable=()
  local script

  while IFS= read -r script; do
    not_executable+=("$script")
  done < <({ find "$repo_dir/bin" -maxdepth 1 -type f ! -perm -u+x; find "$repo_dir/shell" -type f -name '*.sh' ! -perm -u+x; } | sort)

  if (( ${#not_executable[@]} == 0 )); then
    say "ok    bin/ and shell/ scripts executable"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would make ${#not_executable[@]} script(s) in bin/ and shell/ executable"
    return 0
  fi

  chmod +x "${not_executable[@]}"
  say "chmod ${#not_executable[@]} script(s) in bin/ and shell/"
}

bar_has_widget() {
  local shell_config="$1" widget_id="$2"
  jq -e --arg id "$widget_id" '[.bar.layout[][]? | .id?] | index($id) != null' "$shell_config" >/dev/null 2>&1
}

add_bar_widget() {
  local shell_config="$1" widget_id="$2" after_id="$3"
  local updated_config

  updated_config="$(mktemp)"
  jq --arg id "$widget_id" --arg after "$after_id" '
    if ([.bar.layout[][]? | .id?] | index($after)) != null then
      .bar.layout |= map_values([.[] | if .id? == $after then ., {id: $id} else . end])
    else
      .bar.layout.right = [{id: $id}] + (.bar.layout.right // [])
    end
  ' "$shell_config" >"$updated_config" || {
    rm -f "$updated_config"
    warn "could not add $widget_id to shell.json"
    return 0
  }

  cp "$shell_config" "$shell_config.bak"
  mv "$updated_config" "$shell_config"
  say "add   bar widget $widget_id"
}

install_bar_widgets() {
  local shell_config="$config_dir/blob/shell.json"
  local entry widget_id after_id

  if [[ ! -f $shell_config ]]; then
    say "SKIP  bar widgets (no shell.json yet)"
    return 0
  fi

  if ! command -v jq &>/dev/null; then
    say "SKIP  bar widgets (jq not installed)"
    return 0
  fi

  for entry in "${bar_widgets[@]}"; do
    widget_id="${entry%%:*}"
    after_id="${entry#*:}"

    if bar_has_widget "$shell_config" "$widget_id"; then
      say "ok    bar widget $widget_id"
      continue
    fi

    note_change
    if [[ $check == true ]]; then
      say "would add bar widget $widget_id after $after_id"
      continue
    fi

    add_bar_widget "$shell_config" "$widget_id" "$after_id"
  done
}
