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

- **`hypr/`**: Hyprland configurations (keybindings, window rules, animations, layout settings, and autostart).
- **`waybar/`**: Status bar layout, CSS styling, and custom interactive modules.
- **`ags/`**: Custom desktop widgets built with TypeScript and GTK.
- **`scripts/`**: Global utility scripts seamlessly exposed as commands by the installer.
- **`wallpapers/`**: A collection of local custom wallpapers for dynamic theming.
- **`omarchy/hooks/`**: Event hooks for the Omarchy system (e.g. automatically applying dynamic themes when changing wallpapers).
- **`branding/`**: Custom ASCII art and system branding assets.

## Custom Commands

The installer automatically exposes scripts from the `scripts/` directory as global commands:

- **`blob_wallpaper [path]`**: Sets your background using Omarchy's background system. If used with an image from `~/wallpapers/` or a valid path, it leverages Pywal to generate a full system color palette and dynamically updates the `blob-dynamic` theme, AGS widgets, and Waybar.
- **`blob_glass [on|off|toggle]`**: A quick toggle to enable or disable window transparency on the fly.
- **`blob_wifi`**: A streamlined script to connect to the GMU Eduroam Wi-Fi network using `iwd` and `systemd-resolved` (replaces NetworkManager).

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

