#!/bin/bash

set -e

repo_url="${BLOB_REPO_URL:-https://git.sirblob.co/SirBlob/blomarchy.git}"
repo_branch="${BLOB_REPO_BRANCH:-main}"
checkout_dir="${BLOB_CHECKOUT_DIR:-$HOME/dotfiles}"

if (( EUID == 0 )); then
  echo "Run this as your own user, not as root. It asks for sudo when it needs it." >&2
  exit 1
fi

if ! command -v pacman &>/dev/null; then
  echo "pacman not found; Blob installs on Arch Linux only." >&2
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "Installing git"
  sudo pacman -Syu --needed --noconfirm git
fi

if [[ -d $checkout_dir/.git ]]; then
  echo "Updating $checkout_dir"
  git -C "$checkout_dir" pull --ff-only
else
  echo "Cloning $repo_url into $checkout_dir"
  git clone --branch "$repo_branch" "$repo_url" "$checkout_dir"
fi

exec "$checkout_dir/install.sh" "$@" </dev/tty
