mimeapps_file="$config_dir/mimeapps.list"

default_app_associations=(
  "org.gnome.Loupe.desktop:image/png image/jpeg image/gif image/webp image/bmp image/tiff image/avif image/heif image/svg+xml"
  "mpv.desktop:video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4"
  "org.gnome.Evince.desktop:application/pdf application/postscript image/vnd.djvu application/oxps application/vnd.comicbook+zip application/x-cbz"
  "libreoffice-writer.desktop:application/vnd.oasis.opendocument.text application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document application/rtf"
  "libreoffice-calc.desktop:application/vnd.oasis.opendocument.spreadsheet application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet text/csv"
  "libreoffice-impress.desktop:application/vnd.oasis.opendocument.presentation application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation"
  "org.gnome.TextEditor.desktop:text/plain text/markdown"
  "org.gnome.FileRoller.desktop:application/zip application/x-7z-compressed application/vnd.rar application/x-tar application/x-compressed-tar application/gzip application/x-xz application/x-bzip2 application/zstd"
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

  local pending=() entry desktop_file mime_types mime_type
  for entry in "${default_app_associations[@]}"; do
    desktop_file="${entry%%:*}"
    mime_types="${entry#*:}"
    [[ -f /usr/share/applications/$desktop_file ]] || continue
    for mime_type in $mime_types; do
      mime_default_chosen "$mime_type" && continue
      pending+=("$desktop_file:$mime_type")
    done
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
