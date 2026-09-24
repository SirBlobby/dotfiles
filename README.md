<div align="center">
  <h1>Blob</h1>
  <p>A self-contained Wayland desktop for Arch Linux.</p>

  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Hyprland-00A86B?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Quickshell-2A2A2A?style=for-the-badge&logo=qt&logoColor=white" alt="Quickshell" />
</div>

---

This started as a layer of overrides on top of Omarchy and is now its own
desktop. It keeps the look, layout, and base functionality that were worth
keeping, and owns every line that runs. There is no upstream package to track
and nothing to re-apply after somebody else's release.

## What it is

- **[Hyprland](https://hyprland.org/)** as the compositor, configured in Lua.
- **[Quickshell](https://quickshell.org/)** as the desktop: `blob-shell` is one
  process hosting the bar, both menus, the panels, notifications, the lock
  screen, and the OSD as plugins.
- **A `blob-*` CLI** of 290 commands, dispatched by `blob`.
- **24 themes** with a palette pipeline that retints the terminal, editor,
  browser, shell, and lock screen from one `colors.toml`.

## Layout

| Path | Contents |
| --- | --- |
| `bin/` | the `blob-<area>-<verb>` commands |
| `shell/` | the Quickshell desktop |
| `hypr/` | personal Hyprland config, deployed to `~/.config/hypr` |
| `default/` | the shipped defaults the commands and shell resolve: `hypr/` Lua layer, `themed/` templates, `blob/` menu tree |
| `themes/` | colour themes |
| `config/` | shipped app configs |
| `shell.json` | bar layout and idle timings |
| `hooks/` | optional user hook templates (`.sample`), copied to `~/.config/blob/hooks` and run by `blob-hook` once renamed |
| `branding/` | icon, ASCII art, boot splash |
| `wallpapers/` | 103 wallpapers, previewed in [the gallery](wallpaper-gallery/index.md) |
| `session/` | wayland session entry and uwsm environment |
| `install/` | the installer steps `install.sh` runs |
| `docs/` | everything below |

## Docs

| Doc | Covers |
| --- | --- |
| [commands.md](docs/commands.md) | every command, generated from its own metadata |
| [keybinds.md](docs/keybinds.md) | every binding, generated from the Lua |
| [shell.md](docs/shell.md) | shell layout, bar config, plugin model |
| [themes.md](docs/themes.md) | the palette pipeline and how to add a theme |
| [widgets.md](docs/widgets.md) | the ported GTK widgets and where they went |
| [menu.md](docs/menu.md) | the menu tree and what was trimmed |
| [install.md](docs/install.md) | what the installer does, step by step |
| [hooks.md](docs/hooks.md) | the optional user hooks and when each one runs |
| [packages.md](docs/packages.md) | leaving the Omarchy repository, and updating |
| [upstream.md](docs/upstream.md) | the fork base, for diffing later |

## Install

`BLOB_PATH` is a symlink to this checkout, so `bin/`, `shell/`, `themes/` and
`default/` are always the working tree and edits are live. Only the handful of
files that must sit under `~/.config` get copied.

```bash
./install.sh              # directories, packages, config, services, login screen
./install.sh --check      # report what would change, write nothing
./install.sh --force      # overwrite files with local changes
./install.sh --autologin  # log this user straight into the Blob session
./install.sh --no-launch  # do not open the login screen at the end
```

It runs these steps, in this order, and every one of them is idempotent:

| Step | What it does |
| --- | --- |
| 1. Directories | creates the 19 directories the shell and scripts expect, before anything writes into them |
| 2. `BLOB_PATH` | symlinks `~/.local/share/blob` to this checkout |
| 3. Packages | installs what is missing from `packages/`, bootstrapping `yay` first on a machine that has no AUR helper |
| 4. Config | copies `hypr/`, the themed app configs, `blob/shell.json`, and the uwsm environment into `~/.config`, sets the default apps for images, video, PDFs, office files, text and archives, and writes `/etc/profile.d/blob.sh` so a login shell finds the `blob` command |
| 5. First theme | links `~/wallpapers` to the checkout, applies `flats` headless, picks a background, and links the btop and Neovim theme files, so the first login is not a blank desktop |
| 6. User units | installs the session services into `~/.config/systemd/user` and enables them |
| 7. systemd drop-ins | writes the shutdown timeouts, oomd thresholds, plocate prune paths, and sleep hooks under `/etc` |
| 8. System services | enables NetworkManager, resolved, bluetooth, cups, avahi, docker, power-profiles-daemon, and oomd, masks `NetworkManager-wait-online`, sets the boot splash to `branding/blob_boot.png`, and sets GRUB up with every other installed OS in its menu |
| 9. Login screen | installs the session entry and the SDDM config, enables `sddm.service`, and sets the default target to `graphical.target` |
| 10. Reload | reloads systemd, restarts the running user services, and in a running session re-renders the theme, reloads Hyprland, and restarts the Blob shell |
| 11. Launch | starts the login screen, so the desktop comes up without a reboot |

Step 9 is the one a plain Arch install cannot do without: SDDM's stock Wayland
greeter runs on `weston`, which Blob does not install, so the greeter is pointed
at Hyprland with a Lua config, the only format Hyprland still reads. It also
reports any leftover drop-in that autologs into a session that is not installed,
which is the other thing a black screen with no login prompt usually is.
[install.md](docs/install.md) covers each step in full.

To back out, `./uninstall.sh` removes the session entry, the config, the user
services, and the symlinks, restoring any `.bak` the installer made. The
checkout, the wallpapers, and the themes stay where they are.

## Regenerating docs

```bash
blob-docs-commands
blob-docs-keybinds
```

## Keys worth knowing

| Keys | Action |
| --- | --- |
| `Super + Space` | Apps menu |
| `Super + Alt + Space` | Root menu |
| `Super + Ctrl + Q` | Quick settings |
| `Super + Ctrl + M` | System monitor |
| `Super + Alt + W` | Wallpaper picker |
| `Super + Shift + K` | Manage keybindings |
| `Super + Ctrl + L` | Lock |

The rest are in [keybinds.md](docs/keybinds.md), or run `blob menu keybindings`.
