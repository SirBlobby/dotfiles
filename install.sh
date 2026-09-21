#!/bin/bash

set -e

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
blob_path="$HOME/.local/share/blob"
config_dir="$HOME/.config"
font_dir="$HOME/.local/share/fonts"

force=false
check=false
skip_packages=false
no_launch=false
autologin=false
changes=0

usage() {
  cat <<USAGE
Usage: ./install.sh [OPTIONS]

Creates every directory Blob needs, installs the packages that are missing,
writes the config, enables the services, and opens the login screen.

  --check           Report what would change, write nothing
  --force           Overwrite files that have local changes
  --skip-packages   Do not install packages, only directories and config
  --autologin       Log this user straight into the Blob session
  --no-launch       Do not start the login screen at the end
  --help            Show this message
USAGE
  exit 0
}

while (( $# > 0 )); do
  case "$1" in
    --force) force=true; shift ;;
    --check) check=true; shift ;;
    --skip-packages) skip_packages=true; shift ;;
    --autologin) autologin=true; shift ;;
    --no-launch) no_launch=true; shift ;;
    --help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

source "$repo_dir/install/helpers/lib.sh"
source "$repo_dir/install/steps/directories.sh"
source "$repo_dir/install/steps/packages.sh"
source "$repo_dir/install/steps/config.sh"
source "$repo_dir/install/steps/services.sh"
source "$repo_dir/install/steps/theme.sh"
source "$repo_dir/install/steps/login.sh"

say "Blob installer"
say "repo: $repo_dir"
if [[ $check == true ]]; then
  say "mode: check (nothing will be written)"
fi
say ""

create_directories
link_blob_path
install_packages

install_shipped_config
refresh_font_cache
install_shell_profile
install_bash_integration
install_user_units
install_systemd_dropins
install_zen_config

link_wallpapers
install_default_theme
install_default_background
link_app_themes

enable_system_services
mask_system_services
enable_user_units

install_login_config
install_session_entry
install_autologin
enable_display_manager
report_greeter_compositor
report_login_conflicts
report_desktop_essentials

say ""
if [[ $check == true ]]; then
  say "$changes item(s) would change."
  (( changes == 0 )) || exit 1
else
  say "$changes item(s) changed."

  active_theme="$(cat "$current_state_dir/theme.name" 2>/dev/null || true)"
  if [[ -n $active_theme ]]; then
    say "Theme: $active_theme. Change it with 'blob theme set <name>'."
  fi

  say "New shells find the blob command through /etc/profile.d/blob.sh."
  say "For this shell: source $blob_path/session/env-bootstrap"
  say ""
  launch_desktop
fi
