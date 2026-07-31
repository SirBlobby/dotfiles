<div align="center">
  <h1>Blob's Dotfiles</h1>
  <p>My personal system configurations for a custom Wayland desktop environment built on <a href="https://omarchy.org">Omarchy</a>.</p>

  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Hyprland-00A86B?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Waybar-FF6600?style=for-the-badge&logo=linux&logoColor=white" alt="Waybar" />
  <img src="https://img.shields.io/badge/AGS-231F20?style=for-the-badge&logo=gnome&logoColor=white" alt="AGS" />
</div>

---

## What's Inside?

My current setup is built around these core components:

- **[Hyprland](https://hyprland.org/):** A highly customizable dynamic tiling Wayland compositor.
- **[Waybar](https://github.com/Alexays/Waybar):** A customizable, modular status bar.
- **[AGS](https://github.com/Aylur/ags):** Aylur's Gtk Shell, used for creating custom, scriptable desktop widgets.
- **Dynamic Theming:** Seamlessly integrated with Pywal to extract color palettes from wallpapers and apply them instantly across the entire system (widgets, terminal, status bar).

### Directory Structure

- **`hypr/`**: Hyprland configurations (keybindings, window rules, animations, monitor layout, lid-close display handling, and autostart). See [`hypr/keybinds.md`](hypr/keybinds.md) for custom keybindings.
- **`waybar/`**: Status bar layout, CSS styling, and custom interactive modules.
- **`ags/`**: Custom desktop widgets built with TypeScript and GTK — media player, notification hub, quick settings, system monitor, and wallpaper picker.
- **`scripts/`**: Global utility scripts seamlessly exposed as commands by the installer. See [`commands.md`](commands.md).
- **`wallpapers/`**: A collection of local custom wallpapers for dynamic theming. See [`wallpaper-gallery/`](wallpaper-gallery/index.md) for the full gallery (split alphabetically across multiple pages).
- **`omarchy/hooks/`**: Event hooks for the Omarchy system (e.g. automatically applying dynamic themes when changing wallpapers).
- **`branding/`**: Custom ASCII art and system branding assets.

## Docs

- [Wallpaper Gallery](wallpaper-gallery/index.md) — preview of every wallpaper in `wallpapers/`, split alphabetically across [A-D](wallpaper-gallery/a-d.md), [E-M](wallpaper-gallery/e-m.md), [N-R](wallpaper-gallery/n-r.md), [S-Z](wallpaper-gallery/s-z.md).
- [Keybinds](hypr/keybinds.md) — custom Hyprland keybindings on top of Omarchy's defaults.
- [Commands](commands.md) — custom `blob_*` CLI commands exposed by the installer.

## Installation

An automated installer script (`install.sh`) is provided to safely apply these configurations to your system.

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

