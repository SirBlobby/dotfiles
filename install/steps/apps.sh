mimeapps_file="$config_dir/mimeapps.list"

mime_types_dir="$repo_dir/default/mime"

default_app_associations=(
  "org.gnome.Loupe.desktop:image"
  "mpv.desktop:video"
  "org.gnome.Evince.desktop:pdf"
  "libreoffice-writer.desktop:document"
  "libreoffice-calc.desktop:spreadsheet"
  "libreoffice-impress.desktop:presentation"
  "org.gnome.TextEditor.desktop:text"
  "org.gnome.FileRoller.desktop:archive"
)

mime_default_chosen() {
  [[ -f $mimeapps_file ]] || return 1
  awk -v mime="$1" '
    /^\[/ { in_defaults = ($0 == "[Default Applications]"); next }
    in_defaults && index($0, mime "=") == 1 { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$mimeapps_file"
}

install_default_apps() {
  if ! command -v xdg-mime &>/dev/null; then
    say "SKIP  default applications (xdg-utils not installed)"
    return 0
  fi

  local pending=() entry desktop_file kind mime_type
  for entry in "${default_app_associations[@]}"; do
    desktop_file="${entry%%:*}"
    kind="${entry#*:}"
    [[ -f /usr/share/applications/$desktop_file ]] || continue
    [[ -f $mime_types_dir/$kind.types ]] || continue
    while IFS= read -r mime_type; do
      [[ -n $mime_type ]] || continue
      mime_default_chosen "$mime_type" && continue
      pending+=("$desktop_file:$mime_type")
    done <"$mime_types_dir/$kind.types"
  done

  if (( ${#pending[@]} == 0 )); then
    say "ok    default applications"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would set ${#pending[@]} default application association(s)"
    return 0
  fi

  for entry in "${pending[@]}"; do
    xdg-mime default "${entry%%:*}" "${entry#*:}"
  done
  say "set   ${#pending[@]} default application association(s)"
}
