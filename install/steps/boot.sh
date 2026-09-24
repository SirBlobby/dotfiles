boot_splash_image="$repo_dir/branding/blob_boot.png"
boot_splash_theme_dir="/usr/share/plymouth/themes/blob"

boot_splash_installed() {
  command -v plymouth-set-default-theme &>/dev/null || return 1
  [[ -f $boot_splash_theme_dir/blob.plymouth ]] || return 1
  [[ "$(plymouth-set-default-theme 2>/dev/null)" == blob ]]
}

install_boot_splash() {
  if ! command -v plymouth-set-default-theme &>/dev/null; then
    say "SKIP  boot splash (plymouth not installed)"
    return 0
  fi

  if [[ ! -f $boot_splash_image ]]; then
    say "SKIP  boot splash (branding/blob_boot.png missing)"
    return 0
  fi

  if boot_splash_installed && cmp -s "$boot_splash_image" "$boot_splash_theme_dir/logo.png"; then
    say "ok    boot splash"
    return 0
  fi

  note_change
  if [[ $check == true ]]; then
    say "would set the boot splash to branding/blob_boot.png and rebuild the initramfs"
    return 0
  fi

  if BLOB_PATH="$blob_path" "$repo_dir/bin/blob-boot" "$boot_splash_image"; then
    say "set   boot splash to branding/blob_boot.png"
  else
    warn "could not set the boot splash; run 'blob boot' to retry"
  fi
}
