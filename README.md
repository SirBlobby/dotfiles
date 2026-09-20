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
| `hooks/` | event hooks, such as retinting on theme change |
| `branding/` | icon, ASCII art, boot splash |
| `wallpapers/` | 103 wallpapers, previewed in [the gallery](wallpaper-gallery/index.md) |
| `session/` | wayland session entry and uwsm environment |
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
| [packages.md](docs/packages.md) | leaving the Omarchy repository, and updating |
| [upstream.md](docs/upstream.md) | the fork base, for diffing later |

## Install

`BLOB_PATH` is a symlink to this checkout, so `bin/`, `shell/`, `themes/` and
`default/` are always the working tree and edits are live. Only the handful of
files that must sit under `~/.config` get copied.

```bash
./install.sh            # link and deploy
./install.sh --check    # report what would change, write nothing
./install.sh --force    # overwrite files with local changes
```

Then log out and pick the Blob session.

To back out, `./uninstall.sh` removes the session entry, the config, and the
symlink, restoring any `.bak` the installer made. The checkout, the wallpapers,
and the themes stay where they are.

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
| `Super + Ctrl + L` | Lock |

The rest are in [keybinds.md](docs/keybinds.md), or run `blob menu keybindings`.
