<div align="center">
  <h1>Blob's Dotfiles</h1>
  <p>My personal system configurations for a custom Wayland desktop environment built on <a href="https://omarchy.org">Omarchy</a>.</p>

  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Hyprland-00A86B?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Omarchy_4-000000?style=for-the-badge&logo=archlinux&logoColor=white" alt="Omarchy 4" />
  <img src="https://img.shields.io/badge/AGS-231F20?style=for-the-badge&logo=gnome&logoColor=white" alt="AGS" />
</div>

---

## What's Inside?

My current setup is built around these core components:

- **[Hyprland](https://hyprland.org/):** A highly customizable dynamic tiling Wayland compositor.
- **Omarchy shell:** The Quickshell-based bar, notifications, and lock screen that ships with Omarchy 4, configured through `omarchy/shell.json`.
- **[AGS](https://github.com/Aylur/ags):** Aylur's Gtk Shell, used for creating custom, scriptable desktop widgets — quick settings with a browsable calendar, notification center, system monitor, wallpaper and theme pickers, and a Claude Code usage card fed by Omarchy's own agent usage records.
- **Dynamic Theming:** Seamlessly integrated with Pywal to extract color palettes from wallpapers and apply them instantly across the entire system (widgets, terminal, status bar).
- **[kitty](https://sw.kovidgoyal.net/kitty/):** The terminal, with its own checked-in color theme — see [`kitty/`](kitty/README.md).

### Directory Structure

- **`hypr/`**: Hyprland configurations (keybindings, window rules, animations, monitor layout, lid-close display handling, and autostart). See [`hypr/keybinds.md`](hypr/keybinds.md) for custom keybindings.
- **`omarchy/`**: Omarchy 4 configuration — `shell.json` (bar layout, custom bar modules, and idle/lock timings), `extensions/` (entries added to the Omarchy menu), `hooks/` (event hooks such as retinting AGS on theme change), `plugins/` (cloned shell plugins for the bar), and `themed/` (extra theme templates). See [`omarchy/README.md`](omarchy/README.md) for the bar layout and the plugin clones.
- **`ags/`**: Custom desktop widgets built with TypeScript and GTK — media player, notification hub, quick settings, system monitor, wallpaper picker, theme picker, and Claude Code usage.
- **`scripts/`**: Global utility scripts seamlessly exposed as commands by the installer. See [`commands.md`](commands.md).
- **`wallpapers/`**: A collection of local custom wallpapers for dynamic theming. See [`wallpaper-gallery/`](wallpaper-gallery/index.md) for the full gallery (split alphabetically across multiple pages).
- **`themes/`**: Drop-in local color themes (one `colors.toml` per theme) that `install.sh` deploys into Omarchy's theme directory. See [`themes/README.md`](themes/README.md).
- **`branding/`**: Custom ASCII art and system branding assets.
- **`kitty/`**: kitty terminal config and its color theme, applied by hand rather than by `install.sh`. See [`kitty/README.md`](kitty/README.md).

## Docs

- [Wallpaper Gallery](wallpaper-gallery/index.md) — preview of every wallpaper in `wallpapers/`, split alphabetically across [0-9, A-E](wallpaper-gallery/a-d.md), [E-M](wallpaper-gallery/e-m.md), [M-R](wallpaper-gallery/m-r.md), [R-Y](wallpaper-gallery/r-z.md).
- [Omarchy shell](omarchy/README.md) — bar layout, custom bar modules, and the cloned shell plugins.
- [Themes](themes/README.md) — how to add a local color theme.
- [kitty](kitty/README.md) — terminal config, and how to port a theme to it.
- [Keybinds](hypr/keybinds.md) — custom Hyprland keybindings on top of Omarchy's defaults.
- [Commands](commands.md) — custom `blob_*` CLI commands exposed by the installer.

## Installation

An automated installer script (`install.sh`) is provided to safely apply these configurations to your system. It targets Arch running Omarchy 4 — `kitty/` is applied by hand, see [`kitty/README.md`](kitty/README.md).

```bash
# Run the standard installer
./install.sh

# See what would change without modifying any files (dry run)
./install.sh --check

# Force overwrite of any existing local changes
./install.sh --force
```

The installer also configures the laptop lid switch so the machine stays awake (and the external monitors stay active) when docked or on AC power.

To roll back to the backups the installer created, use `revert.sh`:

```bash
# Restore configs from their .bak versions (prompts first)
./revert.sh
```

